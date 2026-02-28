// ─────────────────────────────────────────────────────────────────────────────
// oboe_player.cpp — Real-Time Audio Output via Oboe
// ─────────────────────────────────────────────────────────────────────────────

#include "oboe_player.h"

#include <cstring>

#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "OboePlayer"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#else
#define LOGD(...)
#define LOGE(...)
#endif

// ─── Lifecycle ───────────────────────────────────────────────────────────────

OboePlayer::OboePlayer(AudioMixer& mixer) : mixer_(mixer) {}

OboePlayer::~OboePlayer() {
    stop();
}

bool OboePlayer::start() {
    // Backing Tracks / VS Player: stability over sub-ms latency.
    // PerformanceMode::None lets the system choose a stable media path and avoids thermal throttling issues.
    oboe::AudioStreamBuilder builder;
    builder.setDirection(oboe::Direction::Output);
    builder.setPerformanceMode(oboe::PerformanceMode::None);
    builder.setUsage(oboe::Usage::Media);
    builder.setSharingMode(oboe::SharingMode::Exclusive);
    builder.setFormat(oboe::AudioFormat::Float);
    builder.setChannelCount(oboe::ChannelCount::Stereo);
    builder.setDataCallback(this);
    builder.setErrorCallback(this);

    oboe::Result result = builder.openStream(stream_);
    if (result != oboe::Result::OK) {
        LOGE("Failed to open Oboe stream: %s", oboe::convertToText(result));
        return false;
    }

    sampleRate_ = stream_->getSampleRate();

    // Stage shield: large buffer to absorb CPU throttling / thermal spikes (8x burst)
    stream_->setBufferSizeInFrames(stream_->getFramesPerBurst() * 8);

    // Pre-allocate scratch buffers once (zero allocation in onAudioReady)
    const int32_t bufferFrames = stream_->getBufferSizeInFrames();
    tempL_.resize(static_cast<size_t>(bufferFrames), 0.0f);
    tempR_.resize(static_cast<size_t>(bufferFrames), 0.0f);

    LOGD("Oboe stream opened: %d Hz, %d ch, buffer=%d frames, burst=%d",
         sampleRate_, stream_->getChannelCount(),
         stream_->getBufferSizeInFrames(),
         stream_->getFramesPerBurst());

    // Re-initialise the mixer with the device's actual sample rate
    // so gain-smoothing ramp durations are correct.
    mixer_.setSampleRate(sampleRate_);

    result = stream_->requestStart();
    if (result != oboe::Result::OK) {
        LOGE("Failed to start Oboe stream: %s", oboe::convertToText(result));
        stream_->close();
        stream_.reset();
        return false;
    }

    LOGD("Oboe stream started");
    return true;
}

void OboePlayer::stop() {
    if (stream_) {
        stream_->requestStop();
        stream_->close();
        stream_.reset();
        LOGD("Oboe stream stopped");
    }
}

// ─── Audio Callback ──────────────────────────────────────────────────────────

oboe::DataCallbackResult OboePlayer::onAudioReady(
        oboe::AudioStream* /*stream*/,
        void* audioData,
        int32_t numFrames) {

    auto* output = static_cast<float*>(audioData);

    // Buffers pre-allocated in start(); never allocate here
    if (numFrames <= 0 || static_cast<size_t>(numFrames) > tempL_.size()) {
        std::memset(output, 0, sizeof(float) * 2 * static_cast<size_t>(numFrames > 0 ? numFrames : 0));
        return oboe::DataCallbackResult::Continue;
    }

    // Ask the mixer to fill split L/R buffers
    mixer_.process(tempL_.data(), tempR_.data(), numFrames);

    // Interleave L/R into Oboe's stereo output buffer: [L0, R0, L1, R1, ...]
    for (int32_t i = 0; i < numFrames; ++i) {
        output[i * 2]     = tempL_[i];
        output[i * 2 + 1] = tempR_[i];
    }

    return oboe::DataCallbackResult::Continue;
}

// ─── Error Recovery ──────────────────────────────────────────────────────────

void OboePlayer::onErrorAfterClose(
        oboe::AudioStream* /*stream*/,
        oboe::Result error) {
    LOGE("Oboe stream error: %s — attempting restart",
         oboe::convertToText(error));

    // Auto-reconnect: reopen the stream after a disconnect (e.g. headphones
    // unplugged, Bluetooth device switched).
    start();
}
