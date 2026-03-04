// ─────────────────────────────────────────────────────────────────────────────
// audio_utils.cpp — Low-RAM waveform peak extraction from WAV files
// ─────────────────────────────────────────────────────────────────────────────
// Reads file in small chunks (8192 frames) to keep RAM near zero.
// Caller provides outPeaks (at least numBins floats); this function only writes.
// ─────────────────────────────────────────────────────────────────────────────

#include "audio_utils.h"
#include "libs/dr_wav.h"

#include <cmath>
#include <cstring>
#include <vector>

#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "AudioUtils"
#define LOGD_AU(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE_AU(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#else
#define LOGD_AU(...)
#define LOGE_AU(...)
#endif

namespace audio_utils {

/// Chunk size in frames for reading (keeps RAM low).
constexpr size_t kPeakExtractChunkFrames = 8192;

/// Extracts peak amplitude per bin from a WAV file.
/// Divides the file into numBins bins; for each bin stores the max absolute
/// sample value in outPeaks[b]. outPeaks must be allocated by the caller
/// with at least numBins floats. No memory is allocated here; safe to call
/// from any thread. Returns true on success.
bool extractPeaksFromFile(const char* filePath,
                         int numBins,
                         float* outPeaks) {
    if (!filePath || !outPeaks || numBins <= 0)
        return false;

    std::memset(outPeaks, 0, static_cast<size_t>(numBins) * sizeof(float));

    drwav wav;
    if (!drwav_init_file(&wav, filePath, nullptr)) {
        LOGE_AU("extractPeaksFromFile: failed to open %s", filePath);
        return false;
    }

    const drwav_uint64 totalFrames = wav.totalPCMFrameCount;
    const unsigned int numCh = wav.channels;
    if (totalFrames == 0 || numCh == 0) {
        drwav_uninit(&wav);
        return false;
    }

    const size_t chunkFrames = kPeakExtractChunkFrames;
    const size_t chunkSamples = chunkFrames * numCh;
    std::vector<float> chunk(chunkSamples, 0.0f);

    drwav_uint64 framesRead = 0;
    while (framesRead < totalFrames) {
        drwav_uint64 toRead = (totalFrames - framesRead < chunkFrames)
            ? (totalFrames - framesRead)
            : chunkFrames;
        drwav_uint64 got = drwav_read_pcm_frames_f32(&wav, toRead, chunk.data());
        if (got == 0) break;

        for (drwav_uint64 f = 0; f < got; ++f) {
            const drwav_uint64 globalFrame = framesRead + f;
            const int32_t bin = static_cast<int32_t>(
                (globalFrame * static_cast<drwav_uint64>(numBins)) / totalFrames);
            const int32_t b = (bin >= numBins) ? (numBins - 1) : bin;

            for (unsigned int c = 0; c < numCh; ++c) {
                float s = chunk[static_cast<size_t>(f * numCh + c)];
                float absVal = std::fabs(s);
                if (absVal > outPeaks[b])
                    outPeaks[b] = absVal;
            }
        }
        framesRead += got;
    }

    drwav_uninit(&wav);
    LOGD_AU("extractPeaksFromFile: %s -> %d bins", filePath, numBins);
    return true;
}

// ─── Beat Map Extraction (transient detection) ────────────────────────────────

int extractBeatMap(const char* filePath,
                   float threshold,
                   int minSpacingMs,
                   int* outTimestamps,
                   int maxTimestamps) {
    if (!filePath || !outTimestamps || maxTimestamps <= 0)
        return 0;

    drwav wav;
    if (!drwav_init_file(&wav, filePath, nullptr)) {
        LOGE_AU("extractBeatMap: failed to open %s", filePath);
        return 0;
    }

    const drwav_uint64 totalFrames = wav.totalPCMFrameCount;
    const unsigned int numCh = wav.channels;
    const unsigned int sampleRate = wav.sampleRate;
    if (totalFrames == 0 || numCh == 0 || sampleRate == 0) {
        drwav_uninit(&wav);
        return 0;
    }

    const size_t chunkFrames = kPeakExtractChunkFrames;
    const size_t chunkSamples = chunkFrames * numCh;
    std::vector<float> chunk(chunkSamples, 0.0f);

    // Minimum spacing in frames
    const drwav_uint64 minSpacingFrames =
        static_cast<drwav_uint64>(sampleRate) *
        static_cast<drwav_uint64>(minSpacingMs) / 1000ULL;

    int count = 0;
    drwav_uint64 framesRead = 0;
    drwav_uint64 lastBeatFrame = 0; // Frame of last detected beat
    bool firstBeat = true;

    while (framesRead < totalFrames && count < maxTimestamps) {
        drwav_uint64 toRead = (totalFrames - framesRead < chunkFrames)
            ? (totalFrames - framesRead)
            : chunkFrames;
        drwav_uint64 got = drwav_read_pcm_frames_f32(&wav, toRead, chunk.data());
        if (got == 0) break;

        for (drwav_uint64 f = 0; f < got && count < maxTimestamps; ++f) {
            const drwav_uint64 globalFrame = framesRead + f;

            // Check spacing since last beat
            if (!firstBeat && (globalFrame - lastBeatFrame) < minSpacingFrames)
                continue;

            // Check if any channel exceeds threshold
            bool hit = false;
            for (unsigned int c = 0; c < numCh; ++c) {
                float s = chunk[static_cast<size_t>(f * numCh + c)];
                if (std::fabs(s) > threshold) {
                    hit = true;
                    break;
                }
            }

            if (hit) {
                // Convert frame to milliseconds
                int ms = static_cast<int>(
                    (globalFrame * 1000ULL) / static_cast<drwav_uint64>(sampleRate));
                outTimestamps[count] = ms;
                count++;
                lastBeatFrame = globalFrame;
                firstBeat = false;
            }
        }
        framesRead += got;
    }

    drwav_uninit(&wav);
    LOGD_AU("extractBeatMap: %s -> %d beats (threshold=%.3f, spacing=%dms)",
            filePath, count, threshold, minSpacingMs);
    return count;
}

}  // namespace audio_utils
