/*************************************************************************
 *
 * Copyright 2022 Realm Inc.
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

#ifndef REALM_UTIL_SPAN_HPP
#define REALM_UTIL_SPAN_HPP

#include <realm/util/assert.hpp>

#include <array>
#include <cstddef>
#include <iterator>
#include <limits>
#include <type_traits>

namespace realm::util {

// This is an implementation of C++20's std::span. This should be an exact
// drop-in replacement that can be deleted once we switch to building as C++20.
// See https://en.cppreference.com/w/cpp/container/span for documentation on this type.

inline constexpr size_t dynamic_extent = std::numeric_limits<size_t>::max();

template <typename T, size_t extent = dynamic_extent>
class Span;

} // namespace realm::util

namespace realm::_impl {

// SFINAE helpers: anything which has std::data() and std::size() and
// std::data() produces the correct type can be converted to Span, but
// std::array, C arrays, and Span have separate conversions which need to be
// used instead of the generic one.
template <typename T>
struct IsSpan : public std::false_type {
};
template <typename T, size_t extent>
struct IsSpan<util::Span<T, extent>> : public std::true_type {
};

template <typename T>
struct IsStdArray : public std::false_type {
};
template <typename T, size_t size>
struct IsStdArray<std::array<T, size>> : public std::true_type {
};

// msvc v19.28 hits an internal compiler error if these are inline in the
// template using them rather than type aliases. This appears to be fixed in
// newer versions
template <typename T>
using StdDataT = decltype(std::data(std::declval<T>()));
template <typename T>
using StdSizeT = decltype(std::size(std::declval<T>()));

template <typename T, typename U, typename A = StdDataT<T>, typename B = StdSizeT<T>>
constexpr bool is_span_compatible()
{
    return !IsSpan<std::remove_cv_t<T>>::value && !IsStdArray<std::remove_cv_t<T>>::value && !std::is_array_v<T> &&
           std::is_convertible_v<std::remove_pointer_t<decltype(std::data(std::declval<T&>()))>(*)[], U(*)[]>;
}

template <typename C, typename T>
using EnableIfSpanCompatible = std::enable_if_t<is_span_compatible<C, T>(), int>;
} // namespace realm::_impl

namespace realm::util {
template <typename T, size_t Extent>
class Span {
public:
    using element_type = T;
    using value_type = std::remove_cv_t<T>;
    using size_type = size_t;
    using difference_type = ptrdiff_t;
    using pointer = T*;
    using const_pointer = const T*;
    using reference = T&;
    using const_reference = const T&;
    using iterator = pointer;
    using reverse_iterator = std::reverse_iterator<iterator>;

    static constexpr size_type extent = Extent;

    template <size_t size = extent, std::enable_if_t<size == 0, int> = 0>
    constexpr Span() noexcept
    {
    }
    constexpr Span(const Span&) noexcept = default;
    constexpr Span& operator=(const Span&) noexcept = default;

    constexpr explicit Span(pointer ptr, size_type count)
        : m_data{ptr}
    {
        REALM_ASSERT(extent == count);
    }
    constexpr explicit Span(pointer begin, pointer end)
        : m_data{begin}
    {
        REALM_ASSERT(extent == std::distance(begin, end));
    }
#if 0 // VS 16.9 incorrectly rejects this. 16.10+ support it
    constexpr Span(element_type (&arr)[extent]) noexcept
        : m_data{arr}
    {
    }
#endif
    template <class U, std::enable_if_t<std::is_convertible_v<U (*)[], element_type (*)[]>, int> = 0>
    constexpr Span(std::array<U, extent>& arr) noexcept
        : m_data{arr.data()}
    {
    }
    template <class U, std::enable_if_t<std::is_convertible_v<const U (*)[], element_type (*)[]>, int> = 0>
    constexpr Span(const std::array<U, extent>& arr) noexcept
        : m_data{arr.data()}
    {
    }
    template <class Container, _impl::EnableIfSpanCompatible<Container, T> = 0>
    constexpr explicit Span(Container& c)
        : m_data{std::data(c)}
    {
        REALM_ASSERT(extent == std::size(c));
    }

    template <class Container, _impl::EnableIfSpanCompatible<const Container, T> = 0>
    constexpr explicit Span(const Container& c)
        : m_data{std::data(c)}
    {
        REALM_ASSERT(extent == std::size(c));
    }

    template <class U, std::enable_if_t<std::is_convertible_v<U (*)[], element_type (*)[]>, int> = 0>
    constexpr Span(const Span<U, extent>& other)
        : m_data{other.data()}
    {
    }

#if 0 // VS 16.9 incorrectly rejects this. 16.10+ support it
    template <class U, std::enable_if_t<std::is_convertible_v<U (*)[], element_type (*)[]>, int> = 0>
    constexpr explicit Span(const Span<U, dynamic_extent>& other) noexcept
        : m_data{other.data()}
    {
        REALM_ASSERT(extent == other.size());
    }
#endif

    template <size_t count>
    constexpr Span<element_type, count> first() const noexcept
    {
        static_assert(count <= extent);
        return Span<element_type, count>{data(), count};
    }

    template <size_t count>
    constexpr Span<element_type, count> last() const noexcept
    {
        static_assert(count <= extent);
        return Span<element_type, count>{data() + size() - count, count};
    }

    constexpr Span<element_type, dynamic_extent> first(size_type count) const noexcept
    {
        REALM_ASSERT(count <= size());
        return {data(), count};
    }

    constexpr Span<element_type, dynamic_extent> last(size_type count) const noexcept
    {
        REALM_ASSERT(count <= size());
        return {data() + size() - count, count};
    }

    template <size_t offset, size_t count = dynamic_extent>
    constexpr auto sub_span() const noexcept
    {
        static_assert(offset <= extent);
        static_assert(count == dynamic_extent || count <= extent - offset);

        using Ret = Span<element_type, count != dynamic_extent ? count : extent - offset>;
        return Ret{data() + offset, count == dynamic_extent ? size() - offset : count};
    }

    constexpr Span<element_type, dynamic_extent> sub_span(size_type offset,
                                                          size_type count = dynamic_extent) const noexcept
    {
        REALM_ASSERT(offset <= size());
        REALM_ASSERT(count <= size() || count == dynamic_extent);
        if (count == dynamic_extent)
            return {data() + offset, size() - offset};
        REALM_ASSERT(count <= size() - offset);
        return {data() + offset, count};
    }

    constexpr size_type size() const noexcept
    {
        return extent;
    }
    constexpr size_type size_bytes() const noexcept
    {
        return extent * sizeof(element_type);
    }
    constexpr bool empty() const noexcept
    {
        return extent == 0;
    }
    constexpr reference operator[](size_type idx) const noexcept
    {
        REALM_ASSERT(idx < size());
        return m_data[idx];
    }
    constexpr reference front() const noexcept
    {
        REALM_ASSERT(!empty());
        return m_data[0];
    }
    constexpr reference back() const noexcept
    {
        REALM_ASSERT(!empty());
        return m_data[size() - 1];
    }
    constexpr pointer data() const noexcept
    {
        return m_data;
    }
    constexpr iterator begin() const noexcept
    {
        return data();
    }
    constexpr iterator end() const noexcept
    {
        return data() + size();
    }
    constexpr reverse_iterator rbegin() const noexcept
    {
        return reverse_iterator(end());
    }
    constexpr reverse_iterator rend() const noexcept
    {
        return reverse_iterator(begin());
    }
    Span<const std::byte, extent * sizeof(element_type)> as_bytes() const noexcept
    {
        return Span<const std::byte, extent * sizeof(element_type)>{reinterpret_cast<const std::byte*>(data()),
                                                                    size_bytes()};
    }
    Span<std::byte, extent * sizeof(element_type)> as_writable_bytes() const noexcept
    {
        return Span<std::byte, extent * sizeof(element_type)>{reinterpret_cast<std::byte*>(data()), size_bytes()};
    }

private:
    pointer m_data = nullptr;
};

template <typename T>
class Span<T, dynamic_extent> {
public:
    using element_type = T;
    using value_type = std::remove_cv_t<T>;
    using size_type = size_t;
    using difference_type = ptrdiff_t;
    using pointer = T*;
    using const_pointer = const T*;
    using reference = T&;
    using const_reference = const T&;
    using iterator = pointer;
    using reverse_iterator = std::reverse_iterator<iterator>;

    static constexpr size_type extent = dynamic_extent;

    constexpr Span() noexcept = default;
    constexpr Span(const Span&) noexcept = default;
    constexpr Span& operator=(const Span&) noexcept = default;

    constexpr Span(pointer ptr, size_type count)
        : m_data{ptr}
        , m_size{count}
    {
    }
    constexpr Span(pointer f, pointer l)
        : m_data{f}
        , m_size{static_cast<size_t>(std::distance(f, l))}
    {
    }

    template <size_t size>
    constexpr Span(element_type (&arr)[size]) noexcept
        : m_data{arr}
        , m_size{size}
    {
    }

    template <class U, size_t size, std::enable_if_t<std::is_convertible_v<U (*)[], element_type (*)[]>, int> = 0>
    constexpr Span(std::array<U, size>& arr) noexcept
        : m_data{arr.data()}
        , m_size{size}
    {
    }

    template <class U, size_t size,
              std::enable_if_t<std::is_convertible_v<const U (*)[], element_type (*)[]>, int> = 0>
    constexpr Span(const std::array<U, size>& arr) noexcept
        : m_data{arr.data()}
        , m_size{size}
    {
    }

    template <class Container, _impl::EnableIfSpanCompatible<Container, T> = 0>
    constexpr Span(Container& c)
        : m_data{std::data(c)}
        , m_size{(size_type)std::size(c)}
    {
    }

    template <class Container, _impl::EnableIfSpanCompatible<const Container, T> = 0>
    constexpr Span(const Container& c)
        : m_data{std::data(c)}
        , m_size{(size_type)std::size(c)}
    {
    }

    template <class U, size_t E, std::enable_if_t<std::is_convertible_v<U (*)[], element_type (*)[]>, int> = 0>
    constexpr Span(const Span<U, E>& other) noexcept
        : m_data{other.data()}
        , m_size{other.size()}
    {
    }

    template <size_t count>
    constexpr Span<element_type, count> first() const noexcept
    {
        REALM_ASSERT(count <= m_size);
        return Span<element_type, count>{m_data, count};
    }

    template <size_t count>
    constexpr Span<element_type, count> last() const noexcept
    {
        REALM_ASSERT(count <= m_size);
        return Span<element_type, count>{m_data + m_size - count, count};
    }

    constexpr Span<element_type, dynamic_extent> first(size_type count) const noexcept
    {
        REALM_ASSERT(count <= m_size);
        return {m_data, count};
    }

    constexpr Span<element_type, dynamic_extent> last(size_type count) const noexcept
    {
        REALM_ASSERT(count <= m_size);
        return {m_data + m_size - count, count};
    }

    template <size_t offset, size_t count = dynamic_extent>
    constexpr Span<element_type, count> sub_span() const noexcept
    {
        REALM_ASSERT(offset <= m_size);
        REALM_ASSERT(count == dynamic_extent || count <= m_size - offset);
        return Span<element_type, count>{m_data + offset, count == dynamic_extent ? m_size - offset : count};
    }

    constexpr Span<element_type, dynamic_extent> sub_span(size_type offset,
                                                          size_type count = dynamic_extent) const noexcept
    {
        REALM_ASSERT(offset <= m_size);
        REALM_ASSERT(count <= m_size || count == dynamic_extent);
        if (count == dynamic_extent)
            return {m_data + offset, m_size - offset};
        REALM_ASSERT(count <= m_size - offset);
        return {m_data + offset, count};
    }

    constexpr size_type size() const noexcept
    {
        return m_size;
    }
    constexpr size_type size_bytes() const noexcept
    {
        return m_size * sizeof(element_type);
    }
    constexpr bool empty() const noexcept
    {
        return m_size == 0;
    }
    constexpr reference operator[](size_type idx) const noexcept
    {
        REALM_ASSERT(idx < m_size);
        return m_data[idx];
    }
    constexpr reference front() const noexcept
    {
        REALM_ASSERT(m_size);
        return m_data[0];
    }
    constexpr reference back() const noexcept
    {
        REALM_ASSERT(m_size);
        return m_data[m_size - 1];
    }
    constexpr pointer data() const noexcept
    {
        return m_data;
    }
    constexpr iterator begin() const noexcept
    {
        return m_data;
    }
    constexpr iterator end() const noexcept
    {
        return m_data + m_size;
    }
    constexpr reverse_iterator rbegin() const noexcept
    {
        return reverse_iterator(end());
    }
    constexpr reverse_iterator rend() const noexcept
    {
        return reverse_iterator(begin());
    }
    Span<const std::byte, dynamic_extent> as_bytes() const noexcept
    {
        return {reinterpret_cast<const std::byte*>(m_data), size_bytes()};
    }
    Span<std::byte, dynamic_extent> as_writable_bytes() const noexcept
    {
        return {reinterpret_cast<std::byte*>(m_data), size_bytes()};
    }

private:
    pointer m_data = nullptr;
    size_type m_size = 0;
};

template <typename T, size_t extent>
auto as_bytes(Span<T, extent> s) noexcept -> decltype(s.as_bytes())
{
    return s.as_bytes();
}

template <typename T, size_t extent>
auto as_writable_bytes(Span<T, extent> s) noexcept
    -> std::enable_if_t<!std::is_const_v<T>, decltype(s.as_writable_bytes())>
{
    return s.as_writable_bytes();
}

template <typename T, typename... Args>
constexpr auto unsafe_span_cast(Args&&... args)
{
    auto temp = Span(std::forward<Args>(args)...);
    return Span<T, decltype(temp)::extent>(reinterpret_cast<T*>(temp.data()), temp.size());
}

//  Deduction guides
template <typename T, size_t extent>
Span(T (&)[extent]) -> Span<T, extent>;

template <typename T, size_t extent>
Span(std::array<T, extent>&) -> Span<T, extent>;

template <typename T, size_t extent>
Span(const std::array<T, extent>&) -> Span<const T, extent>;

template <class Container>
Span(Container&) -> Span<typename Container::value_type>;

template <class Container>
Span(const Container&) -> Span<const typename Container::value_type>;

} // namespace realm::util

#endif // REALM_UTIL_SPAN_HPP
