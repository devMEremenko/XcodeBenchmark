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

#ifndef REALM_UTIL_TO_STRING_HPP
#define REALM_UTIL_TO_STRING_HPP

#include <cstdint>
#include <iosfwd>
#include <ostream>
#include <string>
#include <string_view>

#include <realm/util/optional.hpp>

namespace realm {
class StringData;
namespace util {

class Printable {
public:
    constexpr Printable(bool value)
        : m_type(Type::Bool)
        , m_uint(value)
    {
    }
    constexpr Printable(unsigned char value)
        : m_type(Type::Uint)
        , m_uint(value)
    {
    }
    constexpr Printable(unsigned short value)
        : m_type(Type::Uint)
        , m_uint(value)
    {
    }
    constexpr Printable(unsigned int value)
        : m_type(Type::Uint)
        , m_uint(value)
    {
    }
    constexpr Printable(unsigned long value)
        : m_type(Type::Uint)
        , m_uint(value)
    {
    }
    constexpr Printable(unsigned long long value)
        : m_type(Type::Uint)
        , m_uint(value)
    {
    }
    constexpr Printable(char value)
        : m_type(Type::Int)
        , m_int(value)
    {
    }
    constexpr Printable(signed char value)
        : m_type(Type::Int)
        , m_int(value)
    {
    }
    constexpr Printable(short value)
        : m_type(Type::Int)
        , m_int(value)
    {
    }
    constexpr Printable(int value)
        : m_type(Type::Int)
        , m_int(value)
    {
    }
    constexpr Printable(long value)
        : m_type(Type::Int)
        , m_int(value)
    {
    }
    constexpr Printable(long long value)
        : m_type(Type::Int)
        , m_int(value)
    {
    }
    constexpr Printable(double value)
        : m_type(Type::Double)
        , m_double(value)
    {
    }
    constexpr Printable(const char* value)
        : m_type(Type::String)
        , m_string(value)
    {
    }
    Printable(std::string const& value)
        : m_type(Type::String)
        , m_string(value)
    {
    }
    Printable(StringData value);

    template <typename T, typename = std::enable_if_t<!std::is_constructible_v<Printable, T>>>
    Printable(T const& value)
        : m_type(Type::Callback)
        , m_callback({static_cast<const void*>(&value), [](std::ostream& os, const void* ptr) {
                          stream_possible_optional(os, *static_cast<const T*>(ptr));
                      }})
    {
    }


    void print(std::ostream& out, bool quote) const;
    std::string str() const;

    static void print_all(std::ostream& out, const std::initializer_list<Printable>& values, bool quote);

private:
    enum class Type {
        Bool,
        Int,
        Uint,
        Double,
        String,
        Callback,
    } m_type;

    struct Callback {
        const void* data;
        void (*fn)(std::ostream&, const void*);
    };

    union {
        uintmax_t m_uint;
        intmax_t m_int;
        double m_double;
        std::string_view m_string;
        Callback m_callback;
    };
};


template <class T>
std::string to_string(const T& v)
{
    return Printable(v).str();
}

void format(std::ostream&, const char* fmt, std::initializer_list<Printable>);
std::string format(const char* fmt, std::initializer_list<Printable>);

// format string format:
//  "%%" - literal '%'
//  "%1" - substitutes Nth argument, 1-indexed
//
// format("Hello %1, meet %2. %3%% complete.", "Alice", "Bob", 97)
//  -> "Hello Alice, meet Bob. 97% complete."
template <typename... Args>
std::string format(const char* fmt, Args&&... args)
{
    return format(fmt, {Printable(args)...});
}

template <typename... Args>
void format(std::ostream& os, const char* fmt, Args&&... args)
{
    format(os, fmt, {Printable(args)...});
}

} // namespace util
} // namespace realm

#endif // REALM_UTIL_TO_STRING_HPP
