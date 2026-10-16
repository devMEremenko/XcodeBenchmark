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

#ifndef REALM_ARRAY_REF_HPP_
#define REALM_ARRAY_REF_HPP_

#include <realm/array.hpp>

namespace realm {

class ArrayRef : public Array {
public:
    using value_type = ref_type;

    explicit ArrayRef(Allocator& allocator) noexcept
        : Array(allocator)
    {
    }

    void create(size_t sz = 0)
    {
        Array::create(type_HasRefs, false, sz, 0);
    }

    void add(ref_type value)
    {
        Array::add(from_ref(value));
    }

    void set(size_t ndx, ref_type value)
    {
        Array::set(ndx, from_ref(value));
    }

    void insert(size_t ndx, ref_type value)
    {
        Array::insert(ndx, from_ref(value));
    }

    ref_type get(size_t ndx) const noexcept
    {
        return to_ref(Array::get(ndx));
    }
    void verify() const
    {
#ifdef REALM_DEBUG
        Array::verify();
        REALM_ASSERT(has_refs());
#endif
    }
};

} // namespace realm

#endif /* REALM_ARRAY_REF_HPP_ */
