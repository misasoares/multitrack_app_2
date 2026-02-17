// ─────────────────────────────────────────────────────────────────────────────
// bridge.h — C-API declarations for FFI (Dart ↔ Native)
// ─────────────────────────────────────────────────────────────────────────────

#ifndef BRIDGE_H
#define BRIDGE_H

#include <cstdint>

#ifdef __cplusplus
extern "C" {
#endif

// ── Lifecycle ──
void engine_init(int32_t sampleRate);
void engine_dispose(void);

// ── Track management ──
/// Loads raw interleaved PCM float data for a track.
/// `pcmData` must point to `numFrames * numChannels` floats.
void engine_load_track(const char* trackId,
                       const float* pcmData,
                       int64_t numFrames,
                       int32_t numChannels);

void engine_remove_track(const char* trackId);
void engine_remove_all_tracks(void);

// ── Transport ──
void engine_play(void);
void engine_pause(void);
void engine_seek_to(int64_t framePosition);

// ── Per-track parameters ──
void engine_set_volume(const char* trackId, float volume);
void engine_set_pan(const char* trackId, float pan);
void engine_set_mute(const char* trackId, int32_t isMuted);
void engine_set_solo(const char* trackId, int32_t isSolo);

// ── DSP ──
/// Processes `numFrames` and writes the stereo mix into `outputL` / `outputR`.
/// The caller must allocate both buffers with at least `numFrames` floats.
int32_t engine_process(float* outputL, float* outputR, int32_t numFrames);

// ── State ──
int32_t engine_is_playing(void);

#ifdef __cplusplus
}
#endif

#endif // BRIDGE_H
