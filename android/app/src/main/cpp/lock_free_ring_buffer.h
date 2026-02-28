// ─────────────────────────────────────────────────────────────────────────────
// lock_free_ring_buffer.h — SPSC Lock-Free Ring Buffer for Real-Time Audio
// ─────────────────────────────────────────────────────────────────────────────
// Single Producer (IO thread) / Single Consumer (audio callback).
// No mutex on the hot path; indices use std::atomic with memory_order_relaxed.
// Capacity is fixed at construction; power-of-two optional for fast modulo.
// ─────────────────────────────────────────────────────────────────────────────

#ifndef LOCK_FREE_RING_BUFFER_H
#define LOCK_FREE_RING_BUFFER_H

#include <atomic>
#include <vector>
#include <cstddef>
#include <cstring>

/// Lock-free single-producer single-consumer ring buffer for float samples.
/// Producer: writeIndex. Consumer: readIndex. Available = writeIndex - readIndex.
class LockFreeRingBuffer {
public:
    explicit LockFreeRingBuffer(size_t capacitySamples)
        : capacity_(capacitySamples)
        , buffer_(capacitySamples, 0.0f)
        , readIndex_(0)
        , writeIndex_(0) {}

    /// Number of samples currently available to read (never blocks).
    size_t availableToRead() const {
        const size_t w = writeIndex_.load(std::memory_order_acquire);
        const size_t r = readIndex_.load(std::memory_order_relaxed);
        return (w >= r) ? (w - r) : 0;
    }

    /// Number of samples that can be written without overwriting unread data.
    size_t availableToWrite() const {
        return capacity_ - availableToRead();
    }

    /// Consumer: read up to `requestedSamples` into `out`, advance read index.
    /// Returns number of samples actually read. If underflow, fills remainder with 0.0f.
    size_t read(float* out, size_t requestedSamples) {
        const size_t w = writeIndex_.load(std::memory_order_acquire);
        const size_t r = readIndex_.load(std::memory_order_relaxed);
        size_t available = (w >= r) ? (w - r) : 0;
        size_t toRead = (requestedSamples < available) ? requestedSamples : available;

        if (toRead > 0) {
            size_t rMod = r % capacity_;
            if (rMod + toRead <= capacity_) {
                std::memcpy(out, buffer_.data() + rMod, toRead * sizeof(float));
            } else {
                size_t first = capacity_ - rMod;
                std::memcpy(out, buffer_.data() + rMod, first * sizeof(float));
                std::memcpy(out + first, buffer_.data(), (toRead - first) * sizeof(float));
            }
            readIndex_.store(r + toRead, std::memory_order_release);
        }

        // Underflow: fill rest with silence
        for (size_t i = toRead; i < requestedSamples; ++i)
            out[i] = 0.0f;

        return toRead;
    }

    /// Producer: write `numSamples` from `in` into the ring, advance write index.
    /// Drops samples if not enough space (never blocks). Returns number written.
    size_t write(const float* in, size_t numSamples) {
        size_t space = availableToWrite();
        size_t toWrite = (numSamples < space) ? numSamples : space;
        if (toWrite == 0) return 0;

        const size_t w = writeIndex_.load(std::memory_order_relaxed);
        size_t wMod = w % capacity_;
        if (wMod + toWrite <= capacity_) {
            std::memcpy(buffer_.data() + wMod, in, toWrite * sizeof(float));
        } else {
            size_t first = capacity_ - wMod;
            std::memcpy(buffer_.data() + wMod, in, first * sizeof(float));
            std::memcpy(buffer_.data(), in + first, (toWrite - first) * sizeof(float));
        }
        writeIndex_.store(w + toWrite, std::memory_order_release);
        return toWrite;
    }

    /// Reset buffer (e.g. after seek). Call from producer/control only; ensure consumer is not reading.
    void reset() {
        readIndex_.store(0, std::memory_order_release);
        writeIndex_.store(0, std::memory_order_release);
    }

    size_t capacity() const { return capacity_; }

private:
    const size_t capacity_;
    std::vector<float> buffer_;
    std::atomic<size_t> readIndex_;
    std::atomic<size_t> writeIndex_;
};

#endif // LOCK_FREE_RING_BUFFER_H
