// ─────────────────────────────────────────────────────────────────────────────
// audio_mixer.cpp — LiveStage Pro Native Audio Mixer
// ─────────────────────────────────────────────────────────────────────────────
// Disk streaming: lock-free ring buffers + background IO thread (dr_wav).
// ─────────────────────────────────────────────────────────────────────────────

#include "audio_mixer.h"
#include "libs/dr_wav.h"

#include <android/log.h>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <thread>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#ifdef __ANDROID__
#define LOG_TAG "AudioMixer"
#define LOGD_MIX(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE_MIX(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#else
#define LOGD_MIX(...)
#define LOGE_MIX(...)
#endif

// ─── BiquadFilter Implementation ───────────────────────────────────────────────

void BiquadFilter::computeCoefficients(int32_t sampleRate) {
    const float w0 = 2.0f * static_cast<float>(M_PI) * frequency / static_cast<float>(sampleRate);
    const float cosW0 = std::cos(w0);
    const float sinW0 = std::sin(w0);
    const float A = std::pow(10.0f, gainDb / 40.0f);  // sqrt of linear gain
    const float alpha = sinW0 / (2.0f * q);
    
    float a0 = 1.0f;

    switch (type) {
        case FilterType::HIGHPASS:
            b0 = (1.0f + cosW0) / 2.0f;
            b1 = -(1.0f + cosW0);
            b2 = (1.0f + cosW0) / 2.0f;
            a0 = 1.0f + alpha;
            a1 = -2.0f * cosW0;
            a2 = 1.0f - alpha;
            break;

        case FilterType::LOWPASS:
            b0 = (1.0f - cosW0) / 2.0f;
            b1 = 1.0f - cosW0;
            b2 = (1.0f - cosW0) / 2.0f;
            a0 = 1.0f + alpha;
            a1 = -2.0f * cosW0;
            a2 = 1.0f - alpha;
            break;

        case FilterType::PEAKING:
        default:
            a0 = 1.0f + alpha / A;
            b0 = 1.0f + alpha * A;
            b1 = -2.0f * cosW0;
            b2 = 1.0f - alpha * A;
            a1 = -2.0f * cosW0;
            a2 = 1.0f - alpha / A;
            break;
    }

    const float a0_inv = 1.0f / a0;
    b0 *= a0_inv;
    b1 *= a0_inv;
    b2 *= a0_inv;
    a1 *= a0_inv;
    a2 *= a0_inv;
}

float BiquadFilter::processL(float in) {
    // Direct Form II Transposed
    float out = b0 * in + z1L;
    z1L = b1 * in - a1 * out + z2L;
    z2L = b2 * in - a2 * out;
    return out;
}

float BiquadFilter::processR(float in) {
    float out = b0 * in + z1R;
    z1R = b1 * in - a1 * out + z2R;
    z2R = b2 * in - a2 * out;
    return out;
}

void BiquadFilter::resetState() {
    z1L = z2L = 0.0f;
    z1R = z2R = 0.0f;
}

// ─── Lifecycle ───────────────────────────────────────────────────────────────

AudioMixer::AudioMixer() = default;
AudioMixer::~AudioMixer() { dispose(); }

void AudioMixer::init(int32_t sampleRate) {
       std::lock_guard<std::mutex> lock(mutex_);
    sampleRate_ = sampleRate > 0 ? sampleRate : kDefaultSampleRate;
    gainSmoothSamples_ =
        static_cast<int32_t>(kGainSmoothingSeconds * static_cast<float>(sampleRate_));
    if (gainSmoothSamples_ < 1) gainSmoothSamples_ = 1;

    // 10ms Quantized Jump Ramp
    jumpRampFrames_ = static_cast<int32_t>(0.010f * static_cast<float>(sampleRate_));
    if (jumpRampFrames_ < 1) jumpRampFrames_ = 1;
    
    // unique_ptr handles cleanup automatically
    tracks_.clear();

    isPlaying_ = false;
    hasSoloedTracks_ = false;

    // Initialize Drum Voice Pool (32 voices)
    std::lock_guard<std::mutex> dLock(drumMutex_);
    drumVoices_.clear();
    for (int i = 0; i < 32; ++i) {
        drumVoices_.emplace_back();
    }
}

void AudioMixer::setSampleRate(int32_t sampleRate) {
      std::lock_guard<std::mutex> lock(mutex_);
    if (sampleRate <= 0 || sampleRate == sampleRate_) return;

    sampleRate_ = sampleRate;
    gainSmoothSamples_ =
        static_cast<int32_t>(kGainSmoothingSeconds * static_cast<float>(sampleRate_));
    if (gainSmoothSamples_ < 1) gainSmoothSamples_ = 1;

    for (auto& [id, track] : tracks_) {
        if (track->soundTouchProcessor) {
            track->soundTouchProcessor->setSampleRate(sampleRate_);
        }
        for (auto& band : track->eqBands) {
            band.computeCoefficients(sampleRate_);
        }
    }
    for (auto& band : masterEqBands_) {
        band.computeCoefficients(sampleRate_);
    }

    // 10ms Quantized Jump Ramp
    jumpRampFrames_ = static_cast<int32_t>(0.010f * static_cast<float>(sampleRate_));
    if (jumpRampFrames_ < 1) jumpRampFrames_ = 1;
}

void AudioMixer::dispose() {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto& [_, track] : tracks_)
        stopTrackStreaming(*track);
    tracks_.clear();
    isPlaying_ = false;
    hasSoloedTracks_ = false;
}

// ─── Streaming: stop IO thread and close file ─────────────────────────────────

void AudioMixer::stopTrackStreaming(MixerTrack& track) {
    track.ioStopRequested.store(true);
    if (track.ioThread.joinable())
        track.ioThread.join();
    track.ioStopRequested.store(false);
    if (track.wavFileHandle) {
        drwav* wav = static_cast<drwav*>(track.wavFileHandle);
        drwav_uninit(wav);
        delete wav;
        track.wavFileHandle = nullptr;
    }
}

// ─── Resample: linear interpolation (for disk streaming when file rate != mixer rate) ───

static void resampleFrames(const float* in, size_t inFrames, int32_t numCh,
                           int32_t inRate, int32_t outRate,
                           float* out, size_t outFrames) {
    if (inFrames == 0 || outFrames == 0 || numCh < 1 || inRate <= 0 || outRate <= 0) return;
    const float ratio = static_cast<float>(inRate) / static_cast<float>(outRate);
    const size_t inSamples = inFrames * static_cast<size_t>(numCh);
    for (size_t i = 0; i < outFrames; ++i) {
        const float srcFrame = static_cast<float>(i) * ratio;
        const size_t f0 = static_cast<size_t>(srcFrame);
        const size_t f1 = std::min(f0 + 1, inFrames - 1);
        const float frac = srcFrame - std::floor(srcFrame);
        for (int32_t c = 0; c < numCh; ++c) {
            size_t i0 = f0 * numCh + c;
            size_t i1 = f1 * numCh + c;
            if (i0 >= inSamples) i0 = inSamples - numCh + c;
            if (i1 >= inSamples) i1 = i0;
            out[i * static_cast<size_t>(numCh) + c] = in[i0] * (1.0f - frac) + in[i1] * frac;
        }
    }
}

// ─── IO thread: fill ring from file or from preDecodedPcm ──────────────────────

static void runIoThread(MixerTrack* track, int32_t sampleRate) {
    const size_t chunkSamples = kIoChunkSamples;
    std::vector<float> chunk(chunkSamples, 0.0f);
    drwav* wav = static_cast<drwav*>(track->wavFileHandle);
    const int32_t numCh = track->numChannels;
    const int32_t fileRate = track->fileSampleRate;
    const bool needsResample = (fileRate > 0 && fileRate != sampleRate);

    while (!track->ioStopRequested.load(std::memory_order_relaxed)) {
        // Handle seek: only the latest request is applied (exchange clears it).
        // Rapid scrubbing is safe: no mutex; audio thread skips read while seek is pending.
        int64_t seekFrame = track->seekFrameRequested.exchange(-1);
        if (seekFrame >= 0) {
            if (wav) {
                if (drwav_seek_to_pcm_frame(wav, static_cast<drwav_uint64>(seekFrame)))
                    track->ringBuffer->reset();
            } else {
                track->preDecodedReadOffset = static_cast<size_t>(seekFrame * numCh);
                if (track->preDecodedReadOffset >= track->preDecodedPcm.size())
                    track->preDecodedReadOffset = track->preDecodedPcm.size();
                track->ringBuffer->reset();
            }
        }

        size_t requiredSpace = chunkSamples;
        if (wav && needsResample) {
            const size_t chunkFramesFile = chunkSamples / static_cast<size_t>(numCh);
            const size_t outFrames = static_cast<size_t>(
                std::ceil(static_cast<double>(chunkFramesFile) * static_cast<double>(sampleRate) / static_cast<double>(fileRate)));
            requiredSpace = outFrames * static_cast<size_t>(numCh);
        }

        if (track->ringBuffer->availableToWrite() < requiredSpace) {
            // When disk streaming (wav), sleep less so we refill faster under
            // SoundTouch tempo (consumer drains ring faster). Memory path keeps 5ms.
            const auto delayMs = wav ? 2 : 5;
            std::this_thread::sleep_for(std::chrono::milliseconds(delayMs));
            continue;
        }

        size_t written = 0;
        if (wav) {
            // Read at file rate; if resampling, convert to mixer rate before writing to ring.
            const size_t chunkFramesFile = chunkSamples / static_cast<size_t>(numCh);
            drwav_uint64 toRead = chunkFramesFile;
            drwav_uint64 got = drwav_read_pcm_frames_f32(wav, toRead, chunk.data());
            if (got > 0) {
                if (needsResample) {
                    const size_t inFrames = static_cast<size_t>(got);
                    const size_t outFrames = static_cast<size_t>(
                        static_cast<double>(inFrames) * static_cast<double>(sampleRate) / static_cast<double>(fileRate));
                    if (outFrames > 0) {
                        std::vector<float> resampled(outFrames * numCh, 0.0f);
                        resampleFrames(chunk.data(), inFrames, numCh, fileRate, sampleRate,
                                      resampled.data(), outFrames);
                        written = track->ringBuffer->write(resampled.data(), outFrames * numCh);
                    }
                } else {
                    written = track->ringBuffer->write(chunk.data(), static_cast<size_t>(got * numCh));
                }
            }
            if (written == 0)
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
        } else {
            // Memory-backed: feed from preDecodedPcm
            size_t totalSamples = track->preDecodedPcm.size();
            if (track->preDecodedReadOffset >= totalSamples) {
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
                continue;
            }
            size_t toFeed = std::min(chunkSamples, totalSamples - track->preDecodedReadOffset);
            written = track->ringBuffer->write(
                track->preDecodedPcm.data() + track->preDecodedReadOffset, toFeed);
            track->preDecodedReadOffset += written;
        }
    }
}

// ─── Track Management ────────────────────────────────────────────────────────

void AudioMixer::loadTrack(const std::string& id,
                           const float* pcmData,
                           int64_t numFrames,
                           int32_t numChannels) {
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = tracks_.find(id);
    if (it != tracks_.end())
        stopTrackStreaming(*it->second);

    auto track = std::make_unique<MixerTrack>();
    track->id = id;
    track->numChannels = numChannels;
    track->numFrames = numFrames;

    const size_t totalSamples = static_cast<size_t>(numFrames * numChannels);
    track->preDecodedPcm.assign(pcmData, pcmData + totalSamples);
    track->preDecodedReadOffset = 0;
    track->wavFileHandle = nullptr;

    size_t ringCapacity = static_cast<size_t>(sampleRate_ * numChannels * kRingBufferSeconds);
    if (ringCapacity < 4096) ringCapacity = 4096;
    track->ringBuffer = std::make_unique<LockFreeRingBuffer>(ringCapacity);

    // Pre-fill first kPreFillSeconds so play can start immediately
    size_t preFillSamples = static_cast<size_t>(sampleRate_ * numChannels * kPreFillSeconds);
    if (preFillSamples > totalSamples) preFillSamples = totalSamples;
    track->ringBuffer->write(pcmData, preFillSamples);
    track->preDecodedReadOffset = preFillSamples;

    track->currentGain.store(1.0f);
    track->targetGain.store(1.0f);
    track->gainIncrement.store(0.0f);
    track->gainRampSamplesRemaining.store(0);
    track->pan.store(0.0f);
    computePanGains(*track);
    track->isMuted.store(false);
    track->isSolo.store(false);
    track->playheadFrame = 0;

    track->processBuffer.resize(static_cast<size_t>(kMaxProcessFrames * 2), 0.0f);
    track->stMonoInputBuffer.resize(static_cast<size_t>(kStMonoChunkSize * 2), 0.0f);

    track->soundTouchProcessor = std::make_unique<soundtouch::SoundTouch>();
    track->soundTouchProcessor->setSampleRate(sampleRate_);
    track->soundTouchProcessor->setChannels(2);
    track->soundTouchProcessor->setSetting(SETTING_USE_QUICKSEEK, 1);
    track->soundTouchProcessor->setSetting(SETTING_USE_AA_FILTER, 1);

    track->ioStopRequested.store(false);
    track->seekFrameRequested.store(-1);
    track->ioThread = std::thread(runIoThread, track.get(), sampleRate_);

    tracks_[id] = std::move(track);
}

bool AudioMixer::loadTrackFromFile(const std::string& id, const std::string& filePath) {
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = tracks_.find(id);
    if (it != tracks_.end())
        stopTrackStreaming(*it->second);

    drwav* wav = new drwav{};
    if (!drwav_init_file(wav, filePath.c_str(), nullptr)) {
        LOGE_MIX("loadTrackFromFile: failed to open WAV %s", filePath.c_str());
        delete wav;
        return false;
    }

    const int32_t numCh = static_cast<int32_t>(wav->channels);
    const int64_t totalFrames = static_cast<int64_t>(wav->totalPCMFrameCount);
    const uint32_t fileRate = wav->sampleRate;
    if (numCh < 1 || numCh > 2 || totalFrames <= 0) {
        drwav_uninit(wav);
        delete wav;
        return false;
    }
    // Keep WAV open for disk streaming even when sample rate differs; resample in IO thread.
    const bool sameRate = (fileRate == static_cast<uint32_t>(sampleRate_));
    if (!sameRate) {
        LOGD_MIX("loadTrackFromFile: streaming with resample %u -> %d Hz", fileRate, sampleRate_);
    }

    auto track = std::make_unique<MixerTrack>();
    track->id = id;
    track->numChannels = numCh;
    track->numFrames = totalFrames;
    track->wavFileHandle = wav;
    track->fileSampleRate = static_cast<int32_t>(fileRate);

    size_t ringCapacity = static_cast<size_t>(sampleRate_ * numCh * kRingBufferSeconds);
    if (ringCapacity < 4096) ringCapacity = 4096;
    track->ringBuffer = std::make_unique<LockFreeRingBuffer>(ringCapacity);

    // Pre-fill first kPreFillSeconds at mixer rate for instant play (resample if file rate differs)
    const size_t preFillFramesOut = static_cast<size_t>(sampleRate_ * kPreFillSeconds);
    const size_t preFillFramesFile = sameRate
        ? preFillFramesOut
        : static_cast<size_t>(static_cast<double>(fileRate) * kPreFillSeconds);
    const size_t preFillFramesClamped = std::min(preFillFramesFile, static_cast<size_t>(totalFrames));
    std::vector<float> preFill(preFillFramesClamped * numCh, 0.0f);
    drwav_uint64 got = drwav_read_pcm_frames_f32(wav, preFillFramesClamped, preFill.data());
    if (got > 0) {
        if (sameRate) {
            track->ringBuffer->write(preFill.data(), static_cast<size_t>(got * numCh));
        } else {
            const size_t outFrames = static_cast<size_t>(
                static_cast<double>(got) * static_cast<double>(sampleRate_) / static_cast<double>(fileRate));
            std::vector<float> resampled(outFrames * numCh, 0.0f);
            resampleFrames(preFill.data(), static_cast<size_t>(got), numCh,
                          static_cast<int32_t>(fileRate), sampleRate_,
                          resampled.data(), outFrames);
            track->ringBuffer->write(resampled.data(), outFrames * numCh);
        }
    }

    track->currentGain.store(1.0f);
    track->targetGain.store(1.0f);
    track->gainIncrement.store(0.0f);
    track->gainRampSamplesRemaining.store(0);
    track->pan.store(0.0f);
    computePanGains(*track);
    track->isMuted.store(false);
    track->isSolo.store(false);
    track->playheadFrame = 0;

    track->processBuffer.resize(static_cast<size_t>(kMaxProcessFrames * 2), 0.0f);
    track->stMonoInputBuffer.resize(static_cast<size_t>(kStMonoChunkSize * 2), 0.0f);

    track->soundTouchProcessor = std::make_unique<soundtouch::SoundTouch>();
    track->soundTouchProcessor->setSampleRate(sampleRate_);
    track->soundTouchProcessor->setChannels(2);
    track->soundTouchProcessor->setSetting(SETTING_USE_QUICKSEEK, 1);
    track->soundTouchProcessor->setSetting(SETTING_USE_AA_FILTER, 1);

    track->ioStopRequested.store(false);
    // Signal IO thread to seek to frame 0 and reset ring so the "water tank" is filled from
    // the start on first play (avoids mute on first load when engine was cold).
    track->seekFrameRequested.store(0);
    track->ioThread = std::thread(runIoThread, track.get(), sampleRate_);

    tracks_[id] = std::move(track);
    LOGD_MIX("loadTrackFromFile: instant load %s, %lld frames", filePath.c_str(), (long long)totalFrames);
    LOGD_MIX("DEBUG METRONOMO: Track alocada no tracks_ map com ID: [%s]", id.c_str());
    return true;
}

void AudioMixer::removeTrack(const std::string& id) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it != tracks_.end()) {
        stopTrackStreaming(*it->second);
        tracks_.erase(it);
    }
    hasSoloedTracks_ = false;
    for (const auto& [_, t] : tracks_) {
        if (t->isSolo.load()) {
            hasSoloedTracks_ = true;
            break;
        }
    }
}

void AudioMixer::removeAllTracks() {
    // Synchronous clear so callers (e.g. loadSetlist / loadPreview) can load new tracks
    // immediately without a deferred CLEAR wiping them on the next process() callback.
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto& [_, t] : tracks_)
        stopTrackStreaming(*t);
    tracks_.clear();
    hasSoloedTracks_ = false;
}

// ─── Transport ───────────────────────────────────────────────────────────────

void AudioMixer::play() {
    std::lock_guard<std::mutex> lock(mutex_);
    isPlaying_ = true;
}

void AudioMixer::pause() {
    std::lock_guard<std::mutex> lock(mutex_);
    isPlaying_ = false;
}

void AudioMixer::seekTo(int64_t framePosition) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (auto& [_, track] : tracks_) {
        int64_t pos = std::clamp(framePosition, static_cast<int64_t>(0), track->numFrames);
        track->playheadFrame = pos;
        track->seekFrameRequested.store(pos);
        for (auto& band : track->eqBands)
            band.resetState();
        if (track->soundTouchProcessor)
            track->soundTouchProcessor->clear();
    }
}

void AudioMixer::scheduleJump(int64_t triggerFrame, int64_t targetFrame) {
    if (targetFrame < 0) targetFrame = 0;
    
    // Both variables are atomic, allowing wait-free setup from main thread
    jumpTargetFrame_.store(targetFrame, std::memory_order_relaxed);
    jumpTriggerFrame_.store(triggerFrame, std::memory_order_relaxed);
}

// ─── Per-Track Parameters ────────────────────────────────────────────────────

void AudioMixer::setVolume(const std::string& id, float volume) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    MixerTrack& track = *(it->second);
    float clamped = std::clamp(volume, 0.0f, 5.0f);  // Headroom up to +13 dB (~4.46 linear)

    if (std::abs(clamped - track.currentGain.load()) < 1e-6f) {
        // Already at target — skip ramp
        track.targetGain.store(clamped);
        track.gainIncrement.store(0.0f);
        track.gainRampSamplesRemaining.store(0);
        return;
    }

    track.targetGain.store(clamped);
    track.gainRampSamplesRemaining.store(gainSmoothSamples_);
    track.gainIncrement.store(
        (track.targetGain.load() - track.currentGain.load()) /
        static_cast<float>(gainSmoothSamples_));
}

void AudioMixer::setPan(const std::string& id, float pan) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    it->second->pan.store(std::clamp(pan, -1.0f, 1.0f));
    computePanGains(*(it->second));
}

void AudioMixer::setMute(const std::string& id, bool muted) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    it->second->isMuted.store(muted);
}

void AudioMixer::setSolo(const std::string& id, bool solo) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    it->second->isSolo.store(solo);

    // Recalculate solo flag from scratch to avoid stale state
    hasSoloedTracks_ = false;
    for (const auto& [_, t] : tracks_) {
        if (t->isSolo.load()) {
            hasSoloedTracks_ = true;
            break;
        }
    }
}

void AudioMixer::setTrackEq(const std::string& id,
                            int bandIndex,
                            int filterType,
                            float frequency,
                            float gainDb,
                            float q) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;
    if (bandIndex < 0 || bandIndex >= kNumEqBands) return;

    BiquadFilter& band = it->second->eqBands[bandIndex];
    band.type      = static_cast<FilterType>(filterType);
    band.frequency = frequency;
    band.gainDb    = gainDb;
    band.q         = q;
    band.active    = true;
    band.computeCoefficients(sampleRate_);

    // Update isEqFlat flag based on bypass conditions per user rules
    bool flat = true;
    for (const auto& b : it->second->eqBands) {
        if (!b.active) continue;
        if ((b.type == FilterType::PEAKING && std::abs(b.gainDb) > 0.01f) ||
            (b.type == FilterType::HIGHPASS && b.frequency > 20.0f) ||
            (b.type == FilterType::LOWPASS && b.frequency < 20000.0f)) {
            flat = false;
            break;
        }
    }
    it->second->isEqFlat = flat;
}

void AudioMixer::setMasterEq(int bandIndex, int filterType, float frequency, float gainDb, float q) {
    std::lock_guard<std::mutex> lock(mutex_);
    // Ensure we have enough bands in vector
    if (masterEqBands_.size() <= (size_t)bandIndex) {
        masterEqBands_.resize(bandIndex + 1);
    }
    
    BiquadFilter& band = masterEqBands_[bandIndex];
    band.type      = static_cast<FilterType>(filterType);
    band.frequency = frequency;
    band.gainDb    = gainDb;
    band.q         = q;
    band.active    = true;
    band.computeCoefficients(sampleRate_);
}

void AudioMixer::setMasterVolume(float volume) {
    masterVolume_.store(std::clamp(volume, 0.0f, 5.0f), std::memory_order_relaxed);  // Headroom up to +13 dB
}

void AudioMixer::setMasterNormalizationGain(float gain) {
    // Clamp to a sane range: 0.0 (silence) to 10.0 (~+20 dB max boost)
    masterNormalizationGain_.store(std::clamp(gain, 0.0f, 10.0f), std::memory_order_relaxed);
}

void AudioMixer::setMetronomeVolume(float volume) {
    metronomeVolume_.store(std::clamp(volume, 0.0f, 5.0f), std::memory_order_relaxed);  // Headroom up to +13 dB
}

void AudioMixer::setMetronomePan(float pan) {
    metronomePan_.store(std::clamp(pan, -1.0f, 1.0f), std::memory_order_relaxed);
}

void AudioMixer::setMetronomeBpm(float bpm) {
    metronomeBpm_.store(std::clamp(bpm, 20.0f, 300.0f), std::memory_order_relaxed);
}

void AudioMixer::setMetronomePlaying(bool playing) {
    isMetronomePlaying_.store(playing, std::memory_order_relaxed);
}

// ─── SoundTouch Setters ───
// These must define new methods in AudioMixer class (will update header via separate tool or assume implicit if I missed it, 
// wait I missed adding them to .cpp, so I am adding them here).
// Note: setTrackTempo/Pitch were not in original .h but requested in prompt.
// I assumed they were effectively needed. I should add them here.

// But wait, the prompt said "Exposição FFI (bridge.cpp)... Chama setTempo() no SoundTouch da track".
// This implies bridge calls mixer. So mixer MUST have these methods.
// I did NOT add them to the header in the previous step?
// Let me check the previous step output for audio_mixer.h.
// I only added fields. I DID NOT add setTrackTempo/Pitch to header.
// I must add them to audio_mixer.cpp AND update header later? 
// Or I can add them to audio_mixer.cpp and rely on me updating the header in next step or assuming.
// Actually, I can use a simpler approach: expose the tracks map? No, encapsulation.
// I will implement them here and I MUST update header.

void AudioMixer::setTrackTempo(const std::string& id, float tempo) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    commandQueue_.push({EngineCommand::SET_TEMPO, id, tempo, 0, {}});
}

void AudioMixer::setTrackPitch(const std::string& id, int semitones) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    commandQueue_.push({EngineCommand::SET_PITCH, id, 0.0f, semitones, {}});
}

void AudioMixer::setTrackClickMap(const std::string& id,
                                   const int32_t* msTimestamps,
                                   int32_t numTimestamps) {
    CommandMessage cmd;
    cmd.type = EngineCommand::SET_CLICK_MAP;
    cmd.trackId = id;
    cmd.intParam = numTimestamps;
    // CRITICAL: Deep-copy the array BEFORE pushing.
    // Dart may free the pointer immediately after this bridge call returns.
    if (msTimestamps && numTimestamps > 0) {
        cmd.intArrayValue.assign(msTimestamps, msTimestamps + numTimestamps);
    }
    std::lock_guard<std::mutex> lock(queueMutex_);
    commandQueue_.push(std::move(cmd));
    LOGD_MIX("setTrackClickMap: queued %d timestamps for track %s", numTimestamps, id.c_str());
}

bool AudioMixer::loadDrumSample(const std::string& id, const std::string& filePath) {
    drwav wav;
    if (!drwav_init_file(&wav, filePath.c_str(), nullptr)) {
        LOGE_MIX("loadDrumSample: failed to open WAV %s", filePath.c_str());
        return false;
    }

    const int32_t numCh = static_cast<int32_t>(wav.channels);
    const uint32_t fileRate = wav.sampleRate;
    const uint64_t totalFrames = wav.totalPCMFrameCount;

    if (numCh < 1 || numCh > 2 || totalFrames == 0) {
        drwav_uninit(&wav);
        return false;
    }

    auto sample = std::make_unique<DrumSample>();
    sample->id = id;
    sample->numChannels = numCh;

    bool needsResample = (fileRate != static_cast<uint32_t>(sampleRate_));
    if (needsResample) {
        const size_t outFrames = static_cast<size_t>(
            static_cast<double>(totalFrames) * static_cast<double>(sampleRate_) / static_cast<double>(fileRate));
        sample->pcmData.resize(outFrames * numCh);
        
        std::vector<float> sourcePcm(totalFrames * numCh);
        drwav_read_pcm_frames_f32(&wav, totalFrames, sourcePcm.data());
        
        resampleFrames(sourcePcm.data(), static_cast<size_t>(totalFrames), numCh,
                      static_cast<int32_t>(fileRate), sampleRate_,
                      sample->pcmData.data(), outFrames);
    } else {
        sample->pcmData.resize(totalFrames * numCh);
        drwav_read_pcm_frames_f32(&wav, totalFrames, sample->pcmData.data());
    }

    drwav_uninit(&wav);

    {
        std::lock_guard<std::mutex> lock(drumMutex_);
        drumSamples_[id] = std::move(sample);
    }

    LOGD_MIX("loadDrumSample: loaded %s (%zu samples) at %d Hz", id.c_str(), sample->pcmData.size(), sampleRate_);
    return true;
}

void AudioMixer::triggerDrumPad(const std::string& id) {
    const DrumSample* target = nullptr;
    {
        std::lock_guard<std::mutex> lock(drumMutex_);
        auto it = drumSamples_.find(id);
        if (it != drumSamples_.end()) {
            target = it->second.get();
        }
    }

    if (!target) return;

    for (auto& voice : drumVoices_) {
        if (voice.sample == nullptr || voice.readIndex.load() >= voice.sample->pcmData.size()) {
            voice.readIndex.store(0, std::memory_order_relaxed);
            // Activation happens here
            voice.sample = target;
            return;
        }
    }
}

void AudioMixer::clearDrumSamples() {
    std::lock_guard<std::mutex> lock(drumMutex_);
    for (auto& voice : drumVoices_) {
        voice.sample = nullptr;
    }
    drumSamples_.clear();
}


// ─── DSP — Core Mix Loop (Wait-Free, Allocation-Free) ────────────────────────

int32_t AudioMixer::process(float* outputL, float* outputR, int32_t numFrames) {
    // Cap to pre-allocated buffer size; never allocate in this path
    if (numFrames <= 0) return 0;
    if (numFrames > kMaxProcessFrames) {
        std::memset(outputL, 0, sizeof(float) * static_cast<size_t>(numFrames));
        std::memset(outputR, 0, sizeof(float) * static_cast<size_t>(numFrames));
        return numFrames;
    }

    // Try to drain command queue (non-blocking)
    std::queue<CommandMessage> localQueue;
    {
        std::unique_lock<std::mutex> qLock(queueMutex_, std::try_to_lock);
        if (qLock.owns_lock())
            std::swap(localQueue, commandQueue_);
    }

    // Audio thread must never block: if we can't get the mixer lock, output silence
    std::unique_lock<std::mutex> lock(mutex_, std::try_to_lock);
    if (!lock.owns_lock()) {
        std::memset(outputL, 0, sizeof(float) * static_cast<size_t>(numFrames));
        std::memset(outputR, 0, sizeof(float) * static_cast<size_t>(numFrames));
        return numFrames;
    }

    // Execute all pending commands
    while (!localQueue.empty()) {
        auto cmd = localQueue.front();
        localQueue.pop();

        switch (cmd.type) {
            case EngineCommand::CLEAR_TRACKS:
                for (auto& [_, t] : tracks_)
                    stopTrackStreaming(*t);
                tracks_.clear();
                hasSoloedTracks_ = false;
                break;

            case EngineCommand::SET_TEMPO: {
                auto it = tracks_.find(cmd.trackId);
                if (it != tracks_.end()) {
                    it->second->tempoFactor = cmd.floatParam;
                    if (it->second->soundTouchProcessor) {
                        it->second->soundTouchProcessor->setTempo(it->second->tempoFactor);
                    }
                }
                break;
            }

            case EngineCommand::SET_PITCH: {
                auto it = tracks_.find(cmd.trackId);
                if (it != tracks_.end()) {
                    it->second->pitchSemiTones = cmd.intParam;
                    if (it->second->soundTouchProcessor) {
                        it->second->soundTouchProcessor->setPitchSemiTones(it->second->pitchSemiTones);
                    }
                }
                break;
            }

            case EngineCommand::SET_CLICK_MAP: {
                LOGD_MIX("DEBUG METRONOMO: Recebido SET_CLICK_MAP para ID: [%s]", cmd.trackId.c_str());
                auto it = tracks_.find(cmd.trackId);
                if (it != tracks_.end()) {
                    LOGD_MIX("DEBUG METRONOMO: SUCESSO! Track ID [%s] encontrada. Setando isClickTrack=true.", cmd.trackId.c_str());
                    auto& track = *it->second;
                    track.clickFrames.clear();
                    track.clickFrames.reserve(cmd.intArrayValue.size());
                    for (const auto ms : cmd.intArrayValue) {
                        // Convert ms to frames: frames = ms * sampleRate / 1000
                        int64_t frame = static_cast<int64_t>(ms) *
                                        static_cast<int64_t>(sampleRate_) / 1000LL;
                        track.clickFrames.push_back(frame);
                    }
                    track.nextClickIndex = 0;
                    track.isClickTrack = true;
                    LOGD_MIX("SET_CLICK_MAP: track %s -> %zu click frames",
                             cmd.trackId.c_str(), track.clickFrames.size());
                } else {
                    LOGE_MIX("DEBUG METRONOMO: FALHA FATAL! ID [%s] nao encontrado no tracks_ map. Total de tracks: %zu",
                             cmd.trackId.c_str(), tracks_.size());
                }
                break;
            }
        }
    }

    // ── Quantized Jump: Check Schedule / Execution ──
    const int64_t currentTrigger = jumpTriggerFrame_.load(std::memory_order_relaxed);
    if (currentTrigger != -1 && !tracks_.empty()) {
        // Use the first track's playhead as the master reference time
        auto firstTrackIt = tracks_.begin();
        if (firstTrackIt != tracks_.end()) {
            const int64_t globalPlayhead = firstTrackIt->second->playheadFrame;
            // If the playhead is exactly at, or slightly passed the trigger point:
            if (globalPlayhead >= currentTrigger) {
                jumpTriggerFrame_.store(-1, std::memory_order_relaxed); // Clear schedule
                jumpRequested_.store(true, std::memory_order_release);  // Fire jump
            }
        }
    }

    // If jump was fired manually or via schedule trigger
    if (jumpRequested_.exchange(false)) {
        isRampingDown_ = true;
        isRampingUp_ = false;
        isWaitingForJump_ = false;
        jumpRampProgress_ = 0;
    }

    if (isWaitingForJump_) {
        // Output silence while waiting for I/O to seek and fill buffers
        std::memset(outputL, 0, sizeof(float) * numFrames);
        std::memset(outputR, 0, sizeof(float) * numFrames);

        // Check if tracks are refilled enough to start ramping up
        bool ready = true;
        for (auto& [_, track] : tracks_) {
            // Need at least one full callback buffer to resume
            if (track->ringBuffer->availableToRead() < static_cast<size_t>(numFrames * track->numChannels)) {
                ready = false;
                break;
            }
        }
        if (ready) {
            isWaitingForJump_ = false;
            isRampingUp_ = true;
            jumpRampProgress_ = 0;
            // Fall through to normal mix loop so we can perform the start of fade-in immediately
        } else {
            return numFrames;
        }
    }

    // Zero output buffers
    std::memset(outputL, 0, sizeof(float) * numFrames);
    std::memset(outputR, 0, sizeof(float) * numFrames);

    // ── Metronome: synthetic click when VS is not playing (lock-free, no allocation) ──
    const bool vsPlaying = isPlaying_ && !tracks_.empty();
    if (!vsPlaying && isMetronomePlaying_.load(std::memory_order_relaxed)) {
        const float bpm = metronomeBpm_.load(std::memory_order_relaxed);
        const float periodFrames = (60.0f / (bpm > 0.1f ? bpm : 120.0f)) *
            static_cast<float>(sampleRate_);
        const float clickDurationFrames = 0.015f * static_cast<float>(sampleRate_); // 15 ms
        const float twoPi = 2.0f * static_cast<float>(M_PI);
        const float phaseIncr = twoPi * 1000.0f / static_cast<float>(sampleRate_);
        const float vol = metronomeVolume_.load(std::memory_order_relaxed);
        const float pan = metronomePan_.load(std::memory_order_relaxed);
        // Constant-power pan: angle in [0, pi/2], L = cos(angle), R = sin(angle)
        const float angle = (pan + 1.0f) * 0.5f * static_cast<float>(M_PI * 0.5);
        const float gainL = std::cos(angle);
        const float gainR = std::sin(angle);

        for (int32_t i = 0; i < numFrames; ++i) {
            if (metronomeClickFramesLeft_ > 0.5f) {
                float envelope = metronomeClickFramesLeft_ / clickDurationFrames;
                if (envelope > 1.0f) envelope = 1.0f;
                float sample = std::sin(metronomeSinePhase_) * envelope * vol;
                outputL[i] += sample * gainL;
                outputR[i] += sample * gainR;
                metronomeClickFramesLeft_ -= 1.0f;
                metronomeSinePhase_ += phaseIncr;
                if (metronomeSinePhase_ >= twoPi) metronomeSinePhase_ -= twoPi;
            } else {
                metronomePhaseFrames_ += 1.0f;
                if (metronomePhaseFrames_ >= periodFrames) {
                    metronomePhaseFrames_ -= periodFrames;
                    metronomeClickFramesLeft_ = clickDurationFrames;
                    metronomeSinePhase_ = 0.0f;
                }
            }
        }
    } else {
        // Advance phase when metronome off so first click is on beat when turned on
        if (!isMetronomePlaying_.load(std::memory_order_relaxed)) {
            const float bpm = metronomeBpm_.load(std::memory_order_relaxed);
            const float periodFrames = (60.0f / (bpm > 0.1f ? bpm : 120.0f)) *
                static_cast<float>(sampleRate_);
            metronomePhaseFrames_ += numFrames;
            while (metronomePhaseFrames_ >= periodFrames) metronomePhaseFrames_ -= periodFrames;
        }
    }

    if (!isPlaying_ || tracks_.empty()) {
        // Apply master volume to metronome-only or silence
        const float mv = masterVolume_.load(std::memory_order_relaxed);
        const float ng = masterNormalizationGain_.load(std::memory_order_relaxed);
        const float totalGain = mv * ng;
        for (int32_t i = 0; i < numFrames; ++i) {
            outputL[i] *= totalGain;
            outputR[i] *= totalGain;
        }
        return numFrames;
    }

    const bool hasSolo = hasSoloedTracks_;

    for (auto& [id, trackPtr] : tracks_) {
        MixerTrack& track = *trackPtr;

        // Seek pending: ioThread will reset ring and seek file. Don't read until done (avoids race with reset).
        if (track.seekFrameRequested.load(std::memory_order_acquire) >= 0) {
            track.playheadFrame = std::min(track.numFrames, track.playheadFrame + numFrames);
            if (track.soundTouchProcessor) track.soundTouchProcessor->clear();
            continue;
        }

        // CRITICAL: effectiveGain for mute/solo — we ALWAYS read from ring buffer and advance playhead.
        // Silenced tracks still consume buffer so they stay in sync when unmuted/unsoloed.
        float effectiveGain = track.currentGain.load(std::memory_order_relaxed);
        if (track.isMuted.load(std::memory_order_relaxed)) effectiveGain = 0.0f;
        if (hasSolo && !track.isSolo.load(std::memory_order_relaxed)) effectiveGain = 0.0f;

        // Hard bypass: pre-rendered live tracks (tempo 1, pitch 0). No SoundTouch, no processBuffer.
        const bool bypassST = (track.tempoFactor == 1.0f && track.pitchSemiTones == 0);

        if (bypassST) {
            // ALWAYS read from ring buffer (underflow = silence). Then apply effectiveGain when mixing.
            const size_t toReadSamples = static_cast<size_t>(numFrames * track.numChannels);
            if (!track.ringBuffer) { track.playheadFrame = std::min(track.numFrames, track.playheadFrame + numFrames); continue; }
            track.ringBuffer->read(track.processBuffer.data(), toReadSamples);
            const float* pcm = track.processBuffer.data();
            const float panL = track.panGainL.load(std::memory_order_relaxed);
            const float panR = track.panGainR.load(std::memory_order_relaxed);
            float trackPeak = 0.0f;

            for (int32_t i = 0; i < numFrames; ++i) {
                float sampleL, sampleR;
                if (track.numChannels == 2) {
                    sampleL = pcm[i * 2];
                    sampleR = pcm[i * 2 + 1];
                } else {
                    sampleL = sampleR = pcm[i];
                }

                // ── Click Track: Hard-Mute + Synth Click ──
                if (track.isClickTrack) {
                    // 1. HARD-MUTE: discard original WAV audio 100%
                    sampleL = 0.0f;
                    sampleR = 0.0f;

                    if (vsPlaying) {
                        // 2. Check if we crossed a beat timestamp
                        bool triggerBeep = false;
                        if (track.nextClickIndex < track.clickFrames.size()) {
                            const int64_t currentAbsoluteFrame = track.playheadFrame + static_cast<int64_t>(i);
                            if (currentAbsoluteFrame >= track.clickFrames[track.nextClickIndex]) {
                                triggerBeep = true;
                                // Sync free-wheel clock so pause hands off seamlessly
                                metronomePhaseFrames_ = -static_cast<float>(i);
                                metronomeClickFramesLeft_ = 0.015f * static_cast<float>(sampleRate_); // 15ms beep
                                metronomeSinePhase_ = 0.0f;
                                track.nextClickIndex++;
                            }
                        }

                        // 3. Synthesize 1kHz sine if envelope is active
                        if (triggerBeep || metronomeClickFramesLeft_ > 0.5f) {
                            const float phaseInc = 1000.0f * 2.0f * static_cast<float>(M_PI) / static_cast<float>(sampleRate_);
                            const float clickSample = std::sin(metronomeSinePhase_);
                            metronomeSinePhase_ += phaseInc;
                            if (metronomeSinePhase_ > 2.0f * static_cast<float>(M_PI))
                                metronomeSinePhase_ -= 2.0f * static_cast<float>(M_PI);

                            // Exponential decay envelope
                            float env = metronomeClickFramesLeft_ / (0.015f * static_cast<float>(sampleRate_));
                            if (env > 1.0f) env = 1.0f;
                            env = env * env;

                            const float vol = metronomeVolume_.load(std::memory_order_relaxed);
                            sampleL = clickSample * env * vol;
                            sampleR = clickSample * env * vol;
                        }
                    }

                    // Decay: unconditional (no UI guard)
                    if (metronomeClickFramesLeft_ > 0.0f) {
                        metronomeClickFramesLeft_ -= 1.0f;
                    }
                }

                if (!track.isEqFlat) {
                    for (auto& band : track.eqBands) {
                        if (band.active) {
                            sampleL = band.processL(sampleL);
                            sampleR = band.processR(sampleR);
                        }
                    }
                }
                sampleL *= effectiveGain;
                sampleR *= effectiveGain;
                outputL[i] += sampleL * panL;
                outputR[i] += sampleR * panR;
                trackPeak = std::max(trackPeak, std::max(std::abs(sampleL), std::abs(sampleR)));
            }
            track.playheadFrame = std::min(track.numFrames, track.playheadFrame + numFrames);
            track.currentPeak.store(trackPeak, std::memory_order_relaxed);

            int32_t rampRem = track.gainRampSamplesRemaining.load(std::memory_order_relaxed);
            if (rampRem > 0) {
                const float inc = track.gainIncrement.load(std::memory_order_relaxed);
                float curGain = track.currentGain.load(std::memory_order_relaxed);
                curGain += inc * numFrames;
                rampRem -= numFrames;
                if (rampRem <= 0) {
                    curGain = track.targetGain.load(std::memory_order_relaxed);
                    rampRem = 0;
                }
                track.currentGain.store(curGain, std::memory_order_relaxed);
                track.gainRampSamplesRemaining.store(rampRem, std::memory_order_relaxed);
            }
            continue;
        }

        // SoundTouch path: tempo/pitch changed on the fly (not used for pre-rendered live set)
        // ALWAYS feed from ring and process; apply effectiveGain when summing to output.
        float* const trackOutput = track.processBuffer.data();
        std::fill(trackOutput, trackOutput + numFrames * 2, 0.0f);
        int samplesReceived = 0;
            // 2. SoundTouch Loop (Strict Sync) — use pre-allocated stMonoInputBuffer
            soundtouch::SoundTouch* st = track.soundTouchProcessor.get();
            if (!st) continue;

            while (samplesReceived < numFrames) {
                const int want = numFrames - samplesReceived;
                const int gotten = static_cast<int>(st->receiveSamples(
                    trackOutput + samplesReceived * 2,
                    static_cast<unsigned int>(want)));
                    if (gotten > 0) {
                    samplesReceived += gotten;
                    } else {
                        // Feed SoundTouch from ring buffer (underflow = silence)
                        if (track.ringBuffer) {
                            const size_t wantSamples = static_cast<size_t>(kStMonoChunkSize) * static_cast<size_t>(track.numChannels);
                            size_t gotSamples = track.ringBuffer->read(track.stMonoInputBuffer.data(), wantSamples);
                            int gotFrames = static_cast<int>(gotSamples / track.numChannels);
                            if (gotFrames > 0) {
                                if (track.numChannels == 2) {
                                    st->putSamples(track.stMonoInputBuffer.data(), static_cast<unsigned int>(gotFrames));
                                } else {
                                    float* stInput = track.stMonoInputBuffer.data();
                                    const float* mono = track.stMonoInputBuffer.data();
                                    for (int i = gotFrames - 1; i >= 0; --i) {
                                        stInput[i * 2] = mono[i];
                                        stInput[i * 2 + 1] = mono[i];
                                    }
                                    st->putSamples(stInput, static_cast<unsigned int>(gotFrames));
                                }
                            } else {
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                }

        float trackPeak = 0.0f;
        const float panL = track.panGainL.load(std::memory_order_relaxed);
        const float panR = track.panGainR.load(std::memory_order_relaxed);

        for (int32_t i = 0; i < numFrames; ++i) {
            float sampleL = trackOutput[i * 2];
            float sampleR = trackOutput[i * 2 + 1];

            // ── Click Track: Hard-Mute + Synth Click (SoundTouch path) ──
            if (track.isClickTrack) {
                sampleL = 0.0f;
                sampleR = 0.0f;

                if (vsPlaying) {
                    bool triggerBeep = false;
                    if (track.nextClickIndex < track.clickFrames.size()) {
                        const int64_t currentAbsoluteFrame = track.playheadFrame + static_cast<int64_t>(i);
                        if (currentAbsoluteFrame >= track.clickFrames[track.nextClickIndex]) {
                            triggerBeep = true;
                            metronomePhaseFrames_ = -static_cast<float>(i);
                            metronomeClickFramesLeft_ = 0.015f * static_cast<float>(sampleRate_);
                            metronomeSinePhase_ = 0.0f;
                            track.nextClickIndex++;
                        }
                    }

                    if (triggerBeep || metronomeClickFramesLeft_ > 0.5f) {
                        const float phaseInc = 1000.0f * 2.0f * static_cast<float>(M_PI) / static_cast<float>(sampleRate_);
                        const float clickSample = std::sin(metronomeSinePhase_);
                        metronomeSinePhase_ += phaseInc;
                        if (metronomeSinePhase_ > 2.0f * static_cast<float>(M_PI))
                            metronomeSinePhase_ -= 2.0f * static_cast<float>(M_PI);

                        float env = metronomeClickFramesLeft_ / (0.015f * static_cast<float>(sampleRate_));
                        if (env > 1.0f) env = 1.0f;
                        env = env * env;

                        const float vol = metronomeVolume_.load(std::memory_order_relaxed);
                        sampleL = clickSample * env * vol;
                        sampleR = clickSample * env * vol;
                    }
                }

                if (metronomeClickFramesLeft_ > 0.0f) {
                    metronomeClickFramesLeft_ -= 1.0f;
                }
            }

            if (!track.isEqFlat) {
                for (auto& band : track.eqBands) {
                    if (band.active) {
                        sampleL = band.processL(sampleL);
                        sampleR = band.processR(sampleR);
                    }
                }
            }
            sampleL *= effectiveGain;
            sampleR *= effectiveGain;
            outputL[i] += sampleL * panL;
            outputR[i] += sampleR * panR;
            trackPeak = std::max(trackPeak, std::max(std::abs(sampleL), std::abs(sampleR)));
        }
        track.currentPeak.store(trackPeak, std::memory_order_relaxed);

        int32_t rampRem = track.gainRampSamplesRemaining.load(std::memory_order_relaxed);
        if (rampRem > 0) {
            const float inc = track.gainIncrement.load(std::memory_order_relaxed);
            float curGain = track.currentGain.load(std::memory_order_relaxed);
            curGain += inc * numFrames;
            rampRem -= numFrames;
            if (rampRem <= 0) {
                curGain = track.targetGain.load(std::memory_order_relaxed);
                rampRem = 0;
            }
            track.currentGain.store(curGain, std::memory_order_relaxed);
            track.gainRampSamplesRemaining.store(rampRem, std::memory_order_relaxed);
        }

        // Frente A: Advance playheadFrame exactly with output numFrames for real-time acoustic sync
        track.playheadFrame += numFrames;
    }

    // ── Master Bus Processing (with Bypass) ──
    bool skipMasterEq = true;
    for (const auto& b : masterEqBands_) {
        if (!b.active) continue;
        if ((b.type == FilterType::PEAKING && std::abs(b.gainDb) > 0.01f) ||
            (b.type == FilterType::HIGHPASS && b.frequency > 20.0f) ||
            (b.type == FilterType::LOWPASS && b.frequency < 20000.0f)) {
            skipMasterEq = false;
            break;
        }
    }
    float masterPeak = 0.0f;

    for (int32_t i = 0; i < numFrames; ++i) {
        float l = outputL[i];
        float r = outputR[i];
        
        if (!skipMasterEq) {
            for (auto& band : masterEqBands_) {
                if (!band.active) continue;
                l = band.processL(l);
                r = band.processR(r);
            }
        }
        
        const float mv = masterVolume_.load(std::memory_order_relaxed);
        const float ng = masterNormalizationGain_.load(std::memory_order_relaxed);
        const float totalGain = mv * ng;
        l *= totalGain;
        r *= totalGain;
        
        outputL[i] = l;
        outputR[i] = r;

        // Master Metering
        masterPeak = std::max(masterPeak, std::abs(l));
        masterPeak = std::max(masterPeak, std::abs(r));

        // Free-wheel: advance invisible clock while VS plays so pause hands off seamlessly
        if (vsPlaying) {
            metronomePhaseFrames_ += 1.0f;
        }
    }

    // ── Drum Sampler mixing (RAM-based, polyphonic) ──
    for (auto& voice : drumVoices_) {
        const DrumSample* sample = voice.sample;
        if (!sample) continue;

        size_t readIdx = voice.readIndex.load(std::memory_order_relaxed);
        size_t totalSamples = sample->pcmData.size();
        if (readIdx >= totalSamples) {
            voice.sample = nullptr;
            continue;
        }

        const int32_t ch = sample->numChannels;
        const float* pcm = sample->pcmData.data();

        for (int32_t i = 0; i < numFrames && readIdx < totalSamples; ++i) {
            if (ch == 1) { // Mono sample
                float s = pcm[readIdx++];
                outputL[i] += s;
                outputR[i] += s;
            } else { // Stereo sample
                outputL[i] += pcm[readIdx++];
                outputR[i] += pcm[readIdx++];
            }
        }
        voice.readIndex.store(readIdx, std::memory_order_relaxed);
    }

    masterPeak_ = masterPeak;

    // ── Quantized Jump: Apply Ramps to final mix ──
    if (isRampingDown_) {
        for (int32_t i = 0; i < numFrames; ++i) {
            float multiplier = 1.0f - (static_cast<float>(jumpRampProgress_) / static_cast<float>(jumpRampFrames_));
            multiplier = std::max(0.0f, multiplier);
            outputL[i] *= multiplier;
            outputR[i] *= multiplier;
            jumpRampProgress_++;
            if (jumpRampProgress_ >= jumpRampFrames_) {
                isRampingDown_ = false;
                isWaitingForJump_ = true;
                // Signal I/O to seek and flush
                int64_t target = jumpTargetFrame_.load();
                for (auto& [_, track] : tracks_) {
                    track->playheadFrame = target;
                    track->seekFrameRequested.store(target);
                    track->ringBuffer->reset();
                    if (track->soundTouchProcessor) track->soundTouchProcessor->clear();
                }
                // Zero remaining frames in this block
                for (int32_t j = i + 1; j < numFrames; ++j) {
                    outputL[j] = 0.0f;
                    outputR[j] = 0.0f;
                }
                break;
            }
        }
    } else if (isRampingUp_) {
        for (int32_t i = 0; i < numFrames; ++i) {
            float multiplier = static_cast<float>(jumpRampProgress_) / static_cast<float>(jumpRampFrames_);
            multiplier = std::min(1.0f, multiplier);
            outputL[i] *= multiplier;
            outputR[i] *= multiplier;
            jumpRampProgress_++;
            if (jumpRampProgress_ >= jumpRampFrames_) {
                isRampingUp_ = false;
                break;
            }
        }
    }

    return numFrames;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

void AudioMixer::computePanGains(MixerTrack& track) {
    // Constant-power panning using cosine/sine law.
    const float p = track.pan.load();
    const float angle =
        (p + 1.0f) * 0.5f * static_cast<float>(M_PI * 0.5);
    track.panGainL.store(std::cos(angle));
    track.panGainR.store(std::sin(angle));
}

bool AudioMixer::isTrackAudible(const MixerTrack& track) const {
    if (track.isMuted.load()) return false;
    if (hasSoloedTracks_ && !track.isSolo.load()) return false;
    return true;
}

int64_t AudioMixer::getPlaybackPosition() const {
    std::lock_guard<std::mutex> lock(mutex_);
    if (tracks_.empty()) return 0;
    // Return the playhead of the first track as the master clock
    return tracks_.begin()->second->playheadFrame;
}

float AudioMixer::getTrackPeak(const std::string& id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it != tracks_.end()) {
        return it->second->currentPeak.load();
    }
    return 0.0f;
}

float AudioMixer::getMasterPeak() const {
    return masterPeak_.load();
}

// ─── Waveform Peak Extraction ────────────────────────────────────────────────

int32_t AudioMixer::getWaveformPeaks(const std::string& id,
                                      float* outPeaks,
                                      int32_t numBins) const {
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = tracks_.find(id);
    if (it == tracks_.end() || numBins <= 0 || outPeaks == nullptr) return 0;

    const MixerTrack& track = *(it->second);
    if (track.numFrames == 0) return 0;

    // Use preDecodedPcm when available (memory-backed); streaming-only tracks have no full PCM.
    const std::vector<float>* src = track.preDecodedPcm.empty() ? nullptr : &track.preDecodedPcm;
    if (!src) return 0;

    const int32_t bins = std::min(numBins, static_cast<int32_t>(track.numFrames));
    const double framesPerBin = static_cast<double>(track.numFrames) / bins;

    for (int32_t b = 0; b < bins; ++b) {
        const int64_t startFrame = static_cast<int64_t>(b * framesPerBin);
        const int64_t endFrame   = static_cast<int64_t>((b + 1) * framesPerBin);

        float peak = 0.0f;
        for (int64_t f = startFrame; f < endFrame && f < track.numFrames; ++f) {
            const size_t idx = static_cast<size_t>(f * track.numChannels);
            for (int32_t ch = 0; ch < track.numChannels; ++ch) {
                if (idx + ch < src->size()) {
                    const float absVal = std::abs((*src)[idx + ch]);
                    if (absVal > peak) peak = absVal;
                }
            }
        }
        outPeaks[b] = std::min(peak, 1.0f);
    }

    return bins;
}
