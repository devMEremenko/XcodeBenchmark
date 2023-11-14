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

#ifndef REALM_UTIL_SAFE_INT_OPS_HPP
#define REALM_UTIL_SAFE_INT_OPS_HPP

#ifdef _WIN32
#undef max // collides with numeric_limits::max called later in this header file
#undef min // collides with numeric_limits::min called later in this header file
#include <safeint.h>
#endif

#include <limits>

#include <realm/util/features.h>
#include <realm/util/assert.hpp>

namespace realm {
namespace util {

//@{

/// Compare two integers of the same, or of different type, and
/// produce the expected result according to the natural
/// interpretation of the operation.
///
/// Note that in general a standard comparison between a signed and an
/// unsigned integer type is unsafe, and it often generates a compiler
/// warning. An example is a 'less than' comparison between a negative
/// value of type 'int' and a small positive value of type
/// 'unsigned'. In this case the negative value will be converted to
/// 'unsigned' producing a large positive value which, in turn, will
/// lead to the counter intuitive result of 'false'.
///
/// Please note that these operation incur absolutely no overhead when
/// the two types have the same signedness.
///
/// These functions check at compile time that both types have valid
/// specializations of std::numeric_limits<> and that both are indeed
/// integers.

template <class A, class B>
inline bool int_equal_to(A, B) noexcept;
template <class A, class B>
inline bool int_not_equal_to(A, B) noexcept;
template <class A, class B>
inline bool int_less_than(A, B) noexcept;
template <class A, class B>
inline bool int_less_than_or_equal(A, B) noexcept;
template <class A, class B>
inline bool int_greater_than(A, B) noexcept;
template <class A, class B>
inline bool int_greater_than_or_equal(A, B) noexcept;

//@}


//@{

/// Check for overflow in integer variable `lval` while adding integer
/// `rval` to it, or while subtracting integer `rval` from it. Returns
/// true on positive or negative overflow.
///
/// Both `lval` and `rval` must be of an integer type for which a
/// specialization of std::numeric_limits<> exists. The two types need
/// not be the same, in particular, one can be signed and the other
/// one can be unsigned.
///
/// These functions are especially well suited for cases where \a rval
/// is a compile-time constant.
///
/// These functions check at compile time that both types have valid
/// specializations of std::numeric_limits<> and that both are indeed
/// integers.

template <class L, class R>
inline bool int_add_with_overflow_detect(L& lval, R rval) noexcept;

template <class L, class R>
inline bool int_subtract_with_overflow_detect(L& lval, R rval) noexcept;

//@}


/// Check for positive overflow when multiplying two positive integers
/// of the same, or of different type. Returns true on overflow.
///
/// \param lval Must not be negative. Both signed and unsigned types
/// can be used.
///
/// \param rval Must be stricly greater than zero. Both signed and
/// unsigned types can be used.
///
/// This function is especially well suited for cases where \a rval is
/// a compile-time constant.
///
/// This function checks at compile time that both types have valid
/// specializations of std::numeric_limits<> and that both are indeed
/// integers.
template <class L, class R>
inline bool int_multiply_with_overflow_detect(L& lval, R rval) noexcept;


/// Checks for positive overflow when performing a bitwise shift to
/// the left on a non-negative value of arbitrary integer
/// type. Returns true on overflow.
///
/// \param lval Must not be negative. Both signed and unsigned types
/// can be used.
///
/// \param i Must be non-negative and such that <tt>L(1)>>i</tt> has a
/// value that is defined by the C++03 standard. In particular, the
/// value of i must not exceed the number of bits of storage type T as
/// shifting by this amount is not defined by the standard.
template <class T>
inline bool int_shift_left_with_overflow_detect(T& lval, int i) noexcept;


//@{

/// Check for overflow when casting an integer value from one type to
/// another. While the first function is a mere check, the second one
/// also carries out the cast, but only when there is no
/// overflow. Both return true on overflow.
///
/// These functions check at compile time that both types have valid
/// specializations of std::numeric_limits<> and that both are indeed
/// integers.
///
/// These functions make absolutely no assumptions about the platform
/// except that it complies with at least C++03.

template <class To, class From>
bool int_cast_has_overflow(From from) noexcept;

template <class To, class From>
bool int_cast_with_overflow_detect(From from, To& to) noexcept;

//@}

} // namespace util

namespace _impl {

template <class L, class R, typename = void>
struct SafeIntBinopsImpl;

// (both signed or both unsigned)
template <class L, class R>
struct SafeIntBinopsImpl<L, R, std::enable_if_t<std::is_signed_v<L> == std::is_signed_v<R>>> {
    using common = std::common_type_t<L, R>;
    static bool equal(L l, R r) noexcept
    {
        return common(l) == common(r);
    }
    static bool less(L l, R r) noexcept
    {
        return common(l) < common(r);
    }
};

// (unsigned, signed)
template <class L, class R>
struct SafeIntBinopsImpl<L, R, std::enable_if_t<!std::is_signed_v<L> && std::is_signed_v<R>>> {
    using lim_l = std::numeric_limits<L>;
    using lim_r = std::numeric_limits<R>;
    static bool equal(L l, R r) noexcept
    {
        return (lim_l::digits > lim_r::digits) ? r >= 0 && l == L(r) : R(l) == r;
    }
    static bool less(L l, R r) noexcept
    {
        return (lim_l::digits > lim_r::digits) ? r >= 0 && l < L(r) : R(l) < r;
    }
};

// (signed, unsigned) (all size combinations)
template <class L, class R>
struct SafeIntBinopsImpl<L, R, std::enable_if_t<std::is_signed_v<L> && !std::is_signed_v<R>>> {
    static bool equal(L l, R r) noexcept
    {
        // r == l
        return SafeIntBinopsImpl<R, L>::equal(r, l);
    }
    static bool less(L l, R r) noexcept
    {
        // !(r == l || r < l)
        return !(SafeIntBinopsImpl<R, L>::equal(r, l) || SafeIntBinopsImpl<R, L>::less(r, l));
    }
};

template <class L, class R>
struct SafeIntBinops : SafeIntBinopsImpl<L, R> {
    typedef std::numeric_limits<L> lim_l;
    typedef std::numeric_limits<R> lim_r;
    static_assert(lim_l::is_specialized && lim_r::is_specialized,
                  "std::numeric_limits<> must be specialized for both types");
    static_assert(lim_l::is_integer && lim_r::is_integer, "Both types must be integers");
};

} // namespace _impl

namespace util {

template <class A, class B>
inline bool int_equal_to(A a, B b) noexcept
{
    return realm::_impl::SafeIntBinops<A, B>::equal(a, b);
}

template <class A, class B>
inline bool int_not_equal_to(A a, B b) noexcept
{
    return !realm::_impl::SafeIntBinops<A, B>::equal(a, b);
}

template <class A, class B>
inline bool int_less_than(A a, B b) noexcept
{
    return realm::_impl::SafeIntBinops<A, B>::less(a, b);
}

template <class A, class B>
inline bool int_less_than_or_equal(A a, B b) noexcept
{
    return !realm::_impl::SafeIntBinops<B, A>::less(b, a); // Not greater than
}

template <class A, class B>
inline bool int_greater_than(A a, B b) noexcept
{
    return realm::_impl::SafeIntBinops<B, A>::less(b, a);
}

template <class A, class B>
inline bool int_greater_than_or_equal(A a, B b) noexcept
{
    return !realm::_impl::SafeIntBinops<A, B>::less(a, b); // Not less than
}

template <class L, class R>
inline bool int_add_with_overflow_detect(L& lval, R rval) noexcept
{
    // Note: MSVC returns true on success, while gcc/clang return true on overflow.
    // Note: Both may write to destination on overflow, but our tests check that this doesn't happen.
    auto old = lval;
#ifdef _MSC_VER
    auto overflow = !msl::utilities::SafeAdd(lval, rval, lval);
#else
    auto overflow = __builtin_add_overflow(lval, rval, &lval);
#endif
    if (REALM_UNLIKELY(overflow))
        lval = old;
    return overflow;
}

template <class L, class R>
inline bool int_subtract_with_overflow_detect(L& lval, R rval) noexcept
{
    auto old = lval;
#ifdef _MSC_VER
    auto overflow = !msl::utilities::SafeSubtract(lval, rval, lval);
#else
    auto overflow = __builtin_sub_overflow(lval, rval, &lval);
#endif
    if (REALM_UNLIKELY(overflow))
        lval = old;
    return overflow;
}

template <class L, class R>
inline bool int_multiply_with_overflow_detect(L& lval, R rval) noexcept
{
    auto old = lval;
#ifdef _MSC_VER
    auto overflow = !msl::utilities::SafeMultiply(lval, rval, lval);
#else
    auto overflow = __builtin_mul_overflow(lval, rval, &lval);
#endif
    if (REALM_UNLIKELY(overflow))
        lval = old;
    return overflow;
}

template <class T>
inline bool int_shift_left_with_overflow_detect(T& lval, int i) noexcept
{
    typedef std::numeric_limits<T> lim;
    static_assert(lim::is_specialized, "std::numeric_limits<> must be specialized for T");
    static_assert(lim::is_integer, "T must be an integer type");
    REALM_ASSERT(int_greater_than_or_equal(lval, 0));
    if ((lim::max() >> i) < lval)
        return true;
    lval <<= i;
    return false;
}

template <class To, class From>
inline bool int_cast_has_overflow(From from) noexcept
{
    typedef std::numeric_limits<To> lim_to;
    return int_less_than(from, lim_to::min()) || int_less_than(lim_to::max(), from);
}

template <class To, class From>
inline bool int_cast_with_overflow_detect(From from, To& to) noexcept
{
    if (REALM_LIKELY(!int_cast_has_overflow<To>(from))) {
        to = To(from);
        return false;
    }
    return true;
}

} // namespace util
} // namespace realm

#endif // REALM_UTIL_SAFE_INT_OPS_HPP
