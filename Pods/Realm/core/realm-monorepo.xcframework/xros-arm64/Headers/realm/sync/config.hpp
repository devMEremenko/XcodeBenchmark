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

#ifndef REALM_SYNC_CONFIG_HPP
#define REALM_SYNC_CONFIG_HPP

#include <realm/exceptions.hpp>
#include <realm/sync/protocol.hpp>

#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <unordered_map>

namespace realm {

class SyncUser;
class SyncSession;
class Realm;
class ThreadSafeReference;

namespace bson {
class Bson;
}

namespace sync {
using port_type = std::uint_fast16_t;
enum class ProtocolError;
} // namespace sync

struct SyncError {
    enum class ClientResetModeAllowed { DoNotClientReset, RecoveryPermitted, RecoveryNotPermitted };

    Status status;

    bool is_fatal;

    // The following two string_view's are views into the reason string of the status member. Users of
    // SyncError should take care not to modify the status if they are going to access these views into
    // the reason string.
    // Just the minimal error message, without any log URL.
    std::string_view simple_message;
    // The URL to the associated server log if any. If not supplied by the server, this will be `empty()`.
    std::string_view logURL;
    /// A dictionary of extra user information associated with this error.
    /// If this is a client reset error, the keys for c_original_file_path_key and c_recovery_file_path_key will be
    /// populated with the relevant filesystem paths.
    std::unordered_map<std::string, std::string> user_info;
    /// The sync server may send down an error that the client does not recognize,
    /// whether because of a version mismatch or an oversight. It is still valuable
    /// to expose these errors so that users can do something about them.
    bool is_unrecognized_by_client = false;
    // the server may explicitly send down an action the client should take as part of an error (i.e, client reset)
    // if this is set, it overrides the clients interpretation of the error
    sync::ProtocolErrorInfo::Action server_requests_action = sync::ProtocolErrorInfo::Action::NoAction;
    // If this error resulted from a compensating write, this vector will contain information about each object
    // that caused a compensating write and why the write was illegal.
    std::vector<sync::CompensatingWriteErrorInfo> compensating_writes_info;

    SyncError(Status status, bool is_fatal, std::optional<std::string_view> server_log = std::nullopt,
              std::vector<sync::CompensatingWriteErrorInfo> compensating_writes = {});

    static constexpr const char c_original_file_path_key[] = "ORIGINAL_FILE_PATH";
    static constexpr const char c_recovery_file_path_key[] = "RECOVERY_FILE_PATH";

    /// The error indicates a client reset situation.
    bool is_client_reset_requested() const;
};

using SyncSessionErrorHandler = void(std::shared_ptr<SyncSession>, SyncError);

enum class ReconnectMode {
    /// This is the mode that should always be used by SDKs. In this
    /// mode the client uses a scheme for determining a reconnect delay that
    /// prevents it from creating too many connection requests in a short
    /// amount of time (i.e., a server hammering protection mechanism).
    normal,

    /// For internal sync-client testing purposes only.
    ///
    /// Never reconnect automatically after the connection is closed due to
    /// an error. Allow immediate reconnect if the connection was closed
    /// voluntarily (e.g., due to sessions being abandoned).
    ///
    /// In this mode, Client::cancel_reconnect_delay() and
    /// Session::cancel_reconnect_delay() can still be used to trigger
    /// another reconnection attempt (with no delay) after an error has
    /// caused the connection to be closed.
    testing
};

enum class SyncSessionStopPolicy {
    Immediately,          // Immediately stop the session as soon as all Realms/Sessions go out of scope.
    LiveIndefinitely,     // Never stop the session.
    AfterChangesUploaded, // Once all Realms/Sessions go out of scope, wait for uploads to complete and stop.
};

enum class ClientResyncMode : unsigned char {
    // Fire a client reset error
    Manual,
    // Discard local changes, without disrupting accessors or closing the Realm
    DiscardLocal,
    // Attempt to recover unsynchronized but committed changes.
    Recover,
    // Attempt recovery and if that fails, discard local.
    RecoverOrDiscard,
};

enum class SyncClientHookEvent {
    DownloadMessageReceived,
    DownloadMessageIntegrated,
    BootstrapMessageProcessed,
    BootstrapProcessed,
    ErrorMessageReceived,
};

enum class SyncClientHookAction {
    NoAction,
    EarlyReturn,
    SuspendWithRetryableError,
    TriggerReconnect,
};

inline std::ostream& operator<<(std::ostream& os, SyncClientHookAction action)
{
    switch (action) {
        case SyncClientHookAction::NoAction:
            return os << "NoAction";
        case SyncClientHookAction::EarlyReturn:
            return os << "EarlyReturn";
        case SyncClientHookAction::SuspendWithRetryableError:
            return os << "SuspendWithRetryableError";
        case SyncClientHookAction::TriggerReconnect:
            return os << "TriggerReconnect";
    }
    REALM_TERMINATE("Invalid SyncClientHookAction value");
}

struct SyncClientHookData {
    SyncClientHookEvent event;
    sync::SyncProgress progress;
    int64_t query_version;
    sync::DownloadBatchState batch_state;
    size_t num_changesets;
    const sync::ProtocolErrorInfo* error_info = nullptr;
};

struct SyncConfig {
    struct FLXSyncEnabled {};

    struct ProxyConfig {
        using port_type = sync::port_type;
        enum class Type { HTTP, HTTPS } type;
        std::string address;
        port_type port;
    };
    using SSLVerifyCallback = bool(const std::string& server_address, ProxyConfig::port_type server_port,
                                   const char* pem_data, size_t pem_size, int preverify_ok, int depth);

    std::shared_ptr<SyncUser> user;
    std::string partition_value;
    SyncSessionStopPolicy stop_policy = SyncSessionStopPolicy::AfterChangesUploaded;
    std::function<SyncSessionErrorHandler> error_handler;
    bool flx_sync_requested = false;

    // When integrating a flexible sync bootstrap, process this many bytes of changeset data in a single integration
    // attempt. This many bytes of changesets will be uncompressed and held in memory while being applied.
    size_t flx_bootstrap_batch_size_bytes = 1024 * 1024;

    // {@
    /// DEPRECATED - Will be removed in a future release
    // The following parameters are only used by the default SyncSocket implementation. Custom SyncSocket
    // implementations must handle these directly, if these features are supported.
    util::Optional<std::string> authorization_header_name; // not used
    std::map<std::string, std::string> custom_http_headers;
    bool client_validate_ssl = true;
    util::Optional<std::string> ssl_trust_certificate_path;
    std::function<SSLVerifyCallback> ssl_verify_callback;
    util::Optional<ProxyConfig> proxy_config;
    // @}

    // If true, upload/download waits are canceled on any sync error and not just fatal ones
    bool cancel_waits_on_nonfatal_error = false;

    // If false, changesets incoming from the server are discarded without
    // applying them to the Realm file. This is required when writing objects
    // directly to replication, and will break horribly otherwise
    bool apply_server_changes = true;

    // The name of the directory which Realms should be backed up to following
    // a client reset in ClientResyncMode::Manual mode
    util::Optional<std::string> recovery_directory;
    ClientResyncMode client_resync_mode = ClientResyncMode::Manual;
    std::function<void(std::shared_ptr<Realm> before)> notify_before_client_reset;
    std::function<void(std::shared_ptr<Realm> frozen_before, ThreadSafeReference after, bool did_recover)>
        notify_after_client_reset;
    // If true, the Realm passed as the `before` argument to the before reset
    // callbacks will be frozen
    bool freeze_before_reset_realm = true;

    // Used by core testing to hook into the sync client when various events occur and maybe inject
    // errors/disconnects deterministically.
    std::function<SyncClientHookAction(std::weak_ptr<SyncSession>, const SyncClientHookData&)>
        on_sync_client_event_hook;

    bool simulate_integration_error = false;

    // callback invoked right after DataInitializationFunction. It is used in order to setup an initial subscription.
    using SubscriptionInitializerCallback = std::function<void(std::shared_ptr<Realm>)>;
    SubscriptionInitializerCallback subscription_initializer;

    // in case the initial subscription contains a dynamic query, the user may want to force
    // the query to be run again every time the realm is opened. This flag should be set to true
    // in this case.
    bool rerun_init_subscription_on_open{false};

    SyncConfig() = default;
    explicit SyncConfig(std::shared_ptr<SyncUser> user, bson::Bson partition);
    explicit SyncConfig(std::shared_ptr<SyncUser> user, std::string partition);
    explicit SyncConfig(std::shared_ptr<SyncUser> user, const char* partition);
    explicit SyncConfig(std::shared_ptr<SyncUser> user, FLXSyncEnabled);
};

} // namespace realm

#endif // REALM_SYNC_CONFIG_HPP
