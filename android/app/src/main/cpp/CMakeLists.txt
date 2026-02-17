cmake_minimum_required(VERSION 3.18.1)

project(audio_engine LANGUAGES CXX)

# ─── Compiler Settings ───────────────────────────────────────────────────────
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ─── Shared Library ──────────────────────────────────────────────────────────
add_library(audio_engine SHARED
    audio_mixer.cpp
    bridge.cpp
)

# ─── Compile Flags ───────────────────────────────────────────────────────────
target_compile_options(audio_engine PRIVATE
    -O2
    -ffast-math
    -Wall
    -Wextra
    -Wpedantic
)

# ─── Link Libraries ─────────────────────────────────────────────────────────
# log is needed for __android_log_print if we add logging later.
find_library(log-lib log)

target_link_libraries(audio_engine
    ${log-lib}
)
