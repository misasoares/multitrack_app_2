// ─────────────────────────────────────────────────────────────────────────────
// bridge.cpp — C-API Implementation for Dart FFI
// ─────────────────────────────────────────────────────────────────────────────
// Thin wrappers around AudioMixer + OboePlayer + AudioDecoder, exposed as
// extern "C" functions callable from Dart.
// ─────────────────────────────────────────────────────────────────────────────

#include "bridge.h"
#include "audio_mixer.h"
#include "oboe_player.h"
#include "audio_decoder.h"

#include <string>

#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "AudioBridge"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#else
#define LOGD(...)
#define LOGE(...)
#endif

// ── Global singletons ──
static AudioMixer*  gMixer  = nullptr;
static OboePlayer*  gPlayer = nullptr;

#include "audio_preloader.h"

// ─── Lifecycle ───────────────────────────────────────────────────────────────

extern "C" void engine_init(int32_t sampleRate) {
    if (gMixer) {
        LOGD("engine_init: already initialised — disposing first");
        engine_dispose();
    }

    gMixer = new AudioMixer();
    gMixer->init(sampleRate);

    gPlayer = new OboePlayer(*gMixer);
    if (!gPlayer->start()) {
        LOGE("engine_init: failed to start Oboe player");
    }

    LOGD("engine_init: mixer + Oboe player ready (requested %d Hz, got %d Hz)",
         sampleRate, gPlayer->getSampleRate());
}

extern "C" void engine_dispose() {
    AudioPreloader::getInstance().cancelAll();
    if (gPlayer) {
        gPlayer->stop();
        delete gPlayer;
        gPlayer = nullptr;
    }
    if (gMixer) {
        gMixer->dispose();
        delete gMixer;
        gMixer = nullptr;
    }
    LOGD("engine_dispose: resources released");
}

// ─── Track Management ────────────────────────────────────────────────────────

extern "C" void engine_load_track(const char* trackId,
                                   const float* pcmData,
                                   int64_t numFrames,
                                   int32_t numChannels) {
    if (!gMixer || !trackId || !pcmData) return;
    gMixer->loadTrack(std::string(trackId), pcmData, numFrames, numChannels);
}

extern "C" int32_t engine_load_file(const char* trackId,
                                     const char* filePath) {
    if (!gMixer || !trackId || !filePath) return 0;

    std::string idStr(trackId);
    DecodedAudio cachedAudio;
    
    // 1. Check if we have this track pre-loaded in cache
    if (AudioPreloader::getInstance().consume(idStr, cachedAudio)) {
        LOGD("engine_load_file: using cached version for track %s", trackId);
        gMixer->loadTrack(
            idStr,
            cachedAudio.pcmData.data(),
            cachedAudio.numFrames,
            cachedAudio.numChannels
        );
        return 1;
    }

    // 2. Not in cache — decode synchronously as usual
    LOGD("engine_load_file: decoding %s for track %s (cache miss)", filePath, trackId);

    DecodedAudio audio = decodeAudioFile(std::string(filePath));
    if (!audio.success) {
        LOGE("engine_load_file: failed — %s", audio.error.c_str());
        return 0;
    }

    gMixer->loadTrack(
        idStr,
        audio.pcmData.data(),
        audio.numFrames,
        audio.numChannels
    );

    LOGD("engine_load_file: loaded %lld frames for track %s",
         (long long)audio.numFrames, trackId);
    return 1;
}

extern "C" void engine_preload_file(const char* trackId, const char* filePath) {
    if (!trackId || !filePath) return;
    AudioPreloader::getInstance().preload(std::string(trackId), std::string(filePath));
}

extern "C" int32_t engine_get_preload_status(const char* trackId) {
    if (!trackId) return (int32_t)PreloadStatus::NONE;
    return (int32_t)AudioPreloader::getInstance().getStatus(std::string(trackId));
}

extern "C" void engine_remove_track(const char* trackId) {
    if (!gMixer || !trackId) return;
    gMixer->removeTrack(std::string(trackId));
}

extern "C" void engine_remove_all_tracks() {
    AudioPreloader::getInstance().clear();
    if (!gMixer) return;
    gMixer->removeAllTracks();
}

extern "C" void engine_clear_all_tracks() {
    AudioPreloader::getInstance().clear();
    if (!gMixer) return;
    gMixer->removeAllTracks();
}

// ─── Transport ───────────────────────────────────────────────────────────────

extern "C" void engine_play() {
    if (!gMixer) return;
    gMixer->play();
    LOGD("engine_play");
}

extern "C" void engine_pause() {
    if (!gMixer) return;
    gMixer->pause();
    LOGD("engine_pause");
}

extern "C" void engine_seek_to(int64_t framePosition) {
    if (!gMixer) return;
    gMixer->seekTo(framePosition);
    LOGD("engine_seek_to: %lld", (long long)framePosition);
}

// ─── Per-track Parameters ────────────────────────────────────────────────────

extern "C" void engine_set_volume(const char* trackId, float volume) {
    if (!gMixer || !trackId) return;
    gMixer->setVolume(std::string(trackId), volume);
}

extern "C" void engine_set_pan(const char* trackId, float pan) {
    if (!gMixer || !trackId) return;
    gMixer->setPan(std::string(trackId), pan);
}

extern "C" void engine_set_mute(const char* trackId, int32_t isMuted) {
    if (!gMixer || !trackId) return;
    gMixer->setMute(std::string(trackId), isMuted != 0);
}

extern "C" void engine_set_solo(const char* trackId, int32_t isSolo) {
    if (!gMixer || !trackId) return;
    gMixer->setSolo(std::string(trackId), isSolo != 0);
}

extern "C" void engine_set_track_tempo(const char* trackId, float tempo) {
    if (!gMixer || !trackId) return;
    gMixer->setTrackTempo(std::string(trackId), tempo);
}

extern "C" void engine_set_track_pitch(const char* trackId, int semitones) {
    if (!gMixer || !trackId) return;
    gMixer->setTrackPitch(std::string(trackId), semitones);
}

// ─── DSP ─────────────────────────────────────────────────────────────────────

extern "C" int32_t engine_process(float* outputL, float* outputR,
                                   int32_t numFrames) {
    if (!gMixer || !outputL || !outputR) return 0;
    return gMixer->process(outputL, outputR, numFrames);
}

// ─── State ───────────────────────────────────────────────────────────────────

extern "C" int32_t engine_is_playing() {
    if (!gMixer) return 0;
    return gMixer->isPlaying() ? 1 : 0;
}

extern "C" int64_t engine_get_position() {
    if (!gMixer) return 0;
    return gMixer->getPlaybackPosition();
}

extern "C" int32_t engine_get_sample_rate() {
    if (!gMixer) return 44100; // Safe default
    return gMixer->getSampleRate();
}

// ─── Waveform ────────────────────────────────────────────────────────────────

extern "C" int32_t engine_get_waveform_peaks(const char* trackId,
                                              float* outPeaks,
                                              int32_t numBins) {
    if (!gMixer || !trackId || !outPeaks || numBins <= 0) return 0;
    return gMixer->getWaveformPeaks(std::string(trackId), outPeaks, numBins);
}

// ─── EQ ──────────────────────────────────────────────────────────────────────

extern "C" void engine_set_track_eq(const char* trackId,
                                     int32_t bandIndex,
                                     float frequency,
                                     float gainDb,
                                     float q) {
    LOGD("## Set EQ Track: %s, Band: %d, Freq: %.1f, Gain: %.2f, Q: %.2f",
         trackId ? trackId : "(null)", bandIndex, frequency, gainDb, q);

    if (!gMixer || !trackId) {
        LOGE("## Set EQ FAILED — gMixer=%p, trackId=%s",
             (void*)gMixer, trackId ? trackId : "(null)");
        return;
    }
    gMixer->setTrackEq(std::string(trackId), bandIndex, frequency, gainDb, q);
}

extern "C" void engine_set_master_eq(int32_t bandIndex,
                                     float frequency,
                                     float gainDb,
                                     float q) {
    if (!gMixer) return;
    gMixer->setMasterEq(bandIndex, frequency, gainDb, q);
}

extern "C" void engine_set_master_volume(float volume) {
    if (!gMixer) return;
    gMixer->setMasterVolume(volume);
}
