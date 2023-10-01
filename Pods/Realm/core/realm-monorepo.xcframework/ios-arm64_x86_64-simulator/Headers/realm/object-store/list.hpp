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

#ifndef REALM_OS_LIST_HPP
#define REALM_OS_LIST_HPP

#include <realm/object-store/collection.hpp>

#include <realm/decimal128.hpp>
#include <realm/list.hpp>
#include <realm/mixed.hpp>
#include <realm/object_id.hpp>

#include <functional>
#include <memory>

namespace realm {
class Obj;
class Query;
class ThreadSafeReference;
struct ColKey;
struct ObjKey;

class List : public object_store::Collection {
public:
    using object_store::Collection::Collection;
    List()
        : Collection(PropertyType::Array)
    {
    }

    List(const List&);
    List& operator=(const List&);
    List(List&&);
    List& operator=(List&&);

    Query get_query() const;
    ConstTableRef get_table() const;

    void move(size_t source_ndx, size_t dest_ndx);
    void remove(size_t list_ndx);
    void remove_all();
    void swap(size_t ndx1, size_t ndx2);
    void delete_at(size_t list_ndx);
    void delete_all();

    template <typename T = Obj>
    T get(size_t row_ndx) const;

    template <typename T>
    size_t find(T const& value) const;

    // Find the index in the List of the first row matching the query
    size_t find(Query&& query) const;

    template <typename T>
    void add(T value);
    template <typename T>
    void insert(size_t list_ndx, T value);
    template <typename T>
    void set(size_t row_ndx, T value);

    void insert_any(size_t list_ndx, Mixed value);
    void set_any(size_t list_ndx, Mixed value);
    Mixed get_any(size_t list_ndx) const final;
    size_t find_any(Mixed value) const final;

    Results filter(Query q) const;

    // Returns a frozen copy of this List.
    // Equivalent to producing a thread-safe reference and resolving it in the frozen realm.
    List freeze(std::shared_ptr<Realm> const& frozen_realm) const;

    bool operator==(List const& rgt) const noexcept;

    template <typename Context>
    auto get(Context&, size_t row_ndx) const;
    template <typename T, typename Context>
    size_t find(Context&, T&& value) const;

    template <typename T, typename Context>
    void add(Context&, T&& value, CreatePolicy = CreatePolicy::SetLink);
    template <typename T, typename Context>
    void insert(Context&, size_t list_ndx, T&& value, CreatePolicy = CreatePolicy::SetLink);
    template <typename T, typename Context>
    void set(Context&, size_t row_ndx, T&& value, CreatePolicy = CreatePolicy::SetLink);

    Obj add_embedded();
    Obj set_embedded(size_t list_ndx);
    Obj insert_embedded(size_t list_ndx);

    Obj get_object(size_t list_ndx);

    // Replace the values in this list with the values from an enumerable object
    template <typename T, typename Context>
    void assign(Context&, T&& value, CreatePolicy = CreatePolicy::SetLink);

private:
    const char* type_name() const noexcept override
    {
        return "List";
    }

    LstBase& list_base() const noexcept
    {
        REALM_ASSERT_DEBUG(dynamic_cast<LstBase*>(m_coll_base.get()));
        return static_cast<LstBase&>(*m_coll_base);
    }

    template <typename Fn>
    auto dispatch(Fn&&) const;
    template <typename T>
    auto& as() const;

    template <typename T, typename Context>
    void set_if_different(Context&, size_t row_ndx, T&& value, CreatePolicy);

    friend struct std::hash<List>;
};

template <>
Obj List::get(size_t row_ndx) const;

template <typename T>
auto& List::as() const
{
    REALM_ASSERT_DEBUG(dynamic_cast<Lst<T>*>(m_coll_base.get()));
    return static_cast<Lst<T>&>(*m_coll_base);
}

template <>
inline auto& List::as<Obj>() const
{
    REALM_ASSERT_DEBUG(dynamic_cast<LnkLst*>(m_coll_base.get()));
    return static_cast<LnkLst&>(*m_coll_base);
}

template <>
inline auto& List::as<ObjKey>() const
{
    REALM_ASSERT_DEBUG(dynamic_cast<LnkLst*>(m_coll_base.get()));
    return static_cast<LnkLst&>(*m_coll_base);
}

template <typename Fn>
auto List::dispatch(Fn&& fn) const
{
    verify_attached();
    return switch_on_type(get_type(), std::forward<Fn>(fn));
}

template <typename Context>
auto List::get(Context& ctx, size_t row_ndx) const
{
    return dispatch([&](auto t) {
        return ctx.box(this->get<std::decay_t<decltype(*t)>>(row_ndx));
    });
}

template <typename T, typename Context>
size_t List::find(Context& ctx, T&& value) const
{
    return dispatch([&](auto t) {
        return this->find(ctx.template unbox<std::decay_t<decltype(*t)>>(value, CreatePolicy::Skip));
    });
}

template <typename T, typename Context>
void List::add(Context& ctx, T&& value, CreatePolicy policy)
{
    if (m_is_embedded) {
        validate_embedded(ctx, value, policy);
        auto key = as<Obj>().create_and_insert_linked_object(size()).get_key();
        ctx.template unbox<Obj>(value, policy, key);
        return;
    }
    dispatch([&](auto t) {
        this->add(ctx.template unbox<std::decay_t<decltype(*t)>>(value, policy));
    });
}

template <typename T, typename Context>
void List::insert(Context& ctx, size_t list_ndx, T&& value, CreatePolicy policy)
{
    if (m_is_embedded) {
        validate_embedded(ctx, value, policy);
        auto key = as<Obj>().create_and_insert_linked_object(list_ndx).get_key();
        ctx.template unbox<Obj>(value, policy, key);
        return;
    }
    dispatch([&](auto t) {
        this->insert(list_ndx, ctx.template unbox<std::decay_t<decltype(*t)>>(value, policy));
    });
}

template <typename T, typename Context>
void List::set(Context& ctx, size_t list_ndx, T&& value, CreatePolicy policy)
{
    if (m_is_embedded) {
        validate_embedded(ctx, value, policy);

        auto& list = as<Obj>();
        auto key = policy.diff ? list.get(list_ndx) : list.create_and_set_linked_object(list_ndx).get_key();
        ctx.template unbox<Obj>(value, policy, key);
        return;
    }
    dispatch([&](auto t) {
        this->set(list_ndx, ctx.template unbox<std::decay_t<decltype(*t)>>(value, policy));
    });
}

template <typename T, typename Context>
void List::set_if_different(Context& ctx, size_t row_ndx, T&& value, CreatePolicy policy)
{
    if (m_is_embedded) {
        validate_embedded(ctx, value, policy);
        auto key = policy.diff ? this->get<Obj>(row_ndx) : as<Obj>().create_and_set_linked_object(row_ndx);
        ctx.template unbox<Obj>(value, policy, key.get_key());
        return;
    }
    dispatch([&](auto t) {
        using U = std::decay_t<decltype(*t)>;
        if constexpr (std::is_same_v<U, Obj>) {
            auto old_value = this->get<U>(row_ndx);
            auto new_value = ctx.template unbox<U>(value, policy, old_value.get_key());
            if (new_value.get_key() != old_value.get_key())
                this->set(row_ndx, new_value);
        }
        else {
            auto old_value = this->get<U>(row_ndx);
            auto new_value = ctx.template unbox<U>(value, policy);
            if (old_value != new_value)
                this->set(row_ndx, new_value);
        }
    });
}

template <typename T, typename Context>
void List::assign(Context& ctx, T&& values, CreatePolicy policy)
{
    if (ctx.is_same_list(*this, values))
        return;

    if (ctx.is_null(values)) {
        remove_all();
        return;
    }

    if (!policy.diff)
        remove_all();

    size_t sz = size();
    size_t index = 0;
    ctx.enumerate_collection(values, [&](auto&& element) {
        if (index >= sz)
            this->add(ctx, element, policy);
        else if (policy.diff)
            this->set_if_different(ctx, index, element, policy);
        else
            this->set(ctx, index, element, policy);
        index++;
    });
    while (index < sz)
        remove(--sz);
}
} // namespace realm

namespace std {
template <>
struct hash<realm::List> {
    size_t operator()(realm::List const&) const;
};
} // namespace std

#endif // REALM_OS_LIST_HPP
