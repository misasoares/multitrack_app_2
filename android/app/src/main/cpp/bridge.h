// ─────────────────────────────────────────────────────────────────────────────
// bridge.h — C-API for Dart FFI
// ─────────────────────────────────────────────────────────────────────────────
// Exposes the native audio engine functions as extern "C" so they can be
// called from Dart via dart:ffi.
// ─────────────────────────────────────────────────────────────────────────────

#ifndef BRIDGE_H
#define BRIDGE_H

#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

// ── Lifecycle ──
void engine_init(int32_t sampleRate);
void engine_dispose();

// ── Track Management ──
/// Loads raw interleaved PCM float data for a track.
void engine_load_track(const char* trackId,
                       const float* pcmData,
                       int64_t numFrames,
                       int32_t numChannels);

/// Decodes an audio file (MP3/WAV/FLAC) and loads the PCM into the mixer.
/// Returns 1 on success, 0 on failure.
int32_t engine_load_file(const char* trackId, const char* filePath);

void engine_remove_track(const char* trackId);
void engine_remove_all_tracks();

// ── Transport ──
void engine_play();
void engine_pause();
void engine_seek_to(int64_t framePosition);

// ── Per-track parameters ──
void engine_set_volume(const char* trackId, float volume);
void engine_set_pan(const char* trackId, float pan);
void engine_set_mute(const char* trackId, int32_t isMuted);
void engine_set_solo(const char* trackId, int32_t isSolo);

// ── DSP ──
int32_t engine_process(float* outputL, float* outputR, int32_t numFrames);

// ── State ──
int32_t engine_is_playing();

// ── Waveform ──
/// Fills `outPeaks` with downsampled peak amplitudes for a loaded track.
/// Returns the number of bins actually filled (0 if track not found).
int32_t engine_get_waveform_peaks(const char* trackId,
                                   float* outPeaks,
                                   int32_t numBins);

#ifdef __cplusplus
}
#endif

#endif // BRIDGE_H
