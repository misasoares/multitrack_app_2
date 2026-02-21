#ifndef AUDIO_RENDERER_H
#define AUDIO_RENDERER_H

#include <string>
#include <vector>

struct EqBand {
    float frequency;
    float gainDb;
    float q;
};

/**
 * Renders an audio track to a new WAV file with DSP effects applied (Tempo, Pitch, EQ).
 * This runs asynchronously in a background thread.
 * 
 * @param trackId Unique identifier to track progress.
 * @param inputPath Path to the source audio file (.mp3, .wav, .flac).
 * @param outputPath Path where the processed .wav file will be saved.
 * @param tempo Time-stretch factor (1.0 = normal).
 * @param pitch Pitch-shift in semitones (0 = normal).
 * @param eqBands Vector of EQ bands to apply.
 */
void renderTrackOffline(
    std::string trackId,
    std::string inputPath,
    std::string outputPath,
    float tempo,
    float pitch,
    std::vector<EqBand> eqBands
);

/**
 * Returns the rendering progress for a given trackId.
 * @return Value from 0.0 to 1.0. -1.0 indicates error. -2.0 indicates cancelled.
 */
float getRenderProgress(std::string trackId);

/**
 * Cancels an ongoing rendering process.
 */
void cancelRender(std::string trackId);

#endif // AUDIO_RENDERER_H
