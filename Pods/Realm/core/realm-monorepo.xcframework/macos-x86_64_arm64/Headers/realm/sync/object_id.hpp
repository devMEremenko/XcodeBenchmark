/*************************************************************************
 *
 * Copyright 2017 Realm Inc.
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

#ifndef REALM_SYNC_OBJECT_ID_HPP
#define REALM_SYNC_OBJECT_ID_HPP

#include <functional> // std::hash
#include <string>
#include <iosfwd> // operator<<
#include <map>
#include <set>

#include <external/mpark/variant.hpp>
#include <realm/global_key.hpp>
#include <realm/string_data.hpp>
#include <realm/data_type.hpp>
#include <realm/keys.hpp>
#include <realm/db.hpp>
#include <realm/mixed.hpp>

namespace realm {

class Group;

namespace sync {

// Any unambiguous object identifier. Monostate represents NULL (can't use realm::None or std::nullptr_t because they
// do not implement operator<).
using PrimaryKey = mpark::variant<mpark::monostate, int64_t, StringData, GlobalKey, ObjectId, UUID>;

/// FIXME: Since PrimaryKey is a typedef to an `std` type, ADL for operator<<
/// doesn't work properly. This struct exists solely for passing PrimaryKey
/// instances to various output streams.
struct format_pk {
    const PrimaryKey& pk;
    explicit format_pk(const PrimaryKey& pk)
        : pk(pk)
    {
    }
};
std::ostream& operator<<(std::ostream& os, format_pk);


// ObjectIDSet is a set of (table name, object id)
class ObjectIDSet {
public:
    void insert(StringData table, const PrimaryKey& object_id);
    void erase(StringData table, const PrimaryKey& object_id);
    bool contains(StringData table, const PrimaryKey& object_id) const noexcept;
    bool empty() const noexcept;

    // A map from table name to a set of object ids.
    std::map<std::string, std::set<PrimaryKey>> m_objects;
};

// FieldSet is a set of fields in tables. A field is defined by a
// table name, a column in the table and an object id for the row.
class FieldSet {
public:
    void insert(StringData table, StringData column, const PrimaryKey& object_id);
    void erase(StringData table, StringData column, const PrimaryKey& object_id);
    bool contains(StringData table, const PrimaryKey& object_id) const noexcept;
    bool contains(StringData table, StringData column, const PrimaryKey& object_id) const noexcept;
    bool empty() const noexcept;

    // A map from table name to a map from column name to a set of
    // object ids.
    std::map<std::string, std::map<std::string, std::set<PrimaryKey>>> m_fields;
};

struct GlobalID {
    StringData table_name;
    PrimaryKey object_id;

    bool operator==(const GlobalID& other) const;
    bool operator!=(const GlobalID& other) const;
    bool operator<(const GlobalID& other) const;
};

/// Implementation:


inline bool GlobalID::operator==(const GlobalID& other) const
{
    return object_id == other.object_id && table_name == other.table_name;
}

inline bool GlobalID::operator!=(const GlobalID& other) const
{
    return !(*this == other);
}

inline bool GlobalID::operator<(const GlobalID& other) const
{
    if (table_name == other.table_name)
        return object_id < other.object_id;
    return table_name < other.table_name;
}

inline bool ObjectIDSet::empty() const noexcept
{
    return m_objects.empty();
}

inline bool FieldSet::empty() const noexcept
{
    return m_fields.empty();
}

} // namespace sync
} // namespace realm

#endif // REALM_SYNC_OBJECT_ID_HPP
