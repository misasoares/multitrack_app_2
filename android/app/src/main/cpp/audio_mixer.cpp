// ─────────────────────────────────────────────────────────────────────────────
// audio_mixer.cpp — LiveStage Pro Native Audio Mixer
// ─────────────────────────────────────────────────────────────────────────────

#include "audio_mixer.h"

#include <algorithm>
#include <cmath>
#include <cstring>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// ─── Lifecycle ───────────────────────────────────────────────────────────────

AudioMixer::AudioMixer() = default;
AudioMixer::~AudioMixer() { dispose(); }

void AudioMixer::init(int32_t sampleRate) {
    std::lock_guard<std::mutex> lock(mutex_);
    sampleRate_ = sampleRate > 0 ? sampleRate : kDefaultSampleRate;
    gainSmoothSamples_ =
        static_cast<int32_t>(kGainSmoothingSeconds * static_cast<float>(sampleRate_));
    if (gainSmoothSamples_ < 1) gainSmoothSamples_ = 1;

    tracks_.clear();
    isPlaying_ = false;
    hasSoloedTracks_ = false;
}

void AudioMixer::dispose() {
    std::lock_guard<std::mutex> lock(mutex_);
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

    MixerTrack track;
    track.id = id;
    track.numChannels = numChannels;
    track.numFrames = numFrames;

    const int64_t totalSamples = numFrames * numChannels;
    track.pcmData.assign(pcmData, pcmData + totalSamples);

    // Initialise gain ramp — no ramp needed on load
    track.currentGain = 1.0f;
    track.targetGain  = 1.0f;
    track.gainIncrement = 0.0f;
    track.gainRampSamplesRemaining = 0;

    // Centre pan
    track.pan = 0.0f;
    computePanGains(track);

    track.isMuted = false;
    track.isSolo  = false;
    track.playheadFrame = 0;

    tracks_[id] = std::move(track);
}

void AudioMixer::removeTrack(const std::string& id) {
    std::lock_guard<std::mutex> lock(mutex_);
    tracks_.erase(id);

    // Recompute solo cache
    hasSoloedTracks_ = false;
    for (const auto& [_, t] : tracks_) {
        if (t.isSolo) { hasSoloedTracks_ = true; break; }
    }
}

void AudioMixer::removeAllTracks() {
    std::lock_guard<std::mutex> lock(mutex_);
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
        track.playheadFrame = std::clamp(framePosition,
                                         static_cast<int64_t>(0),
                                         track.numFrames);
    }
}

// ─── Per-Track Parameters ────────────────────────────────────────────────────

void AudioMixer::setVolume(const std::string& id, float volume) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    MixerTrack& track = it->second;
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

    it->second.pan = std::clamp(pan, -1.0f, 1.0f);
    computePanGains(it->second);
}

void AudioMixer::setMute(const std::string& id, bool muted) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    it->second.isMuted = muted;
}

void AudioMixer::setSolo(const std::string& id, bool solo) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = tracks_.find(id);
    if (it == tracks_.end()) return;

    it->second.isSolo = solo;

    // Recompute cached solo flag
    hasSoloedTracks_ = false;
    for (const auto& [_, t] : tracks_) {
        if (t.isSolo) { hasSoloedTracks_ = true; break; }
    }
}

// ─── DSP — Core Mix Loop ────────────────────────────────────────────────────

int32_t AudioMixer::process(float* outputL, float* outputR, int32_t numFrames) {
    std::lock_guard<std::mutex> lock(mutex_);

    // Zero output buffers
    std::memset(outputL, 0, sizeof(float) * numFrames);
    std::memset(outputR, 0, sizeof(float) * numFrames);

    if (!isPlaying_ || tracks_.empty()) return numFrames;

    for (auto& [_, track] : tracks_) {
        if (!isTrackAudible(track)) continue;

        for (int32_t i = 0; i < numFrames; ++i) {
            if (track.playheadFrame >= track.numFrames) break;

            // ── Gain Smoothing (per-sample ramp) ──
            if (track.gainRampSamplesRemaining > 0) {
                track.currentGain += track.gainIncrement;
                track.gainRampSamplesRemaining--;

                if (track.gainRampSamplesRemaining == 0) {
                    // Snap to target to avoid float drift
                    track.currentGain = track.targetGain;
                }
            }

            // ── Read source sample(s) ──
            float sampleL, sampleR;
            const int64_t sampleIndex = track.playheadFrame * track.numChannels;

            if (track.numChannels == 2) {
                sampleL = track.pcmData[sampleIndex];
                sampleR = track.pcmData[sampleIndex + 1];
            } else {
                // Mono → duplicate to both channels
                sampleL = track.pcmData[sampleIndex];
                sampleR = sampleL;
            }

            // ── Apply gain ──
            sampleL *= track.currentGain;
            sampleR *= track.currentGain;

            // ── Apply constant-power panning ──
            outputL[i] += sampleL * track.panGainL;
            outputR[i] += sampleR * track.panGainR;

            track.playheadFrame++;
        }
    }

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
