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

#ifndef REALM_OBJECT_CHANGESET_HPP
#define REALM_OBJECT_CHANGESET_HPP

#include <realm/object-store/collection_notifications.hpp>

#include <realm/keys.hpp>
#include <realm/util/optional.hpp>

#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace realm {

/**
 * An `ObjectChangeSet` holds information about all insertions, modifications and deletions
 * in a single table.
 */
class ObjectChangeSet {
public:
    using ObjectSet = std::unordered_set<ObjKey>;
    using ColumnSet = std::unordered_set<ColKey>;
    using ObjectMapToColumnSet = std::unordered_map<ObjKey, ColumnSet>;

    ObjectChangeSet() = default;
    ObjectChangeSet(ObjectChangeSet const&) = default;
    ObjectChangeSet(ObjectChangeSet&&) = default;
    ObjectChangeSet& operator=(ObjectChangeSet const&) = default;
    ObjectChangeSet& operator=(ObjectChangeSet&&) = default;

    void insertions_add(ObjKey obj);
    void modifications_add(ObjKey obj, ColKey col);
    void deletions_add(ObjKey obj);

    bool insertions_remove(ObjKey obj);
    bool modifications_remove(ObjKey obj);
    bool deletions_remove(ObjKey obj);

    bool insertions_contains(ObjKey obj) const;
    /**
     * Checks if a given object was modified. If the optional filter is provided only those colums
     * will be looked at.
     *
     * @param obj The `ObjKey` that should be checked for changes.
     * @param filtered_col_keys Optional collection of `ColKey` the check will be restricted to.
     *
     * @return True if `obj` is contained in `m_modifications` and `filtered_col_keys` contains
     *         at least one changed column. False otherwise.
     */
    bool modifications_contains(ObjKey obj, const std::vector<ColKey>& filtered_col_keys) const;
    bool deletions_contains(ObjKey obj) const;
    // if the specified object has not been modified, returns nullptr
    // if the object has been modified, returns a pointer to the ObjectSet
    const ColumnSet* get_columns_modified(ObjKey obj) const;

    bool insertions_empty() const noexcept
    {
        return m_insertions.empty();
    }
    bool modifications_empty() const noexcept
    {
        return m_modifications.empty();
    }
    bool deletions_empty() const noexcept
    {
        return m_deletions.empty();
    }

    size_t insertions_size() const noexcept
    {
        return m_insertions.size();
    }
    size_t modifications_size() const noexcept
    {
        return m_modifications.size();
    }
    size_t deletions_size() const noexcept
    {
        return m_deletions.size();
    }

    bool empty() const noexcept
    {
        return m_deletions.empty() && m_insertions.empty() && m_modifications.empty();
    }

    void merge(ObjectChangeSet&& other);
    void verify();

    const ObjectSet& get_deletions() const noexcept
    {
        return m_deletions;
    }
    const ObjectMapToColumnSet& get_modifications() const noexcept
    {
        return m_modifications;
    }
    const ObjectSet& get_insertions() const noexcept
    {
        return m_insertions;
    }

private:
    ObjectSet m_deletions;
    ObjectSet m_insertions;
    // `m_modifications` contains one entry per changed object.
    // It also includes the information about all columns changed in that object.
    ObjectMapToColumnSet m_modifications;
};

} // end namespace realm

#endif // REALM_OBJECT_CHANGESET_HPP
