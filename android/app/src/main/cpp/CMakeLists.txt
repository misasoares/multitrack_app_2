# ─────────────────────────────────────────────────────────────────────────────
# CMakeLists.txt — LiveStage Pro Native Audio Engine
# ─────────────────────────────────────────────────────────────────────────────
# Builds the C++ audio engine as a shared library (libaudio_engine.so).
# Includes: AudioMixer, OboePlayer (real-time output), AudioDecoder (MP3/WAV/FLAC).
# ─────────────────────────────────────────────────────────────────────────────

cmake_minimum_required(VERSION 3.22.1)
project(audio_engine)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── Fetch Oboe (Google's low-latency audio library for Android) ──
include(FetchContent)
FetchContent_Declare(
    oboe
    GIT_REPOSITORY https://github.com/google/oboe.git
    GIT_TAG        1.9.0
)
FetchContent_MakeAvailable(oboe)

# ── Audio engine shared library ──
add_library(audio_engine SHARED
    audio_mixer.cpp
    audio_utils.cpp
    audio_decoder.cpp
    audio_renderer.cpp
    oboe_player.cpp
    bridge.cpp
)

# ── Include paths ──
target_include_directories(audio_engine PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/libs
)

# ── Compiler flags ──
target_compile_options(audio_engine PRIVATE
    -O2
    -ffast-math
    -Wall
    -Wextra
    -Wno-unused-parameter
    -DSOUNDTOUCH_DISABLE_X86_OPTIMIZATIONS
)

# ── Link dependencies ──
target_link_libraries(audio_engine PRIVATE
    oboe
    log
)

# ── SoundTouch Support ──
# We explicitly list generic sources to avoid architecture-specific issues (MMX/SSE) on ARM.
target_sources(audio_engine PRIVATE
    soundtouch/source/AAFilter.cpp
    soundtouch/source/BPMDetect.cpp
    soundtouch/source/FIFOSampleBuffer.cpp
    soundtouch/source/FIRFilter.cpp
    soundtouch/source/InterpolateCubic.cpp
    soundtouch/source/InterpolateLinear.cpp
    soundtouch/source/InterpolateShannon.cpp
    soundtouch/source/PeakFinder.cpp
    soundtouch/source/RateTransposer.cpp
    soundtouch/source/SoundTouch.cpp
    soundtouch/source/TDStretch.cpp
    soundtouch/source/cpu_detect_stub.cpp
)

target_include_directories(audio_engine PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/soundtouch/include
)

# Add ST_NO_EXCEPTION_HANDLING to avoid try-catch overhead if desired,
# but default is usually fine.

