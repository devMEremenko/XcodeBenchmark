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

#ifndef REALM_OS_DICTIONARY_HPP
#define REALM_OS_DICTIONARY_HPP

#include <realm/object-store/collection.hpp>
#include <realm/object-store/object.hpp>
#include <realm/dictionary.hpp>

namespace realm {

struct DictionaryChangeSet {
    DictionaryChangeSet(size_t max_keys)
    {
        m_string_store.reserve(max_keys);
    }
    DictionaryChangeSet()
        : DictionaryChangeSet(0)
    {
    }

    DictionaryChangeSet(const DictionaryChangeSet&);
    DictionaryChangeSet(DictionaryChangeSet&&) = default;

    DictionaryChangeSet& operator=(const DictionaryChangeSet&);
    DictionaryChangeSet& operator=(DictionaryChangeSet&&) = default;

    // Keys which were removed from the _old_ dictionary
    std::vector<Mixed> deletions;

    // Keys in the _new_ dictionary which are new insertions
    std::vector<Mixed> insertions;

    // Keys of objects/values which were modified
    std::vector<Mixed> modifications;

    bool collection_root_was_deleted = false;

    void add_deletion(const Mixed& key)
    {
        add(deletions, key);
    }
    void add_insertion(const Mixed& key)
    {
        add(insertions, key);
    }
    void add_modification(const Mixed& key)
    {
        add(modifications, key);
    }

private:
    void add(std::vector<Mixed>& arr, const Mixed& key);
    std::vector<std::string> m_string_store;
};

namespace object_store {

class Dictionary : public object_store::Collection {
public:
    using Iterator = realm::Dictionary::Iterator;
    using Collection::Collection;
    Dictionary()
        : Collection(PropertyType::Dictionary)
    {
    }

    bool operator==(const Dictionary& rgt) const noexcept;
    bool operator!=(const Dictionary& rgt) const noexcept;

    template <typename T>
    void insert(StringData key, T value);
    std::pair<size_t, bool> insert_any(StringData key, Mixed value);

    template <typename T>
    T get(StringData key) const;

    Obj insert_embedded(StringData key);
    void erase(StringData key);
    bool try_erase(StringData key);
    void remove_all();
    Obj get_object(StringData key);
    Mixed get_any(StringData key);
    Mixed get_any(size_t ndx) const final;
    util::Optional<Mixed> try_get_any(StringData key) const;
    std::pair<StringData, Mixed> get_pair(size_t ndx) const;
    size_t find_any(Mixed value) const final;
    bool contains(StringData key) const;

    template <typename T, typename Context>
    void insert(Context&, StringData key, T&& value, CreatePolicy = CreatePolicy::SetLink);
    template <typename Context>
    auto get(Context&, StringData key) const;

    // Replace the values in this dictionary with the values from an map type object
    template <typename T, typename Context>
    void assign(Context&, T&& value, CreatePolicy = CreatePolicy::SetLink);

    Results snapshot() const;
    Dictionary freeze(const std::shared_ptr<Realm>& realm) const;
    Results get_keys() const;
    Results get_values() const;

    using CBFunc = util::UniqueFunction<void(DictionaryChangeSet)>;
    NotificationToken
    add_key_based_notification_callback(CBFunc cb, std::optional<KeyPathArray> key_path_array = std::nullopt) &;

    Iterator begin() const;
    Iterator end() const;

private:
    const char* type_name() const noexcept override
    {
        return "Dictionary";
    }

    realm::Dictionary& dict() const noexcept
    {
        REALM_ASSERT_DEBUG(dynamic_cast<realm::Dictionary*>(m_coll_base.get()));
        return static_cast<realm::Dictionary&>(*m_coll_base);
    }

    template <typename Fn>
    auto dispatch(Fn&&) const;
    Obj get_object(StringData key) const;
};


template <typename Fn>
auto Dictionary::dispatch(Fn&& fn) const
{
    verify_attached();
    return switch_on_type(get_type(), std::forward<Fn>(fn));
}

template <typename T>
void Dictionary::insert(StringData key, T value)
{
    verify_in_transaction();
    dict().insert(key, value);
}

template <typename T>
T Dictionary::get(StringData key) const
{
    auto res = dict().get(key);
    if (res.is_null()) {
        if constexpr (std::is_same_v<T, Decimal128>) {
            return Decimal128{realm::null()};
        }
        else {
            return T{};
        }
    }
    return res.get<T>();
}

template <>
inline Obj Dictionary::get<Obj>(StringData key) const
{
    return get_object(key);
}

template <typename T, typename Context>
void Dictionary::insert(Context& ctx, StringData key, T&& value, CreatePolicy policy)
{
    if (ctx.is_null(value)) {
        this->insert(key, Mixed());
        return;
    }
    if (m_is_embedded) {
        validate_embedded(ctx, value, policy);
        auto obj_key = dict().create_and_insert_linked_object(key).get_key();
        ctx.template unbox<Obj>(value, policy, obj_key);
        return;
    }
    dispatch([&](auto t) {
        this->insert(key, ctx.template unbox<std::decay_t<decltype(*t)>>(value, policy));
    });
}

template <typename Context>
auto Dictionary::get(Context& ctx, StringData key) const
{
    return dispatch([&](auto t) {
        return ctx.box(this->get<std::decay_t<decltype(*t)>>(key));
    });
}

template <typename T, typename Context>
void Dictionary::assign(Context& ctx, T&& values, CreatePolicy policy)
{
    if (ctx.is_same_dictionary(*this, values))
        return;

    if (ctx.is_null(values)) {
        remove_all();
        return;
    }

    if (!policy.diff)
        remove_all();

    ctx.enumerate_dictionary(values, [&](StringData key, auto&& value) {
        if (policy.diff) {
            util::Optional<Mixed> old_value = dict().try_get(key);
            auto new_value = ctx.template unbox<Mixed>(value);
            if (!old_value || *old_value != new_value) {
                dict().insert(key, new_value);
            }
        }
        else {
            this->insert(ctx, key, value, policy);
        }
    });
}

} // namespace object_store
} // namespace realm


#endif /* REALM_OS_DICTIONARY_HPP */
