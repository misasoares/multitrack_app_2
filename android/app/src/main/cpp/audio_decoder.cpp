// ─────────────────────────────────────────────────────────────────────────────
// audio_decoder.cpp — Native Audio File Decoder
// ─────────────────────────────────────────────────────────────────────────────
// Uses minimp3, dr_wav, and dr_flac (all header-only, public domain / MIT)
// to decode audio files into interleaved float PCM.
// ─────────────────────────────────────────────────────────────────────────────

// ── Implementation macros — must come BEFORE the includes ──
#define MINIMP3_IMPLEMENTATION
#define MINIMP3_FLOAT_OUTPUT
#define DR_WAV_IMPLEMENTATION
#define DR_FLAC_IMPLEMENTATION

#include "audio_decoder.h"
#include "libs/minimp3.h"
#include "libs/minimp3_ex.h"
#include "libs/dr_wav.h"
#include "libs/dr_flac.h"

#include <algorithm>
#include <cstring>

#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "AudioDecoder"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#else
#define LOGD(...)
#define LOGE(...)
#endif

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Returns the lowercase file extension (e.g. ".mp3").
static std::string getFileExtension(const std::string& path) {
    auto dot = path.rfind('.');
    if (dot == std::string::npos) return "";
    std::string ext = path.substr(dot);
    std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);
    return ext;
}

// ─── MP3 Decoder ─────────────────────────────────────────────────────────────

static DecodedAudio decodeMp3(const std::string& filePath) {
    DecodedAudio result;

    mp3dec_t mp3d;
    mp3dec_file_info_t info;
    std::memset(&info, 0, sizeof(info));

    int ret = mp3dec_load(&mp3d, filePath.c_str(), &info, nullptr, nullptr);
    if (ret != 0 || info.samples == 0) {
        result.error = "Failed to decode MP3: " + filePath;
        LOGE("%s", result.error.c_str());
        return result;
    }

    result.numChannels = info.channels;
    result.sampleRate  = info.hz;
    result.numFrames   = static_cast<int64_t>(info.samples) / info.channels;

    // minimp3 with MINIMP3_FLOAT_OUTPUT gives us float samples directly
    result.pcmData.assign(info.buffer, info.buffer + info.samples);
    free(info.buffer);

    result.success = true;
    LOGD("Decoded MP3: %s — %lld frames, %d ch, %d Hz",
         filePath.c_str(), (long long)result.numFrames,
         result.numChannels, result.sampleRate);
    return result;
}

// ─── WAV Decoder ─────────────────────────────────────────────────────────────

static DecodedAudio decodeWav(const std::string& filePath) {
    DecodedAudio result;

    drwav wav;
    if (!drwav_init_file(&wav, filePath.c_str(), nullptr)) {
        result.error = "Failed to open WAV: " + filePath;
        LOGE("%s", result.error.c_str());
        return result;
    }

    result.numChannels = static_cast<int32_t>(wav.channels);
    result.sampleRate  = static_cast<int32_t>(wav.sampleRate);
    result.numFrames   = static_cast<int64_t>(wav.totalPCMFrameCount);

    size_t totalSamples = static_cast<size_t>(result.numFrames * result.numChannels);
    result.pcmData.resize(totalSamples);

    drwav_read_pcm_frames_f32(&wav, wav.totalPCMFrameCount, result.pcmData.data());
    drwav_uninit(&wav);

    result.success = true;
    LOGD("Decoded WAV: %s — %lld frames, %d ch, %d Hz",
         filePath.c_str(), (long long)result.numFrames,
         result.numChannels, result.sampleRate);
    return result;
}

// ─── FLAC Decoder ────────────────────────────────────────────────────────────

static DecodedAudio decodeFlac(const std::string& filePath) {
    DecodedAudio result;

    unsigned int channels, sampleRate;
    drflac_uint64 totalPCMFrameCount;

    float* pSamples = drflac_open_file_and_read_pcm_frames_f32(
        filePath.c_str(), &channels, &sampleRate, &totalPCMFrameCount, nullptr);

    if (pSamples == nullptr) {
        result.error = "Failed to decode FLAC: " + filePath;
        LOGE("%s", result.error.c_str());
        return result;
    }

    result.numChannels = static_cast<int32_t>(channels);
    result.sampleRate  = static_cast<int32_t>(sampleRate);
    result.numFrames   = static_cast<int64_t>(totalPCMFrameCount);

    size_t totalSamples = static_cast<size_t>(result.numFrames * result.numChannels);
    result.pcmData.assign(pSamples, pSamples + totalSamples);
    drflac_free(pSamples, nullptr);

    result.success = true;
    LOGD("Decoded FLAC: %s — %lld frames, %d ch, %d Hz",
         filePath.c_str(), (long long)result.numFrames,
         result.numChannels, result.sampleRate);
    return result;
}

// ─── Public API ──────────────────────────────────────────────────────────────

DecodedAudio decodeAudioFile(const std::string& filePath) {
    std::string ext = getFileExtension(filePath);

    if (ext == ".mp3") return decodeMp3(filePath);
    if (ext == ".wav") return decodeWav(filePath);
    if (ext == ".flac") return decodeFlac(filePath);

    DecodedAudio result;
    result.error = "Unsupported audio format: " + ext;
    LOGE("%s", result.error.c_str());
    return result;
}
