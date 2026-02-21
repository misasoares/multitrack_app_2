#ifndef AUDIO_PRELOADER_H
#define AUDIO_PRELOADER_H

#include <string>
#include <unordered_map>
#include <list>
#include <mutex>
#include <thread>
#include <atomic>
#include <vector>
#include "audio_decoder.h"

enum class PreloadStatus {
    NONE = 0,
    LOADING = 1,
    READY = 2,
    FAILED = 3
};

class AudioPreloader {
public:
    static AudioPreloader& getInstance() {
        static AudioPreloader instance;
        return instance;
    }

    void preload(const std::string& trackId, const std::string& filePath);
    PreloadStatus getStatus(const std::string& trackId);
    bool consume(const std::string& trackId, DecodedAudio& outAudio);
    void clear();
    void cancelAll();

    ~AudioPreloader() {
        cancelAll();
    }

private:
    AudioPreloader() : maxCacheSize_(3) {}
    
    struct CacheEntry {
        DecodedAudio audio;
        PreloadStatus status;
    };

    void workerThread(std::string trackId, std::string filePath);
    void evictIfNeeded();

    std::unordered_map<std::string, CacheEntry> cache_;
    std::list<std::string> lruList_; // Front is most recently used
    std::mutex mutex_;
    std::atomic<bool> globalCancel_{false};
    
    // We track active threads to join them if needed, or just let them finish/cancel
    std::vector<std::thread> workers_;
    size_t maxCacheSize_;

    // Prevent copying
    AudioPreloader(const AudioPreloader&) = delete;
    AudioPreloader& operator=(const AudioPreloader&) = delete;
};

#endif // AUDIO_PRELOADER_H
