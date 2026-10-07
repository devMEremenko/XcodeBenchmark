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

#ifndef REALM_OS_OBJECT_HPP
#define REALM_OS_OBJECT_HPP

#include <realm/object-store/impl/collection_notifier.hpp>

#include <realm/obj.hpp>

namespace realm {
class ObjectSchema;
struct Property;

namespace _impl {
class ObjectNotifier;
}

/// Options for how objects should be unboxed by a context.
///
/// unbox<Obj>() is used for several different operations which want an Obj
/// from a SDK type. CreatePolicy packs together all of the different options
/// around what unbox() should do.
struct CreatePolicy {
    /// If given something that is not a managed Object, should an object be
    /// created in the Realm? False for pure lookup functions such as find(),
    /// index_of() and queries, true for everything else.
    bool create : 1;
    /// Should the input object be copied into the Realm even if it is already
    /// an object managed by the current Realm? True for realm.create(), false
    /// for things like setting a link property.
    bool copy : 1;
    /// If the object has a primary key and an object with the same primary key
    /// already exists, should the existing object be updated rather than
    /// throwing an exception? Only meaningful if .create is true.
    bool update : 1;
    /// When updating an object, should the old and new objects be diffed and
    /// only the values which are different be set, or should all fields be set?
    /// Only meaningful if .create and .update are true.
    bool diff : 1;

    // Shorthand aliases for some of the common configurations

    /// {.create = false}}
    static CreatePolicy Skip;
    /// {.create = true, .copy = true, .update = false}
    static CreatePolicy ForceCreate;
    /// {.create = true, .copy = true, .update = true, .diff = false}
    static CreatePolicy UpdateAll;
    /// {.create = true, .copy = true, .update = true, .diff = true}
    static CreatePolicy UpdateModified;
    /// {.create = true, .copy = false, .update = false, .diff = false}
    static CreatePolicy SetLink;
};

class Object {
public:
    Object();
    Object(const std::shared_ptr<Realm>& r, Obj const& o);
    Object(const std::shared_ptr<Realm>& r, ObjectSchema const& s, Obj const& o, Obj const& parent = {},
           ColKey incoming_column = {});
    Object(const std::shared_ptr<Realm>& r, StringData object_type, ObjKey key);
    Object(const std::shared_ptr<Realm>& r, StringData object_type, size_t index);
    Object(const std::shared_ptr<Realm>& r, ObjLink link);

    Object(Object const&);
    Object(Object&&);
    Object& operator=(Object const&);
    Object& operator=(Object&&);

    ~Object();

    std::shared_ptr<Realm> const& realm() const
    {
        return m_realm;
    }
    std::shared_ptr<Realm> const& get_realm() const
    {
        return m_realm;
    }
    ObjectSchema const& get_object_schema() const
    {
        return *m_object_schema;
    }
    [[deprecated]] Obj obj() const
    {
        return m_obj;
    }
    const Obj& get_obj() const
    {
        return m_obj;
    }
    Obj& get_obj()
    {
        return m_obj;
    }
    bool is_valid() const
    {
        return m_obj.is_valid();
    }

    // Freeze a copy of this object in the context of the frozen Realm.
    // Equivalent to producing a thread-safe reference and resolving it in the frozen realm.
    Object freeze(std::shared_ptr<Realm> frozen_realm) const;

    // Returns whether or not this Object is frozen.
    bool is_frozen() const noexcept;

    /**
     * Adds a `CollectionChangeCallback` to this `Collection`. The `CollectionChangeCallback` is exectuted when
     * insertions, modifications or deletions happen on this `Collection`.
     *
     * @param callback The function to execute when a insertions, modification or deletion in this `Collection` was
     * detected.
     * @param key_path_array A filter that can be applied to make sure the `CollectionChangeCallback` is only executed
     * when the property in the filter is changed but not otherwise.
     *
     * @return A `NotificationToken` that is used to identify this callback. This token can be used to remove the
     * callback via `remove_callback`.
     */
    NotificationToken add_notification_callback(CollectionChangeCallback callback,
                                                std::optional<KeyPathArray> key_path_array = std::nullopt) &;

    template <typename ValueType>
    void set_column_value(StringData prop_name, ValueType&& value)
    {
        m_obj.set(prop_name, value);
    }

    template <typename ValueType>
    ValueType get_column_value(StringData prop_name) const
    {
        return m_obj.get<ValueType>(prop_name);
    }

    // The following functions require an accessor context which converts from
    // the binding's native data types to the core data types. See CppContext
    // for a reference implementation of such a context.
    //
    // The actual definitions of these templated functions is in object_accessor.hpp

    // property getter/setter
    template <typename ValueType, typename ContextType>
    void set_property_value(ContextType& ctx, StringData prop_name, ValueType value,
                            CreatePolicy policy = CreatePolicy::SetLink);
    template <typename ValueType, typename ContextType>
    void set_property_value(ContextType& ctx, Property const& prop, ValueType value,
                            CreatePolicy policy = CreatePolicy::SetLink);

    template <typename ValueType, typename ContextType>
    ValueType get_property_value(ContextType& ctx, StringData prop_name) const;

    template <typename ValueType, typename ContextType>
    ValueType get_property_value(ContextType& ctx, const Property& property) const;

    // create an Object from a native representation
    template <typename ValueType, typename ContextType>
    static Object create(ContextType& ctx, std::shared_ptr<Realm> const& realm, const ObjectSchema& object_schema,
                         ValueType value, CreatePolicy policy = CreatePolicy::ForceCreate,
                         ObjKey current_obj = ObjKey(), Obj* = nullptr);

    template <typename ValueType, typename ContextType>
    static Object create(ContextType& ctx, std::shared_ptr<Realm> const& realm, StringData object_type,
                         ValueType value, CreatePolicy policy = CreatePolicy::ForceCreate,
                         ObjKey current_obj = ObjKey(), Obj* = nullptr);

    template <typename ValueType, typename ContextType>
    static Object get_for_primary_key(ContextType& ctx, std::shared_ptr<Realm> const& realm,
                                      const ObjectSchema& object_schema, ValueType primary_value);

    template <typename ValueType, typename ContextType>
    static Object get_for_primary_key(ContextType& ctx, std::shared_ptr<Realm> const& realm, StringData object_type,
                                      ValueType primary_value);

    void verify_attached() const;

private:
    friend class Results;

    std::shared_ptr<Realm> m_realm;
    Obj m_obj;
    const ObjectSchema* m_object_schema;
    _impl::CollectionNotifier::Handle<_impl::ObjectNotifier> m_notifier;

    Object(std::shared_ptr<Realm> r, const ObjectSchema* s, Obj const& o, Obj const& parent = {},
           ColKey incoming_column = {});
    template <typename Key>
    Object(const std::shared_ptr<Realm>& r, const ObjectSchema* s, Key key);

    template <typename ValueType, typename ContextType>
    void set_property_value_impl(ContextType& ctx, const Property& property, ValueType value, CreatePolicy policy,
                                 bool is_default);
    template <typename ValueType, typename ContextType>
    ValueType get_property_value_impl(ContextType& ctx, const Property& property) const;

    template <typename ValueType, typename ContextType>
    static ObjKey get_for_primary_key_in_migration(ContextType& ctx, Table const& table, const Property& primary_prop,
                                                   ValueType&& primary_value);

    Property const& property_for_name(StringData prop_name) const;
    void validate_property_for_setter(Property const&) const;
};

struct InvalidatedObjectException : public LogicError {
    InvalidatedObjectException(const std::string& object_type);
    const std::string object_type;
};

struct InvalidPropertyException : public LogicError {
    InvalidPropertyException(const std::string& object_type, const std::string& property_name);
    const std::string object_type;
    const std::string property_name;
};

struct MissingPropertyValueException : public LogicError {
    MissingPropertyValueException(const std::string& object_type, const std::string& property_name);
    const std::string object_type;
    const std::string property_name;
};

struct MissingPrimaryKeyException : public LogicError {
    MissingPrimaryKeyException(const std::string& object_type);
    const std::string object_type;
};

struct ReadOnlyPropertyException : public LogicError {
    ReadOnlyPropertyException(const std::string& object_type, const std::string& property_name);
    const std::string object_type;
    const std::string property_name;
};

struct ModifyPrimaryKeyException : public LogicError {
    ModifyPrimaryKeyException(const std::string& object_type, const std::string& property_name);
    const std::string object_type;
    const std::string property_name;
};

} // namespace realm

#endif // REALM_OS_OBJECT_HPP
