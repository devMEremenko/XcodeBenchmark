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

#ifndef REALM_SUBSCRIBABLE_HPP
#define REALM_SUBSCRIBABLE_HPP

#include <atomic>
#include <cstdint>
#include <mutex>
#include <unordered_map>

namespace realm {

/// Generic subscribable that allows for coarse, manual notifications
/// from class type T.
template <class T>
struct Subscribable {
    /// Token that identifies an observer.
    /// Unsubscribes when deconstructed to
    /// avoid dangling observers.
    struct Token {
        Token(Subscribable* subscribable, uint64_t token)
            : m_subscribable(subscribable)
            , m_token(token)
        {
        }
        Token(Token&& other) noexcept
            : m_subscribable(std::move(other.m_subscribable))
            , m_token(std::move(other.m_token))
        {
            other.m_subscribable = nullptr;
        }
        Token& operator=(Token&& other) noexcept
        {
            m_subscribable = std::move(other.m_subscribable);
            m_token = std::move(other.m_token);
            other.m_subscribable = nullptr;
            return *this;
        }
        Token(const Token&) = delete;
        Token& operator=(const Token&) = delete;

        ~Token()
        {
            if (m_subscribable) {
                m_subscribable->unsubscribe(*this);
            }
        }

        uint64_t value() const
        {
            return m_token;
        }

    private:
        Subscribable* m_subscribable;
        uint64_t m_token;

        template <class U>
        friend struct Subscribable;
    };

    using Observer = std::function<void(const T&)>;

    Subscribable() = default;
    Subscribable(const Subscribable& other)
    {
        std::scoped_lock lock(m_mutex, other.m_mutex);
        m_subscribers = other.m_subscribers;
    }
    Subscribable(Subscribable&& other) noexcept
    {
        std::scoped_lock lock(m_mutex, other.m_mutex);
        m_subscribers = std::move(other.m_subscribers);
    }
    Subscribable& operator=(const Subscribable& other)
    {
        if (&other == this) {
            return *this;
        }
        std::scoped_lock lock(m_mutex, other.m_mutex);
        m_subscribers = other.m_subscribers;
        return *this;
    }
    Subscribable& operator=(Subscribable&& other) noexcept
    {
        if (&other == this) {
            return *this;
        }
        std::scoped_lock lock(m_mutex, other.m_mutex);
        m_subscribers = std::move(other.m_subscribers);
        return *this;
    }
    /// Subscribe to notifications for class type T. Any mutation to the T class
    /// will trigger the observer. Notifying subscribers must be done manually
    /// by the Subscribable.
    /// @param observer callback to be called on mutation
    /// @returns a token identifying the observer
    [[nodiscard]] Token subscribe(Observer&& observer)
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        static std::atomic<uint64_t> s_token = 0;
        m_subscribers.insert({s_token, std::move(observer)});
        return Token{this, s_token++};
    }

    /// Unsubscribe to notifications for this Subscribable using the
    /// token returned when calling `subscribe`.
    /// @param token the token identifying the observer.
    void unsubscribe(const Token& token)
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_subscribers.erase(token.m_token);
    }

    /// A count of subscribers subscribed to class T.
    /// @return the amount of subscribers subscribed to class T.
    size_t subscribers_count() const
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        return m_subscribers.size();
    }

protected:
    /// Emit a change event to all subscribers.
    void emit_change_to_subscribers(const T& subject) const
    {
        std::unordered_map<uint64_t, Observer> subscribers;
        {
            std::lock_guard<std::mutex> lock(m_mutex);
            subscribers = m_subscribers;
        }
        for (const auto& [_, subscriber] : subscribers) {
            subscriber(subject);
        }
    }

private:
    mutable std::mutex m_mutex;
    std::unordered_map<uint64_t, Observer> m_subscribers;
};

} // namespace realm

#endif /* REALM_SUBSCRIBABLE_HPP */
