#ifndef DRUM_SAMPLER_H
#define DRUM_SAMPLER_H

#include <string>
#include <vector>
#include <unordered_map>
#include <memory>
#include <mutex>
#include <atomic>

// ─── Drum Rack ───────────────────────────────────────────────────────────────

struct DrumSample {
    std::string id;
    int32_t numChannels = 0;
    std::vector<float> pcmData;
};

struct DrumVoice {
    const DrumSample* sample = nullptr;
    std::atomic<size_t> readIndex{0};
    float volume = 1.0f;
    float panL = 0.707f;
    float panR = 0.707f;

    bool isActive() const {
        return sample != nullptr && readIndex.load() < sample->pcmData.size();
    }
};

class DrumSampler {
public:
    DrumSampler();
    ~DrumSampler() = default;

    bool loadDrumSample(const std::string& id, const std::string& filePath);
    void setDrumPadParams(const std::string& id, float volume, float pan);
    void triggerDrumPad(const std::string& id);
    void clearDrumSamples();

    int32_t processMixed(float* outputL, float* outputR, int32_t numFrames);

private:
    std::unordered_map<std::string, std::pair<float, float>> drumPadSettings_;
    std::unordered_map<std::string, std::unique_ptr<DrumSample>> drumSamples_;
    std::vector<std::unique_ptr<DrumVoice>> drumVoices_;
    mutable std::mutex drumMutex_;
};

#endif // DRUM_SAMPLER_H
