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

#ifndef REALM_TABLE_HPP
#define REALM_TABLE_HPP

#include "external/mpark/variant.hpp"
#include <algorithm>
#include <map>
#include <utility>
#include <typeinfo>
#include <memory>
#include <mutex>

#include <realm/util/features.h>
#include <realm/util/function_ref.hpp>
#include <realm/util/thread.hpp>
#include <realm/table_ref.hpp>
#include <realm/spec.hpp>
#include <realm/query.hpp>
#include <realm/cluster_tree.hpp>
#include <realm/keys.hpp>
#include <realm/global_key.hpp>

// Only set this to one when testing the code paths that exercise object ID
// hash collisions. It artificially limits the "optimistic" local ID to use
// only the lower 15 bits of the ID rather than the lower 63 bits, making it
// feasible to generate collisions within reasonable time.
#define REALM_EXERCISE_OBJECT_ID_COLLISION 0

namespace realm {

class BacklinkColumn;
template <class>
class BacklinkCount;
class TableView;
class Group;
class SortDescriptor;
class TableView;
template <class>
class Columns;
template <class>
class SubQuery;
class ColKeys;
struct GlobalKey;
class LinkChain;
class Subexpr;
class StringIndex;

struct Link {
};
typedef Link BackLink;


namespace _impl {
class TableFriend;
}
namespace util {
class Logger;
}
namespace query_parser {
class Arguments;
class KeyPathMapping;
class ParserDriver;
} // namespace query_parser

enum class ExpressionComparisonType : unsigned char {
    Any,
    All,
    None,
};

class Table {
public:
    /// The type of tables supported by a realm.
    /// Note: Any change to this enum is a file-format breaking change.
    /// Note: Enumeration value assignments must be kept in sync with
    /// <realm/object-store/object_schema.hpp>.
    enum class Type : uint8_t { TopLevel = 0, Embedded = 0x1, TopLevelAsymmetric = 0x2 };
    constexpr static uint8_t table_type_mask = 0x3;

    /// Construct a new freestanding top-level table with static
    /// lifetime. For debugging only.
    Table(Allocator& = Allocator::get_default());

    /// Construct a copy of the specified table as a new freestanding
    /// top-level table with static lifetime. For debugging only.
    Table(const Table&, Allocator& = Allocator::get_default());

    ~Table() noexcept;

    Allocator& get_alloc() const;

    /// Get the name of this table, if it has one. Only group-level tables have
    /// names. For a table of any other kind, this function returns the empty
    /// string.
    StringData get_name() const noexcept;

    // Get table name with class prefix removed
    StringData get_class_name() const noexcept;

    const char* get_state() const noexcept;

    /// If this table is a group-level table, the parent group is returned,
    /// otherwise null is returned.
    Group* get_parent_group() const noexcept;

    // Whether or not elements can be null.
    bool is_nullable(ColKey col_key) const;

    // Whether or not the column is a list.
    bool is_list(ColKey col_key) const;

    //@{
    /// Conventience functions for inspecting the dynamic table type.
    ///
    bool is_embedded() const noexcept;   // true if table holds embedded objects
    bool is_asymmetric() const noexcept; // true if table is asymmetric
    Type get_table_type() const noexcept;
    size_t get_column_count() const noexcept;
    DataType get_column_type(ColKey column_key) const;
    StringData get_column_name(ColKey column_key) const;
    ColumnAttrMask get_column_attr(ColKey column_key) const noexcept;
    DataType get_dictionary_key_type(ColKey column_key) const noexcept;
    ColKey get_column_key(StringData name) const noexcept;
    ColKeys get_column_keys() const;
    typedef util::Optional<std::pair<ConstTableRef, ColKey>> BacklinkOrigin;
    BacklinkOrigin find_backlink_origin(StringData origin_table_name, StringData origin_col_name) const noexcept;
    BacklinkOrigin find_backlink_origin(ColKey backlink_col) const noexcept;
    std::vector<std::pair<TableKey, ColKey>> get_incoming_link_columns() const noexcept;
    //@}

    // Primary key columns
    ColKey get_primary_key_column() const;
    void set_primary_key_column(ColKey col);
    void validate_primary_column();

    //@{
    /// Convenience functions for manipulating the dynamic table type.
    ///
    static const size_t max_column_name_length = 63;
    static const uint64_t max_num_columns = 0xFFFFUL; // <-- must be power of two -1
    ColKey add_column(DataType type, StringData name, bool nullable = false);
    ColKey add_column(Table& target, StringData name);
    ColKey add_column_list(DataType type, StringData name, bool nullable = false);
    ColKey add_column_list(Table& target, StringData name);
    ColKey add_column_set(DataType type, StringData name, bool nullable = false);
    ColKey add_column_set(Table& target, StringData name);
    ColKey add_column_dictionary(DataType type, StringData name, bool nullable = false,
                                 DataType key_type = type_String);
    ColKey add_column_dictionary(Table& target, StringData name, DataType key_type = type_String);

    [[deprecated("Use add_column(Table&) or add_column_list(Table&) instead.")]] //
    ColKey
    add_column_link(DataType type, StringData name, Table& target);

    void remove_column(ColKey col_key);
    void rename_column(ColKey col_key, StringData new_name);
    bool valid_column(ColKey col_key) const noexcept;
    void check_column(ColKey col_key) const
    {
        if (REALM_UNLIKELY(!valid_column(col_key)))
            throw InvalidColumnKey();
    }
    // Change the type of a table. Only allowed to switch to/from TopLevel from/to Embedded.
    void set_table_type(Type new_type, bool handle_backlinks = false);
    //@}

    /// True for `col_type_Link` and `col_type_LinkList`.
    static bool is_link_type(ColumnType) noexcept;

    //@{

    /// has_search_index() returns true if, and only if a search index has been
    /// added to the specified column. Rather than throwing, it returns false if
    /// the table accessor is detached or the specified index is out of range.
    ///
    /// add_search_index() adds a search index to the specified column of the
    /// table. It has no effect if a search index has already been added to the
    /// specified column (idempotency).
    ///
    /// remove_search_index() removes the search index from the specified column
    /// of the table. It has no effect if the specified column has no search
    /// index. The search index cannot be removed from the primary key of a
    /// table.
    ///
    /// \param col_key The key of a column of the table.

    IndexType search_index_type(ColKey col_key) const noexcept;
    bool has_search_index(ColKey col_key) const noexcept
    {
        return search_index_type(col_key) == IndexType::General;
    }
    void add_search_index(ColKey col_key, IndexType type = IndexType::General);
    void add_fulltext_index(ColKey col_key)
    {
        add_search_index(col_key, IndexType::Fulltext);
    }
    void remove_search_index(ColKey col_key);

    void enumerate_string_column(ColKey col_key);
    bool is_enumerated(ColKey col_key) const noexcept;
    bool contains_unique_values(ColKey col_key) const;

    //@}

    /// If the specified column is optimized to store only unique values, then
    /// this function returns the number of unique values currently
    /// stored. Otherwise it returns zero. This function is mainly intended for
    /// debugging purposes.
    size_t get_num_unique_values(ColKey col_key) const;

    template <class T>
    Columns<T> column(ColKey col_key, util::Optional<ExpressionComparisonType> = util::none) const;
    template <class T>
    Columns<T> column(const Table& origin, ColKey origin_col_key) const;

    // BacklinkCount is a total count per row and therefore not attached to a specific column
    template <class T>
    BacklinkCount<T> get_backlink_count() const;

    template <class T>
    SubQuery<T> column(ColKey col_key, Query subquery) const;
    template <class T>
    SubQuery<T> column(const Table& origin, ColKey origin_col_key, Query subquery) const;

    // Table size and deletion
    bool is_empty() const noexcept;
    size_t size() const noexcept
    {
        return m_clusters.size();
    }
    size_t nb_unresolved() const noexcept
    {
        return m_tombstones ? m_tombstones->size() : 0;
    }

    //@{

    /// Object handling.

    enum class UpdateMode { never, changed, all };

    // Create an object with key. If the key is omitted, a key will be generated by the system
    Obj create_object(ObjKey key = {}, const FieldValues& = {});
    // Create an object with specific GlobalKey - or return already existing object
    // Potential tombstone will be resurrected
    Obj create_object(GlobalKey object_id, const FieldValues& = {});
    // Create an object with primary key. If an object with the given primary key already exists, it
    // will be returned and did_create (if supplied) will be set to false.
    // Potential tombstone will be resurrected
    Obj create_object_with_primary_key(const Mixed& primary_key, FieldValues&&, UpdateMode mode = UpdateMode::all,
                                       bool* did_create = nullptr);
    Obj create_object_with_primary_key(const Mixed& primary_key, bool* did_create = nullptr)
    {
        return create_object_with_primary_key(primary_key, {{}}, UpdateMode::all, did_create);
    }
    // Return key for existing object or return null key.
    ObjKey find_primary_key(Mixed value) const;
    // Return ObjKey for object identified by id. If objects does not exist, return null key
    // Important: This function must not be called for tables with primary keys.
    ObjKey get_objkey(GlobalKey id) const;
    // Return key for existing object or return unresolved key.
    // Important: This is to be used ONLY by the Sync client. SDKs should NEVER
    // observe an unresolved key. Ever.
    ObjKey get_objkey_from_primary_key(const Mixed& primary_key);
    // Return key for existing object or return unresolved key.
    // Important: This is to be used ONLY by the Sync client. SDKs should NEVER
    // observe an unresolved key. Ever.
    // Important (2): This function must not be called for tables with primary keys.
    ObjKey get_objkey_from_global_key(GlobalKey key);
    /// Create a number of objects and add corresponding keys to a vector
    void create_objects(size_t number, std::vector<ObjKey>& keys);
    /// Create a number of objects with keys supplied
    void create_objects(const std::vector<ObjKey>& keys);
    /// Does the key refer to an object within the table?
    bool is_valid(ObjKey key) const noexcept
    {
        return m_clusters.is_valid(key);
    }
    GlobalKey get_object_id(ObjKey key) const;
    Obj get_object(ObjKey key) const
    {
        REALM_ASSERT(!key.is_unresolved());
        return m_clusters.get(key);
    }
    Obj try_get_object(ObjKey key) const noexcept
    {
        return m_clusters.try_get_obj(key);
    }
    Obj get_object(size_t ndx) const
    {
        return m_clusters.get(ndx);
    }
    // Get object based on primary key
    Obj get_object_with_primary_key(Mixed pk) const;
    // Get primary key based on ObjKey
    Mixed get_primary_key(ObjKey key) const;
    // Get logical index for object. This function is not very efficient
    size_t get_object_ndx(ObjKey key) const noexcept
    {
        return m_clusters.get_ndx(key);
    }

    void dump_objects();

    bool traverse_clusters(ClusterTree::TraverseFunction func) const
    {
        return m_clusters.traverse(func);
    }

    /// remove_object() removes the specified object from the table.
    /// Any links from the specified object into objects residing in an embedded
    /// table will cause those objects to be deleted as well, and so on recursively.
    void remove_object(ObjKey key);
    /// remove_object_recursive() will delete linked rows if the removed link was the
    /// last one holding on to the row in question. This will be done recursively.
    void remove_object_recursive(ObjKey key);
    // Invalidate object. To be used by the Sync client.
    // - turns the object into a tombstone if links exist
    // - otherwise works just as remove_object()
    ObjKey invalidate_object(ObjKey key);
    Obj try_get_tombstone(ObjKey key) const
    {
        REALM_ASSERT(key.is_unresolved());
        REALM_ASSERT(m_tombstones);
        return m_tombstones->try_get_obj(key);
    }

    void clear();
    using Iterator = ClusterTree::Iterator;
    Iterator begin() const;
    Iterator end() const;
    void remove_object(const Iterator& it)
    {
        remove_object(it->get_key());
    }
    //@}


    TableRef get_link_target(ColKey column_key) noexcept;
    ConstTableRef get_link_target(ColKey column_key) const noexcept;

    static const size_t max_string_size = 0xFFFFF8 - Array::header_size - 1;
    static const size_t max_binary_size = 0xFFFFF8 - Array::header_size;

    static constexpr int_fast64_t max_integer = std::numeric_limits<int64_t>::max();
    static constexpr int_fast64_t min_integer = std::numeric_limits<int64_t>::min();

    /// Only group-level unordered tables can be used as origins or targets of
    /// links.
    bool is_group_level() const noexcept;

    /// A Table accessor obtained from a frozen transaction is also frozen.
    bool is_frozen() const noexcept
    {
        return m_is_frozen;
    }

    /// If this table is a group-level table, then this function returns the
    /// index of this table within the group. Otherwise it returns realm::npos.
    size_t get_index_in_group() const noexcept;
    TableKey get_key() const noexcept;

    uint64_t allocate_sequence_number();
    // Used by upgrade
    void set_sequence_number(uint64_t seq);
    void set_collision_map(ref_type ref);

    // Get the key of this table directly, without needing a Table accessor.
    static TableKey get_key_direct(Allocator& alloc, ref_type top_ref);

    // Aggregate functions
    size_t count_int(ColKey col_key, int64_t value) const;
    size_t count_string(ColKey col_key, StringData value) const;
    size_t count_float(ColKey col_key, float value) const;
    size_t count_double(ColKey col_key, double value) const;
    size_t count_decimal(ColKey col_key, Decimal128 value) const;

    // Aggregates return nullopt if the operation is not supported on the given column
    // Everything but `sum` returns `some(null)` if there are no non-null values
    // Sum returns `some(0)` if there are no non-null values.
    std::optional<Mixed> sum(ColKey col_key) const;
    std::optional<Mixed> min(ColKey col_key, ObjKey* = nullptr) const;
    std::optional<Mixed> max(ColKey col_key, ObjKey* = nullptr) const;
    std::optional<Mixed> avg(ColKey col_key, size_t* value_count = nullptr) const;

    // Will return pointer to search index accessor. Will return nullptr if no index
    StringIndex* get_search_index(ColKey col) const noexcept
    {
        check_column(col);
        return m_index_accessors[col.get_index().val].get();
    }
    template <class T>
    ObjKey find_first(ColKey col_key, T value) const;

    ObjKey find_first_int(ColKey col_key, int64_t value) const;
    ObjKey find_first_bool(ColKey col_key, bool value) const;
    ObjKey find_first_timestamp(ColKey col_key, Timestamp value) const;
    ObjKey find_first_object_id(ColKey col_key, ObjectId value) const;
    ObjKey find_first_float(ColKey col_key, float value) const;
    ObjKey find_first_double(ColKey col_key, double value) const;
    ObjKey find_first_decimal(ColKey col_key, Decimal128 value) const;
    ObjKey find_first_string(ColKey col_key, StringData value) const;
    ObjKey find_first_binary(ColKey col_key, BinaryData value) const;
    ObjKey find_first_null(ColKey col_key) const;
    ObjKey find_first_uuid(ColKey col_key, UUID value) const;

    //    TableView find_all_link(Key target_key);
    TableView find_all_int(ColKey col_key, int64_t value);
    TableView find_all_int(ColKey col_key, int64_t value) const;
    TableView find_all_bool(ColKey col_key, bool value);
    TableView find_all_bool(ColKey col_key, bool value) const;
    TableView find_all_float(ColKey col_key, float value);
    TableView find_all_float(ColKey col_key, float value) const;
    TableView find_all_double(ColKey col_key, double value);
    TableView find_all_double(ColKey col_key, double value) const;
    TableView find_all_string(ColKey col_key, StringData value);
    TableView find_all_string(ColKey col_key, StringData value) const;
    TableView find_all_binary(ColKey col_key, BinaryData value);
    TableView find_all_binary(ColKey col_key, BinaryData value) const;
    TableView find_all_null(ColKey col_key);
    TableView find_all_null(ColKey col_key) const;

    TableView find_all_fulltext(ColKey col_key, StringData value) const;

    TableView get_sorted_view(ColKey col_key, bool ascending = true);
    TableView get_sorted_view(ColKey col_key, bool ascending = true) const;

    TableView get_sorted_view(SortDescriptor order);
    TableView get_sorted_view(SortDescriptor order) const;

    // Report the current content version. This is a 64-bit value which is bumped whenever
    // the content in the table changes.
    uint_fast64_t get_content_version() const noexcept;

    // Report the current instance version. This is a 64-bit value which is bumped
    // whenever the table accessor is recycled.
    uint_fast64_t get_instance_version() const noexcept;

    // Report the current storage version. This is a 64-bit value which is bumped
    // whenever the location in memory of any part of the table changes.
    uint_fast64_t get_storage_version(uint64_t instance_version) const;
    uint_fast64_t get_storage_version() const;
    void bump_storage_version() const noexcept;
    void bump_content_version() const noexcept;

    // Change the nullability of the column identified by col_key.
    // This might result in the creation of a new column and deletion of the old.
    // The column key to use going forward is returned.
    // If the conversion is from nullable to non-nullable, throw_on_null determines
    // the reaction to encountering a null value: If clear, null values will be
    // converted to default values. If set, a 'column_not_nullable' is thrown and the
    // table is unchanged.
    ColKey set_nullability(ColKey col_key, bool nullable, bool throw_on_null);

    // Iterate through (subset of) columns. The supplied function may abort iteration
    // by returning 'IteratorControl::Stop' (early out).
    template <typename Func>
    bool for_each_and_every_column(Func func) const
    {
        for (auto col_key : m_leaf_ndx2colkey) {
            if (!col_key)
                continue;
            if (func(col_key) == IteratorControl::Stop)
                return true;
        }
        return false;
    }
    template <typename Func>
    bool for_each_public_column(Func func) const
    {
        for (auto col_key : m_leaf_ndx2colkey) {
            if (!col_key)
                continue;
            if (col_key.get_type() == col_type_BackLink)
                continue;
            if (func(col_key) == IteratorControl::Stop)
                return true;
        }
        return false;
    }
    template <typename Func>
    bool for_each_backlink_column(Func func) const
    {
        // Could be optimized - to not iterate through all non-backlink columns:
        for (auto col_key : m_leaf_ndx2colkey) {
            if (!col_key)
                continue;
            if (col_key.get_type() != col_type_BackLink)
                continue;
            if (func(col_key) == IteratorControl::Stop)
                return true;
        }
        return false;
    }

private:
    template <class T>
    TableView find_all(ColKey col_key, T value);
    void build_column_mapping();
    ColKey generate_col_key(ColumnType ct, ColumnAttrMask attrs);
    void convert_column(ColKey from, ColKey to, bool throw_on_null);
    template <class F, class T>
    void change_nullability(ColKey from, ColKey to, bool throw_on_null);
    template <class F, class T>
    void change_nullability_list(ColKey from, ColKey to, bool throw_on_null);
    Obj create_linked_object();
    // Change the embedded property of a table. If switching to being embedded, the table must
    // not have a primary key and all objects must have exactly 1 backlink.
    void set_embedded(bool embedded, bool handle_backlinks);
    /// Changes type unconditionally. Called only from Group::do_get_or_add_table()
    void do_set_table_type(Type table_type);

public:
    // mapping between index used in leaf nodes (leaf_ndx) and index used in spec (spec_ndx)
    // as well as the full column key. A leaf_ndx can be obtained directly from the column key
    size_t colkey2spec_ndx(ColKey key) const;
    size_t leaf_ndx2spec_ndx(ColKey::Idx idx) const;
    ColKey::Idx spec_ndx2leaf_ndx(size_t idx) const;
    ColKey leaf_ndx2colkey(ColKey::Idx idx) const;
    ColKey spec_ndx2colkey(size_t ndx) const;

    // Queries
    // Using where(tv) is the new method to perform queries on TableView. The 'tv' can have any order; it does not
    // need to be sorted, and, resulting view retains its order.
    Query where(TableView* tv = nullptr)
    {
        return Query(m_own_ref, tv);
    }

    Query where(TableView* tv = nullptr) const
    {
        return Query(m_own_ref, tv);
    }

    // Perform queries on a Link Collection. The returned Query holds a reference to collection.
    Query where(const ObjList& list) const
    {
        return Query(m_own_ref, list);
    }
    Query where(const DictionaryLinkValues& dictionary_of_links) const;

    Query query(const std::string& query_string,
                const std::vector<mpark::variant<Mixed, std::vector<Mixed>>>& arguments = {}) const;
    Query query(const std::string& query_string, const std::vector<Mixed>& arguments) const;
    Query query(const std::string& query_string, const std::vector<Mixed>& arguments,
                const query_parser::KeyPathMapping& mapping) const;
    Query query(const std::string& query_string,
                const std::vector<mpark::variant<Mixed, std::vector<Mixed>>>& arguments,
                const query_parser::KeyPathMapping& mapping) const;
    Query query(const std::string& query_string, query_parser::Arguments& arguments,
                const query_parser::KeyPathMapping&) const;

    //@{
    /// WARNING: The link() and backlink() methods will alter a state on the Table object and return a reference
    /// to itself. Be aware if assigning the return value of link() to a variable; this might be an error!

    /// This is an error:

    /// Table& cats = owners->link(1);
    /// auto& dogs = owners->link(2);

    /// Query q = person_table->where()
    /// .and_query(cats.column<String>(5).equal("Fido"))
    /// .Or()
    /// .and_query(dogs.column<String>(6).equal("Meowth"));

    /// Instead, do this:

    /// Query q = owners->where()
    /// .and_query(person_table->link(1).column<String>(5).equal("Fido"))
    /// .Or()
    /// .and_query(person_table->link(2).column<String>(6).equal("Meowth"));

    /// The two calls to link() in the erroneous example will append the two values 0 and 1 to an internal vector in
    /// the owners table, and we end up with three references to that same table: owners, cats and dogs. They are all
    /// the same table, its vector has the values {0, 1}, so a query would not make any sense.
    LinkChain link(ColKey link_column) const;
    LinkChain backlink(const Table& origin, ColKey origin_col_key) const;

    // Conversion
    void schema_to_json(std::ostream& out, const std::map<std::string, std::string>& renames) const;
    void to_json(std::ostream& out, size_t link_depth, const std::map<std::string, std::string>& renames,
                 JSONOutputMode output_mode = output_mode_json) const;

    /// \brief Compare two tables for equality.
    ///
    /// Two tables are equal if they have equal descriptors
    /// (`Descriptor::operator==()`) and equal contents. Equal descriptors imply
    /// that the two tables have the same columns in the same order. Equal
    /// contents means that the two tables must have the same number of rows,
    /// and that for each row index, the two rows must have the same values in
    /// each column.
    ///
    /// In mixed columns, both the value types and the values are required to be
    /// equal.
    ///
    /// For a particular row and column, if the two values are themselves tables
    /// (subtable and mixed columns) value equality implies a recursive
    /// invocation of `Table::operator==()`.
    bool operator==(const Table&) const;

    /// \brief Compare two tables for inequality.
    ///
    /// See operator==().
    bool operator!=(const Table& t) const;

    // Debug
    void verify() const;

#ifdef REALM_DEBUG
    MemStats stats() const;
#endif
    TableRef get_opposite_table(ColKey col_key) const;
    TableKey get_opposite_table_key(ColKey col_key) const;
    bool links_to_self(ColKey col_key) const;
    ColKey get_opposite_column(ColKey col_key) const;
    ColKey find_opposite_column(ColKey col_key) const;

    class DisableReplication {
    public:
        DisableReplication(Table& table) noexcept
            : m_table(table)
            , m_repl(table.m_repl)
        {
            m_table.m_repl = &g_dummy_replication;
        }
        ~DisableReplication()
        {
            m_table.m_repl = m_repl;
        }

    private:
        Table& m_table;
        Replication* const* m_repl;
    };

private:
    enum LifeCycleCookie {
        cookie_created = 0x1234,
        cookie_transaction_ended = 0xcafe,
        cookie_initialized = 0xbeef,
        cookie_removed = 0xbabe,
        cookie_void = 0x5678,
        cookie_deleted = 0xdead,
    };

    // This is only used for debugging checks, so relaxed operations are fine.
    class AtomicLifeCycleCookie {
    public:
        void operator=(LifeCycleCookie cookie)
        {
            m_storage.store(cookie, std::memory_order_relaxed);
        }
        operator LifeCycleCookie() const
        {
            return m_storage.load(std::memory_order_relaxed);
        }

    private:
        std::atomic<LifeCycleCookie> m_storage = {};
    };

    mutable WrappedAllocator m_alloc;
    Array m_top;
    void update_allocator_wrapper(bool writable)
    {
        m_alloc.update_from_underlying_allocator(writable);
    }
    void refresh_allocator_wrapper() const noexcept
    {
        m_alloc.refresh_ref_translation();
    }
    Spec m_spec;                                    // 1st slot in m_top
    ClusterTree m_clusters;                         // 3rd slot in m_top
    std::unique_ptr<ClusterTree> m_tombstones;      // 13th slot in m_top
    TableKey m_key;                                 // 4th slot in m_top
    Array m_index_refs;                             // 5th slot in m_top
    Array m_opposite_table;                         // 7th slot in m_top
    Array m_opposite_column;                        // 8th slot in m_top
    std::vector<std::unique_ptr<StringIndex>> m_index_accessors;
    ColKey m_primary_key_col;
    Replication* const* m_repl;
    static Replication* g_dummy_replication;
    bool m_is_frozen = false;
    util::Optional<bool> m_has_any_embedded_objects;
    TableRef m_own_ref;

    void batch_erase_rows(const KeyColumn& keys);
    size_t do_set_link(ColKey col_key, size_t row_ndx, size_t target_row_ndx);

    void populate_search_index(ColKey col_key);
    void erase_from_search_indexes(ObjKey key);
    void update_indexes(ObjKey key, const FieldValues& values);
    void clear_indexes();

    // Migration support
    void migrate_column_info();
    bool verify_column_keys();
    void migrate_indexes(ColKey pk_col_key);
    void migrate_subspec();
    void create_columns();
    bool migrate_objects(); // Returns true if there are no links to migrate
    void migrate_links();
    void finalize_migration(ColKey pk_col_key);
    void migrate_sets_and_dictionaries();

    /// Disable copying assignment.
    ///
    /// It could easily be implemented by calling assign(), but the
    /// non-checking nature of the low-level dynamically typed API
    /// makes it too risky to offer this feature as an
    /// operator.
    Table& operator=(const Table&) = delete;

    /// Create an uninitialized accessor whose lifetime is managed by Group
    Table(Replication* const* repl, Allocator&);
    void revive(Replication* const* repl, Allocator& new_allocator, bool writable);

    void init(ref_type top_ref, ArrayParent*, size_t ndx_in_parent, bool is_writable, bool is_frozen);
    void ensure_graveyard();

    void set_key(TableKey key);

    ColKey do_insert_column(ColKey col_key, DataType type, StringData name, Table* target_table,
                            DataType key_type = DataType(0));

    struct InsertSubtableColumns;
    struct EraseSubtableColumns;
    struct RenameSubtableColumns;

    void erase_root_column(ColKey col_key);
    ColKey do_insert_root_column(ColKey col_key, ColumnType, StringData name, DataType key_type = DataType(0));
    void do_erase_root_column(ColKey col_key);
    void do_add_search_index(ColKey col_key, IndexType type);

    bool has_any_embedded_objects();
    void set_opposite_column(ColKey col_key, TableKey opposite_table, ColKey opposite_column);
    ColKey find_backlink_column(ColKey origin_col_key, TableKey origin_table) const;
    ColKey find_or_add_backlink_column(ColKey origin_col_key, TableKey origin_table);
    void do_set_primary_key_column(ColKey col_key);
    void validate_column_is_unique(ColKey col_key) const;

    ObjKey get_next_valid_key();
    /// Some Object IDs are generated as a tuple of the client_file_ident and a
    /// local sequence number. This function takes the next number in the
    /// sequence for the given table and returns an appropriate globally unique
    /// GlobalKey.
    GlobalKey allocate_object_id_squeezed();

    /// Find the local 64-bit object ID for the provided global 128-bit ID.
    ObjKey global_to_local_object_id_hashed(GlobalKey global_id) const;

    /// After a local ObjKey collision has been detected, this function may be
    /// called to obtain a non-colliding local ObjKey in such a way that subsequent
    /// calls to global_to_local_object_id() will return the correct local ObjKey
    /// for both \a incoming_id and \a colliding_id.
    ObjKey allocate_local_id_after_hash_collision(GlobalKey incoming_id, GlobalKey colliding_id,
                                                  ObjKey colliding_local_id);
    /// Create a placeholder for a not yet existing object and return key to it
    Obj get_or_create_tombstone(ObjKey key, ColKey pk_col, Mixed pk_val);
    /// Should be called when an object is deleted
    void free_local_id_after_hash_collision(ObjKey key);
    /// Should be called when last entry is removed - or when table is cleared
    void free_collision_table();

    /// Called in the context of Group::commit() to ensure that
    /// attached table accessors stay valid across a commit. Please
    /// note that this works only for non-transactional commits. Table
    /// accessors obtained during a transaction are always detached
    /// when the transaction ends.
    void update_from_parent() noexcept;

    // Detach accessor. This recycles the Table accessor and all subordinate
    // accessors become invalid.
    void detach(LifeCycleCookie) noexcept;
    void fully_detach() noexcept;

    ColumnType get_real_column_type(ColKey col_key) const noexcept;

    uint64_t get_sync_file_id() const noexcept;

    /// Create an empty table with independent spec and return just
    /// the reference to the underlying memory.
    static ref_type create_empty_table(Allocator&, TableKey = TableKey());

    void nullify_links(CascadeState&);
    void remove_recursive(CascadeState&);

    Replication* get_repl() const noexcept;
    util::Logger* get_logger() const noexcept;

    void set_ndx_in_parent(size_t ndx_in_parent) noexcept;

    /// Refresh the part of the accessor tree that is rooted at this
    /// table.
    void refresh_accessor_tree();
    void refresh_index_accessors();
    void refresh_content_version();
    void flush_for_commit();

    bool is_cross_table_link_target() const noexcept;

    template <typename T>
    void aggregate(QueryStateBase& st, ColKey col_key) const;

    std::vector<ColKey> m_leaf_ndx2colkey;
    std::vector<ColKey::Idx> m_spec_ndx2leaf_ndx;
    std::vector<size_t> m_leaf_ndx2spec_ndx;
    Type m_table_type = Type::TopLevel;
    uint64_t m_in_file_version_at_transaction_boundary = 0;
    AtomicLifeCycleCookie m_cookie;

    static constexpr int top_position_for_spec = 0;
    static constexpr int top_position_for_columns = 1;
    static constexpr int top_position_for_cluster_tree = 2;
    static constexpr int top_position_for_key = 3;
    static constexpr int top_position_for_search_indexes = 4;
    static constexpr int top_position_for_column_key = 5;
    static constexpr int top_position_for_version = 6;
    static constexpr int top_position_for_opposite_table = 7;
    static constexpr int top_position_for_opposite_column = 8;
    static constexpr int top_position_for_sequence_number = 9;
    static constexpr int top_position_for_collision_map = 10;
    static constexpr int top_position_for_pk_col = 11;
    static constexpr int top_position_for_flags = 12;
    // flags contents: bit 0-1 - table type
    static constexpr int top_position_for_tombstones = 13;
    static constexpr int top_array_size = 14;

    enum { s_collision_map_lo = 0, s_collision_map_hi = 1, s_collision_map_local_id = 2, s_collision_map_num_slots };

    friend class _impl::TableFriend;
    friend class Query;
    template <class>
    friend class SimpleQuerySupport;
    friend class TableView;
    template <class T>
    friend class Columns;
    friend class Columns<StringData>;
    friend class ParentNode;
    friend struct util::serializer::SerialisationState;
    friend class LinkMap;
    friend class LinkView;
    friend class Group;
    friend class Transaction;
    friend class Cluster;
    friend class ClusterTree;
    friend class ColKeyIterator;
    friend class Obj;
    friend class LnkLst;
    friend class Dictionary;
    friend class IncludeDescriptor;
    template <class T>
    friend class AggregateHelper;
};

std::ostream& operator<<(std::ostream& o, Table::Type table_type);

class ColKeyIterator {
public:
    bool operator!=(const ColKeyIterator& other)
    {
        return m_pos != other.m_pos;
    }
    ColKeyIterator& operator++()
    {
        ++m_pos;
        return *this;
    }
    ColKeyIterator operator++(int)
    {
        ColKeyIterator tmp(m_table, m_pos);
        ++m_pos;
        return tmp;
    }
    ColKey operator*()
    {
        if (m_pos < m_table->get_column_count()) {
            REALM_ASSERT(m_table->m_spec.get_key(m_pos) == m_table->spec_ndx2colkey(m_pos));
            return m_table->m_spec.get_key(m_pos);
        }
        return {};
    }

private:
    friend class ColKeys;
    const Table* m_table;
    size_t m_pos;

    ColKeyIterator(const Table* t, size_t p)
        : m_table(t)
        , m_pos(p)
    {
    }
};

class ColKeys {
public:
    ColKeys(const Table* t)
        : m_table(t)
    {
    }

    ColKeys()
        : m_table(nullptr)
    {
    }

    size_t size() const
    {
        return m_table->get_column_count();
    }
    bool empty() const
    {
        return size() == 0;
    }
    ColKey operator[](size_t p) const
    {
        return ColKeyIterator(m_table, p).operator*();
    }
    ColKeyIterator begin() const
    {
        return ColKeyIterator(m_table, 0);
    }
    ColKeyIterator end() const
    {
        return ColKeyIterator(m_table, size());
    }

private:
    const Table* m_table;
};

// Class used to collect a chain of links when building up a Query following links.
// It has member functions corresponding to the ones defined on Table.
class LinkChain {
public:
    LinkChain(ConstTableRef t = {}, util::Optional<ExpressionComparisonType> type = util::none)
        : m_current_table(t)
        , m_base_table(t)
        , m_comparison_type(type)
    {
    }
    ConstTableRef get_base_table()
    {
        return m_base_table;
    }

    ConstTableRef get_current_table() const
    {
        return m_current_table;
    }

    ColKey get_current_col() const
    {
        return m_link_cols.back();
    }

    LinkChain& link(ColKey link_column)
    {
        add(link_column);
        return *this;
    }

    LinkChain& link(std::string col_name)
    {
        auto ck = m_current_table->get_column_key(col_name);
        if (!ck) {
            throw LogicError(ErrorCodes::InvalidProperty,
                             util::format("'%1' has no property '%2'", m_current_table->get_class_name(), col_name));
        }
        add(ck);
        return *this;
    }

    LinkChain& backlink(const Table& origin, ColKey origin_col_key)
    {
        auto backlink_col_key = origin.get_opposite_column(origin_col_key);
        return link(backlink_col_key);
    }

    std::unique_ptr<Subexpr> column(const std::string&);
    std::unique_ptr<Subexpr> subquery(Query subquery);

    template <class T>
    inline Columns<T> column(ColKey col_key)
    {
        m_current_table->check_column(col_key);

        // Check if user-given template type equals Realm type.
        auto ct = col_key.get_type();
        if (ct == col_type_LinkList)
            ct = col_type_Link;
        if constexpr (std::is_same_v<T, Dictionary>) {
            if (!col_key.is_dictionary())
                throw LogicError(ErrorCodes::TypeMismatch, "Not a dictionary");
        }
        else {
            if (ct != ColumnTypeTraits<T>::column_id)
                throw LogicError(ErrorCodes::TypeMismatch,
                                 util::format("Expected %1 to be a %2", m_current_table->get_column_name(col_key),
                                              ColumnTypeTraits<T>::column_id));
        }

        if (std::is_same<T, Link>::value || std::is_same<T, LnkLst>::value || std::is_same<T, BackLink>::value) {
            m_link_cols.push_back(col_key);
        }

        return Columns<T>(col_key, m_base_table, m_link_cols, m_comparison_type);
    }
    template <class T>
    Columns<T> column(const Table& origin, ColKey origin_col_key)
    {
        static_assert(std::is_same<T, BackLink>::value, "");

        auto backlink_col_key = origin.get_opposite_column(origin_col_key);
        m_link_cols.push_back(backlink_col_key);

        return Columns<T>(backlink_col_key, m_base_table, std::move(m_link_cols));
    }
    template <class T>
    SubQuery<T> column(ColKey col_key, Query subquery)
    {
        static_assert(std::is_same<T, Link>::value, "A subquery must involve a link list or backlink column");
        return SubQuery<T>(column<T>(col_key), std::move(subquery));
    }

    template <class T>
    SubQuery<T> column(const Table& origin, ColKey origin_col_key, Query subquery)
    {
        static_assert(std::is_same<T, BackLink>::value, "A subquery must involve a link list or backlink column");
        return SubQuery<T>(column<T>(origin, origin_col_key), std::move(subquery));
    }

    template <class T>
    BacklinkCount<T> get_backlink_count()
    {
        return BacklinkCount<T>(m_base_table, std::move(m_link_cols));
    }

private:
    friend class Table;
    friend class query_parser::ParserDriver;

    std::vector<ColKey> m_link_cols;
    ConstTableRef m_current_table;
    ConstTableRef m_base_table;
    util::Optional<ExpressionComparisonType> m_comparison_type;

    void add(ColKey ck);

    template <class T>
    std::unique_ptr<Subexpr> create_subexpr(ColKey col_key)
    {
        return std::make_unique<Columns<T>>(col_key, m_base_table, m_link_cols, m_comparison_type);
    }
};

// Implementation:

inline ColKeys Table::get_column_keys() const
{
    return ColKeys(this);
}

inline uint_fast64_t Table::get_content_version() const noexcept
{
    return m_alloc.get_content_version();
}

inline uint_fast64_t Table::get_instance_version() const noexcept
{
    return m_alloc.get_instance_version();
}


inline uint_fast64_t Table::get_storage_version(uint64_t instance_version) const
{
    return m_alloc.get_storage_version(instance_version);
}

inline uint_fast64_t Table::get_storage_version() const
{
    return m_alloc.get_storage_version();
}


inline TableKey Table::get_key() const noexcept
{
    return m_key;
}

inline void Table::bump_storage_version() const noexcept
{
    return m_alloc.bump_storage_version();
}

inline void Table::bump_content_version() const noexcept
{
    m_alloc.bump_content_version();
}


inline size_t Table::get_column_count() const noexcept
{
    return m_spec.get_public_column_count();
}

inline bool Table::is_embedded() const noexcept
{
    return m_table_type == Type::Embedded;
}

inline bool Table::is_asymmetric() const noexcept
{
    return m_table_type == Type::TopLevelAsymmetric;
}

inline Table::Type Table::get_table_type() const noexcept
{
    return m_table_type;
}

inline StringData Table::get_column_name(ColKey column_key) const
{
    auto spec_ndx = colkey2spec_ndx(column_key);
    REALM_ASSERT_3(spec_ndx, <, get_column_count());
    return m_spec.get_column_name(spec_ndx);
}

inline ColKey Table::get_column_key(StringData name) const noexcept
{
    size_t spec_ndx = m_spec.get_column_index(name);
    if (spec_ndx == npos)
        return ColKey();
    return spec_ndx2colkey(spec_ndx);
}

inline ColumnType Table::get_real_column_type(ColKey col_key) const noexcept
{
    return col_key.get_type();
}

inline DataType Table::get_column_type(ColKey column_key) const
{
    return DataType(column_key.get_type());
}

inline ColumnAttrMask Table::get_column_attr(ColKey column_key) const noexcept
{
    return column_key.get_attrs();
}

inline DataType Table::get_dictionary_key_type(ColKey column_key) const noexcept
{
    auto spec_ndx = colkey2spec_ndx(column_key);
    REALM_ASSERT_3(spec_ndx, <, get_column_count());
    return m_spec.get_dictionary_key_type(spec_ndx);
}


inline void Table::revive(Replication* const* repl, Allocator& alloc, bool writable)
{
    m_alloc.switch_underlying_allocator(alloc);
    m_alloc.update_from_underlying_allocator(writable);
    m_repl = repl;
    m_own_ref = TableRef(this, m_alloc.get_instance_version());

    // since we're rebinding to a new table, we'll bump version counters
    // Possible optimization: save version counters along with the table data
    // and restore them from there. Should decrease amount of non-necessary
    // recomputations of any queries relying on this table.
    bump_content_version();
    bump_storage_version();
    // we assume all other accessors are detached, so we're done.
}

inline Allocator& Table::get_alloc() const
{
    return m_alloc;
}

// For use by queries
template <class T>
inline Columns<T> Table::column(ColKey col_key, util::Optional<ExpressionComparisonType> cmp_type) const
{
    LinkChain lc(m_own_ref, cmp_type);
    return lc.column<T>(col_key);
}

template <class T>
inline Columns<T> Table::column(const Table& origin, ColKey origin_col_key) const
{
    LinkChain lc(m_own_ref);
    return lc.column<T>(origin, origin_col_key);
}

template <class T>
inline BacklinkCount<T> Table::get_backlink_count() const
{
    return BacklinkCount<T>(this, {});
}

template <class T>
SubQuery<T> Table::column(ColKey col_key, Query subquery) const
{
    LinkChain lc(m_own_ref);
    return lc.column<T>(col_key, subquery);
}

template <class T>
SubQuery<T> Table::column(const Table& origin, ColKey origin_col_key, Query subquery) const
{
    LinkChain lc(m_own_ref);
    return lc.column<T>(origin, origin_col_key, subquery);
}

inline LinkChain Table::link(ColKey link_column) const
{
    LinkChain lc(m_own_ref);
    lc.add(link_column);

    return lc;
}

inline LinkChain Table::backlink(const Table& origin, ColKey origin_col_key) const
{
    auto backlink_col_key = origin.get_opposite_column(origin_col_key);
    return link(backlink_col_key);
}

inline bool Table::is_empty() const noexcept
{
    return size() == 0;
}

inline ConstTableRef Table::get_link_target(ColKey col_key) const noexcept
{
    return const_cast<Table*>(this)->get_link_target(col_key);
}

inline bool Table::is_group_level() const noexcept
{
    return bool(get_parent_group());
}

inline bool Table::operator!=(const Table& t) const
{
    return !(*this == t); // Throws
}

inline bool Table::is_link_type(ColumnType col_type) noexcept
{
    return col_type == col_type_Link || col_type == col_type_LinkList;
}

inline Replication* Table::get_repl() const noexcept
{
    return *m_repl;
}

inline void Table::set_ndx_in_parent(size_t ndx_in_parent) noexcept
{
    REALM_ASSERT(m_top.is_attached());
    m_top.set_ndx_in_parent(ndx_in_parent);
}

inline size_t Table::colkey2spec_ndx(ColKey key) const
{
    auto leaf_idx = key.get_index();
    REALM_ASSERT(leaf_idx.val < m_leaf_ndx2spec_ndx.size());
    return m_leaf_ndx2spec_ndx[leaf_idx.val];
}

inline ColKey Table::spec_ndx2colkey(size_t spec_ndx) const
{
    REALM_ASSERT(spec_ndx < m_spec_ndx2leaf_ndx.size());
    return m_leaf_ndx2colkey[m_spec_ndx2leaf_ndx[spec_ndx].val];
}

inline size_t Table::leaf_ndx2spec_ndx(ColKey::Idx leaf_ndx) const
{
    REALM_ASSERT(leaf_ndx.val < m_leaf_ndx2colkey.size());
    return m_leaf_ndx2spec_ndx[leaf_ndx.val];
}

inline ColKey::Idx Table::spec_ndx2leaf_ndx(size_t spec_ndx) const
{
    REALM_ASSERT(spec_ndx < m_spec_ndx2leaf_ndx.size());
    return m_spec_ndx2leaf_ndx[spec_ndx];
}

inline ColKey Table::leaf_ndx2colkey(ColKey::Idx leaf_ndx) const
{
    // this may be called with leaf indicies outside of the table. This can happen
    // when a column is removed from the mapping, but space for it is still reserved
    // at leaf level. Operations on Cluster and ClusterTree which walks the columns
    // based on leaf indicies may ask for colkeys which are no longer valid.
    if (leaf_ndx.val < m_leaf_ndx2spec_ndx.size())
        return m_leaf_ndx2colkey[leaf_ndx.val];
    else
        return ColKey();
}

bool inline Table::valid_column(ColKey col_key) const noexcept
{
    if (col_key == ColKey())
        return false;
    ColKey::Idx leaf_idx = col_key.get_index();
    if (leaf_idx.val >= m_leaf_ndx2colkey.size())
        return false;
    return col_key == m_leaf_ndx2colkey[leaf_idx.val];
}

// The purpose of this class is to give internal access to some, but
// not all of the non-public parts of the Table class.
class _impl::TableFriend {
public:
    static Spec& get_spec(Table& table) noexcept
    {
        return table.m_spec;
    }

    static const Spec& get_spec(const Table& table) noexcept
    {
        return table.m_spec;
    }

    static TableRef get_opposite_link_table(const Table& table, ColKey col_key);

    static Group* get_parent_group(const Table& table) noexcept
    {
        return table.get_parent_group();
    }

    static void remove_recursive(Table& table, CascadeState& rows)
    {
        table.remove_recursive(rows); // Throws
    }

    static void batch_erase_rows(Table& table, const KeyColumn& keys)
    {
        table.batch_erase_rows(keys); // Throws
    }
    static ObjKey global_to_local_object_id_hashed(const Table& table, GlobalKey global_id)
    {
        return table.global_to_local_object_id_hashed(global_id);
    }
};

} // namespace realm

#endif // REALM_TABLE_HPP
