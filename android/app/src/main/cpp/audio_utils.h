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

/// Extracts beat/transient timestamps from a WAV file.
/// Detects samples where abs(sample) > threshold and the time since the
/// last detected beat is > minSpacingMs. Writes timestamps in milliseconds
/// to outTimestamps. Returns the number of timestamps found (up to maxTimestamps).
int extractBeatMap(const char* filePath,
                   float threshold,
                   int minSpacingMs,
                   int* outTimestamps,
                   int maxTimestamps);
}  // namespace audio_utils

#endif  // AUDIO_UTILS_H
