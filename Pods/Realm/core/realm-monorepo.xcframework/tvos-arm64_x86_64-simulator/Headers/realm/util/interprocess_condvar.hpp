/*************************************************************************
 *
 * Copyright 2016 Realm Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 **************************************************************************/

#ifndef REALM_UTIL_INTERPROCESS_CONDVAR
#define REALM_UTIL_INTERPROCESS_CONDVAR


#include <realm/util/features.h>
#include <realm/util/thread.hpp>
#include <realm/util/interprocess_mutex.hpp>
#include <cstdint>
#include <fcntl.h>
#include <sys/stat.h>
#include <mutex>

#if REALM_PLATFORM_APPLE
#include <sys/time.h>
#endif

// Condvar Emulation is required if RobustMutex emulation is enabled
#if REALM_ROBUST_MUTEX_EMULATION || defined(_WIN32)
#define REALM_CONDVAR_EMULATION
#endif

namespace realm {
namespace util {


/// Condition variable for use in synchronization monitors.
/// This condition variable uses emulation based on named pipes
/// for the inter-process case, if enabled by REALM_CONDVAR_EMULATION.
///
/// FIXME: This implementation will never release/delete pipes. This is unlikely
/// to be a problem as long as only a modest number of different database names
/// are in use
///
/// A InterprocessCondVar is always process shared.
class InterprocessCondVar {
public:
    InterprocessCondVar();
    ~InterprocessCondVar() noexcept;

    // Disable copying. Copying an open file will create a scenario
    // where the same file descriptor will be opened once but closed twice.
    InterprocessCondVar(const InterprocessCondVar&) = delete;
    InterprocessCondVar& operator=(const InterprocessCondVar&) = delete;

    /// To use the InterprocessCondVar, you also must place a structure of type
    /// InterprocessCondVar::SharedPart in memory shared by multiple processes
    /// or in a memory mapped file, and use set_shared_part() to associate
    /// the condition variable with it's shared part. You must initialize
    /// the shared part using InterprocessCondVar::init_shared_part(), but only before
    /// first use and only when you have exclusive access to the shared part.

#ifdef REALM_CONDVAR_EMULATION
    struct SharedPart {
#ifdef _WIN32
        // See top of .cpp for description of how windows implementation works.
        std::atomic_int32_t m_max_process_num;
        bool m_any_waiters; // guarded by mutex associated with this CondVar.

        static_assert(std::atomic_int32_t::is_always_lock_free);
#else
        uint64_t signal_counter;
        uint64_t wait_counter;
#endif
    };
#else
    typedef CondVar SharedPart;
#endif

    /// You need to bind the emulation to a SharedPart in shared/mmapped memory.
    /// The SharedPart is assumed to have been initialized (possibly by another process)
    /// earlier through a call to init_shared_part.
    void set_shared_part(SharedPart& shared_part, std::string path, std::string condvar_name, std::string tmp_path);

    /// Initialize the shared part of a process shared condition variable.
    /// A process shared condition variables may be represented by any number of
    /// InterprocessCondVar instances in any number of different processes,
    /// all sharing a common SharedPart instance, which must be in shared memory.
    static void init_shared_part(SharedPart& shared_part);

    /// Release any system resources allocated for the shared part. This should
    /// be used *only* when you are certain, that nobody is using it.
    void release_shared_part();

    /// Wait for someone to call notify_all() on this condition
    /// variable. The call to wait() may return spuriously, so the caller should
    /// always re-evaluate the condition on which to wait and loop on wait()
    /// if necessary.
    void wait(InterprocessMutex& m, const struct timespec* tp);

    /// While cond() returns false, waits for a call to notify_all(). This is
    /// the preferred overload to use because it correctly handles spurious
    /// wakeups, and avoids some condvar anti-patterns, by pushing callers into
    /// the correct pattern.
    template <typename Cond>
    void wait(InterprocessMutex& m, const struct timespec* tp, Cond&& cond)
    {
        while (!cond()) {
            wait(m, tp);
            if (tp) {
                struct timespec now;
#ifdef _WIN32
                timespec_get(&now, TIME_UTC);
#elif REALM_PLATFORM_APPLE
                if (__builtin_available(iOS 10, macOS 12, tvOS 10, watchOS 3, *)) {
                    clock_gettime(CLOCK_REALTIME, &now);
                }
                else {
                    timeval tv;
                    gettimeofday(&tv, 0);
                    now.tv_sec = tv.tv_sec;
                    now.tv_nsec = tv.tv_usec * 1000;
                }
#else
                clock_gettime(CLOCK_REALTIME, &now);
#endif
                if (std::tie(now.tv_sec, now.tv_nsec) >= std::tie(tp->tv_sec, tp->tv_nsec))
                    return;
            }
        }
    }

    /// Wake up every thread that is currently waiting on this condition.
    /// The caller must hold the lock associated with the condvar at the time
    /// of calling notify_all().
    /// In order to avoid missed wakeups in the case of sudden process termination, it is important
    /// to notify the CV *prior* to changing the state that the condition variable is protecting,
    /// within the same mutex hold.
    void notify_all() noexcept;

    /// Cleanup and release system resources if possible.
    void close() noexcept;

private:
    // non-zero if a shared part has been registered (always 0 on process local instances)
    SharedPart* m_shared_part = nullptr;

#ifdef REALM_CONDVAR_EMULATION
    // keep the path to allocated system resource so we can remove them again
    std::string m_resource_path;
    // pipe used for emulation. When using a named pipe, m_fd_read is read-write and m_fd_write is unused.
    // When using an anonymous pipe (currently only for tvOS) m_fd_read is read-only and m_fd_write is write-only.
    int m_fd_read = -1;
    int m_fd_write = -1;
#endif

#ifdef _WIN32
    // A wrapper around HANDLE that auto-closes.
    struct HandleHolder {
        HandleHolder() = default;
        /*implicit*/ HandleHolder(HANDLE h)
            : handle(h)
        {
        }
        ~HandleHolder()
        {
            if (handle)
                REALM_ASSERT_RELEASE(CloseHandle(handle));
        }
        HandleHolder(HandleHolder&& other) noexcept
            : handle(std::exchange(other.handle, {}))
        {
        }
        HandleHolder& operator=(HandleHolder&& other) noexcept
        {
            if (handle)
                REALM_ASSERT_RELEASE(CloseHandle(handle));
            handle = std::exchange(other.handle, {});
            return *this;
        }

        /*implicit*/ operator HANDLE() const
        {
            return handle;
        }

        explicit operator bool() const
        {
            return bool(handle);
        }

        HANDLE handle = {};
    };

    struct Event {
        void wait(DWORD millis = INFINITE) noexcept;
        void set() noexcept;
        void reset() noexcept;
        HandleHolder handle;
    };

    struct Mutex {
        void lock() noexcept;
        bool try_lock() noexcept;
        void unlock() noexcept;
        HandleHolder handle;
    };

    void update_event_handles();
    Event open_event(int32_t n);
    Mutex open_mutex(int32_t n);
    Mutex open_mutex(std::string name);

    Event& my_event() noexcept
    {
        return m_events[m_my_id];
    }

    int32_t m_my_id = -1;
    std::vector<Event> m_events;

    // Held whole time this condvar object lives.
    Mutex m_my_mutex;

    // The main algorithm only supports one waiter per process.
    // These members exist to extend that to support N waiters per process.
    // They are guarded by the mutex associated with this cv.
    std::condition_variable_any m_waiter_cv;
    int64_t m_highest_waiter = 0;
    int64_t m_signaled_waiters = 0;
    bool m_have_waiter = false;

    std::string m_name_with_path;
#endif
};


// Implementation:


} // namespace util
} // namespace realm


#endif
