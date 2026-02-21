#include "audio_renderer.h"
#include "audio_decoder.h"
#include "SoundTouch.h"
#include "libs/dr_wav.h"
#include <thread>
#include <mutex>
#include <map>
#include <algorithm>
#include <cmath>

#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "AudioRenderer"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#else
#define LOGD(...)
#define LOGE(...)
#endif

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// ─── Internal EQ Helper (Isolated Biquad) ────────────────────────────────────

struct RendererBiquad {
    float b0 = 1.0f, b1 = 0.0f, b2 = 0.0f;
    float a1 = 0.0f, a2 = 0.0f;
    float z1L = 0.0f, z2L = 0.0f;
    float z1R = 0.0f, z2R = 0.0f;

    void compute(float freq, float gainDb, float q, int sampleRate) {
        const float w0 = 2.0f * (float)M_PI * freq / (float)sampleRate;
        const float cosW0 = std::cos(w0);
        const float sinW0 = std::sin(w0);
        const float A = std::pow(10.0f, gainDb / 40.0f);
        const float alpha = sinW0 / (2.0f * q);
        const float a0_inv = 1.0f / (1.0f + alpha / A);

        b0 = (1.0f + alpha * A) * a0_inv;
        b1 = (-2.0f * cosW0)    * a0_inv;
        b2 = (1.0f - alpha * A) * a0_inv;
        a1 = (-2.0f * cosW0)    * a0_inv;
        a2 = (1.0f - alpha / A) * a0_inv;
    }

    float processL(float in) {
        float out = b0 * in + z1L;
        z1L = b1 * in - a1 * out + z2L;
        z2L = b2 * in - a2 * out;
        return out;
    }

    float processR(float in) {
        float out = b0 * in + z1R;
        z1R = b1 * in - a1 * out + z2R;
        z2R = b2 * in - a2 * out;
        return out;
    }
};

// ─── Progress Tracking ───────────────────────────────────────────────────────

static std::map<std::string, float> g_progressMap;
static std::map<std::string, std::atomic<bool>*> g_cancelFlags;
static std::mutex g_progressMutex;

float getRenderProgress(std::string trackId) {
    std::lock_guard<std::mutex> lock(g_progressMutex);
    if (g_progressMap.find(trackId) == g_progressMap.end()) return 0.0f;
    return g_progressMap[trackId];
}

void cancelRender(std::string trackId) {
    std::lock_guard<std::mutex> lock(g_progressMutex);
    if (g_cancelFlags.count(trackId)) {
        g_cancelFlags[trackId]->store(true);
    }
}

static void updateProgress(std::string trackId, float progress) {
    std::lock_guard<std::mutex> lock(g_progressMutex);
    g_progressMap[trackId] = progress;
}

static void registerCancelFlag(std::string trackId, std::atomic<bool>* flag) {
    std::lock_guard<std::mutex> lock(g_progressMutex);
    g_cancelFlags[trackId] = flag;
}

static void unregisterCancelFlag(std::string trackId) {
    std::lock_guard<std::mutex> lock(g_progressMutex);
    g_cancelFlags.erase(trackId);
}

// ─── Worker Function ─────────────────────────────────────────────────────────

static void renderWorker(
    std::string trackId,
    std::string inputPath,
    std::string outputPath,
    float tempo,
    float pitch,
    std::vector<EqBand> eqBands
) {
    LOGD("Starting offline render for %s -> %s", inputPath.c_str(), outputPath.c_str());
    updateProgress(trackId, 0.01f);

    std::atomic<bool> cancelFlag(false);
    registerCancelFlag(trackId, &cancelFlag);

    // RAII for cleanup
    auto cleanup = [&]() {
        unregisterCancelFlag(trackId);
        if (cancelFlag.load()) {
            // Delete incomplete file
            std::remove(outputPath.c_str());
            updateProgress(trackId, -2.0f); // -2.0 = Cancelled
            LOGD("Offline render cancelled and file deleted for %s", trackId.c_str());
        }
    };

    // 1. Decode Source
    DecodedAudio audio = decodeAudioFile(inputPath, &cancelFlag);
    if (cancelFlag.load()) { cleanup(); return; }
    
    if (!audio.success) {
        LOGE("Render failed: could not decode %s - %s", inputPath.c_str(), audio.error.c_str());
        updateProgress(trackId, -1.0f); // Error state
        unregisterCancelFlag(trackId);
        return;
    }

    // 2. Setup SoundTouch
    soundtouch::SoundTouch st;
    st.setSampleRate(audio.sampleRate);
    st.setChannels(audio.numChannels);
    st.setTempo(tempo);
    st.setPitchSemiTones(pitch);
    st.setSetting(SETTING_USE_QUICKSEEK, 1);
    st.setSetting(SETTING_USE_AA_FILTER, 1);

    // 3. Setup EQ
    std::vector<RendererBiquad> filters;
    for (const auto& band : eqBands) {
        if (std::abs(band.gainDb) < 0.01f) continue;
        RendererBiquad filter;
        filter.compute(band.frequency, band.gainDb, band.q, audio.sampleRate);
        filters.push_back(filter);
    }

    // 4. Setup WAV Writer (dr_wav)
    drwav wav;
    drwav_data_format format;
    format.container = drwav_container_riff;
    format.format = DR_WAVE_FORMAT_IEEE_FLOAT; // 32-bit float for high quality baking
    format.channels = audio.numChannels;
    format.sampleRate = audio.sampleRate;
    format.bitsPerSample = 32;

    if (!drwav_init_file_write(&wav, outputPath.c_str(), &format, nullptr)) {
        LOGE("Render failed: could not open %s for writing", outputPath.c_str());
        updateProgress(trackId, -1.0f);
        unregisterCancelFlag(trackId);
        return;
    }

    // 5. Processing Loop
    const int CHUNK_SIZE = 4096;
    int64_t framesProcessed = 0;
    std::vector<float> outputBuffer(CHUNK_SIZE * audio.numChannels);

    while (framesProcessed < audio.numFrames && !cancelFlag.load()) {
        int64_t remaining = audio.numFrames - framesProcessed;
        int64_t toFeed = std::min((int64_t)CHUNK_SIZE, remaining);

        // Put samples into SoundTouch
        st.putSamples(audio.pcmData.data() + (framesProcessed * audio.numChannels), toFeed);
        framesProcessed += toFeed;

        // Receive processed samples from SoundTouch
        int samplesReceived;
        do {
            if (cancelFlag.load()) break;
            samplesReceived = st.receiveSamples(outputBuffer.data(), CHUNK_SIZE);
            if (samplesReceived > 0) {
                // Apply EQ
                for (int i = 0; i < samplesReceived; ++i) {
                    if (audio.numChannels == 2) {
                        float& l = outputBuffer[i * 2];
                        float& r = outputBuffer[i * 2 + 1];
                        for (auto& f : filters) {
                            l = f.processL(l);
                            r = f.processR(r);
                        }
                    } else {
                        float& s = outputBuffer[i];
                        for (auto& f : filters) {
                            s = f.processL(s); // Mono uses ProcessL logic
                        }
                    }
                }
                // Write to WAV
                drwav_write_pcm_frames(&wav, samplesReceived, outputBuffer.data());
            }
        } while (samplesReceived > 0);

        // Update Progress
        updateProgress(trackId, (float)framesProcessed / (float)audio.numFrames);
    }

    if (cancelFlag.load()) {
        drwav_uninit(&wav);
        cleanup();
        return;
    }

    // Flush SoundTouch
    st.flush();
    int samplesReceived;
    do {
        samplesReceived = st.receiveSamples(outputBuffer.data(), CHUNK_SIZE);
        if (samplesReceived > 0) {
            for (int i = 0; i < samplesReceived; ++i) {
                if (audio.numChannels == 2) {
                    float& l = outputBuffer[i * 2];
                    float& r = outputBuffer[i * 2 + 1];
                    for (auto& f : filters) { l = f.processL(l); r = f.processR(r); }
                } else {
                    float& s = outputBuffer[i];
                    for (auto& f : filters) { s = f.processL(s); }
                }
            }
            drwav_write_pcm_frames(&wav, samplesReceived, outputBuffer.data());
        }
    } while (samplesReceived > 0);

    drwav_uninit(&wav);
    updateProgress(trackId, 1.0f);
    unregisterCancelFlag(trackId);
    LOGD("Offline render finished for %s", trackId.c_str());
}

void renderTrackOffline(
    std::string trackId,
    std::string inputPath,
    std::string outputPath,
    float tempo,
    float pitch,
    std::vector<EqBand> eqBands
) {
    // Run in a detached thread
    std::thread worker(renderWorker, trackId, inputPath, outputPath, tempo, pitch, eqBands);
    worker.detach();
}
