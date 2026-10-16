////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#ifndef REALM_OS_UTIL_TAGGED_STRING_HPP
#define REALM_OS_UTIL_TAGGED_STRING_HPP

#include <type_traits>
#include <string>

namespace realm {
namespace util {
// A type factory which defines a type which is implicitly convertable to and
// from `std::string`, but not to other TaggedString types
//
// Usage:
// using AuthCode = util::TaggedString<class AuthCode>;
// using IdToken = util::TaggedString<class IdToken>;
// void foo(AuthCode auth_code, IdToken id_token);
//
// foo(AuthCode{""}, IdToken{""}); // compiles
// foo(IdToken{""}, AuthCode{""}); // doesn't compile
template <typename Tag>
struct TaggedString {
    // Allow explicit construction from anything convertible to const char*
    constexpr explicit TaggedString(const char* v) noexcept
        : m_value(v)
    {
    }

    // Allow implicit construction from *just* std::string and not things convertible
    // to std::string (such as other types of tagged std::string)
    template <typename Str, typename = typename std::enable_if<std::is_same<Str, std::string>::value>::type>
    constexpr TaggedString(Str v) noexcept
        : m_value(v)
    {
    }

    constexpr TaggedString(TaggedString const& v) = default;
    constexpr TaggedString& operator=(TaggedString const& v) = default;
    constexpr TaggedString(TaggedString&& v) = default;
    constexpr TaggedString& operator=(TaggedString&& v) = default;

    constexpr operator const char*() const noexcept
    {
        return m_value.data();
    }

    friend constexpr bool operator==(TaggedString l, TaggedString r) noexcept
    {
        return l.m_value == r.m_value;
    }
    friend constexpr bool operator!=(TaggedString l, TaggedString r) noexcept
    {
        return l.m_value != r.m_value;
    }

private:
    std::string m_value;
};

} // namespace util
} // namespace realm
#endif // REALM_OS_UTIL_TAGGED_STRING_HPP
