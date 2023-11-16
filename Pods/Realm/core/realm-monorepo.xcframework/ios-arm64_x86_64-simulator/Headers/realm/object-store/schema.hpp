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

#ifndef REALM_SCHEMA_HPP
#define REALM_SCHEMA_HPP

#include <ostream>
#include <string>
#include <vector>

#include <realm/object-store/object_schema.hpp>
#include <realm/util/features.h>

namespace realm {
class SchemaChange;
class StringData;
struct TableKey;
struct Property;

// How to handle update_schema() being called on a file which has
// already been initialized with a different schema
enum class SchemaMode : uint8_t {
    // If the schema version has increased, automatically apply all
    // changes, then call the migration function.
    //
    // If the schema version has not changed, verify that the only
    // changes are to add new tables and add or remove indexes, and then
    // apply them if so. Does not call the migration function.
    //
    // This mode does not automatically remove tables which are not
    // present in the schema that must be manually done in the migration
    // function, to support sharing a Realm file between processes using
    // different class subsets.
    //
    // This mode allows using schemata with different subsets of tables
    // on different threads, but the tables which are shared must be
    // identical.
    Automatic,

    // Open the file in immutable mode. Schema version must match the
    // version in the file, and all tables present in the file must
    // exactly match the specified schema, except for indexes. Tables
    // are allowed to be missing from the file.
    Immutable,

    // Open the Realm in read-only mode, transactions are not allowed to
    // be performed on the Realm instance. The schema of the existing Realm
    // file won't be changed through this Realm instance. Extra tables and
    // extra properties are allowed in the existing Realm schema. The
    // difference of indexes is allowed as well. Other schema differences
    // than those will cause an exception. This is different from Immutable
    // mode, sync Realm can be opened with ReadOnly mode. Changes
    // can be made to the Realm file through another writable Realm instance.
    // Thus, notifications are also allowed in this mode.
    ReadOnly,

    // If the schema version matches and the only schema changes are new
    // tables and indexes being added or removed, apply the changes to
    // the existing file.
    // Otherwise delete the file and recreate it from scratch.
    // The migration function is not used.
    //
    // This mode allows using schemata with different subsets of tables
    // on different threads, but the tables which are shared must be
    // identical.
    SoftResetFile,

    // Delete the file and recreate it from scratch.
    // The migration function is not used.
    HardResetFile,

    // The only changes allowed are to add new tables, add columns to
    // existing tables, and to add or remove indexes from existing
    // columns. Extra tables not present in the schema are ignored.
    // Indexes are only added to or removed from existing columns if the
    // schema version is greater than the existing one (and unlike other
    // modes, the schema version is allowed to be less than the existing
    // one).
    // The migration function is not used.
    // This should be used when including discovered user classes.
    // Previously called Additive.
    //
    // This mode allows updating the schema with additive changes even
    // if the Realm is already open on another thread.
    AdditiveDiscovered,

    // The same additive properties as AdditiveDiscovered, except
    // in this mode, all classes in the schema have been explicitly
    // included by the user. This means that stricter schema checks are
    // run such as throwing an error when an embedded object type which
    // is not linked from any top level object types is included.
    AdditiveExplicit,

    // Verify that the schema version has increased, call the migration
    // function, and then verify that the schema now matches.
    // The migration function is mandatory for this mode.
    //
    // This mode requires that all threads and processes which open a
    // file use identical schemata.
    Manual
};

// Options for how to handle the schema when the file has classes and/or
// properties not in the schema.
//
// Most schema modes allow the requested schema to be a subset of the actual
// schema of the Realm file. By default, any properties or object types not in
// the requested schema are simply ignored entirely and the Realm's in-memory
// schema will always exactly match the requested one.
struct SchemaSubsetMode {
    // Add additional tables present in the Realm file to the schema. This is
    // applicable to all schema modes except for Manual and ResetFile.
    bool include_types : 1;

    // Add additional columns in the tables present in the Realm file to the
    // object schema for those types. The additional properties are always
    // added to the end of persisted_properties. This is only applicable to
    // Additive and ReadOnly schema modes.
    bool include_properties : 1;

    // The reported schema will always exactly match the requested one.
    static const SchemaSubsetMode Strict;
    // Additional object classes present in the Realm file are added to the
    // requested schema, but all object types present in the requested schema
    // will always exactly match even if there are additional columns in the
    // tables.
    static const SchemaSubsetMode AllClasses;
    // Additional properties present in the Realm file are added to the
    // requested schema, but tables not present in the schema are ignored.
    static const SchemaSubsetMode AllProperties;
    // Always report the complete schema.
    static const SchemaSubsetMode Complete;

    friend bool operator==(const SchemaSubsetMode& x, const SchemaSubsetMode& y)
    {
        return x.include_types == y.include_types && x.include_properties == y.include_properties;
    }
};

inline constexpr SchemaSubsetMode SchemaSubsetMode::Strict = {false, false};
inline constexpr SchemaSubsetMode SchemaSubsetMode::AllClasses = {true, false};
inline constexpr SchemaSubsetMode SchemaSubsetMode::AllProperties = {false, true};
inline constexpr SchemaSubsetMode SchemaSubsetMode::Complete = {true, true};


class Schema : private std::vector<ObjectSchema> {
private:
    using base = std::vector<ObjectSchema>;

public:
    Schema() noexcept;
    ~Schema();
    // Create a schema from a vector of ObjectSchema
    Schema(base types) noexcept;
    Schema(std::initializer_list<ObjectSchema> types);

    Schema(Schema const&);
    Schema(Schema&&) noexcept;
    Schema& operator=(Schema const&);
    Schema& operator=(Schema&&) noexcept;

    // find an ObjectSchema by name
    iterator find(StringData name) noexcept;
    const_iterator find(StringData name) const noexcept;

    // find an ObjectSchema with the same name as the passed in one
    iterator find(ObjectSchema const& object) noexcept;
    const_iterator find(ObjectSchema const& object) const noexcept;

    // find an ObjectSchema by table key
    iterator find(TableKey table_key) noexcept;
    const_iterator find(TableKey table_key) const noexcept;

    // Verify that this schema is internally consistent (i.e. all properties are
    // valid, links link to types that actually exist, etc.)
    void validate(SchemaValidationMode validation_mode = SchemaValidationMode::Basic) const;

    // Get the changes which must be applied to this schema to produce the passed-in schema
    std::vector<SchemaChange> compare(Schema const&, SchemaMode = SchemaMode::Automatic,
                                      bool include_removals = false) const;

    void copy_keys_from(Schema const&, SchemaSubsetMode subset_mode);

    friend bool operator==(Schema const&, Schema const&) noexcept;
    friend bool operator!=(Schema const& a, Schema const& b) noexcept
    {
        return !(a == b);
    }
    friend std::ostream& operator<<(std::ostream&, const Schema&);

    using base::begin;
    using base::const_iterator;
    using base::empty;
    using base::end;
    using base::iterator;
    using base::size;

private:
    template <typename T, typename U, typename Func>
    static void zip_matching(T&& a, U&& b, Func&& func);
    // sort all the classes by name in order to speed up find(StringData name)
    void sort_schema();
};

namespace schema_change {
struct AddTable {
    const ObjectSchema* object;
};

struct RemoveTable {
    const ObjectSchema* object;
};

struct ChangeTableType {
    const ObjectSchema* object;
    const ObjectSchema::ObjectType* old_table_type;
    const ObjectSchema::ObjectType* new_table_type;
};

struct AddInitialProperties {
    const ObjectSchema* object;
};

struct AddProperty {
    const ObjectSchema* object;
    const Property* property;
};

struct RemoveProperty {
    const ObjectSchema* object;
    const Property* property;
};

struct ChangePropertyType {
    const ObjectSchema* object;
    const Property* old_property;
    const Property* new_property;
};

struct MakePropertyNullable {
    const ObjectSchema* object;
    const Property* property;
};

struct MakePropertyRequired {
    const ObjectSchema* object;
    const Property* property;
};

struct AddIndex {
    const ObjectSchema* object;
    const Property* property;
    IndexType type;
};

struct RemoveIndex {
    const ObjectSchema* object;
    const Property* property;
};

struct ChangePrimaryKey {
    const ObjectSchema* object;
    const Property* property;
};
} // namespace schema_change

#define REALM_FOR_EACH_SCHEMA_CHANGE_TYPE(macro)                                                                     \
    macro(AddTable) macro(RemoveTable) macro(ChangeTableType) macro(AddInitialProperties) macro(AddProperty)         \
        macro(RemoveProperty) macro(ChangePropertyType) macro(MakePropertyNullable) macro(MakePropertyRequired)      \
            macro(AddIndex) macro(RemoveIndex) macro(ChangePrimaryKey)

class SchemaChange {
public:
#define REALM_SCHEMA_CHANGE_CONSTRUCTOR(name)                                                                        \
    SchemaChange(schema_change::name value)                                                                          \
        : m_kind(Kind::name)                                                                                         \
    {                                                                                                                \
        name = value;                                                                                                \
    }
    REALM_FOR_EACH_SCHEMA_CHANGE_TYPE(REALM_SCHEMA_CHANGE_CONSTRUCTOR)
#undef REALM_SCHEMA_CHANGE_CONSTRUCTOR

    template <typename Visitor>
    auto visit(Visitor&& visitor) const
    {
        switch (m_kind) {
#define REALM_SWITCH_CASE(name)                                                                                      \
    case Kind::name:                                                                                                 \
        return visitor(name);
            REALM_FOR_EACH_SCHEMA_CHANGE_TYPE(REALM_SWITCH_CASE)
#undef REALM_SWITCH_CASE
        }
        REALM_COMPILER_HINT_UNREACHABLE();
    }

    friend bool operator==(SchemaChange const& lft, SchemaChange const& rgt) noexcept;

private:
    enum class Kind {
#define REALM_SCHEMA_CHANGE_TYPE(name) name,
        REALM_FOR_EACH_SCHEMA_CHANGE_TYPE(REALM_SCHEMA_CHANGE_TYPE)
#undef REALM_SCHEMA_CHANGE_TYPE

    } m_kind;
    union {
#define REALM_DEFINE_FIELD(name) schema_change::name name;
        REALM_FOR_EACH_SCHEMA_CHANGE_TYPE(REALM_DEFINE_FIELD)
#undef REALM_DEFINE_FIELD
    };
};

#undef REALM_FOR_EACH_SCHEMA_CHANGE_TYPE
} // namespace realm

#endif /* defined(REALM_SCHEMA_HPP) */
