////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#ifndef REALM_PROPERTY_HPP
#define REALM_PROPERTY_HPP

#include <realm/util/features.h>
#include <realm/util/assert.hpp>
// FIXME: keys.hpp is currently pretty heavyweight
#include <realm/keys.hpp>
#include <realm/util/optional.hpp>
#include <realm/util/tagged_bool.hpp>

#include <string>

namespace realm {
class BinaryData;
class Decimal128;
class Obj;
class ObjectId;
class StringData;
class Table;
class Timestamp;
class UUID;
class Mixed;

enum class PropertyType : unsigned short {
    Int = 0,
    Bool = 1,
    String = 2,
    Data = 3,
    Date = 4,
    Float = 5,
    Double = 6,
    Object = 7,         // currently must be either Array xor Nullable
    LinkingObjects = 8, // currently must be Array and not Nullable

    Mixed = 9,
    ObjectId = 10,
    Decimal = 11,
    UUID = 12,

    // Flags which can be combined with any of the above types except as noted
    Required = 0,
    Nullable = 64,
    Array = 128,
    Set = 256,
    Dictionary = 512,

    Collection = Array | Set | Dictionary,
    Flags = Nullable | Collection
};

struct Property {
    using IsPrimary = util::TaggedBool<class IsPrimaryTag>;
    using IsIndexed = util::TaggedBool<class IsIndexedTag>;
    using IsFulltextIndexed = util::TaggedBool<class IsFulltextIndexedTag>;

    // The internal column name used in the Realm file.
    std::string name;

    // The public name used by the binding to represent the internal column name in the Realm file. Bindings can use
    // this to expose a different name in the binding API, e.g. to map between different naming conventions.
    //
    // Public names are only ever user defined, they are not persisted on disk, so reading the schema from the file
    // will leave this field empty. If `public_name` is empty, the internal and public name are considered to be the
    // same.
    //
    // ObjectStore will ensure that no conflicts occur between persisted properties and the public name, so
    // the public name is just as unique an identifier as the internal name in the file.
    //
    // In order to respect public names bindings should use `ObjectSchema::property_for_public_name()` in the schema
    // and `Object::value_for_property()` in the Object accessor for reading fields defined by the public name.
    //
    // For queries, bindings should provide an appropriate `KeyPathMapping` definition. Bindings are responsible
    // for creating this.
    std::string public_name;
    PropertyType type = PropertyType::Int;
    std::string object_type;
    std::string link_origin_property_name;
    IsPrimary is_primary = false;
    IsIndexed is_indexed = false;
    IsFulltextIndexed is_fulltext_indexed = false;

    ColKey column_key;

    Property() = default;

    Property(std::string name, PropertyType type, IsPrimary primary = false, IsIndexed indexed = false,
             std::string public_name = "");

    // Text property with fulltext index
    Property(std::string name, IsFulltextIndexed indexed, std::string public_name = "");

    Property(std::string name, PropertyType type, std::string object_type, std::string link_origin_property_name = "",
             std::string public_name = "");

    Property(Property const&) = default;
    Property(Property&&) noexcept = default;
    Property& operator=(Property const&) = default;
    Property& operator=(Property&&) noexcept = default;

    bool requires_index() const
    {
        return is_indexed || is_primary;
    }

    bool requires_fulltext_index() const
    {
        return is_fulltext_indexed;
    }

    bool type_is_indexable() const noexcept;
    bool type_is_nullable() const noexcept;

    std::string type_string() const;
};

template <typename E>
constexpr auto to_underlying(E e)
{
    return static_cast<typename std::underlying_type<E>::type>(e);
}

inline constexpr PropertyType operator&(PropertyType a, PropertyType b)
{
    return static_cast<PropertyType>(to_underlying(a) & to_underlying(b));
}

inline constexpr PropertyType operator|(PropertyType a, PropertyType b)
{
    return static_cast<PropertyType>(to_underlying(a) | to_underlying(b));
}

inline constexpr PropertyType operator^(PropertyType a, PropertyType b)
{
    return static_cast<PropertyType>(to_underlying(a) ^ to_underlying(b));
}

inline constexpr PropertyType operator~(PropertyType a)
{
    return static_cast<PropertyType>(~to_underlying(a));
}

inline constexpr bool operator==(PropertyType a, PropertyType b)
{
    return to_underlying(a & ~PropertyType::Flags) == to_underlying(b & ~PropertyType::Flags);
}

inline constexpr bool operator!=(PropertyType a, PropertyType b)
{
    return !(a == b);
}

inline PropertyType& operator&=(PropertyType& a, PropertyType b)
{
    a = a & b;
    return a;
}

inline PropertyType& operator|=(PropertyType& a, PropertyType b)
{
    a = a | b;
    return a;
}

inline PropertyType& operator^=(PropertyType& a, PropertyType b)
{
    a = a ^ b;
    return a;
}

inline constexpr bool is_array(PropertyType a)
{
    return to_underlying(a & PropertyType::Array) == to_underlying(PropertyType::Array);
}

inline constexpr bool is_set(PropertyType a)
{
    return to_underlying(a & PropertyType::Set) == to_underlying(PropertyType::Set);
}

inline constexpr bool is_dictionary(PropertyType a)
{
    return to_underlying(a & PropertyType::Dictionary) == to_underlying(PropertyType::Dictionary);
}

inline constexpr bool is_collection(PropertyType a)
{
    return to_underlying(a & PropertyType::Collection) != 0;
}

inline constexpr bool is_nullable(PropertyType a)
{
    return to_underlying(a & PropertyType::Nullable) == to_underlying(PropertyType::Nullable);
}

inline constexpr bool is_mixed(PropertyType a)
{
    return to_underlying(a & PropertyType::Mixed) == to_underlying(PropertyType::Mixed);
}

// Some of the places we use switch_on_type() the Obj version isn't instantiatable
// or reachable, so we want to map it to a valid type to let the unreachable code compile
template <typename T>
struct NonObjType {
    using type = std::remove_reference_t<T>;
};
template <>
struct NonObjType<Obj&> {
    using type = int64_t;
};
template <typename T>
using NonObjTypeT = typename NonObjType<T>::type;

template <typename ObjType = Obj, typename Fn>
static auto switch_on_type(PropertyType type, Fn&& fn)
{
    using PT = PropertyType;
    bool is_optional = is_nullable(type);
    switch (type & ~PropertyType::Flags) {
        case PT::Int:
            return is_optional ? fn((util::Optional<int64_t>*)0) : fn((int64_t*)0);
        case PT::Bool:
            return is_optional ? fn((util::Optional<bool>*)0) : fn((bool*)0);
        case PT::Float:
            return is_optional ? fn((util::Optional<float>*)0) : fn((float*)0);
        case PT::Double:
            return is_optional ? fn((util::Optional<double>*)0) : fn((double*)0);
        case PT::String:
            return fn((StringData*)0);
        case PT::Data:
            return fn((BinaryData*)0);
        case PT::Date:
            return fn((Timestamp*)0);
        case PT::Object:
            return fn((ObjType*)0);
        case PT::ObjectId:
            return is_optional ? fn((util::Optional<ObjectId>*)0) : fn((ObjectId*)0);
        case PT::Decimal:
            return fn((Decimal128*)0);
        case PT::UUID:
            return is_optional ? fn((util::Optional<UUID>*)0) : fn((UUID*)0);
        case PT::Mixed:
            return fn((Mixed*)0);
        default:
            REALM_COMPILER_HINT_UNREACHABLE();
    }
}

static const char* string_for_property_type(PropertyType type)
{
    if (is_array(type)) {
        if (type == PropertyType::LinkingObjects)
            return "linking objects";
        return "array";
    }
    if (is_set(type)) {
        return "set";
    }
    if (is_dictionary(type)) {
        return "dictionary";
    }
    switch (type & ~PropertyType::Flags) {
        case PropertyType::String:
            return "string";
        case PropertyType::Int:
            return "int";
        case PropertyType::Bool:
            return "bool";
        case PropertyType::Date:
            return "date";
        case PropertyType::Data:
            return "data";
        case PropertyType::Double:
            return "double";
        case PropertyType::Float:
            return "float";
        case PropertyType::Object:
            return "object";
        case PropertyType::Mixed:
            return "mixed";
        case PropertyType::UUID:
            return "uuid";
        case PropertyType::LinkingObjects:
            return "linking objects";
        case PropertyType::ObjectId:
            return "object id";
        case PropertyType::Decimal:
            return "decimal";
        default:
            REALM_COMPILER_HINT_UNREACHABLE();
    }
}

inline Property::Property(std::string name, PropertyType type, IsPrimary primary, IsIndexed indexed,
                          std::string public_name)
    : name(std::move(name))
    , public_name(std::move(public_name))
    , type(type)
    , is_primary(primary)
    , is_indexed(indexed)
{
}

inline Property::Property(std::string name, IsFulltextIndexed indexed, std::string public_name)
    : name(std::move(name))
    , public_name(std::move(public_name))
    , type(PropertyType::String)
    , is_fulltext_indexed(indexed)
{
}

inline Property::Property(std::string name, PropertyType type, std::string object_type,
                          std::string link_origin_property_name, std::string public_name)
    : name(std::move(name))
    , public_name(std::move(public_name))
    , type(type)
    , object_type(std::move(object_type))
    , link_origin_property_name(std::move(link_origin_property_name))
{
}

inline bool Property::type_is_indexable() const noexcept
{
    return !is_collection(type) &&
           (type == PropertyType::Int || type == PropertyType::Bool || type == PropertyType::Date ||
            type == PropertyType::String || type == PropertyType::ObjectId || type == PropertyType::UUID ||
            type == PropertyType::Mixed);
}

inline bool Property::type_is_nullable() const noexcept
{
    return !((is_array(type) || is_set(type)) && type == PropertyType::Object) &&
           type != PropertyType::LinkingObjects;
}

inline std::string Property::type_string() const
{
    if (is_array(type)) {
        if (type == PropertyType::Object)
            return "array<" + object_type + ">";
        if (type == PropertyType::LinkingObjects)
            return "linking objects<" + object_type + ">";
        return std::string("array<") + string_for_property_type(type & ~PropertyType::Flags) + ">";
    }
    if (is_set(type)) {
        REALM_ASSERT(type != PropertyType::LinkingObjects);
        if (type == PropertyType::Object)
            return "set<" + object_type + ">";
        return std::string("set<") + string_for_property_type(type & ~PropertyType::Flags) + ">";
    }
    if (is_dictionary(type)) {
        REALM_ASSERT(type != PropertyType::LinkingObjects);
        if (type == PropertyType::Object)
            return "dictionary<string, " + object_type + ">";
        return std::string("dictionary<string, ") + string_for_property_type(type & ~PropertyType::Flags) + ">";
    }
    switch (auto base_type = (type & ~PropertyType::Flags)) {
        case PropertyType::Object:
            return "<" + object_type + ">";
        case PropertyType::LinkingObjects:
            return "linking objects<" + object_type + ">";
        default:
            return string_for_property_type(base_type);
    }
}

inline bool operator==(Property const& lft, Property const& rgt)
{
    // note: not checking column_key
    // ordered roughly by the cost of the check
    return to_underlying(lft.type) == to_underlying(rgt.type) && lft.is_primary == rgt.is_primary &&
           lft.requires_index() == rgt.requires_index() &&
           lft.requires_fulltext_index() == rgt.requires_fulltext_index() && lft.name == rgt.name &&
           lft.object_type == rgt.object_type && lft.link_origin_property_name == rgt.link_origin_property_name;
}
} // namespace realm

#endif // REALM_PROPERTY_HPP
