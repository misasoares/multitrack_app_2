// ─────────────────────────────────────────────────────────────────────────────
// bridge.cpp — C-API implementation for FFI (Dart ↔ Native)
// ─────────────────────────────────────────────────────────────────────────────
// Thin wrapper around the AudioMixer singleton.  Every function guards against
// a null mixer pointer so a mis-ordered call from Dart never segfaults.
// ─────────────────────────────────────────────────────────────────────────────

#include "bridge.h"
#include "audio_mixer.h"

#include <string>

/// Global mixer instance.  Created by `engine_init`, destroyed by
/// `engine_dispose`.  Using a raw pointer intentionally — the lifecycle is
/// fully controlled by the two functions above.
static AudioMixer* gMixer = nullptr;

// ─── Lifecycle ───────────────────────────────────────────────────────────────

extern "C" void engine_init(int32_t sampleRate) {
    if (gMixer != nullptr) {
        gMixer->dispose();
        delete gMixer;
    }
    gMixer = new AudioMixer();
    gMixer->init(sampleRate);
}

extern "C" void engine_dispose(void) {
    if (gMixer == nullptr) return;
    gMixer->dispose();
    delete gMixer;
    gMixer = nullptr;
}

// ─── Track Management ────────────────────────────────────────────────────────

extern "C" void engine_load_track(const char* trackId,
                                  const float* pcmData,
                                  int64_t numFrames,
                                  int32_t numChannels) {
    if (gMixer == nullptr || trackId == nullptr || pcmData == nullptr) return;
    gMixer->loadTrack(std::string(trackId), pcmData, numFrames, numChannels);
}

extern "C" void engine_remove_track(const char* trackId) {
    if (gMixer == nullptr || trackId == nullptr) return;
    gMixer->removeTrack(std::string(trackId));
}

extern "C" void engine_remove_all_tracks(void) {
    if (gMixer == nullptr) return;
    gMixer->removeAllTracks();
}

// ─── Transport ───────────────────────────────────────────────────────────────

extern "C" void engine_play(void) {
    if (gMixer == nullptr) return;
    gMixer->play();
}

extern "C" void engine_pause(void) {
    if (gMixer == nullptr) return;
    gMixer->pause();
}

extern "C" void engine_seek_to(int64_t framePosition) {
    if (gMixer == nullptr) return;
    gMixer->seekTo(framePosition);
}

// ─── Per-Track Parameters ────────────────────────────────────────────────────

extern "C" void engine_set_volume(const char* trackId, float volume) {
    if (gMixer == nullptr || trackId == nullptr) return;
    gMixer->setVolume(std::string(trackId), volume);
}

extern "C" void engine_set_pan(const char* trackId, float pan) {
    if (gMixer == nullptr || trackId == nullptr) return;
    gMixer->setPan(std::string(trackId), pan);
}

extern "C" void engine_set_mute(const char* trackId, int32_t isMuted) {
    if (gMixer == nullptr || trackId == nullptr) return;
    gMixer->setMute(std::string(trackId), isMuted != 0);
}

extern "C" void engine_set_solo(const char* trackId, int32_t isSolo) {
    if (gMixer == nullptr || trackId == nullptr) return;
    gMixer->setSolo(std::string(trackId), isSolo != 0);
}

// ─── DSP ─────────────────────────────────────────────────────────────────────

extern "C" int32_t engine_process(float* outputL, float* outputR,
                                  int32_t numFrames) {
    if (gMixer == nullptr || outputL == nullptr || outputR == nullptr) {
        return 0;
    }
    return gMixer->process(outputL, outputR, numFrames);
}

// ─── State ───────────────────────────────────────────────────────────────────

extern "C" int32_t engine_is_playing(void) {
    if (gMixer == nullptr) return 0;
    return gMixer->isPlaying() ? 1 : 0;
}
