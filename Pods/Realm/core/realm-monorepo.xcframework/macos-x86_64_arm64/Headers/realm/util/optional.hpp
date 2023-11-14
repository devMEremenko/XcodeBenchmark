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

#pragma once
#ifndef REALM_UTIL_OPTIONAL_HPP
#define REALM_UTIL_OPTIONAL_HPP

#include <optional>
#include <ostream>

namespace realm {
namespace util {

template <class T>
using Optional = std::optional<T>;
using None = std::nullopt_t;

template <class T, class... Args>
Optional<T> some(Args&&... args)
{
    return std::make_optional<T>(std::forward<Args>(args)...);
}

using std::make_optional;

constexpr auto none = std::nullopt;

template <class T>
struct RemoveOptional {
    using type = T;
};
template <class T>
struct RemoveOptional<Optional<T>> {
    using type = typename RemoveOptional<T>::type; // Remove recursively
};

/**
 * Writes a T to an ostream, with special handling if T is a std::optional.
 *
 * This function supports both optional and non-optional Ts, so that callers don't need to do their own dispatch.
 */
template <class T>
std::ostream& stream_possible_optional(std::ostream& os, const T& rhs)
{
    return os << rhs;
}
template <class T>
std::ostream& stream_possible_optional(std::ostream& os, const std::optional<T>& rhs)
{
    if (rhs) {
        os << "some(" << *rhs << ")";
    }
    else {
        os << "none";
    }
    return os;
}

} // namespace util

using util::none;

} // namespace realm

#endif // REALM_UTIL_OPTIONAL_HPP
