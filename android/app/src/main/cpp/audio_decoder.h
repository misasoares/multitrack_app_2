#ifndef AUDIO_DECODER_H
#define AUDIO_DECODER_H

#include <cstdint>
#include <string>
#include <vector>
#include <atomic>

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
/// `shouldCancel` allows for collaborative cancellation during decoding.
DecodedAudio decodeAudioFile(const std::string& filePath, std::atomic<bool>* shouldCancel = nullptr);

#endif // AUDIO_DECODER_H
