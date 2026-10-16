/*************************************************************************
 *
 * Copyright 2020 Realm Inc.
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

#ifndef REALM_UUID_HPP
#define REALM_UUID_HPP

#include <realm/string_data.hpp>

namespace realm {

struct InvalidUUIDString : std::logic_error {
    using std::logic_error::logic_error;
};

/// A UUID is a sequence of 16 bytes (128 bits)
class UUID {
public:
    static constexpr size_t num_bytes = 16;
    using UUIDBytes = std::array<uint8_t, num_bytes>;

    /// A string is considered valid if it contains only hex [a-f, 0-9]
    /// and hyphens in the correct sequence, case insensitive. For
    /// example: "01234567-9abc-4def-9012-3456789abcde" is valid.
    /// Other than the above, this function does not check the validity
    /// of the bits according to the rfc spec in order to allow for any
    /// user defined bit pattern and future compatibility.
    static bool is_valid_string(StringData) noexcept;

    /// This constructor may throw InvalidUUIDString if the format
    /// of the parameter is invalid according to `is_valid_string`
    explicit UUID(StringData);

    /// Constructs a  UUID with all zero bytes
    UUID()
    noexcept
        : m_bytes{}
    {
    }

    explicit UUID(const UUIDBytes& raw) noexcept
        : m_bytes(raw)
    {
    }

    bool operator==(const UUID& other) const
    {
        return m_bytes == other.m_bytes;
    }
    bool operator!=(const UUID& other) const
    {
        return m_bytes != other.m_bytes;
    }
    bool operator>(const UUID& other) const
    {
        return m_bytes > other.m_bytes;
    }
    bool operator<(const UUID& other) const
    {
        return m_bytes < other.m_bytes;
    }
    bool operator>=(const UUID& other) const
    {
        return m_bytes >= other.m_bytes;
    }
    bool operator<=(const UUID& other) const
    {
        return m_bytes <= other.m_bytes;
    }
    std::string to_string() const;
    std::string to_base64() const;
    UUIDBytes to_bytes() const
    {
        return m_bytes;
    }

    inline size_t hash() const noexcept
    {
        return murmur2_or_cityhash(m_bytes.data(), sizeof(m_bytes));
    }

private:
    UUIDBytes m_bytes = {};
};

inline std::ostream& operator<<(std::ostream& ostr, const UUID& id)
{
    ostr << id.to_string();
    return ostr;
}

} // namespace realm

namespace std {
template <>
struct hash<realm::UUID> {
    size_t operator()(const realm::UUID& uuid) const noexcept
    {
        return uuid.hash();
    }
};
} // namespace std

#endif /* REALM_UUID_HPP */
