#include "metronome_engine.h"
#include <cmath>
#include <algorithm>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

MetronomeEngine::MetronomeEngine() = default;

void MetronomeEngine::processSyntheticClick(float* outputL, float* outputR, int32_t numFrames,
                                            int32_t sampleRate, int64_t currentAbsoluteFrame,
                                            const std::vector<int64_t>& clickFrames,
                                            size_t& nextClickIndex,
                                            float utilityGain) {
    const float bpm = metronomeBpm_.load(std::memory_order_relaxed);
    const float periodFrames = (60.0f / (bpm > 0.1f ? bpm : 120.0f)) * static_cast<float>(sampleRate);
    const float clickDurationFrames = 0.015f * static_cast<float>(sampleRate);
    const float twoPi = 2.0f * static_cast<float>(M_PI);
    const float phaseIncr = twoPi * 1000.0f / static_cast<float>(sampleRate);
    const float vol = metronomeVolume_.load(std::memory_order_relaxed);
    const float pan = metronomePan_.load(std::memory_order_relaxed);

    const float angle = (pan + 1.0f) * 0.5f * static_cast<float>(M_PI * 0.5);
    const float gainL = std::cos(angle);
    const float gainR = std::sin(angle);

    if (clickFrames.empty()) {
        // Mode 1: Free-wheel (VS stopped or no click map)
        if (!isMetronomePlaying_.load(std::memory_order_relaxed)) {
            advancePhaseOnly(numFrames, sampleRate);
            return;
        }

        for (int32_t i = 0; i < numFrames; ++i) {
            if (metronomeClickFramesLeft_ > 0.5f) {
                float envelope = metronomeClickFramesLeft_ / clickDurationFrames;
                if (envelope > 1.0f) envelope = 1.0f;
                float sample = std::sin(metronomeSinePhase_) * envelope * vol * utilityGain;
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
        // Mode 2: Synced with VS (clickFrames provided)
        for (int32_t i = 0; i < numFrames; ++i) {
            bool triggerBeep = false;
            if (nextClickIndex < clickFrames.size()) {
                const int64_t frameNow = currentAbsoluteFrame + static_cast<int64_t>(i);
                if (frameNow >= clickFrames[nextClickIndex]) {
                    triggerBeep = true;
                    // Sync free-wheel clock
                    metronomePhaseFrames_ = -static_cast<float>(i);
                    metronomeClickFramesLeft_ = clickDurationFrames;
                    metronomeSinePhase_ = 0.0f;
                    nextClickIndex++;
                }
            }

            if (triggerBeep || metronomeClickFramesLeft_ > 0.5f) {
                const float clickSample = std::sin(metronomeSinePhase_);
                metronomeSinePhase_ += phaseIncr;
                if (metronomeSinePhase_ > twoPi) metronomeSinePhase_ -= twoPi;

                float env = metronomeClickFramesLeft_ / clickDurationFrames;
                if (env > 1.0f) env = 1.0f;
                env = env * env; // Exponential decay

                float sample = clickSample * env * vol * utilityGain;
                outputL[i] += sample * gainL;
                outputR[i] += sample * gainR;
            }

            if (metronomeClickFramesLeft_ > 0.0f) {
                metronomeClickFramesLeft_ -= 1.0f;
            }
        }
    }
}

void MetronomeEngine::advancePhaseOnly(int32_t numFrames, int32_t sampleRate) {
    const float bpm = metronomeBpm_.load(std::memory_order_relaxed);
    if (bpm <= 0.1f) return;
    const float periodFrames = (60.0f / bpm) * static_cast<float>(sampleRate);
    metronomePhaseFrames_ += static_cast<float>(numFrames);
    while (metronomePhaseFrames_ >= periodFrames) metronomePhaseFrames_ -= periodFrames;
}
