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

#ifndef REALM_OBJ_LIST_HPP
#define REALM_OBJ_LIST_HPP

#include <realm/obj.hpp>

namespace realm {

class DescriptorOrdering;
class Table;
class TableView;

class ObjList {
public:
    virtual ~ObjList();

    virtual size_t size() const = 0;
    virtual TableRef get_target_table() const = 0;
    virtual ObjKey get_key(size_t ndx) const = 0;
    virtual Obj get_object(size_t row_ndx) const = 0;
    virtual void sync_if_needed() const = 0;
    virtual void get_dependencies(TableVersions&) const = 0;
    virtual bool is_in_sync() const = 0;
    virtual LinkCollectionPtr clone_obj_list() const = 0;
    virtual bool matches(const ObjList&) const
    {
        return true;
    }
    virtual Obj get_owning_obj() const
    {
        return {};
    }
    virtual ColKey get_owning_col_key() const
    {
        return {};
    }

    // Get the versions of all tables which this list depends on
    TableVersions get_dependency_versions() const
    {
        TableVersions ret;
        get_dependencies(ret);
        return ret;
    }
    Obj operator[](size_t ndx) const
    {
        return get_object(ndx);
    }

    template <class F>
    void for_each(F func) const
    {
        auto sz = size();
        for (size_t i = 0; i < sz; i++) {
            auto o = get_object(i);
            if (o && func(o) == IteratorControl::Stop)
                return;
        }
    }

    template <class T>
    size_t find_first(ColKey column_key, T value) const
    {
        auto sz = size();
        for (size_t i = 0; i < sz; i++) {
            auto o = get_object(i);
            if (o) {
                T v = o.get<T>(column_key);
                if (v == value)
                    return i;
            }
        }
        return realm::npos;
    }

    template <class T>
    TableView find_all(ColKey column_key, T value) const;
};
}

#endif /* SRC_REALM_OBJ_LIST_HPP_ */
