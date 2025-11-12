#ifndef REALM_SYNC_PROTOCOL_HPP
#define REALM_SYNC_PROTOCOL_HPP

#include <cstdint>
#include <system_error>

#include <realm/error_codes.h>
#include <realm/mixed.hpp>
#include <realm/replication.hpp>
#include <realm/util/tagged_bool.hpp>


// NOTE: The protocol specification is in `/doc/protocol.md`


namespace realm {
namespace sync {

// Protocol versions:
//
//   1 Initial version, matching io.realm.sync-30, but not including query-based
//     sync, serialized transactions, and state realms (async open).
//
//   2 Restored erase-always-wins OT behavior.
//
//   3 Support for Mixed, TypeLinks, Set, and Dictionary columns.
//
//   4 Error messaging format accepts a flexible JSON field in 'json_error'.
//     JSONErrorMessage.IsClientReset controls recovery mode.
//
//   5 Introduces compensating write errors.
//
//   6 Support for asymmetric tables.
//
//   7 Client takes the 'action' specified in the 'json_error' messages received
//     from server. Client sends 'json_error' messages to the server.
//
//   8 Websocket http errors are now sent as websocket close codes
//     FLX sync BIND message can include JSON data in place of server path string
//     Updated format for Sec-Websocket-Protocol strings
//
//   9 Support for PBS->FLX client migration
//     Client reset updated to not provide the local schema when creating frozen
//     realms - this informs the server to not send the schema before sending the
//     migrate to FLX server action
//
//   10 Update BIND message to send information to the server about the reason a
//      synchronization session is used for; add support for server log messages
//
//  XX Changes:
//     - TBD
//
constexpr int get_current_protocol_version() noexcept
{
    // Also update the current protocol version test in flx_sync.cpp when
    // updating this value
    return 10;
}

constexpr std::string_view get_pbs_websocket_protocol_prefix() noexcept
{
    return "com.mongodb.realm-sync#";
}

constexpr std::string_view get_flx_websocket_protocol_prefix() noexcept
{
    return "com.mongodb.realm-query-sync#";
}

enum class SyncServerMode { PBS, FLX };

/// Supported protocol envelopes:
///
///                                                             Alternative (*)
///      Name     Envelope          URL scheme   Default port   default port
///     ------------------------------------------------------------------------
///      realm    WebSocket         realm:       7800           80
///      realms   WebSocket + SSL   realms:      7801           443
///      ws       WebSocket         ws:          80
///      wss      WebSocket + SSL   wss:         443
///
///       *) When Client::Config::enable_default_port_hack is true
///
enum class ProtocolEnvelope { realm, realms, ws, wss };

inline bool is_ssl(ProtocolEnvelope protocol) noexcept
{
    switch (protocol) {
        case ProtocolEnvelope::realm:
        case ProtocolEnvelope::ws:
            break;
        case ProtocolEnvelope::realms:
        case ProtocolEnvelope::wss:
            return true;
    }
    return false;
}

inline std::string_view to_string(ProtocolEnvelope protocol) noexcept
{
    switch (protocol) {
        case ProtocolEnvelope::realm:
            return "realm://";
        case ProtocolEnvelope::realms:
            return "realms://";
        case ProtocolEnvelope::ws:
            return "ws://";
        case ProtocolEnvelope::wss:
            return "wss://";
    }
    return "";
}


// These integer types are selected so that they accomodate the requirements of
// the protocol specification (`/doc/protocol.md`).
//
// clang-format off
using file_ident_type    = std::uint_fast64_t;
using version_type       = Replication::version_type;
using salt_type          = std::int_fast64_t;
using timestamp_type     = std::uint_fast64_t;
using session_ident_type = std::uint_fast64_t;
using request_ident_type = std::uint_fast64_t;
using milliseconds_type  = std::int_fast64_t;
// clang-format on

constexpr file_ident_type get_max_file_ident()
{
    return 0x0'7FFF'FFFF'FFFF'FFFF;
}


struct SaltedFileIdent {
    file_ident_type ident;
    /// History divergence and identity spoofing protection.
    salt_type salt;
};

struct SaltedVersion {
    version_type version;
    /// History divergence protection.
    salt_type salt;
};


/// \brief A client's reference to a position in the server-side history.
///
/// A download cursor refers to a position in the server-side history. If
/// `server_version` is zero, the position is at the beginning of the history,
/// otherwise the position is after the entry whose changeset produced that
/// version. In general, positions are to be understood as places between two
/// adjacent history entries.
///
/// `last_integrated_client_version` is the version produced on the client by
/// the last changeset that was sent to the server and integrated into the
/// server-side Realm state at the time indicated by the history position
/// specified by `server_version`, or zero if no changesets from the client were
/// integrated by the server at that point in time.
struct DownloadCursor {
    version_type server_version;
    version_type last_integrated_client_version;
};

enum class DownloadBatchState {
    MoreToCome,
    LastInBatch,
    SteadyState,
};

/// Checks that `dc.last_integrated_client_version` is zero if
/// `dc.server_version` is zero.
bool is_consistent(DownloadCursor dc) noexcept;

/// Checks that `a.last_integrated_client_version` and
/// `b.last_integrated_client_version` are equal, if `a.server_version` and
/// `b.server_version` are equal. Otherwise checks that
/// `a.last_integrated_client_version` is less than, or equal to
/// `b.last_integrated_client_version`, if `a.server_version` is less than
/// `b.server_version`. Otherwise checks that `a.last_integrated_client_version`
/// is greater than, or equal to `b.last_integrated_client_version`.
bool are_mutually_consistent(DownloadCursor a, DownloadCursor b) noexcept;


/// \brief The server's reference to a position in the client-side history.
///
/// An upload cursor refers to a position in the client-side history. If
/// `client_version` is zero, the position is at the beginning of the history,
/// otherwise the position is after the entry whose changeset produced that
/// version. In general, positions are to be understood as places between two
/// adjacent history entries.
///
/// `last_integrated_server_version` is the version produced on the server by
/// the last changeset that was sent to the client and integrated into the
/// client-side Realm state at the time indicated by the history position
/// specified by `client_version`, or zero if no changesets from the server were
/// integrated by the client at that point in time.
struct UploadCursor {
    version_type client_version;
    version_type last_integrated_server_version;
};

/// Checks that `uc.last_integrated_server_version` is zero if
/// `uc.client_version` is zero.
bool is_consistent(UploadCursor uc) noexcept;

/// Checks that `a.last_integrated_server_version` and
/// `b.last_integrated_server_version` are equal, if `a.client_version` and
/// `b.client_version` are equal. Otherwise checks that
/// `a.last_integrated_server_version` is less than, or equal to
/// `b.last_integrated_server_version`, if `a.client_version` is less than
/// `b.client_version`. Otherwise checks that `a.last_integrated_server_version`
/// is greater than, or equal to `b.last_integrated_server_version`.
bool are_mutually_consistent(UploadCursor a, UploadCursor b) noexcept;


/// A client's record of the current point of progress of the synchronization
/// process. The client must store this persistently in the local Realm file.
struct SyncProgress {
    /// The last server version that the client has heard about.
    SaltedVersion latest_server_version = {0, 0};

    /// The last server version integrated, or about to be integrated by the
    /// client.
    DownloadCursor download = {0, 0};

    /// The last client version integrated by the server.
    UploadCursor upload = {0, 0};
};

struct CompensatingWriteErrorInfo {
    std::string object_name;
    OwnedMixed primary_key;
    std::string reason;
};

struct ResumptionDelayInfo {
    // This is the maximum delay between trying to resume a session/connection.
    std::chrono::milliseconds max_resumption_delay_interval = std::chrono::minutes{5};
    // The initial delay between trying to resume a session/connection.
    std::chrono::milliseconds resumption_delay_interval = std::chrono::seconds{1};
    // After each failure of the same type, the last delay will be multiplied by this value
    // until it is greater-than-or-equal to the max_resumption_delay_interval.
    int resumption_delay_backoff_multiplier = 2;
    // When calculating a new delay interval, a random value betwen zero and the result off
    // dividing the current delay value by the delay_jitter_divisor will be subtracted from the
    // delay interval. The default is to subtract up to 25% of the current delay interval.
    //
    // This is to reduce the likelyhood of a connection storm if the server goes down and
    // all clients attempt to reconnect at once.
    int delay_jitter_divisor = 4;
};

class IsFatalTag {};
using IsFatal = util::TaggedBool<class IsFatalTag>;

struct ProtocolErrorInfo {
    enum class Action {
        NoAction,
        ProtocolViolation,
        ApplicationBug,
        Warning,
        Transient,
        DeleteRealm,
        ClientReset,
        ClientResetNoRecovery,
        MigrateToFLX,
        RevertToPBS,
        // The RefreshUser/RefreshLocation/LogOutUser actions are currently generated internally when the
        // sync websocket is closed with specific error codes.
        RefreshUser,
        RefreshLocation,
        LogOutUser,
    };

    ProtocolErrorInfo() = default;
    ProtocolErrorInfo(int error_code, const std::string& msg, IsFatal is_fatal)
        : raw_error_code(error_code)
        , message(msg)
        , is_fatal(is_fatal)
        , client_reset_recovery_is_disabled(false)
        , should_client_reset(util::none)
        , server_requests_action(Action::NoAction)
    {
    }
    int raw_error_code = 0;
    std::string message;
    IsFatal is_fatal = IsFatal{true};
    bool client_reset_recovery_is_disabled = false;
    std::optional<bool> should_client_reset;
    std::optional<std::string> log_url;
    std::optional<version_type> compensating_write_server_version;
    version_type compensating_write_rejected_client_version = 0;
    std::vector<CompensatingWriteErrorInfo> compensating_writes;
    std::optional<ResumptionDelayInfo> resumption_delay_interval;
    Action server_requests_action;
    std::optional<std::string> migration_query_string;
};


/// \brief Protocol errors discovered by the server, and reported to the client
/// by way of ERROR messages.
///
/// These errors will be reported to the client-side application via the error
/// handlers of the affected sessions.
///
/// ATTENTION: Please remember to update is_session_level_error() when
/// adding/removing error codes.
enum class ProtocolError {
    // clang-format off

    // Connection level and protocol errors
    connection_closed            = RLM_SYNC_ERR_CONNECTION_CONNECTION_CLOSED,       // Connection closed (no error)
    other_error                  = RLM_SYNC_ERR_CONNECTION_OTHER_ERROR,             // Other connection level error
    unknown_message              = RLM_SYNC_ERR_CONNECTION_UNKNOWN_MESSAGE,         // Unknown type of input message
    bad_syntax                   = RLM_SYNC_ERR_CONNECTION_BAD_SYNTAX,              // Bad syntax in input message head
    limits_exceeded              = RLM_SYNC_ERR_CONNECTION_LIMITS_EXCEEDED,         // Limits exceeded in input message
    wrong_protocol_version       = RLM_SYNC_ERR_CONNECTION_WRONG_PROTOCOL_VERSION,  // Wrong protocol version (CLIENT) (obsolete)
    bad_session_ident            = RLM_SYNC_ERR_CONNECTION_BAD_SESSION_IDENT,       // Bad session identifier in input message
    reuse_of_session_ident       = RLM_SYNC_ERR_CONNECTION_REUSE_OF_SESSION_IDENT,  // Overlapping reuse of session identifier (BIND)
    bound_in_other_session       = RLM_SYNC_ERR_CONNECTION_BOUND_IN_OTHER_SESSION,  // Client file bound in other session (IDENT)
    bad_message_order            = RLM_SYNC_ERR_CONNECTION_BAD_MESSAGE_ORDER,       // Bad input message order
    bad_decompression            = RLM_SYNC_ERR_CONNECTION_BAD_DECOMPRESSION,       // Error in decompression (UPLOAD)
    bad_changeset_header_syntax  = RLM_SYNC_ERR_CONNECTION_BAD_CHANGESET_HEADER_SYNTAX, // Bad syntax in a changeset header (UPLOAD)
    bad_changeset_size           = RLM_SYNC_ERR_CONNECTION_BAD_CHANGESET_SIZE,      // Bad size specified in changeset header (UPLOAD)
    switch_to_flx_sync           = RLM_SYNC_ERR_CONNECTION_SWITCH_TO_FLX_SYNC,      // Connected with wrong wire protocol - should switch to FLX sync
    switch_to_pbs                = RLM_SYNC_ERR_CONNECTION_SWITCH_TO_PBS,           // Connected with wrong wire protocol - should switch to PBS

    // Session level errors
    session_closed               = RLM_SYNC_ERR_SESSION_SESSION_CLOSED,             // Session closed (no error)
    other_session_error          = RLM_SYNC_ERR_SESSION_OTHER_SESSION_ERROR,        // Other session level error
    token_expired                = RLM_SYNC_ERR_SESSION_TOKEN_EXPIRED,              // Access token expired
    bad_authentication           = RLM_SYNC_ERR_SESSION_BAD_AUTHENTICATION,         // Bad user authentication (BIND)
    illegal_realm_path           = RLM_SYNC_ERR_SESSION_ILLEGAL_REALM_PATH,         // Illegal Realm path (BIND)
    no_such_realm                = RLM_SYNC_ERR_SESSION_NO_SUCH_REALM,              // No such Realm (BIND)
    permission_denied            = RLM_SYNC_ERR_SESSION_PERMISSION_DENIED,          // Permission denied (BIND)
    bad_server_file_ident        = RLM_SYNC_ERR_SESSION_BAD_SERVER_FILE_IDENT,      // Bad server file identifier (IDENT) (obsolete!)
    bad_client_file_ident        = RLM_SYNC_ERR_SESSION_BAD_CLIENT_FILE_IDENT,      // Bad client file identifier (IDENT)
    bad_server_version           = RLM_SYNC_ERR_SESSION_BAD_SERVER_VERSION,         // Bad server version (IDENT, UPLOAD, TRANSACT)
    bad_client_version           = RLM_SYNC_ERR_SESSION_BAD_CLIENT_VERSION,         // Bad client version (IDENT, UPLOAD)
    diverging_histories          = RLM_SYNC_ERR_SESSION_DIVERGING_HISTORIES,        // Diverging histories (IDENT)
    bad_changeset                = RLM_SYNC_ERR_SESSION_BAD_CHANGESET,              // Bad changeset (UPLOAD, ERROR)
    partial_sync_disabled        = RLM_SYNC_ERR_SESSION_PARTIAL_SYNC_DISABLED,      // Partial sync disabled (BIND)
    unsupported_session_feature  = RLM_SYNC_ERR_SESSION_UNSUPPORTED_SESSION_FEATURE, // Unsupported session-level feature
    bad_origin_file_ident        = RLM_SYNC_ERR_SESSION_BAD_ORIGIN_FILE_IDENT,      // Bad origin file identifier (UPLOAD)
    bad_client_file              = RLM_SYNC_ERR_SESSION_BAD_CLIENT_FILE,            // Synchronization no longer possible for client-side file
    server_file_deleted          = RLM_SYNC_ERR_SESSION_SERVER_FILE_DELETED,        // Server file was deleted while session was bound to it
    client_file_blacklisted      = RLM_SYNC_ERR_SESSION_CLIENT_FILE_BLACKLISTED,    // Client file has been blacklisted (IDENT)
    user_blacklisted             = RLM_SYNC_ERR_SESSION_USER_BLACKLISTED,           // User has been blacklisted (BIND)
    transact_before_upload       = RLM_SYNC_ERR_SESSION_TRANSACT_BEFORE_UPLOAD,     // Serialized transaction before upload completion
    client_file_expired          = RLM_SYNC_ERR_SESSION_CLIENT_FILE_EXPIRED,        // Client file has expired
    user_mismatch                = RLM_SYNC_ERR_SESSION_USER_MISMATCH,              // User mismatch for client file identifier (IDENT)
    too_many_sessions            = RLM_SYNC_ERR_SESSION_TOO_MANY_SESSIONS,          // Too many sessions in connection (BIND)
    invalid_schema_change        = RLM_SYNC_ERR_SESSION_INVALID_SCHEMA_CHANGE,      // Invalid schema change (UPLOAD)
    bad_query                    = RLM_SYNC_ERR_SESSION_BAD_QUERY,                  // Client query is invalid/malformed (IDENT, QUERY)
    object_already_exists        = RLM_SYNC_ERR_SESSION_OBJECT_ALREADY_EXISTS,      // Client tried to create an object that already exists outside their view (UPLOAD)
    server_permissions_changed   = RLM_SYNC_ERR_SESSION_SERVER_PERMISSIONS_CHANGED, // Server permissions for this file ident have changed since the last time it was used (IDENT)
    initial_sync_not_completed   = RLM_SYNC_ERR_SESSION_INITIAL_SYNC_NOT_COMPLETED, // Client tried to open a session before initial sync is complete (BIND)
    write_not_allowed            = RLM_SYNC_ERR_SESSION_WRITE_NOT_ALLOWED,          // Client attempted a write that is disallowed by permissions, or modifies an
                                                                                    // object outside the current query - requires client reset (UPLOAD)
    compensating_write           = RLM_SYNC_ERR_SESSION_COMPENSATING_WRITE,         // Client attempted a write that is disallowed by permissions, or modifies an
                                                                                    // object outside the current query, and the server undid the modification
                                                                                    // (UPLOAD)
    migrate_to_flx               = RLM_SYNC_ERR_SESSION_MIGRATE_TO_FLX,             // Server migrated from PBS to FLX - migrate client to FLX (BIND)
    bad_progress                 = RLM_SYNC_ERR_SESSION_BAD_PROGRESS,               // Bad progress information (ERROR)
    revert_to_pbs                = RLM_SYNC_ERR_SESSION_REVERT_TO_PBS,              // Server rolled back to PBS after FLX migration - revert FLX client migration (BIND)

    // clang-format on
};

Status protocol_error_to_status(ProtocolError raw_error_code, std::string_view msg);

constexpr bool is_session_level_error(ProtocolError);

/// Returns null if the specified protocol error code is not defined by
/// ProtocolError.
const char* get_protocol_error_message(int error_code) noexcept;
std::ostream& operator<<(std::ostream&, ProtocolError protocol_error);

// Implementation

inline bool is_consistent(DownloadCursor dc) noexcept
{
    return (dc.server_version != 0 || dc.last_integrated_client_version == 0);
}

inline bool are_mutually_consistent(DownloadCursor a, DownloadCursor b) noexcept
{
    if (a.server_version < b.server_version)
        return (a.last_integrated_client_version <= b.last_integrated_client_version);
    if (a.server_version > b.server_version)
        return (a.last_integrated_client_version >= b.last_integrated_client_version);
    return (a.last_integrated_client_version == b.last_integrated_client_version);
}

inline bool is_consistent(UploadCursor uc) noexcept
{
    return (uc.client_version != 0 || uc.last_integrated_server_version == 0);
}

inline bool are_mutually_consistent(UploadCursor a, UploadCursor b) noexcept
{
    if (a.client_version < b.client_version)
        return (a.last_integrated_server_version <= b.last_integrated_server_version);
    if (a.client_version > b.client_version)
        return (a.last_integrated_server_version >= b.last_integrated_server_version);
    return (a.last_integrated_server_version == b.last_integrated_server_version);
}

constexpr bool is_session_level_error(ProtocolError error)
{
    return int(error) >= 200 && int(error) <= 299;
}

inline std::ostream& operator<<(std::ostream& o, ProtocolErrorInfo::Action action)
{
    switch (action) {
        case ProtocolErrorInfo::Action::NoAction:
            return o << "NoAction";
        case ProtocolErrorInfo::Action::ProtocolViolation:
            return o << "ProtocolViolation";
        case ProtocolErrorInfo::Action::ApplicationBug:
            return o << "ApplicationBug";
        case ProtocolErrorInfo::Action::Warning:
            return o << "Warning";
        case ProtocolErrorInfo::Action::Transient:
            return o << "Transient";
        case ProtocolErrorInfo::Action::DeleteRealm:
            return o << "DeleteRealm";
        case ProtocolErrorInfo::Action::ClientReset:
            return o << "ClientReset";
        case ProtocolErrorInfo::Action::ClientResetNoRecovery:
            return o << "ClientResetNoRecovery";
        case ProtocolErrorInfo::Action::MigrateToFLX:
            return o << "MigrateToFLX";
        case ProtocolErrorInfo::Action::RevertToPBS:
            return o << "RevertToPBS";
        case ProtocolErrorInfo::Action::RefreshUser:
            return o << "RefreshUser";
        case ProtocolErrorInfo::Action::RefreshLocation:
            return o << "RefreshLocation";
        case ProtocolErrorInfo::Action::LogOutUser:
            return o << "LogOutUser";
    }
    return o << "Invalid error action: " << int64_t(action);
}

} // namespace sync
} // namespace realm

#endif // REALM_SYNC_PROTOCOL_HPP
