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

#ifndef REALM_IMPL_TRANSACT_LOG_HPP
#define REALM_IMPL_TRANSACT_LOG_HPP

#include <realm/binary_data.hpp>
#include <realm/collection.hpp>
#include <realm/data_type.hpp>
#include <realm/group.hpp>
#include <realm/string_data.hpp>
#include <realm/util/buffer.hpp>
#include <realm/util/input_stream.hpp>

namespace realm {

struct GlobalKey;

namespace _impl {

/// Transaction log instruction encoding
/// NOTE: Any change to this enum is a file-format breaking change.
enum Instruction {
    instr_InsertGroupLevelTable = 1,
    instr_EraseGroupLevelTable = 2, // Remove columnless table from group
    instr_RenameGroupLevelTable = 3,

    instr_SelectTable = 10,
    instr_CreateObject = 11,
    instr_RemoveObject = 12,
    instr_Set = 13,
    instr_SetDefault = 14,
    // instr_ClearTable = 15, Remove all rows in selected table  (unused from file format 11)

    instr_InsertColumn = 20, // Insert new column into to selected descriptor
    instr_EraseColumn = 21,  // Remove column from selected descriptor
    instr_RenameColumn = 22, // Rename column in selected descriptor
    // instr_SetLinkType = 23,  Strong/weak (unused from file format 11)

    instr_SelectCollection = 30,
    instr_CollectionInsert = 31, // Insert collection entry
    instr_CollectionSet = 32,    // Assign to collection entry
    instr_CollectionMove = 33,   // Move an entry within an ordered collection
    // instr_ListSwap = 34,   Swap two entries within a list (unused from file format 11)
    instr_CollectionErase = 35, // Remove an entry from a collection
    instr_CollectionClear = 36, // Remove all entries from a collection

    // No longer emitted, but supported for a file shared with an older version.
    // Treated identically to the Collection versions.
    instr_DictionaryInsert = 37,
    instr_DictionarySet = 38,
    instr_DictionaryErase = 39,
    instr_SetInsert = 40,
    instr_SetErase = 41,
    instr_SetClear = 42,

    // An action involving TypedLinks has occurred which caused
    // the number of backlink columns to change. This can happen
    // when a TypedLink is created for the first time to a Table.
    instr_TypedLinkChange = 43,
};

class TransactLogStream {
public:
    virtual ~TransactLogStream() {}

    /// Ensure contiguous free space in the transaction log
    /// buffer. This method must update `out_free_begin`
    /// and `out_free_end` such that they refer to a chunk
    /// of free space whose size is at least \a n.
    ///
    /// \param size The required amount of contiguous free space. Must be
    /// small (probably not greater than 1024)
    /// \param out_free_begin must point to current write position which must be inside earlier
    /// allocated area. Will be updated to point to new writing position.
    /// \param out_free_end Will be updated to point to end of allocated area.
    virtual void transact_log_reserve(size_t size, char** out_free_begin, char** out_free_end) = 0;

    /// Copy the specified data into the transaction log buffer. This
    /// function should be called only when the specified data does
    /// not fit inside the chunk of free space currently referred to
    /// by `out_free_begin` and `out_free_end`.
    ///
    /// This method must update `out_begin` and
    /// `out_end` such that, upon return, they still
    /// refer to a (possibly empty) chunk of free space.
    virtual void transact_log_append(const char* data, size_t size, char** out_free_begin, char** out_free_end) = 0;
};

class TransactLogBufferStream : public TransactLogStream {
public:
    void transact_log_reserve(size_t size, char** out_free_begin, char** out_free_end) override;
    void transact_log_append(const char* data, size_t size, char** out_free_begin, char** out_free_end) override;

    const char* get_data() const;
    char* get_data();
    size_t get_size();

private:
    util::Buffer<char> m_buffer;
};


// LCOV_EXCL_START (because the NullInstructionObserver is trivial)
class NullInstructionObserver {
public:
    /// The following methods are also those that TransactLogParser expects
    /// to find on the `InstructionHandler`.

    // No selection needed:
    bool select_table(TableKey)
    {
        return true;
    }
    bool select_collection(ColKey, ObjKey)
    {
        return true;
    }
    bool insert_group_level_table(TableKey)
    {
        return true;
    }
    bool erase_class(TableKey)
    {
        return true;
    }
    bool rename_class(TableKey)
    {
        return true;
    }
    bool typed_link_change(ColKey, TableKey)
    {
        return true;
    }

    // Must have table selected:
    bool create_object(ObjKey)
    {
        return true;
    }
    bool remove_object(ObjKey)
    {
        return true;
    }
    bool modify_object(ColKey, ObjKey)
    {
        return true;
    }

    // Must have descriptor selected:
    bool insert_column(ColKey)
    {
        return true;
    }
    bool erase_column(ColKey)
    {
        return true;
    }
    bool rename_column(ColKey)
    {
        return true;
    }
    bool set_link_type(ColKey)
    {
        return true;
    }

    // Must have collection selected:
    bool collection_set(size_t)
    {
        return true;
    }
    bool collection_insert(size_t)
    {
        return true;
    }
    bool collection_move(size_t, size_t)
    {
        return true;
    }
    bool collection_erase(size_t)
    {
        return true;
    }
    bool collection_clear(size_t)
    {
        return true;
    }

    void parse_complete() {}
};
// LCOV_EXCL_STOP (NullInstructionObserver)


/// See Replication for information about the meaning of the
/// arguments of each of the functions in this class.
class TransactLogEncoder {
public:
    /// The following methods are also those that TransactLogParser expects
    /// to find on the `InstructionHandler`.

    // No selection needed:
    bool select_table(TableKey key);
    bool insert_group_level_table(TableKey table_key);
    bool erase_class(TableKey table_key);
    bool rename_class(TableKey table_key);

    /// Must have table selected.
    bool create_object(ObjKey key)
    {
        append_simple_instr(instr_CreateObject, key); // Throws
        return true;
    }

    bool remove_object(ObjKey key)
    {
        append_simple_instr(instr_RemoveObject, key); // Throws
        return true;
    }
    bool modify_object(ColKey col_key, ObjKey key);

    // Must have descriptor selected:
    bool insert_column(ColKey col_key);
    bool erase_column(ColKey col_key);
    bool rename_column(ColKey col_key);
    bool set_link_type(ColKey col_key);

    // Must have collection selected:
    bool select_collection(ColKey col_key, ObjKey key);
    bool collection_set(size_t collection_ndx);
    bool collection_insert(size_t ndx);
    bool collection_move(size_t from_ndx, size_t to_ndx);
    bool collection_erase(size_t collection_ndx);
    bool collection_clear(size_t old_size);

    bool typed_link_change(ColKey col, TableKey dest);


    /// End of methods expected by parser.


    TransactLogEncoder(TransactLogStream& out_stream);
    void set_buffer(char* new_free_begin, char* new_free_end);
    char* write_position() const
    {
        return m_transact_log_free_begin;
    }

private:
    // Make sure this is in agreement with the actual integer encoding
    // scheme (see encode_int()).
    static constexpr int max_enc_bytes_per_int = 10;
// Space is reserved in chunks to avoid excessive over allocation.
#ifdef REALM_DEBUG
    static constexpr int max_numbers_per_chunk = 2; // Increase the chance of chunking in debug mode
#else
    static constexpr int max_numbers_per_chunk = 8;
#endif

    TransactLogStream& m_stream;

    // These two delimit a contiguous region of free space in a
    // transaction log buffer following the last written data. It may
    // be empty.
    char* m_transact_log_free_begin = nullptr;
    char* m_transact_log_free_end = nullptr;

    char* reserve(size_t size);
    /// \param ptr Must be in the range [m_transact_log_free_begin, m_transact_log_free_end]
    void advance(char* ptr) noexcept;

    template <class T>
    size_t max_size(T);

    size_t max_size_list()
    {
        return 0;
    }

    template <class T, class... Args>
    size_t max_size_list(T val, Args... args)
    {
        return max_size(val) + max_size_list(args...);
    }

    template <class T>
    char* encode(char* ptr, T value);

    char* encode_list(char* ptr)
    {
        advance(ptr);
        return ptr;
    }

    template <class T, class... Args>
    char* encode_list(char* ptr, T value, Args... args)
    {
        return encode_list(encode(ptr, value), args...);
    }

    template <class... L>
    void append_simple_instr(L... numbers);

    template <typename... L>
    void append_string_instr(Instruction, StringData);

    template <class T>
    static char* encode_int(char*, T value);
    friend class TransactLogParser;
};


class TransactLogParser {
public:
    /// See `TransactLogEncoder` for a list of methods that the `InstructionHandler` must define.
    template <class InstructionHandler>
    void parse(util::InputStream&, InstructionHandler&);

private:
    util::Buffer<char> m_input_buffer{1024};

    // The input stream is assumed to consist of chunks of memory organised such that
    // every instruction resides in a single chunk only.
    util::InputStream* m_input;
    // pointer into transaction log, each instruction is parsed from m_input_begin and onwards.
    // Each instruction are assumed to be contiguous in memory.
    const char* m_input_begin;
    // pointer to one past current instruction log chunk. If m_input_begin reaches m_input_end,
    // a call to next_input_buffer will move m_input_begin and m_input_end to a new chunk of
    // memory. Setting m_input_end to 0 disables this check, and is used if it is already known
    // that all of the instructions are in memory.
    const char* m_input_end;
    std::string m_string_buffer;

    REALM_COLD REALM_NORETURN void parser_error() const;

    template <class InstructionHandler>
    void parse_one(InstructionHandler&);
    bool has_next() noexcept;

    template <class T>
    T read_int();

    void read_bytes(char* data, size_t size);
    BinaryData read_buffer(std::string&, size_t size);

    StringData read_string(std::string&);

    // Advance m_input_begin and m_input_end to reflect the next block of instructions
    // Returns false if no more input was available
    bool next_input_buffer();

    // return true if input was available
    bool read_char(char&); // throws
};


/// Implementation:

inline void TransactLogBufferStream::transact_log_reserve(size_t size, char** inout_new_begin, char** out_new_end)
{
    char* data = m_buffer.data();
    REALM_ASSERT(*inout_new_begin >= data);
    REALM_ASSERT(*inout_new_begin <= (data + m_buffer.size()));
    size_t used_size = *inout_new_begin - data;
    m_buffer.reserve_extra(used_size, size);
    data = m_buffer.data(); // May have changed
    *inout_new_begin = data + used_size;
    *out_new_end = data + m_buffer.size();
}

inline void TransactLogBufferStream::transact_log_append(const char* data, size_t size, char** out_new_begin,
                                                         char** out_new_end)
{
    transact_log_reserve(size, out_new_begin, out_new_end);
    *out_new_begin = realm::safe_copy_n(data, size, *out_new_begin);
}

inline const char* TransactLogBufferStream::get_data() const
{
    return m_buffer.data();
}

inline char* TransactLogBufferStream::get_data()
{
    return m_buffer.data();
}

inline size_t TransactLogBufferStream::get_size()
{
    return m_buffer.size();
}

inline TransactLogEncoder::TransactLogEncoder(TransactLogStream& stream)
    : m_stream(stream)
{
}

inline void TransactLogEncoder::set_buffer(char* free_begin, char* free_end)
{
    REALM_ASSERT(free_begin <= free_end);
    m_transact_log_free_begin = free_begin;
    m_transact_log_free_end = free_end;
}

inline char* TransactLogEncoder::reserve(size_t n)
{
    if (size_t(m_transact_log_free_end - m_transact_log_free_begin) < n) {
        m_stream.transact_log_reserve(n, &m_transact_log_free_begin, &m_transact_log_free_end);
    }
    return m_transact_log_free_begin;
}

inline void TransactLogEncoder::advance(char* ptr) noexcept
{
    REALM_ASSERT_DEBUG(m_transact_log_free_begin <= ptr);
    REALM_ASSERT_DEBUG(ptr <= m_transact_log_free_end);
    m_transact_log_free_begin = ptr;
}


// The integer encoding is platform independent. Also, it does not
// depend on the type of the specified integer. Integers of any type
// can be encoded as long as the specified buffer is large enough (see
// below). The decoding does not have to use the same type. Decoding
// will fail if, and only if the encoded value falls outside the range
// of the requested destination type.
//
// The encoding uses one or more bytes. It never uses more than 8 bits
// per byte. The last byte in the sequence is the first one that has
// its 8th bit set to zero.
//
// Consider a particular non-negative value V. Let W be the number of
// bits needed to encode V using the trivial binary encoding of
// integers. The total number of bytes produced is then
// ceil((W+1)/7). The first byte holds the 7 least significant bits of
// V. The last byte holds at most 6 bits of V including the most
// significant one. The value of the first bit of the last byte is
// always 2**((N-1)*7) where N is the total number of bytes.
//
// A negative value W is encoded by setting the sign bit to one and
// then encoding the positive result of -(W+1) as described above. The
// advantage of this representation is that it converts small negative
// values to small positive values which require a small number of
// bytes. This would not have been true for 2's complements
// representation, for example. The sign bit is always stored as the
// 7th bit of the last byte.
//
//               value bits    value + sign    max bytes
//     --------------------------------------------------
//     int8_t         7              8              2
//     uint8_t        8              9              2
//     int16_t       15             16              3
//     uint16_t      16             17              3
//     int32_t       31             32              5
//     uint32_t      32             33              5
//     int64_t       63             64             10
//     uint64_t      64             65             10
//
template <class T>
char* TransactLogEncoder::encode_int(char* ptr, T value)
{
    static_assert(std::numeric_limits<T>::is_integer, "Integer required");
    bool negative = value < 0;
    if (negative) {
        // The following conversion is guaranteed by C++11 to never
        // overflow (contrast this with "-value" which indeed could
        // overflow). See C99+TC3 section 6.2.6.2 paragraph 2.
        REALM_DIAG_PUSH();
        REALM_DIAG_IGNORE_UNSIGNED_MINUS();
        value = -(value + 1);
        REALM_DIAG_POP();
    }
    // At this point 'value' is always a positive number. Also, small
    // negative numbers have been converted to small positive numbers.
    REALM_ASSERT(value >= 0);
    // One sign bit plus number of value bits
    const int num_bits = 1 + std::numeric_limits<T>::digits;
    // Only the first 7 bits are available per byte. Had it not been
    // for the fact that maximum guaranteed bit width of a char is 8,
    // this value could have been increased to 15 (one less than the
    // number of value bits in 'unsigned').
    const int bits_per_byte = 7;
    const int max_bytes = (num_bits + (bits_per_byte - 1)) / bits_per_byte;
    static_assert(max_bytes <= max_enc_bytes_per_int, "Bad max_enc_bytes_per_int");
    // An explicit constant maximum number of iterations is specified
    // in the hope that it will help the optimizer (to do loop
    // unrolling, for example).
    typedef unsigned char uchar;
    for (int i = 0; i < max_bytes; ++i) {
        if (value >> (bits_per_byte - 1) == 0)
            break;
        *reinterpret_cast<uchar*>(ptr) = uchar((1U << bits_per_byte) | unsigned(value & ((1U << bits_per_byte) - 1)));
        ++ptr;
        value >>= bits_per_byte;
    }
    *reinterpret_cast<uchar*>(ptr) = uchar(negative ? (1U << (bits_per_byte - 1)) | unsigned(value) : value);
    return ++ptr;
}

template <class T>
inline char* TransactLogEncoder::encode(char* ptr, T inst)
{
    return encode_int<T>(ptr, inst);
}

template <>
inline char* TransactLogEncoder::encode<TableKey>(char* ptr, TableKey key)
{
    return encode_int<int64_t>(ptr, key.value);
}

template <>
inline char* TransactLogEncoder::encode<ColKey>(char* ptr, ColKey key)
{
    return encode_int<int64_t>(ptr, key.value);
}

template <>
inline char* TransactLogEncoder::encode<ObjKey>(char* ptr, ObjKey key)
{
    return encode_int<int64_t>(ptr, key.value);
}

template <>
inline char* TransactLogEncoder::encode<Instruction>(char* ptr, Instruction inst)
{
    return encode_int<int64_t>(ptr, inst);
}

template <class T>
size_t TransactLogEncoder::max_size(T)
{
    return max_enc_bytes_per_int;
}

template <>
inline size_t TransactLogEncoder::max_size(Instruction)
{
    return 1;
}

template <class... L>
void TransactLogEncoder::append_simple_instr(L... numbers)
{
    size_t max_required_bytes = max_size_list(numbers...);
    char* ptr = reserve(max_required_bytes); // Throws
    encode_list(ptr, numbers...);
}

template <typename... L>
void TransactLogEncoder::append_string_instr(Instruction instr, StringData string)
{
    size_t max_required_bytes = 1 + max_enc_bytes_per_int + string.size();
    char* ptr = reserve(max_required_bytes); // Throws
    *ptr++ = char(instr);
    ptr = encode(ptr, int(type_String));
    ptr = encode(ptr, size_t(string.size()));
    ptr = std::copy(string.data(), string.data() + string.size(), ptr);
    advance(ptr);
}

inline bool TransactLogEncoder::insert_group_level_table(TableKey table_key)
{
    append_simple_instr(instr_InsertGroupLevelTable, table_key); // Throws
    return true;
}

inline bool TransactLogEncoder::erase_class(TableKey table_key)
{
    append_simple_instr(instr_EraseGroupLevelTable, table_key); // Throws
    return true;
}

inline bool TransactLogEncoder::rename_class(TableKey table_key)
{
    append_simple_instr(instr_RenameGroupLevelTable, table_key); // Throws
    return true;
}

inline bool TransactLogEncoder::insert_column(ColKey col_key)
{
    append_simple_instr(instr_InsertColumn, col_key); // Throws
    return true;
}

inline bool TransactLogEncoder::erase_column(ColKey col_key)
{
    append_simple_instr(instr_EraseColumn, col_key); // Throws
    return true;
}

inline bool TransactLogEncoder::rename_column(ColKey col_key)
{
    append_simple_instr(instr_RenameColumn, col_key); // Throws
    return true;
}

inline bool TransactLogEncoder::modify_object(ColKey col_key, ObjKey key)
{
    append_simple_instr(instr_Set, col_key, key); // Throws
    return true;
}


/************************************ Collections ***********************************/

inline bool TransactLogEncoder::collection_set(size_t ndx)
{
    append_simple_instr(instr_CollectionSet, ndx); // Throws
    return true;
}

inline bool TransactLogEncoder::collection_insert(size_t ndx)
{
    append_simple_instr(instr_CollectionInsert, ndx); // Throws
    return true;
}


inline bool TransactLogEncoder::collection_move(size_t from_ndx, size_t to_ndx)
{
    // This test is to prevent some fuzzy testing on the server to crash
    if (from_ndx != to_ndx) {
        append_simple_instr(instr_CollectionMove, from_ndx, to_ndx); // Throws
    }
    return true;
}

inline bool TransactLogEncoder::collection_erase(size_t ndx)
{
    append_simple_instr(instr_CollectionErase, ndx); // Throws
    return true;
}


inline bool TransactLogEncoder::collection_clear(size_t old_size)
{
    append_simple_instr(instr_CollectionClear, old_size); // Throws
    return true;
}

inline bool TransactLogEncoder::typed_link_change(ColKey col, TableKey dest)
{
    append_simple_instr(instr_TypedLinkChange, col, dest);
    return true;
}


template <class InstructionHandler>
void TransactLogParser::parse(util::InputStream& in, InstructionHandler& handler)
{
    m_input = &in;
    m_input_begin = m_input_end = nullptr;

    while (has_next())
        parse_one(handler); // Throws
}

inline bool TransactLogParser::has_next() noexcept
{
    return m_input_begin != m_input_end || next_input_buffer();
}

template <class InstructionHandler>
void TransactLogParser::parse_one(InstructionHandler& handler)
{
    char instr_ch = 0; // silence a warning
    if (!read_char(instr_ch))
        parser_error(); // Throws
    Instruction instr = Instruction(instr_ch);
    switch (instr) {
        case instr_Set: {
            ColKey col_key = ColKey(read_int<int64_t>()); // Throws
            ObjKey key(read_int<int64_t>());              // Throws
            if (!handler.modify_object(col_key, key))     // Throws
                parser_error();
            return;
        }
        case instr_SetDefault:
            // Should not appear in the transaction log
            parser_error();
        case instr_CreateObject: {
            ObjKey key(read_int<int64_t>()); // Throws
            if (!handler.create_object(key)) // Throws
                parser_error();
            return;
        }
        case instr_RemoveObject: {
            ObjKey key(read_int<int64_t>()); // Throws
            if (!handler.remove_object(key)) // Throws
                parser_error();
            return;
        }
        case instr_SelectTable: {
            int levels = read_int<int>(); // Throws
            REALM_ASSERT(levels == 0);
            TableKey key = TableKey(read_int<uint32_t>());
            if (!handler.select_table(key)) // Throws
                parser_error();
            return;
        }
        case instr_CollectionSet: {
            size_t ndx = read_int<size_t>();
            if (!handler.collection_set(ndx)) // Throws
                parser_error();
            return;
        }
        case instr_SetInsert:
        case instr_CollectionInsert: {
            size_t ndx = read_int<size_t>();
            if (!handler.collection_insert(ndx)) // Throws
                parser_error();
            return;
        }
        case instr_CollectionMove: {
            size_t from_ndx = read_int<size_t>();           // Throws
            size_t to_ndx = read_int<size_t>();             // Throws
            if (!handler.collection_move(from_ndx, to_ndx)) // Throws
                parser_error();
            return;
        }
        case instr_SetErase:
        case instr_CollectionErase: {
            size_t ndx = read_int<size_t>();    // Throws
            if (!handler.collection_erase(ndx)) // Throws
                parser_error();
            return;
        }
        case instr_SetClear:
        case instr_CollectionClear: {
            size_t old_size = read_int<size_t>();    // Throws
            if (!handler.collection_clear(old_size)) // Throws
                parser_error();
            return;
        }
        case instr_DictionaryInsert: {
            int type = read_int<int>(); // Throws
            REALM_ASSERT(type == int(type_String));
            read_string(m_string_buffer);             // skip key
            size_t dict_ndx = read_int<size_t>();     // Throws
            if (!handler.collection_insert(dict_ndx)) // Throws
                parser_error();
            return;
        }
        case instr_DictionarySet: {
            int type = read_int<int>(); // Throws
            REALM_ASSERT(type == int(type_String));
            read_string(m_string_buffer);               // skip key
            size_t dict_ndx = read_int<size_t>();       // Throws
            if (!handler.collection_set(dict_ndx))      // Throws
                parser_error();
            return;
        }
        case instr_DictionaryErase: {
            int type = read_int<int>(); // Throws
            REALM_ASSERT(type == int(type_String));
            read_string(m_string_buffer);                 // skip key
            size_t dict_ndx = read_int<size_t>();         // Throws
            if (!handler.collection_erase(dict_ndx))      // Throws
                parser_error();
            return;
        }
        case instr_SelectCollection: {
            ColKey col_key = ColKey(read_int<int64_t>()); // Throws
            ObjKey key = ObjKey(read_int<int64_t>());     // Throws
            if (!handler.select_collection(col_key, key)) // Throws
                parser_error();
            return;
        }
        case instr_InsertColumn: {
            ColKey col_key = ColKey(read_int<int64_t>()); // Throws
            if (!handler.insert_column(col_key))          // Throws
                parser_error();
            return;
        }
        case instr_EraseColumn: {
            ColKey col_key = ColKey(read_int<int64_t>()); // Throws
            if (!handler.erase_column(col_key))           // Throws
                parser_error();
            return;
        }
        case instr_RenameColumn: {
            ColKey col_key = ColKey(read_int<int64_t>()); // Throws
            if (!handler.rename_column(col_key))          // Throws
                parser_error();
            return;
        }
        case instr_InsertGroupLevelTable: {
            TableKey table_key = TableKey(read_int<uint32_t>()); // Throws
            if (!handler.insert_group_level_table(table_key))    // Throws
                parser_error();
            return;
        }
        case instr_EraseGroupLevelTable: {
            TableKey table_key = TableKey(read_int<uint32_t>()); // Throws
            if (!handler.erase_class(table_key))                 // Throws
                parser_error();
            return;
        }
        case instr_RenameGroupLevelTable: {
            TableKey table_key = TableKey(read_int<uint32_t>()); // Throws
            if (!handler.rename_class(table_key))                // Throws
                parser_error();
            return;
        }
        case instr_TypedLinkChange: {
            ColKey col_key = ColKey(read_int<int64_t>());         // Throws
            TableKey dest_table = TableKey(read_int<uint32_t>()); // Throws
            if (!handler.typed_link_change(col_key, dest_table))
                parser_error();
            return;
        }
    }

    parser_error();
}


template <class T>
T TransactLogParser::read_int()
{
    T value = 0;
    int part = 0;
    const int max_bytes = (std::numeric_limits<T>::digits + 1 + 6) / 7;
    for (int i = 0; i != max_bytes; ++i) {
        char c;
        if (!read_char(c))
            parser_error(); // Input ended early
        part = static_cast<unsigned char>(c);
        if (0xFF < part)
            parser_error(); // Only the first 8 bits may be used in each byte
        if ((part & 0x80) == 0) {
            T p = part & 0x3F;
            if (util::int_shift_left_with_overflow_detect(p, i * 7))
                parser_error();
            value |= p;
            break;
        }
        if (i == max_bytes - 1)
            parser_error(); // Too many bytes
        value |= T(part & 0x7F) << (i * 7);
    }
    if (part & 0x40) {
        // The real value is negative. Because 'value' is positive at
        // this point, the following negation is guaranteed by C++11
        // to never overflow. See C99+TC3 section 6.2.6.2 paragraph 2.
        REALM_DIAG_PUSH();
        REALM_DIAG_IGNORE_UNSIGNED_MINUS();
        value = -value;
        REALM_DIAG_POP();
        if (util::int_subtract_with_overflow_detect(value, 1))
            parser_error();
    }
    return value;
}

inline void TransactLogParser::read_bytes(char* data, size_t size)
{
    for (;;) {
        const size_t avail = m_input_end - m_input_begin;
        if (size <= avail)
            break;
        const char* to = m_input_begin + avail;
        std::copy(m_input_begin, to, data);
        if (!next_input_buffer())
            parser_error();
        data += avail;
        size -= avail;
    }
    const char* to = m_input_begin + size;
    std::copy(m_input_begin, to, data);
    m_input_begin = to;
}

inline BinaryData TransactLogParser::read_buffer(std::string& buf, size_t size)
{
    const size_t avail = m_input_end - m_input_begin;
    if (avail >= size) {
        m_input_begin += size;
        return BinaryData(m_input_begin - size, size);
    }

    buf.clear();
    buf.resize(size); // Throws
    read_bytes(buf.data(), size);
    return BinaryData(buf.data(), size);
}

inline StringData TransactLogParser::read_string(std::string& buf)
{
    size_t size = read_int<size_t>(); // Throws

    if (size > Table::max_string_size)
        parser_error();

    BinaryData buffer = read_buffer(buf, size);
    return StringData{buffer.data(), size};
}

inline bool TransactLogParser::next_input_buffer()
{
    auto buffer = m_input->next_block();
    m_input_begin = buffer.begin();
    m_input_end = buffer.end();
    return m_input_begin != m_input_end;
}


inline bool TransactLogParser::read_char(char& c)
{
    if (m_input_begin == m_input_end && !next_input_buffer())
        return false;
    c = *m_input_begin++;
    return true;
}

template <typename Handler>
void parse_transact_log(util::InputStream& is, Handler& handler)
{
    TransactLogParser parser;
    parser.parse(is, handler);
    handler.parse_complete();
}

} // namespace _impl
} // namespace realm

#endif // REALM_IMPL_TRANSACT_LOG_HPP
