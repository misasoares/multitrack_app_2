#include "drum_sampler.h"
#include "libs/dr_wav.h"
#include <algorithm>
#include <cmath>

#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "DrumSampler"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#else
#define LOGD(...)
#define LOGE(...)
#endif

DrumSampler::DrumSampler() {
    std::lock_guard<std::mutex> lock(drumMutex_);
    drumVoices_.clear();
    for (int i = 0; i < 32; ++i) {
        drumVoices_.push_back(std::make_unique<DrumVoice>());
    }
}

bool DrumSampler::loadDrumSample(const std::string& id, const std::string& filePath) {
    LOGD("loadDrumSample: %s from %s", id.c_str(), filePath.c_str());

    drwav wav;
    if (!drwav_init_file(&wav, filePath.c_str(), nullptr)) {
        LOGE("loadDrumSample: failed to open %s", filePath.c_str());
        return false;
    }

    auto sample = std::make_unique<DrumSample>();
    sample->id = id;
    sample->numChannels = wav.channels;
    sample->pcmData.resize(wav.totalPCMFrameCount * wav.channels);
    drwav_read_pcm_frames_f32(&wav, wav.totalPCMFrameCount, sample->pcmData.data());
    drwav_uninit(&wav);

    std::lock_guard<std::mutex> lock(drumMutex_);
    drumSamples_[id] = std::move(sample);
    return true;
}

void DrumSampler::setDrumPadParams(const std::string& id, float volume, float pan) {
    std::lock_guard<std::mutex> lock(drumMutex_);
    drumPadSettings_[id] = {volume, pan};
}

void DrumSampler::triggerDrumPad(const std::string& id) {
    std::lock_guard<std::mutex> lock(drumMutex_);
    auto it = drumSamples_.find(id);
    if (it == drumSamples_.end()) return;

    float vol = 1.0f;
    float pan = 0.0f;
    auto sIt = drumPadSettings_.find(id);
    if (sIt != drumPadSettings_.end()) {
        vol = sIt->second.first;
        pan = sIt->second.second;
    }

    // Constant-power pan
    const float angle = (pan + 1.0f) * 0.5f * 1.570796f; // PI/2
    float panL = std::cos(angle);
    float panR = std::sin(angle);

    for (auto& voice : drumVoices_) {
        if (!voice->isActive()) {
            voice->sample = it->second.get();
            voice->volume = vol;
            voice->panL = panL;
            voice->panR = panR;
            voice->readIndex.store(0);
            return;
        }
    }
}

void DrumSampler::clearDrumSamples() {
    std::lock_guard<std::mutex> lock(drumMutex_);
    for (auto& voice : drumVoices_) voice->sample = nullptr;
    drumSamples_.clear();
}

int32_t DrumSampler::processMixed(float* outputL, float* outputR, int32_t numFrames) {
    for (auto& voicePtr : drumVoices_) {
        const DrumSample* sample = voicePtr->sample;
        if (!sample) continue;

        size_t readIdx = voicePtr->readIndex.load(std::memory_order_relaxed);
        size_t totalSamples = sample->pcmData.size();
        if (readIdx >= totalSamples) {
            voicePtr->sample = nullptr;
            continue;
        }

        const int32_t ch = sample->numChannels;
        const float* pcm = sample->pcmData.data();
        const float v = voicePtr->volume;
        const float pL = voicePtr->panL;
        const float pR = voicePtr->panR;

        for (int32_t i = 0; i < numFrames && readIdx < totalSamples; ++i) {
            if (ch == 1) { // Mono sample
                float s = pcm[readIdx++];
                outputL[i] += s * v * pL;
                outputR[i] += s * v * pR;
            } else { // Stereo sample
                float sL = pcm[readIdx++];
                float sR = pcm[readIdx++];
                outputL[i] += sL * v * pL;
                outputR[i] += sR * v * pR;
            }
        }
        voicePtr->readIndex.store(readIdx, std::memory_order_relaxed);
    }
    return numFrames;
}
