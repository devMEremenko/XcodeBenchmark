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

#ifndef REALM_ARRAY_INTEGER_TPL_HPP
#define REALM_ARRAY_INTEGER_TPL_HPP

#include <realm/array_integer.hpp>
#include <realm/array_with_find.hpp>

namespace realm {

template <class cond, class Callback>
bool ArrayInteger::find(value_type value, size_t start, size_t end, QueryStateBase* state, Callback callback) const
{
    return ArrayWithFind(*this).find<cond, Callback>(value, start, end, 0, state, callback);
}

template <class Callback>
inline bool ArrayIntNull::find_impl(int cond, value_type value, size_t start, size_t end, QueryStateBase* state,
                                    Callback callback) const
{
    switch (cond) {
        case cond_Equal:
            return find_impl<Equal>(value, start, end, state, callback);
        case cond_NotEqual:
            return find_impl<NotEqual>(value, start, end, state, callback);
        case cond_Greater:
            return find_impl<Greater>(value, start, end, state, callback);
        case cond_Less:
            return find_impl<Less>(value, start, end, state, callback);
        case cond_None:
            return find_impl<None>(value, start, end, state, callback);
        case cond_LeftNotNull:
            return find_impl<NotNull>(value, start, end, state, callback);
    }
    REALM_ASSERT_DEBUG(false);
    return false;
}

template <class cond, class Callback>
bool ArrayIntNull::find_impl(value_type opt_value, size_t start, size_t end, QueryStateBase* state,
                             Callback callback) const
{
    int64_t null_value = Array::get(0);
    bool find_null = !bool(opt_value);
    int64_t value;

    size_t end2 = (end == npos ? size() : end) + 1;
    size_t start2 = start + 1;
    size_t baseindex2 = size_t(-1);

    if constexpr (std::is_same_v<cond, Equal>) {
        if (find_null) {
            value = null_value;
        }
        else {
            if (*opt_value == null_value) {
                // If the value to search for is equal to the null value, the value cannot be in the array
                return true;
            }
            else {
                value = *opt_value;
            }
        }

        // Fall back to plain Array find.
        return ArrayWithFind(*this).find<cond>(value, start2, end2, baseindex2, state, callback);
    }
    else {
        cond c;

        if (opt_value) {
            value = *opt_value;
        }
        else {
            value = null_value;
        }

        for (size_t i = start2; i < end2; ++i) {
            int64_t v = Array::get(i);
            bool value_is_null = (v == null_value);
            if (c(v, value, value_is_null, find_null)) {
                util::Optional<int64_t> v2 = value_is_null ? util::none : util::make_optional(v);
                if (!ArrayWithFind(*this).find_action(i + baseindex2, v2, state, callback)) {
                    return false; // tell caller to stop aggregating/search
                }
            }
        }
        return true; // tell caller to continue aggregating/search (on next array leafs)
    }
}

template <class cond>
size_t ArrayIntNull::find_first(value_type value, size_t start, size_t end) const
{
    QueryStateFindFirst state;
    find_impl<cond>(value, start, end, &state, nullptr);

    if (state.match_count() > 0)
        return to_size_t(state.m_state);
    else
        return not_found;
}

template <class cond, class Callback>
inline bool ArrayIntNull::find(value_type value, size_t start, size_t end, QueryStateBase* state,
                               Callback callback) const
{
    return find_impl<cond, Callback>(value, start, end, state, callback);
}

} // namespace realm

#endif /* REALM_ARRAY_INTEGER_TPL_HPP */
