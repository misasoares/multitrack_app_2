// ─────────────────────────────────────────────────────────────────────────────
// audio_decoder.h — Native Audio File Decoder
// ─────────────────────────────────────────────────────────────────────────────
// Decodes MP3, WAV, and FLAC files into interleaved float PCM data using
// lightweight header-only C libraries (minimp3, dr_wav, dr_flac).
// ─────────────────────────────────────────────────────────────────────────────

#ifndef AUDIO_DECODER_H
#define AUDIO_DECODER_H

#include <cstdint>
#include <string>
#include <vector>

/// Result of decoding an audio file to PCM.
struct DecodedAudio {
    std::vector<float> pcmData;     // Interleaved float samples [-1.0, 1.0]
    int32_t numChannels = 0;        // 1 = mono, 2 = stereo
    int64_t numFrames   = 0;        // Total frames (samples / channels)
    int32_t sampleRate  = 0;        // Source sample rate
    bool    success     = false;    // True if decoding succeeded
    std::string error;              // Error message if failed
};

/// Decodes an audio file at `filePath` into interleaved float PCM.
/// Supports: .mp3, .wav, .flac
/// The output sample rate matches the source file; caller may resample.
DecodedAudio decodeAudioFile(const std::string& filePath);

#endif // AUDIO_DECODER_H
