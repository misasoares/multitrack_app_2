// ─────────────────────────────────────────────────────────────────────────────
// oboe_player.h — Real-Time Audio Output via Oboe
// ─────────────────────────────────────────────────────────────────────────────
// Wraps an Oboe output stream that drives AudioMixer::process() from the
// real-time audio callback thread.
// ─────────────────────────────────────────────────────────────────────────────

#ifndef OBOE_PLAYER_H
#define OBOE_PLAYER_H

#include <oboe/Oboe.h>
#include "audio_mixer.h"

/// Manages an Oboe output stream that feeds mixed audio from AudioMixer
/// to the device speakers / headphones.
class OboePlayer : public oboe::AudioStreamDataCallback,
                   public oboe::AudioStreamErrorCallback {
public:
    /// @param mixer — the AudioMixer whose process() will be called
    ///                from the real-time audio callback.
    explicit OboePlayer(AudioMixer& mixer);
    ~OboePlayer();

    /// Opens and starts the Oboe output stream.
    /// Returns true on success.
    bool start();

    /// Stops and closes the stream.
    void stop();

    /// Returns the actual sample rate chosen by the device.
    int32_t getSampleRate() const { return sampleRate_; }

    // ── Oboe callbacks ──
    oboe::DataCallbackResult onAudioReady(
        oboe::AudioStream* stream,
        void* audioData,
        int32_t numFrames) override;

    void onErrorAfterClose(
        oboe::AudioStream* stream,
        oboe::Result error) override;

private:
    AudioMixer& mixer_;
    std::shared_ptr<oboe::AudioStream> stream_;
    int32_t sampleRate_ = 0;

    // Scratch buffers for split L/R from the mixer (reused to avoid alloc)
    std::vector<float> tempL_;
    std::vector<float> tempR_;
};

#endif // OBOE_PLAYER_H
