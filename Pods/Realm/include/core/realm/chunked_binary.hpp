/*************************************************************************
 *
 * Copyright 2019 Realm Inc.
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

#ifndef REALM_NOINST_CHUNKED_BINARY_HPP
#define REALM_NOINST_CHUNKED_BINARY_HPP

#include <realm/binary_data.hpp>
#include <realm/column_binary.hpp>
#include <realm/table.hpp>

#include <realm/util/buffer.hpp>
#include <realm/util/buffer_stream.hpp>
#include <realm/util/input_stream.hpp>


namespace realm {

/// ChunkedBinaryData manages a vector of BinaryData. It is used to facilitate
/// extracting large binaries from binary columns and tables.
class ChunkedBinaryData {
public:
    ChunkedBinaryData() {}

    ChunkedBinaryData(const BinaryData& bd)
        : m_begin{bd}
    {
    }

    ChunkedBinaryData(const BinaryColumn& col, size_t index)
        : m_begin{&col, index}
    {
    }

    /// size() returns the number of bytes in the chunked binary.
    /// FIXME: This operation is O(n).
    size_t size() const noexcept;

    /// is_null returns true if the chunked binary has zero chunks or if
    /// the first chunk points to the nullptr.
    bool is_null() const;

    /// FIXME: O(n)
    char operator[](size_t index) const;

    std::string hex_dump(const char* separator = " ", int min_digits = -1) const;

    void write_to(util::ResettableExpandableBufferOutputStream& out) const;

    /// copy_to() clears the target buffer and then copies the chunked binary
    /// data to it.
    void copy_to(util::AppendBuffer<char>& dest) const;

    /// get_first_chunk() is used in situations
    /// where it is known that there is exactly one
    /// chunk. This is the case if the ChunkedBinary
    /// has been constructed from BinaryData.
    BinaryData get_first_chunk() const;

    BinaryIterator iterator() const noexcept;

private:
    BinaryIterator m_begin;
};

class ChunkedBinaryInputStream : public util::InputStream {
public:
    explicit ChunkedBinaryInputStream(const ChunkedBinaryData& chunks)
        : m_it(chunks.iterator())
    {
    }

    util::Span<const char> next_block() override
    {
        return m_it.get_next();
    }

private:
    BinaryIterator m_it;
};

} // namespace realm

#endif // REALM_NOINST_CHUNKED_BINARY_HPP
