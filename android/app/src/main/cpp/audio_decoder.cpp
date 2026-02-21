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

// ─── MP3 Decoder ─────────────────────────────────────────────────────────────

static DecodedAudio decodeMp3(const std::string& filePath, std::atomic<bool>* shouldCancel) {
    DecodedAudio result;

    mp3dec_t mp3d;
    mp3dec_file_info_t info;
    std::memset(&info, 0, sizeof(info));

    // minimp3_ex doesn't easily support collaborative cancellation in a single call.
    // However, we can check before loading.
    if (shouldCancel && shouldCancel->load()) {
        result.error = "Decoding cancelled";
        return result;
    }

    int ret = mp3dec_load(&mp3d, filePath.c_str(), &info, nullptr, nullptr);
    if (ret != 0 || info.samples == 0) {
        result.error = "Failed to decode MP3: " + filePath;
        LOGE("%s", result.error.c_str());
        return result;
    }

    result.numChannels = info.channels;
    result.sampleRate  = info.hz;
    result.numFrames   = static_cast<int64_t>(info.samples) / info.channels;

    result.pcmData.assign(info.buffer, info.buffer + info.samples);
    free(info.buffer);

    result.success = true;
    return result;
}

// ─── WAV Decoder ─────────────────────────────────────────────────────────────

static DecodedAudio decodeWav(const std::string& filePath, std::atomic<bool>* shouldCancel) {
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

    const drwav_uint64 chunkSize = 4096;
    drwav_uint64 framesProcessed = 0;
    while (framesProcessed < wav.totalPCMFrameCount) {
        if (shouldCancel && shouldCancel->load()) {
            drwav_uninit(&wav);
            result.success = false;
            result.error = "Decoding cancelled";
            return result;
        }

        drwav_uint64 framesToRead = std::min(chunkSize, wav.totalPCMFrameCount - framesProcessed);
        drwav_read_pcm_frames_f32(&wav, framesToRead, result.pcmData.data() + (framesProcessed * result.numChannels));
        framesProcessed += framesToRead;
    }

    drwav_uninit(&wav);
    result.success = true;
    return result;
}

// ─── FLAC Decoder ────────────────────────────────────────────────────────────

static DecodedAudio decodeFlac(const std::string& filePath, std::atomic<bool>* shouldCancel) {
    DecodedAudio result;

    drflac* pFlac = drflac_open_file(filePath.c_str(), nullptr);
    if (pFlac == nullptr) {
        result.error = "Failed to decode FLAC: " + filePath;
        LOGE("%s", result.error.c_str());
        return result;
    }

    result.numChannels = static_cast<int32_t>(pFlac->channels);
    result.sampleRate  = static_cast<int32_t>(pFlac->sampleRate);
    result.numFrames   = static_cast<int64_t>(pFlac->totalPCMFrameCount);

    size_t totalSamples = static_cast<size_t>(result.numFrames * result.numChannels);
    result.pcmData.resize(totalSamples);

    const drflac_uint64 chunkSize = 4096;
    drflac_uint64 framesProcessed = 0;
    while (framesProcessed < pFlac->totalPCMFrameCount) {
        if (shouldCancel && shouldCancel->load()) {
            drflac_close(pFlac);
            result.success = false;
            result.error = "Decoding cancelled";
            return result;
        }

        drflac_uint64 framesToRead = std::min(chunkSize, pFlac->totalPCMFrameCount - framesProcessed);
        drflac_read_pcm_frames_f32(pFlac, framesToRead, result.pcmData.data() + (framesProcessed * result.numChannels));
        framesProcessed += framesToRead;
    }

    drflac_close(pFlac);
    result.success = true;
    return result;
}

// ─── Public API ──────────────────────────────────────────────────────────────

DecodedAudio decodeAudioFile(const std::string& filePath, std::atomic<bool>* shouldCancel) {
    std::string ext = getFileExtension(filePath);
    DecodedAudio result;

    if (ext == ".mp3") result = decodeMp3(filePath, shouldCancel);
    else if (ext == ".wav") result = decodeWav(filePath, shouldCancel);
    else if (ext == ".flac") result = decodeFlac(filePath, shouldCancel);
    else {
        result.error = "Unsupported audio format: " + ext;
        LOGE("%s", result.error.c_str());
        return result;
    }

    if (result.success) {
        LOGD("Decoded %s: %lld frames, %d ch, %d Hz",
             ext.c_str(), (long long)result.numFrames,
             result.numChannels, result.sampleRate);
    }
    
    return result;
}
