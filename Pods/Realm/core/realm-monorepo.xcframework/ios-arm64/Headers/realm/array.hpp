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

#ifndef REALM_ARRAY_HPP
#define REALM_ARRAY_HPP

#include <realm/node.hpp>
#include <realm/query_state.hpp>
#include <realm/column_fwd.hpp>
#include <realm/array_direct.hpp>

namespace realm {

// Pre-definitions
class GroupWriter;
namespace _impl {
class ArrayWriterBase;
}

struct MemStats {
    size_t allocated = 0;
    size_t used = 0;
    size_t array_count = 0;
};

// Stores a value obtained from Array::get(). It is a ref if the least
// significant bit is clear, otherwise it is a tagged integer. A tagged interger
// is obtained from a logical integer value by left shifting by one bit position
// (multiplying by two), and then setting the least significant bit to
// one. Clearly, this means that the maximum value that can be stored as a
// tagged integer is 2**63 - 1.
class RefOrTagged {
public:
    bool is_ref() const noexcept;
    bool is_tagged() const noexcept;
    ref_type get_as_ref() const noexcept;
    uint_fast64_t get_as_int() const noexcept;

    static RefOrTagged make_ref(ref_type) noexcept;
    static RefOrTagged make_tagged(uint_fast64_t) noexcept;

private:
    int_fast64_t m_value;
    RefOrTagged(int_fast64_t) noexcept;
    friend class Array;
};


template <class T>
class QueryStateFindAll : public QueryStateBase {
public:
    explicit QueryStateFindAll(T& keys, size_t limit = -1)
        : QueryStateBase(limit)
        , m_keys(keys)
    {
    }
    bool match(size_t index, Mixed) noexcept final;

private:
    T& m_keys;
};

class QueryStateFindFirst : public QueryStateBase {
public:
    size_t m_state = realm::not_found;
    QueryStateFindFirst()
        : QueryStateBase(1)
    {
    }
    bool match(size_t index, Mixed) noexcept final;
};

class Array : public Node, public ArrayParent {
public:
    /// Create an array accessor in the unattached state.
    explicit Array(Allocator& allocator) noexcept
        : Node(allocator)
    {
    }

    ~Array() noexcept override {}

    /// Create a new integer array of the specified type and size, and filled
    /// with the specified value, and attach this accessor to it. This does not
    /// modify the parent reference information of this accessor.
    ///
    /// Note that the caller assumes ownership of the allocated underlying
    /// node. It is not owned by the accessor.
    void create(Type, bool context_flag = false, size_t size = 0, int_fast64_t value = 0);

    /// Reinitialize this array accessor to point to the specified new
    /// underlying memory. This does not modify the parent reference information
    /// of this accessor.
    void init_from_ref(ref_type ref) noexcept
    {
        REALM_ASSERT_DEBUG(ref);
        char* header = m_alloc.translate(ref);
        init_from_mem(MemRef(header, ref, m_alloc));
    }

    /// Same as init_from_ref(ref_type) but avoid the mapping of 'ref' to memory
    /// pointer.
    void init_from_mem(MemRef) noexcept;

    /// Same as `init_from_ref(get_ref_from_parent())`.
    void init_from_parent() noexcept
    {
        ref_type ref = get_ref_from_parent();
        init_from_ref(ref);
    }

    /// Called in the context of Group::commit() to ensure that attached
    /// accessors stay valid across a commit. Please note that this works only
    /// for non-transactional commits. Accessors obtained during a transaction
    /// are always detached when the transaction ends.
    void update_from_parent() noexcept;

    /// Change the type of an already attached array node.
    ///
    /// The effect of calling this function on an unattached accessor is
    /// undefined.
    void set_type(Type);

    /// Construct an empty integer array of the specified type, and return just
    /// the reference to the underlying memory.
    static MemRef create_empty_array(Type, bool context_flag, Allocator&);

    /// Construct an integer array of the specified type and size, and return
    /// just the reference to the underlying memory. All elements will be
    /// initialized to the specified value.
    static MemRef create_array(Type, bool context_flag, size_t size, int_fast64_t value, Allocator&);

    Type get_type() const noexcept;

    /// The meaning of 'width' depends on the context in which this
    /// array is used.
    size_t get_width() const noexcept
    {
        REALM_ASSERT_3(m_width, ==, get_width_from_header(get_header()));
        return m_width;
    }

    void insert(size_t ndx, int_fast64_t value);
    void add(int_fast64_t value);

    // Used from ArrayBlob
    size_t blob_size() const noexcept;
    ref_type blob_replace(size_t begin, size_t end, const char* data, size_t data_size, bool add_zero_term);

    /// This function is guaranteed to not throw if the current width is
    /// sufficient for the specified value (e.g. if you have called
    /// ensure_minimum_width(value)) and get_alloc().is_read_only(get_ref())
    /// returns false (noexcept:array-set). Note that for a value of zero, the
    /// first criterion is trivially satisfied.
    void set(size_t ndx, int64_t value);

    void set_as_ref(size_t ndx, ref_type ref);

    template <size_t w>
    void set(size_t ndx, int64_t value);

    int64_t get(size_t ndx) const noexcept;

    template <size_t w>
    int64_t get(size_t ndx) const noexcept;

    void get_chunk(size_t ndx, int64_t res[8]) const noexcept;

    template <size_t w>
    void get_chunk(size_t ndx, int64_t res[8]) const noexcept;

    ref_type get_as_ref(size_t ndx) const noexcept;

    RefOrTagged get_as_ref_or_tagged(size_t ndx) const noexcept;
    void set(size_t ndx, RefOrTagged);
    void add(RefOrTagged);
    void ensure_minimum_width(RefOrTagged);

    int64_t front() const noexcept;
    int64_t back() const noexcept;

    void alloc(size_t init_size, size_t new_width)
    {
        REALM_ASSERT_3(m_width, ==, get_width_from_header(get_header()));
        REALM_ASSERT_3(m_size, ==, get_size_from_header(get_header()));
        Node::alloc(init_size, new_width);
        update_width_cache_from_header();
    }

    /// Remove the element at the specified index, and move elements at higher
    /// indexes to the next lower index.
    ///
    /// This function does **not** destroy removed subarrays. That is, if the
    /// erased element is a 'ref' pointing to a subarray, then that subarray
    /// will not be destroyed automatically.
    ///
    /// This function guarantees that no exceptions will be thrown if
    /// get_alloc().is_read_only(get_ref()) would return false before the
    /// call. This is automatically guaranteed if the array is used in a
    /// non-transactional context, or if the array has already been successfully
    /// modified within the current write transaction.
    void erase(size_t ndx);

    /// Same as erase(size_t), but remove all elements in the specified
    /// range.
    ///
    /// Please note that this function does **not** destroy removed subarrays.
    ///
    /// This function guarantees that no exceptions will be thrown if
    /// get_alloc().is_read_only(get_ref()) would return false before the call.
    void erase(size_t begin, size_t end);

    /// Reduce the size of this array to the specified number of elements. It is
    /// an error to specify a size that is greater than the current size of this
    /// array. The effect of doing so is undefined. This is just a shorthand for
    /// calling the ranged erase() function with appropriate arguments.
    ///
    /// Please note that this function does **not** destroy removed
    /// subarrays. See clear_and_destroy_children() for an alternative.
    ///
    /// This function guarantees that no exceptions will be thrown if
    /// get_alloc().is_read_only(get_ref()) would return false before the call.
    void truncate(size_t new_size);

    /// Reduce the size of this array to the specified number of elements. It is
    /// an error to specify a size that is greater than the current size of this
    /// array. The effect of doing so is undefined. Subarrays will be destroyed
    /// recursively, as if by a call to `destroy_deep(subarray_ref, alloc)`.
    ///
    /// This function is guaranteed not to throw if
    /// get_alloc().is_read_only(get_ref()) returns false.
    void truncate_and_destroy_children(size_t new_size);

    /// Remove every element from this array. This is just a shorthand for
    /// calling truncate(0).
    ///
    /// Please note that this function does **not** destroy removed
    /// subarrays. See clear_and_destroy_children() for an alternative.
    ///
    /// This function guarantees that no exceptions will be thrown if
    /// get_alloc().is_read_only(get_ref()) would return false before the call.
    void clear();

    /// Remove every element in this array. Subarrays will be destroyed
    /// recursively, as if by a call to `destroy_deep(subarray_ref,
    /// alloc)`. This is just a shorthand for calling
    /// truncate_and_destroy_children(0).
    ///
    /// This function guarantees that no exceptions will be thrown if
    /// get_alloc().is_read_only(get_ref()) would return false before the call.
    void clear_and_destroy_children();

    /// If neccessary, expand the representation so that it can store the
    /// specified value.
    void ensure_minimum_width(int_fast64_t value);

    /// Add \a diff to the element at the specified index.
    void adjust(size_t ndx, int_fast64_t diff);

    /// Add \a diff to all the elements in the specified index range.
    void adjust(size_t begin, size_t end, int_fast64_t diff);

    //@{
    /// This is similar in spirit to std::move() from `<algorithm>`.
    /// \a dest_begin must not be in the range [`begin`,`end`)
    ///
    /// This function is guaranteed to not throw if
    /// `get_alloc().is_read_only(get_ref())` returns false.
    void move(size_t begin, size_t end, size_t dest_begin);
    //@}

    // Move elements from ndx and above to another array
    void move(Array& dst, size_t ndx);

    //@{
    /// Find the lower/upper bound of the specified value in a sequence of
    /// integers which must already be sorted ascendingly.
    ///
    /// For an integer value '`v`', lower_bound_int(v) returns the index '`l`'
    /// of the first element such that `get(l) &ge; v`, and upper_bound_int(v)
    /// returns the index '`u`' of the first element such that `get(u) &gt;
    /// v`. In both cases, if no such element is found, the returned value is
    /// the number of elements in the array.
    ///
    ///     3 3 3 4 4 4 5 6 7 9 9 9
    ///     ^     ^     ^     ^     ^
    ///     |     |     |     |     |
    ///     |     |     |     |      -- Lower and upper bound of 15
    ///     |     |     |     |
    ///     |     |     |      -- Lower and upper bound of 8
    ///     |     |     |
    ///     |     |      -- Upper bound of 4
    ///     |     |
    ///     |      -- Lower bound of 4
    ///     |
    ///      -- Lower and upper bound of 1
    ///
    /// These functions are similar to std::lower_bound() and
    /// std::upper_bound().
    ///
    /// We currently use binary search. See for example
    /// http://www.tbray.org/ongoing/When/200x/2003/03/22/Binary.
    ///
    /// FIXME: It may be worth considering if overall efficiency can be improved
    /// by doing a linear search for short sequences.
    size_t lower_bound_int(int64_t value) const noexcept;
    size_t upper_bound_int(int64_t value) const noexcept;
    //@}

    int64_t get_sum(size_t start = 0, size_t end = size_t(-1)) const
    {
        return sum(start, end);
    }

    /// This information is guaranteed to be cached in the array accessor.
    bool is_inner_bptree_node() const noexcept;

    /// Returns true if type is either type_HasRefs or type_InnerColumnNode.
    ///
    /// This information is guaranteed to be cached in the array accessor.
    bool has_refs() const noexcept;
    void set_has_refs(bool) noexcept;

    /// This information is guaranteed to be cached in the array accessor.
    ///
    /// Columns and indexes can use the context bit to differentiate leaf types.
    bool get_context_flag() const noexcept;
    void set_context_flag(bool) noexcept;

    /// Recursively destroy children (as if calling
    /// clear_and_destroy_children()), then put this accessor into the detached
    /// state (as if calling detach()), then free the allocated memory. If this
    /// accessor is already in the detached state, this function has no effect
    /// (idempotency).
    void destroy_deep() noexcept;

    /// Shorthand for `destroy_deep(MemRef(ref, alloc), alloc)`.
    static void destroy_deep(ref_type ref, Allocator& alloc) noexcept;

    /// Destroy the specified array node and all of its children, recursively.
    ///
    /// This is done by freeing the specified array node after calling
    /// destroy_deep() for every contained 'ref' element.
    static void destroy_deep(MemRef, Allocator&) noexcept;

    // Clone deep
    static MemRef clone(MemRef, Allocator& from_alloc, Allocator& target_alloc);

    // Serialization

    /// Returns the ref (position in the target stream) of the written copy of
    /// this array, or the ref of the original array if \a only_if_modified is
    /// true, and this array is unmodified (Alloc::is_read_only()).
    ///
    /// The number of bytes that will be written by a non-recursive invocation
    /// of this function is exactly the number returned by get_byte_size().
    ///
    /// \param out The destination stream (writer).
    ///
    /// \param deep If true, recursively write out subarrays, but still subject
    /// to \a only_if_modified.
    ///
    /// \param only_if_modified Set to `false` to always write, or to `true` to
    /// only write the array if it has been modified.
    ref_type write(_impl::ArrayWriterBase& out, bool deep, bool only_if_modified) const;

    /// Same as non-static write() with `deep` set to true. This is for the
    /// cases where you do not already have an array accessor available.
    static ref_type write(ref_type, Allocator&, _impl::ArrayWriterBase&, bool only_if_modified);

    size_t find_first(int64_t value, size_t begin = 0, size_t end = size_t(-1)) const;

    // Wrappers for backwards compatibility and for simple use without
    // setting up state initialization etc
    template <class cond>
    size_t find_first(int64_t value, size_t start = 0, size_t end = size_t(-1)) const
    {
        REALM_ASSERT(start <= m_size && (end <= m_size || end == size_t(-1)) && start <= end);
        // todo, would be nice to avoid this in order to speed up find_first loops
        QueryStateFindFirst state;
        Finder finder = m_vtable->finder[cond::condition];
        (this->*finder)(value, start, end, 0, &state);

        return static_cast<size_t>(state.m_state);
    }

    /// Get the specified element without the cost of constructing an
    /// array instance. If an array instance is already available, or
    /// you need to get multiple values, then this method will be
    /// slower.
    static int_fast64_t get(const char* header, size_t ndx) noexcept;

    /// Like get(const char*, size_t) but gets two consecutive
    /// elements.
    static std::pair<int64_t, int64_t> get_two(const char* header, size_t ndx) noexcept;

    static RefOrTagged get_as_ref_or_tagged(const char* header, size_t ndx) noexcept
    {
        return get(header, ndx);
    }

    /// Get the number of bytes currently in use by this array. This
    /// includes the array header, but it does not include allocated
    /// bytes corresponding to excess capacity. The result is
    /// guaranteed to be a multiple of 8 (i.e., 64-bit aligned).
    ///
    /// This number is exactly the number of bytes that will be
    /// written by a non-recursive invocation of write().
    size_t get_byte_size() const noexcept;

    /// Get the maximum number of bytes that can be written by a
    /// non-recursive invocation of write() on an array with the
    /// specified number of elements, that is, the maximum value that
    /// can be returned by get_byte_size().
    static size_t get_max_byte_size(size_t num_elems) noexcept;

    /// FIXME: Belongs in IntegerArray
    static size_t calc_aligned_byte_size(size_t size, int width);

#ifdef REALM_DEBUG
    class MemUsageHandler {
    public:
        virtual void handle(ref_type ref, size_t allocated, size_t used) = 0;
    };

    void report_memory_usage(MemUsageHandler&) const;

    void stats(MemStats& stats_dest) const noexcept;
#endif

    void verify() const;

    Array& operator=(const Array&) = delete; // not allowed
    Array(const Array&) = delete;            // not allowed

protected:
    // This returns the minimum value ("lower bound") of the representable values
    // for the given bit width. Valid widths are 0, 1, 2, 4, 8, 16, 32, and 64.
    static constexpr int_fast64_t lbound_for_width(size_t width) noexcept;

    // This returns the maximum value ("inclusive upper bound") of the representable values
    // for the given bit width. Valid widths are 0, 1, 2, 4, 8, 16, 32, and 64.
    static constexpr int_fast64_t ubound_for_width(size_t width) noexcept;

    // This will have to be eventually used, exposing this here for testing.
    size_t count(int64_t value) const noexcept;

private:
    void update_width_cache_from_header() noexcept;

    void do_ensure_minimum_width(int_fast64_t);

    int64_t sum(size_t start, size_t end) const;

    template <size_t w>
    int64_t sum(size_t start, size_t end) const;

protected:
    /// It is an error to specify a non-zero value unless the width
    /// type is wtype_Bits. It is also an error to specify a non-zero
    /// size if the width type is wtype_Ignore.
    static MemRef create(Type, bool context_flag, WidthType, size_t size, int_fast64_t value, Allocator&);

    // Overriding method in ArrayParent
    void update_child_ref(size_t, ref_type) override;

    // Overriding method in ArrayParent
    ref_type get_child_ref(size_t) const noexcept override;

    void destroy_children(size_t offset = 0) noexcept;

protected:
    // Getters and Setters for adaptive-packed arrays
    typedef int64_t (Array::*Getter)(size_t) const; // Note: getters must not throw
    typedef void (Array::*Setter)(size_t, int64_t);
    typedef bool (Array::*Finder)(int64_t, size_t, size_t, size_t, QueryStateBase*) const;
    typedef void (Array::*ChunkGetter)(size_t, int64_t res[8]) const; // Note: getters must not throw

    struct VTable {
        Getter getter;
        ChunkGetter chunk_getter;
        Setter setter;
        Finder finder[cond_VTABLE_FINDER_COUNT]; // one for each active function pointer
    };
    template <size_t w>
    struct VTableForWidth;

    // This is the one installed into the m_vtable->finder slots.
    template <class cond, size_t bitwidth>
    bool find_vtable(int64_t value, size_t start, size_t end, size_t baseindex, QueryStateBase* state) const;

    template <size_t w>
    int64_t get_universal(const char* const data, const size_t ndx) const;

protected:
    /// Takes a 64-bit value and returns the minimum number of bits needed
    /// to fit the value. For alignment this is rounded up to nearest
    /// log2. Posssible results {0, 1, 2, 4, 8, 16, 32, 64}
    static size_t bit_width(int64_t value);

protected:
    Getter m_getter = nullptr; // cached to avoid indirection
    const VTable* m_vtable = nullptr;

    uint_least8_t m_width = 0; // Size of an element (meaning depend on type of array).
    int64_t m_lbound;          // min number that can be stored with current m_width
    int64_t m_ubound;          // max number that can be stored with current m_width

    bool m_is_inner_bptree_node; // This array is an inner node of B+-tree.
    bool m_has_refs;             // Elements whose first bit is zero are refs to subarrays.
    bool m_context_flag;         // Meaning depends on context.

private:
    ref_type do_write_shallow(_impl::ArrayWriterBase&) const;
    ref_type do_write_deep(_impl::ArrayWriterBase&, bool only_if_modified) const;

#ifdef REALM_DEBUG
    void report_memory_usage_2(MemUsageHandler&) const;
#endif

    friend class Allocator;
    friend class SlabAlloc;
    friend class GroupWriter;
    friend class ArrayWithFind;
};

// Implementation:


constexpr inline int_fast64_t Array::lbound_for_width(size_t width) noexcept
{
    if (width == 32) {
        return -0x80000000LL;
    }
    else if (width == 16) {
        return -0x8000LL;
    }
    else if (width < 8) {
        return 0;
    }
    else if (width == 8) {
        return -0x80LL;
    }
    else if (width == 64) {
        return -0x8000000000000000LL;
    }
    else {
        REALM_UNREACHABLE();
    }
}

constexpr inline int_fast64_t Array::ubound_for_width(size_t width) noexcept
{
    if (width == 32) {
        return 0x7FFFFFFFLL;
    }
    else if (width == 16) {
        return 0x7FFFLL;
    }
    else if (width == 0) {
        return 0;
    }
    else if (width == 1) {
        return 1;
    }
    else if (width == 2) {
        return 3;
    }
    else if (width == 4) {
        return 15;
    }
    else if (width == 8) {
        return 0x7FLL;
    }
    else if (width == 64) {
        return 0x7FFFFFFFFFFFFFFFLL;
    }
    else {
        REALM_UNREACHABLE();
    }
}

inline bool RefOrTagged::is_ref() const noexcept
{
    return (m_value & 1) == 0;
}

inline bool RefOrTagged::is_tagged() const noexcept
{
    return !is_ref();
}

inline ref_type RefOrTagged::get_as_ref() const noexcept
{
    // to_ref() is defined in <alloc.hpp>
    return to_ref(m_value);
}

inline uint_fast64_t RefOrTagged::get_as_int() const noexcept
{
    // The bitwise AND is there in case uint_fast64_t is wider than 64 bits.
    return (uint_fast64_t(m_value) & 0xFFFFFFFFFFFFFFFFULL) >> 1;
}

inline RefOrTagged RefOrTagged::make_ref(ref_type ref) noexcept
{
    // from_ref() is defined in <alloc.hpp>
    int_fast64_t value = from_ref(ref);
    return RefOrTagged(value);
}

inline RefOrTagged RefOrTagged::make_tagged(uint_fast64_t i) noexcept
{
    REALM_ASSERT(i < (1ULL << 63));
    return RefOrTagged((i << 1) | 1);
}

inline RefOrTagged::RefOrTagged(int_fast64_t value) noexcept
    : m_value(value)
{
}

inline void Array::create(Type type, bool context_flag, size_t length, int_fast64_t value)
{
    MemRef mem = create_array(type, context_flag, length, value, m_alloc); // Throws
    init_from_mem(mem);
}


inline Array::Type Array::get_type() const noexcept
{
    if (m_is_inner_bptree_node) {
        REALM_ASSERT_DEBUG(m_has_refs);
        return type_InnerBptreeNode;
    }
    if (m_has_refs)
        return type_HasRefs;
    return type_Normal;
}


inline void Array::get_chunk(size_t ndx, int64_t res[8]) const noexcept
{
    REALM_ASSERT_DEBUG(ndx < m_size);
    (this->*(m_vtable->chunk_getter))(ndx, res);
}

template <size_t w>
int64_t Array::get_universal(const char* data, size_t ndx) const
{
    if (w == 0) {
        return 0;
    }
    else if (w == 1) {
        size_t offset = ndx >> 3;
        return (data[offset] >> (ndx & 7)) & 0x01;
    }
    else if (w == 2) {
        size_t offset = ndx >> 2;
        return (data[offset] >> ((ndx & 3) << 1)) & 0x03;
    }
    else if (w == 4) {
        size_t offset = ndx >> 1;
        return (data[offset] >> ((ndx & 1) << 2)) & 0x0F;
    }
    else if (w == 8) {
        return *reinterpret_cast<const signed char*>(data + ndx);
    }
    else if (w == 16) {
        size_t offset = ndx * 2;
        return *reinterpret_cast<const int16_t*>(data + offset);
    }
    else if (w == 32) {
        size_t offset = ndx * 4;
        return *reinterpret_cast<const int32_t*>(data + offset);
    }
    else if (w == 64) {
        size_t offset = ndx * 8;
        return *reinterpret_cast<const int64_t*>(data + offset);
    }
    else {
        REALM_ASSERT_DEBUG(false);
        return int64_t(-1);
    }
}

template <size_t w>
int64_t Array::get(size_t ndx) const noexcept
{
    return get_universal<w>(m_data, ndx);
}

inline int64_t Array::get(size_t ndx) const noexcept
{
    REALM_ASSERT_DEBUG(is_attached());
    REALM_ASSERT_DEBUG_EX(ndx < m_size, ndx, m_size);
    return (this->*m_getter)(ndx);

    // Two ideas that are not efficient but may be worth looking into again:
    /*
        // Assume correct width is found early in REALM_TEMPEX, which is the case for B tree offsets that
        // are probably either 2^16 long. Turns out to be 25% faster if found immediately, but 50-300% slower
        // if found later
        REALM_TEMPEX(return get, (ndx));
    */
    /*
        // Slightly slower in both of the if-cases. Also needs an matchcount m_size check too, to avoid
        // reading beyond array.
        if (m_width >= 8 && m_size > ndx + 7)
            return get<64>(ndx >> m_shift) & m_widthmask;
        else
            return (this->*(m_vtable->getter))(ndx);
    */
}

inline int64_t Array::front() const noexcept
{
    return get(0);
}

inline int64_t Array::back() const noexcept
{
    return get(m_size - 1);
}

inline ref_type Array::get_as_ref(size_t ndx) const noexcept
{
    REALM_ASSERT_DEBUG(is_attached());
    REALM_ASSERT_DEBUG_EX(m_has_refs, m_ref, ndx, m_size);
    int64_t v = get(ndx);
    return to_ref(v);
}

inline RefOrTagged Array::get_as_ref_or_tagged(size_t ndx) const noexcept
{
    REALM_ASSERT(has_refs());
    return RefOrTagged(get(ndx));
}

inline void Array::set(size_t ndx, RefOrTagged ref_or_tagged)
{
    REALM_ASSERT(has_refs());
    set(ndx, ref_or_tagged.m_value); // Throws
}

inline void Array::add(RefOrTagged ref_or_tagged)
{
    REALM_ASSERT(has_refs());
    add(ref_or_tagged.m_value); // Throws
}

inline void Array::ensure_minimum_width(RefOrTagged ref_or_tagged)
{
    REALM_ASSERT(has_refs());
    ensure_minimum_width(ref_or_tagged.m_value); // Throws
}

inline bool Array::is_inner_bptree_node() const noexcept
{
    return m_is_inner_bptree_node;
}

inline bool Array::has_refs() const noexcept
{
    return m_has_refs;
}

inline void Array::set_has_refs(bool value) noexcept
{
    if (m_has_refs != value) {
        REALM_ASSERT(!is_read_only());
        m_has_refs = value;
        set_hasrefs_in_header(value, get_header());
    }
}

inline bool Array::get_context_flag() const noexcept
{
    return m_context_flag;
}

inline void Array::set_context_flag(bool value) noexcept
{
    if (m_context_flag != value) {
        copy_on_write();
        m_context_flag = value;
        set_context_flag_in_header(value, get_header());
    }
}

inline void Array::destroy_deep() noexcept
{
    if (!is_attached())
        return;

    if (m_has_refs)
        destroy_children();

    char* header = get_header_from_data(m_data);
    m_alloc.free_(m_ref, header);
    m_data = nullptr;
}

inline ref_type Array::write(_impl::ArrayWriterBase& out, bool deep, bool only_if_modified) const
{
    REALM_ASSERT(is_attached());

    if (only_if_modified && m_alloc.is_read_only(m_ref))
        return m_ref;

    if (!deep || !m_has_refs)
        return do_write_shallow(out); // Throws

    return do_write_deep(out, only_if_modified); // Throws
}

inline ref_type Array::write(ref_type ref, Allocator& alloc, _impl::ArrayWriterBase& out, bool only_if_modified)
{
    if (only_if_modified && alloc.is_read_only(ref))
        return ref;

    Array array(alloc);
    array.init_from_ref(ref);

    if (!array.m_has_refs)
        return array.do_write_shallow(out); // Throws

    return array.do_write_deep(out, only_if_modified); // Throws
}

inline void Array::add(int_fast64_t value)
{
    insert(m_size, value);
}

inline void Array::erase(size_t ndx)
{
    // This can throw, but only if array is currently in read-only
    // memory.
    move(ndx + 1, size(), ndx);

    // Update size (also in header)
    --m_size;
    set_header_size(m_size);
}


inline void Array::erase(size_t begin, size_t end)
{
    if (begin != end) {
        // This can throw, but only if array is currently in read-only memory.
        move(end, size(), begin); // Throws

        // Update size (also in header)
        m_size -= end - begin;
        set_header_size(m_size);
    }
}

inline void Array::clear()
{
    truncate(0); // Throws
}

inline void Array::clear_and_destroy_children()
{
    truncate_and_destroy_children(0);
}

inline void Array::destroy_deep(ref_type ref, Allocator& alloc) noexcept
{
    destroy_deep(MemRef(ref, alloc), alloc);
}

inline void Array::destroy_deep(MemRef mem, Allocator& alloc) noexcept
{
    if (!get_hasrefs_from_header(mem.get_addr())) {
        alloc.free_(mem);
        return;
    }
    Array array(alloc);
    array.init_from_mem(mem);
    array.destroy_deep();
}


inline void Array::adjust(size_t ndx, int_fast64_t diff)
{
    REALM_ASSERT_3(ndx, <=, m_size);
    if (diff != 0) {
        // FIXME: Should be optimized
        int_fast64_t v = get(ndx);
        set(ndx, int64_t(v + diff)); // Throws
    }
}

inline void Array::adjust(size_t begin, size_t end, int_fast64_t diff)
{
    if (diff != 0) {
        // FIXME: Should be optimized
        for (size_t i = begin; i != end; ++i)
            adjust(i, diff); // Throws
    }
}


//-------------------------------------------------


inline size_t Array::get_byte_size() const noexcept
{
    const char* header = get_header_from_data(m_data);
    WidthType wtype = Node::get_wtype_from_header(header);
    size_t num_bytes = NodeHeader::calc_byte_size(wtype, m_size, m_width);

    REALM_ASSERT_7(m_alloc.is_read_only(m_ref), ==, true, ||, num_bytes, <=, get_capacity_from_header(header));

    return num_bytes;
}


//-------------------------------------------------

inline MemRef Array::create_empty_array(Type type, bool context_flag, Allocator& alloc)
{
    size_t size = 0;
    int_fast64_t value = 0;
    return create_array(type, context_flag, size, value, alloc); // Throws
}

inline MemRef Array::create_array(Type type, bool context_flag, size_t size, int_fast64_t value, Allocator& alloc)
{
    return create(type, context_flag, wtype_Bits, size, value, alloc); // Throws
}

inline size_t Array::get_max_byte_size(size_t num_elems) noexcept
{
    int max_bytes_per_elem = 8;
    return header_size + num_elems * max_bytes_per_elem;
}


inline void Array::update_child_ref(size_t child_ndx, ref_type new_ref)
{
    set(child_ndx, new_ref);
}

inline ref_type Array::get_child_ref(size_t child_ndx) const noexcept
{
    return get_as_ref(child_ndx);
}

inline void Array::ensure_minimum_width(int_fast64_t value)
{
    if (value >= m_lbound && value <= m_ubound)
        return;
    do_ensure_minimum_width(value);
}


} // namespace realm

#endif // REALM_ARRAY_HPP
