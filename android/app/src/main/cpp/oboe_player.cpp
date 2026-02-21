// ─────────────────────────────────────────────────────────────────────────────
// oboe_player.cpp — Real-Time Audio Output via Oboe
// ─────────────────────────────────────────────────────────────────────────────

#include "oboe_player.h"

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
    // Build an Oboe output stream — stereo, float, low-latency
    oboe::AudioStreamBuilder builder;
    builder.setDirection(oboe::Direction::Output);
    builder.setPerformanceMode(oboe::PerformanceMode::None);
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
    
    // Increase buffer size to provide more CPU margin (stability over latency)
    stream_->setBufferSizeInFrames(stream_->getFramesPerBurst() * 4);

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

    // Resize scratch buffers if needed (no allocation after first call)
    if (static_cast<int32_t>(tempL_.size()) < numFrames) {
        tempL_.resize(numFrames);
        tempR_.resize(numFrames);
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
