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

#ifndef REALM_OS_SYNC_MANAGER_HPP
#define REALM_OS_SYNC_MANAGER_HPP

#include <realm/object-store/shared_realm.hpp>

#include <realm/util/checked_mutex.hpp>
#include <realm/util/logger.hpp>
#include <realm/util/optional.hpp>
#include <realm/sync/binding_callback_thread_observer.hpp>
#include <realm/sync/config.hpp>
#include <realm/sync/socket_provider.hpp>

#include <memory>
#include <mutex>
#include <unordered_map>

class TestAppSession;
class TestSyncManager;

namespace realm {

class DB;
struct SyncConfig;
class SyncSession;
class SyncUser;
class SyncFileManager;
class SyncMetadataManager;
class SyncFileActionMetadata;
class SyncAppMetadata;

namespace _impl {
struct SyncClient;
}

namespace app {
class App;
}

struct SyncClientTimeouts {
    SyncClientTimeouts();
    // See sync::Client::Config for the meaning of these fields.
    uint64_t connect_timeout;
    uint64_t connection_linger_time;
    uint64_t ping_keepalive_period;
    uint64_t pong_keepalive_timeout;
    uint64_t fast_reconnect_limit;
};

struct SyncClientConfig {
    enum class MetadataMode {
        NoEncryption, // Enable metadata, but disable encryption.
        Encryption,   // Enable metadata, and use encryption (automatic if possible).
        NoMetadata,   // Disable metadata.
    };

    std::string base_file_path;
    MetadataMode metadata_mode = MetadataMode::Encryption;
    util::Optional<std::vector<char>> custom_encryption_key;

    using LoggerFactory = std::function<std::shared_ptr<util::Logger>(util::Logger::Level)>;
    LoggerFactory logger_factory;
    util::Logger::Level log_level = util::Logger::Level::info;
    ReconnectMode reconnect_mode = ReconnectMode::normal; // For internal sync-client testing only!
#if REALM_DISABLE_SYNC_MULTIPLEXING
    bool multiplex_sessions = false;
#else
    bool multiplex_sessions = true;
#endif

    // The SyncSocket instance used by the Sync Client for event synchronization
    // and creating WebSockets. If not provided the default implementation will be used.
    std::shared_ptr<sync::SyncSocketProvider> socket_provider;

    // Optional thread observer for event loop thread events in the default SyncSocketProvider
    // implementation. It is not used for custom SyncSocketProvider implementations.
    std::shared_ptr<BindingCallbackThreadObserver> default_socket_provider_thread_observer;

    // {@
    // Optional information about the binding/application that is sent as part of the User-Agent
    // when establishing a connection to the server. These values are only used by the default
    // SyncSocket implementation. Custom SyncSocket implementations must update the User-Agent
    // directly, if supported by the platform APIs.
    std::string user_agent_binding_info;
    std::string user_agent_application_info;
    // @}

    SyncClientTimeouts timeouts;
};

class SyncManager : public std::enable_shared_from_this<SyncManager> {
    friend class SyncSession;
    friend class ::TestSyncManager;
    friend class ::TestAppSession;

public:
    using MetadataMode = SyncClientConfig::MetadataMode;

    // Immediately run file actions for a single Realm at a given original path.
    // Returns whether or not a file action was successfully executed for the specified Realm.
    // Preconditions: all references to the Realm at the given path must have already been invalidated.
    // The metadata and file management subsystems must also have already been configured.
    bool immediately_run_file_actions(const std::string& original_name) REQUIRES(!m_file_system_mutex);

    // Enables/disables using a single connection for all sync sessions for each host/port/user rather
    // than one per session.
    // This must be called before any sync sessions are created, cannot be
    // disabled afterwards, and currently is incompatible with automatic failover.
    void set_session_multiplexing(bool allowed) REQUIRES(!m_mutex);

    // Destroys the sync manager, terminates all sessions created by it, and stops its SyncClient.
    ~SyncManager();

    // Sets the log level for the Sync Client.
    // The log level can only be set up until the point the Sync Client is
    // created (when the first Session is created) or an App operation is
    // performed (e.g. log in).
    void set_log_level(util::Logger::Level) noexcept REQUIRES(!m_mutex);
    void set_logger_factory(SyncClientConfig::LoggerFactory) REQUIRES(!m_mutex);

    // Sets the application level user agent string.
    // This should have the format specified here:
    // https://github.com/realm/realm-sync/blob/develop/src/realm/sync/client.hpp#L126 The user agent can only be set
    // up  until the  point the Sync Client is created. This happens when the first Session is created.
    void set_user_agent(std::string user_agent) REQUIRES(!m_mutex);

    // Sets client timeout settings.
    // The timeout settings can only be set up until the point the Sync Client is created.
    // This happens when the first Session is created.
    void set_timeouts(SyncClientTimeouts timeouts) REQUIRES(!m_mutex);

    /// Ask all valid sync sessions to perform whatever tasks might be necessary to
    /// re-establish connectivity with the Realm Object Server. It is presumed that
    /// the caller knows that network connectivity has been restored.
    ///
    /// Refer to `SyncSession::handle_reconnect()` to see what sort of work is done
    /// on a per-session basis.
    void reconnect() const REQUIRES(!m_session_mutex);

    util::Logger::Level log_level() const noexcept REQUIRES(!m_mutex);

    std::vector<std::shared_ptr<SyncSession>> get_all_sessions() const REQUIRES(!m_session_mutex);
    std::shared_ptr<SyncSession> get_session(std::shared_ptr<DB> db, const RealmConfig& config)
        REQUIRES(!m_mutex, !m_session_mutex);
    std::shared_ptr<SyncSession> get_existing_session(const std::string& path) const REQUIRES(!m_session_mutex);
    std::shared_ptr<SyncSession> get_existing_active_session(const std::string& path) const
        REQUIRES(!m_session_mutex);

    // Returns `true` if the SyncManager still contains any existing sessions not yet fully cleaned up.
    // This will return true as long as there is an external reference to a session object, no matter
    // the state of that session.
    bool has_existing_sessions() REQUIRES(!m_session_mutex);

    // Blocking call that only return once all sessions have been terminated.
    // Due to the async nature of the SyncClient, even with `SyncSessionStopPolicy::Immediate`, a
    // session is not guaranteed to stop immediately when a Realm is closed. Using this method
    // makes it possible to guarantee that all sessions have, in fact, been closed.
    void wait_for_sessions_to_terminate() REQUIRES(!m_mutex);

    // If the metadata manager is configured, perform an update. Returns `true` if the code was run.
    bool perform_metadata_update(util::FunctionRef<void(SyncMetadataManager&)> update_function) const
        REQUIRES(!m_file_system_mutex);

    // Get a sync user for a given identity, or create one if none exists yet, and set its token.
    // If a logged-out user exists, it will marked as logged back in.
    std::shared_ptr<SyncUser> get_user(const std::string& user_id, const std::string& refresh_token,
                                       const std::string& access_token, const std::string& device_id)
        REQUIRES(!m_user_mutex, !m_file_system_mutex);

    // Get an existing user for a given identifier, if one exists and is logged in.
    std::shared_ptr<SyncUser> get_existing_logged_in_user(const std::string& user_id) const REQUIRES(!m_user_mutex);

    // Get all the users that are logged in and not errored out.
    std::vector<std::shared_ptr<SyncUser>> all_users() REQUIRES(!m_user_mutex);

    // Gets the currently active user.
    std::shared_ptr<SyncUser> get_current_user() const REQUIRES(!m_user_mutex, !m_file_system_mutex);

    // Log out a given user
    void log_out_user(const SyncUser& user) REQUIRES(!m_user_mutex, !m_file_system_mutex);

    // Sets the currently active user.
    void set_current_user(const std::string& user_id) REQUIRES(!m_user_mutex, !m_file_system_mutex);

    // Removes a user
    void remove_user(const std::string& user_id) REQUIRES(!m_user_mutex, !m_file_system_mutex);

    // Permanently deletes a user.
    void delete_user(const std::string& user_id) REQUIRES(!m_user_mutex, !m_file_system_mutex);

    // Get the default path for a Realm for the given configuration.
    // The default value is `<rootDir>/<appId>/<userId>/<partitionValue>.realm`.
    // If the file cannot be created at this location, for example due to path length restrictions,
    // this function may pass back `<rootDir>/<hashedFileName>.realm`
    std::string path_for_realm(const SyncConfig& config, util::Optional<std::string> custom_file_name = none) const
        REQUIRES(!m_file_system_mutex);

    // Get the path of the recovery directory for backed-up or recovered Realms.
    std::string recovery_directory_path(util::Optional<std::string> const& custom_dir_name = none) const
        REQUIRES(!m_file_system_mutex);

    // Reset the singleton state for testing purposes. DO NOT CALL OUTSIDE OF TESTING CODE.
    // Precondition: any synced Realms or `SyncSession`s must be closed or rendered inactive prior to
    // calling this method.
    void reset_for_testing() REQUIRES(!m_mutex, !m_file_system_mutex, !m_user_mutex, !m_session_mutex);

    // Get the app metadata for the active app.
    util::Optional<SyncAppMetadata> app_metadata() const REQUIRES(!m_file_system_mutex);

    // Immediately closes any open sync sessions for this sync manager
    void close_all_sessions() REQUIRES(!m_mutex, !m_session_mutex);

    void set_sync_route(std::string sync_route) REQUIRES(!m_mutex)
    {
        util::CheckedLockGuard lock(m_mutex);
        m_sync_route = std::move(sync_route);
    }

    const std::string sync_route() const REQUIRES(!m_mutex)
    {
        util::CheckedLockGuard lock(m_mutex);
        return m_sync_route;
    }

    std::weak_ptr<app::App> app() const REQUIRES(!m_mutex)
    {
        util::CheckedLockGuard lock(m_mutex);
        return m_app;
    }

    SyncClientConfig config() const REQUIRES(!m_mutex)
    {
        util::CheckedLockGuard lock(m_mutex);
        return m_config;
    }

    // Return the cached logger
    const std::shared_ptr<util::Logger>& get_logger() const REQUIRES(!m_mutex);

    SyncManager();
    SyncManager(const SyncManager&) = delete;
    SyncManager& operator=(const SyncManager&) = delete;

    struct OnlyForTesting {
        friend class TestHelper;

        static void voluntary_disconnect_all_connections(SyncManager&);
    };

protected:
    friend class SyncUser;
    friend class SyncSesson;

    using std::enable_shared_from_this<SyncManager>::shared_from_this;
    using std::enable_shared_from_this<SyncManager>::weak_from_this;

private:
    friend class app::App;

    void configure(std::shared_ptr<app::App> app, const std::string& sync_route, const SyncClientConfig& config)
        REQUIRES(!m_mutex, !m_file_system_mutex, !m_user_mutex, !m_session_mutex);

    // Stop tracking the session for the given path if it is inactive.
    // No-op if the session is either still active or in the active sessions list
    // due to someone holding a strong reference to it.
    void unregister_session(const std::string& path) REQUIRES(!m_session_mutex);

    _impl::SyncClient& get_sync_client() const REQUIRES(!m_mutex);
    std::unique_ptr<_impl::SyncClient> create_sync_client() const REQUIRES(m_mutex);

    std::shared_ptr<SyncSession> get_existing_session_locked(const std::string& path) const REQUIRES(m_session_mutex);

    std::shared_ptr<SyncUser> get_user_for_identity(std::string const& identity) const noexcept
        REQUIRES(m_user_mutex);

    mutable util::CheckedMutex m_mutex;

    bool run_file_action(SyncFileActionMetadata&) REQUIRES(m_file_system_mutex);
    void init_metadata(SyncClientConfig config, const std::string& app_id);

    // internally create a new logger - used by configure() and set_logger_factory()
    void do_make_logger() REQUIRES(m_mutex);

    // Protects m_users
    mutable util::CheckedMutex m_user_mutex;

    // A vector of all SyncUser objects.
    std::vector<std::shared_ptr<SyncUser>> m_users GUARDED_BY(m_user_mutex);
    std::shared_ptr<SyncUser> m_current_user GUARDED_BY(m_user_mutex);

    mutable std::unique_ptr<_impl::SyncClient> m_sync_client GUARDED_BY(m_mutex);

    SyncClientConfig m_config GUARDED_BY(m_mutex);
    mutable std::shared_ptr<util::Logger> m_logger_ptr GUARDED_BY(m_mutex);

    // Protects m_file_manager and m_metadata_manager
    mutable util::CheckedMutex m_file_system_mutex;
    std::unique_ptr<SyncFileManager> m_file_manager GUARDED_BY(m_file_system_mutex);
    std::unique_ptr<SyncMetadataManager> m_metadata_manager GUARDED_BY(m_file_system_mutex);

    // Protects m_sessions
    mutable util::CheckedMutex m_session_mutex;

    // Map of sessions by path name.
    // Sessions remove themselves from this map by calling `unregister_session` once they're
    // inactive and have performed any necessary cleanup work.
    std::unordered_map<std::string, std::shared_ptr<SyncSession>> m_sessions GUARDED_BY(m_session_mutex);

    // Internal method returning `true` if the SyncManager still contains sessions not yet fully closed.
    // Callers of this method should hold the `m_session_mutex` themselves.
    bool do_has_existing_sessions() REQUIRES(m_session_mutex);

    std::string m_sync_route GUARDED_BY(m_mutex);

    std::weak_ptr<app::App> m_app GUARDED_BY(m_mutex);
};

} // namespace realm

#endif // REALM_OS_SYNC_MANAGER_HPP
