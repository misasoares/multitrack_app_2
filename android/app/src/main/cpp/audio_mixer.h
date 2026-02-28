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
#include <atomic>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>
#include <queue>

#include "lock_free_ring_buffer.h"

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
constexpr int kNumEqBands = 5;

/// Ring buffer capacity: seconds of audio per track (e.g. 4 sec at 48 kHz stereo = 384000 samples).
constexpr int32_t kRingBufferSeconds = 4;

/// Chunk size for background IO (samples). When free space >= this, IO thread reads from disk.
/// Larger value = fewer wakeups and more headroom when SoundTouch tempo > 1 (consumer drains faster).
constexpr size_t kIoChunkSamples = 65536;  // ~0.74 s stereo @ 44.1 kHz

/// Maximum frames per audio callback. Pre-allocated buffers are sized for this.
/// Prevents any allocation in the real-time process() path.
constexpr int32_t kMaxProcessFrames = 4096;

/// SoundTouch mono→stereo feed chunk size (frames). stMonoInputBuffer = kStMonoChunkSize * 2.
constexpr int32_t kStMonoChunkSize = 1024;

/// Pre-fill duration (seconds) on load so play can start immediately.
constexpr float kPreFillSeconds = 1.0f;

// ─── Filter Types ────────────────────────────────────────────────────────────
enum class FilterType {
    HIGHPASS = 0,
    PEAKING  = 1,
    LOWPASS  = 2
};

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
    FilterType type = FilterType::PEAKING;
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
/// PCM is consumed from a **lock-free ring buffer** (disk streaming or pre-decoded).
/// Interleaved float samples [-1.0, 1.0]. Mono = 1 ch, stereo = 2 ch.
struct MixerTrack {
    std::string id;

    // ── Ring buffer (single consumer: audio thread; single producer: IO thread or pre-fill) ──
    std::unique_ptr<LockFreeRingBuffer> ringBuffer;
    int32_t numChannels = 0;      // 1 = mono, 2 = stereo
    int64_t numFrames   = 0;      // Total frames (samples / channels) in the source

    // ── Disk streaming: WAV file handle (opaque; cast to drwav* in .cpp). Null if memory-backed. ──
    void* wavFileHandle = nullptr;

    // ── Memory-backed source (for MP3/FLAC after full decode). IO thread feeds ring from this. ──
    std::vector<float> preDecodedPcm;
    size_t preDecodedReadOffset = 0;  // Next sample index to feed into ring

    // ── Background IO thread: fills ring from file or preDecodedPcm ──
    std::thread ioThread;
    std::atomic<bool> ioStopRequested{false};
    std::atomic<int64_t> seekFrameRequested{-1};  // >= 0 means seek to this frame

    // ── Gain (volume) — atomic for lock-free read in audio thread ──
    std::atomic<float> currentGain{1.0f};
    std::atomic<float> targetGain{1.0f};
    std::atomic<float> gainIncrement{0.0f};
    std::atomic<int32_t> gainRampSamplesRemaining{0};

    // ── Pan — atomic for lock-free read in audio thread ──
    std::atomic<float> pan{0.0f};
    std::atomic<float> panGainL{0.707107f};
    std::atomic<float> panGainR{0.707107f};

    // ── Routing — atomic for lock-free read in audio thread ──
    std::atomic<bool> isMuted{false};
    std::atomic<bool> isSolo{false};

    // ── Pre-allocated buffers (resized once in loadTrack; zero allocation in process()) ──
    std::vector<float> processBuffer;      // stereo: kMaxProcessFrames * 2
    std::vector<float> stMonoInputBuffer;  // mono→stereo feed: kStMonoChunkSize * 2

    // ── Parametric EQ ──
    std::array<BiquadFilter, kNumEqBands> eqBands{};
    bool isEqFlat = true; // Optimization: bypass EQ loop if all gains are 0dB

    // ── Time/Pitch (SoundTouch) ──
    // We use a pointer to avoid including SoundTouch.h in the header if we could fwd declare,
    // but here we include it. Pointer isolates the instance lifecycle.
    std::unique_ptr<soundtouch::SoundTouch> soundTouchProcessor;

    float tempoFactor = 1.0f;     // Current stretch factor
    int pitchSemiTones = 0;       // Current pitch shift

    // Helps SoundTouch optimization (e.g. disable AA filter for percussive sounds)
    bool isPercussive = false;

    // ── Playback ──
    int64_t playheadFrame = 0;    // Current logical position in frames (for seek/sync; consumption is from ring)

    // ── Metering ──
    std::atomic<float> currentPeak{0.0f}; // Absolute peak (0.0 to 1.0)
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
    /// Loads from pre-decoded PCM (e.g. after MP3/FLAC decode). Pre-fills ring and starts feeder thread.
    void loadTrack(const std::string& id,
                   const float* pcmData,
                   int64_t numFrames,
                   int32_t numChannels);

    /// Instant load for WAV: opens file, reads header, pre-fills ring with first kPreFillSeconds, starts IO thread.
    /// Returns true on success. Does not decode the entire file.
    bool loadTrackFromFile(const std::string& id, const std::string& filePath);

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
                    int filterType,
                    float frequency,
                    float gainDb,
                    float q);

    /// Set a parametric EQ band for the Master Output.
    void setMasterEq(int bandIndex,
                     int filterType,
                     float frequency,
                     float gainDb,
                     float q);

    /// Set the Master Volume (0.0 to 1.0).
    void setMasterVolume(float volume);

    /// Metronome (synthetic click when VS is paused/stopped).
    void setMetronomeVolume(float volume);
    void setMetronomePan(float pan);
    void setMetronomeBpm(float bpm);
    void setMetronomePlaying(bool playing);

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

    // ── Metering ──
    float getTrackPeak(const std::string& id) const;
    float getMasterPeak() const;

    /// Extracts downsampled peak amplitudes from a loaded track.
    /// For streaming tracks, uses pre-decoded cache or ring buffer; may be approximate for very long files.
    int32_t getWaveformPeaks(const std::string& id,
                              float* outPeaks,
                              int32_t numBins) const;

private:
    /// Stops the track's IO thread (if running) and closes the WAV file (if open).
    /// Must be called before removing or replacing a track. Not real-time safe.
    void stopTrackStreaming(MixerTrack& track);

    /// Recomputes the left/right pan gains for a track using constant-power
    /// panning (equal-power cosine/sine law).
    static void computePanGains(MixerTrack& track);

    /// Returns true if `track` should contribute to the mix given the
    /// current mute/solo state across all tracks.
    bool isTrackAudible(const MixerTrack& track) const;

    std::unordered_map<std::string, std::unique_ptr<MixerTrack>> tracks_;
    mutable std::mutex mutex_;

    // Thread-safe command queue for rapid UI interaction without blocking
    std::queue<CommandMessage> commandQueue_;
    mutable std::mutex queueMutex_;

    int32_t sampleRate_         = kDefaultSampleRate;
    int32_t gainSmoothSamples_  = 0;   // Computed from rate + constant
    bool    isPlaying_          = false;
    bool    hasSoloedTracks_    = false; // Cached flag for solo routing

    // ── Master FX (atomic for lock-free read in process()) ──
    std::atomic<float> masterVolume_{1.0f};
    std::vector<BiquadFilter> masterEqBands_;

    // ── Metronome (lock-free: atomics read in process(), no allocation) ──
    std::atomic<float> metronomeVolume_{0.8f};
    std::atomic<float> metronomePan_{-1.0f};   // -1 = left
    std::atomic<float> metronomeBpm_{120.0f};
    std::atomic<bool> isMetronomePlaying_{false};
    float metronomePhaseFrames_      = 0.0f;   // position within beat period (audio thread only)
    float metronomeClickFramesLeft_  = 0.0f;   // remaining frames of current click (audio thread only)
    float metronomeSinePhase_        = 0.0f;   // phase in radians for 1 kHz sine (audio thread only)

    // ── Metering ──
    std::atomic<float> masterPeak_{0.0f};
};

#endif // AUDIO_MIXER_H
