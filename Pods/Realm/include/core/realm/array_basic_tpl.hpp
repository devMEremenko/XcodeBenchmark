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

#ifndef REALM_ARRAY_BASIC_TPL_HPP
#define REALM_ARRAY_BASIC_TPL_HPP

#include <algorithm>
#include <limits>

#include <realm/array_basic.hpp>
#include <realm/node.hpp>

namespace realm {

template <class T>
inline BasicArray<T>::BasicArray(Allocator& allocator) noexcept
    : Node(allocator)
{
}

template <class T>
inline MemRef BasicArray<T>::create_array(size_t init_size, Allocator& allocator)
{
    size_t byte_size_0 = calc_aligned_byte_size(init_size); // Throws
    // Adding zero to Array::initial_capacity to avoid taking the
    // address of that member
    size_t byte_size = std::max(byte_size_0, Node::initial_capacity + 0); // Throws

    MemRef mem = allocator.alloc(byte_size); // Throws

    bool is_inner_bptree_node = false;
    bool has_refs = false;
    bool context_flag = false;
    int width = sizeof(T);
    init_header(mem.get_addr(), is_inner_bptree_node, has_refs, context_flag, wtype_Multiply, width, init_size,
                byte_size);

    return mem;
}


template <class T>
inline void BasicArray<T>::create(NodeHeader::Type type, bool context_flag)
{
    REALM_ASSERT(type == NodeHeader::type_Normal);
    REALM_ASSERT(!context_flag);
    size_t length = 0;
    MemRef mem = create_array(length, get_alloc()); // Throws
    init_from_mem(mem);
}


template <class T>
inline void BasicArray<T>::add(T value)
{
    insert(m_size, value);
}


template <class T>
inline T BasicArray<T>::get(size_t ndx) const noexcept
{
    return *(reinterpret_cast<const T*>(m_data) + ndx);
}


template <class T>
inline T BasicArray<T>::get(const char* header, size_t ndx) noexcept
{
    const char* data = get_data_from_header(header);
    // This casting assumes that T can be aliged on an 8-bype
    // boundary (since data is aligned on an 8-byte boundary.)
    return *(reinterpret_cast<const T*>(data) + ndx);
}


template <class T>
inline void BasicArray<T>::set(size_t ndx, T value)
{
    REALM_ASSERT_3(ndx, <, m_size);
    if (get(ndx) == value)
        return;

    // Check if we need to copy before modifying
    copy_on_write(); // Throws

    // Set the value
    T* data = reinterpret_cast<T*>(m_data) + ndx;
    *data = value;
}

template <class T>
void BasicArray<T>::insert(size_t ndx, T value)
{
    REALM_ASSERT_3(ndx, <=, m_size);

    // Check if we need to copy before modifying
    copy_on_write(); // Throws

    // Make room for the new value
    const auto old_size = m_size;
    alloc(m_size + 1, sizeof(T)); // Throws

    // Move values below insertion
    if (ndx != old_size) {
        char* src_begin = m_data + ndx * sizeof(T);
        char* src_end = m_data + old_size * sizeof(T);
        char* dst_end = src_end + sizeof(T);
        std::copy_backward(src_begin, src_end, dst_end);
    }

    // Set the value
    T* data = reinterpret_cast<T*>(m_data) + ndx;
    *data = value;
}

template <class T>
void BasicArray<T>::erase(size_t ndx)
{
    REALM_ASSERT_3(ndx, <, m_size);

    // Check if we need to copy before modifying
    copy_on_write(); // Throws

    // move data under deletion up
    if (ndx < m_size - 1) {
        char* dst_begin = m_data + ndx * sizeof(T);
        const char* src_begin = dst_begin + sizeof(T);
        const char* src_end = m_data + m_size * sizeof(T);
        realm::safe_copy_n(src_begin, src_end - src_begin, dst_begin);
    }

    // Update size (also in header)
    --m_size;
    set_header_size(m_size);
}

template <class T>
void BasicArray<T>::truncate(size_t to_size)
{
    REALM_ASSERT(is_attached());
    REALM_ASSERT_3(to_size, <=, m_size);

    copy_on_write(); // Throws

    // Update size in accessor and in header. This leaves the capacity
    // unchanged.
    m_size = to_size;
    set_header_size(to_size);
}

template <class T>
inline void BasicArray<T>::clear()
{
    truncate(0); // Throws
}

template <class T>
size_t BasicArray<T>::calc_byte_len(size_t for_size, size_t) const
{
    // FIXME: Consider calling `calc_aligned_byte_size(size)`
    // instead. Note however, that calc_byte_len() is supposed to return
    // the unaligned byte size. It is probably the case that no harm
    // is done by returning the aligned version, and most callers of
    // calc_byte_len() will actually benefit if calc_byte_len() was
    // changed to always return the aligned byte size.
    return header_size + for_size * sizeof(T);
}

template <class T>
size_t BasicArray<T>::calc_item_count(size_t bytes, size_t) const noexcept
{
    size_t bytes_without_header = bytes - header_size;
    return bytes_without_header / sizeof(T);
}

template <class T>
inline size_t BasicArray<T>::find_first(T value, size_t begin, size_t end) const
{
    if (end == npos)
        end = m_size;
    REALM_ASSERT(begin <= m_size && end <= m_size && begin <= end);
    const T* data = reinterpret_cast<const T*>(m_data);
    const T* i = std::find(data + begin, data + end, value);
    return i == data + end ? not_found : size_t(i - data);
}

template <class T>
size_t BasicArrayNull<T>::find_first_null(size_t begin, size_t end) const
{
    size_t sz = Node::size();
    if (end == npos)
        end = sz;
    REALM_ASSERT(begin <= sz && end <= sz && begin <= end);
    while (begin != end) {
        if (this->is_null(begin))
            return begin;
        begin++;
    }
    return not_found;
}

template <class T>
inline size_t BasicArray<T>::calc_aligned_byte_size(size_t size)
{
    size_t max = std::numeric_limits<size_t>::max();
    size_t max_2 = max & ~size_t(7); // Allow for upwards 8-byte alignment
    if (size > (max_2 - header_size) / sizeof(T))
        throw std::overflow_error("Byte size overflow");
    size_t byte_size = header_size + size * sizeof(T);
    REALM_ASSERT_3(byte_size, >, 0);
    size_t aligned_byte_size = ((byte_size - 1) | 7) + 1; // 8-byte alignment
    return aligned_byte_size;
}

} // namespace realm

#endif // REALM_ARRAY_BASIC_TPL_HPP
