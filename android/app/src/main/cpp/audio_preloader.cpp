#include "audio_preloader.h"
#include <algorithm>

#ifdef __ANDROID__
#include <android/log.h>
#define LOG_TAG "AudioPreloader"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#else
#define LOGD(...)
#endif

void AudioPreloader::preload(const std::string& trackId, const std::string& filePath) {
    std::lock_guard<std::mutex> lock(mutex_);

    // If already in cache or loading, just promote in LRU if ready
    auto it = cache_.find(trackId);
    if (it != cache_.end()) {
        if (it->second.status == PreloadStatus::READY) {
            lruList_.remove(trackId);
            lruList_.push_front(trackId);
        }
        return;
    }

    // Set as loading
    cache_[trackId] = {DecodedAudio(), PreloadStatus::LOADING};
    
    // Spawn worker
    globalCancel_ = false;
    workers_.emplace_back(&AudioPreloader::workerThread, this, trackId, filePath);
}

PreloadStatus AudioPreloader::getStatus(const std::string& trackId) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = cache_.find(trackId);
    if (it == cache_.end()) return PreloadStatus::NONE;
    return it->second.status;
}

bool AudioPreloader::consume(const std::string& trackId, DecodedAudio& outAudio) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = cache_.find(trackId);
    if (it == cache_.end() || it->second.status != PreloadStatus::READY) {
        return false;
    }

    // Move data out
    outAudio = std::move(it->second.audio);
    
    // Remove from cache and LRU
    cache_.erase(it);
    lruList_.remove(trackId);
    
    return true;
}

void AudioPreloader::clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    cache_.clear();
    lruList_.clear();
}

void AudioPreloader::cancelAll() {
    globalCancel_ = true;
    for (auto& t : workers_) {
        if (t.joinable()) t.join();
    }
    workers_.clear();
    clear();
}

void AudioPreloader::workerThread(std::string trackId, std::string filePath) {
    DecodedAudio result = decodeAudioFile(filePath, &globalCancel_);

    std::lock_guard<std::mutex> lock(mutex_);
    
    // Check if we were cancelled while decoding
    if (globalCancel_) return;

    auto it = cache_.find(trackId);
    if (it == cache_.end()) return; // Item was removed while decoding

    if (result.success) {
        it->second.audio = std::move(result);
        it->second.status = PreloadStatus::READY;
        
        // Add to LRU
        lruList_.push_front(trackId);
        evictIfNeeded();
        
        LOGD("Preloaded track %s successfully", trackId.c_str());
    } else {
        it->second.status = PreloadStatus::FAILED;
        LOGD("Failed to preload track %s: %s", trackId.c_str(), result.error.c_str());
    }
}

void AudioPreloader::evictIfNeeded() {
    // Note: Mutex is already locked when this is called from workerThread or preload
    while (lruList_.size() > maxCacheSize_) {
        std::string toEvict = lruList_.back();
        lruList_.pop_back();
        cache_.erase(toEvict);
        LOGD("Evicted track %s from preloader cache", toEvict.c_str());
    }
}
