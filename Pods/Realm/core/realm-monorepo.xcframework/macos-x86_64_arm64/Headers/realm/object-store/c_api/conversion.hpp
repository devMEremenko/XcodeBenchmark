#ifndef REALM_OBJECT_STORE_C_API_CONVERSION_HPP
#define REALM_OBJECT_STORE_C_API_CONVERSION_HPP

#include <realm.h>

#include <realm/object-store/property.hpp>
#include <realm/object-store/schema.hpp>
#include <realm/object-store/object_schema.hpp>
#include <realm/object-store/shared_realm.hpp>

#include <realm/string_data.hpp>
#include <realm/binary_data.hpp>
#include <realm/timestamp.hpp>
#include <realm/decimal128.hpp>
#include <realm/object_id.hpp>
#include <realm/mixed.hpp>
#include <realm/uuid.hpp>

#include <string>

namespace realm::c_api {

static inline realm_string_t to_capi(StringData data)
{
    return realm_string_t{data.data(), data.size()};
}

// Because this is often used as `return to_capi(...);` it is dangerous to pass a temporary string here. If you really
// need to and know it is correct (eg passing to a C callback), you can explicitly create the StringData wrapper.
realm_string_t to_capi(const std::string&& str) = delete; // temporary std::string would dangle.

static inline realm_string_t to_capi(const std::string& str)
{
    return to_capi(StringData{str});
}

static inline realm_string_t to_capi(std::string_view str_view)
{
    return realm_string_t{str_view.data(), str_view.size()};
}

static inline StringData from_capi(realm_string_t str)
{
    return StringData{str.data, str.size};
}

static inline realm_binary_t to_capi(BinaryData bin)
{
    return realm_binary_t{reinterpret_cast<const unsigned char*>(bin.data()), bin.size()};
}

static inline BinaryData from_capi(realm_binary_t bin)
{
    return BinaryData{reinterpret_cast<const char*>(bin.data), bin.size};
}

static inline realm_timestamp_t to_capi(Timestamp ts)
{
    return realm_timestamp_t{ts.get_seconds(), ts.get_nanoseconds()};
}

static inline Timestamp from_capi(realm_timestamp_t ts)
{
    return Timestamp{ts.seconds, ts.nanoseconds};
}

static inline realm_decimal128_t to_capi(const Decimal128& dec)
{
    auto raw = dec.raw();
    return realm_decimal128_t{{raw->w[0], raw->w[1]}};
}

static inline Decimal128 from_capi(realm_decimal128_t dec)
{
    return Decimal128{Decimal128::Bid128{{dec.w[0], dec.w[1]}}};
}

static inline realm_object_id_t to_capi(ObjectId object_id)
{
    realm_object_id_t result;
    auto bytes = object_id.to_bytes();
    std::copy(bytes.begin(), bytes.end(), result.bytes);
    return result;
}

static inline ObjectId from_capi(realm_object_id_t object_id)
{
    static_assert(ObjectId::num_bytes == 12);
    ObjectId::ObjectIdBytes bytes;
    std::copy(object_id.bytes, object_id.bytes + 12, bytes.begin());
    return ObjectId(bytes);
}

static inline ObjLink from_capi(realm_link_t val)
{
    return ObjLink{TableKey(val.target_table), ObjKey(val.target)};
}

static inline realm_link_t to_capi(ObjLink link)
{
    return realm_link_t{link.get_table_key().value, link.get_obj_key().value};
}

static inline UUID from_capi(realm_uuid_t val)
{
    static_assert(sizeof(val.bytes) == UUID::num_bytes);
    UUID::UUIDBytes bytes;
    std::copy(val.bytes, val.bytes + UUID::num_bytes, bytes.data());
    return UUID{bytes};
}

static inline realm_uuid_t to_capi(UUID val)
{
    realm_uuid_t uuid;
    auto bytes = val.to_bytes();
    std::copy(bytes.data(), bytes.data() + UUID::num_bytes, uuid.bytes);
    return uuid;
}

static inline Mixed from_capi(realm_value_t val)
{
    switch (val.type) {
        case RLM_TYPE_NULL:
            return Mixed{};
        case RLM_TYPE_INT:
            return Mixed{val.integer};
        case RLM_TYPE_BOOL:
            return Mixed{val.boolean};
        case RLM_TYPE_STRING:
            return Mixed{from_capi(val.string)};
        case RLM_TYPE_BINARY:
            return Mixed{from_capi(val.binary)};
        case RLM_TYPE_TIMESTAMP:
            return Mixed{from_capi(val.timestamp)};
        case RLM_TYPE_FLOAT:
            return Mixed{val.fnum};
        case RLM_TYPE_DOUBLE:
            return Mixed{val.dnum};
        case RLM_TYPE_DECIMAL128:
            return Mixed{from_capi(val.decimal128)};
        case RLM_TYPE_OBJECT_ID:
            return Mixed{from_capi(val.object_id)};
        case RLM_TYPE_LINK:
            return Mixed{ObjLink{TableKey(val.link.target_table), ObjKey(val.link.target)}};
        case RLM_TYPE_UUID:
            return Mixed{UUID{from_capi(val.uuid)}};
    }
    REALM_TERMINATE("Invalid realm_value_t"); // LCOV_EXCL_LINE
}

static inline realm_value_t to_capi(Mixed value)
{
    realm_value_t val;
    if (value.is_null()) {
        val.type = RLM_TYPE_NULL;
    }
    else {
        switch (value.get_type()) {
            case type_Int: {
                val.type = RLM_TYPE_INT;
                val.integer = value.get<int64_t>();
                break;
            }
            case type_Bool: {
                val.type = RLM_TYPE_BOOL;
                val.boolean = value.get<bool>();
                break;
            }
            case type_String: {
                val.type = RLM_TYPE_STRING;
                val.string = to_capi(value.get<StringData>());
                break;
            }
            case type_Binary: {
                val.type = RLM_TYPE_BINARY;
                val.binary = to_capi(value.get<BinaryData>());
                break;
            }
            case type_Timestamp: {
                val.type = RLM_TYPE_TIMESTAMP;
                val.timestamp = to_capi(value.get<Timestamp>());
                break;
            }
            case type_Float: {
                val.type = RLM_TYPE_FLOAT;
                val.fnum = value.get<float>();
                break;
            }
            case type_Double: {
                val.type = RLM_TYPE_DOUBLE;
                val.dnum = value.get<double>();
                break;
            }
            case type_Decimal: {
                val.type = RLM_TYPE_DECIMAL128;
                val.decimal128 = to_capi(value.get<Decimal128>());
                break;
            }
            case type_Link: {
                REALM_TERMINATE("Not implemented yet"); // LCOV_EXCL_LINE
            }
            case type_ObjectId: {
                val.type = RLM_TYPE_OBJECT_ID;
                val.object_id = to_capi(value.get<ObjectId>());
                break;
            }
            case type_TypedLink: {
                val.type = RLM_TYPE_LINK;
                auto link = value.get<ObjLink>();
                val.link.target_table = link.get_table_key().value;
                val.link.target = link.get_obj_key().value;
                break;
            }
            case type_UUID: {
                val.type = RLM_TYPE_UUID;
                auto uuid = value.get<UUID>();
                val.uuid = to_capi(uuid);
                break;
            }

            case type_LinkList:
            case type_Mixed:
                REALM_TERMINATE("Invalid Mixed value type"); // LCOV_EXCL_LINE
        }
    }

    return val;
}

static inline SchemaMode from_capi(realm_schema_mode_e mode)
{
    switch (mode) {
        case RLM_SCHEMA_MODE_AUTOMATIC:
            return SchemaMode::Automatic;
        case RLM_SCHEMA_MODE_IMMUTABLE:
            return SchemaMode::Immutable;
        case RLM_SCHEMA_MODE_READ_ONLY:
            return SchemaMode::ReadOnly;
        case RLM_SCHEMA_MODE_SOFT_RESET_FILE:
            return SchemaMode::SoftResetFile;
        case RLM_SCHEMA_MODE_HARD_RESET_FILE:
            return SchemaMode::HardResetFile;
        case RLM_SCHEMA_MODE_ADDITIVE_DISCOVERED:
            return SchemaMode::AdditiveDiscovered;
        case RLM_SCHEMA_MODE_ADDITIVE_EXPLICIT:
            return SchemaMode::AdditiveExplicit;
        case RLM_SCHEMA_MODE_MANUAL:
            return SchemaMode::Manual;
    }
    REALM_TERMINATE("Invalid schema mode."); // LCOV_EXCL_LINE
}

static inline realm_schema_mode_e to_capi(SchemaMode mode)
{
    switch (mode) {
        case SchemaMode::Automatic:
            return RLM_SCHEMA_MODE_AUTOMATIC;
        case SchemaMode::Immutable:
            return RLM_SCHEMA_MODE_IMMUTABLE;
        case SchemaMode::ReadOnly:
            return RLM_SCHEMA_MODE_READ_ONLY;
        case SchemaMode::SoftResetFile:
            return RLM_SCHEMA_MODE_SOFT_RESET_FILE;
        case SchemaMode::HardResetFile:
            return RLM_SCHEMA_MODE_HARD_RESET_FILE;
        case SchemaMode::AdditiveDiscovered:
            return RLM_SCHEMA_MODE_ADDITIVE_DISCOVERED;
        case SchemaMode::AdditiveExplicit:
            return RLM_SCHEMA_MODE_ADDITIVE_EXPLICIT;
        case SchemaMode::Manual:
            return RLM_SCHEMA_MODE_MANUAL;
    }
    REALM_TERMINATE("Invalid schema mode."); // LCOV_EXCL_LINE
}

static inline SchemaSubsetMode from_capi(realm_schema_subset_mode_e subset_mode)
{
    switch (subset_mode) {
        case RLM_SCHEMA_SUBSET_MODE_ALL_CLASSES:
            return SchemaSubsetMode::AllClasses;
        case RLM_SCHEMA_SUBSET_MODE_ALL_PROPERTIES:
            return SchemaSubsetMode::AllProperties;
        case RLM_SCHEMA_SUBSET_MODE_COMPLETE:
            return SchemaSubsetMode::Complete;
        case RLM_SCHEMA_SUBSET_MODE_STRICT:
            return SchemaSubsetMode::Strict;
    }
    REALM_TERMINATE("Invalid subset schema mode."); // LCOV_EXCL_LINE
}

static inline realm_schema_subset_mode_e to_capi(const SchemaSubsetMode& subset_mode)
{
    if (subset_mode == SchemaSubsetMode::AllClasses)
        return RLM_SCHEMA_SUBSET_MODE_ALL_CLASSES;
    else if (subset_mode == SchemaSubsetMode::AllProperties)
        return RLM_SCHEMA_SUBSET_MODE_ALL_PROPERTIES;
    else if (subset_mode == SchemaSubsetMode::Complete)
        return RLM_SCHEMA_SUBSET_MODE_COMPLETE;
    else if (subset_mode == SchemaSubsetMode::Strict)
        return RLM_SCHEMA_SUBSET_MODE_STRICT;
    REALM_TERMINATE("Invalid subset schema mode."); // LCOV_EXCL_LINE
}

static inline realm_property_type_e to_capi(PropertyType type) noexcept
{
    type &= ~PropertyType::Flags;

    switch (type) {
        case PropertyType::Int:
            return RLM_PROPERTY_TYPE_INT;
        case PropertyType::Bool:
            return RLM_PROPERTY_TYPE_BOOL;
        case PropertyType::String:
            return RLM_PROPERTY_TYPE_STRING;
        case PropertyType::Data:
            return RLM_PROPERTY_TYPE_BINARY;
        case PropertyType::Mixed:
            return RLM_PROPERTY_TYPE_MIXED;
        case PropertyType::Date:
            return RLM_PROPERTY_TYPE_TIMESTAMP;
        case PropertyType::Float:
            return RLM_PROPERTY_TYPE_FLOAT;
        case PropertyType::Double:
            return RLM_PROPERTY_TYPE_DOUBLE;
        case PropertyType::Decimal:
            return RLM_PROPERTY_TYPE_DECIMAL128;
        case PropertyType::Object:
            return RLM_PROPERTY_TYPE_OBJECT;
        case PropertyType::LinkingObjects:
            return RLM_PROPERTY_TYPE_LINKING_OBJECTS;
        case PropertyType::ObjectId:
            return RLM_PROPERTY_TYPE_OBJECT_ID;
        case PropertyType::UUID:
            return RLM_PROPERTY_TYPE_UUID;
        // LCOV_EXCL_START
        case PropertyType::Nullable:
            [[fallthrough]];
        case PropertyType::Flags:
            [[fallthrough]];
        case PropertyType::Set:
            [[fallthrough]];
        case PropertyType::Dictionary:
            [[fallthrough]];
        case PropertyType::Collection:
            [[fallthrough]];
        case PropertyType::Array:
            REALM_UNREACHABLE();
            // LCOV_EXCL_STOP
    }
    REALM_TERMINATE("Unsupported property type"); // LCOV_EXCL_LINE
}

static inline PropertyType from_capi(realm_property_type_e type) noexcept
{
    switch (type) {
        case RLM_PROPERTY_TYPE_INT:
            return PropertyType::Int;
        case RLM_PROPERTY_TYPE_BOOL:
            return PropertyType::Bool;
        case RLM_PROPERTY_TYPE_STRING:
            return PropertyType::String;
        case RLM_PROPERTY_TYPE_BINARY:
            return PropertyType::Data;
        case RLM_PROPERTY_TYPE_MIXED:
            return PropertyType::Mixed;
        case RLM_PROPERTY_TYPE_TIMESTAMP:
            return PropertyType::Date;
        case RLM_PROPERTY_TYPE_FLOAT:
            return PropertyType::Float;
        case RLM_PROPERTY_TYPE_DOUBLE:
            return PropertyType::Double;
        case RLM_PROPERTY_TYPE_DECIMAL128:
            return PropertyType::Decimal;
        case RLM_PROPERTY_TYPE_OBJECT:
            return PropertyType::Object;
        case RLM_PROPERTY_TYPE_LINKING_OBJECTS:
            return PropertyType::LinkingObjects;
        case RLM_PROPERTY_TYPE_OBJECT_ID:
            return PropertyType::ObjectId;
        case RLM_PROPERTY_TYPE_UUID:
            return PropertyType::UUID;
    }
    REALM_TERMINATE("Unsupported property type"); // LCOV_EXCL_LINE
}


static inline Property from_capi(const realm_property_info_t& p) noexcept
{
    Property prop;
    prop.name = p.name;
    prop.public_name = p.public_name;
    prop.type = from_capi(p.type);
    prop.object_type = p.link_target;
    prop.link_origin_property_name = p.link_origin_property_name;
    prop.is_primary = Property::IsPrimary{bool(p.flags & RLM_PROPERTY_PRIMARY_KEY)};
    prop.is_indexed = Property::IsIndexed{bool(p.flags & RLM_PROPERTY_INDEXED)};
    prop.is_fulltext_indexed = Property::IsFulltextIndexed{bool(p.flags & RLM_PROPERTY_FULLTEXT_INDEXED)};

    if (bool(p.flags & RLM_PROPERTY_NULLABLE)) {
        prop.type |= PropertyType::Nullable;
    }
    switch (p.collection_type) {
        case RLM_COLLECTION_TYPE_NONE:
            break;
        case RLM_COLLECTION_TYPE_LIST: {
            prop.type |= PropertyType::Array;
            break;
        }
        case RLM_COLLECTION_TYPE_SET: {
            prop.type |= PropertyType::Set;
            break;
        }
        case RLM_COLLECTION_TYPE_DICTIONARY: {
            prop.type |= PropertyType::Dictionary;
            break;
        }
    }
    return prop;
}

static inline realm_property_info_t to_capi(const Property& prop) noexcept
{
    realm_property_info_t p;
    p.name = prop.name.c_str();
    p.public_name = prop.public_name.c_str();
    p.type = to_capi(prop.type & ~PropertyType::Flags);
    p.link_target = prop.object_type.c_str();
    p.link_origin_property_name = prop.link_origin_property_name.c_str();

    p.flags = RLM_PROPERTY_NORMAL;
    if (prop.is_indexed)
        p.flags |= RLM_PROPERTY_INDEXED;
    if (prop.is_fulltext_indexed)
        p.flags |= RLM_PROPERTY_FULLTEXT_INDEXED;
    if (prop.is_primary)
        p.flags |= RLM_PROPERTY_PRIMARY_KEY;
    if (bool(prop.type & PropertyType::Nullable))
        p.flags |= RLM_PROPERTY_NULLABLE;

    p.collection_type = RLM_COLLECTION_TYPE_NONE;
    if (bool(prop.type & PropertyType::Array))
        p.collection_type = RLM_COLLECTION_TYPE_LIST;
    if (bool(prop.type & PropertyType::Set))
        p.collection_type = RLM_COLLECTION_TYPE_SET;
    if (bool(prop.type & PropertyType::Dictionary))
        p.collection_type = RLM_COLLECTION_TYPE_DICTIONARY;

    p.key = prop.column_key.value;

    return p;
}

static inline realm_class_info_t to_capi(const ObjectSchema& o)
{
    realm_class_info_t info;
    info.name = o.name.c_str();
    info.primary_key = o.primary_key.c_str();
    info.num_properties = o.persisted_properties.size();
    info.num_computed_properties = o.computed_properties.size();
    info.key = o.table_key.value;
    switch (o.table_type) {
        case ObjectSchema::ObjectType::Embedded: {
            info.flags = RLM_CLASS_EMBEDDED;
            break;
        }
        case ObjectSchema::ObjectType::TopLevelAsymmetric: {
            info.flags = RLM_CLASS_ASYMMETRIC;
            break;
        }
        case ObjectSchema::ObjectType::TopLevel: {
            info.flags = RLM_CLASS_NORMAL;
            break;
        }
        default:
            REALM_TERMINATE(util::format("Invalid table type: %1", uint8_t(o.table_type)).c_str());
    }
    return info;
}

static inline realm_version_id_t to_capi(const VersionID& v)
{
    realm_version_id_t version_id;
    version_id.version = v.version;
    version_id.index = v.index;
    return version_id;
}

static inline realm_error_t to_capi(const Status& s)
{
    realm_error_t err;
    err.error = static_cast<realm_errno_e>(s.code());
    err.categories = static_cast<realm_error_category_e>(ErrorCodes::error_categories(s.code()).value());
    err.message = s.reason().c_str();
    return err;
}

} // namespace realm::c_api


#endif // REALM_OBJECT_STORE_C_API_CONVERSION_HPP
