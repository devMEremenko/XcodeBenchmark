/*************************************************************************
 *
 * Copyright 2019 Realm Inc.
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

#ifndef REALM_OBJECT_ID_HPP
#define REALM_OBJECT_ID_HPP

#include <array>
#include <cstdint>
#include <cstring>
#include <realm/timestamp.hpp>

namespace realm {

class ObjectId {
public:
    static constexpr size_t num_bytes = 12;
    using ObjectIdBytes = std::array<uint8_t, num_bytes>;
    /**
     * Constructs an ObjectId with all bytes 0x00.
     */
    ObjectId() noexcept = default;

    /**
     * Checks if the given string is a valid object id.
     */
    static bool is_valid_str(StringData) noexcept;

    /**
     * Constructs an ObjectId from 24 hex characters.
     */
    explicit ObjectId(StringData init) noexcept;

    /**
     * Constructs an ObjectID from an array of 12 unsigned bytes
     */
    explicit ObjectId(const ObjectIdBytes& init) noexcept;

    /**
     * Constructs an ObjectId with the specified inputs, and a random number
     */
    ObjectId(Timestamp d, int machine_id, int process_id) noexcept;

    /**
     * Generates a new ObjectId using the algorithm to attempt to avoid collisions.
     */
    static ObjectId gen();

    bool operator==(const ObjectId& other) const
    {
        return m_bytes == other.m_bytes;
    }
    bool operator!=(const ObjectId& other) const
    {
        return m_bytes != other.m_bytes;
    }
    bool operator>(const ObjectId& other) const
    {
        return m_bytes > other.m_bytes;
    }
    bool operator<(const ObjectId& other) const
    {
        return m_bytes < other.m_bytes;
    }
    bool operator>=(const ObjectId& other) const
    {
        return m_bytes >= other.m_bytes;
    }
    bool operator<=(const ObjectId& other) const
    {
        return m_bytes <= other.m_bytes;
    }
    explicit operator Timestamp() const
    {
        return get_timestamp();
    }

    Timestamp get_timestamp() const;
    std::string to_string() const;
    ObjectIdBytes to_bytes() const;
    size_t hash() const noexcept;

private:
    ObjectIdBytes m_bytes = {};
};

inline std::ostream& operator<<(std::ostream& ostr, const ObjectId& id)
{
    ostr << id.to_string();
    return ostr;
}

} // namespace realm

namespace std {
template <>
struct hash<realm::ObjectId> {
    size_t operator()(const realm::ObjectId& oid) const noexcept
    {
        return oid.hash();
    }
};
} // namespace std

#endif /* REALM_OBJECT_ID_HPP */
