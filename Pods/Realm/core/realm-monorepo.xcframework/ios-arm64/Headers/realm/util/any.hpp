////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#ifndef REALM_UTIL_ANY_HPP
#define REALM_UTIL_ANY_HPP

#include <any>

namespace realm::util {
using Any = std::any;

// We can't use std::any_cast directly because the versions which throw on error
// have a deployment target of iOS 11. Once we bump our deployment target to
// that we should delete this.
template <class T>
T any_cast(Any const& v)
{
    using U = std::remove_cv_t<std::remove_reference_t<T>>;
    static_assert(std::is_constructible_v<T, U const&>,
                  "T must be a const lvalue reference or a CopyConstructible type");
    if (auto ptr = std::any_cast<std::add_const_t<U>>(&v))
        return static_cast<T>(*ptr);
    throw std::bad_cast();
}

template <class T>
T any_cast(Any& v)
{
    using U = std::remove_cv_t<std::remove_reference_t<T>>;
    static_assert(std::is_constructible_v<T, U&>, "T must be a lvalue reference or a CopyConstructible type");
    if (auto ptr = std::any_cast<U>(&v))
        return static_cast<T>(*ptr);
    throw std::bad_cast();
}

template <class T>
T any_cast(Any&& v)
{
    using U = std::remove_cv_t<std::remove_reference_t<T>>;
    static_assert(std::is_constructible_v<T, U>, "T must be a rvalue reference or a CopyConstructible type");
    if (auto ptr = std::any_cast<U>(&v))
        return static_cast<T>(std::move(*ptr));
    throw std::bad_cast();
}
} // namespace realm::util

#endif // REALM_UTIL_ANY_HPP
