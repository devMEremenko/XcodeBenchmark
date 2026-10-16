////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#ifndef REALM_OS_SET_HPP
#define REALM_OS_SET_HPP

#include <realm/object-store/collection_notifications.hpp>
#include <realm/object-store/impl/collection_notifier.hpp>

#include <realm/object-store/object.hpp>
#include <realm/object-store/property.hpp>
#include <realm/object-store/collection.hpp>

#include <realm/set.hpp>

namespace realm {

namespace _impl {
class ListNotifier;
}

namespace object_store {

class Set : public Collection {
public:
    using Collection::Collection;
    Set()
        : Collection(PropertyType::Set)
    {
    }

    Set(const Set&);
    Set& operator=(const Set&);
    Set(Set&&);
    Set& operator=(Set&&);

    Query get_query() const;
    ConstTableRef get_table() const;

    template <class T>
    size_t find(const T&) const;
    template <class T>
    std::pair<size_t, bool> insert(T);
    template <class T>
    std::pair<size_t, bool> remove(const T&);

    template <class T, class Context>
    size_t find(Context&, const T&) const;

    // Find the index in the Set of the first row matching the query
    size_t find(Query&& query) const;

    template <class T, class Context>
    std::pair<size_t, bool> insert(Context&, T&& value, CreatePolicy = CreatePolicy::SetLink);
    template <class T, class Context>
    std::pair<size_t, bool> remove(Context&, T&&);

    std::pair<size_t, bool> insert_any(Mixed value);
    Mixed get_any(size_t ndx) const final;
    std::pair<size_t, bool> remove_any(Mixed value);
    size_t find_any(Mixed value) const final;

    void remove_all();
    void delete_all();

    // Replace the values in this set with the values from an enumerable object
    template <typename T, typename Context>
    void assign(Context&, T&& value, CreatePolicy = CreatePolicy::SetLink);

    template <typename Context>
    auto get(Context&, size_t row_ndx) const;
    template <typename T = Obj>
    T get(size_t row_ndx) const;

    Results filter(Query q) const;

    Set freeze(const std::shared_ptr<Realm>& realm) const;

    bool is_subset_of(const Collection& rhs) const;
    bool is_strict_subset_of(const Collection& rhs) const;
    bool is_superset_of(const Collection& rhs) const;
    bool is_strict_superset_of(const Collection& rhs) const;
    bool intersects(const Collection& rhs) const;
    bool set_equals(const Collection& rhs) const;

    void assign_intersection(const Collection& rhs);
    void assign_union(const Collection& rhs);
    void assign_difference(const Collection& rhs);
    void assign_symmetric_difference(const Collection& rhs);

    bool operator==(const Set& rhs) const noexcept;

private:
    const char* type_name() const noexcept override
    {
        return "Set";
    }

    SetBase& set_base() const noexcept
    {
        REALM_ASSERT_DEBUG(dynamic_cast<SetBase*>(m_coll_base.get()));
        return static_cast<SetBase&>(*m_coll_base);
    }

    template <class Fn>
    auto dispatch(Fn&&) const;
    template <class T>
    auto& as() const;

    friend struct std::hash<Set>;
};

template <class Fn>
auto Set::dispatch(Fn&& fn) const
{
    verify_attached();
    return switch_on_type(get_type(), std::forward<Fn>(fn));
}

template <typename T>
auto& Set::as() const
{
    REALM_ASSERT_DEBUG(dynamic_cast<realm::Set<T>*>(m_coll_base.get()));
    return static_cast<realm::Set<T>&>(*m_coll_base);
}

template <>
inline auto& Set::as<Obj>() const
{
    REALM_ASSERT_DEBUG(dynamic_cast<LnkSet*>(m_coll_base.get()));
    return static_cast<LnkSet&>(*m_coll_base);
}

template <>
inline auto& Set::as<ObjKey>() const
{
    REALM_ASSERT_DEBUG(dynamic_cast<LnkSet*>(m_coll_base.get()));
    return static_cast<LnkSet&>(*m_coll_base);
}

template <class T, class Context>
size_t Set::find(Context& ctx, const T& value) const
{
    return dispatch([&](auto t) {
        return this->find(ctx.template unbox<std::decay_t<decltype(*t)>>(value, CreatePolicy::Skip));
    });
}

template <typename Context>
auto Set::get(Context& ctx, size_t row_ndx) const
{
    return dispatch([&](auto t) {
        return ctx.box(this->get<std::decay_t<decltype(*t)>>(row_ndx));
    });
}

template <class T, class Context>
std::pair<size_t, bool> Set::insert(Context& ctx, T&& value, CreatePolicy policy)
{
    return dispatch([&](auto t) {
        return this->insert(ctx.template unbox<std::decay_t<decltype(*t)>>(value, policy));
    });
}

template <class T, class Context>
std::pair<size_t, bool> Set::remove(Context& ctx, T&& value)
{
    return dispatch([&](auto t) {
        return this->remove(ctx.template unbox<std::decay_t<decltype(*t)>>(value));
    });
}

template <typename T, typename Context>
void Set::assign(Context& ctx, T&& values, CreatePolicy policy)
{
    if (ctx.is_same_set(*this, values))
        return;

    if (ctx.is_null(values)) {
        remove_all();
        return;
    }

    if (!policy.diff)
        remove_all();

    ctx.enumerate_collection(values, [&](auto&& element) {
        this->insert(ctx, element, policy);
    });
}

} // namespace object_store
} // namespace realm

namespace std {
template <>
struct hash<realm::object_store::Set> {
    size_t operator()(realm::object_store::Set const&) const;
};
} // namespace std

#endif // REALM_OS_SET_HPP
