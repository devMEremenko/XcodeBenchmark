
#include <cstdint>
#include <memory>
#include <chrono>
#include <string>

#include <realm/impl/cont_transact_hist.hpp>
#include <realm/sync/config.hpp>
#include <realm/sync/instruction_replication.hpp>
#include <realm/sync/protocol.hpp>
#include <realm/sync/transform.hpp>
#include <realm/sync/object_id.hpp>
#include <realm/sync/instructions.hpp>

#ifndef REALM_SYNC_HISTORY_HPP
#define REALM_SYNC_HISTORY_HPP


namespace realm {
namespace _impl {

struct ObjectIDHistoryState;

} // namespace _impl
} // namespace realm


namespace realm {
namespace sync {

struct VersionInfo {
    /// Realm snapshot version.
    version_type realm_version = 0;

    /// The synchronization version corresponding to `realm_version`.
    ///
    /// In the context of the client-side history type `sync_version.version`
    /// will currently always be equal to `realm_version` and
    /// `sync_version.salt` will always be zero.
    SaltedVersion sync_version = {0, 0};
};

timestamp_type generate_changeset_timestamp() noexcept;

// FIXME: in C++17, switch to using std::timespec in place of last two
// arguments.
void map_changeset_timestamp(timestamp_type, std::time_t& seconds_since_epoch, long& nanoseconds) noexcept;

inline timestamp_type generate_changeset_timestamp() noexcept
{
    namespace chrono = std::chrono;
    // Unfortunately, C++11 does not specify what the epoch is for
    // `chrono::system_clock` (or for any other clock). It is believed, however,
    // that there is a de-facto standard, that the Epoch for
    // `chrono::system_clock` is the Unix epoch, i.e., 1970-01-01T00:00:00Z. See
    // http://stackoverflow.com/a/29800557/1698548. Additionally, it is assumed
    // that leap seconds are not included in the value returned by
    // time_since_epoch(), i.e., that it conforms to POSIX time. This is known
    // to be true on Linux.
    //
    // FIXME: Investigate under which conditions OS X agrees with POSIX about
    // not including leap seconds in the value returned by time_since_epoch().
    //
    // FIXME: Investigate whether Microsoft Windows agrees with POSIX about
    // about not including leap seconds in the value returned by
    // time_since_epoch().
    auto time_since_epoch = chrono::system_clock::now().time_since_epoch();
    std::uint_fast64_t millis_since_epoch = chrono::duration_cast<chrono::milliseconds>(time_since_epoch).count();
    // `offset_in_millis` is the number of milliseconds between
    // 1970-01-01T00:00:00Z and 2015-01-01T00:00:00Z not counting leap seconds.
    std::uint_fast64_t offset_in_millis = 1420070400000ULL;
    return timestamp_type(millis_since_epoch - offset_in_millis);
}

inline void map_changeset_timestamp(timestamp_type timestamp, std::time_t& seconds_since_epoch,
                                    long& nanoseconds) noexcept
{
    std::uint_fast64_t offset_in_millis = 1420070400000ULL;
    std::uint_fast64_t millis_since_epoch = std::uint_fast64_t(offset_in_millis + timestamp);
    seconds_since_epoch = std::time_t(millis_since_epoch / 1000);
    nanoseconds = long(millis_since_epoch % 1000 * 1000000L);
}

} // namespace sync
} // namespace realm

#endif // REALM_SYNC_HISTORY_HPP
