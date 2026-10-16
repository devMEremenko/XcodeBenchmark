
#ifndef REALM_IMPL_CLOCK_HPP
#define REALM_IMPL_CLOCK_HPP

#include <cstdint>
#include <chrono>

#include <realm/sync/protocol.hpp>

namespace realm {
namespace _impl {

inline sync::milliseconds_type realtime_clock_now() noexcept
{
    using clock = std::chrono::system_clock;
    auto time_since_epoch = clock::now().time_since_epoch();
    auto millis_since_epoch = std::chrono::duration_cast<std::chrono::milliseconds>(time_since_epoch).count();
    return sync::milliseconds_type(millis_since_epoch);
}


inline sync::milliseconds_type monotonic_clock_now() noexcept
{
    using clock = std::chrono::steady_clock;
    auto time_since_epoch = clock::now().time_since_epoch();
    auto millis_since_epoch = std::chrono::duration_cast<std::chrono::milliseconds>(time_since_epoch).count();
    return sync::milliseconds_type(millis_since_epoch);
}

} // namespace _impl
} // namespace realm

#endif // REALM_IMPL_CLOCK_HPP
