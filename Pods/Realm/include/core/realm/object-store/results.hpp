////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#ifndef REALM_RESULTS_HPP
#define REALM_RESULTS_HPP

#include <realm/object-store/collection_notifications.hpp>
#include <realm/object-store/dictionary.hpp>
#include <realm/object-store/impl/collection_notifier.hpp>
#include <realm/object-store/list.hpp>
#include <realm/object-store/object.hpp>
#include <realm/object-store/object_schema.hpp>
#include <realm/object-store/property.hpp>
#include <realm/object-store/set.hpp>
#include <realm/object-store/shared_realm.hpp>
#include <realm/object-store/util/copyable_atomic.hpp>

#include <realm/table_view.hpp>
#include <realm/util/checked_mutex.hpp>
#include <realm/util/optional.hpp>

namespace realm {
class Mixed;
class SectionedResults;

namespace _impl {
class ResultsNotifierBase;
}

class Results {
public:
    // Results can be either be backed by nothing, a thin wrapper around a table,
    // or a wrapper around a query and a sort order which creates and updates
    // the tableview as needed
    Results();
    Results(std::shared_ptr<Realm> r, ConstTableRef table);
    Results(std::shared_ptr<Realm> r, Query q, DescriptorOrdering o = {});
    Results(std::shared_ptr<Realm> r, TableView tv, DescriptorOrdering o = {});
    Results(std::shared_ptr<Realm> r, std::shared_ptr<CollectionBase> list, DescriptorOrdering o);
    Results(std::shared_ptr<Realm> r, std::shared_ptr<CollectionBase> collection, util::Optional<Query> q = {},
            SortDescriptor s = {});
    ~Results();

    // Results is copyable and moveable
    Results(Results&&);
    Results& operator=(Results&&);
    Results(const Results&);
    Results& operator=(const Results&);

    // Get the Realm
    const std::shared_ptr<Realm>& get_realm() const
    {
        return m_realm;
    }

    // Object schema describing the vendored object type
    const ObjectSchema& get_object_schema() const REQUIRES(!m_mutex);

    // Get the table of the vendored object type
    ConstTableRef get_table() const REQUIRES(!m_mutex);

    // Get a query which will match the same rows as is contained in this Results
    // Returned query will not be valid if the current mode is Empty
    Query get_query() const REQUIRES(!m_mutex);

    // Get ordering for the query associated with the result
    const DescriptorOrdering& get_ordering() const;

    // Get the Collection this Results is derived from, if any
    const std::shared_ptr<CollectionBase>& get_collection() const
    {
        return m_collection;
    }

    // Get the list of sort and distinct operations applied for this Results.
    DescriptorOrdering const& get_descriptor_ordering() const noexcept
    {
        return m_descriptor_ordering;
    }

    // Get a tableview containing the same rows as this Results
    TableView get_tableview() REQUIRES(!m_mutex);

    // Get the object type which will be returned by get()
    StringData get_object_type() const noexcept;

    PropertyType get_type() const REQUIRES(!m_mutex);

    // Get the size of this results
    // Can be either O(1) or O(N) depending on the state of things
    size_t size() REQUIRES(!m_mutex);

    // Get the row accessor for the given index
    // Throws OutOfBoundsIndexException if index >= size()
    template <typename T = Obj>
    T get(size_t index) REQUIRES(!m_mutex);

    // Get an element in a list
    Mixed get_any(size_t index) REQUIRES(!m_mutex);

    // Get the key/value pair at an index of the results.
    // This method is only valid when applied to a results based on a
    // object_store::Dictionary::get_values(), and will assert this.
    std::pair<StringData, Mixed> get_dictionary_element(size_t index) REQUIRES(!m_mutex);

    // Get the boxed row accessor for the given index
    // Throws OutOfBoundsIndexException if index >= size()
    template <typename Context>
    auto get(Context&, size_t index) REQUIRES(!m_mutex);

    // Get a row accessor for the first/last row, or none if the results are empty
    // More efficient than calling size()+get()
    template <typename T = Obj>
    util::Optional<T> first() REQUIRES(!m_mutex);
    template <typename T = Obj>
    util::Optional<T> last() REQUIRES(!m_mutex);

    // Get the index of the first row matching the query in this table
    size_t index_of(Query&& q) REQUIRES(!m_mutex);

    // Get the first index of the given value in this results, or not_found
    // Throws DetachedAccessorException if row is not attached
    // Throws IncorrectTableException if row belongs to a different table
    template <typename T>
    size_t index_of(T const& value) REQUIRES(!m_mutex);

    // Delete all of the rows in this Results from the Realm
    // size() will always be zero afterwards
    // Throws InvalidTransactionException if not in a write transaction
    void clear() REQUIRES(!m_mutex);

    // Create a new Results by further filtering or sorting this Results
    Results filter(Query&& q) const REQUIRES(!m_mutex);
    // Create a new Results by sorting this Result.
    Results sort(SortDescriptor&& sort) const REQUIRES(!m_mutex);
    // Create a new Results by sorting this Result based on the specified key paths.
    Results sort(std::vector<std::pair<std::string, bool>> const& keypaths) const REQUIRES(!m_mutex);

    // Create a new Results by removing duplicates.
    Results distinct(DistinctDescriptor&& uniqueness) const REQUIRES(!m_mutex);
    // Create a new Results by removing duplicates based on the specified key paths.
    Results distinct(std::vector<std::string> const& keypaths) const REQUIRES(!m_mutex);

    // Create a new Results with only the first `max_count` entries
    Results limit(size_t max_count) const REQUIRES(!m_mutex);

    // Create a new Results by adding sort and distinct combinations
    Results apply_ordering(DescriptorOrdering&& ordering) REQUIRES(!m_mutex);

    // Return a snapshot of this Results that never updates to reflect changes in the underlying data.
    // A snapshot can still change if modified explicitly. The problem that a snapshot solves is that
    // a collection of links may change in unexpected ways if the destination objects are removed.
    // It’s unintuitive that users can accidentally modify the collection, e.g. when deleting
    // the object from the Realm. This would work just fine with an in-memory collection but fail
    // with Realm collections that are not snapshotted.
    // Since snapshots only account for links to objects, using snapshot on a collection of
    // primitive values has no effect.
    Results snapshot() const& REQUIRES(!m_mutex);
    Results snapshot() && REQUIRES(!m_mutex);

    // Returns a frozen copy of this result
    // Equivalent to producing a thread-safe reference and resolving it in the frozen realm.
    Results freeze(std::shared_ptr<Realm> const& frozen_realm) REQUIRES(!m_mutex);

    // Returns whether or not this Results is frozen.
    bool is_frozen() const REQUIRES(!m_mutex);

    // Get the min/max/average/sum of the given column
    // All but sum() returns none when there are zero matching rows
    // sum() returns 0, except for when it returns none
    // Throws UnsupportedColumnTypeException for sum/average on timestamp or non-numeric column
    // Throws OutOfBoundsIndexException for an out-of-bounds column
    util::Optional<Mixed> max(ColKey column = {}) REQUIRES(!m_mutex);
    util::Optional<Mixed> min(ColKey column = {}) REQUIRES(!m_mutex);
    util::Optional<Mixed> average(ColKey column = {}) REQUIRES(!m_mutex);
    util::Optional<Mixed> sum(ColKey column = {}) REQUIRES(!m_mutex);

    util::Optional<Mixed> max(StringData column_name) REQUIRES(!m_mutex)
    {
        return max(key(column_name));
    }
    util::Optional<Mixed> min(StringData column_name) REQUIRES(!m_mutex)
    {
        return min(key(column_name));
    }
    util::Optional<Mixed> average(StringData column_name) REQUIRES(!m_mutex)
    {
        return average(key(column_name));
    }
    util::Optional<Mixed> sum(StringData column_name) REQUIRES(!m_mutex)
    {
        return sum(key(column_name));
    }

    enum class Mode {
        // A default-constructed Results which is backed by nothing. This
        // behaves as if it was backed by an empty table/collection, and is
        // inteded for read-only Realms which are missing tables.
        Empty,
        // Backed directly by a Table with no sort/filter/distinct.
        Table,
        // Backed by a Collection, possibly with sort/distinct (but no filter).
        // Collections of Objects with a sort/distinct will transition to
        // TableView the first time they're accessed, while collections of other
        // types will remain in mode Collection and apply sort/distinct via
        // m_list_indices.
        Collection,
        // Backed by a Query that has not yet been run. May have sort and distinct.
        // Switches to mode TableView as soon as the query has to be run for
        // the first time, except for size() with no distinct, which gets the
        // count from the Query directly.
        Query,
        // Backed by a TableView of some sort, which encompases things like
        // sort and distinct
        TableView,
    };
    // Get the current mode of the Results
    // Ideally this would not be public but it's needed for some KVO stuff
    Mode get_mode() const noexcept REQUIRES(!m_mutex);

    // Is this Results associated with a Realm that has not been invalidated?
    bool is_valid() const;

    /**
     * Create an async query from this Results
     * The query will be run on a background thread and delivered to the callback,
     * and then rerun after each commit (if needed) and redelivered if it changed
     *
     * @param callback The function to execute when a insertions, modification or deletion in this `Collection` was
     * detected.
     * @param key_path_array A filter that can be applied to make sure the `CollectionChangeCallback` is only executed
     * when the property in the filter is changed but not otherwise.
     *
     * @return A `NotificationToken` that is used to identify this callback. This token can be used to remove the
     * callback via `remove_callback`.
     */
    NotificationToken add_notification_callback(CollectionChangeCallback callback,
                                                std::optional<KeyPathArray> key_path_array = std::nullopt) &;

    // Returns whether the rows are guaranteed to be in table order.
    bool is_in_table_order() const;

    template <typename Context>
    auto first(Context&) REQUIRES(!m_mutex);
    template <typename Context>
    auto last(Context&) REQUIRES(!m_mutex);

    template <typename Context, typename T>
    size_t index_of(Context&, T value) REQUIRES(!m_mutex);

    // Batch updates all items in this collection with the provided value
    // Must be called inside a transaction
    // Throws an exception if the value does not match the type for given prop_name
    template <typename ValueType, typename ContextType>
    void set_property_value(ContextType& ctx, StringData prop_name, ValueType value) REQUIRES(!m_mutex);

    // Execute the query immediately if needed. When the relevant query is slow, size()
    // may cost similar time compared with creating the tableview. Use this function to
    // avoid running the query twice for size() and other accessors.
    void evaluate_query_if_needed(bool wants_notifications = true) REQUIRES(!m_mutex);

    enum class UpdatePolicy {
        Auto,      // Update automatically to reflect changes in the underlying data.
        AsyncOnly, // Only update via ResultsNotifier and never run queries synchronously
        Never,     // Never update.
    };
    // For tests only. Use snapshot() for normal uses.
    void set_update_policy(UpdatePolicy policy)
    {
        m_update_policy = policy;
    }

    /**
     * Creates a SectionedResults object by using a user defined sectioning algorithm to project the key for each
     * section.
     *
     * @param section_key_func The callback to be iterated on each value in the underlying Results.
     * This callback must return a value which defines the section key
     *
     * @return A SectionedResults object using a user defined sectioning algorithm.
     */
    SectionedResults sectioned_results(
        util::UniqueFunction<Mixed(Mixed value, const std::shared_ptr<Realm>& realm)>&& section_key_func);
    enum class SectionedResultsOperator {
        FirstLetter // Section by the first letter of each string element. Note that col must be a string.
    };

    /**
     * Creates a SectionedResults object by using a built in sectioning algorithm to help with efficiency and reduce
     * overhead from the SDK level.
     *
     * @param op The `SectionedResultsOperator` operator to use
     * @param property_name Takes a property name if sectioning on a collection of links, the property name needs to
     * reference the column being sectioned on.
     *
     * @return A SectionedResults object with results sectioned based on the chosen built in operator.
     */
    SectionedResults sectioned_results(SectionedResultsOperator op,
                                       util::Optional<StringData> property_name = util::none);

private:
    std::shared_ptr<Realm> m_realm;
    mutable util::CopyableAtomic<const ObjectSchema*> m_object_schema = nullptr;
    Query m_query GUARDED_BY(m_mutex);
    ConstTableRef m_table;
    TableView m_table_view GUARDED_BY(m_mutex);
    DescriptorOrdering m_descriptor_ordering;
    std::shared_ptr<CollectionBase> m_collection;
    util::Optional<std::vector<size_t>> m_list_indices GUARDED_BY(m_mutex);

    _impl::CollectionNotifier::Handle<_impl::ResultsNotifierBase> m_notifier;

    Mode m_mode GUARDED_BY(m_mutex) = Mode::Empty;
    friend class SectionedResults;
    UpdatePolicy m_update_policy = UpdatePolicy::Auto;
    uint64_t m_last_collection_content_version GUARDED_BY(m_mutex) = 0;

    void validate_read() const;
    void validate_write() const;

    size_t do_size() REQUIRES(m_mutex);
    Query do_get_query() const REQUIRES(m_mutex);
    PropertyType do_get_type() const REQUIRES(m_mutex);

    using ForCallback = util::TaggedBool<class ForCallback>;
    void prepare_async(ForCallback);

    ColKey key(StringData) const;
    size_t actual_index(size_t) const noexcept REQUIRES(m_mutex);

    template <typename T>
    util::Optional<T> try_get(size_t) REQUIRES(m_mutex);

    template <typename AggregateFunction>
    util::Optional<Mixed> aggregate(ColKey column, const char* name, AggregateFunction&& func) REQUIRES(!m_mutex);

    template <typename Fn>
    auto dispatch(Fn&&) const REQUIRES(!m_mutex);

    enum class EvaluateMode { Count, Snapshot, Normal };
    /// Returns true if the underlying table_view or collection has changed, and is waiting
    /// for `ensure_up_to_date` to run.
    bool has_changed() REQUIRES(!m_mutex);
    void ensure_up_to_date(EvaluateMode mode = EvaluateMode::Normal) REQUIRES(m_mutex);

    // Shared logic between freezing and thawing Results as the Core API is the same.
    Results import_copy_into_realm(std::shared_ptr<Realm> const& realm) REQUIRES(!m_mutex);

    class IteratorWrapper {
    public:
        IteratorWrapper() = default;
        IteratorWrapper(IteratorWrapper const&);
        IteratorWrapper& operator=(IteratorWrapper const&);
        IteratorWrapper(IteratorWrapper&&) = default;
        IteratorWrapper& operator=(IteratorWrapper&&) = default;

        Obj get(Table const& table, size_t ndx);

    private:
        std::unique_ptr<Table::Iterator> m_it;
    } m_table_iterator;

    util::CheckedOptionalMutex m_mutex;

    // A work around for what appears to be a false positive in clang's thread
    // analysis when constructing a different object of the same type within a
    // member function. Putting the ACQUIRE on the constructor seems like it
    // should work, but doesn't.
    void assert_unlocked() ACQUIRE(!m_mutex) {}
};

template <typename Fn>
auto Results::dispatch(Fn&& fn) const
{
    return switch_on_type(get_type(), std::forward<Fn>(fn));
}

template <typename Context>
auto Results::get(Context& ctx, size_t row_ndx)
{
    return dispatch([&](auto t) {
        return ctx.box(this->get<std::decay_t<decltype(*t)>>(row_ndx));
    });
}

template <typename Context>
auto Results::first(Context& ctx)
{
    // GCC 4.9 complains about `ctx` not being defined within the lambda without this goofy capture
    return dispatch([this, ctx = &ctx](auto t) {
        auto value = this->first<std::decay_t<decltype(*t)>>();
        return value ? static_cast<decltype(ctx->no_value())>(ctx->box(std::move(*value))) : ctx->no_value();
    });
}

template <typename Context>
auto Results::last(Context& ctx)
{
    return dispatch([&](auto t) {
        auto value = this->last<std::decay_t<decltype(*t)>>();
        return value ? static_cast<decltype(ctx.no_value())>(ctx.box(std::move(*value))) : ctx.no_value();
    });
}

template <>
size_t Results::index_of(Obj const& obj);
template <>
size_t Results::index_of(Mixed const& value);

template <typename T>
inline size_t Results::index_of(T const& value)
{
    return index_of(Mixed(value));
}

template <typename Context, typename T>
size_t Results::index_of(Context& ctx, T value)
{
    return dispatch([&](auto t) {
        return this->index_of(ctx.template unbox<std::decay_t<decltype(*t)>>(value, CreatePolicy::Skip));
    });
}

template <typename ValueType, typename ContextType>
void Results::set_property_value(ContextType& ctx, StringData prop_name, ValueType value) NO_THREAD_SAFETY_ANALYSIS
{
    // Check invariants for calling this method
    validate_write();
    const ObjectSchema& object_schema = get_object_schema();
    const Property* prop = object_schema.property_for_name(prop_name);
    if (!prop) {
        throw InvalidPropertyException(object_schema.name, prop_name);
    }
    if (prop->is_primary && !m_realm->is_in_migration()) {
        throw ModifyPrimaryKeyException(object_schema.name, prop->name);
    }

    // Update all objects in this ResultSets. Use snapshot to avoid correctness problems if the
    // object is removed from the TableView after the property update as well as avoiding to
    // re-evaluating the query too many times.
    auto snapshot = this->snapshot();
    size_t size = snapshot.size();
    for (size_t i = 0; i < size; ++i) {
        Object obj(m_realm, *m_object_schema, snapshot.get(i));
        obj.set_property_value_impl(ctx, *prop, value, CreatePolicy::ForceCreate, false);
    }
}

} // namespace realm

#endif // REALM_RESULTS_HPP
