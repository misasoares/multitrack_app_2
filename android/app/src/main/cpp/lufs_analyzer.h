// ─────────────────────────────────────────────────────────────────────────────
// lufs_analyzer.h — EBU R128 Integrated LUFS Analyzer (Offline)
// ─────────────────────────────────────────────────────────────────────────────
// Analyzes the mixed loudness of multiple rendered WAV tracks to compute
// a normalization gain factor targeting -14 LUFS for live performance.
// ─────────────────────────────────────────────────────────────────────────────

#ifndef LUFS_ANALYZER_H
#define LUFS_ANALYZER_H

#include <string>
#include <vector>

/// Result of an integrated LUFS analysis.
struct LufsResult {
    float integratedLufs;      // Measured integrated LUFS (EBU R128)
    float truePeak;            // True peak (linear, 0.0–1.0+)
    float normalizationGain;   // Linear gain factor to reach target LUFS
    bool  success;             // false if analysis failed (no audio, decode error, etc.)
};

/// Analyzes the combined loudness of multiple rendered WAV files by mixing
/// them down offline and computing Integrated LUFS per EBU R128 / ITU-R BS.1770-4.
///
/// @param trackPaths  Paths to the rendered .wav files for one SetlistItem.
/// @param targetLufs  Target loudness (e.g. -14.0f for stage playback).
/// @return LufsResult with measured LUFS, true peak, and the normalization gain.
LufsResult analyzeMixLufs(const std::vector<std::string>& trackPaths, float targetLufs);

#endif // LUFS_ANALYZER_H
