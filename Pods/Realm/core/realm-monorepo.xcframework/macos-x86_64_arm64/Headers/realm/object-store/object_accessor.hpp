////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#ifndef REALM_OS_OBJECT_ACCESSOR_HPP
#define REALM_OS_OBJECT_ACCESSOR_HPP

#include <realm/object-store/object.hpp>

#include <realm/object-store/feature_checks.hpp>
#include <realm/object-store/list.hpp>
#include <realm/object-store/dictionary.hpp>
#include <realm/object-store/set.hpp>
#include <realm/object-store/dictionary.hpp>
#include <realm/object-store/object_schema.hpp>
#include <realm/object-store/object_store.hpp>
#include <realm/object-store/results.hpp>
#include <realm/object-store/schema.hpp>
#include <realm/object-store/shared_realm.hpp>

#include <realm/util/assert.hpp>
#include <realm/util/optional.hpp>
#include <realm/table_view.hpp>

#include <string>

namespace realm {
template <typename ValueType, typename ContextType>
void Object::set_property_value(ContextType& ctx, StringData prop_name, ValueType value, CreatePolicy policy)
{
    auto& property = property_for_name(prop_name);
    validate_property_for_setter(property);
    set_property_value_impl(ctx, property, value, policy, false);
}

template <typename ValueType, typename ContextType>
void Object::set_property_value(ContextType& ctx, const Property& property, ValueType value, CreatePolicy policy)
{
    set_property_value_impl(ctx, property, value, policy, false);
}

template <typename ValueType, typename ContextType>
ValueType Object::get_property_value(ContextType& ctx, const Property& property) const
{
    return get_property_value_impl<ValueType>(ctx, property);
}

template <typename ValueType, typename ContextType>
ValueType Object::get_property_value(ContextType& ctx, StringData prop_name) const
{
    return get_property_value_impl<ValueType>(ctx, property_for_name(prop_name));
}

namespace {
template <typename ValueType, typename ContextType>
struct ValueUpdater {
    ContextType& ctx;
    Property const& property;
    ValueType& value;
    Obj& obj;
    ColKey col;
    CreatePolicy policy;
    bool is_default;

    void operator()(Obj*)
    {
        ContextType child_ctx(ctx, obj, property);
        auto policy2 = policy;
        policy2.create = false;
        auto link = child_ctx.template unbox<Obj>(value, policy2);
        if (!policy.copy && link && link.get_table()->is_embedded())
            throw InvalidArgument("Cannot set a link to an existing managed embedded object");

        ObjKey curr_link;
        if (policy.diff)
            curr_link = obj.get<ObjKey>(col);
        if (!link || link.get_table()->is_embedded())
            link = child_ctx.template unbox<Obj>(value, policy, curr_link);
        if (!policy.diff || curr_link != link.get_key()) {
            if (!link || !link.get_table()->is_embedded())
                obj.set(col, link.get_key());
        }
    }

    template <typename T>
    void operator()(T*)
    {
        bool attr_changed = !policy.diff;
        auto new_val = ctx.template unbox<T>(value, policy);

        if (!attr_changed) {
            auto old_val = obj.get<T>(col);

            if constexpr (std::is_same<T, realm::Mixed>::value) {
                attr_changed = !new_val.is_same_type(old_val);
            }

            attr_changed = attr_changed || new_val != old_val;
        }

        if (attr_changed)
            obj.set(col, new_val, is_default);
    }
};
} // namespace

template <typename ValueType, typename ContextType>
void Object::set_property_value_impl(ContextType& ctx, const Property& property, ValueType value, CreatePolicy policy,
                                     bool is_default)
{
    ctx.will_change(*this, property);

    ColKey col{property.column_key};
    if (!is_collection(property.type) && is_nullable(property.type) && ctx.is_null(value)) {
        if (!policy.diff || !m_obj.is_null(col)) {
            if (property.type == PropertyType::Object) {
                if (!is_default)
                    m_obj.set_null(col);
            }
            else {
                m_obj.set_null(col, is_default);
            }
        }

        ctx.did_change();
        return;
    }

    if (is_array(property.type)) {
        if (property.type == PropertyType::LinkingObjects)
            throw ReadOnlyPropertyException(m_object_schema->name, property.name);

        ContextType child_ctx(ctx, m_obj, property);
        List list(m_realm, m_obj, col);
        list.assign(child_ctx, value, policy);
        ctx.did_change();
        return;
    }

    if (is_dictionary(property.type)) {
        ContextType child_ctx(ctx, m_obj, property);
        object_store::Dictionary dict(m_realm, m_obj, col);
        dict.assign(child_ctx, value, policy);
        ctx.did_change();
        return;
    }

    if (is_set(property.type)) {
        if (property.type == PropertyType::LinkingObjects)
            throw ReadOnlyPropertyException(m_object_schema->name, property.name);

        ContextType child_ctx(ctx, m_obj, property);
        object_store::Set set(m_realm, m_obj, col);
        set.assign(child_ctx, value, policy);
        ctx.did_change();
        return;
    }

    ValueUpdater<ValueType, ContextType> updater{ctx, property, value, m_obj, col, policy, is_default};
    switch_on_type(property.type, updater);
    ctx.did_change();
}

template <typename ValueType, typename ContextType>
ValueType Object::get_property_value_impl(ContextType& ctx, const Property& property) const
{
    verify_attached();

    ColKey column{property.column_key};
    if (is_nullable(property.type) && m_obj.is_null(column))
        return ctx.null_value();
    if (is_array(property.type) && property.type != PropertyType::LinkingObjects)
        return ctx.box(List(m_realm, m_obj, column));
    if (is_set(property.type) && property.type != PropertyType::LinkingObjects)
        return ctx.box(object_store::Set(m_realm, m_obj, column));
    if (is_dictionary(property.type))
        return ctx.box(object_store::Dictionary(m_realm, m_obj, column));

    switch (property.type & ~PropertyType::Flags) {
        case PropertyType::Bool:
            return ctx.box(m_obj.get<bool>(column));
        case PropertyType::Int:
            return is_nullable(property.type) ? ctx.box(*m_obj.get<util::Optional<int64_t>>(column))
                                              : ctx.box(m_obj.get<int64_t>(column));
        case PropertyType::Float:
            return ctx.box(m_obj.get<float>(column));
        case PropertyType::Double:
            return ctx.box(m_obj.get<double>(column));
        case PropertyType::String:
            return ctx.box(m_obj.get<StringData>(column));
        case PropertyType::Data:
            return ctx.box(m_obj.get<BinaryData>(column));
        case PropertyType::Date:
            return ctx.box(m_obj.get<Timestamp>(column));
        case PropertyType::ObjectId:
            return is_nullable(property.type) ? ctx.box(m_obj.get<util::Optional<ObjectId>>(column))
                                              : ctx.box(m_obj.get<ObjectId>(column));
        case PropertyType::Decimal:
            return ctx.box(m_obj.get<Decimal>(column));
        case PropertyType::UUID:
            return is_nullable(property.type) ? ctx.box(m_obj.get<util::Optional<UUID>>(column))
                                              : ctx.box(m_obj.get<UUID>(column));
        case PropertyType::Mixed:
            return ctx.box(m_obj.get<Mixed>(column));
        case PropertyType::Object: {
            auto linkObjectSchema = m_realm->schema().find(property.object_type);
            auto linked = const_cast<Obj&>(m_obj).get_linked_object(column);
            return ctx.box(Object(m_realm, *linkObjectSchema, linked, m_obj, column));
        }
        case PropertyType::LinkingObjects: {
            auto target_object_schema = m_realm->schema().find(property.object_type);
            auto link_property = target_object_schema->property_for_name(property.link_origin_property_name);
            auto table = m_realm->read_group().get_table(target_object_schema->table_key);
            auto tv = const_cast<Obj&>(m_obj).get_backlink_view(table, ColKey(link_property->column_key));
            return ctx.box(Results(m_realm, std::move(tv)));
        }
        default:
            REALM_UNREACHABLE();
    }
}

template <typename ValueType, typename ContextType>
Object Object::create(ContextType& ctx, std::shared_ptr<Realm> const& realm, StringData object_type, ValueType value,
                      CreatePolicy policy, ObjKey current_obj, Obj* out_row)
{
    auto object_schema = realm->schema().find(object_type);
    REALM_ASSERT(object_schema != realm->schema().end());
    return create(ctx, realm, *object_schema, value, policy, current_obj, out_row);
}

template <typename ValueType, typename ContextType>
Mixed as_mixed(ContextType& ctx, ValueType& value, PropertyType type)
{
    if (!value)
        return {};
    return switch_on_type(type, [&](auto* t) {
        return Mixed(ctx.template unbox<NonObjTypeT<decltype(*t)>>(*value));
    });
}

template <typename ValueType, typename ContextType>
Object Object::create(ContextType& ctx, std::shared_ptr<Realm> const& realm, ObjectSchema const& object_schema,
                      ValueType value, CreatePolicy policy, ObjKey current_obj, Obj* out_row)
{
    realm->verify_in_write();

    // When setting each property, we normally want to skip over the primary key
    // as that's set as part of object creation. However, during migrations the
    // property marked as the primary key in the schema may not currently be
    // considered a primary key by core, and so will need to be set.
    bool skip_primary = true;
    // If the input value is missing values for any of the properties we want to
    // set the property to the default value for new objects, but leave it
    // untouched for existing objects.
    bool created = false;

    Obj obj;
    auto table = realm->read_group().get_table(object_schema.table_key);

    // Asymmetric objects cannot be updated through Object::create.
    if (object_schema.table_type == ObjectSchema::ObjectType::TopLevelAsymmetric) {
        REALM_ASSERT(!policy.update);
        REALM_ASSERT(!current_obj);
        REALM_ASSERT(object_schema.primary_key_property());
    }

    // If there's a primary key, we need to first check if an object with the
    // same primary key already exists. If it does, we either update that object
    // or throw an exception if updating is disabled.
    if (auto primary_prop = object_schema.primary_key_property()) {
        auto primary_value =
            ctx.value_for_property(value, *primary_prop, primary_prop - &object_schema.persisted_properties[0]);
        if (!primary_value)
            primary_value = ctx.default_value_for_property(object_schema, *primary_prop);
        if (!primary_value && !is_nullable(primary_prop->type))
            throw MissingPropertyValueException(object_schema.name, primary_prop->name);

        // When changing the primary key of a table, we remove the existing pk (if any), call
        // the migration function, then add the new pk (if any). This means that we can't call
        // create_object_with_primary_key(), and creating duplicate primary keys is allowed as
        // long as they're unique by the end of the migration.
        if (table->get_primary_key_column() == ColKey{}) {
            REALM_ASSERT(realm->is_in_migration());
            if (policy.update) {
                if (auto key = get_for_primary_key_in_migration(ctx, *table, *primary_prop, *primary_value))
                    obj = table->get_object(key);
            }
            if (!obj)
                skip_primary = false;
        }
        else {
            obj = table->create_object_with_primary_key(as_mixed(ctx, primary_value, primary_prop->type), &created);
            if (!created && !policy.update) {
                if (!realm->is_in_migration()) {
                    auto pk_val = primary_value ? ctx.print(*primary_value) : "null";
                    throw ObjectAlreadyExists(object_schema.name, pk_val);
                }
                table->set_primary_key_column(ColKey{});
                skip_primary = false;
                obj = {};
            }
        }
    }

    // No primary key (possibly temporarily due to migrations). If we're
    // currently performing a recursive update on an existing object tree then
    // an object key was passed in that we need to look up, and otherwise we
    // need to create the new object.
    if (!obj) {
        if (current_obj)
            obj = table->get_object(current_obj);
        else if (object_schema.table_type == ObjectSchema::ObjectType::Embedded)
            obj = ctx.create_embedded_object();
        else
            obj = table->create_object();
        created = !policy.diff || !current_obj;
    }

    Object object(realm, object_schema, obj);
    // KVO in Cocoa requires that the obj ivar on the wrapper object be set
    // *before* we start setting the properties, so it passes in a pointer to
    // that.
    if (out_row && object_schema.table_type != ObjectSchema::ObjectType::TopLevelAsymmetric)
        *out_row = obj;
    for (size_t i = 0; i < object_schema.persisted_properties.size(); ++i) {
        auto& prop = object_schema.persisted_properties[i];
        // If table has primary key, it must have been set during object creation
        if (prop.is_primary && skip_primary)
            continue;

        auto v = ctx.value_for_property(value, prop, i);
        if (!created && !v)
            continue;

        bool is_default = false;
        if (!v) {
            v = ctx.default_value_for_property(object_schema, prop);
            is_default = true;
        }
        // We consider null or a missing value to be equivalent to an empty
        // array/set for historical reasons; the original implementation did this
        // accidentally and it's not worth changing.
        if ((!v || ctx.is_null(*v)) && !is_nullable(prop.type) && !is_collection(prop.type)) {
            if (prop.is_primary || !ctx.allow_missing(value))
                throw MissingPropertyValueException(object_schema.name, prop.name);
        }
        if (v)
            object.set_property_value_impl(ctx, prop, *v, policy, is_default);
    }
    if (object_schema.table_type == ObjectSchema::ObjectType::TopLevelAsymmetric) {
        return Object{};
    }
    return object;
}

template <typename ValueType, typename ContextType>
Object Object::get_for_primary_key(ContextType& ctx, std::shared_ptr<Realm> const& realm, StringData object_type,
                                   ValueType primary_value)
{
    auto object_schema = realm->schema().find(object_type);
    REALM_ASSERT(object_schema != realm->schema().end());
    return get_for_primary_key(ctx, realm, *object_schema, primary_value);
}

template <typename ValueType, typename ContextType>
Object Object::get_for_primary_key(ContextType& ctx, std::shared_ptr<Realm> const& realm,
                                   const ObjectSchema& object_schema, ValueType primary_value)
{
    auto primary_prop = object_schema.primary_key_property();
    if (!primary_prop) {
        throw MissingPrimaryKeyException(object_schema.name);
    }

    TableRef table;
    if (object_schema.table_key)
        table = realm->read_group().get_table(object_schema.table_key);
    if (!table)
        return Object(realm, object_schema, Obj());
    if (ctx.is_null(primary_value) && !is_nullable(primary_prop->type))
        throw NotNullable(util::format("Invalid null value for non-nullable primary key '%1.%2'.", object_schema.name,
                                       primary_prop->name));

    auto primary_key_value = switch_on_type(primary_prop->type, [&](auto* t) {
        return Mixed(ctx.template unbox<NonObjTypeT<decltype(*t)>>(primary_value));
    });
    auto key = table->find_primary_key(primary_key_value);
    return Object(realm, object_schema, key ? table->get_object(key) : Obj{});
}

template <typename ValueType, typename ContextType>
ObjKey Object::get_for_primary_key_in_migration(ContextType& ctx, Table const& table, const Property& primary_prop,
                                                ValueType&& primary_value)
{
    bool is_null = ctx.is_null(primary_value);
    if (is_null && !is_nullable(primary_prop.type))
        throw NotNullable(util::format("Invalid null value for non-nullable primary key '%1.%2'.",
                                       table.get_class_name(), primary_prop.name));
    if (primary_prop.type == PropertyType::String) {
        return table.find_first(primary_prop.column_key, ctx.template unbox<StringData>(primary_value));
    }
    if (primary_prop.type == PropertyType::ObjectId) {
        if (is_nullable(primary_prop.type)) {
            return table.find_first(primary_prop.column_key,
                                    ctx.template unbox<util::Optional<ObjectId>>(primary_value));
        }
        return table.find_first(primary_prop.column_key, ctx.template unbox<ObjectId>(primary_value));
    }
    else if (primary_prop.type == PropertyType::UUID) {
        if (is_nullable(primary_prop.type)) {
            return table.find_primary_key(ctx.template unbox<util::Optional<UUID>>(primary_value));
        }
        return table.find_primary_key(ctx.template unbox<UUID>(primary_value));
    }
    if (is_nullable(primary_prop.type))
        return table.find_first(primary_prop.column_key, ctx.template unbox<util::Optional<int64_t>>(primary_value));
    return table.find_first(primary_prop.column_key, ctx.template unbox<int64_t>(primary_value));
}

} // namespace realm

#endif // REALM_OS_OBJECT_ACCESSOR_HPP
