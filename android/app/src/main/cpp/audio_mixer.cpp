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
    
    // unique_ptr handles cleanup automatically
    tracks_.clear();

    isPlaying_ = false;
    hasSoloedTracks_ = false;
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

// ─── IO thread: fill ring from file or from preDecodedPcm ──────────────────────

static void runIoThread(MixerTrack* track, int32_t sampleRate) {
    const size_t chunkSamples = kIoChunkSamples;
    std::vector<float> chunk(chunkSamples, 0.0f);
    drwav* wav = static_cast<drwav*>(track->wavFileHandle);
    const int32_t numCh = track->numChannels;

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

        if (track->ringBuffer->availableToWrite() < chunkSamples) {
            // When disk streaming (wav), sleep less so we refill faster under
            // SoundTouch tempo (consumer drains ring faster). Memory path keeps 5ms.
            const auto delayMs = wav ? 2 : 5;
            std::this_thread::sleep_for(std::chrono::milliseconds(delayMs));
            continue;
        }

        size_t written = 0;
        if (wav) {
            drwav_uint64 toRead = chunkSamples / static_cast<drwav_uint64>(numCh);
            if (toRead > 0) {
                drwav_uint64 got = drwav_read_pcm_frames_f32(wav, toRead, chunk.data());
                if (got > 0)
                    written = track->ringBuffer->write(chunk.data(), static_cast<size_t>(got * numCh));
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
    // If file sample rate differs from mixer, fall back to full decode (caller will retry with decode path)
    if (fileRate != static_cast<uint32_t>(sampleRate_)) {
        drwav_uninit(wav);
        delete wav;
        LOGD_MIX("loadTrackFromFile: sample rate mismatch (%u vs %d), use decode path", fileRate, sampleRate_);
        return false;
    }

    auto track = std::make_unique<MixerTrack>();
    track->id = id;
    track->numChannels = numCh;
    track->numFrames = totalFrames;
    track->wavFileHandle = wav;

    size_t ringCapacity = static_cast<size_t>(sampleRate_ * numCh * kRingBufferSeconds);
    if (ringCapacity < 4096) ringCapacity = 4096;
    track->ringBuffer = std::make_unique<LockFreeRingBuffer>(ringCapacity);

    // Pre-fill first kPreFillSeconds for instant play
    size_t preFillFrames = static_cast<size_t>(sampleRate_ * kPreFillSeconds);
    if (preFillFrames > static_cast<size_t>(totalFrames)) preFillFrames = static_cast<size_t>(totalFrames);
    std::vector<float> preFill(preFillFrames * numCh, 0.0f);
    drwav_uint64 got = drwav_read_pcm_frames_f32(wav, preFillFrames, preFill.data());
    if (got > 0)
        track->ringBuffer->write(preFill.data(), static_cast<size_t>(got * numCh));

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
    LOGD_MIX("loadTrackFromFile: instant load %s, %lld frames", filePath.c_str(), (long long)totalFrames);
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
    std::lock_guard<std::mutex> lock(queueMutex_);
    commandQueue_.push({EngineCommand::CLEAR_TRACKS, "", 0.0f, 0});
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

// ─── Per-Track Parameters ────────────────────────────────────────────────────

void AudioMixer::setVolume(const std::string& id, float volume) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    MixerTrack& track = *(it->second);
    float clamped = std::clamp(volume, 0.0f, 1.0f);

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
    std::lock_guard<std::mutex> lock(mutex_);
    masterVolume_ = std::clamp(volume, 0.0f, 1.0f);
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
    commandQueue_.push({EngineCommand::SET_TEMPO, id, tempo, 0});
}

void AudioMixer::setTrackPitch(const std::string& id, int semitones) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    commandQueue_.push({EngineCommand::SET_PITCH, id, 0.0f, semitones});
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
        }
    }

    // Zero output buffers
    std::memset(outputL, 0, sizeof(float) * numFrames);
    std::memset(outputR, 0, sizeof(float) * numFrames);



    if (!isPlaying_ || tracks_.empty()) return numFrames;

    for (auto& [id, trackPtr] : tracks_) {
        MixerTrack& track = *trackPtr;

        // Seek pending: ioThread will reset ring and seek file. Don't read until done (avoids race with reset).
        if (track.seekFrameRequested.load(std::memory_order_acquire) >= 0) {
            track.playheadFrame = std::min(track.numFrames, track.playheadFrame + numFrames);
            if (track.soundTouchProcessor) track.soundTouchProcessor->clear();
            continue;
        }

        if (!isTrackAudible(track)) {
            // Even if not audible, we MUST advance the playhead to keep sync
            // unless we are paused (but we checked isPlaying_ above).
            // However, SoundTouch bypass vs non-bypass complicates silent advance.
            // For stability, we advance playhead strictly based on numFrames.
            if (track.tempoFactor == 1.0f && track.pitchSemiTones == 0) {
                track.playheadFrame = std::min(track.numFrames, track.playheadFrame + numFrames);
            } else {
                // If using SoundTouch, we'd need to process and discard to maintain exact time,
                // but since it's muted, we can approximate by advancing playhead by (numFrames * tempo).
                track.playheadFrame = std::min(track.numFrames, 
                    track.playheadFrame + static_cast<int64_t>(numFrames * track.tempoFactor));
                if (track.soundTouchProcessor) track.soundTouchProcessor->clear();
            }
            continue;
        }

        // Hard bypass: pre-rendered live tracks (tempo 1, pitch 0). No SoundTouch, no processBuffer.
        const bool bypassST = (track.tempoFactor == 1.0f && track.pitchSemiTones == 0);

        if (bypassST) {
            // Fast path: read from ring buffer (underflow = silence), then volume + pan + optional EQ
            const size_t toReadSamples = static_cast<size_t>(numFrames * track.numChannels);
            if (!track.ringBuffer) { track.playheadFrame = std::min(track.numFrames, track.playheadFrame + numFrames); continue; }
            track.ringBuffer->read(track.processBuffer.data(), toReadSamples);
            const float* pcm = track.processBuffer.data();
            const float gain = track.currentGain.load(std::memory_order_relaxed);
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
                if (!track.isEqFlat) {
                    for (auto& band : track.eqBands) {
                        if (band.active) {
                            sampleL = band.processL(sampleL);
                            sampleR = band.processR(sampleR);
                        }
                    }
                }
                sampleL *= gain;
                sampleR *= gain;
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
                                track.playheadFrame = std::min(track.numFrames, track.playheadFrame + gotFrames);
                            } else {
                                break;
                            }
                        } else {
                            break;
                        }
                    }
                }

        float trackPeak = 0.0f;
        const float gain = track.currentGain.load(std::memory_order_relaxed);
        const float panL = track.panGainL.load(std::memory_order_relaxed);
        const float panR = track.panGainR.load(std::memory_order_relaxed);

        for (int32_t i = 0; i < numFrames; ++i) {
            float sampleL = trackOutput[i * 2];
            float sampleR = trackOutput[i * 2 + 1];
            if (!track.isEqFlat) {
                for (auto& band : track.eqBands) {
                    if (band.active) {
                        sampleL = band.processL(sampleL);
                        sampleR = band.processR(sampleR);
                    }
                }
            }
            sampleL *= gain;
            sampleR *= gain;
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
        
        l *= masterVolume_;
        r *= masterVolume_;
        
        outputL[i] = l;
        outputR[i] = r;

        // Master Metering
        masterPeak = std::max(masterPeak, std::abs(l));
        masterPeak = std::max(masterPeak, std::abs(r));
    }

    masterPeak_ = masterPeak;

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
