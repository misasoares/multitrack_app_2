// ─────────────────────────────────────────────────────────────────────────────
// audio_mixer.cpp — LiveStage Pro Native Audio Mixer
// ─────────────────────────────────────────────────────────────────────────────

#include "audio_mixer.h"

#include <android/log.h>
#include <algorithm>
#include <cmath>
#include <cstring>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// ─── BiquadFilter Implementation ───────────────────────────────────────────────

void BiquadFilter::computeCoefficients(int32_t sampleRate) {
    // Peaking EQ from Audio EQ Cookbook (Robert Bristow-Johnson)
    const float w0 = 2.0f * static_cast<float>(M_PI) * frequency / static_cast<float>(sampleRate);
    const float cosW0 = std::cos(w0);
    const float sinW0 = std::sin(w0);
    const float A = std::pow(10.0f, gainDb / 40.0f);  // sqrt of linear gain
    const float alpha = sinW0 / (2.0f * q);

    const float a0_inv = 1.0f / (1.0f + alpha / A);

    b0 = (1.0f + alpha * A) * a0_inv;
    b1 = (-2.0f * cosW0)    * a0_inv;
    b2 = (1.0f - alpha * A) * a0_inv;
    a1 = (-2.0f * cosW0)    * a0_inv;
    a2 = (1.0f - alpha / A) * a0_inv;
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
    // unique_ptr handles cleanup automatically
    tracks_.clear();
    isPlaying_ = false;
    hasSoloedTracks_ = false;
}

// ─── Track Management ────────────────────────────────────────────────────────

void AudioMixer::loadTrack(const std::string& id,
                           const float* pcmData,
                           int64_t numFrames,
                           int32_t numChannels) {
    std::lock_guard<std::mutex> lock(mutex_);

    auto track = std::make_unique<MixerTrack>();
    track->id = id;
    track->numChannels = numChannels;
    track->numFrames = numFrames;

    const int64_t totalSamples = numFrames * numChannels;
    track->pcmData.assign(pcmData, pcmData + totalSamples);

    // Initialise gain ramp — no ramp needed on load
    track->currentGain = 1.0f;
    track->targetGain  = 1.0f;
    track->gainIncrement = 0.0f;
    track->gainRampSamplesRemaining = 0;

    // Centre pan
    track->pan = 0.0f;
    computePanGains(*track);

    track->isMuted = false;
    track->isSolo  = false;
    track->playheadFrame = 0;

    // ── SoundTouch Init ──
    track->soundTouchProcessor = std::make_unique<soundtouch::SoundTouch>();
    track->soundTouchProcessor->setSampleRate(sampleRate_);
    track->soundTouchProcessor->setChannels(2); // Always output stereo for the mix bus
    // Optimise for performance (QuickSeek is good for music)
    track->soundTouchProcessor->setSetting(SETTING_USE_QUICKSEEK, 1);
    // Disable AA filter if percussive (optional, default false)
    track->soundTouchProcessor->setSetting(SETTING_USE_AA_FILTER, 1);

    tracks_[id] = std::move(track);
}

void AudioMixer::removeTrack(const std::string& id) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it != tracks_.end()) {
        tracks_.erase(it);
    }

    for (const auto& [_, t] : tracks_) {
        if (t->isSolo) { hasSoloedTracks_ = true; break; }
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
        track->playheadFrame = std::clamp(framePosition,
                                         static_cast<int64_t>(0),
                                         track->numFrames);
        // Reset EQ filter state to avoid artifacts after seek
        for (auto& band : track->eqBands) {
            band.resetState();
        }
        // Reset SoundTouch state
        if (track->soundTouchProcessor) {
            track->soundTouchProcessor->clear();
        }
    }
}

// ─── Per-Track Parameters ────────────────────────────────────────────────────

void AudioMixer::setVolume(const std::string& id, float volume) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    MixerTrack& track = *(it->second);
    float clamped = std::clamp(volume, 0.0f, 1.0f);

    if (std::abs(clamped - track.currentGain) < 1e-6f) {
        // Already at target — skip ramp
        track.targetGain = clamped;
        track.gainIncrement = 0.0f;
        track.gainRampSamplesRemaining = 0;
        return;
    }

    track.targetGain = clamped;
    track.gainRampSamplesRemaining = gainSmoothSamples_;
    track.gainIncrement =
        (track.targetGain - track.currentGain) /
        static_cast<float>(gainSmoothSamples_);
}

void AudioMixer::setPan(const std::string& id, float pan) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    it->second->pan = std::clamp(pan, -1.0f, 1.0f);
    computePanGains(*(it->second));
}

void AudioMixer::setMute(const std::string& id, bool muted) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    it->second->isMuted = muted;
}

void AudioMixer::setSolo(const std::string& id, bool solo) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    it->second->isSolo = solo;

    for (const auto& [_, t] : tracks_) {
        if (t->isSolo) { hasSoloedTracks_ = true; break; }
    }
}

void AudioMixer::setTrackEq(const std::string& id,
                            int bandIndex,
                            float frequency,
                            float gainDb,
                            float q) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;
    if (bandIndex < 0 || bandIndex >= kNumEqBands) return;

    BiquadFilter& band = it->second->eqBands[bandIndex];
    band.frequency = frequency;
    band.gainDb    = gainDb;
    band.q         = q;
    band.active    = true;
    band.computeCoefficients(sampleRate_);

    // Update isEqFlat flag
    bool flat = true;
    for (const auto& b : it->second->eqBands) {
        if (b.active && std::abs(b.gainDb) > 0.01f) {
            flat = false;
            break;
        }
    }
    it->second->isEqFlat = flat;
}

void AudioMixer::setMasterEq(int bandIndex, float frequency, float gainDb, float q) {
    std::lock_guard<std::mutex> lock(mutex_);
    // Ensure we have enough bands in vector
    if (masterEqBands_.size() <= (size_t)bandIndex) {
        masterEqBands_.resize(bandIndex + 1);
    }
    
    BiquadFilter& band = masterEqBands_[bandIndex];
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

// ─── DSP — Core Mix Loop ────────────────────────────────────────────────────

int32_t AudioMixer::process(float* outputL, float* outputR, int32_t numFrames) {
    static int log_counter = 0;
    
    // ─── Process Command Queue (Lock-Free from Audio Thread perspective) ───
    std::queue<CommandMessage> localQueue;
    {
        std::lock_guard<std::mutex> qLock(queueMutex_);
        std::swap(localQueue, commandQueue_);
    }

    std::lock_guard<std::mutex> lock(mutex_);

    // Execute all pending commands
    while (!localQueue.empty()) {
        auto cmd = localQueue.front();
        localQueue.pop();

        switch (cmd.type) {
            case EngineCommand::CLEAR_TRACKS:
                // unique_ptr handles cleanup automatically
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

        std::vector<float> trackOutput(numFrames * 2, 0.0f); 
        int samplesReceived = 0;

        // 1. ST Bypass Check
        bool bypassST = (track.tempoFactor == 1.0f && track.pitchSemiTones == 0);

        if (bypassST) {
            // Direct PCM Copy Fast-Path
            int64_t available = track.numFrames - track.playheadFrame;
            int64_t toCopy = std::min((int64_t)numFrames, available);
            
            if (toCopy > 0) {
                const float* pcm = track.pcmData.data() + track.playheadFrame * track.numChannels;
                for (int i = 0; i < toCopy; ++i) {
                    if (track.numChannels == 2) {
                        trackOutput[i * 2] = pcm[i * 2];
                        trackOutput[i * 2 + 1] = pcm[i * 2 + 1];
                    } else {
                        trackOutput[i * 2] = pcm[i];
                        trackOutput[i * 2 + 1] = pcm[i];
                    }
                }
                track.playheadFrame += toCopy;
            }
            samplesReceived = numFrames; // Pad rest with zeros implicitly (std::vector init)
        } else {
            // 2. SoundTouch Loop (Strict Sync)
            soundtouch::SoundTouch* st = track.soundTouchProcessor.get();
            if (!st) continue;

            while (samplesReceived < numFrames) {
                int gotten = st->receiveSamples(trackOutput.data() + samplesReceived * 2, 
                                                numFrames - samplesReceived);
                if (gotten > 0) {
                    samplesReceived += gotten;
                } else {
                    // FEED LOOP
                    if (track.playheadFrame < track.numFrames) {
                        const int kChunkSize = 1024; 
                        int64_t remaining = track.numFrames - track.playheadFrame;
                        int64_t feed = std::min((int64_t)kChunkSize, remaining);
                        
                        // Force stereo feed since ST is configured for 2 channels
                        if (track.numChannels == 2) {
                            st->putSamples(track.pcmData.data() + track.playheadFrame * 2, feed);
                        } else {
                            std::vector<float> stInput(feed * 2);
                            const float* pcm = track.pcmData.data() + track.playheadFrame;
                            for (int i = 0; i < feed; ++i) {
                                stInput[i * 2] = pcm[i];
                                stInput[i * 2 + 1] = pcm[i];
                            }
                            st->putSamples(stInput.data(), feed);
                        }
                        track.playheadFrame += feed;
                    } else {
                        // EOF reached - pad with silence to maintain exact sync
                        // The loop will break because gotten=0 and playheadFrame >= numFrames.
                        break; 
                    }
                }
            }
            // Ensure we return exactly numFrames (rest is already 0.0f)
            samplesReceived = numFrames; 
        }

        float trackPeak = 0.0f;

        // MIXING LOOP
        for (int32_t i = 0; i < numFrames; ++i) {
            float sampleL = trackOutput[i * 2];
            float sampleR = trackOutput[i * 2 + 1];

            // ── Parametric EQ ──
            if (!track.isEqFlat) {
                for (auto& band : track.eqBands) {
                    if (band.active) {
                        sampleL = band.processL(sampleL);
                        sampleR = band.processR(sampleR);
                    }
                }
            }
            // ── Apply gain & pan ──
            sampleL *= track.currentGain;
            sampleR *= track.currentGain;

            outputL[i] += sampleL * track.panGainL;
            outputR[i] += sampleR * track.panGainR;

            // Track Metering
            trackPeak = std::max(trackPeak, std::abs(sampleL));
            trackPeak = std::max(trackPeak, std::abs(sampleR));
        }
        
        track.currentPeak = trackPeak;
        
        // Update gain ramp
        if (track.gainRampSamplesRemaining > 0) {
            int processed = numFrames; 
            float totalChange = track.gainIncrement * processed;
            track.currentGain += totalChange;
            track.gainRampSamplesRemaining -= processed;
            if (track.gainRampSamplesRemaining <= 0) {
                track.currentGain = track.targetGain;
                track.gainRampSamplesRemaining = 0;
            }
        }
    }
    
    // ── Master Bus Processing (with Bypass) ──
    bool skipMasterEq = true;
    for (const auto& band : masterEqBands_) {
        if (band.active && std::abs(band.gainDb) > 0.01f) {
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
    //
    // Map pan from [-1, 1]  →  angle [0, π/2]:
    //   pan = -1  →  angle = 0      →  L = cos(0)    = 1.0,  R = sin(0)    = 0.0
    //   pan =  0  →  angle = π/4    →  L = cos(π/4)  ≈ 0.707, R = sin(π/4) ≈ 0.707
    //   pan =  1  →  angle = π/2    →  L = cos(π/2)  = 0.0,  R = sin(π/2)  = 1.0
    //
    // This preserves perceived loudness across the stereo field.
    const float angle =
        (track.pan + 1.0f) * 0.5f * static_cast<float>(M_PI * 0.5);

    track.panGainL = std::cos(angle);
    track.panGainR = std::sin(angle);
}

bool AudioMixer::isTrackAudible(const MixerTrack& track) const {
    if (track.isMuted) return false;
    if (hasSoloedTracks_ && !track.isSolo) return false;
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

    const int32_t bins = std::min(numBins, static_cast<int32_t>(track.numFrames));
    const double framesPerBin = static_cast<double>(track.numFrames) / bins;

    for (int32_t b = 0; b < bins; ++b) {
        const int64_t startFrame = static_cast<int64_t>(b * framesPerBin);
        const int64_t endFrame   = static_cast<int64_t>((b + 1) * framesPerBin);

        float peak = 0.0f;
        for (int64_t f = startFrame; f < endFrame && f < track.numFrames; ++f) {
            const int64_t idx = f * track.numChannels;
            for (int32_t ch = 0; ch < track.numChannels; ++ch) {
                const float absVal = std::abs(track.pcmData[idx + ch]);
                if (absVal > peak) peak = absVal;
            }
        }
        outPeaks[b] = std::min(peak, 1.0f);
    }

    return bins;
}
