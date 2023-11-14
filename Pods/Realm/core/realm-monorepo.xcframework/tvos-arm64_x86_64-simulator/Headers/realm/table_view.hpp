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

#ifndef REALM_TABLE_VIEW_HPP
#define REALM_TABLE_VIEW_HPP

#include <realm/sort_descriptor.hpp>
#include <realm/table.hpp>
#include <realm/util/features.h>
#include <realm/obj_list.hpp>
#include <realm/list.hpp>
#include <realm/set.hpp>

namespace realm {

// Views, tables and synchronization between them:
//
// Views are built through queries against either tables or another view.
// Views may be restricted to only hold entries provided by another view.
// this other view is called the "restricting view".
// Views may be sorted in ascending or descending order of values in one ore more columns.
//
// Views remember the query from which it was originally built.
// Views remember the table from which it was originally built.
// Views remember a restricting view if one was used when it was originally built.
// Views remember the sorting criteria (columns and direction)
//
// A view may be operated in one of two distinct modes: *reflective* and *imperative*.
// Sometimes the term "reactive" is used instead of "reflective" with the same meaning.
//
// Reflective views:
// - A reflective view *always* *reflect* the result of running the query.
//   If the underlying tables or tableviews change, the reflective view changes as well.
//   A reflective view may need to rerun the query it was generated from, a potentially
//   costly operation which happens on demand.
// - It does not matter whether changes are explicitly done within the transaction, or
//   occur implicitly as part of advance_read() or promote_to_write().
//
// Imperative views:
// - An imperative view only *initially* holds the result of the query. An imperative
//   view *never* reruns the query. To force the view to match it's query (by rerunning it),
//   the view must be operated in reflective mode.
//   An imperative view can be modified explicitly. References can be added, removed or
//   changed.
//
// - In imperative mode, the references in the view tracks movement of the referenced data:
//   If you delete an entry which is referenced from a view, said reference is detached,
//   not removed.
// - It does not matter whether the delete is done in-line (as part of the current transaction),
//   or if it is done implicitly as part of advance_read() or promote_to_write().
//
// The choice between reflective and imperative views might eventually be represented by a
// switch on the tableview, but isn't yet. For now, clients (bindings) must call sync_if_needed()
// to get reflective behavior.
//
// Use cases:
//
// 1. Presenting data
// The first use case (and primary motivator behind the reflective view) is to just track
// and present the state of the database. In this case, the view is operated in reflective
// mode, it is not modified within the transaction, and it is not used to modify data in
// other parts of the database.
//
// 2. Background execution
// This is the second use case. The implicit rerun of the query in our first use case
// may be too costly to be acceptable on the main thread. Instead you want to run the query
// on a worker thread, but display it on the main thread. To achieve this, you need two
// Transactions locked on to the same version of the database. If you have that, you can
// import_copy_of() a view from one transaction to the other. See also db.hpp for more
// information. Technically, you can also import_copy_of into a transaction locked to a
// different version. The imported view will automatically match the importing version.
//
// 3. Iterating a view and changing data
// The third use case (and a motivator behind the imperative view) is when you want
// to make changes to the database in accordance with a query result. Imagine you want to
// find all employees with a salary below a limit and raise their salaries to the limit (pseudocode):
//
//    promote_to_write();
//    view = table.where().less_than(salary_column,limit).find_all();
//    for (size_t i = 0; i < view.size(); ++i) {
//        view[i].set(salary_column, limit);
//        // add this to get reflective mode: view.sync_if_needed();
//    }
//    commit_and_continue_as_read();
//
// This is idiomatic imperative code and it works if the view is operated in imperative mode.
//
// If the view is operated in reflective mode, the behaviour surprises most people: When the
// first salary is changed, the entry no longer fullfills the query, so it is dropped from the
// view implicitly. view[0] is removed, view[1] moves to view[0] and so forth. But the next
// loop iteration has i=1 and refers to view[1], thus skipping view[0]. The end result is that
// every other employee get a raise, while the others don't.
//
// 4. Iterating intermixed with implicit updates
// This leads us to use case 4, which is similar to use case 3, but uses promote_to_write()
// intermixed with iterating a view. This is actually quite important to some, who do not want
// to end up with a large write transaction.
//
//    view = table.where().less_than(salary_column,limit).find_all();
//    for (size_t i = 0; i < view.size(); ++i) {
//        promote_to_write();
//        view[i].set(salary_column, limit);
//        commit_and_continue_as_write();
//    }
//
// Anything can happen at the call to promote_to_write(). The key question then becomes: how
// do we support a safe way of realising the original goal (raising salaries) ?
//
// using the imperative operating mode:
//
//    view = table.where().less_than(salary_column,limit).find_all();
//    for (size_t i = 0; i < view.size(); ++i) {
//        promote_to_write();
//        // add r.sync_if_needed(); to get reflective mode
//        if (r.is_obj_valid(i)) {
//            auto r = view[i];
//            view[i].set(salary_column, limit);
//        }
//        commit_and_continue_as_write();
//    }
//
// This is safe, and we just aim for providing low level safety: is_obj_valid() can tell
// if the reference is valid, and the references in the view continue to point to the
// same object at all times, also following implicit updates. The rest is up to the
// application logic.
//
// It is important to see, that there is no guarantee that all relevant employees get
// their raise in cases whith concurrent updates. At every call to promote_to_write() new
// employees may be added to the underlying table, but as the view is in imperative mode,
// these new employees are not added to the view. Also at promote_to_write() an existing
// employee could recieve a (different, larger) raise which would then be overwritten and lost.
// However, these are problems that you should expect, since the activity is spread over multiple
// transactions.

class TableView : public ObjList {
public:
    /// Construct null view (no memory allocated).
    TableView() {}

    /// Construct empty view, ready for addition of row indices.
    explicit TableView(ConstTableRef parent);
    TableView(const Query& query, size_t limit);
    TableView(ConstTableRef parent, ColKey column, const Obj& obj);
    TableView(LinkCollectionPtr&& collection);

    /// Copy constructor.
    TableView(const TableView&);

    /// Move constructor.
    TableView(TableView&&) noexcept;

    TableView& operator=(const TableView&);
    TableView& operator=(TableView&&) noexcept;

    TableView(TableView& source, Transaction* tr, PayloadPolicy mode);

    ~TableView() {}

    TableRef get_parent() const noexcept
    {
        return m_table.cast_away_const();
    }

    TableRef get_target_table() const final
    {
        return m_table.cast_away_const();
    }
    size_t size() const final
    {
        return m_key_values.size();
    }
    bool is_empty() const noexcept
    {
        return m_key_values.size() == 0;
    }

    // Tells if the table that this TableView points at still exists or has been deleted.
    bool is_attached() const noexcept
    {
        return bool(m_table);
    }

    ObjKey get_key(size_t ndx) const final
    {
        return m_key_values.get(ndx);
    }

    bool is_obj_valid(size_t ndx) const noexcept
    {
        return m_table->is_valid(get_key(ndx));
    }

    Obj get_object(size_t ndx) const noexcept final
    {
        REALM_ASSERT(ndx < size());
        ObjKey key(m_key_values.get(ndx));
        return m_table->try_get_object(key);
    }

    // Get the query used to create this TableView
    // The query will have a null source table if this tv was not created from
    // a query
    const std::optional<Query>& get_query() const noexcept
    {
        return m_query;
    }

    void clear();

    // Change the TableView to be backed by another query
    // only works if the TableView is already backed by a query, and both
    // queries points to the same Table
    void update_query(const Query& q);

    std::unique_ptr<TableView> clone() const
    {
        return std::unique_ptr<TableView>(new TableView(*this));
    }

    LinkCollectionPtr clone_obj_list() const final
    {
        return std::unique_ptr<TableView>(new TableView(*this));
    }

    // import_copy_of() machinery entry points based on dynamic type. These methods:
    // a) forward their calls to the static type entry points.
    // b) new/delete patch data structures.
    std::unique_ptr<TableView> clone_for_handover(Transaction* tr, PayloadPolicy mode)
    {
        std::unique_ptr<TableView> retval(new TableView(*this, tr, mode));
        return retval;
    }
    template <Action action, typename T>
    Mixed aggregate(ColKey column_key, size_t* result_count = nullptr, ObjKey* return_key = nullptr) const;
    template <typename T>
    size_t aggregate_count(ColKey column_key, T count_target) const;

    size_t count_int(ColKey column_key, int64_t target) const;
    size_t count_float(ColKey column_key, float target) const;
    size_t count_double(ColKey column_key, double target) const;
    size_t count_timestamp(ColKey column_key, Timestamp target) const;
    size_t count_decimal(ColKey column_key, Decimal128 target) const;
    size_t count_mixed(ColKey column_key, Mixed target) const;

    /// Get the min element, according to whatever comparison function is
    /// meaningful for the collection, or none if min is not supported for this type.
    util::Optional<Mixed> min(ColKey column_key, ObjKey* return_key = nullptr) const;

    /// Get the max element, according to whatever comparison function is
    /// meaningful for the collection, or none if max is not supported for this type.
    util::Optional<Mixed> max(ColKey column_key, ObjKey* return_key = nullptr) const;

    /// For collections of arithmetic types, return the sum of all elements.
    /// For non arithmetic types, returns none.
    util::Optional<Mixed> sum(ColKey column_key) const;

    /// For collections of arithmetic types, return the average of all elements.
    /// For non arithmetic types, returns none.
    util::Optional<Mixed> avg(ColKey column_key, size_t* value_count = nullptr) const;

    /// Search this view for the specified key. If found, the index of that row
    /// within this view is returned, otherwise `realm::not_found` is returned.
    size_t find_by_source_ndx(ObjKey key) const noexcept
    {
        return m_key_values.find_first(key);
    }

    // Conversion
    void to_json(std::ostream&, size_t link_depth = 0, const std::map<std::string, std::string>& renames = {},
                 JSONOutputMode mode = output_mode_json) const;

    // Determine if the view is 'in sync' with the underlying table
    // as well as other views used to generate the view. Note that updates
    // through views maintains synchronization between view and table.
    // It doesnt by itself maintain other views as well. So if a view
    // is generated from another view (not a table), updates may cause
    // that view to be outdated, AND as the generated view depends upon
    // it, it too will become outdated.
    bool is_in_sync() const final;

    // A TableView is frozen if it is a) obtained from a query against a frozen table
    // and b) is synchronized (is_in_sync())
    bool is_frozen()
    {
        return m_table->is_frozen() && is_in_sync();
    }
    // Tells if this TableView depends on a LinkList or row that has been deleted.
    bool depends_on_deleted_object() const;

    // Synchronize a view to match a table or tableview from which it
    // has been derived. Synchronization is achieved by rerunning the
    // query used to generate the view. If derived from another view, that
    // view will be synchronized as well.
    //
    // "live" or "reactive" views are implemented by calling sync_if_needed()
    // before any of the other access-methods whenever the view may have become
    // outdated.
    void sync_if_needed() const final;
    // Return the version of the source it was created from.
    TableVersions get_dependency_versions() const
    {
        TableVersions ret;
        get_dependencies(ret);
        return ret;
    }

    bool has_changed() const
    {
        return m_last_seen_versions != get_dependency_versions();
    }

    // Sort m_key_values according to one column
    void sort(ColKey column, bool ascending = true);

    // Sort m_key_values according to multiple columns
    void sort(SortDescriptor order);

    // Get the number of total results which have been filtered out because a number of "LIMIT" operations have
    // been applied. This number only applies to the last sync.
    size_t get_num_results_excluded_by_limit() const noexcept
    {
        return m_limit_count;
    }

    // Remove rows that are duplicated with respect to the column set passed as argument.
    // distinct() will preserve the original order of the row pointers, also if the order is a result of sort()
    // If two rows are identical (for the given set of distinct-columns), then the last row is removed.
    // You can call sync_if_needed() to update the distinct view, just like you can for a sorted view.
    // Each time you call distinct() it will compound on the previous calls
    void distinct(ColKey column);
    void distinct(DistinctDescriptor columns);
    void limit(LimitDescriptor limit);

    // Replace the order of sort and distinct operations, bypassing manually
    // calling sort and distinct. This is a convenience method for bindings.
    void apply_descriptor_ordering(const DescriptorOrdering& new_ordering);

    // Gets a readable and parsable string which completely describes the sort and
    // distinct operations applied to this view.
    std::string get_descriptor_ordering_description() const;

    // Returns whether the rows are guaranteed to be in table order.
    // This is true only of unsorted TableViews created from either:
    // - Table::find_all()
    // - Query::find_all() when the query is not restricted to a view.
    bool is_in_table_order() const;

    bool is_backlink_view() const
    {
        return m_source_column_key != ColKey();
    }

protected:
    // This TableView can be "born" from 4 different sources:
    // - LinkView
    // - Query::find_all()
    // - Table::get_distinct_view()
    // - Table::get_backlink_view()

    void get_dependencies(TableVersions&) const final;

    void do_sync();
    void do_sort(const DescriptorOrdering&);

    mutable ConstTableRef m_table;
    // The source column index that this view contain backlinks for.
    ColKey m_source_column_key;
    // The target object that rows in this view link to.
    Obj m_linked_obj;

    // If this TableView was created from an Object Collection, then this reference points to it. Otherwise it's 0
    mutable LinkCollectionPtr m_collection_source;

    // Stores the ordering criteria of applied sort and distinct operations.
    DescriptorOrdering m_descriptor_ordering;
    size_t m_limit_count = 0;

    // A valid query holds a reference to its table which must match our m_table.
    std::optional<Query> m_query;
    // parameters for findall, needed to rerun the query
    size_t m_limit = size_t(-1);

    // FIXME: This class should eventually be replaced by std::vector<ObjKey>
    // It implements a vector of ObjKey, where the elements are held in the
    // heap (default allocator is the only option)
    class KeyValues : public KeyColumn {
    public:
        KeyValues()
            : KeyColumn(Allocator::get_default())
        {
        }
        KeyValues(const KeyValues&) = delete;
        ~KeyValues()
        {
            destroy();
        }
        void move_from(KeyValues&);
        void copy_from(const KeyValues&);
    };

    mutable TableVersions m_last_seen_versions;
    KeyValues m_key_values;

private:
    ObjKey find_first_integer(ColKey column_key, int64_t value) const;
    template <Action action>
    std::optional<Mixed> aggregate(ColKey column_key, size_t* count, ObjKey* return_key) const;

    util::RaceDetector m_race_detector;

    friend class Table;
    friend class Obj;
    friend class Query;
    friend class DB;
    friend class ObjList;
    friend class LnkLst;
};


// ================================================================================================
// TableView Implementation:

inline TableView::TableView(ConstTableRef parent)
    : m_table(parent) // Throws
{
    m_key_values.create();
    if (m_table) {
        m_last_seen_versions.emplace_back(m_table->get_key(), m_table->get_content_version());
    }
}

inline TableView::TableView(const Query& query, size_t lim)
    : m_table(query.get_table())
    , m_query(query)
    , m_limit(lim)
{
    m_key_values.create();
    REALM_ASSERT(query.m_table);
}

inline TableView::TableView(ConstTableRef src_table, ColKey src_column_key, const Obj& obj)
    : m_table(src_table) // Throws
    , m_source_column_key(src_column_key)
    , m_linked_obj(obj)
{
    m_key_values.create();
    if (m_table) {
        m_last_seen_versions.emplace_back(m_table->get_key(), m_table->get_content_version());
        m_last_seen_versions.emplace_back(obj.get_table()->get_key(), obj.get_table()->get_content_version());
    }
}

inline TableView::TableView(LinkCollectionPtr&& collection)
    : m_table(collection->get_target_table()) // Throws
    , m_collection_source(std::move(collection))
{
    REALM_ASSERT(m_collection_source);
    m_key_values.create();
    if (m_table) {
        m_last_seen_versions.emplace_back(m_table->get_key(), m_table->get_content_version());
    }
}

inline TableView::TableView(const TableView& tv)
    : m_table(tv.m_table)
    , m_source_column_key(tv.m_source_column_key)
    , m_linked_obj(tv.m_linked_obj)
    , m_collection_source(tv.m_collection_source ? tv.m_collection_source->clone_obj_list() : LinkCollectionPtr{})
    , m_descriptor_ordering(tv.m_descriptor_ordering)
    , m_query(tv.m_query)
    , m_limit(tv.m_limit)
    , m_last_seen_versions(tv.m_last_seen_versions)
{
    m_key_values.copy_from(tv.m_key_values);
    m_limit_count = tv.m_limit_count;
}

inline TableView::TableView(TableView&& tv) noexcept
    : m_table(tv.m_table)
    , m_source_column_key(tv.m_source_column_key)
    , m_linked_obj(tv.m_linked_obj)
    , m_collection_source(std::move(tv.m_collection_source))
    , m_descriptor_ordering(std::move(tv.m_descriptor_ordering))
    , m_query(std::move(tv.m_query))
    , m_limit(tv.m_limit)
    // if we are created from a table view which is outdated, take care to use the outdated
    // version number so that we can later trigger a sync if needed.
    , m_last_seen_versions(std::move(tv.m_last_seen_versions))
{
    m_key_values.move_from(tv.m_key_values);
    m_limit_count = tv.m_limit_count;
}

inline TableView& TableView::operator=(TableView&& tv) noexcept
{
    m_table = std::move(tv.m_table);

    m_key_values.move_from(tv.m_key_values);
    m_query = std::move(tv.m_query);
    m_last_seen_versions = tv.m_last_seen_versions;
    m_limit = tv.m_limit;
    m_limit_count = tv.m_limit_count;
    m_source_column_key = tv.m_source_column_key;
    m_linked_obj = tv.m_linked_obj;
    m_collection_source = std::move(tv.m_collection_source);
    m_descriptor_ordering = std::move(tv.m_descriptor_ordering);

    return *this;
}

inline TableView& TableView::operator=(const TableView& tv)
{
    if (this == &tv)
        return *this;

    m_key_values.copy_from(tv.m_key_values);

    m_query = tv.m_query;
    m_last_seen_versions = tv.m_last_seen_versions;
    m_limit = tv.m_limit;
    m_limit_count = tv.m_limit_count;
    m_source_column_key = tv.m_source_column_key;
    m_linked_obj = tv.m_linked_obj;
    m_collection_source = tv.m_collection_source ? tv.m_collection_source->clone_obj_list() : LinkCollectionPtr{};
    m_descriptor_ordering = tv.m_descriptor_ordering;

    return *this;
}

} // namespace realm

#endif // REALM_TABLE_VIEW_HPP
