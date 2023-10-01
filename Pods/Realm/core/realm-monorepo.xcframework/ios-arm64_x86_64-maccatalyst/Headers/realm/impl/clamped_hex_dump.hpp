
#ifndef REALM_IMPL_CLAMPED_HEX_DUMP_HPP
#define REALM_IMPL_CLAMPED_HEX_DUMP_HPP

#include <realm/util/hex_dump.hpp>
#include <realm/binary_data.hpp>

namespace realm {
namespace _impl {

/// Limit the amount of dumped data to 1024 bytes. For use in connection with
/// logging.
inline std::string clamped_hex_dump(BinaryData blob, std::size_t max_size = 1024)
{
    bool was_clipped = false;
    std::size_t size_2 = blob.size();
    if (size_2 > max_size) {
        size_2 = max_size;
        was_clipped = true;
    }
    std::string str = util::hex_dump(blob.data(), size_2); // Throws
    if (was_clipped)
        str += "..."; // Throws
    return str;
}

} // namespace _impl
} // namespace realm

#endif // REALM_IMPL_CLAMPED_HEX_DUMP_HPP
