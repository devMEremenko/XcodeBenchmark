////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#ifndef REALM_OS_SYNC_USER_HPP
#define REALM_OS_SYNC_USER_HPP

#include <realm/object-store/util/atomic_shared_ptr.hpp>
#include <realm/object-store/util/bson/bson.hpp>
#include <realm/object-store/sync/subscribable.hpp>

#include <realm/util/checked_mutex.hpp>
#include <realm/util/optional.hpp>
#include <realm/table.hpp>

#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace realm {
namespace app {
struct AppError;
class MongoClient;
} // namespace app
class SyncManager;
class SyncSession;
class SyncUserMetadata;

// A superclass that bindings can inherit from in order to store information
// upon a `SyncUser` object.
class SyncUserContext {
public:
    virtual ~SyncUserContext() = default;
};

using SyncUserContextFactory = util::UniqueFunction<std::shared_ptr<SyncUserContext>()>;

// A struct that decodes a given JWT.
struct RealmJWT {
    // The token being decoded from.
    std::string token;

    // When the token expires.
    int64_t expires_at = 0;
    // When the token was issued.
    int64_t issued_at = 0;
    // Custom user data embedded in the encoded token.
    util::Optional<bson::BsonDocument> user_data;

    explicit RealmJWT(const std::string& token);
    RealmJWT() = default;

    bool operator==(const RealmJWT& other) const
    {
        return token == other.token;
    }
};

struct SyncUserProfile {
    // The full name of the user.
    util::Optional<std::string> name() const
    {
        return get_field("name");
    }
    // The email address of the user.
    util::Optional<std::string> email() const
    {
        return get_field("email");
    }
    // A URL to the user's profile picture.
    util::Optional<std::string> picture_url() const
    {
        return get_field("picture_url");
    }
    // The first name of the user.
    util::Optional<std::string> first_name() const
    {
        return get_field("first_name");
    }
    // The last name of the user.
    util::Optional<std::string> last_name() const
    {
        return get_field("last_name");
    }
    // The gender of the user.
    util::Optional<std::string> gender() const
    {
        return get_field("gender");
    }
    // The birthdate of the user.
    util::Optional<std::string> birthday() const
    {
        return get_field("birthday");
    }
    // The minimum age of the user.
    util::Optional<std::string> min_age() const
    {
        return get_field("min_age");
    }
    // The maximum age of the user.
    util::Optional<std::string> max_age() const
    {
        return get_field("max_age");
    }

    bson::Bson operator[](const std::string& key) const
    {
        return m_data.at(key);
    }

    const bson::BsonDocument& data() const
    {
        return m_data;
    }

    SyncUserProfile(bson::BsonDocument&& data)
        : m_data(std::move(data))
    {
    }
    SyncUserProfile() = default;

private:
    bson::BsonDocument m_data;

    util::Optional<std::string> get_field(const char* name) const
    {
        auto it = m_data.find(name);
        if (it == m_data.end()) {
            return util::none;
        }
        return static_cast<std::string>((*it).second);
    }
};

// A struct that represents an identity that a `User` is linked to
struct SyncUserIdentity {
    // the id of the identity
    std::string id;
    // the associated provider type of the identity
    std::string provider_type;

    SyncUserIdentity(const std::string& id, const std::string& provider_type);

    bool operator==(const SyncUserIdentity& other) const
    {
        return id == other.id && provider_type == other.provider_type;
    }

    bool operator!=(const SyncUserIdentity& other) const
    {
        return id != other.id || provider_type != other.provider_type;
    }
};

// A `SyncUser` represents a single user account. Each user manages the sessions that
// are associated with it.
class SyncUser : public std::enable_shared_from_this<SyncUser>, public Subscribable<SyncUser> {
    friend class SyncSession;

public:
    enum class State {
        LoggedOut,
        LoggedIn,
        Removed,
    };

    // Return a list of all sessions belonging to this user.
    std::vector<std::shared_ptr<SyncSession>> all_sessions() REQUIRES(!m_mutex);

    // Return a session for a given on disk path.
    // In most cases, bindings shouldn't expose this to consumers, since the on-disk
    // path for a synced Realm is an opaque implementation detail. This API is retained
    // for testing purposes, and for bindings for consumers that are servers or tools.
    std::shared_ptr<SyncSession> session_for_on_disk_path(const std::string& path) REQUIRES(!m_mutex);

    // Log the user out and mark it as such. This will also close its associated Sessions.
    void log_out() REQUIRES(!m_mutex, !m_tokens_mutex);

    /// Returns true if the users access_token and refresh_token are set.
    bool is_logged_in() const REQUIRES(!m_mutex, !m_tokens_mutex);

    /// Returns true if the user's only identity is anonymous.
    bool is_anonymous() const REQUIRES(!m_mutex, !m_tokens_mutex);

    const std::string& identity() const noexcept
    {
        return m_identity;
    }

    const std::vector<std::string>& legacy_identities() const noexcept
    {
        return m_legacy_identities;
    }

    std::string access_token() const REQUIRES(!m_tokens_mutex);
    std::string refresh_token() const REQUIRES(!m_tokens_mutex);
    std::string device_id() const REQUIRES(!m_mutex);
    bool has_device_id() const REQUIRES(!m_mutex);
    SyncUserProfile user_profile() const REQUIRES(!m_mutex);
    std::vector<SyncUserIdentity> identities() const REQUIRES(!m_mutex);
    State state() const REQUIRES(!m_mutex);

    // Custom user data embedded in the access token.
    util::Optional<bson::BsonDocument> custom_data() const REQUIRES(!m_tokens_mutex);

    std::shared_ptr<SyncUserContext> binding_context() const
    {
        return m_binding_context.load();
    }

    // Optionally set a context factory. If so, must be set before any sessions are created.
    static void set_binding_context_factory(SyncUserContextFactory factory);

    std::shared_ptr<SyncManager> sync_manager() const REQUIRES(!m_mutex);

    /// Retrieves a general-purpose service client for the Realm Cloud service
    /// @param service_name The name of the cluster
    app::MongoClient mongo_client(const std::string& service_name) REQUIRES(!m_mutex);

    // ------------------------------------------------------------------------
    // All of the following are called by `SyncManager` and are public only for
    // testing purposes. SDKs should not call these directly in non-test code
    // or expose them in the public API.

    // Don't use this directly; use the `SyncManager` APIs. Public for use with `make_shared`.
    SyncUser(const std::string& refresh_token, const std::string& id, const std::string& access_token,
             const std::string& device_id, SyncManager* sync_manager);
    SyncUser(const SyncUserMetadata& data, SyncManager* sync_manager);

    // Atomically set the user to be logged in and update both tokens.
    void log_in(const std::string& access_token, const std::string& refresh_token)
        REQUIRES(!m_mutex, !m_tokens_mutex);

    // Atomically set the user to be removed and remove tokens.
    void invalidate() REQUIRES(!m_mutex, !m_tokens_mutex);

    // Update the user's access token. If the user is logged out, it will log itself back in.
    // Note that this is called by the SyncManager, and should not be directly called.
    void update_access_token(std::string&& token) REQUIRES(!m_mutex, !m_tokens_mutex);

    // Update the user's profile and identities.
    void update_user_profile(std::vector<SyncUserIdentity> identities, SyncUserProfile profile) REQUIRES(!m_mutex);

    // Register a session to this user.
    // A registered session will be bound at the earliest opportunity: either
    // immediately, or upon the user becoming Active.
    // Note that this is called by the SyncManager, and should not be directly called.
    void register_session(std::shared_ptr<SyncSession>) REQUIRES(!m_mutex);

    /// Refreshes the custom data for this user
    /// If `update_location` is true, the location metadata will be queried before the request
    void refresh_custom_data(bool update_location,
                             util::UniqueFunction<void(util::Optional<app::AppError>)> completion_block)
        REQUIRES(!m_mutex);
    void refresh_custom_data(util::UniqueFunction<void(util::Optional<app::AppError>)> completion_block)
        REQUIRES(!m_mutex);

    /// Checks the expiry on the access token against the local time and if it is invalid or expires soon, returns
    /// true.
    bool access_token_refresh_required() const REQUIRES(!m_tokens_mutex);

    // Hook for testing access token timeouts
    void set_seconds_to_adjust_time_for_testing(int seconds)
    {
        m_seconds_to_adjust_time_for_testing.store(seconds);
    }

protected:
    friend class SyncManager;
    void detach_from_sync_manager() REQUIRES(!m_mutex);

private:
    static SyncUserContextFactory s_binding_context_factory;
    static std::mutex s_binding_context_factory_mutex;

    bool do_is_anonymous() const REQUIRES(m_mutex);

    std::vector<std::shared_ptr<SyncSession>> revive_sessions() REQUIRES(m_mutex);

    State m_state GUARDED_BY(m_mutex);

    util::AtomicSharedPtr<SyncUserContext> m_binding_context;

    // UUIDs which used to be used to generate local Realm file paths. Now only
    // used to locate existing files.
    std::vector<std::string> m_legacy_identities;

    mutable util::CheckedMutex m_mutex;

    // Set by the server. The unique ID of the user account on the Realm Application.
    const std::string m_identity;

    // Sessions are owned by the SyncManager, but the user keeps a map of weak references
    // to them.
    std::unordered_map<std::string, std::weak_ptr<SyncSession>> m_sessions;

    // Waiting sessions are those that should be asked to connect once this user is logged in.
    std::unordered_map<std::string, std::weak_ptr<SyncSession>> m_waiting_sessions;

    mutable util::CheckedMutex m_tokens_mutex;

    // The user's refresh token.
    RealmJWT m_refresh_token GUARDED_BY(m_tokens_mutex);

    // The user's access token.
    RealmJWT m_access_token GUARDED_BY(m_tokens_mutex);

    // The identities associated with this user.
    std::vector<SyncUserIdentity> m_user_identities GUARDED_BY(m_mutex);

    SyncUserProfile m_user_profile GUARDED_BY(m_mutex);

    const std::string m_device_id;

    SyncManager* m_sync_manager;

    std::atomic<int> m_seconds_to_adjust_time_for_testing = 0;
};

} // namespace realm

namespace std {
template <>
struct hash<realm::SyncUserIdentity> {
    size_t operator()(realm::SyncUserIdentity const&) const;
};
} // namespace std

#endif // REALM_OS_SYNC_USER_HPP
