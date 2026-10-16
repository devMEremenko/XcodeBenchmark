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

#ifndef REALM_GROUP_WRITER_HPP
#define REALM_GROUP_WRITER_HPP

#include <cstdint> // unint8_t etc
#include <utility>
#include <map>

#include <realm/util/file.hpp>
#include <realm/alloc.hpp>
#include <realm/array.hpp>
#include <realm/impl/array_writer.hpp>
#include <realm/db_options.hpp>


namespace realm {

// Pre-declarations
class Transaction;
class SlabAlloc;

class Reachable {
public:
    ref_type pos;
    size_t size;
};
class VersionInfo {
public:
    VersionInfo(ref_type t, ref_type l)
        : top_ref(t)
        , logical_file_size(l)
    {
    }
    ref_type top_ref;
    ref_type logical_file_size;
    // used in debug mode to validate backdating algo:
    std::vector<Reachable> reachable_blocks;
};

using TopRefMap = std::map<uint64_t, VersionInfo>;
using VersionVector = std::vector<uint64_t>;

class WriteWindowMgr {
public:
    using Durability = DBOptions::Durability;
    WriteWindowMgr(SlabAlloc& alloc, Durability dura, util::WriteMarker* write_marker);
    // Flush all cached memory mappings
    // Sync all cached memory mappings to disk - includes flush if needed
    void sync_all_mappings();
    // Flush all cached memory mappings from private to shared cache.
    void flush_all_mappings();
    class MapWindow;
    // Get a suitable memory mapping for later access:
    // potentially adding it to the cache, potentially closing
    // the least recently used and sync'ing it to disk
    MapWindow* get_window(ref_type start_ref, size_t size);

protected:
    SlabAlloc& m_alloc;
    Durability m_durability;
    // Currently cached memory mappings. We keep as many as 16 1MB windows
    // open for writing. The allocator will favor sequential allocation
    // from a modest number of windows, depending upon fragmentation, so
    // 16 windows should be more than enough. If more than 16 windows are
    // needed, the least recently used is sync'ed and closed to make room
    // for a new one. The windows are kept in MRU (most recently used) order.
    const static int num_map_windows = 16;
    std::vector<std::unique_ptr<MapWindow>> m_map_windows;
    size_t m_window_alignment;
    util::WriteMarker* m_write_marker = nullptr;
};

class GroupCommitter {
public:
    using Durability = DBOptions::Durability;
    using MapWindow = WriteWindowMgr::MapWindow;
    GroupCommitter(Transaction&, Durability dura = Durability::Full, util::WriteMarker* write_marker = nullptr);
    ~GroupCommitter();
    /// Flush changes to physical medium, then write the new top ref
    /// to the file header, then flush again. Pass the top ref
    /// returned by write_group().
    void commit(ref_type new_top_ref);

protected:
    Transaction& m_group;
    SlabAlloc& m_alloc;
    Durability m_durability;
    WriteWindowMgr m_window_mgr;
};

/// This class is not supposed to be reused for multiple write sessions. In
/// particular, do not reuse it in case any of the functions throw.
class GroupWriter : public _impl::ArrayWriterBase {
public:
    using Durability = DBOptions::Durability;
    using MapWindow = WriteWindowMgr::MapWindow;
    enum class EvacuationStage { idle, evacuating, waiting, blocked };
    // For groups in transactional mode (Group::m_is_shared), this constructor
    // must be called while a write transaction is in progress.
    //
    // The constructor adds free-space tracking information to the specified
    // group, if it is not already present (4th and 5th entry in
    // Group::m_top). If the specified group is in transactional mode
    // (Group::m_is_shared), the constructor also adds version tracking
    // information to the group, if it is not already present (6th and 7th entry
    // in Group::m_top).
    GroupWriter(Transaction&, Durability dura = Durability::Full, util::WriteMarker* write_marker = nullptr);
    ~GroupWriter();

    void set_versions(uint64_t current, TopRefMap& top_refs, bool any_num_unreachables) noexcept;

    /// Write all changed array nodes into free space.
    ///
    /// Returns the new top ref. When in full durability mode, call
    /// commit() with the returned top ref.
    ref_type write_group();


    size_t get_file_size() const noexcept;

    ref_type write_array(const char*, size_t, uint32_t) override;

#ifdef REALM_DEBUG
    void dump();
#endif

    size_t get_free_space_size() const
    {
        return m_free_space_size;
    }

    size_t get_locked_space_size() const
    {
        return m_locked_space_size;
    }

    size_t get_logical_size() const noexcept
    {
        return m_logical_size;
    }

    size_t get_evacuation_limit() const noexcept
    {
        return m_backoff ? 0 : m_evacuation_limit;
    }

    size_t get_free_list_size()
    {
        return m_free_positions.size() * size_per_free_list_entry();
    }

    /// Prepare for a round of evacuation (if applicable)
    void prepare_evacuation();

    std::vector<size_t>& get_evacuation_progress()
    {
        return m_evacuation_progress;
    }

    EvacuationStage get_evacuation_stage() const noexcept
    {
        if (m_evacuation_limit == 0) {
            if (m_backoff == 0) {
                return EvacuationStage::idle;
            }
            else {
                return EvacuationStage::blocked;
            }
        }
        else {
            if (m_backoff == 0) {
                return EvacuationStage::evacuating;
            }
            else {
                return EvacuationStage::waiting;
            }
        }
    }
    void sync_according_to_durability();

private:
    friend class InMemoryWriter;
    struct FreeSpaceEntry {
        FreeSpaceEntry(size_t r, size_t s, uint64_t v)
            : ref(r)
            , size(s)
            , released_at_version(v)
        {
        }
        size_t ref;
        size_t size;
        uint64_t released_at_version;
    };

    static void merge_adjacent_entries_in_freelist(std::vector<FreeSpaceEntry>& list);
    static void move_free_in_file_to_size_map(const std::vector<GroupWriter::FreeSpaceEntry>& list,
                                              std::multimap<size_t, size_t>& size_map);

    Transaction& m_group;
    SlabAlloc& m_alloc;
    Durability m_durability;
    WriteWindowMgr m_window_mgr;
    Array m_free_positions; // 4th slot in Group::m_top
    Array m_free_lengths;   // 5th slot in Group::m_top
    Array m_free_versions;  // 6th slot in Group::m_top
    uint64_t m_current_version = 0;
    uint64_t m_oldest_reachable_version;
    TopRefMap m_top_ref_map;
    bool m_any_new_unreachables;
    size_t m_free_space_size = 0;
    size_t m_locked_space_size = 0;
    size_t m_evacuation_limit;
    int64_t m_backoff;
    size_t m_logical_size = 0;

    //  m_free_in_file;
    std::vector<FreeSpaceEntry> m_not_free_in_file;
    std::vector<FreeSpaceEntry> m_under_evacuation;
    std::multimap<size_t, size_t> m_size_map;
    std::vector<size_t> m_evacuation_progress;
    using FreeListElement = std::multimap<size_t, size_t>::iterator;

    void read_in_freelist();
    size_t recreate_freelist(size_t reserve_pos);

    /// Allocate a chunk of free space of the specified size. The
    /// specified size must be 8-byte aligned. Extend the file if
    /// required. The returned chunk is removed from the amount of
    /// remaing free space. The returned chunk is guaranteed to be
    /// within a single contiguous memory mapping.
    ///
    /// \return The position within the database file of the allocated
    /// chunk.
    size_t get_free_space(size_t size);

    /// Find a block of free space that is at least as big as the
    /// specified size and which will allow an allocation that is mapped
    /// inside a contiguous address range. The specified size does not
    /// need to be 8-byte aligned. Extend the file if required.
    /// The returned chunk is not removed from the amount of remaing
    /// free space.
    ///
    /// \return A pair (`chunk_ndx`, `chunk_size`) where `chunk_ndx`
    /// is the index of a chunk whose size is at least the requestd
    /// size, and `chunk_size` is the size of that chunk.
    FreeListElement reserve_free_space(size_t size);

    FreeListElement search_free_space_in_free_list_element(FreeListElement element, size_t size);

    /// Search only a range of the free list for a block as big as the
    /// specified size. Return a pair with index and size of the found chunk.
    FreeListElement search_free_space_in_part_of_freelist(size_t size);

    /// Extend the file to ensure that a chunk of free space of the
    /// specified size is available. The specified size does not need
    /// to be 8-byte aligned. This function guarantees that it will
    /// add at most one entry to the free-lists.
    ///
    /// \return A pair (`chunk_ndx`, `chunk_size`) where `chunk_ndx`
    /// is the index of a chunk whose size is at least the requestd
    /// size, and `chunk_size` is the size of that chunk.
    FreeListElement extend_free_space(size_t requested_size);

    template <class T>
    void write_array_at(T* translator, ref_type, const char* data, size_t size);
    FreeListElement split_freelist_chunk(FreeListElement, size_t alloc_pos);

    /// Backdate (if possible) any blocks in the freelist belonging to
    /// a version currently becomming unreachable. The effect of backdating
    /// is that many blocks can be freed earlier.
    void backdate();

    /// Debug helper - extends the TopRefMap with list of reachable blocks
    void map_reachable();

    size_t size_per_free_list_entry() const
    {
        // If current size is less than 128 MB, the database need not expand above 2 GB
        // which means that the positions and sizes can still be in 32 bit.
        return (m_logical_size < 0x8000000 ? 8 : 16) + 8;
    }
};


// Implementation:

inline void GroupWriter::set_versions(uint64_t current, TopRefMap& top_refs, bool any_new_unreachables) noexcept
{
    m_oldest_reachable_version = top_refs.begin()->first;
    REALM_ASSERT(m_oldest_reachable_version <= current);
    m_current_version = current;
    m_any_new_unreachables = any_new_unreachables;
    m_top_ref_map = std::move(top_refs);
}

} // namespace realm

#endif // REALM_GROUP_WRITER_HPP
