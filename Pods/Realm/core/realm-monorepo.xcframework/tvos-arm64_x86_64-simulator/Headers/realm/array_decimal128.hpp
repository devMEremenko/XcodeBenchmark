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

#ifndef REALM_ARRAY_DECIMAL128_HPP
#define REALM_ARRAY_DECIMAL128_HPP

#include <realm/array.hpp>
#include <realm/decimal128.hpp>

namespace realm {

class ArrayDecimal128 : public ArrayPayload, private Array {
public:
    using value_type = Decimal128;

    using Array::Array;
    using Array::destroy;
    using Array::get_ref;
    using Array::init_from_mem;
    using Array::init_from_parent;
    using Array::size;
    using Array::truncate;
    using Array::update_parent;
    using Array::verify;

    static Decimal128 default_value(bool nullable)
    {
        return nullable ? Decimal128(realm::null()) : Decimal128(0);
    }

    void create()
    {
        auto mem = Array::create(type_Normal, false, wtype_Multiply, 0, 0, m_alloc); // Throws
        Array::init_from_mem(mem);
    }

    void init_from_ref(ref_type ref) noexcept override
    {
        Array::init_from_ref(ref);
    }

    void set_parent(ArrayParent* parent, size_t ndx_in_parent) noexcept override
    {
        Array::set_parent(parent, ndx_in_parent);
    }

    bool is_null(size_t ndx) const
    {
        return this->get_width() == 0 || get(ndx).is_null();
    }

    Decimal128 get(size_t ndx) const
    {
        REALM_ASSERT(ndx < m_size);
        auto values = reinterpret_cast<Decimal128*>(this->m_data);
        return values[ndx];
    }

    Mixed get_any(size_t ndx) const override;

    void add(Decimal128 value)
    {
        insert(size(), value);
    }

    void set(size_t ndx, Decimal128 value);
    void set_null(size_t ndx)
    {
        set(ndx, Decimal128(realm::null()));
    }

    void insert(size_t ndx, Decimal128 value);
    void erase(size_t ndx);
    void move(ArrayDecimal128& dst, size_t ndx);
    void clear()
    {
        truncate(0);
    }

    size_t find_first(Decimal128 value, size_t begin = 0, size_t end = npos) const noexcept;

protected:
    size_t calc_byte_len(size_t num_items, size_t) const override
    {
        return num_items * sizeof(Decimal128) + header_size;
    }
};

} // namespace realm

#endif /* REALM_ARRAY_DECIMAL128_HPP */
