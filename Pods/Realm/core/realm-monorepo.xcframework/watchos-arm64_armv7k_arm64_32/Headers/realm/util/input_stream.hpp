/*************************************************************************
 *
 * Copyright 2022 Realm Inc.
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

#ifndef REALM_UTIL_INPUT_STREAM_HPP
#define REALM_UTIL_INPUT_STREAM_HPP

#include <realm/utilities.hpp>
#include <realm/util/span.hpp>

namespace realm::util {
class InputStream {
public:
    /// Returns a span containing the next block.
    /// A zero-length span indicates end-of-input.
    virtual Span<const char> next_block() = 0;

    virtual ~InputStream() noexcept = default;
};

class SimpleInputStream final : public InputStream {
public:
    SimpleInputStream(Span<const char> data)
        : m_data(data)
    {
    }

    Span<const char> next_block() override
    {
        auto ret = m_data;
        m_data = m_data.last(0);
        return ret;
    }

private:
    Span<const char> m_data;
};

} // namespace realm::util

#endif // REALM_UTIL_INPUT_STREAM_HPP
