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

#ifndef REALM_COLUMN_TYPE_HPP
#define REALM_COLUMN_TYPE_HPP

#include <realm/data_type.hpp>
#include <realm/util/assert.hpp>

namespace realm {

struct ColumnType {
    // Note: Enumeration value assignments must be kept in sync with
    // <realm/data_type.hpp>.
    enum class Type {
        // Column types
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
        BackLink = 14,
        ObjectId = 15,
        TypedLink = 16,
        UUID = 17
    };

    constexpr explicit ColumnType(int64_t t) noexcept
        : m_type(Type(t))
    {
    }

    constexpr ColumnType(Type t = Type::Int) noexcept
        : m_type(t)
    {
    }

    constexpr bool operator==(const ColumnType& rhs) const noexcept
    {
        return m_type == rhs.m_type;
    }
    constexpr bool operator!=(const ColumnType& rhs) const noexcept
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

    // FIXME: Remove this
    constexpr explicit operator DataType() const noexcept
    {
        return DataType(int(m_type));
    }

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
            case Type::BackLink:
            case Type::ObjectId:
            case Type::TypedLink:
            case Type::UUID:
                return true;
        }
        return false;
    }

    Type m_type = Type::Int;
};

static constexpr ColumnType col_type_Int = ColumnType{ColumnType::Type::Int};
static constexpr ColumnType col_type_Bool = ColumnType{ColumnType::Type::Bool};
static constexpr ColumnType col_type_String = ColumnType{ColumnType::Type::String};
static constexpr ColumnType col_type_Binary = ColumnType{ColumnType::Type::Binary};
static constexpr ColumnType col_type_Mixed = ColumnType{ColumnType::Type::Mixed};
static constexpr ColumnType col_type_Timestamp = ColumnType{ColumnType::Type::Timestamp};
static constexpr ColumnType col_type_Float = ColumnType{ColumnType::Type::Float};
static constexpr ColumnType col_type_Double = ColumnType{ColumnType::Type::Double};
static constexpr ColumnType col_type_Decimal = ColumnType{ColumnType::Type::Decimal};
static constexpr ColumnType col_type_Link = ColumnType{ColumnType::Type::Link};
static constexpr ColumnType col_type_LinkList = ColumnType{ColumnType::Type::LinkList};
static constexpr ColumnType col_type_BackLink = ColumnType{ColumnType::Type::BackLink};
static constexpr ColumnType col_type_ObjectId = ColumnType{ColumnType::Type::ObjectId};
static constexpr ColumnType col_type_TypedLink = ColumnType{ColumnType::Type::TypedLink};
static constexpr ColumnType col_type_UUID = ColumnType{ColumnType::Type::UUID};

// Deprecated column types that must still be handled in migration code, but not
// in every enum everywhere. Note that `ColumnType::is_valid()` returns false
// for these.
static constexpr ColumnType col_type_OldStringEnum = ColumnType{3};
static constexpr ColumnType col_type_OldTable = ColumnType{5};
static constexpr ColumnType col_type_OldDateTime = ColumnType{7};
static_assert(!col_type_OldStringEnum.is_valid());
static_assert(!col_type_OldTable.is_valid());
static_assert(!col_type_OldDateTime.is_valid());

enum class IndexType { None, General, Fulltext };

inline std::ostream& operator<<(std::ostream& ostr, IndexType type)
{
    switch (type) {
        case IndexType::None:
            ostr << "no index";
            break;
        case IndexType::General:
            ostr << "search index";
            break;
        case IndexType::Fulltext:
            ostr << "fulltext index";
            break;
    }
    return ostr;
}

// Column attributes can be combined using bitwise or.
enum ColumnAttr {
    col_attr_None = 0,
    col_attr_Indexed = 1,

    /// Specifies that this column forms a unique constraint. It requires
    /// `col_attr_Indexed`.
    col_attr_Unique = 2,

    /// Reserved for future use.
    col_attr_Reserved = 4,

    /// Specifies that the links of this column are strong, not weak. Applies
    /// only to link columns (`type_Link` and `type_LinkList`).
    col_attr_StrongLinks = 8,

    /// Specifies that elements in the column can be null.
    col_attr_Nullable = 16,

    /// Each element is a list of values
    col_attr_List = 32,

    /// Each element is a dictionary
    col_attr_Dictionary = 64,

    /// Each element is a set of values
    col_attr_Set = 128,

    /// Specifies that elements in the column are full-text indexed
    col_attr_FullText_Indexed = 256,

    /// Either list, dictionary, or set
    col_attr_Collection = 128 + 64 + 32
};

class ColumnAttrMask {
public:
    constexpr ColumnAttrMask()
        : m_value(0)
    {
    }
    bool test(ColumnAttr prop)
    {
        return (m_value & prop) != 0;
    }
    constexpr void set(ColumnAttr prop)
    {
        m_value |= prop;
    }
    void reset(ColumnAttr prop)
    {
        m_value &= ~prop;
    }
    bool operator==(const ColumnAttrMask& other) const
    {
        return m_value == other.m_value;
    }
    bool operator!=(const ColumnAttrMask& other) const
    {
        return m_value != other.m_value;
    }

private:
    friend class Spec;
    friend struct ColKey;
    friend class Table;
    int m_value;
    ColumnAttrMask(int64_t val)
        : m_value(int(val))
    {
    }
};

constexpr inline ColumnType::operator util::Printable() const noexcept
{
    switch (*this) {
        case col_type_Int:
            return "col_type_Int";
        case col_type_Bool:
            return "col_type_Bool";
        case col_type_String:
            return "col_type_String";
        case col_type_Binary:
            return "col_type_Binary";
        case col_type_Mixed:
            return "col_type_Mixed";
        case col_type_Timestamp:
            return "col_type_Timestamp";
        case col_type_Float:
            return "col_type_Float";
        case col_type_Double:
            return "col_type_Double";
        case col_type_Decimal:
            return "col_type_Decimal";
        case col_type_Link:
            return "col_type_Link";
        case col_type_LinkList:
            return "col_type_LinkList";
        case col_type_BackLink:
            return "col_type_BackLink";
        case col_type_ObjectId:
            return "col_type_ObjectId";
        case col_type_TypedLink:
            return "col_type_TypedLink";
        case col_type_UUID:
            return "col_type_UUID";
    }
    if (*this == col_type_OldTable) {
        return "col_type_OldTable";
    }
    if (*this == col_type_OldDateTime) {
        return "col_type_OldDateTime";
    }
    if (*this == col_type_OldStringEnum) {
        return "col_type_OldStringEnum";
    }
    return int(m_type);
}

template <class O>
constexpr inline O& operator<<(O& os, const ColumnType& col_type) noexcept
{
    util::Printable printable{col_type};
    printable.print(os, false);
    return os;
}

constexpr inline DataType::operator ColumnType() const noexcept
{
    return ColumnType(int(*this));
}

} // namespace realm

#endif // REALM_COLUMN_TYPE_HPP
