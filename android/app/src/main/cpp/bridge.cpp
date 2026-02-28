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
#include "libs/dr_wav.h"

#include <string>
#include <vector>
#include <cmath>
#include <algorithm>
#include "audio_renderer.h"

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



// ─── Lifecycle ───────────────────────────────────────────────────────────────

extern "C" void engine_init(int32_t sampleRate) {
    if (gMixer) {
        LOGD("engine_init: already initialised — disposing first");
        engine_dispose();
    }

    gMixer = new AudioMixer();
    // Initialize mixer with requested rate temporarily (Oboe will override this immediately)
    gMixer->init(sampleRate);
    setTargetSampleRate(sampleRate);

    gPlayer = new OboePlayer(*gMixer);
    if (!gPlayer->start()) {
        LOGE("engine_init: failed to start Oboe player");
    }

    // [CRITICAL] Invert the source of truth!
    // The hardware might have ignored our requested 'sampleRate' (e.g., requested 44.1kHz, hardware forced 48kHz).
    // OboePlayer::start() captures the actual rate and calls gMixer->setSampleRate(actualRate).
    // We MUST also inform the Decoder so that future files are resampled to this *actual* hardware rate.
    int32_t actualHardwareRate = gPlayer->getSampleRate();
    if (actualHardwareRate != sampleRate) {
        LOGD("engine_init: Hardware forced sample rate %d Hz (requested %d Hz). Syncing ecosystem.", 
             actualHardwareRate, sampleRate);
        setTargetSampleRate(actualHardwareRate);
    }

    LOGD("engine_init: mixer + Oboe player ready (requested %d Hz, actual hardware %d Hz)",
         sampleRate, actualHardwareRate);
}

extern "C" void engine_dispose() {
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

    std::string path(filePath);
    std::string ext;
    auto dot = path.rfind('.');
    if (dot != std::string::npos) {
        ext = path.substr(dot);
        for (char& c : ext) c = static_cast<char>(::tolower(static_cast<unsigned char>(c)));
    }

    // WAV: instant load via disk streaming (no full decode, O(1))
    if (ext == ".wav") {
        if (gMixer->loadTrackFromFile(std::string(trackId), path)) {
            LOGD("engine_load_file: streaming load WAV for track %s", trackId);
            return 1;
        }
        LOGE("engine_load_file: streaming open failed, falling back to decode");
    }

    // Non-WAV or streaming failed: full decode then load into ring buffer (memory-backed)
    LOGD("engine_load_file: decoding %s for track %s", filePath, trackId);
    DecodedAudio audio = decodeAudioFile(path);
    if (!audio.success) {
        LOGE("engine_load_file: failed — %s", audio.error.c_str());
        return 0;
    }

    gMixer->loadTrack(
        std::string(trackId),
        audio.pcmData.data(),
        audio.numFrames,
        audio.numChannels
    );

    LOGD("engine_load_file: loaded %lld frames for track %s",
         (long long)audio.numFrames, trackId);
    return 1;
}



extern "C" void engine_remove_track(const char* trackId) {
    if (!gMixer || !trackId) return;
    gMixer->removeTrack(std::string(trackId));
}

extern "C" void engine_remove_all_tracks() {
    if (!gMixer) return;
    gMixer->removeAllTracks();
}

extern "C" void engine_clear_all_tracks() {
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

// ─── Metering ────────────────────────────────────────────────────────────────

static float calculateDb(float peak) {
    if (peak <= 0.000001f) return -60.0f; // Protection against log(0) and noise floor
    float db = 20.0f * std::log10(peak);
    return std::max(db, -60.0f); // Clamp to floor
}

extern "C" float engine_get_track_db(const char* trackId) {
    if (!gMixer || !trackId) return -60.0f;
    return calculateDb(gMixer->getTrackPeak(std::string(trackId)));
}

extern "C" float engine_get_master_db() {
    if (!gMixer) return -60.0f;
    return calculateDb(gMixer->getMasterPeak());
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

// ─── Peak extraction from file (low RAM, chunked read) ────────────────────────

static constexpr size_t kPeakExtractChunkFrames = 4096;

extern "C" void engine_extract_peaks_from_file(const char* filePath,
                                                int32_t numBins,
                                                float* outPeaks) {
    if (!filePath || !outPeaks || numBins <= 0) return;

    for (int32_t i = 0; i < numBins; ++i)
        outPeaks[i] = 0.0f;

    drwav wav;
    if (!drwav_init_file(&wav, filePath, nullptr)) {
        LOGE("engine_extract_peaks_from_file: failed to open %s", filePath);
        return;
    }

    const drwav_uint64 totalFrames = wav.totalPCMFrameCount;
    const unsigned int numCh = wav.channels;
    if (totalFrames == 0 || numCh == 0) {
        drwav_uninit(&wav);
        return;
    }

    const size_t chunkFrames = kPeakExtractChunkFrames;
    const size_t chunkSamples = chunkFrames * numCh;
    std::vector<float> chunk(chunkSamples, 0.0f);

    drwav_uint64 framesRead = 0;
    while (framesRead < totalFrames) {
        drwav_uint64 toRead = (totalFrames - framesRead < chunkFrames)
            ? (totalFrames - framesRead)
            : chunkFrames;
        drwav_uint64 got = drwav_read_pcm_frames_f32(&wav, toRead, chunk.data());
        if (got == 0) break;

        for (drwav_uint64 f = 0; f < got; ++f) {
            const drwav_uint64 globalFrame = framesRead + f;
            const int32_t bin = static_cast<int32_t>(
                (globalFrame * static_cast<drwav_uint64>(numBins)) / totalFrames);
            const int32_t b = (bin >= numBins) ? (numBins - 1) : bin;

            for (unsigned int c = 0; c < numCh; ++c) {
                float s = chunk[static_cast<size_t>(f * numCh + c)];
                float absVal = std::fabs(s);
                if (absVal > outPeaks[b])
                    outPeaks[b] = absVal;
            }
        }
        framesRead += got;
    }

    drwav_uninit(&wav);
    LOGD("engine_extract_peaks_from_file: %s -> %d bins", filePath, numBins);
}

// ─── EQ ──────────────────────────────────────────────────────────────────────

extern "C" void engine_set_track_eq(const char* trackId,
                                     int32_t bandIndex,
                                     int32_t filterType,
                                     float frequency,
                                     float gainDb,
                                     float q) {
    LOGD("## Set EQ Track: %s, Band: %d, Type: %d, Freq: %.1f, Gain: %.2f, Q: %.2f",
         trackId ? trackId : "(null)", bandIndex, filterType, frequency, gainDb, q);

    if (!gMixer || !trackId) {
        LOGE("## Set EQ FAILED — gMixer=%p, trackId=%s",
             (void*)gMixer, trackId ? trackId : "(null)");
        return;
    }
    gMixer->setTrackEq(std::string(trackId), bandIndex, filterType, frequency, gainDb, q);
}

extern "C" void engine_set_master_eq(int32_t bandIndex,
                                     int32_t filterType,
                                     float frequency,
                                     float gainDb,
                                     float q) {
    if (!gMixer) return;
    gMixer->setMasterEq(bandIndex, filterType, frequency, gainDb, q);
}

extern "C" void engine_set_master_volume(float volume) {
    if (!gMixer) return;
    gMixer->setMasterVolume(volume);
}

// ─── Offline Rendering ───────────────────────────────────────────────────────

extern "C" void engine_render_track_offline(const char* trackId,
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
                                            const float* eqQs) {
    if (!trackId || !inputPath || !outputPath) return;

    std::vector<EqBand> eqBands;
    for (int i = 0; i < numEqBands; ++i) {
        eqBands.push_back({eqTypes[i], eqFreqs[i], eqGains[i], eqQs[i]});
    }

    renderTrackOffline(std::string(trackId),
                       std::string(inputPath),
                       std::string(outputPath),
                       tempo,
                       pitch,
                       volume,
                       pan,
                       eqBands);
}

extern "C" float engine_get_render_progress(const char* trackId) {
    if (!trackId) return 0.0f;
    return getRenderProgress(std::string(trackId));
}

extern "C" void engine_cancel_render(const char* trackId) {
    if (!trackId) return;
    cancelRender(std::string(trackId));
}
