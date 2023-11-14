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

#ifndef REALM_ARRAY_FIXED_BYTES_HPP
#define REALM_ARRAY_FIXED_BYTES_HPP

#include <realm/array.hpp>
#include <realm/object_id.hpp>
#include <realm/uuid.hpp>
#include <realm/mixed.hpp>

namespace realm {

template <class ObjectType, int ElementSize>
class ArrayFixedBytes : public ArrayPayload, protected Array {
public:
    using value_type = ObjectType;
    using self_type = ArrayFixedBytes<ObjectType, ElementSize>;

    using Array::Array;
    using Array::destroy;
    using Array::get_ref;
    using Array::init_from_mem;
    using Array::init_from_parent;
    using Array::update_parent;
    using Array::verify;

    static ObjectType default_value(bool nullable)
    {
        REALM_ASSERT(!nullable);
        return ObjectType();
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

    size_t size() const
    {
        auto data_bytes = m_size - div_round_up<s_block_size>(m_size); // remove one byte per block.
        return data_bytes / s_width;
    }

    bool is_null(size_t ndx) const
    {
        return this->get_width() == 0 || get_pos(ndx).is_null(this);
    }

    ObjectType get(size_t ndx) const
    {
        REALM_ASSERT(is_valid_ndx(ndx));
        REALM_ASSERT(!is_null(ndx));
        return get_pos(ndx).get_value(this);
    }

    Mixed get_any(size_t ndx) const override
    {
        return Mixed(get(ndx));
    }

    void add(const ObjectType& value)
    {
        insert(size(), value);
    }

    void set(size_t ndx, const ObjectType& value);
    void insert(size_t ndx, const ObjectType& value);
    void erase(size_t ndx);
    void move(ArrayFixedBytes<ObjectType, ElementSize>& dst, size_t ndx);
    void clear()
    {
        truncate(0);
    }
    void truncate(size_t ndx)
    {
        Array::truncate(calc_required_bytes(ndx));
    }

    size_t find_first(const ObjectType& value, size_t begin = 0, size_t end = npos) const noexcept;

protected:
    static constexpr size_t s_width = ElementSize; // Size of each element

    // A block is a byte bitvector indicating null entries and 8 ObjectIds.
    static constexpr size_t s_block_size = s_width * 8 + 1; // 97

    template <size_t div>
    static size_t div_round_up(size_t num)
    {
        return (num + div - 1) / div;
    }

    // An accessor for the data at a given index. All casting and offset calculation should be kept here.
    struct Pos {
        size_t base_byte;
        size_t offset;

        void set_value(self_type* arr, const ObjectType& val) const
        {
            reinterpret_cast<ObjectType*>(arr->m_data + base_byte + 1 /*null bit byte*/)[offset] = val;
        }
        const ObjectType& get_value(const self_type* arr) const
        {
            return reinterpret_cast<const ObjectType*>(arr->m_data + base_byte + 1 /*null bit byte*/)[offset];
        }

        void set_null(self_type* arr, bool new_is_null) const
        {
            auto& bitvec = arr->m_data[base_byte];
            if (new_is_null) {
                bitvec |= 1 << offset;
            }
            else {
                bitvec &= ~(1 << offset);
            }
        }
        bool is_null(const self_type* arr) const
        {
            return arr->m_data[base_byte] & (1 << offset);
        }
    };

    static Pos get_pos(size_t ndx)
    {

        return Pos{(ndx / 8) * s_block_size, ndx % 8};
    }

    static size_t calc_required_bytes(size_t num_items)
    {
        return (num_items * s_width) +       // ObjectId data
               (div_round_up<8>(num_items)); // null bitvectors (1 byte per 8 oids, rounded up)
    }

    size_t calc_byte_len(size_t num_items, size_t /*unused width*/ = 0) const override
    {
        return num_items + Node::header_size;
    }

    bool is_valid_ndx(size_t ndx) const
    {
        return calc_byte_len(ndx) <= m_size;
    }
};

// The nullable ObjectType array uses the same layout and is compatible with the non-nullable one. It adds support for
// operations on null. Because the base class maintains null markers, we are able to defer to it for many operations.
template <class ObjectType, int ElementSize>
class ArrayFixedBytesNull : public ArrayFixedBytes<ObjectType, ElementSize> {
public:
    using Base = ArrayFixedBytes<ObjectType, ElementSize>;
    ArrayFixedBytesNull(Allocator& alloc) noexcept
        : ArrayFixedBytes<ObjectType, ElementSize>(alloc)
    {
    }
    static constexpr util::Optional<ObjectType> default_value(bool nullable)
    {
        if (nullable)
            return util::none;
        return ObjectType();
    }

    void set(size_t ndx, const util::Optional<ObjectType>& value)
    {
        if (value) {
            Base::set(ndx, *value);
        }
        else {
            set_null(ndx);
        }
    }
    void add(const util::Optional<ObjectType>& value)
    {
        insert(this->size(), value);
    }
    void insert(size_t ndx, const util::Optional<ObjectType>& value);
    void set_null(size_t ndx);
    util::Optional<ObjectType> get(size_t ndx) const noexcept
    {
        auto pos = this->get_pos(ndx);
        if (pos.is_null(this)) {
            return util::none;
        }
        return pos.get_value(this);
    }
    Mixed get_any(size_t ndx) const override
    {
        return Mixed(get(ndx));
    }
    size_t find_first(const util::Optional<ObjectType>& value, size_t begin = 0, size_t end = npos) const
    {
        if (value) {
            return Base::find_first(*value, begin, end);
        }
        else {
            return find_first_null(begin, end);
        }
    }
    size_t find_first_null(size_t begin = 0, size_t end = npos) const;
};

typedef ArrayFixedBytes<ObjectId, ObjectId::num_bytes> ArrayObjectId;
typedef ArrayFixedBytesNull<ObjectId, ObjectId::num_bytes> ArrayObjectIdNull;
typedef ArrayFixedBytes<UUID, UUID::num_bytes> ArrayUUID;
typedef ArrayFixedBytesNull<UUID, UUID::num_bytes> ArrayUUIDNull;

extern template class ArrayFixedBytes<ObjectId, ObjectId::num_bytes>;
extern template class ArrayFixedBytesNull<ObjectId, ObjectId::num_bytes>;
extern template class ArrayFixedBytes<UUID, UUID::num_bytes>;
extern template class ArrayFixedBytesNull<UUID, UUID::num_bytes>;

} // namespace realm

#endif /* REALM_ARRAY_FIXED_BYTES_HPP */
