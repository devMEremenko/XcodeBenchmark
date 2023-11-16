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

#ifndef REALM_UTIL_BUFFER_STREAM_HPP
#define REALM_UTIL_BUFFER_STREAM_HPP

#include <cstddef>
#include <sstream>

#include <realm/util/span.hpp>

namespace realm {
namespace util {


template <class C, class T = std::char_traits<C>, class A = std::allocator<C>>
class BasicResettableExpandableOutputStreambuf : public std::basic_stringbuf<C, T, A> {
public:
    using char_type = typename std::basic_stringbuf<C, T, A>::char_type;

    /// Reset current writing position (std::basic_streambuf::pptr()) to the
    /// beginning of the output buffer without reallocating buffer memory.
    void reset() noexcept;

    //@{
    /// Get a pointer to the beginning of the output buffer
    /// (std::basic_streambuf::pbase()). Note that this will change as the
    /// buffer is reallocated.
    char_type* data() noexcept;
    const char_type* data() const noexcept;
    //@}

    /// Get the number of bytes written to the output buffer since the creation
    /// of the stream buffer, or since the last invocation of reset()
    /// (std::basic_streambuf::pptr() - std::basic_streambuf::pbase()).
    std::size_t size() const noexcept;

    util::Span<C> as_span() noexcept;
    util::Span<const C> as_span() const noexcept;
};


template <class C, class T = std::char_traits<C>, class A = std::allocator<C>>
class BasicResettableExpandableBufferOutputStream : public std::basic_ostream<C, T> {
public:
    using char_type = typename std::basic_ostream<C, T>::char_type;

    BasicResettableExpandableBufferOutputStream();

    /// Calls BasicResettableExpandableOutputStreambuf::reset().
    void reset() noexcept;

    //@{
    /// Calls BasicResettableExpandableOutputStreambuf::data().
    char_type* data() noexcept;
    const char_type* data() const noexcept;
    //@}

    /// Calls BasicResettableExpandableOutputStreambuf::size().
    std::size_t size() const noexcept;

    util::Span<C> as_span() noexcept;
    util::Span<const C> as_span() const noexcept;

private:
    BasicResettableExpandableOutputStreambuf<C, T, A> m_streambuf;
};


using ResettableExpandableBufferOutputStream = BasicResettableExpandableBufferOutputStream<char>;


// Implementation

template <class C, class T, class A>
inline void BasicResettableExpandableOutputStreambuf<C, T, A>::reset() noexcept
{
    char_type* pbeg = this->pbase();
    char_type* pend = this->epptr();
    this->setp(pbeg, pend);
}

template <class C, class T, class A>
inline typename BasicResettableExpandableOutputStreambuf<C, T, A>::char_type*
BasicResettableExpandableOutputStreambuf<C, T, A>::data() noexcept
{
    return this->pbase();
}

template <class C, class T, class A>
inline const typename BasicResettableExpandableOutputStreambuf<C, T, A>::char_type*
BasicResettableExpandableOutputStreambuf<C, T, A>::data() const noexcept
{
    return this->pbase();
}

template <class C, class T, class A>
inline std::size_t BasicResettableExpandableOutputStreambuf<C, T, A>::size() const noexcept
{
    std::size_t size = std::size_t(this->pptr() - this->pbase());
    return size;
}

template <class C, class T, class A>
inline util::Span<C> BasicResettableExpandableOutputStreambuf<C, T, A>::as_span() noexcept
{
    return util::Span<C>(data(), size());
}

template <class C, class T, class A>
inline util::Span<const C> BasicResettableExpandableOutputStreambuf<C, T, A>::as_span() const noexcept
{
    return util::Span<const C>(data(), size());
}

template <class C, class T, class A>
inline BasicResettableExpandableBufferOutputStream<C, T, A>::BasicResettableExpandableBufferOutputStream()
    : std::basic_ostream<C, T>(&m_streambuf) // Throws
{
}

template <class C, class T, class A>
inline void BasicResettableExpandableBufferOutputStream<C, T, A>::reset() noexcept
{
    m_streambuf.reset();
}

template <class C, class T, class A>
inline typename BasicResettableExpandableBufferOutputStream<C, T, A>::char_type*
BasicResettableExpandableBufferOutputStream<C, T, A>::data() noexcept
{
    return m_streambuf.data();
}

template <class C, class T, class A>
inline const typename BasicResettableExpandableBufferOutputStream<C, T, A>::char_type*
BasicResettableExpandableBufferOutputStream<C, T, A>::data() const noexcept
{
    return m_streambuf.data();
}

template <class C, class T, class A>
inline std::size_t BasicResettableExpandableBufferOutputStream<C, T, A>::size() const noexcept
{
    return m_streambuf.size();
}

template <class C, class T, class A>
inline util::Span<C> BasicResettableExpandableBufferOutputStream<C, T, A>::as_span() noexcept
{
    return util::Span<C>(m_streambuf.data(), m_streambuf.size());
}

template <class C, class T, class A>
inline util::Span<const C> BasicResettableExpandableBufferOutputStream<C, T, A>::as_span() const noexcept
{
    return util::Span<const C>(m_streambuf.data(), m_streambuf.size());
}

} // namespace util
} // namespace realm

#endif // REALM_UTIL_BUFFER_STREAM_HPP
