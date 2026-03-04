// ─────────────────────────────────────────────────────────────────────────────
// lufs_analyzer.cpp — EBU R128 Integrated LUFS Analyzer (Offline)
// ─────────────────────────────────────────────────────────────────────────────
// Implements K-Weighted loudness measurement per ITU-R BS.1770-4 / EBU R128.
// Mixes multiple rendered WAV tracks offline and computes the Integrated LUFS
// with absolute (-70 LUFS) and relative (-10 dB) gating.
// ─────────────────────────────────────────────────────────────────────────────

#include "lufs_analyzer.h"
#include "libs/dr_wav.h"

#include <cmath>
#include <algorithm>
#include <numeric>

#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "LufsAnalyzer"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#else
#define LOGD(...)
#define LOGE(...)
#endif

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// ─── K-Weighting Biquad Filter ───────────────────────────────────────────────
// Two cascaded biquad stages per ITU-R BS.1770-4:
//   Stage 1: Pre-filter (high-shelf boost)
//   Stage 2: RLB weighting (high-pass)

struct KWeightBiquad {
    double b0 = 1.0, b1 = 0.0, b2 = 0.0;
    double a1 = 0.0, a2 = 0.0;
    double z1L = 0.0, z2L = 0.0;
    double z1R = 0.0, z2R = 0.0;

    void reset() { z1L = z2L = z1R = z2R = 0.0; }

    double processL(double in) {
        double out = b0 * in + z1L;
        z1L = b1 * in - a1 * out + z2L;
        z2L = b2 * in - a2 * out;
        return out;
    }

    double processR(double in) {
        double out = b0 * in + z1R;
        z1R = b1 * in - a1 * out + z2R;
        z2R = b2 * in - a2 * out;
        return out;
    }
};

// ─── Compute K-Weighting Filter Coefficients ─────────────────────────────────
// Based on ITU-R BS.1770-4 Table 1 (reference coefficients are for 48 kHz;
// we use the bilinear transform to support any sample rate).

static void computePreFilter(KWeightBiquad& f, int32_t sampleRate) {
    // Stage 1: High shelving filter (pre-filter)
    // Design parameters from ITU-R BS.1770-4
    const double db  = 3.999843853973347;
    const double fc  = 1681.974450955533;
    const double Q   = 0.7071752369554196;
    const double K   = std::tan(M_PI * fc / sampleRate);
    const double Vh  = std::pow(10.0, db / 20.0);
    const double Vb  = std::pow(Vh, 0.4996667741545416);

    const double a0_ = 1.0 + K / Q + K * K;
    f.b0 = (Vh + Vb * K / Q + K * K) / a0_;
    f.b1 = 2.0 * (K * K - Vh) / a0_;
    f.b2 = (Vh - Vb * K / Q + K * K) / a0_;
    f.a1 = 2.0 * (K * K - 1.0) / a0_;
    f.a2 = (1.0 - K / Q + K * K) / a0_;
}

static void computeRlbFilter(KWeightBiquad& f, int32_t sampleRate) {
    // Stage 2: Revised Low-frequency B-weighting (RLB) high-pass filter
    const double fc = 38.13547087602444;
    const double Q  = 0.5003270373238773;
    const double K  = std::tan(M_PI * fc / sampleRate);

    const double a0_ = 1.0 + K / Q + K * K;
    f.b0 =  1.0 / a0_;
    f.b1 = -2.0 / a0_;
    f.b2 =  1.0 / a0_;
    f.a1 =  2.0 * (K * K - 1.0) / a0_;
    f.a2 = (1.0 - K / Q + K * K) / a0_;
}

// ─── LUFS Constants ──────────────────────────────────────────────────────────

// EBU R128 gating block duration: 400 ms
static constexpr double kGateBlockSeconds = 0.4;
// EBU R128 gating overlap: 75% → step = 100 ms
static constexpr double kGateStepSeconds = 0.1;
// Absolute gate threshold in LUFS
static constexpr double kAbsoluteGateLufs = -70.0;
// Relative gate offset in dB below ungated mean
static constexpr double kRelativeGateOffsetDb = -10.0;
// LUFS offset per ITU-R BS.1770-4
static constexpr double kLufsOffset = -0.691;

// ─── Main Analysis Function ──────────────────────────────────────────────────

LufsResult analyzeMixLufs(const std::vector<std::string>& trackPaths, float targetLufs) {
    LufsResult result{};
    result.success = false;
    result.integratedLufs = -120.0f;
    result.truePeak = 0.0f;
    result.normalizationGain = 1.0f;

    if (trackPaths.empty()) {
        LOGE("analyzeMixLufs: no track paths provided");
        return result;
    }

    // ── 1. Open all WAV files and validate ──
    struct WavHandle {
        drwav wav{};
        bool open = false;
    };

    std::vector<WavHandle> handles(trackPaths.size());
    int32_t sampleRate = 0;
    uint64_t maxFrames = 0;

    for (size_t i = 0; i < trackPaths.size(); ++i) {
        if (!drwav_init_file(&handles[i].wav, trackPaths[i].c_str(), nullptr)) {
            LOGE("analyzeMixLufs: failed to open %s", trackPaths[i].c_str());
            // Clean up already opened
            for (size_t j = 0; j < i; ++j) {
                if (handles[j].open) drwav_uninit(&handles[j].wav);
            }
            return result;
        }
        handles[i].open = true;

        // Use the sample rate of the first file; all rendered tracks should match
        if (sampleRate == 0) {
            sampleRate = static_cast<int32_t>(handles[i].wav.sampleRate);
        }
        maxFrames = std::max<uint64_t>(maxFrames, static_cast<uint64_t>(handles[i].wav.totalPCMFrameCount));
    }

    if (sampleRate <= 0 || maxFrames == 0) {
        LOGE("analyzeMixLufs: invalid sample rate or zero frames");
        for (auto& h : handles) { if (h.open) drwav_uninit(&h.wav); }
        return result;
    }

    LOGD("analyzeMixLufs: %zu tracks, %d Hz, %llu max frames",
         trackPaths.size(), sampleRate, (unsigned long long)maxFrames);

    // ── 2. Setup K-Weighting filters ──
    KWeightBiquad preFilter, rlbFilter;
    computePreFilter(preFilter, sampleRate);
    computeRlbFilter(rlbFilter, sampleRate);

    // ── 3. Parameters for gating ──
    const int32_t blockSamples = static_cast<int32_t>(kGateBlockSeconds * sampleRate);
    const int32_t stepSamples  = static_cast<int32_t>(kGateStepSeconds * sampleRate);

    // Accumulate mean-square per channel for each gating block
    // Ring buffer approach: accumulate per-sample squared values, compute block means
    // We process in chunks for memory efficiency
    static constexpr int32_t kChunkFrames = 4096;

    // Per-sample squared values for the sliding window (we keep the last blockSamples)
    std::vector<double> squaredL(blockSamples, 0.0);
    std::vector<double> squaredR(blockSamples, 0.0);
    int32_t sqIdx = 0;          // Ring index into squared buffers
    int64_t totalSamplesProcessed = 0;
    int64_t nextBlockEnd = blockSamples; // Next frame index where a gating block completes

    // Gating block powers (mean square of each 400ms block)
    std::vector<double> blockPowers;
    blockPowers.reserve(static_cast<size_t>(maxFrames / stepSamples + 1));

    // True peak tracking
    double truePeakLinear = 0.0;

    // Temp buffers for reading
    std::vector<float> readBuf(kChunkFrames * 2);   // Max stereo
    std::vector<double> mixL(kChunkFrames, 0.0);
    std::vector<double> mixR(kChunkFrames, 0.0);

    // ── 4. Process all frames: mix → K-weight → accumulate ──
    for (uint64_t frameOffset = 0; frameOffset < maxFrames; ) {
        const int32_t framesToRead = static_cast<int32_t>(
            std::min(static_cast<uint64_t>(kChunkFrames), maxFrames - frameOffset));

        // Zero mix buffers
        std::fill(mixL.begin(), mixL.begin() + framesToRead, 0.0);
        std::fill(mixR.begin(), mixR.begin() + framesToRead, 0.0);

        // Sum all tracks into stereo mix
        for (size_t t = 0; t < handles.size(); ++t) {
            auto& h = handles[t];
            if (!h.open) continue;

            const int32_t numCh = static_cast<int32_t>(h.wav.channels);
            const uint64_t trackFrames = h.wav.totalPCMFrameCount;

            // Skip if this track is shorter than current offset
            if (frameOffset >= trackFrames) continue;

            const int32_t canRead = static_cast<int32_t>(
                std::min(static_cast<uint64_t>(framesToRead), trackFrames - frameOffset));

            drwav_uint64 got = drwav_read_pcm_frames_f32(&h.wav, canRead, readBuf.data());

            for (int32_t i = 0; i < static_cast<int32_t>(got); ++i) {
                if (numCh >= 2) {
                    mixL[i] += static_cast<double>(readBuf[i * numCh]);
                    mixR[i] += static_cast<double>(readBuf[i * numCh + 1]);
                } else {
                    // Mono: center-pan to both channels
                    const double s = static_cast<double>(readBuf[i]);
                    mixL[i] += s;
                    mixR[i] += s;
                }
            }
        }

        // Apply K-weighting and accumulate squared samples + track true peak
        for (int32_t i = 0; i < framesToRead; ++i) {
            double l = mixL[i];
            double r = mixR[i];

            // True peak (on the raw mix, before K-weighting)
            truePeakLinear = std::max(truePeakLinear, std::max(std::abs(l), std::abs(r)));

            // Stage 1: Pre-filter (high shelf)
            l = preFilter.processL(l);
            r = preFilter.processR(r);

            // Stage 2: RLB (high-pass)
            l = rlbFilter.processL(l);
            r = rlbFilter.processR(r);

            // Store squared value in ring buffer
            squaredL[sqIdx] = l * l;
            squaredR[sqIdx] = r * r;
            sqIdx = (sqIdx + 1) % blockSamples;

            totalSamplesProcessed++;

            // Check if we've completed a gating block
            if (totalSamplesProcessed >= nextBlockEnd) {
                // Compute mean square for this block
                double sumL = 0.0, sumR = 0.0;
                for (int32_t j = 0; j < blockSamples; ++j) {
                    sumL += squaredL[j];
                    sumR += squaredR[j];
                }
                // ITU-R BS.1770-4: mean of per-channel mean-squares
                // For stereo (equal weight): power = (meanL + meanR)
                // The channel weighting for L/R is 1.0 each (center/surround differ but we're stereo)
                const double meanL = sumL / blockSamples;
                const double meanR = sumR / blockSamples;
                const double blockPower = meanL + meanR;

                blockPowers.push_back(blockPower);

                // Schedule next block (step = 100 ms for 75% overlap)
                nextBlockEnd += stepSamples;
            }
        }

        frameOffset += framesToRead;
    }

    // Close all WAV files
    for (auto& h : handles) {
        if (h.open) drwav_uninit(&h.wav);
    }

    if (blockPowers.empty()) {
        LOGE("analyzeMixLufs: no gating blocks produced (audio too short?)");
        result.truePeak = static_cast<float>(truePeakLinear);
        return result;
    }

    // ── 5. EBU R128 Gating ──

    // Absolute gate: discard blocks below -70 LUFS
    const double absoluteGateThreshold = std::pow(10.0, (kAbsoluteGateLufs - kLufsOffset) / 10.0);

    std::vector<double> aboveAbsolute;
    aboveAbsolute.reserve(blockPowers.size());
    for (double p : blockPowers) {
        if (p > absoluteGateThreshold) {
            aboveAbsolute.push_back(p);
        }
    }

    if (aboveAbsolute.empty()) {
        LOGD("analyzeMixLufs: all blocks below absolute gate (-70 LUFS), silence detected");
        result.integratedLufs = -120.0f;
        result.truePeak = static_cast<float>(truePeakLinear);
        result.normalizationGain = 1.0f;
        result.success = true;
        return result;
    }

    // Mean of blocks above absolute gate
    const double meanAboveAbsolute = std::accumulate(
        aboveAbsolute.begin(), aboveAbsolute.end(), 0.0) / aboveAbsolute.size();

    // Relative gate: -10 dB below the mean of blocks above absolute gate
    const double relativeGateLufs = kLufsOffset + 10.0 * std::log10(meanAboveAbsolute) + kRelativeGateOffsetDb;
    const double relativeGateThreshold = std::pow(10.0, (relativeGateLufs - kLufsOffset) / 10.0);

    std::vector<double> aboveRelative;
    aboveRelative.reserve(aboveAbsolute.size());
    for (double p : aboveAbsolute) {
        if (p > relativeGateThreshold) {
            aboveRelative.push_back(p);
        }
    }

    if (aboveRelative.empty()) {
        LOGD("analyzeMixLufs: all blocks below relative gate");
        result.integratedLufs = -120.0f;
        result.truePeak = static_cast<float>(truePeakLinear);
        result.normalizationGain = 1.0f;
        result.success = true;
        return result;
    }

    // ── 6. Compute Integrated LUFS ──
    const double meanAboveRelative = std::accumulate(
        aboveRelative.begin(), aboveRelative.end(), 0.0) / aboveRelative.size();

    const double integratedLufs = kLufsOffset + 10.0 * std::log10(meanAboveRelative);

    // ── 7. Compute normalization gain ──
    const double deltaDdb = static_cast<double>(targetLufs) - integratedLufs;
    double normGain = std::pow(10.0, deltaDdb / 20.0);

    // Clipping protection: ensure truePeak * normGain <= 1.0
    if (truePeakLinear > 0.0 && truePeakLinear * normGain > 1.0) {
        const double ceiledGain = 1.0 / truePeakLinear;
        LOGD("analyzeMixLufs: ceiling normalization gain from %.4f to %.4f (truePeak=%.4f)",
             normGain, ceiledGain, truePeakLinear);
        normGain = ceiledGain;
    }

    result.integratedLufs = static_cast<float>(integratedLufs);
    result.truePeak = static_cast<float>(truePeakLinear);
    result.normalizationGain = static_cast<float>(normGain);
    result.success = true;

    LOGD("analyzeMixLufs: integrated=%.2f LUFS, truePeak=%.4f, normGain=%.4f (target=%.1f LUFS)",
         result.integratedLufs, result.truePeak, result.normalizationGain, targetLufs);

    return result;
}
