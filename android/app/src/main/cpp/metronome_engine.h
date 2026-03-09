#ifndef METRONOME_ENGINE_H
#define METRONOME_ENGINE_H

#include <atomic>
#include <cstdint>
#include <vector>
#include <cmath>

class MetronomeEngine {
public:
    MetronomeEngine();
    ~MetronomeEngine() = default;

    void setVolume(float volume) { metronomeVolume_.store(volume); }
    void setPan(float pan) { metronomePan_.store(pan); }
    void setBpm(float bpm) { metronomeBpm_.store(bpm); }
    void setPlaying(bool playing) { isMetronomePlaying_.store(playing); }
    void setSampleRate(int32_t sampleRate) { sampleRate_.store(sampleRate); }

    void processSyntheticClick(float* outputL, float* outputR, int32_t numFrames, 
                               int64_t currentAbsoluteFrame, 
                               const std::vector<int64_t>& clickFrames, 
                               float utilityGain);

    void advancePhaseOnly(int32_t numFrames);

    /// Resets the click index based on a seek position.
    void resetSyncedIndex(int64_t framePosition, const std::vector<int64_t>& clickFrames);

private:
    std::atomic<float> metronomeVolume_{0.8f};
    std::atomic<float> metronomePan_{-1.0f};
    std::atomic<float> metronomeBpm_{120.0f};
    std::atomic<bool> isMetronomePlaying_{false};
    std::atomic<int32_t> sampleRate_{44100};

    size_t nextClickIndex_ = 0;
    float metronomePhaseFrames_ = 0.0f;
    float metronomeClickFramesLeft_ = 0.0f;
    float metronomeSinePhase_ = 0.0f;
};

#endif // METRONOME_ENGINE_H
