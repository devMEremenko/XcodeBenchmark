////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

#ifndef DEEP_CHANGE_CHECKER_HPP
#define DEEP_CHANGE_CHECKER_HPP

#include <realm/object-store/object_changeset.hpp>
#include <realm/object-store/impl/collection_change_builder.hpp>

#include <array>

namespace realm {
class CollectionBase;
class Group;
class Mixed;
class Realm;
class Table;
class TableRef;
class Transaction;

using KeyPath = std::vector<std::pair<TableKey, ColKey>>;
using KeyPathArray = std::vector<KeyPath>;
using ref_type = size_t;

namespace _impl {
class RealmCoordinator;

struct CollectionChangeInfo {
    TableKey table_key;
    ObjKey obj_key;
    ColKey col_key;
    CollectionChangeBuilder* changes;
};

struct TransactionChangeInfo {
    std::vector<CollectionChangeInfo> collections;
    std::unordered_map<TableKey, ObjectChangeSet> tables;
    bool schema_changed = false;
};

/**
 * The `DeepChangeChecker` serves two purposes:
 * - Given an initial `Table` and an optional `KeyPathArray` it find all tables related to that initial table.
 *   A `RelatedTable` is a `Table` that can be reached via a link from another `Table`.
 * - The `DeepChangeChecker` also offers a way to check if a specific `ObjKey` was changed.
 */
class DeepChangeChecker {
public:
    /**
     * `RelatedTable` is used to describe the connections of a `Table` to other tables.
     * Tables count as related if they can be reached via a forward link.
     * A table counts as being related to itself.
     */
    struct RelatedTable {
        // The key of the table for which this struct holds all outgoing links.
        TableKey table_key;
        // All outgoing links to the table specified by `table_key`.
        std::vector<ColKey> links;
    };

    typedef std::vector<RelatedTable> RelatedTables;
    DeepChangeChecker(TransactionChangeInfo const& info, Table const& root_table, RelatedTables const& related_tables,
                      const KeyPathArray& key_path_array, bool all_callbacks_filtered);

    /**
     * Check if the object identified by `object_key` was changed.
     *
     * @param object_key The `ObjKey::value` for the object that is supposed to be checked.
     *
     * @return True if the object was changed, false otherwise.
     */
    bool operator()(ObjKey object_key);
    bool operator()(int64_t i)
    {
        return operator()(ObjKey(i));
    }

    /**
     * Search for related tables within the specified `table`.
     * Related tables are all tables that can be reached via links from the `table`.
     * A table is always related to itself.
     *
     * Example schema:
     * {
     *   {"root_table",
     *       {
     *           {"link", PropertyType::Object | PropertyType::Nullable, "linked_table"},
     *       }
     *   },
     *   {"linked_table",
     *       {
     *           {"value", PropertyType::Int}
     *       }
     *   },
     * }
     *
     * Asking for related tables for `root_table` based on this schema will result in a `std::vector<RelatedTable>`
     * with two entries, one for `root_table` and one for `linked_table`. The function would be called once for
     * each table involved until there are no further links.
     *
     * Likewise a search for related tables starting with `linked_table` would only return this table.
     *
     * Filter:
     * Using a `key_path_array` that only consists of the table key for `root_table` would result
     * in `out` just having this one entry.
     *
     * @param out Return value containing all tables that can be reached from the given `table` including
     *            some additional information about those tables    .
     * @param table The table that the related tables will be searched for.
     * @param key_path_array A collection of all `KeyPath`s passed to the `NotificationCallback`s for this
     *                        `CollectionNotifier`.
     */
    static void find_related_tables(std::vector<RelatedTable>& out, Table const& table,
                                    const KeyPathArray& key_path_array);

protected:
    friend class ObjectKeyPathChangeChecker;

    TransactionChangeInfo const& m_info;

    // The `Table` this `DeepChangeChecker` is based on.
    Table const& m_root_table;

    // The `m_key_path_array` contains all columns filtered for. We need this when checking for
    // changes in `operator()` to make sure only columns actually filtered for send notifications.
    const KeyPathArray& m_key_path_array;

    // The `ObjectChangeSet` for `root_table` if it is contained in `m_info`.
    ObjectChangeSet const* const m_root_object_changes;

    // Contains all `ColKey`s that we filter for in the root table.
    std::vector<ColKey> m_filtered_columns_in_root_table;
    std::vector<ColKey> m_filtered_columns;

private:
    RelatedTables const& m_related_tables;

    std::unordered_map<TableKey, std::unordered_set<ObjKey>> m_not_modified;

    struct Path {
        ObjKey obj_key;
        ColKey col_key;
        bool depth_exceeded;
    };
    std::array<Path, 4> m_current_path;

    /**
     * Checks if a specific object, identified by it's `ObjKey` in a given `Table` was changed.
     *
     * @param table The `Table` that contains the `ObjKey` that will be checked.
     * @param object_key The `ObjKey` identifying the object to be checked for changes.
     * @param filtered_columns A `std::vector` of all `ColKey`s filtered in any of the `NotificationCallbacks`.
     * @param depth Determines how deep the search will be continued if the change could not be found
     *              on the first level.
     *
     * @return True if the object was changed, false otherwise.
     */
    bool check_row(Table const& table, ObjKey object_key, const std::vector<ColKey>& filtered_columns,
                   size_t depth = 0);

    /**
     * Check the `table` within `m_related_tables` for changes in it's outgoing links.
     *
     * @param table The table to check for changed links.
     * @param object_key The key for the object to look for.
     * @param depth The maximum depth that should be considered for this search.
     *
     * @return True if the specified `table` does have linked objects that have been changed.
     *         False if the `table` is not contained in `m_related_tables` or the `table` does not have any
     *         outgoing links at all or the `table` does not have linked objects with changes.
     */
    bool check_outgoing_links(Table const& table, ObjKey object_key, const std::vector<ColKey>& filtered_columns,
                              size_t depth = 0);

    bool do_check_for_collection_modifications(const Obj& obj, ColKey col,
                                               const std::vector<ColKey>& filtered_columns, size_t depth);
    template <typename T>
    bool check_collection(ref_type ref, const Obj& obj, ColKey col, const std::vector<ColKey>& filtered_columns,
                          size_t depth);
    bool do_check_mixed_for_link(Group&, TableRef& cached_linked_table, Mixed value,
                                 const std::vector<ColKey>& filtered_columns, size_t depth);
};

/**
 * The `CollectionKeyPathChangeChecker` is a specialised version of `DeepChangeChecker` that offers a check by
 * traversing and only traversing the given `KeyPathArray`. With this it supports any depth (as opposed to the maxium
 * depth of 4 on the `DeepChangeChecker`) and backlinks.
 */
class CollectionKeyPathChangeChecker : DeepChangeChecker {
public:
    CollectionKeyPathChangeChecker(TransactionChangeInfo const& info, Table const& root_table,
                                   std::vector<RelatedTable> const& related_tables,
                                   const KeyPathArray& key_path_array, bool all_callbacks_filtered);

    /**
     * Check if the `Object` identified by `object_key` was changed and it is included in the `KeyPathArray` provided
     * when construction this `CollectionKeyPathChangeChecker`.
     *
     * @param object_key The `ObjKey::value` for the `Object` that is supposed to be checked.
     *
     * @return True if the `Object` was changed, false otherwise.
     */
    bool operator()(ObjKey object_key);

private:
    friend class ObjectKeyPathChangeChecker;

    /**
     * Traverses down a given `KeyPath` and checks the objects along the way for changes.
     *
     * @param changed_columns The list of `ColKeyType`s that was changed in the root object.
     *                        A key will be added to this list if it turns out to be changed.
     * @param key_path The `KeyPath` used to traverse the given object with.
     * @param depth The current depth in the key_path.
     * @param table The `TableKey` for the current depth.
     * @param object_key_value The `ObjKeyType` that is to be checked for changes.
     */
    void find_changed_columns(std::vector<ColKey>& changed_columns, const KeyPath& key_path, size_t depth,
                              const Table& table, const ObjKey& object_key_value);
};

/**
 * The `ObjectKeyPathChangeChecker` is a specialised version of `CollectionKeyPathChangeChecker` that offers a deep
 * change check for `Object` which is different from the checks done for `Collection`. Like
 * `CollectionKeyPathChangeChecker` it is only traversing the given KeyPathArray and has no depth limit.
 *
 * This difference is mainly seen in the fact that for `Object` we notify about the specific columns that have been
 * changed which we do not for `Collection`.
 */
class ObjectKeyPathChangeChecker : CollectionKeyPathChangeChecker {
public:
    ObjectKeyPathChangeChecker(TransactionChangeInfo const& info, Table const& root_table,
                               std::vector<DeepChangeChecker::RelatedTable> const& related_tables,
                               const KeyPathArray& key_path_array, bool all_callbacks_filtered);

    /**
     * Check if the `Object` identified by `object_key` was changed and it is included in the `KeyPathArray` provided
     * when construction this `ObjectKeyPathChangeChecker`.
     *
     * @param object_key The `ObjKey::value` for the `Object` that is supposed to be checked.
     *
     * @return A list of columns changed in the root `Object`.
     */
    std::vector<ColKey> operator()(ObjKey object_key);
};


} // namespace _impl
} // namespace realm

#endif /* DEEP_CHANGE_CHECKER_HPP */
