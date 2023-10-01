/*************************************************************************
 *
 * Copyright 2020 Realm Inc.
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

#ifndef REALM_BSON_INDEXED_MAP_HPP
#define REALM_BSON_INDEXED_MAP_HPP

#include <stdio.h>
#include <string>
#include <unordered_map>
#include <vector>

namespace realm {
namespace bson {

/// A map type that orders based on insertion order.
template <typename T>
class IndexedMap {
public:
    using entry = std::pair<std::string, T>;

    class iterator {
        size_t m_idx = 0;
        const IndexedMap* m_map;

    public:
        iterator(const IndexedMap* map, size_t idx);
        entry operator*()
        {
            return m_map->operator[](m_idx);
        }
        iterator& operator++();
        iterator& operator--();
        iterator operator++(int);
        iterator operator--(int);

        bool operator!=(const typename IndexedMap<T>::iterator& rhs) const noexcept
        {
            return !(m_idx == rhs.m_idx);
        }
        bool operator==(const typename IndexedMap<T>::iterator& rhs) const noexcept
        {
            return m_idx == rhs.m_idx;
        }
    };


    constexpr IndexedMap() noexcept;
    IndexedMap(const IndexedMap&) = default;
    IndexedMap(IndexedMap&&) = default;
    IndexedMap& operator=(IndexedMap const&) = default;
    IndexedMap& operator=(IndexedMap&&) = default;

    IndexedMap(std::initializer_list<entry> entries);
    ~IndexedMap() = default;

    /// The size of the map
    size_t size() const;

    /// Find an entry by index
    entry operator[](size_t idx) const;

    iterator begin() const;

    iterator end() const;

    entry front();

    entry back();

    iterator find(const std::string& k) const;

    /// Find or add a given key
    T& operator[](const std::string& k);

    T& at(const std::string& k)
    {
        return m_map.at(k);
    }
    const T& at(const std::string& k) const
    {
        return m_map.at(k);
    }

    /// Whether or not this map is empty
    bool empty();

    /// Pop the last entry of the map
    void pop_back();

    const std::vector<std::string>& keys() const noexcept
    {
        return m_keys;
    }
    const std::unordered_map<std::string, T>& entries() const noexcept
    {
        return m_map;
    }

private:
    template <typename V>
    friend bool operator==(const IndexedMap<V>& lhs, const IndexedMap<V>& rhs) noexcept;
    template <typename V>
    friend bool operator!=(const IndexedMap<V>& lhs, const IndexedMap<V>& rhs) noexcept;
    std::unordered_map<std::string, T> m_map;
    std::vector<std::string> m_keys;
};

template <typename T>
bool operator==(const typename IndexedMap<T>::iterator& lhs, const typename IndexedMap<T>::iterator& rhs) noexcept
{
    return lhs.m_idx == rhs.m_idx;
}

template <typename T>
bool operator!=(const typename IndexedMap<T>::iterator lhs, const typename IndexedMap<T>::iterator rhs) noexcept
{
    return !(lhs.m_idx == rhs.m_idx);
}

template <typename T>
bool operator==(const IndexedMap<T>& lhs, const IndexedMap<T>& rhs) noexcept
{
    return lhs.m_map == rhs.m_map && lhs.m_keys == rhs.m_keys;
}

template <typename T>
bool operator!=(const IndexedMap<T>& lhs, const IndexedMap<T>& rhs) noexcept
{
    return lhs.m_map != rhs.m_map && lhs.m_keys != rhs.m_keys;
}

template <typename T>
IndexedMap<T>::iterator::iterator(const IndexedMap<T>* map, size_t idx)
    : m_idx(idx)
    , m_map(map)
{
}

template <typename T>
typename IndexedMap<T>::iterator& IndexedMap<T>::iterator::operator++()
{
    m_idx++;
    return *this;
}

template <typename T>
typename IndexedMap<T>::iterator& IndexedMap<T>::iterator::operator--()
{
    m_idx--;
    return *this;
}

template <typename T>
typename IndexedMap<T>::iterator IndexedMap<T>::iterator::operator++(int)
{
    return IndexedMap<T>::iterator(m_map, m_idx++);
}

template <typename T>
typename IndexedMap<T>::iterator IndexedMap<T>::iterator::operator--(int)
{
    return IndexedMap<T>::iterator(m_map, m_idx--);
}

template <typename T>
constexpr IndexedMap<T>::IndexedMap() noexcept
{
}

template <typename T>
IndexedMap<T>::IndexedMap(std::initializer_list<entry> entries)
{
    for (auto& entry : entries) {
        m_keys.push_back(entry.first);
        m_map[entry.first] = entry.second;
    }
}

template <typename T>
size_t IndexedMap<T>::IndexedMap::size() const
{
    return m_map.size();
}

template <typename T>
std::pair<std::string, T> IndexedMap<T>::operator[](size_t idx) const
{
    auto key = m_keys[idx];
    return {key, m_map.at(key)};
}

template <typename T>
typename IndexedMap<T>::iterator IndexedMap<T>::begin() const
{
    return iterator(this, 0);
}

template <typename T>
typename IndexedMap<T>::iterator IndexedMap<T>::end() const
{
    return iterator(this, m_map.size());
}

template <typename T>
std::pair<std::string, T> IndexedMap<T>::front()
{
    return *this->begin();
}

template <typename T>
std::pair<std::string, T> IndexedMap<T>::back()
{
    return *(--this->end());
}

template <typename T>
typename IndexedMap<T>::iterator IndexedMap<T>::find(const std::string& k) const
{
    auto it = begin();
    while (it != end()) {
        if ((*it).first == k)
            return it;
        it++;
    }
    return it;
}

template <typename T>
T& IndexedMap<T>::operator[](const std::string& k)
{
    auto entry = m_map.find(k);
    if (entry == m_map.end()) {
        m_keys.push_back(k);
    }

    return m_map[k];
}

template <typename T>
bool IndexedMap<T>::empty()
{
    return m_map.empty();
}

template <typename T>
void IndexedMap<T>::pop_back()
{
    auto last_key = m_keys.back();
    m_keys.pop_back();
    m_map.erase(last_key);
}

} // namespace bson
} // namespace realm

#endif /* REALM_BSON_INDEXED_MAP_HPP */
