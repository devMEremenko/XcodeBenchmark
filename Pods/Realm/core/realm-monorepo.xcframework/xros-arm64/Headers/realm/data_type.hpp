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

#ifndef REALM_DATA_TYPE_HPP
#define REALM_DATA_TYPE_HPP

#include <stdint.h>
#include <realm/util/to_string.hpp>
#include <realm/util/features.h>

namespace realm {

class StringData;
class BinaryData;
class Timestamp;
class Decimal128;

typedef int64_t Int;
typedef bool Bool;
typedef float Float;
typedef double Double;
typedef realm::StringData String;
typedef realm::BinaryData Binary;
typedef realm::Decimal128 Decimal;

struct ColumnType;

struct DataType {
    enum class Type {
        // Note: Value assignments must be kept in sync with <realm/column_type.h>
        // Note: Any change to this enum is a file-format breaking change.
        Int = 0,
        Bool = 1,
        String = 2,
        Binary = 4,
        Mixed = 6,
        Timestamp = 8,
        Float = 9,
        Double = 10,
        Decimal = 11,
        Link = 12,
        LinkList = 13,
        ObjectId = 15,
        TypedLink = 16,
        UUID = 17,
    };

    constexpr explicit DataType(int t) noexcept
        : m_type(Type(t))
    {
    }

    constexpr DataType(Type t = Type::Int) noexcept
        : m_type(t)
    {
    }

    constexpr bool operator==(const DataType& rhs) const noexcept
    {
        return m_type == rhs.m_type;
    }
    constexpr bool operator!=(const DataType& rhs) const noexcept
    {
        return !(*this == rhs);
    }

    // Allow switch statements over the struct.
    constexpr operator Type() const noexcept
    {
        return m_type;
    }

    constexpr explicit operator int() const noexcept
    {
        return int(m_type);
    }

    constexpr explicit operator int64_t() const noexcept
    {
        return int64_t(m_type);
    }

    constexpr explicit operator uint64_t() const noexcept
    {
        return uint64_t(m_type);
    }

    // FIXME: Remove this
    constexpr explicit operator ColumnType() const noexcept;

    constexpr explicit operator util::Printable() const noexcept;

    constexpr bool is_valid() const noexcept
    {
        switch (m_type) {
            case Type::Int:
            case Type::Bool:
            case Type::String:
            case Type::Binary:
            case Type::Mixed:
            case Type::Timestamp:
            case Type::Float:
            case Type::Double:
            case Type::Decimal:
            case Type::Link:
            case Type::LinkList:
            case Type::ObjectId:
            case Type::TypedLink:
            case Type::UUID:
                return true;
        }
        return false;
    }

    Type m_type;
};

static constexpr DataType type_Int = DataType{DataType::Type::Int};
static constexpr DataType type_Bool = DataType{DataType::Type::Bool};
static constexpr DataType type_String = DataType{DataType::Type::String};
static constexpr DataType type_Binary = DataType{DataType::Type::Binary};
static constexpr DataType type_Mixed = DataType{DataType::Type::Mixed};
static constexpr DataType type_Timestamp = DataType{DataType::Type::Timestamp};
static constexpr DataType type_Float = DataType{DataType::Type::Float};
static constexpr DataType type_Double = DataType{DataType::Type::Double};
static constexpr DataType type_Decimal = DataType{DataType::Type::Decimal};
static constexpr DataType type_Link = DataType{DataType::Type::Link};
static constexpr DataType type_LinkList = DataType{DataType::Type::LinkList};
static constexpr DataType type_ObjectId = DataType{DataType::Type::ObjectId};
static constexpr DataType type_TypedLink = DataType{DataType::Type::TypedLink};
static constexpr DataType type_UUID = DataType{DataType::Type::UUID};

// Deprecated column types that must still be handled in migration code, but not
// in every enum everywhere. Note that `DataType::is_valid()` returns false for
// these.
static constexpr DataType type_OldTable = DataType{5};
static constexpr DataType type_OldDateTime = DataType{7};
static_assert(!type_OldTable.is_valid());
static_assert(!type_OldDateTime.is_valid());
static constexpr DataType type_TypeOfValue = DataType{18};
#if REALM_ENABLE_GEOSPATIAL
static constexpr DataType type_Geospatial = DataType{22};
#endif

constexpr inline DataType::operator util::Printable() const noexcept
{
    switch (*this) {
        case type_Int:
            return "type_Int";
        case type_Bool:
            return "type_Bool";
        case type_String:
            return "type_String";
        case type_Binary:
            return "type_Binary";
        case type_Mixed:
            return "type_Mixed";
        case type_Timestamp:
            return "type_Timestamp";
        case type_Float:
            return "type_Float";
        case type_Double:
            return "type_Double";
        case type_Decimal:
            return "type_Decimal";
        case type_Link:
            return "type_Link";
        case type_LinkList:
            return "type_LinkList";
        case type_ObjectId:
            return "type_ObjectId";
        case type_TypedLink:
            return "type_TypedLink";
        case type_UUID:
            return "type_UUID";
    }
    if (*this == type_OldTable) {
        return "type_OldTable";
    }
    if (*this == type_OldDateTime) {
        return "type_OldDateTime";
    }
    if (*this == type_TypeOfValue) {
        return "type_TypeOfValue";
    }
#if REALM_ENABLE_GEOSPATIAL
    if (*this == type_Geospatial) {
        return "type_Geospatial";
    }
#endif
    return "type_UNKNOWN";
}

template <class O>
constexpr inline O& operator<<(O& os, const DataType& data_type) noexcept
{
    util::Printable printable{data_type};
    printable.print(os, false);
    return os;
}

const char* get_data_type_name(DataType type) noexcept;

} // namespace realm

#endif // REALM_DATA_TYPE_HPP
