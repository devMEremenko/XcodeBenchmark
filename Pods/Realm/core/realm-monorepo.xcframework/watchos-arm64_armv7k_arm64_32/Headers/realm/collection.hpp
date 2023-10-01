#ifndef REALM_COLLECTION_HPP
#define REALM_COLLECTION_HPP

#include <realm/obj.hpp>
#include <realm/bplustree.hpp>
#include <realm/obj_list.hpp>
#include <realm/table.hpp>

#include <iosfwd>      // std::ostream
#include <type_traits> // std::void_t

namespace realm {

template <class L>
struct CollectionIterator;

/// Base class for all collection accessors.
///
/// Collections are bound to particular properties of an object. In a
/// collection's public interface, the implementation must take care to keep the
/// object consistent with the persisted state, mindful of the fact that the
/// state may have changed as a consequence of modifications from other instances
/// referencing the same persisted state.
class CollectionBase {
public:
    virtual ~CollectionBase() {}

    /// The size of the collection.
    virtual size_t size() const = 0;

    /// True if the element at @a ndx is NULL.
    virtual bool is_null(size_t ndx) const = 0;

    /// Get element at @a ndx as a `Mixed`.
    virtual Mixed get_any(size_t ndx) const = 0;

    /// Clear the collection.
    virtual void clear() = 0;

    /// Get the min element, according to whatever comparison function is
    /// meaningful for the collection, or none if min is not supported for this type.
    virtual util::Optional<Mixed> min(size_t* return_ndx = nullptr) const = 0;

    /// Get the max element, according to whatever comparison function is
    /// meaningful for the collection, or none if max is not supported for this type.
    virtual util::Optional<Mixed> max(size_t* return_ndx = nullptr) const = 0;

    /// For collections of arithmetic types, return the sum of all elements.
    /// For non arithmetic types, returns none.
    virtual util::Optional<Mixed> sum(size_t* return_cnt = nullptr) const = 0;

    /// For collections of arithmetic types, return the average of all elements.
    /// For non arithmetic types, returns none.
    virtual util::Optional<Mixed> avg(size_t* return_cnt = nullptr) const = 0;

    /// Produce a clone of the collection accessor referring to the same
    /// underlying memory.
    virtual std::unique_ptr<CollectionBase> clone_collection() const = 0;

    /// Modifies a vector of indices so that they refer to values sorted
    /// according to the specified sort order.
    virtual void sort(std::vector<size_t>& indices, bool ascending = true) const = 0;

    /// Modifies a vector of indices so that they refer to distinct values. If
    /// @a sort_order is supplied, the indices will refer to values in sort
    /// order, otherwise the indices will be in the same order as they appear in
    /// the collection.
    virtual void distinct(std::vector<size_t>& indices, util::Optional<bool> sort_order = util::none) const = 0;

    // Return index of the first occurrence of 'value'
    virtual size_t find_any(Mixed value) const = 0;

    /// True if `size()` returns 0.
    virtual bool is_empty() const final
    {
        return size() == 0;
    }

    /// Get the object that owns this collection.
    virtual const Obj& get_obj() const noexcept = 0;

    /// Get the column key for this collection.
    virtual ColKey get_col_key() const noexcept = 0;

    /// Return true if the collection has changed since the last call to
    /// `has_changed()`. Note that this function is not idempotent and updates
    /// the internal state of the accessor if it has changed.
    virtual bool has_changed() const = 0;

    /// Returns true if the accessor is in the attached state. By default, this
    /// checks if the owning object is still valid.
    virtual bool is_attached() const
    {
        return get_obj().is_valid();
    }

    // Note: virtual..final prevents static override.

    /// Get the key of the object that owns this collection.
    virtual ObjKey get_owner_key() const noexcept final
    {
        return get_obj().get_key();
    }

    /// Get the table of the object that owns this collection.
    virtual ConstTableRef get_table() const noexcept final
    {
        return get_obj().get_table();
    }

    /// If this is a collection of links, get the target table.
    virtual TableRef get_target_table() const final
    {
        return get_obj().get_target_table(get_col_key());
    }

    virtual size_t translate_index(size_t ndx) const noexcept
    {
        return ndx;
    }

    StringData get_property_name() const
    {
        return get_table()->get_column_name(get_col_key());
    }

protected:
    friend class Transaction;
    CollectionBase() noexcept = default;
    CollectionBase(const CollectionBase&) noexcept = default;
    CollectionBase(CollectionBase&&) noexcept = default;
    CollectionBase& operator=(const CollectionBase&) noexcept = default;
    CollectionBase& operator=(CollectionBase&&) noexcept = default;

    void validate_index(const char* msg, size_t index, size_t size) const;
};

inline std::string_view collection_type_name(ColKey col, bool uppercase = false)
{
    if (col.is_list())
        return uppercase ? "List" : "list";
    if (col.is_set())
        return uppercase ? "Set" : "set";
    if (col.is_dictionary())
        return uppercase ? "Dictionary" : "dictionary";
    return "";
}

inline void CollectionBase::validate_index(const char* msg, size_t index, size_t size) const
{
    if (index >= size) {
        throw OutOfBounds(util::format("%1 on %2 '%3.%4'", msg, collection_type_name(get_col_key()),
                                       get_table()->get_class_name(), get_property_name()),
                          index, size);
    }
}


template <class T>
inline void check_column_type(ColKey col)
{
    if (col && col.get_type() != ColumnTypeTraits<T>::column_id) {
        throw InvalidColumnKey();
    }
}

template <>
inline void check_column_type<Int>(ColKey col)
{
    if (col && (col.get_type() != col_type_Int || col.get_attrs().test(col_attr_Nullable))) {
        throw InvalidColumnKey();
    }
}

template <>
inline void check_column_type<util::Optional<Int>>(ColKey col)
{
    if (col && (col.get_type() != col_type_Int || !col.get_attrs().test(col_attr_Nullable))) {
        throw InvalidColumnKey();
    }
}

template <>
inline void check_column_type<ObjKey>(ColKey col)
{
    if (col) {
        bool is_link_list = (col.get_type() == col_type_LinkList);
        bool is_link_set = (col.is_set() && col.get_type() == col_type_Link);
        if (!(is_link_list || is_link_set))
            throw InvalidArgument(ErrorCodes::TypeMismatch, "Property not a list or set");
    }
}

template <class T, class = void>
struct MinHelper {
    template <class U>
    static util::Optional<Mixed> eval(U&, size_t*) noexcept
    {
        return util::none;
    }
    static util::Optional<Mixed> not_found(size_t*) noexcept
    {
        return util::none;
    }
};

template <class T>
struct MinHelper<T, std::void_t<ColumnMinMaxType<T>>> {
    template <class U>
    static util::Optional<Mixed> eval(U& tree, size_t* return_ndx)
    {
        auto optional_min = bptree_minimum<T>(tree, return_ndx);
        if (optional_min) {
            return Mixed{*optional_min};
        }
        return Mixed{};
    }
    static util::Optional<Mixed> not_found(size_t* return_ndx) noexcept
    {
        if (return_ndx)
            *return_ndx = realm::not_found;
        return Mixed{};
    }
};

template <class T, class Enable = void>
struct MaxHelper {
    template <class U>
    static util::Optional<Mixed> eval(U&, size_t*) noexcept
    {
        return util::none;
    }
    static util::Optional<Mixed> not_found(size_t*) noexcept
    {
        return util::none;
    }
};

template <class T>
struct MaxHelper<T, std::void_t<ColumnMinMaxType<T>>> {
    template <class U>
    static util::Optional<Mixed> eval(U& tree, size_t* return_ndx)
    {
        auto optional_max = bptree_maximum<T>(tree, return_ndx);
        if (optional_max) {
            return Mixed{*optional_max};
        }
        return Mixed{};
    }
    static util::Optional<Mixed> not_found(size_t* return_ndx) noexcept
    {
        if (return_ndx)
            *return_ndx = realm::not_found;
        return Mixed{};
    }
};

template <class T, class Enable = void>
class SumHelper {
public:
    template <class U>
    static util::Optional<Mixed> eval(U&, size_t* return_cnt) noexcept
    {
        if (return_cnt)
            *return_cnt = 0;
        return util::none;
    }
    static util::Optional<Mixed> not_found(size_t*) noexcept
    {
        return util::none;
    }
};

template <class T>
class SumHelper<T, std::void_t<ColumnSumType<T>>> {
public:
    template <class U>
    static util::Optional<Mixed> eval(U& tree, size_t* return_cnt)
    {
        return Mixed{bptree_sum<T>(tree, return_cnt)};
    }
    static util::Optional<Mixed> not_found(size_t* return_cnt) noexcept
    {
        if (return_cnt)
            *return_cnt = 0;
        using ResultType = typename aggregate_operations::Sum<typename util::RemoveOptional<T>::type>::ResultType;
        return Mixed{ResultType{}};
    }
};

template <class T, class = void>
struct AverageHelper {
    template <class U>
    static util::Optional<Mixed> eval(U&, size_t* return_cnt) noexcept
    {
        if (return_cnt)
            *return_cnt = 0;
        return util::none;
    }
    static util::Optional<Mixed> not_found(size_t*) noexcept
    {
        return util::none;
    }
};

template <class T>
struct AverageHelper<T, std::void_t<ColumnSumType<T>>> {
    template <class U>
    static util::Optional<Mixed> eval(U& tree, size_t* return_cnt)
    {
        size_t count = 0;
        auto result = Mixed{bptree_average<T>(tree, &count)};
        if (return_cnt) {
            *return_cnt = count;
        }
        return count == 0 ? util::none : result;
    }
    static util::Optional<Mixed> not_found(size_t* return_cnt) noexcept
    {
        if (return_cnt)
            *return_cnt = 0;
        return Mixed{};
    }
};

/// Convenience base class for collections, which implements most of the
/// relevant interfaces for a collection that is bound to an object accessor and
/// representable as a BPlusTree<T>.
template <class Interface>
class CollectionBaseImpl : public Interface, protected ArrayParent {
public:
    static_assert(std::is_base_of_v<CollectionBase, Interface>);

    // Overriding members of CollectionBase:
    ColKey get_col_key() const noexcept final
    {
        return m_col_key;
    }

    const Obj& get_obj() const noexcept final
    {
        return m_obj;
    }


    /// Returns true if the accessor has changed since the last time
    /// `has_changed()` was called.
    ///
    /// Note: This method is not idempotent.
    ///
    /// Note: This involves a call to `update_if_needed()`.
    ///
    /// Note: This function does not return true for an accessor that became
    /// detached since the last call, even though it may look to the caller as
    /// if the size of the collection suddenly became zero.
    bool has_changed() const final
    {
        // `has_changed()` sneakily modifies internal state.
        update_if_needed();
        if (m_last_content_version != m_content_version) {
            m_last_content_version = m_content_version;
            return true;
        }
        return false;
    }

    using Interface::get_owner_key;
    using Interface::get_table;
    using Interface::get_target_table;

    bool operator==(const CollectionBaseImpl& other) const noexcept
    {
        return get_table() == other.get_table() && get_owner_key() == other.get_owner_key() &&
               get_col_key() == other.get_col_key();
    }

    bool operator!=(const CollectionBaseImpl& other) const noexcept
    {
        return !(*this == other);
    }

protected:
    Obj m_obj;
    ColKey m_col_key;
    bool m_nullable = false;

    mutable uint_fast64_t m_content_version = 0;

    // Content version used by `has_changed()`.
    mutable uint_fast64_t m_last_content_version = 0;

    CollectionBaseImpl() = default;
    CollectionBaseImpl(const CollectionBaseImpl& other) = default;
    CollectionBaseImpl(CollectionBaseImpl&& other) = default;

    CollectionBaseImpl(const Obj& obj, ColKey col_key) noexcept
        : m_obj(obj)
        , m_col_key(col_key)
        , m_nullable(col_key.is_nullable())
    {
    }

    CollectionBaseImpl& operator=(const CollectionBaseImpl& other) = default;
    CollectionBaseImpl& operator=(CollectionBaseImpl&& other) = default;

    /// Refresh the associated `Obj` (if needed), and update the internal
    /// content version number. This is meant to be called from a derived class
    /// before accessing its data.
    ///
    /// If the `Obj` changed since the last call, or the content version was
    /// bumped, this returns `UpdateStatus::Updated`. In response, the caller
    /// must invoke `init_from_parent()` or similar on its internal state
    /// accessors to refresh its view of the data.
    ///
    /// If the owning object (or parent container) was deleted, this returns
    /// `UpdateStatus::Detached`, and the caller is allowed to enter a
    /// degenerate state.
    ///
    /// If no change has happened to the data, this function returns
    /// `UpdateStatus::NoChange`, and the caller is allowed to not do anything.
    virtual UpdateStatus update_if_needed() const
    {
        UpdateStatus status = m_obj.update_if_needed_with_status();

        if (status != UpdateStatus::Detached) {
            auto content_version = m_obj.get_alloc().get_content_version();
            if (content_version != m_content_version) {
                m_content_version = content_version;
                status = UpdateStatus::Updated;
            }
        }

        return status;
    }

    /// Refresh the associated `Obj` (if needed) and ensure that the
    /// collection is created. Must be used in places where you
    /// modify a potentially detached collection.
    ///
    /// The caller must react to the `UpdateStatus` in the same way as with
    /// `update_if_needed()`, i.e., eventually end up calling
    /// `init_from_parent()` or similar.
    ///
    /// Throws if the owning object no longer exists. Note: This means that this
    /// method will never return `UpdateStatus::Detached`.
    virtual UpdateStatus ensure_created()
    {
        bool changed = m_obj.update_if_needed(); // Throws if the object does not exist.
        auto content_version = m_obj.get_alloc().get_content_version();

        if (changed || content_version != m_content_version) {
            m_content_version = content_version;
            return UpdateStatus::Updated;
        }
        return UpdateStatus::NoChange;
    }

    void bump_content_version()
    {
        m_content_version = m_obj.bump_content_version();
    }

    /// Reset the accessor's tracking of the content version. Derived classes
    /// may choose to call this to force the accessor to become out of date,
    /// such that `update_if_needed()` returns `UpdateStatus::Updated` the next
    /// time it is called (or `UpdateStatus::Detached` if the data vanished in
    /// the meantime).
    void reset_content_version()
    {
        m_content_version = 0;
    }

    // Overriding ArrayParent interface:
    ref_type get_child_ref(size_t child_ndx) const noexcept final
    {
        static_cast<void>(child_ndx);
        try {
            return to_ref(m_obj._get<int64_t>(m_col_key.get_index()));
        }
        catch (const KeyNotFound&) {
            return ref_type(0);
        }
    }

    void update_child_ref(size_t child_ndx, ref_type new_ref) final
    {
        static_cast<void>(child_ndx);
        m_obj.set_int(m_col_key, from_ref(new_ref));
    }
};

namespace _impl {
/// Translate from condensed index to uncondensed index in collections that hide
/// tombstones.
size_t virtual2real(const std::vector<size_t>& vec, size_t ndx) noexcept;
size_t virtual2real(const BPlusTree<ObjKey>* tree, size_t ndx) noexcept;

/// Translate from uncondensed index to condensed into in collections that hide
/// tombstones.
size_t real2virtual(const std::vector<size_t>& vec, size_t ndx) noexcept;

/// Rebuild the list of unresolved keys for tombstone handling.
void update_unresolved(std::vector<size_t>& vec, const BPlusTree<ObjKey>* tree);

/// Clear the context flag on the tree if there are no more unresolved links.
void check_for_last_unresolved(BPlusTree<ObjKey>* tree);

/// Proxy class needed because the ObjList interface clobbers method names from
/// CollectionBase.
struct ObjListProxy : ObjList {
    virtual TableRef proxy_get_target_table() const = 0;

    TableRef get_target_table() const final
    {
        return proxy_get_target_table();
    }
};

} // namespace _impl

/// Base class for collections of objects, where unresolved links (tombstones)
/// can occur.
template <class Interface>
class ObjCollectionBase : public Interface, public _impl::ObjListProxy {
public:
    static_assert(std::is_base_of_v<CollectionBase, Interface>);

    using Interface::get_col_key;
    using Interface::get_obj;
    using Interface::get_table;
    using Interface::is_attached;
    using Interface::size;

    // Overriding methods in ObjList:

    void get_dependencies(TableVersions& versions) const final
    {
        if (is_attached()) {
            auto table = this->get_table();
            versions.emplace_back(table->get_key(), table->get_content_version());
        }
    }

    void sync_if_needed() const final
    {
        update_if_needed();
    }

    bool is_in_sync() const noexcept final
    {
        return true;
    }

    bool has_unresolved() const noexcept
    {
        update_if_needed();
        return m_unresolved.size() != 0;
    }

    using Interface::get_target_table;

protected:
    ObjCollectionBase() = default;
    ObjCollectionBase(const ObjCollectionBase&) = default;
    ObjCollectionBase(ObjCollectionBase&&) = default;
    ObjCollectionBase& operator=(const ObjCollectionBase&) = default;
    ObjCollectionBase& operator=(ObjCollectionBase&&) = default;

    /// Implementations should call `update_if_needed()` on their inner accessor
    /// (without `update_unresolved()`).
    virtual UpdateStatus do_update_if_needed() const = 0;

    /// Implementations should return a non-const reference to their internal
    /// `BPlusTree<T>`.
    virtual BPlusTree<ObjKey>* get_mutable_tree() const = 0;

    /// Implements update_if_needed() in a way that ensures the consistency of
    /// the unresolved list. Derived classes should call this instead of calling
    /// `update_if_needed()` on their inner accessor.
    UpdateStatus update_if_needed() const
    {
        auto status = do_update_if_needed();
        update_unresolved(status);
        return status;
    }

    /// Translate from condensed index to uncondensed.
    size_t virtual2real(size_t ndx) const noexcept
    {
        return _impl::virtual2real(m_unresolved, ndx);
    }

    /// Translate from uncondensed index to condensed.
    size_t real2virtual(size_t ndx) const noexcept
    {
        return _impl::real2virtual(m_unresolved, ndx);
    }

    /// Rebuild the list of tombstones if there is a possibility that it has
    /// changed.
    ///
    /// If the accessor became detached, this clears the unresolved list.
    void update_unresolved(UpdateStatus status) const
    {
        switch (status) {
            case UpdateStatus::Detached: {
                clear_unresolved();
                break;
            }
            case UpdateStatus::Updated: {
                _impl::update_unresolved(m_unresolved, get_mutable_tree());
                break;
            }
            case UpdateStatus::NoChange:
                break;
        }
    }

    /// When a tombstone is removed from a list, call this to update internal
    /// flags that indicate the presence of tombstones.
    void check_for_last_unresolved()
    {
        _impl::check_for_last_unresolved(get_mutable_tree());
    }

    /// Clear the list of tombstones. It will be rebuilt the next time
    /// `update_if_needed()` is called.
    void clear_unresolved() const noexcept
    {
        m_unresolved.clear();
    }

    /// Return the number of tombstones.
    size_t num_unresolved() const noexcept
    {
        return m_unresolved.size();
    }

private:
    // Sorted set of indices containing unresolved links.
    mutable std::vector<size_t> m_unresolved;

    TableRef proxy_get_target_table() const final
    {
        return Interface::get_target_table();
    }
    bool matches(const ObjList& other) const final
    {
        return get_owning_obj().get_key() == other.get_owning_obj().get_key() &&
               get_owning_col_key() == other.get_owning_col_key();
    }
    Obj get_owning_obj() const final
    {
        return get_obj();
    }
    ColKey get_owning_col_key() const final
    {
        return get_col_key();
    }
};

/// Random-access iterator over elements of a collection.
///
/// Values are cached into a member variable in order to support `operator->`
/// and `operator*` returning a pointer and a reference, respectively.
template <class L>
struct CollectionIterator {
    using iterator_category = std::random_access_iterator_tag;
    using value_type = typename L::value_type;
    using difference_type = ptrdiff_t;
    using pointer = const value_type*;
    using reference = const value_type&;

    CollectionIterator(const L* l, size_t ndx) noexcept
        : m_list(l)
        , m_ndx(ndx)
    {
    }

    pointer operator->() const
    {
        m_val = m_list->get(m_ndx);
        return &m_val;
    }

    reference operator*() const
    {
        return *operator->();
    }

    CollectionIterator& operator++() noexcept
    {
        ++m_ndx;
        return *this;
    }

    CollectionIterator operator++(int) noexcept
    {
        auto tmp = *this;
        operator++();
        return tmp;
    }

    CollectionIterator& operator--() noexcept
    {
        --m_ndx;
        return *this;
    }

    CollectionIterator operator--(int) noexcept
    {
        auto tmp = *this;
        operator--();
        return tmp;
    }

    CollectionIterator& operator+=(ptrdiff_t n) noexcept
    {
        m_ndx += n;
        return *this;
    }

    CollectionIterator& operator-=(ptrdiff_t n) noexcept
    {
        m_ndx -= n;
        return *this;
    }

    friend ptrdiff_t operator-(const CollectionIterator& lhs, const CollectionIterator& rhs) noexcept
    {
        return ptrdiff_t(lhs.m_ndx) - ptrdiff_t(rhs.m_ndx);
    }

    friend CollectionIterator operator+(CollectionIterator lhs, ptrdiff_t rhs) noexcept
    {
        lhs.m_ndx += rhs;
        return lhs;
    }

    friend CollectionIterator operator+(ptrdiff_t lhs, CollectionIterator rhs) noexcept
    {
        return rhs + lhs;
    }

    bool operator!=(const CollectionIterator& rhs) const noexcept
    {
        REALM_ASSERT_DEBUG(m_list == rhs.m_list);
        return m_ndx != rhs.m_ndx;
    }

    bool operator==(const CollectionIterator& rhs) const noexcept
    {
        REALM_ASSERT_DEBUG(m_list == rhs.m_list);
        return m_ndx == rhs.m_ndx;
    }

    size_t index() const noexcept
    {
        return m_ndx;
    }

private:
    mutable value_type m_val;
    const L* m_list;
    size_t m_ndx = size_t(-1);
};

namespace _impl {
size_t get_collection_size_from_ref(ref_type, Allocator& alloc);
}

} // namespace realm

#endif // REALM_COLLECTION_HPP
