/*************************************************************************
 *
 * Copyright 2019 Realm Inc.
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

#ifndef REALM_ARRAY_TYPED_LINK_HPP
#define REALM_ARRAY_TYPED_LINK_HPP

#include <realm/array.hpp>
#include <realm/data_type.hpp>
#include <realm/keys.hpp>
#include <realm/mixed.hpp>

namespace realm {

class ArrayTypedLink : public ArrayPayload, private Array {
public:
    using value_type = ObjLink;

    using Array::detach;
    using Array::get_ref;
    using Array::init_from_mem;
    using Array::set_parent;
    using Array::update_parent;
    using Array::verify;

    explicit ArrayTypedLink(Allocator& alloc)
        : Array(alloc)
    {
    }

    static ObjLink default_value(bool)
    {
        return ObjLink{};
    }

    void create()
    {
        MemRef mem = Array::create_empty_array(type_Normal, false, m_alloc);
        init_from_mem(mem);
    }
    void destroy()
    {
        Array::destroy_deep();
    }
    void init_from_ref(ref_type ref) noexcept override
    {
        Array::init_from_mem(MemRef(m_alloc.translate(ref), ref, m_alloc));
    }
    void set_parent(ArrayParent* parent, size_t ndx_in_parent) noexcept override
    {
        Array::set_parent(parent, ndx_in_parent);
    }
    void init_from_parent()
    {
        ref_type ref = get_ref_from_parent();
        init_from_ref(ref);
    }

    size_t size() const
    {
        return Array::size() >> 1;
    }

    bool is_null(size_t ndx)
    {
        ndx <<= 1;
        return Array::get(ndx) == 0;
    }

    void add(ObjLink value)
    {
        int64_t tk = (value.get_table_key().value + 1) & 0x7FFFFFFF;
        Array::add(tk);
        Array::add(value.get_obj_key().value + 1);
    }
    void set(size_t ndx, ObjLink value)
    {
        ndx <<= 1;
        int64_t tk = (value.get_table_key().value + 1) & 0x7FFFFFFF;
        Array::set(ndx, tk);
        Array::set(ndx + 1, value.get_obj_key().value + 1);
    }
    void set_null(size_t ndx)
    {
        ndx <<= 1;
        Array::set(ndx, 0);
        Array::set(ndx + 1, 0);
    }
    void insert(size_t ndx, ObjLink value)
    {
        ndx <<= 1;
        int64_t tk = (value.get_table_key().value + 1) & 0x7FFFFFFF;
        Array::insert(ndx, tk);
        Array::insert(ndx + 1, value.get_obj_key().value + 1);
    }
    ObjLink get(size_t ndx) const
    {
        ndx <<= 1;
        uint32_t tk = uint32_t(Array::get(ndx) - 1) & 0x7FFFFFFF;
        return {TableKey(tk), ObjKey(Array::get(ndx + 1) - 1)};
    }
    Mixed get_any(size_t ndx) const override
    {
        return Mixed(get(ndx));
    }
    bool is_null(size_t ndx) const
    {
        return Array::get(ndx << 1) == 0;
    }

    void erase(size_t ndx)
    {
        ndx <<= 1;
        Array::erase(ndx, ndx + 2);
    }
    void move(ArrayTypedLink& dst, size_t ndx)
    {
        Array::move(dst, ndx << 1);
    }
    void clear()
    {
        Array::clear();
    }

    size_t find_first(ObjLink value, size_t begin, size_t end) const noexcept
    {
        int64_t tk = (value.get_table_key().value + 1) & 0x7FFFFFFF;
        size_t element_ndx = begin * 2;
        size_t element_end = end * 2;
        for (;;) {
            element_ndx = Array::find_first(tk, element_ndx, element_end);
            if (element_ndx == realm::npos)
                return realm::npos;
            if (!(element_ndx & 1) && (Array::get(element_ndx + 1) - 1) == value.get_obj_key().value) {
                return element_ndx / 2;
            }
            ++element_ndx;
        }
        return realm::npos;
    }
};
} // namespace realm

#endif /* REALM_ARRAY_TYPED_LINK_HPP */
