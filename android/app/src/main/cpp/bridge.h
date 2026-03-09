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

// ── Offline Rendering ──
void engine_render_track_offline(const char* trackId,
                                 const char* inputPath,
                                 const char* outputPath,
                                 float tempo,
                                 float pitch,
                                 float volume,
                                 float pan,
                                 int32_t numEqBands,
                                 const int32_t* eqTypes,
                                 const float* eqFreqs,
                                 const float* eqGains,
                                 const float* eqQs);

float engine_get_render_progress(const char* trackId);
void engine_cancel_render(const char* trackId);


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
void engine_set_track_normalization_gain(const char* trackId, float gain);
void engine_set_track_utility(const char* trackId, int32_t isUtility);
void engine_set_track_tempo(const char* trackId, float tempo);
void engine_set_track_pitch(const char* trackId, int32_t semitones);

// ── DSP ──
int32_t engine_process(float* outputL, float* outputR, int32_t numFrames);

// ── State ──
int32_t engine_is_playing();
int64_t engine_get_position();
int32_t engine_get_sample_rate();

// ── Metering ──
float engine_get_track_db(const char* trackId);
/// Returns current linear peak (0.0 to 1.0) for VU meter. Thread-safe.
float engine_get_track_peak(const char* trackId);
float engine_get_master_db();

// ── Waveform ──
/// Fills `outPeaks` with downsampled peak amplitudes for a loaded track.
/// Returns the number of bins actually filled (0 if track not found).
int32_t engine_get_waveform_peaks(const char* trackId,
                                   float* outPeaks,
                                   int32_t numBins);

/// Low-RAM peak extraction from a WAV file (chunked read, never loads full file).
/// Fills `outPeaks[0..numBins-1]` with max absolute sample value per bin.
/// Caller must allocate at least numBins floats. Safe to call from any thread.
void engine_extract_peaks_from_file(const char* filePath,
                                    int32_t numBins,
                                    float* outPeaks);

/// Same as engine_extract_peaks_from_file; alias for Timeline waveform API.
void engine_extract_peaks(const char* filePath, int numBins, float* outPeaks);

// ── EQ ──
/// Set parametric EQ parameters for a single band on a track.
void engine_set_track_eq(const char* trackId,
                         int32_t bandIndex,
                         int32_t filterType,
                         float frequency,
                         float gainDb,
                         float q);

/// Set master parametric EQ parameters.
void engine_set_master_eq(int32_t bandIndex,
                          int32_t filterType,
                          float frequency,
                          float gainDb,
                          float q);

/// Master volume (0.0 to 1.0).
void engine_set_master_volume(float volume);

/// Hidden normalization gain applied silently in the Master Bus (LUFS normalization).
/// Does NOT affect the UI fader. Default = 1.0 (no normalization).
void engine_set_master_normalization_gain(float gain);
void engine_set_utility_normalization_gain(float gain);

/// Metronome: volume, pan (-1..1), BPM, playing flag.
void engine_set_metronome_volume(float volume);
void engine_set_metronome_pan(float pan);
void engine_set_metronome_bpm(float bpm);
void engine_set_metronome_playing(int32_t playing);

/// Extracts beat/transient timestamps from a WAV click track.
/// Returns the number of timestamps written to outTimestamps.
int32_t engine_extract_beat_map(const char* filePath,
                                 float threshold,
                                 int32_t minSpacingMs,
                                 int32_t* outTimestamps,
                                 int32_t maxTimestamps);

/// Sends beat-map timestamps (in ms) to a track in the mixer via the command queue.
void engine_set_track_click_map(const char* trackId,
                                 const int32_t* mapMs,
                                 int32_t size);

// ── LUFS Analysis ──
/// Analyzes the combined loudness of rendered WAV tracks and returns
/// the linear gain factor needed to reach targetLufs.
/// trackPaths: null-terminated array of file path strings.
/// numTracks: number of paths in the array.
/// targetLufs: target loudness (e.g. -14.0).
/// Returns the normalization gain (linear). 1.0 on failure.
double engine_analyze_lufs(const char** trackPaths, int32_t numTracks, float targetLufs);

/// Analyzes a single track and returns results via pointers.
/// Returns 1 on success, 0 on failure.
int32_t engine_analyze_track(const char* filePath, 
                             float targetLufs, 
                             float* outLufs, 
                             float* outPeak, 
                             float* outGain);

// ── Drum Rack ──
bool engine_load_drum_sample(const char* id, const char* path);
void engine_trigger_pad(const char* id);
void engine_clear_drum_samples();

#ifdef __cplusplus
}
#endif

#endif // BRIDGE_H
