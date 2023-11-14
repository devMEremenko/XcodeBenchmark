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

#ifndef REALM_UTIL_COMPRESSION_HPP
#define REALM_UTIL_COMPRESSION_HPP

#include <realm/util/buffer.hpp>
#include <realm/util/features.h>
#include <realm/util/input_stream.hpp>
#include <realm/util/span.hpp>

#include <array>
#include <memory>
#include <system_error>
#include <stdint.h>
#include <stddef.h>
#include <string>
#include <vector>

// Use libcompression by default on Apple platforms, but it can be disabled to
// test the zlib codepaths
#ifndef REALM_USE_LIBCOMPRESSION
#define REALM_USE_LIBCOMPRESSION REALM_PLATFORM_APPLE
#endif

namespace realm::util::compression {

enum class error {
    out_of_memory = 1,
    compress_buffer_too_small = 2,
    compress_error = 3,
    compress_input_too_long = 4,
    corrupt_input = 5,
    incorrect_decompressed_size = 6,
    decompress_error = 7,
    decompress_unsupported = 8,
};

const std::error_category& error_category() noexcept;

std::error_code make_error_code(error) noexcept;

} // namespace realm::util::compression

namespace std {

template <>
struct is_error_code_enum<realm::util::compression::error> {
    static const bool value = true;
};

} // namespace std

namespace realm::util::compression {

class Alloc {
public:
    // Returns null on "out of memory"
    virtual void* alloc(size_t size) noexcept = 0;
    virtual void free(void* addr) noexcept = 0;
    virtual ~Alloc() {}
};

class CompressMemoryArena : public Alloc {
public:
    void* alloc(size_t size) noexcept override final
    {
        size_t offset = m_offset;
        size_t misalignment = offset % alignof(std::max_align_t);
        size_t padding = (misalignment == 0) ? 0 : (alignof(std::max_align_t) - misalignment);
        if (padding > m_size - offset)
            return nullptr;
        offset += padding;
        REALM_ASSERT(offset % alignof(std::max_align_t) == 0);
        void* addr = m_buffer.get() + offset;
        if (size > m_size - offset)
            return nullptr;
        m_offset = offset + size;
        return addr;
    }

    void free(void*) noexcept override final
    {
        // No-op
    }

    void reset() noexcept
    {
        m_offset = 0;
    }

    size_t size() const noexcept
    {
        return m_size;
    }

    void resize(size_t size)
    {
        m_buffer = std::make_unique<char[]>(size); // Throws
        m_size = size;
        m_offset = 0;
    }

private:
    size_t m_size = 0, m_offset = 0;
    std::unique_ptr<char[]> m_buffer;
};


/// compress_bound() calculates an upper bound on the size of the compressed
/// data. The caller can use this function to allocate memory buffer calling
/// compress(). Returns 0 if the bound would overflow size_t.
size_t compress_bound(size_t uncompressed_size) noexcept;

/// compress() compresses the data in the \a uncompressed_buf using zlib and
/// stores it in \a compressed_buf. If compression is successful, the
/// compressed size is stored in \a compressed_size. \a compression_level is
/// [1-9] with 1 the fastest for the current zlib implementation. The returned
/// error code is of category compression::error_category. If \a Alloc is
/// non-null, it is used for all memory allocations inside compress() and
/// compress() will not throw any exceptions.
std::error_code compress(Span<const char> uncompressed_buf, Span<char> compressed_buf, size_t& compressed_size,
                         int compression_level = 1, Alloc* custom_allocator = nullptr);

/// decompress() decompresses zlib-compressed the data in \a compressed_buf into \a decompressed_buf.
/// decompress may throw std::bad_alloc, but all other errors (including the
/// target buffer being too small) are reported by returning an error code of
/// category compression::error_code.
std::error_code decompress(Span<const char> compressed_buf, Span<char> decompressed_buf);

/// decompress() decompresses zlib-compressed data in \a compressed into \a
/// decompressed_buf. decompress may throw std::bad_alloc or any exceptions
/// thrown by \a compressed, but all other errors (including the target buffer
/// being too small) are reported by returning an error code of category
/// compression::error_code.
std::error_code decompress(InputStream& compressed, Span<char> decompressed_buf);

/// allocate_and_compress() compresses the data in \a uncompressed_buf using
/// zlib, storing the result in \a compressed_buf. \a compressed_buf is resized
/// to the required size, and on non-error return has size equal to the
/// compressed size. All errors other than std::bad_alloc are returned as an
/// error code of categrory compression::error_code.
std::error_code allocate_and_compress(CompressMemoryArena& compress_memory_arena, Span<const char> uncompressed_buf,
                                      std::vector<char>& compressed_buf);

/// decompress() decompresses data produced by
/// allocate_and_compress_nonportable() in \a compressed into \a decompressed.
/// \a decompressed is resized to the required size, and on non-error return
/// has size equal to the compressed size. All errors other than std::bad_alloc
/// are returned as an error code of categrory compression::error_code.
std::error_code decompress_nonportable(InputStream& compressed, AppendBuffer<char>& decompressed);

/// decompress_nonportable_input_stream() returns an input stream which wraps
/// the \a source input stream and decompresses data produced by
/// allocate_and_compress_nonportable(). The returned input stream will be
/// nullptr if the source data is in an unsupported format. Decompression
/// errors will be reported by throwing a std::system_error containing an error
/// code of category compression::error_code. If this returns a non-nullptr
/// input stream, \a total_size is set to the decompressed size of the data
/// which will be produced by fully consuming the returned input stream.
std::unique_ptr<InputStream> decompress_nonportable_input_stream(InputStream& source, size_t& total_size);

/// allocate_and_compress_nonportable() compresses the data stored in \a
/// uncompressed_buf, writing it to \a compressed_buf.
///
/// The compressed data may use one of several compression algorithms and
/// contains a nonstandard header, and so it can only be read by
/// decompress_nonportable() or decompress_nonportable_input_stream(). The set
/// of compression algorithms available is platform-specific, so data
/// compressed with this function must only be used locally.
///
/// This function reports errors by throwing a std::system_error containing an
/// error code of category compression::error_code. It may additionally throw
/// std::bad_alloc.
void allocate_and_compress_nonportable(CompressMemoryArena& compress_memory_arena, Span<const char> uncompressed_buf,
                                       util::AppendBuffer<char>& compressed_buf);

/// allocate_and_compress_nonportable() compresses the data stored in \a
/// uncompressed_buf, returning a buffer of the appropriate size.
///
/// The compressed data may use one of several compression algorithms and
/// contains a nonstandard header, and so it can only be read by
/// decompress_nonportable() or decompress_nonportable_input_stream(). The set
/// of compression algorithms available is platform-specific, so data
/// compressed with this function must only be used locally.
///
/// This function reports errors by throwing a std::system_error containing an
/// error code of category compression::error_code. It may additionally throw
/// std::bad_alloc.
util::AppendBuffer<char> allocate_and_compress_nonportable(Span<const char> uncompressed_buf);

/// Get the decompressed size of the data produced by
/// allocate_and_compress_nonportable() which is stored in \a source.
size_t get_uncompressed_size_from_header(InputStream& source);

} // namespace realm::util::compression

#endif // REALM_UTIL_COMPRESSION_HPP
