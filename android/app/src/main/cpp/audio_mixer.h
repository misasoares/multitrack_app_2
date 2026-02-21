// ─────────────────────────────────────────────────────────────────────────────
// audio_mixer.h — LiveStage Pro Native Audio Mixer
// ─────────────────────────────────────────────────────────────────────────────
// Core mixing engine: multi-track PCM buffer mixing with gain smoothing and
// constant-power stereo panning. This header is platform-agnostic — it does
// NOT depend on Oboe, AAudio, or any OS-specific API.
// ─────────────────────────────────────────────────────────────────────────────

#ifndef AUDIO_MIXER_H
#define AUDIO_MIXER_H

#include <array>
#include <cstdint>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>
#include <queue>

// ─── SoundTouch ──────────────────────────────────────────────────────────────
#include "SoundTouch.h" // Requires target_include_directories to point to soundtouch/include

// ─── Constants ───────────────────────────────────────────────────────────────

/// Default sample rate (Hz). May be overridden at init time.
constexpr int32_t kDefaultSampleRate = 44100;

/// Duration (in seconds) of the gain-smoothing ramp.
/// At 44100 Hz this equals ~2205 samples — long enough to avoid clicks,
/// short enough to feel instantaneous to the musician.
constexpr float kGainSmoothingSeconds = 0.05f;

/// Number of parametric EQ bands per track.
constexpr int kNumEqBands = 3;

// ─── Biquad Filter ───────────────────────────────────────────────────────────

/// Second-order IIR biquad filter (Direct Form II Transposed).
/// Used for parametric peaking EQ bands.
struct BiquadFilter {
    // Coefficients
    float b0 = 1.0f, b1 = 0.0f, b2 = 0.0f;
    float a1 = 0.0f, a2 = 0.0f;

    // State (per-channel: L and R)
    float z1L = 0.0f, z2L = 0.0f;
    float z1R = 0.0f, z2R = 0.0f;

    // Parameters
    float frequency = 1000.0f;
    float gainDb    = 0.0f;
    float q         = 0.707f;
    bool  active    = false;  // true once explicitly set from Flutter

    /// Recompute coefficients for a peaking EQ filter.
    void computeCoefficients(int32_t sampleRate);

    /// Process a single sample (left channel).
    float processL(float in);

    /// Process a single sample (right channel).
    float processR(float in);

    /// Reset filter state (call on seek).
    void resetState();
};

// ─── MixerTrack ──────────────────────────────────────────────────────────────

/// Represents a single audio track loaded into the mixer.
///
/// The PCM data is stored as **interleaved float samples** normalised to
/// [-1.0, 1.0].  Mono files use `numChannels = 1`; stereo uses `2`.
struct MixerTrack {
    std::string id;

    // ── Audio Data ──
    std::vector<float> pcmData;   // Interleaved PCM samples
    int32_t numChannels = 0;      // 1 = mono, 2 = stereo
    int64_t numFrames   = 0;      // Total frames (samples / channels)

    // ── Gain (volume) ──
    float currentGain = 1.0f;     // Value being output RIGHT NOW
    float targetGain  = 1.0f;     // Value we're ramping towards
    float gainIncrement = 0.0f;   // Per-sample delta for the ramp
    int32_t gainRampSamplesRemaining = 0;

    // ── Pan ──
    float pan = 0.0f;             // -1.0 = full left, 0.0 = center, 1.0 = full right
    float panGainL = 0.707107f;   // Pre-computed left channel gain  (cos)
    float panGainR = 0.707107f;   // Pre-computed right channel gain (sin)

    // ── Routing ──
    bool isMuted = false;
    bool isSolo  = false;

    // ── Parametric EQ ──
    std::array<BiquadFilter, kNumEqBands> eqBands{};

    // ── Time/Pitch (SoundTouch) ──
    // We use a pointer to avoid including SoundTouch.h in the header if we could fwd declare,
    // but here we include it. Pointer isolates the instance lifecycle.
    soundtouch::SoundTouch* soundTouchProcessor = nullptr;

    float tempoFactor = 1.0f;     // Current stretch factor
    int pitchSemiTones = 0;       // Current pitch shift

    // Helps SoundTouch optimization (e.g. disable AA filter for percussive sounds)
    bool isPercussive = false;

    // ── Playback ──
    int64_t playheadFrame = 0;    // Current read position in frames
};

// ─── Command Queue ───────────────────────────────────────────────────────────

enum class EngineCommand {
    CLEAR_TRACKS,
    SET_TEMPO,
    SET_PITCH
};

struct CommandMessage {
    EngineCommand type;
    std::string trackId;
    float floatParam = 0.0f;
    int intParam = 0;
};

// ─── AudioMixer ──────────────────────────────────────────────────────────────

/// Multi-track audio mixer with gain smoothing and constant-power panning.
///
/// Thread safety: all public methods lock an internal mutex so they can be
/// called from the Dart isolate while the audio callback runs on the native
/// thread.  The `process()` method is designed to be called from the
/// real-time audio callback (Oboe / AAudio) in a future integration step.
class AudioMixer {
public:
    AudioMixer();
    ~AudioMixer();

    // ── Lifecycle ──
    void init(int32_t sampleRate);
    void setSampleRate(int32_t sampleRate);
    void dispose();

    // ── Track management ──
    /// Loads interleaved PCM float data for a track.
    /// If a track with the same `id` already exists it is replaced.
    void loadTrack(const std::string& id,
                   const float* pcmData,
                   int64_t numFrames,
                   int32_t numChannels);

    void removeTrack(const std::string& id);
    void removeAllTracks();

    // ── Transport ──
    void play();
    void pause();
    void seekTo(int64_t framePosition);

    // ── Per-track parameters ──
    void setVolume(const std::string& id, float volume);
    void setPan(const std::string& id, float pan);
    void setMute(const std::string& id, bool muted);
    void setSolo(const std::string& id, bool solo);

    /// Set a parametric EQ band for a track.
    void setTrackEq(const std::string& id,
                    int bandIndex,
                    float frequency,
                    float gainDb,
                    float q);

    /// Set a parametric EQ band for the Master Output.
    void setMasterEq(int bandIndex,
                     float frequency,
                     float gainDb,
                     float q);

    /// Set the Master Volume (0.0 to 1.0).
    void setMasterVolume(float volume);

    // ── Time/Pitch ──
    void setTrackTempo(const std::string& id, float tempo);
    void setTrackPitch(const std::string& id, int semitones);

    // ── DSP ──
    /// Fills `outputL` and `outputR` with `numFrames` mixed samples.
    /// Returns the number of frames actually written (may be less if all
    /// tracks have finished).
    int32_t process(float* outputL, float* outputR, int32_t numFrames);
    
    // ── State queries ──
    bool isPlaying() const { return isPlaying_; }
    int64_t getPlaybackPosition() const;
    int32_t getSampleRate() const { return sampleRate_; }

    /// Extracts downsampled peak amplitudes from a loaded track's PCM data.
    /// Fills `outPeaks` with `numBins` values in [0.0, 1.0].
    /// Returns the number of bins actually filled (0 if track not found).
    int32_t getWaveformPeaks(const std::string& id,
                              float* outPeaks,
                              int32_t numBins) const;

private:
    /// Recomputes the left/right pan gains for a track using constant-power
    /// panning (equal-power cosine/sine law).
    static void computePanGains(MixerTrack& track);

    /// Returns true if `track` should contribute to the mix given the
    /// current mute/solo state across all tracks.
    bool isTrackAudible(const MixerTrack& track) const;

    std::unordered_map<std::string, MixerTrack> tracks_;
    mutable std::mutex mutex_;

    // Thread-safe command queue for rapid UI interaction without blocking
    std::queue<CommandMessage> commandQueue_;
    mutable std::mutex queueMutex_;

    int32_t sampleRate_         = kDefaultSampleRate;
    int32_t gainSmoothSamples_  = 0;   // Computed from rate + constant
    bool    isPlaying_          = false;
    bool    hasSoloedTracks_    = false; // Cached flag for solo routing

    // ── Master FX ──
    float masterVolume_         = 1.0f;
    std::vector<BiquadFilter> masterEqBands_;
};

#endif // AUDIO_MIXER_H
