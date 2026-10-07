/*************************************************************************
 *
 * Copyright 2020 Realm Inc.
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

#ifndef REALM_BSON_MAX_KEY_HPP
#define REALM_BSON_MAX_KEY_HPP

namespace realm {
namespace bson {

/// MaxKey will always be the greatest value when comparing to other BSON types
struct MaxKey {
    constexpr explicit MaxKey() {}
};
static constexpr MaxKey max_key{};

inline bool operator==(const MaxKey&, const MaxKey&) noexcept
{
    return true;
}

inline bool operator!=(const MaxKey&, const MaxKey&) noexcept
{
    return false;
}

} // namespace bson
} // namespace realm

#endif /* REALM_BSON_MAX_KEY_HPP */
