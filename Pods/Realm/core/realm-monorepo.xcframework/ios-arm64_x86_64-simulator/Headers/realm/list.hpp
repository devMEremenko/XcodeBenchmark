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

#ifndef REALM_LIST_HPP
#define REALM_LIST_HPP

#include <realm/collection.hpp>

#include <realm/obj.hpp>
#include <realm/bplustree.hpp>
#include <realm/obj_list.hpp>
#include <realm/array_basic.hpp>
#include <realm/array_integer.hpp>
#include <realm/array_key.hpp>
#include <realm/array_bool.hpp>
#include <realm/array_string.hpp>
#include <realm/array_binary.hpp>
#include <realm/array_timestamp.hpp>
#include <realm/array_ref.hpp>
#include <realm/array_fixed_bytes.hpp>
#include <realm/array_decimal128.hpp>
#include <realm/array_mixed.hpp>
#include <realm/array_typed_link.hpp>
#include <realm/replication.hpp>

namespace realm {

class TableView;
class SortDescriptor;
class Group;
template <class>
class Lst;

template <class T>
using LstIterator = CollectionIterator<Lst<T>>;

/*
 * This class defines a virtual interface to a writable list
 */
class LstBase : public CollectionBase {
public:
    using CollectionBase::CollectionBase;

    virtual ~LstBase() {}
    virtual LstBasePtr clone() const = 0;
    virtual void set_null(size_t ndx) = 0;
    virtual void set_any(size_t ndx, Mixed val) = 0;
    virtual void insert_null(size_t ndx) = 0;
    virtual void insert_any(size_t ndx, Mixed val) = 0;
    virtual void resize(size_t new_size) = 0;
    virtual void remove(size_t from, size_t to) = 0;
    virtual void move(size_t from, size_t to) = 0;
    virtual void swap(size_t ndx1, size_t ndx2) = 0;

protected:
    void swap_repl(Replication* repl, size_t ndx1, size_t ndx2) const;
};

template <class T>
class Lst final : public CollectionBaseImpl<LstBase> {
public:
    using Base = CollectionBaseImpl<LstBase>;
    using iterator = LstIterator<T>;
    using value_type = T;

    Lst() = default;
    Lst(const Obj& owner, ColKey col_key);
    Lst(const Lst& other);
    Lst(Lst&&) noexcept;
    Lst& operator=(const Lst& other);
    Lst& operator=(Lst&& other) noexcept;

    iterator begin() const noexcept
    {
        return iterator{this, 0};
    }

    iterator end() const noexcept
    {
        return iterator{this, size()};
    }

    T get(size_t ndx) const;
    size_t find_first(const T& value) const;
    T set(size_t ndx, T value);
    void insert(size_t ndx, T value);
    T remove(size_t ndx);

    // Overriding members of CollectionBase:
    size_t size() const final;
    void clear() final;
    Mixed get_any(size_t ndx) const final;
    bool is_null(size_t ndx) const final;
    CollectionBasePtr clone_collection() const final;
    util::Optional<Mixed> min(size_t* return_ndx = nullptr) const final;
    util::Optional<Mixed> max(size_t* return_ndx = nullptr) const final;
    util::Optional<Mixed> sum(size_t* return_cnt = nullptr) const final;
    util::Optional<Mixed> avg(size_t* return_cnt = nullptr) const final;
    void sort(std::vector<size_t>& indices, bool ascending = true) const final;
    void distinct(std::vector<size_t>& indices, util::Optional<bool> sort_order = util::none) const final;

    // Overriding members of LstBase:
    LstBasePtr clone() const final;
    void set_null(size_t ndx) final;
    void set_any(size_t ndx, Mixed val) final;
    void insert_null(size_t ndx) final;
    void insert_any(size_t ndx, Mixed val) final;
    size_t find_any(Mixed val) const final;
    void resize(size_t new_size) final;
    void remove(size_t from, size_t to) final;
    void move(size_t from, size_t to) final;
    void swap(size_t ndx1, size_t ndx2) final;

    // Lst<T> interface:
    T remove(const iterator& it);

    void add(T value)
    {
        insert(size(), std::move(value));
    }

    T operator[](size_t ndx) const
    {
        return this->get(ndx);
    }

    template <typename Func>
    void find_all(value_type value, Func&& func) const
    {
        if (update()) {
            if constexpr (std::is_same_v<T, Mixed>) {
                if (value.is_null()) {
                    // if value is null then we find also all the unresolved links with a O(n lg n) scan
                    find_all_mixed_unresolved_links(std::forward<Func>(func));
                }
            }
            m_tree->find_all(value, std::forward<Func>(func));
        }
    }

    inline const BPlusTree<T>& get_tree() const
    {
        return *m_tree;
    }

    UpdateStatus update_if_needed() const final
    {
        auto status = Base::update_if_needed();
        switch (status) {
            case UpdateStatus::Detached: {
                m_tree.reset();
                return UpdateStatus::Detached;
            }
            case UpdateStatus::NoChange:
                if (m_tree && m_tree->is_attached()) {
                    return UpdateStatus::NoChange;
                }
                // The tree has not been initialized yet for this accessor, so
                // perform lazy initialization by treating it as an update.
                [[fallthrough]];
            case UpdateStatus::Updated: {
                bool attached = init_from_parent(false);
                return attached ? UpdateStatus::Updated : UpdateStatus::Detached;
            }
        }
        REALM_UNREACHABLE();
    }

    UpdateStatus ensure_created() final
    {
        auto status = Base::ensure_created();
        switch (status) {
            case UpdateStatus::Detached:
                break; // Not possible (would have thrown earlier).
            case UpdateStatus::NoChange: {
                if (m_tree && m_tree->is_attached()) {
                    return UpdateStatus::NoChange;
                }
                // The tree has not been initialized yet for this accessor, so
                // perform lazy initialization by treating it as an update.
                [[fallthrough]];
            }
            case UpdateStatus::Updated: {
                bool attached = init_from_parent(true);
                REALM_ASSERT(attached);
                return attached ? UpdateStatus::Updated : UpdateStatus::Detached;
            }
        }

        REALM_UNREACHABLE();
    }

    /// Update the accessor and return true if it is attached after the update.
    inline bool update() const
    {
        return update_if_needed() != UpdateStatus::Detached;
    }

    size_t translate_index(size_t ndx) const noexcept override
    {
        if constexpr (std::is_same_v<T, ObjKey>) {
            return _impl::virtual2real(m_tree.get(), ndx);
        }
        else {
            return ndx;
        }
    }

protected:
    // Friend because it needs access to `m_tree` in the implementation of
    // `ObjCollectionBase::get_mutable_tree()`.
    friend class LnkLst;

    // `do_` methods here perform the action after preconditions have been
    // checked (bounds check, writability, etc.).
    void do_set(size_t ndx, T value);
    void do_insert(size_t ndx, T value);
    void do_remove(size_t ndx);
    void do_clear();

    // BPlusTree must be wrapped in an `std::unique_ptr` because it is not
    // default-constructible, due to its `Allocator&` member.
    mutable std::unique_ptr<BPlusTree<T>> m_tree;

    using Base::bump_content_version;
    using Base::m_col_key;
    using Base::m_nullable;
    using Base::m_obj;

    bool init_from_parent(bool allow_create) const
    {
        if (!m_tree) {
            m_tree.reset(new BPlusTree<T>(m_obj.get_alloc()));
            const ArrayParent* parent = this;
            m_tree->set_parent(const_cast<ArrayParent*>(parent), 0);
        }

        if (m_tree->init_from_parent()) {
            // All is well
            return true;
        }

        if (!allow_create) {
            return false;
        }

        // The ref in the column was NULL, create the tree in place.
        m_tree->create();
        REALM_ASSERT(m_tree->is_attached());
        return true;
    }

    template <class Func>
    void find_all_mixed_unresolved_links(Func&& func) const
    {
        for (size_t i = 0; i < m_tree->size(); ++i) {
            auto mixed = m_tree->get(i);
            if (mixed.is_unresolved_link()) {
                func(i);
            }
        }
    }

private:
    template <class U>
    static U unresolved_to_null(U value) noexcept
    {
        return value;
    }

    static Mixed unresolved_to_null(Mixed value) noexcept
    {
        if (value.is_type(type_TypedLink) && value.is_unresolved_link())
            return Mixed{};
        return value;
    }
    T do_get(size_t ndx, const char* msg) const;
};

// Specialization of Lst<ObjKey>:
template <>
void Lst<ObjKey>::do_set(size_t, ObjKey);
template <>
void Lst<ObjKey>::do_insert(size_t, ObjKey);
template <>
void Lst<ObjKey>::do_remove(size_t);
template <>
void Lst<ObjKey>::do_clear();

extern template class Lst<ObjKey>;

// Specialization of Lst<Mixed>:
template <>
void Lst<Mixed>::do_set(size_t, Mixed);
template <>
void Lst<Mixed>::do_insert(size_t, Mixed);
template <>
void Lst<Mixed>::do_remove(size_t);
template <>
void Lst<Mixed>::do_clear();
extern template class Lst<Mixed>;

// Specialization of Lst<ObjLink>:
template <>
void Lst<ObjLink>::do_set(size_t, ObjLink);
template <>
void Lst<ObjLink>::do_insert(size_t, ObjLink);
template <>
void Lst<ObjLink>::do_remove(size_t);
extern template class Lst<ObjLink>;

// Extern template declarations for lists of primitives:
extern template class Lst<int64_t>;
extern template class Lst<bool>;
extern template class Lst<StringData>;
extern template class Lst<BinaryData>;
extern template class Lst<Timestamp>;
extern template class Lst<float>;
extern template class Lst<double>;
extern template class Lst<Decimal128>;
extern template class Lst<ObjectId>;
extern template class Lst<UUID>;
extern template class Lst<util::Optional<int64_t>>;
extern template class Lst<util::Optional<bool>>;
extern template class Lst<util::Optional<float>>;
extern template class Lst<util::Optional<double>>;
extern template class Lst<util::Optional<ObjectId>>;
extern template class Lst<util::Optional<UUID>>;

class LnkLst final : public ObjCollectionBase<LstBase> {
public:
    using Base = ObjCollectionBase<LstBase>;
    using value_type = ObjKey;
    using iterator = CollectionIterator<LnkLst>;

    LnkLst() = default;

    LnkLst(const Obj& owner, ColKey col_key)
        : m_list(owner, col_key)
    {
    }

    LnkLst(const LnkLst& other) = default;
    LnkLst(LnkLst&& other) = default;
    LnkLst& operator=(const LnkLst& other) = default;
    LnkLst& operator=(LnkLst&& other) = default;
    bool operator==(const LnkLst& other) const;
    bool operator!=(const LnkLst& other) const;

    Obj operator[](size_t ndx) const
    {
        return get_object(ndx);
    }

    ObjKey get(size_t ndx) const;
    size_t find_first(const ObjKey&) const;
    void insert(size_t ndx, ObjKey value);
    ObjKey set(size_t ndx, ObjKey value);
    ObjKey remove(size_t ndx);

    void add(ObjKey value)
    {
        // FIXME: Should this add to the end of the unresolved list?
        insert(size(), value);
    }

    // Overriding members of CollectionBase:
    using CollectionBase::get_owner_key;
    size_t size() const final;
    bool is_null(size_t ndx) const final;
    Mixed get_any(size_t ndx) const final;
    void clear() final;
    util::Optional<Mixed> min(size_t* return_ndx = nullptr) const final;
    util::Optional<Mixed> max(size_t* return_ndx = nullptr) const final;
    util::Optional<Mixed> sum(size_t* return_cnt = nullptr) const final;
    util::Optional<Mixed> avg(size_t* return_cnt = nullptr) const final;
    std::unique_ptr<CollectionBase> clone_collection() const final;
    void sort(std::vector<size_t>& indices, bool ascending = true) const final;
    void distinct(std::vector<size_t>& indices, util::Optional<bool> sort_order = util::none) const final;
    const Obj& get_obj() const noexcept final;
    bool has_changed() const final;
    ColKey get_col_key() const noexcept final;

    // Overriding members of LstBase:
    std::unique_ptr<LstBase> clone() const
    {
        if (get_obj().is_valid()) {
            return std::make_unique<LnkLst>(get_obj(), get_col_key());
        }
        else {
            return std::make_unique<LnkLst>();
        }
    }
    // Overriding members of ObjList:
    LinkCollectionPtr clone_obj_list() const
    {
        if (get_obj().is_valid()) {
            return std::make_unique<LnkLst>(get_obj(), get_col_key());
        }
        else {
            return std::make_unique<LnkLst>();
        }
    }
    void set_null(size_t ndx) final;
    void set_any(size_t ndx, Mixed val) final;
    void insert_null(size_t ndx) final;
    void insert_any(size_t ndx, Mixed val) final;
    size_t find_any(Mixed value) const final;
    void resize(size_t new_size) final;
    void remove(size_t from, size_t to) final;
    void move(size_t from, size_t to) final;
    void swap(size_t ndx1, size_t ndx2) final;

    // Overriding members of ObjList:
    Obj get_object(size_t ndx) const final
    {
        ObjKey key = this->get(ndx);
        return get_target_table()->get_object(key);
    }
    ObjKey get_key(size_t ndx) const final
    {
        return get(ndx);
    }

    // LnkLst interface:

    std::unique_ptr<LnkLst> clone_linklist() const
    {
        // FIXME: The copy constructor requires this.
        update_if_needed();
        return std::make_unique<LnkLst>(*this);
    }

    template <class Func>
    void find_all(ObjKey value, Func&& func) const
    {
        if (value.is_unresolved())
            return;

        m_list.find_all(value, [&](size_t ndx) {
            func(real2virtual(ndx));
        });
    }

    // Create a new object in insert a link to it
    Obj create_and_insert_linked_object(size_t ndx);

    // Create a new object and link it. If an embedded object
    // is already set, it will be removed. TBD: If a non-embedded
    // object is already set, we throw LogicError (to prevent
    // dangling objects, since they do not delete automatically
    // if they are not embedded...)
    Obj create_and_set_linked_object(size_t ndx);

    // to be implemented:
    Obj clear_linked_object(size_t ndx);

    TableView get_sorted_view(SortDescriptor order) const;
    TableView get_sorted_view(ColKey column_key, bool ascending = true) const;
    void remove_target_row(size_t link_ndx);
    void remove_all_target_rows();

    iterator begin() const noexcept
    {
        return iterator{this, 0};
    }
    iterator end() const noexcept
    {
        return iterator{this, size()};
    }

    const BPlusTree<ObjKey>& get_tree() const
    {
        return m_list.get_tree();
    }

private:
    friend class TableView;
    friend class Query;

    Lst<ObjKey> m_list;

    // Overriding members of ObjCollectionBase:

    UpdateStatus do_update_if_needed() const final
    {
        return m_list.update_if_needed();
    }

    BPlusTree<ObjKey>* get_mutable_tree() const final
    {
        return m_list.m_tree.get();
    }
};


// Implementation:

inline void LstBase::swap_repl(Replication* repl, size_t ndx1, size_t ndx2) const
{
    if (ndx2 < ndx1)
        std::swap(ndx1, ndx2);
    repl->list_move(*this, ndx2, ndx1);
    if (ndx1 + 1 != ndx2)
        repl->list_move(*this, ndx1 + 1, ndx2);
}

template <class T>
inline Lst<T>::Lst(const Obj& obj, ColKey col_key)
    : Base(obj, col_key)
{
    if (!col_key.is_list()) {
        throw InvalidArgument(ErrorCodes::TypeMismatch, "Property not a list");
    }

    check_column_type<T>(m_col_key);
}

template <class T>
inline Lst<T>::Lst(const Lst& other)
    : Base(static_cast<const Base&>(other))
{
    // Reset the content version so we can rely on init_from_parent() being
    // called lazily when the accessor is used.
    Base::reset_content_version();
}

template <class T>
inline Lst<T>::Lst(Lst&& other) noexcept
    : Base(static_cast<Base&&>(other))
    , m_tree(std::exchange(other.m_tree, nullptr))
{
    if (m_tree) {
        m_tree->set_parent(this, 0);
    }
}

template <class T>
Lst<T>& Lst<T>::operator=(const Lst& other)
{
    Base::operator=(static_cast<const Base&>(other));

    if (this != &other) {
        // Just reset the pointer and rely on init_from_parent() being called
        // when the accessor is actually used.
        m_tree.reset();
        Base::reset_content_version();
    }

    return *this;
}

template <class T>
inline Lst<T>& Lst<T>::operator=(Lst&& other) noexcept
{
    Base::operator=(static_cast<Base&&>(other));

    if (this != &other) {
        m_tree = std::exchange(other.m_tree, nullptr);
        if (m_tree) {
            m_tree->set_parent(this, 0);
        }
    }

    return *this;
}

template <class T>
inline T Lst<T>::remove(const iterator& it)
{
    return remove(it.index());
}

template <class T>
inline size_t Lst<T>::size() const
{
    return update() ? m_tree->size() : 0;
}

template <class T>
inline bool Lst<T>::is_null(size_t ndx) const
{
    return m_nullable && value_is_null(get(ndx));
}

template <class T>
inline Mixed Lst<T>::get_any(size_t ndx) const
{
    return get(ndx);
}

template <class T>
inline void Lst<T>::do_set(size_t ndx, T value)
{
    m_tree->set(ndx, value);
}

template <class T>
inline void Lst<T>::do_insert(size_t ndx, T value)
{
    m_tree->insert(ndx, value);
}

template <class T>
inline void Lst<T>::do_remove(size_t ndx)
{
    m_tree->erase(ndx);
}

template <class T>
inline void Lst<T>::do_clear()
{
    m_tree->clear();
}

template <typename U>
inline Lst<U> Obj::get_list(ColKey col_key) const
{
    return Lst<U>(*this, col_key);
}

template <typename U>
inline LstPtr<U> Obj::get_list_ptr(ColKey col_key) const
{
    return std::make_unique<Lst<U>>(*this, col_key);
}

inline LnkLst Obj::get_linklist(ColKey col_key) const
{
    return LnkLst(*this, col_key);
}

inline LnkLstPtr Obj::get_linklist_ptr(ColKey col_key) const
{
    return std::make_unique<LnkLst>(*this, col_key);
}

inline LnkLst Obj::get_linklist(StringData col_name) const
{
    return get_linklist(get_column_key(col_name));
}

template <class T>
void Lst<T>::clear()
{
    if (size() > 0) {
        if (Replication* repl = this->m_obj.get_replication()) {
            repl->list_clear(*this);
        }
        do_clear();
        bump_content_version();
    }
}

template <class T>
inline CollectionBasePtr Lst<T>::clone_collection() const
{
    return std::make_unique<Lst<T>>(m_obj, m_col_key);
}

template <class T>
inline T Lst<T>::get(size_t ndx) const
{
    return do_get(ndx, "get()");
}

template <class T>
inline T Lst<T>::do_get(size_t ndx, const char* msg) const
{
    const auto current_size = size();
    CollectionBase::validate_index(msg, ndx, current_size);

    return unresolved_to_null(m_tree->get(ndx));
}

template <class T>
inline size_t Lst<T>::find_first(const T& value) const
{
    if (!update())
        return not_found;

    if constexpr (std::is_same_v<T, Mixed>) {
        if (value.is_null()) {
            auto ndx = m_tree->find_first(value);
            auto size = ndx == not_found ? m_tree->size() : ndx;
            for (size_t i = 0; i < size; ++i) {
                if (m_tree->get(i).is_unresolved_link())
                    return i;
            }
            return ndx;
        }
    }
    return m_tree->find_first(value);
}

template <class T>
inline util::Optional<Mixed> Lst<T>::min(size_t* return_ndx) const
{
    if (update()) {
        return MinHelper<T>::eval(*m_tree, return_ndx);
    }
    return MinHelper<T>::not_found(return_ndx);
}

template <class T>
inline util::Optional<Mixed> Lst<T>::max(size_t* return_ndx) const
{
    if (update()) {
        return MaxHelper<T>::eval(*m_tree, return_ndx);
    }
    return MaxHelper<T>::not_found(return_ndx);
}

template <class T>
inline util::Optional<Mixed> Lst<T>::sum(size_t* return_cnt) const
{
    if (update()) {
        return SumHelper<T>::eval(*m_tree, return_cnt);
    }
    return SumHelper<T>::not_found(return_cnt);
}

template <class T>
inline util::Optional<Mixed> Lst<T>::avg(size_t* return_cnt) const
{
    if (update()) {
        return AverageHelper<T>::eval(*m_tree, return_cnt);
    }
    return AverageHelper<T>::not_found(return_cnt);
}

template <class T>
inline LstBasePtr Lst<T>::clone() const
{
    return std::make_unique<Lst<T>>(m_obj, m_col_key);
}

template <class T>
inline void Lst<T>::set_null(size_t ndx)
{
    set(ndx, BPlusTree<T>::default_value(m_nullable));
}

template <class T>
void Lst<T>::set_any(size_t ndx, Mixed val)
{
    if constexpr (std::is_same_v<T, Mixed>) {
        set(ndx, val);
    }
    else {
        if (val.is_null()) {
            set_null(ndx);
        }
        else {
            set(ndx, val.get<typename util::RemoveOptional<T>::type>());
        }
    }
}

template <class T>
inline void Lst<T>::insert_null(size_t ndx)
{
    insert(ndx, BPlusTree<T>::default_value(m_nullable));
}

template <class T>
inline void Lst<T>::insert_any(size_t ndx, Mixed val)
{
    if constexpr (std::is_same_v<T, Mixed>) {
        insert(ndx, val);
    }
    else {
        if (val.is_null()) {
            insert_null(ndx);
        }
        else {
            insert(ndx, val.get<typename util::RemoveOptional<T>::type>());
        }
    }
}

template <class T>
size_t Lst<T>::find_any(Mixed val) const
{
    if constexpr (std::is_same_v<T, Mixed>) {
        return find_first(val);
    }
    else {
        if (val.is_null()) {
            return find_first(BPlusTree<T>::default_value(m_nullable));
        }
        else if (val.get_type() == ColumnTypeTraits<T>::id) {
            return find_first(val.get<typename util::RemoveOptional<T>::type>());
        }
        return realm::not_found;
    }
}

template <class T>
void Lst<T>::resize(size_t new_size)
{
    size_t current_size = size();
    while (new_size > current_size) {
        insert_null(current_size++);
    }
    remove(new_size, current_size);
    m_obj.bump_both_versions();
}

template <class T>
inline void Lst<T>::remove(size_t from, size_t to)
{
    while (from < to) {
        remove(--to);
    }
}

template <class T>
void Lst<T>::move(size_t from, size_t to)
{
    auto sz = size();
    CollectionBase::validate_index("move()", from, sz);
    CollectionBase::validate_index("move()", to, sz);

    if (from != to) {
        if (Replication* repl = this->m_obj.get_replication()) {
            repl->list_move(*this, from, to);
        }
        if (to > from) {
            to++;
        }
        else {
            from++;
        }
        // We use swap here as it handles the special case for StringData where
        // 'to' and 'from' points into the same array. In this case you cannot
        // set an entry with the result of a get from another entry in the same
        // leaf.
        m_tree->insert(to, BPlusTree<T>::default_value(m_nullable));
        m_tree->swap(from, to);
        m_tree->erase(from);

        bump_content_version();
    }
}

template <class T>
void Lst<T>::swap(size_t ndx1, size_t ndx2)
{
    auto sz = size();
    CollectionBase::validate_index("swap()", ndx1, sz);
    CollectionBase::validate_index("swap()", ndx2, sz);

    if (ndx1 != ndx2) {
        if (Replication* repl = this->m_obj.get_replication()) {
            LstBase::swap_repl(repl, ndx1, ndx2);
        }
        m_tree->swap(ndx1, ndx2);
        bump_content_version();
    }
}

template <class T>
T Lst<T>::set(size_t ndx, T value)
{
    if (value_is_null(value) && !m_nullable)
        throw InvalidArgument(ErrorCodes::PropertyNotNullable,
                              util::format("List: %1", CollectionBase::get_property_name()));

    // get will check for ndx out of bounds
    T old = do_get(ndx, "set()");
    if (Replication* repl = this->m_obj.get_replication()) {
        repl->list_set(*this, ndx, value);
    }
    if constexpr (std::is_same_v<T, Mixed>) {
        if (!(old.is_same_type(value) && old == value)) {
            do_set(ndx, value);
            bump_content_version();
        }
    }
    else {
        if (old != value) {
            do_set(ndx, value);
            bump_content_version();
        }
    }
    return old;
}

template <class T>
void Lst<T>::insert(size_t ndx, T value)
{
    if (value_is_null(value) && !m_nullable)
        throw InvalidArgument(ErrorCodes::PropertyNotNullable,
                              util::format("List: %1", CollectionBase::get_property_name()));

    auto sz = size();
    CollectionBase::validate_index("insert()", ndx, sz + 1);

    ensure_created();

    if (Replication* repl = this->m_obj.get_replication()) {
        repl->list_insert(*this, ndx, value, sz);
    }
    do_insert(ndx, value);
    bump_content_version();
}

template <class T>
T Lst<T>::remove(size_t ndx)
{
    // get will check for ndx out of bounds
    T old = do_get(ndx, "remove()");
    if (Replication* repl = this->m_obj.get_replication()) {
        repl->list_erase(*this, ndx);
    }

    do_remove(ndx);
    bump_content_version();
    return old;
}

inline bool LnkLst::operator==(const LnkLst& other) const
{
    return m_list == other.m_list;
}

inline bool LnkLst::operator!=(const LnkLst& other) const
{
    return m_list != other.m_list;
}

inline size_t LnkLst::size() const
{
    update_if_needed();
    return m_list.size() - num_unresolved();
}

inline bool LnkLst::is_null(size_t ndx) const
{
    update_if_needed();
    return m_list.is_null(virtual2real(ndx));
}

inline Mixed LnkLst::get_any(size_t ndx) const
{
    update_if_needed();
    auto obj_key = m_list.get(virtual2real(ndx));
    return ObjLink{get_target_table()->get_key(), obj_key};
}

inline void LnkLst::clear()
{
    m_list.clear();
    clear_unresolved();
}

inline util::Optional<Mixed> LnkLst::min(size_t* return_ndx) const
{
    static_cast<void>(return_ndx);
    REALM_TERMINATE("Not implemented yet");
}

inline util::Optional<Mixed> LnkLst::max(size_t* return_ndx) const
{
    static_cast<void>(return_ndx);
    REALM_TERMINATE("Not implemented yet");
}

inline util::Optional<Mixed> LnkLst::sum(size_t* return_cnt) const
{
    static_cast<void>(return_cnt);
    REALM_TERMINATE("Not implemented yet");
}

inline util::Optional<Mixed> LnkLst::avg(size_t* return_cnt) const
{
    static_cast<void>(return_cnt);
    REALM_TERMINATE("Not implemented yet");
}

inline std::unique_ptr<CollectionBase> LnkLst::clone_collection() const
{
    return clone_linklist();
}

inline void LnkLst::sort(std::vector<size_t>& indices, bool ascending) const
{
    static_cast<void>(indices);
    static_cast<void>(ascending);
    REALM_TERMINATE("Not implemented yet");
}

inline void LnkLst::distinct(std::vector<size_t>& indices, util::Optional<bool> sort_order) const
{
    static_cast<void>(indices);
    static_cast<void>(sort_order);
    REALM_TERMINATE("Not implemented yet");
}

inline const Obj& LnkLst::get_obj() const noexcept
{
    return m_list.get_obj();
}

inline bool LnkLst::has_changed() const
{
    return m_list.has_changed();
}

inline ColKey LnkLst::get_col_key() const noexcept
{
    return m_list.get_col_key();
}

inline void LnkLst::set_null(size_t ndx)
{
    update_if_needed();
    m_list.set_null(virtual2real(ndx));
}

inline void LnkLst::set_any(size_t ndx, Mixed val)
{
    update_if_needed();
    m_list.set_any(virtual2real(ndx), val);
}

inline void LnkLst::insert_null(size_t ndx)
{
    update_if_needed();
    m_list.insert_null(virtual2real(ndx));
}

inline void LnkLst::insert_any(size_t ndx, Mixed val)
{
    update_if_needed();
    m_list.insert_any(virtual2real(ndx), val);
}

inline size_t LnkLst::find_any(Mixed value) const
{
    if (value.is_null()) {
        return find_first(ObjKey());
    }
    if (value.get_type() == type_Link) {
        return find_first(value.get<ObjKey>());
    }
    else if (value.get_type() == type_TypedLink) {
        auto link = value.get_link();
        if (link.get_table_key() == get_target_table()->get_key()) {
            return find_first(link.get_obj_key());
        }
    }
    return realm::not_found;
}

inline void LnkLst::resize(size_t new_size)
{
    update_if_needed();
    m_list.resize(new_size + num_unresolved());
}

inline void LnkLst::remove(size_t from, size_t to)
{
    update_if_needed();
    m_list.remove(virtual2real(from), virtual2real(to));
    update_unresolved(UpdateStatus::Updated);
}

inline void LnkLst::move(size_t from, size_t to)
{
    update_if_needed();
    m_list.move(virtual2real(from), virtual2real(to));
}

inline void LnkLst::swap(size_t ndx1, size_t ndx2)
{
    update_if_needed();
    m_list.swap(virtual2real(ndx1), virtual2real(ndx2));
}

inline ObjKey LnkLst::get(size_t ndx) const
{
    const auto current_size = size();
    CollectionBase::validate_index("get()", ndx, current_size);
    return m_list.m_tree->get(virtual2real(ndx));
}

inline size_t LnkLst::find_first(const ObjKey& key) const
{
    if (key.is_unresolved())
        return not_found;

    size_t found = not_found;
    if (update_if_needed() != UpdateStatus::Detached) {
        found = m_list.m_tree->find_first(key);
    }

    return (found != not_found) ? real2virtual(found) : not_found;
}

inline void LnkLst::insert(size_t ndx, ObjKey value)
{
    REALM_ASSERT(!value.is_unresolved());
    if (get_target_table()->is_embedded() && value != ObjKey())
        throw IllegalOperation(
            util::format("Cannot insert an already managed object into list of embedded objects '%1.%2'",
                         get_table()->get_class_name(), CollectionBase::get_property_name()));

    update_if_needed();
    m_list.insert(virtual2real(ndx), value);
    update_unresolved(UpdateStatus::Updated);
}

inline ObjKey LnkLst::set(size_t ndx, ObjKey value)
{
    REALM_ASSERT(!value.is_unresolved());
    if (get_target_table()->is_embedded() && value != ObjKey())
        throw IllegalOperation(
            util::format("Cannot insert an already managed object into list of embedded objects '%1.%2'",
                         get_table()->get_class_name(), CollectionBase::get_property_name()));

    update_if_needed();
    ObjKey old = m_list.set(virtual2real(ndx), value);
    REALM_ASSERT(!old.is_unresolved());
    return old;
}

inline ObjKey LnkLst::remove(size_t ndx)
{
    update_if_needed();
    ObjKey old = m_list.remove(virtual2real(ndx));
    REALM_ASSERT(!old.is_unresolved());
    update_unresolved(UpdateStatus::Updated);
    return old;
}

} // namespace realm

#endif /* REALM_LIST_HPP */
