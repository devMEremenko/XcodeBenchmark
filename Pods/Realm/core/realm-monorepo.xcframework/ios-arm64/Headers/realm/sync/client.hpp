#ifndef REALM_SYNC_CLIENT_HPP
#define REALM_SYNC_CLIENT_HPP

#include <cstddef>
#include <cstdint>
#include <exception>
#include <functional>
#include <memory>
#include <string>
#include <utility>

#include <realm/util/buffer.hpp>
#include <realm/util/functional.hpp>
#include <realm/util/future.hpp>
#include <realm/sync/client_base.hpp>

namespace realm::sync {

class MigrationStore;
class SubscriptionStore;

class Client {
public:
    using port_type = sync::port_type;

    static constexpr milliseconds_type default_connect_timeout = sync::default_connect_timeout;
    static constexpr milliseconds_type default_connection_linger_time = sync::default_connection_linger_time;
    static constexpr milliseconds_type default_ping_keepalive_period = sync::default_ping_keepalive_period;
    static constexpr milliseconds_type default_pong_keepalive_timeout = sync::default_pong_keepalive_timeout;
    static constexpr milliseconds_type default_fast_reconnect_limit = sync::default_fast_reconnect_limit;

    using Config = ClientConfig;

    /// \throw util::EventLoop::Implementation::NotAvailable if no event loop
    /// implementation was specified, and
    /// util::EventLoop::Implementation::get_default() throws it.
    Client(Config = {});
    Client(Client&&) noexcept;
    ~Client() noexcept;

    /// Run the internal event-loop of the client. At most one thread may
    /// execute run() at any given time. The call will not return until somebody
    /// calls stop().
    void run() noexcept;

    /// See run().
    ///
    /// Thread-safe.
    void shutdown() noexcept;

    /// Forces all connections to close and waits for any pending work on the event
    /// loop to complete. All sessions must be destroyed before calling shutdown_and_wait.
    void shutdown_and_wait();

    /// \brief Cancel current or next reconnect delay for all servers.
    ///
    /// This corresponds to calling Session::cancel_reconnect_delay() on all
    /// bound sessions, but will also cancel reconnect delays applying to
    /// servers for which there are currently no bound sessions.
    ///
    /// Thread-safe.
    void cancel_reconnect_delay();

    /// Forces all open connections to disconnect/reconnect. To be used in testing.
    void voluntary_disconnect_all_connections();

    /// \brief Wait for session termination to complete.
    ///
    /// Wait for termination of all sessions whose termination was initiated
    /// prior this call (the completion condition), or until the client's event
    /// loop thread exits from Client::run(), whichever happens
    /// first. Termination of a session can be initiated implicitly (e.g., via
    /// destruction of the session object), or explicitly by Session::detach().
    ///
    /// Note: After session termination (when this function returns true) no
    /// session specific callback function can be called or continue to execute,
    /// and the client is guaranteed to no longer have a Realm file open on
    /// behalf of the terminated session.
    ///
    /// CAUTION: If run() returns while a wait operation is in progress, this
    /// waiting function will return immediately, even if the completion
    /// condition is not yet satisfied. The completion condition is guaranteed
    /// to be satisfied only when these functions return true. If it returns
    /// false, session specific callback functions may still be executing or get
    /// called, and the associated Realm files may still not have been closed.
    ///
    /// If a new wait operation is initiated while another wait operation is in
    /// progress by another thread, the waiting period of fist operation may, or
    /// may not get extended. The application must not assume either.
    ///
    /// Note: Session termination does not imply that the client has received an
    /// UNBOUND message from the server (see the protocol specification). This
    /// may happen later.
    ///
    /// \return True only if the completion condition was satisfied. False if
    /// the client's event loop thread exited from Client::run() in which case
    /// the completion condition may, or may not have been satisfied.
    ///
    /// Note: These functions are fully thread-safe. That is, they may be called
    /// by any thread, and by multiple threads concurrently.
    bool wait_for_session_terminations_or_client_stopped();

    /// Returns false if the specified URL is invalid.
    bool decompose_server_url(const std::string& url, ProtocolEnvelope& protocol, std::string& address,
                              port_type& port, std::string& path) const;

private:
    std::unique_ptr<ClientImpl> m_impl;
    friend class Session;
};


class BadServerUrl; // Exception


/// \brief Client-side representation of a Realm file synchronization session.
///
/// A synchronization session deals with precisely one local Realm file. To
/// synchronize multiple local Realm files, you need multiple sessions.
///
/// A session object is always associated with a particular client object (\ref
/// Client). The application must ensure that the destruction of the associated
/// client object never happens before the destruction of the session
/// object. The consequences of a violation are unspecified.
///
/// A session object is always associated with a particular local Realm file,
/// however, a session object does not represent a session until it is bound to
/// a server side Realm, i.e., until bind() is called. From the point of view of
/// the thread that calls bind(), the session starts precisely when the
/// execution of bind() starts, i.e., before bind() returns.
///
/// At most one session is allowed to exist for a particular local Realm file
/// (file system inode) at any point in time. Multiple session objects may
/// coexists for a single file, as long as bind() has been called on at most one
/// of them. Additionally, two bound session objects for the same file are
/// allowed to exist at different times, if they have no overlap in time (in
/// their bound state), as long as they are associated with the same client
/// object, or with two different client objects that do not overlap in
/// time. This means, in particular, that it is an error to create two bound
/// session objects for the same local Realm file, if they are associated with
/// two different client objects that overlap in time, even if the session
/// objects do not overlap in time (in their bound state). It is the
/// responsibility of the application to ensure that these rules are adhered
/// to. The consequences of a violation are unspecified.
///
/// Thread-safety: It is safe for multiple threads to construct, use (with some
/// exceptions), and destroy session objects concurrently, regardless of whether
/// those session objects are associated with the same, or with different Client
/// objects. Please note that some of the public member functions are fully
/// thread-safe, while others are not.
///
/// Callback semantics: All session specific callback functions will be executed
/// by the event loop thread, i.e., the thread that calls Client::run(). No
/// callback function will be called before Session::bind() is called. Callback
/// functions that are specified prior to calling bind() (e.g., any passed to
/// set_progress_handler()) may start to execute before bind() returns, as long
/// as some thread is executing Client::run(). Likewise, completion handlers,
/// such as those passed to async_wait_for_sync_completion() may start to
/// execute before the submitting function returns. All session specific
/// callback functions (including completion handlers) are guaranteed to no
/// longer be executing when session termination completes, and they are
/// guaranteed to not be called after session termination completes. Termination
/// is an event that completes asynchronously with respect to the application,
/// but is initiated by calling detach(), or implicitly by destroying a session
/// object. After having initiated one or more session terminations, the
/// application can wait for those terminations to complete by calling
/// Client::wait_for_session_terminations_or_client_stopped(). Since callback
/// functions are always executed by the event loop thread, they are also
/// guaranteed to not be executing after Client::run() has returned.
class Session {
public:
    using ErrorInfo = SessionErrorInfo;
    using port_type = sync::port_type;
    using SyncTransactCallback = void(VersionID old_version, VersionID new_version);
    using ProgressHandler = void(std::uint_fast64_t downloaded_bytes, std::uint_fast64_t downloadable_bytes,
                                 std::uint_fast64_t uploaded_bytes, std::uint_fast64_t uploadable_bytes,
                                 std::uint_fast64_t progress_version, std::uint_fast64_t snapshot_version);
    using WaitOperCompletionHandler = util::UniqueFunction<void(Status)>;
    using SSLVerifyCallback = bool(const std::string& server_address, port_type server_port, const char* pem_data,
                                   size_t pem_size, int preverify_ok, int depth);

    struct Config {
        Config() {}

        /// server_address is the fully qualified host name, or IP address of
        /// the server.
        std::string server_address = "localhost";

        /// server_port is the port at which the server listens. If server_port
        /// is zero, the default port for the specified protocol is used. See
        /// ProtocolEnvelope for information on default ports.
        port_type server_port = 0;

        /// realm_identifier is  the virtual path by which the server identifies the
        /// Realm.
        /// When connecting to the mock C++ server, this path must always be an
        /// absolute path, and must therefore always contain a leading slash (`/`).
        /// Furthermore, each segment of the virtual path must consist of one or
        /// more characters that are either alpha-numeric or in (`_`, `-`, `.`),
        /// and each segment is not allowed to equal `.` or `..`, and must not end
        /// with `.realm`, `.realm.lock`, or `.realm.management`. These rules are
        /// necessary because the C++ server currently reserves the right to use the
        /// specified path as part of the file system path of a Realm file.
        /// On the MongoDB Realm-based Sync server, virtual paths are not coupled
        /// to file system paths, and thus, these restrictions do not apply.
        std::string realm_identifier = "";

        /// The user id of the logged in user for this sync session. This will be used
        /// along with the server_address/server_port/protocol_envelope to determine
        /// which connection to the server this session will use.
        std::string user_id;

        /// The protocol used for communicating with the server. See
        /// ProtocolEnvelope.
        ProtocolEnvelope protocol_envelope = ProtocolEnvelope::realm;

        /// service_identifier is a prefix that is prepended to the realm_identifier
        /// in the HTTP GET request that initiates a sync connection. The value
        /// specified here must match with the server's expectation. Changing
        /// the value of service_identifier should be matched with a corresponding
        /// change in the C++ mock server.
        std::string service_identifier = "";

        ///
        /// DEPRECATED - Will be removed in a future release
        ///
        /// authorization_header_name is the name of the HTTP header containing
        /// the Realm access token. The value of the HTTP header is "Bearer <token>".
        /// authorization_header_name does not participate in session
        /// multiplexing partitioning.
        std::string authorization_header_name = "Authorization";

        ///
        /// DEPRECATED - Will be removed in a future release
        ///
        /// custom_http_headers is a map of custom HTTP headers. The keys of the map
        /// are HTTP header names, and the values are the corresponding HTTP
        /// header values.
        /// If "Authorization" is used as a custom header name,
        /// authorization_header_name must be set to anther value.
        std::map<std::string, std::string> custom_http_headers;

        ///
        /// DEPRECATED - Will be removed in a future release
        ///
        /// Controls whether the server certificate is verified for SSL
        /// connections. It should generally be true in production.
        bool verify_servers_ssl_certificate = true;

        ///
        /// DEPRECATED - Will be removed in a future release
        ///
        /// ssl_trust_certificate_path is the path of a trust/anchor
        /// certificate used by the client to verify the server certificate.
        /// ssl_trust_certificate_path is only used if the protocol is ssl and
        /// verify_servers_ssl_certificate is true.
        ///
        /// A server certificate is verified by first checking that the
        /// certificate has a valid signature chain back to a trust/anchor
        /// certificate, and secondly checking that the server_address matches
        /// a host name contained in the certificate. The host name of the
        /// certificate is stored in either Common Name or the Alternative
        /// Subject Name (DNS section).
        ///
        /// If ssl_trust_certificate_path is None (default), ssl_verify_callback
        /// (see below) is used if set, and the default device trust/anchor
        /// store is used otherwise.
        util::Optional<std::string> ssl_trust_certificate_path;

        ///
        /// DEPRECATED - Will be removed in a future release
        ///
        /// If Client::Config::ssl_verify_callback is set, that function is called
        /// to verify the certificate, unless verify_servers_ssl_certificate is
        /// false.

        /// ssl_verify_callback is used to implement custom SSL certificate
        /// verification. it is only used if the protocol is SSL,
        /// verify_servers_ssl_certificate is true and ssl_trust_certificate_path
        /// is None.
        ///
        /// The signature of ssl_verify_callback is
        ///
        /// bool(const std::string& server_address,
        ///      port_type server_port,
        ///      const char* pem_data,
        ///      size_t pem_size,
        ///      int preverify_ok,
        ///      int depth);
        ///
        /// server address and server_port is the address and port of the server
        /// that a SSL connection is being established to. They are identical to
        /// the server_address and server_port set in this config file and are
        /// passed for convenience.
        /// pem_data is the certificate of length pem_size in
        /// the PEM format. preverify_ok is OpenSSL's preverification of the
        /// certificate. preverify_ok is either 0, or 1. If preverify_ok is 1,
        /// OpenSSL has accepted the certificate and it will generally be safe
        /// to trust that certificate. depth represents the position of the
        /// certificate in the certificate chain sent by the server. depth = 0
        /// represents the actual server certificate that should contain the
        /// host name(server address) of the server. The highest depth is the
        /// root certificate.
        /// The callback function will receive the certificates starting from
        /// the root certificate and moving down the chain until it reaches the
        /// server's own certificate with a host name. The depth of the last
        /// certificate is 0. The depth of the first certificate is chain
        /// length - 1.
        ///
        /// The return value of the callback function decides whether the
        /// client accepts the certificate. If the return value is false, the
        /// processing of the certificate chain is interrupted and the SSL
        /// connection is rejected. If the return value is true, the verification
        /// process continues. If the callback function returns true for all
        /// presented certificates including the depth == 0 certificate, the
        /// SSL connection is accepted.
        ///
        /// A recommended way of using the callback function is to return true
        /// if preverify_ok = 1 and depth > 0,
        /// always check the host name if depth = 0,
        /// and use an independent verification step if preverify_ok = 0.
        ///
        /// Another possible way of using the callback is to collect all the
        /// certificates until depth = 0, and present the entire chain for
        /// independent verification.
        std::function<SSLVerifyCallback> ssl_verify_callback;

        /// signed_user_token is a cryptographically signed token describing the
        /// identity and access rights of the current user.
        std::string signed_user_token;

        using ClientReset = sync::ClientReset;
        util::Optional<ClientReset> client_reset_config;

        ///
        /// DEPRECATED - Will be removed in a future release
        ///
        util::Optional<SyncConfig::ProxyConfig> proxy_config;

        /// When integrating a flexible sync bootstrap, process this many bytes of
        /// changeset data in a single integration attempt.
        size_t flx_bootstrap_batch_size_bytes = 1024 * 1024;

        /// Set to true to cause the integration of the first received changeset
        /// (in a DOWNLOAD message) to fail.
        ///
        /// This feature exists exclusively for testing purposes at this time.
        bool simulate_integration_error = false;

        std::function<SyncClientHookAction(const SyncClientHookData&)> on_sync_client_event_hook;

        /// The reason this synchronization session is used for.
        ///
        /// Note: Currently only used in FLX sync.
        SessionReason session_reason = SessionReason::Sync;
    };

    /// \brief Start a new session for the specified client-side Realm.
    ///
    /// Note that the session is not fully activated until you call bind().
    /// Also note that if you call set_sync_transact_callback(), it must be
    /// done before calling bind().
    Session(Client&, std::shared_ptr<DB>, std::shared_ptr<SubscriptionStore>, std::shared_ptr<MigrationStore>,
            Config&& = {});

    /// This leaves the right-hand side session object detached. See "Thread
    /// safety" section under detach().
    Session(Session&&) noexcept;

    /// Create a detached session object (see detach()).
    Session() noexcept = default;

    /// Implies detachment. See "Thread safety" section under detach().
    ~Session() noexcept;

    /// Detach the object on the left-hand side, then "steal" the session from
    /// the object on the right-hand side, if there is one. This leaves the
    /// object on the right-hand side detached. See "Thread safety" section
    /// under detach().
    Session& operator=(Session&&) noexcept;

    /// Detach this session object from the client object (Client). If the
    /// session object is already detached, this function has no effect
    /// (idempotency).
    ///
    /// Detachment initiates session termination, which is an event that takes
    /// place shortly thereafter in the context of the client's event loop
    /// thread.
    ///
    /// A detached session object may be destroyed, move-assigned to, and moved
    /// from. Apart from that, it is an error to call any function other than
    /// detach() on a detached session object.
    ///
    /// Thread safety: Detachment is not a thread-safe operation. This means
    /// that detach() may not be executed by two threads concurrently, and may
    /// not execute concurrently with object destruction. Additionally,
    /// detachment must not execute concurrently with a moving operation
    /// involving the session object on the left or right-hand side. See move
    /// constructor and assignment operator.
    void detach() noexcept;

    /// \brief Set a function to be called when the local Realm has changed due
    /// to integration of a downloaded changeset.
    ///
    /// Specify the callback function that will be called when one or more
    /// transactions are performed to integrate downloaded changesets into the
    /// client-side Realm, that is associated with this session.
    ///
    /// The callback function will always be called by the thread that executes
    /// the event loop (Client::run()), but not until bind() is called. If the
    /// callback function throws an exception, that exception will "travel" out
    /// through Client::run().
    ///
    /// Note: Any call to this function must have returned before bind() is
    /// called. If this function is called multiple times, each call overrides
    /// the previous setting.
    ///
    /// Note: This function is **not thread-safe**. That is, it is an error if
    /// it is called while another thread is executing any member function on
    /// the same Session object.
    ///
    /// CAUTION: The specified callback function may get called before the call
    /// to bind() returns, and it may get called (or continue to execute) after
    /// the session object is destroyed. Please see "Callback semantics" section
    /// under Session for more on this.
    void set_sync_transact_callback(util::UniqueFunction<SyncTransactCallback>);

    /// \brief Set a handler to monitor the state of download and upload
    /// progress.
    ///
    /// The handler must have signature
    ///
    ///     void(uint_fast64_t downloaded_bytes, uint_fast64_t downloadable_bytes,
    ///          uint_fast64_t uploaded_bytes, uint_fast64_t uploadable_bytes,
    ///          uint_fast64_t progress_version);
    ///
    /// downloaded_bytes is the size in bytes of all downloaded changesets.
    /// downloadable_bytes is equal to downloaded_bytes plus an estimate of
    /// the size of the remaining server history.
    ///
    /// uploaded_bytes is the size in bytes of all locally produced changesets
    /// that have been received and acknowledged by the server.
    /// uploadable_bytes is the size in bytes of all locally produced changesets.
    ///
    /// Due to the nature of the merge rules, it is possible that the size of an
    /// uploaded changeset uploaded from one client is not equal to the size of
    /// the changesets that other clients will download.
    ///
    /// Typical uses of this function:
    ///
    /// Upload completion can be checked by
    ///
    ///    bool upload_complete = (uploaded_bytes == uploadable_bytes);
    ///
    /// Download completion could be checked by
    ///
    ///     bool download_complete = (downloaded_bytes == downloadable_bytes);
    ///
    /// However, download completion might never be reached because the server
    /// can receive new changesets from other clients. downloadable_bytes can
    /// decrease for two reasons: server side compaction and changesets of
    /// local origin. Code using downloadable_bytes must not assume that it
    /// is increasing.
    ///
    /// Upload progress can be calculated by caching an initial value of
    /// uploaded_bytes from the last, or next, callback. Then
    ///
    ///     double upload_progress =
    ///        (uploaded_bytes - initial_uploaded_bytes)
    ///       -------------------------------------------
    ///       (uploadable_bytes - initial_uploaded_bytes)
    ///
    /// Download progress can be calculates similarly:
    ///
    ///     double download_progress =
    ///        (downloaded_bytes - initial_downloaded_bytes)
    ///       -----------------------------------------------
    ///       (downloadable_bytes - initial_downloaded_bytes)
    ///
    /// progress_version is 0 at the start of a session. When at least one
    /// DOWNLOAD message has been received from the server, progress_version is
    /// positive. progress_version can be used to ensure that the reported
    /// progress contains information obtained from the server in the current
    /// session. The server will send a message as soon as possible, and the
    /// progress handler will eventually be called with a positive progress_version
    /// unless the session is interrupted before a message from the server has
    /// been received.
    ///
    /// The handler is called on the event loop thread.The handler after bind(),
    /// after each DOWNLOAD message, and after each local transaction
    /// (nonsync_transact_notify).
    ///
    /// set_progress_handler() is not thread safe and it must be called before
    /// bind() is called. Subsequent calls to set_progress_handler() overwrite
    /// the previous calls. Typically, this function is called once per session.
    ///
    /// CAUTION: The specified callback function may get called before the call
    /// to bind() returns, and it may get called (or continue to execute) after
    /// the session object is destroyed. Please see "Callback semantics" section
    /// under Session for more on this.
    void set_progress_handler(util::UniqueFunction<ProgressHandler>);

    using ConnectionStateChangeListener = void(ConnectionState, util::Optional<SessionErrorInfo>);

    /// \brief Install a connection state change listener.
    ///
    /// Sets a function to be called whenever the state of the underlying
    /// network connection changes between "disconnected", "connecting", and
    /// "connected". The initial state is always "disconnected". The next state
    /// after "disconnected" is always "connecting". The next state after
    /// "connecting" is either "connected" or "disconnected". The next state
    /// after "connected" is always "disconnected". A switch to the
    /// "disconnected" state only happens when an error occurs.
    ///
    /// Whenever the installed function is called, an SessionErrorInfo object is passed
    /// when, and only when the passed state is ConnectionState::disconnected.
    ///
    /// When multiple sessions share a single connection, the state changes will
    /// be reported for each session in turn.
    ///
    /// The callback function will always be called by the thread that executes
    /// the event loop (Client::run()), but not until bind() is called. If the
    /// callback function throws an exception, that exception will "travel" out
    /// through Client::run().
    ///
    /// Note: Any call to this function must have returned before bind() is
    /// called. If this function is called multiple times, each call overrides
    /// the previous setting.
    ///
    /// Note: This function is **not thread-safe**. That is, it is an error if
    /// it is called while another thread is executing any member function on
    /// the same Session object.
    ///
    /// CAUTION: The specified callback function may get called before the call
    /// to bind() returns, and it may get called (or continue to execute) after
    /// the session object is destroyed. Please see "Callback semantics" section
    /// under Session for more on this.
    void set_connection_state_change_listener(util::UniqueFunction<ConnectionStateChangeListener>);

    //@{
    /// Deprecated! Use set_connection_state_change_listener() instead.
    using ErrorHandler = void(const SessionErrorInfo&);
    void set_error_handler(util::UniqueFunction<ErrorHandler>);
    //@}

    /// @{ \brief Bind this session to the specified server side Realm.
    ///
    /// No communication takes place on behalf of this session before the
    /// session is bound, but as soon as the session becomes bound, the server
    /// will start to push changes to the client, and vice versa.
    ///
    /// If a callback function was set using set_sync_transact_callback(), then
    /// that callback function will start to be called as changesets are
    /// downloaded and integrated locally. It is important to understand that
    /// callback functions are executed by the event loop thread (Client::run())
    /// and the callback function may therefore be called before bind() returns.
    ///
    /// Note: It is an error if this function is called more than once per
    /// Session object.
    ///
    /// Note: This function is **not thread-safe**. That is, it is an error if
    /// it is called while another thread is executing any member function on
    /// the same Session object.
    ///
    /// bind() binds this session to the specified server side Realm using the
    /// parameters specified in the Session::Config object.
    ///
    /// The two other forms of bind() are convenience functions.
    void bind();

    /// @}

    /// \brief Refresh the access token associated with this session.
    ///
    /// This causes the REFRESH protocol message to be sent to the server. See
    /// ProtocolEnvelope. It is an error to pass a token with a different user
    /// identity than the token used to initiate the session.
    ///
    /// In an on-going session the application may expect the access token to
    /// expire at a certain time and schedule acquisition of a fresh access
    /// token (using a refresh token or by other means) in due time to provide a
    /// better user experience, and seamless connectivity to the server.
    ///
    /// If the application does not proactively refresh an expiring token, the
    /// session will eventually be disconnected. The application can detect this
    /// by monitoring the connection state
    /// (set_connection_state_change_listener()), and check whether the error
    /// code is `ProtocolError::token_expired`. Such a session can then be
    /// revived by calling refresh() with a newly acquired access token.
    ///
    /// Due to protocol techicalities, a race condition exists that can cause a
    /// session to become, and remain disconnected after a new access token has
    /// been passed to refresh(). The application can work around this race
    /// condition by detecting the `ProtocolError::token_expired` error, and
    /// always initiate a token renewal in this case.
    ///
    /// It is an error to call this function before calling `Client::bind()`.
    ///
    /// Note: This function is thread-safe.
    ///
    /// \param signed_user_token A cryptographically signed token describing the
    /// identity and access rights of the current user. See ProtocolEnvelope.
    void refresh(const std::string& signed_user_token);

    /// \brief Inform the synchronization agent about changes of local origin.
    ///
    /// This function must be called by the application after a transaction
    /// performed on its behalf, that is, after a transaction that is not
    /// performed to integrate a changeset that was downloaded from the server.
    ///
    /// It is an error to call this function before bind() has been called, and
    /// has returned.
    ///
    /// Note: This function is fully thread-safe. That is, it may be called by
    /// any thread, and by multiple threads concurrently.
    void nonsync_transact_notify(version_type new_version);

    /// @{ \brief Wait for upload, download, or upload+download completion.
    ///
    /// async_wait_for_upload_completion() initiates an asynchronous wait for
    /// upload to complete, async_wait_for_download_completion() initiates an
    /// asynchronous wait for download to complete, and
    /// async_wait_for_sync_completion() initiates an asynchronous wait for
    /// upload and download to complete.
    ///
    /// Upload is considered complete when all non-empty changesets of local
    /// origin have been uploaded to the server, and the server has acknowledged
    /// reception of them. Changesets of local origin introduced after the
    /// initiation of the session (after bind() is called) will generally not be
    /// considered for upload unless they are announced to this client through
    /// nonsync_transact_notify() prior to the initiation of the wait operation,
    /// i.e., prior to the invocation of async_wait_for_upload_completion() or
    /// async_wait_for_sync_completion(). Unannounced changesets may get picked
    /// up, but there is no guarantee that they will be, however, if a certain
    /// changeset is announced, then all previous changesets are implicitly
    /// announced. Also all preexisting changesets are implicitly announced
    /// when the session is initiated.
    ///
    /// Download is considered complete when all non-empty changesets of remote
    /// origin have been downloaded from the server, and integrated into the
    /// local Realm state. To know what is currently outstanding on the server,
    /// the client always sends a special "marker" message to the server, and
    /// waits until it has downloaded all outstanding changesets that were
    /// present on the server at the time when the server received that marker
    /// message. Each call to async_wait_for_download_completion() and
    /// async_wait_for_sync_completion() therefore requires a full client <->
    /// server round-trip.
    ///
    /// If a new wait operation is initiated while another wait operation is in
    /// progress by another thread, the waiting period of first operation may,
    /// or may not get extended. The application must not assume either. The
    /// application may assume, however, that async_wait_for_upload_completion()
    /// will not affect the waiting period of
    /// async_wait_for_download_completion(), and vice versa.
    ///
    /// It is an error to call these functions before bind() has been called,
    /// and has returned.
    ///
    /// The specified completion handlers will always be executed by the thread
    /// that executes the event loop (the thread that calls Client::run()). If
    /// the handler throws an exception, that exception will "travel" out
    /// through Client::run().
    ///
    /// If incomplete wait operations exist when the session is terminated,
    /// those wait operations will be canceled. Session termination is an event
    /// that happens in the context of the client's event loop thread shortly
    /// after the destruction of the session object. The Status
    /// argument passed to the completion handler of a canceled wait operation
    /// will be `ErrorCodes::OperationAborted`. For uncanceled wait operations
    /// it will be `Status::OK()`. Note that as long as the client's event
    /// loop thread is running, all completion handlers will be called
    /// regardless of whether the operations get canceled or not.
    ///
    /// CAUTION: The specified completion handlers may get called before the
    /// call to the waiting function returns, and it may get called (or continue
    /// to execute) after the session object is destroyed. Please see "Callback
    /// semantics" section under Session for more on this.
    ///
    /// Note: These functions are fully thread-safe. That is, they may be called
    /// by any thread, and by multiple threads concurrently.
    void async_wait_for_sync_completion(WaitOperCompletionHandler);
    void async_wait_for_upload_completion(WaitOperCompletionHandler);
    void async_wait_for_download_completion(WaitOperCompletionHandler);
    /// @}

    /// @{ \brief Synchronous wait for upload or download completion.
    ///
    /// These functions are synchronous equivalents of
    /// async_wait_for_upload_completion() and
    /// async_wait_for_download_completion() respectively. This means that they
    /// block the caller until the completion condition is satisfied, or the
    /// client's event loop thread exits from Client::run(), whichever happens
    /// first.
    ///
    /// It is an error to call these functions before bind() has been called,
    /// and has returned.
    ///
    /// CAUTION: If Client::run() returns while a wait operation is in progress,
    /// these waiting functions return immediately, even if the completion
    /// condition is not yet satisfied. The completion condition is guaranteed
    /// to be satisfied only when these functions return true.
    ///
    /// \return True only if the completion condition was satisfied. False if
    /// the client's event loop thread exited from Client::run() in which case
    /// the completion condition may, or may not have been satisfied.
    ///
    /// Note: These functions are fully thread-safe. That is, they may be called
    /// by any thread, and by multiple threads concurrently.
    bool wait_for_upload_complete_or_client_stopped();
    bool wait_for_download_complete_or_client_stopped();
    /// @}

    /// \brief Cancel the current or next reconnect delay for the server
    /// associated with this session.
    ///
    /// When the network connection is severed, or an attempt to establish
    /// connection fails, a certain delay will take effect before the client
    /// will attempt to reestablish the connection. This delay will generally
    /// grow with the number of unsuccessful reconnect attempts, and can grow to
    /// over a minute. In some cases however, the application will know when it
    /// is a good time to stop waiting and retry immediately. One example is
    /// when a device has been offline for a while, and the operating system
    /// then tells the application that network connectivity has been restored.
    ///
    /// Clearly, this function should not be called too often and over extended
    /// periods of time, as that would effectively disable the built-in "server
    /// hammering" protection.
    ///
    /// It is an error to call this function before bind() has been called, and
    /// has returned.
    ///
    /// This function is fully thread-safe. That is, it may be called by any
    /// thread, and by multiple threads concurrently.
    void cancel_reconnect_delay();

    void on_new_flx_sync_subscription(int64_t new_version);

    util::Future<std::string> send_test_command(std::string command_body);

    /// Returns the app services connection id if the session is connected, otherwise
    /// returns an empty string. This function blocks until the value is set from
    /// the event loop thread. If an error occurs, this will throw an ExceptionForStatus
    /// with the error.
    std::string get_appservices_connection_id();

private:
    SessionWrapper* m_impl = nullptr;

    void abandon() noexcept;
    void async_wait_for(bool upload_completion, bool download_completion, WaitOperCompletionHandler);
};

std::ostream& operator<<(std::ostream& os, SyncConfig::ProxyConfig::Type);

// Implementation

class BadServerUrl : public Exception {
public:
    BadServerUrl(std::string_view url)
        : Exception(ErrorCodes::BadServerUrl, util::format("Unable to parse server URL '%1'", url))
    {
    }
};

inline Session::Session(Session&& sess) noexcept
    : m_impl{sess.m_impl}
{
    sess.m_impl = nullptr;
}

inline Session::~Session() noexcept
{
    if (m_impl)
        abandon();
}

inline Session& Session::operator=(Session&& sess) noexcept
{
    if (m_impl)
        abandon();
    m_impl = sess.m_impl;
    sess.m_impl = nullptr;
    return *this;
}

inline void Session::detach() noexcept
{
    if (m_impl)
        abandon();
    m_impl = nullptr;
}

inline void Session::set_error_handler(util::UniqueFunction<ErrorHandler> handler)
{
    auto handler_2 = [handler = std::move(handler)](ConnectionState state,
                                                    const util::Optional<SessionErrorInfo>& error_info) {
        if (state != ConnectionState::disconnected)
            return;
        REALM_ASSERT(error_info);
        handler(*error_info); // Throws
    };
    set_connection_state_change_listener(std::move(handler_2)); // Throws
}

inline void Session::async_wait_for_sync_completion(WaitOperCompletionHandler handler)
{
    bool upload_completion = true, download_completion = true;
    async_wait_for(upload_completion, download_completion, std::move(handler)); // Throws
}

inline void Session::async_wait_for_upload_completion(WaitOperCompletionHandler handler)
{
    bool upload_completion = true, download_completion = false;
    async_wait_for(upload_completion, download_completion, std::move(handler)); // Throws
}

inline void Session::async_wait_for_download_completion(WaitOperCompletionHandler handler)
{
    bool upload_completion = false, download_completion = true;
    async_wait_for(upload_completion, download_completion, std::move(handler)); // Throws
}

} // namespace realm::sync

#endif // REALM_SYNC_CLIENT_HPP
