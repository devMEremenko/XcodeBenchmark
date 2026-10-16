////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#ifndef REALM_OS_OBJECT_ACCESSOR_IMPL_HPP
#define REALM_OS_OBJECT_ACCESSOR_IMPL_HPP

#include <realm/object-store/object_accessor.hpp>
#include <realm/object-store/schema.hpp>

#if REALM_ENABLE_GEOSPATIAL
#include <realm/geospatial.hpp>
#endif
#include <realm/util/any.hpp>

namespace realm {
using AnyDict = std::map<std::string, std::any>;
using AnyVector = std::vector<std::any>;

// An object accessor context which can be used to create and access objects
// using std::any as the type-erased value type. In addition, this serves as
// the reference implementation of an accessor context that must be implemented
// by each binding.
class CppContext {
public:
    // This constructor is the only one used by the object accessor code, and is
    // used when recurring into a link or array property during object creation
    // (i.e. prop.type will always be Object or Array).
    CppContext(CppContext& c, Obj parent, Property const& prop)
        : realm(c.realm)
        , object_schema(prop.type == PropertyType::Object ? &*realm->schema().find(prop.object_type)
                                                          : c.object_schema)
        , m_parent(std::move(parent))
        , m_property(&prop)
    {
    }

    CppContext() = default;
    CppContext(std::shared_ptr<Realm> realm, const ObjectSchema* os = nullptr)
        : realm(std::move(realm))
        , object_schema(os)
    {
    }

    // The use of util::Optional for the following two functions is not a hard
    // requirement; only that it be some type which can be evaluated in a
    // boolean context to determine if it contains a value, and if it does
    // contain a value it must be dereferencable to obtain that value.

    // Get the value for a property in an input object, or `util::none` if no
    // value present. The property is identified both by the name of the
    // property and its index within the ObjectScehma's persisted_properties
    // array.
    util::Optional<std::any> value_for_property(std::any& dict, const Property& prop,
                                                size_t /* property_index */) const
    {
#if REALM_ENABLE_GEOSPATIAL
        if (auto geo = std::any_cast<Geospatial>(&dict)) {
            if (prop.name == Geospatial::c_geo_point_type_col_name) {
                return geo->get_type_string();
            }
            else if (prop.name == Geospatial::c_geo_point_coords_col_name) {
                std::vector<std::any> coords;
                auto&& point = geo->get<GeoPoint>(); // throws
                coords.push_back(point.longitude);
                coords.push_back(point.latitude);
                if (point.has_altitude()) {
                    coords.push_back(*point.get_altitude());
                }
                return coords;
            }
            REALM_ASSERT_EX(false, prop.name); // unexpected property type
        }
#endif
        auto const& v = util::any_cast<AnyDict&>(dict);
        auto it = v.find(prop.name);
        return it == v.end() ? util::none : util::make_optional(it->second);
    }

    // Get the default value for the given property in the given object schema,
    // or `util::none` if there is none (which is distinct from the default
    // being `null`).
    //
    // This implementation does not support default values; see the default
    // value tests for an example of one which does.
    util::Optional<std::any> default_value_for_property(ObjectSchema const&, Property const&) const
    {
        return util::none;
    }

    // Invoke `fn` with each of the values from an enumerable type
    template <typename Func>
    void enumerate_collection(std::any& value, Func&& fn)
    {
        for (auto&& v : util::any_cast<AnyVector&>(value))
            fn(v);
    }

    template <typename Func>
    void enumerate_dictionary(std::any& value, Func&& fn)
    {
        for (auto&& v : util::any_cast<AnyDict&>(value))
            fn(v.first, v.second);
    }

    // Determine if `value` boxes the same Set as `set`
    bool is_same_set(object_store::Set const& set, std::any const& value)
    {
        if (auto set2 = std::any_cast<object_store::Set>(&value))
            return set == *set2;
        return false;
    }

    // Determine if `value` boxes the same List as `list`
    bool is_same_list(List const& list, std::any const& value)
    {
        if (auto list2 = std::any_cast<List>(&value))
            return list == *list2;
        return false;
    }

    // Determine if `value` boxes the same Dictionary as `dict`
    bool is_same_dictionary(const object_store::Dictionary& dict, const std::any& value)
    {
        if (auto dict2 = std::any_cast<object_store::Dictionary>(&value))
            return dict == *dict2;
        return false;
    }

    // Convert from core types to the boxed type
    std::any box(BinaryData v) const
    {
        return std::string(v);
    }
    std::any box(List v) const
    {
        return v;
    }
    std::any box(object_store::Set s) const
    {
        return s;
    }
    std::any box(object_store::Dictionary v) const
    {
        return v;
    }

    std::any box(Object v) const
    {
        return v;
    }
    std::any box(Results v) const
    {
        return v;
    }
    std::any box(StringData v) const
    {
        return std::string(v);
    }
    std::any box(Timestamp v) const
    {
        return v;
    }
    std::any box(bool v) const
    {
        return v;
    }
    std::any box(double v) const
    {
        return v;
    }
    std::any box(float v) const
    {
        return v;
    }
    std::any box(int64_t v) const
    {
        return v;
    }
    std::any box(ObjectId v) const
    {
        return v;
    }
    std::any box(Decimal v) const
    {
        return v;
    }
    std::any box(UUID v) const
    {
        return v;
    }
    std::any box(util::Optional<bool> v) const
    {
        return v;
    }
    std::any box(util::Optional<double> v) const
    {
        return v;
    }
    std::any box(util::Optional<float> v) const
    {
        return v;
    }
    std::any box(util::Optional<int64_t> v) const
    {
        return v;
    }
    std::any box(util::Optional<ObjectId> v) const
    {
        return v;
    }
    std::any box(util::Optional<UUID> v) const
    {
        return v;
    }
    std::any box(Obj) const;

    std::any box(Mixed v) const
    {
        return v;
    }

    // Convert from the boxed type to core types. This needs to be implemented
    // for all of the types which `box()` can take, plus `Obj` and optional
    // versions of the numeric types, minus `List` and `Results`.
    //
    // `create` and `update` are only applicable to `unbox<Obj>`. If
    // `create` is false then when given something which is not a managed Realm
    // object `unbox()` should simply return a detached obj, while if it's
    // true then `unbox()` should create a new object in the context's Realm
    // using the provided value. If `update` is true then upsert semantics
    // should be used for this.
    // If `update_only_diff` is true, only properties that are different from
    // already existing properties should be updated. If `create` and `update_only_diff`
    // is true, `current_row` may hold a reference to the object that should
    // be compared against.
    template <typename T>
    T unbox(std::any& v, CreatePolicy = CreatePolicy::Skip, ObjKey /*current_row*/ = ObjKey()) const
    {
        return util::any_cast<T>(v);
    }

    Obj create_embedded_object();

    bool is_null(std::any const& v) const noexcept
    {
        return !v.has_value();
    }
    std::any null_value() const noexcept
    {
        return {};
    }
    util::Optional<std::any> no_value() const noexcept
    {
        return {};
    }

    // KVO hooks which will be called before and after modying a property from
    // within Object::create().
    void will_change(Object const&, Property const&) {}
    void did_change() {}

    // Get a string representation of the given value for use in error messages.
    std::string print(std::any const&) const
    {
        return "not implemented";
    }

    // Cocoa allows supplying fewer values than there are properties when
    // creating objects using an array of values. Other bindings should not
    // mimick this behavior so just return false here.
    bool allow_missing(std::any const&) const
    {
        return false;
    }

private:
    std::shared_ptr<Realm> realm;
    const ObjectSchema* object_schema = nullptr;
    Obj m_parent;
    const Property* m_property = nullptr;
};

inline std::any CppContext::box(Obj obj) const
{
    REALM_ASSERT(object_schema);
    return Object(realm, *object_schema, obj);
}

template <>
inline StringData CppContext::unbox(std::any& v, CreatePolicy, ObjKey) const
{
    if (!v.has_value())
        return StringData();
    auto& value = util::any_cast<std::string&>(v);
    return StringData(value.c_str(), value.size());
}

template <>
inline BinaryData CppContext::unbox(std::any& v, CreatePolicy, ObjKey) const
{
    if (!v.has_value())
        return BinaryData();
    auto& value = util::any_cast<std::string&>(v);
    return BinaryData(value.c_str(), value.size());
}

template <>
inline Obj CppContext::unbox(std::any& v, CreatePolicy policy, ObjKey current_obj) const
{
    if (auto object = std::any_cast<Object>(&v))
        return object->get_obj();
    if (auto obj = std::any_cast<Obj>(&v))
        return *obj;
    if (!policy.create)
        return Obj();

    REALM_ASSERT(object_schema);
    return Object::create(const_cast<CppContext&>(*this), realm, *object_schema, v, policy, current_obj).get_obj();
}

template <>
inline util::Optional<bool> CppContext::unbox(std::any& v, CreatePolicy, ObjKey) const
{
    return v.has_value() ? util::make_optional(unbox<bool>(v)) : util::none;
}

template <>
inline util::Optional<int64_t> CppContext::unbox(std::any& v, CreatePolicy, ObjKey) const
{
    return v.has_value() ? util::make_optional(unbox<int64_t>(v)) : util::none;
}

template <>
inline util::Optional<double> CppContext::unbox(std::any& v, CreatePolicy, ObjKey) const
{
    return v.has_value() ? util::make_optional(unbox<double>(v)) : util::none;
}

template <>
inline util::Optional<float> CppContext::unbox(std::any& v, CreatePolicy, ObjKey) const
{
    return v.has_value() ? util::make_optional(unbox<float>(v)) : util::none;
}

template <>
inline util::Optional<ObjectId> CppContext::unbox(std::any& v, CreatePolicy, ObjKey) const
{
    return v.has_value() ? util::make_optional(unbox<ObjectId>(v)) : util::none;
}

template <>
inline util::Optional<UUID> CppContext::unbox(std::any& v, CreatePolicy, ObjKey) const
{
    return v.has_value() ? util::make_optional(unbox<UUID>(v)) : util::none;
}

template <>
inline Mixed CppContext::unbox(std::any& v, CreatePolicy, ObjKey) const
{
    if (v.has_value()) {
        const std::type_info& this_type{v.type()};
        if (this_type == typeid(Mixed)) {
            return util::any_cast<Mixed>(v);
        }
        else if (this_type == typeid(int)) {
            return Mixed(util::any_cast<int>(v));
        }
        else if (this_type == typeid(int64_t)) {
            return Mixed(util::any_cast<int64_t>(v));
        }
        else if (this_type == typeid(std::string)) {
            auto& value = util::any_cast<std::string&>(v);
            return Mixed(value);
        }
        else if (this_type == typeid(Timestamp)) {
            return Mixed(util::any_cast<Timestamp>(v));
        }
        else if (this_type == typeid(double)) {
            return Mixed(util::any_cast<double>(v));
        }
        else if (this_type == typeid(float)) {
            return Mixed(util::any_cast<float>(v));
        }
        else if (this_type == typeid(bool)) {
            return Mixed(util::any_cast<bool>(v));
        }
        else if (this_type == typeid(Decimal128)) {
            return Mixed(util::any_cast<Decimal128>(v));
        }
        else if (this_type == typeid(ObjectId)) {
            return Mixed(util::any_cast<ObjectId>(v));
        }
        else if (this_type == typeid(UUID)) {
            return Mixed(util::any_cast<UUID>(v));
        }
    }
    return Mixed{};
}

inline Obj CppContext::create_embedded_object()
{
    return m_parent.create_and_set_linked_object(m_property->column_key);
}
} // namespace realm

#endif // REALM_OS_OBJECT_ACCESSOR_IMPL_HPP
