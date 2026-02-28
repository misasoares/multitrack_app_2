// ─────────────────────────────────────────────────────────────────────────────
// audio_utils.h — Low-RAM waveform peak extraction
// ─────────────────────────────────────────────────────────────────────────────

#ifndef AUDIO_UTILS_H
#define AUDIO_UTILS_H

/// Extracts peak amplitude per bin from a WAV file (chunked read, low RAM).
/// outPeaks must be allocated by the caller with at least numBins floats.
/// Returns true on success. Thread-safe; no allocations.
namespace audio_utils {
bool extractPeaksFromFile(const char* filePath,
                         int numBins,
                         float* outPeaks);
}  // namespace audio_utils

#endif  // AUDIO_UTILS_H
