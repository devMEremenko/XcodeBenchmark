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

#ifndef REALM_QUERY_STATE_HPP
#define REALM_QUERY_STATE_HPP

#include <cstdlib> // size_t
#include <cstdint> // unint8_t etc

namespace realm {

enum Action { act_ReturnFirst, act_Sum, act_Max, act_Min, act_Count, act_FindAll, act_CallbackIdx, act_Average };


// Array::VTable only uses the first 4 conditions (enums) in an array of function pointers
enum { cond_Equal, cond_NotEqual, cond_Greater, cond_Less, cond_VTABLE_FINDER_COUNT, cond_None, cond_LeftNotNull };

class ArrayUnsigned;
class Mixed;

class QueryStateBase {
public:
    int64_t m_minmax_key = -1; // used only for min/max, to save index of current min/max value
    uint64_t m_key_offset = 0;
    const ArrayUnsigned* m_key_values = nullptr;
    QueryStateBase(size_t limit = -1)
        : m_limit(limit)
    {
    }
    virtual ~QueryStateBase() {}

    // Called when we have a match.
    // The return value indicates if the query should continue.
    virtual bool match(size_t, Mixed) noexcept = 0;

    virtual bool match_pattern(size_t, uint64_t)
    {
        return false;
    }

    inline size_t match_count() const noexcept
    {
        return m_match_count;
    }

    inline size_t limit() const noexcept
    {
        return m_limit;
    }

protected:
    size_t m_match_count = 0;
    size_t m_limit;

private:
    virtual void dyncast();
};

template <class>
class QueryStateMin;

template <class>
class QueryStateMax;

class QueryStateCount : public QueryStateBase {
public:
    QueryStateCount(size_t limit = -1)
        : QueryStateBase(limit)
    {
    }
    bool match(size_t, Mixed) noexcept final;
    size_t get_count() const noexcept
    {
        return m_match_count;
    }
};

} // namespace realm

#endif /* REALM_QUERY_STATE_HPP */
