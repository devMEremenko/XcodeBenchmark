/*************************************************************************
 *
 * Copyright 2021 Realm Inc.
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

#pragma once

#include <type_traits>

#include "realm/status.hpp"
#include "realm/util/assert.hpp"
#include "realm/util/features.h"
#include "realm/util/optional.hpp"

namespace realm {

template <typename T>
class StatusWith;

template <typename T>
constexpr bool is_status_with = false;
template <typename T>
constexpr bool is_status_with<StatusWith<T>> = true;

template <typename T>
constexpr bool is_status_or_status_with = std::is_same_v<T, ::realm::Status> || is_status_with<T>;

template <typename T>
using StatusOrStatusWith = std::conditional_t<std::is_void_v<T>, Status, StatusWith<T>>;

/**
 * StatusWith is used to return an error or a value.
 * This class is designed to make exception-free code cleaner by not needing as many out
 * parameters.
 *
 * Example:
 * StatusWith<int> fib( int n ) {
 *   if ( n < 0 )
 *       return StatusWith<int>( ErrorCodes::BadValue, "parameter to fib has to be >= 0" );
 *   if ( n <= 1 ) return StatusWith<int>( 1 );
 *   StatusWith<int> a = fib( n - 1 );
 *   StatusWith<int> b = fib( n - 2 );
 *   if ( !a.isOK() ) return a;
 *   if ( !b.isOK() ) return b;
 *   return StatusWith<int>( a.getValue() + b.getValue() );
 * }
 */
template <typename T>
class REALM_NODISCARD StatusWith {
    static_assert(!is_status_or_status_with<T>, "StatusWith<Status> and StatusWith<StatusWith<T>> are banned.");

public:
    using value_type = T;

    template <typename Reason, std::enable_if_t<std::is_constructible_v<std::string_view, Reason>, int> = 0>
    StatusWith(ErrorCodes::Error code, Reason reason)
        : m_status(code, reason)
    {
    }

    StatusWith(Status status)
        : m_status(std::move(status))
    {
    }

    StatusWith(T value)
        : m_status(Status::OK())
        , m_value(std::move(value))
    {
    }

    bool is_ok() const
    {
        return m_status.is_ok();
    }

    const T& get_value() const
    {
        REALM_ASSERT_DEBUG(is_ok());
        REALM_ASSERT_RELEASE(m_value);
        return *m_value;
    }

    T& get_value()
    {
        REALM_ASSERT_DEBUG(is_ok());
        REALM_ASSERT_RELEASE(m_value);
        return *m_value;
    }

    const Status& get_status() const
    {
        return m_status;
    }

private:
    Status m_status;
    util::Optional<T> m_value;
};

template <typename T, typename... Args>
StatusWith<T> make_status_with(Args&&... args)
{
    return StatusWith<T>{T(std::forward<Args>(args)...)};
}

template <typename T>
auto operator<<(std::ostream& stream, const StatusWith<T>& sw)
    -> decltype(stream << sw.get_value()) // SFINAE on T streamability.
{
    if (sw.is_ok())
        return stream << sw.get_value();
    return stream << sw.get_status();
}

//
// EqualityComparable(StatusWith<T>, T). Intentionally not providing an ordering relation.
//

template <typename T>
bool operator==(const StatusWith<T>& sw, const T& val)
{
    return sw.is_ok() && sw.get_value() == val;
}

template <typename T>
bool operator==(const T& val, const StatusWith<T>& sw)
{
    return sw.is_ok() && val == sw.get_value();
}

template <typename T>
bool operator!=(const StatusWith<T>& sw, const T& val)
{
    return !(sw == val);
}

template <typename T>
bool operator!=(const T& val, const StatusWith<T>& sw)
{
    return !(val == sw);
}

//
// EqualityComparable(StatusWith<T>, Status)
//

template <typename T>
bool operator==(const StatusWith<T>& sw, const Status& status)
{
    return sw.get_status() == status;
}

template <typename T>
bool operator==(const Status& status, const StatusWith<T>& sw)
{
    return status == sw.get_status();
}

template <typename T>
bool operator!=(const StatusWith<T>& sw, const Status& status)
{
    return !(sw == status);
}

template <typename T>
bool operator!=(const Status& status, const StatusWith<T>& sw)
{
    return !(status == sw);
}

//
// EqualityComparable(StatusWith<T>, ErrorCode)
//

template <typename T>
bool operator==(const StatusWith<T>& sw, const ErrorCodes::Error code)
{
    return sw.get_status() == code;
}

template <typename T>
bool operator==(const ErrorCodes::Error code, const StatusWith<T>& sw)
{
    return code == sw.get_status();
}

template <typename T>
bool operator!=(const StatusWith<T>& sw, const ErrorCodes::Error code)
{
    return !(sw == code);
}

template <typename T>
bool operator!=(const ErrorCodes::Error code, const StatusWith<T>& sw)
{
    return !(code == sw);
}

} // namespace realm
