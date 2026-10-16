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
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or utilied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#ifndef REALM_APP_HPP
#define REALM_APP_HPP

#include <realm/object-store/sync/app_credentials.hpp>
#include <realm/object-store/sync/app_service_client.hpp>
#include <realm/object-store/sync/auth_request_client.hpp>
#include <realm/object-store/sync/generic_network_transport.hpp>
#include <realm/object-store/sync/push_client.hpp>
#include <realm/object-store/sync/subscribable.hpp>

#include <realm/object_id.hpp>
#include <realm/util/logger.hpp>
#include <realm/util/optional.hpp>
#include <realm/util/functional.hpp>

#include <mutex>

namespace realm {
class SyncUser;
class SyncSession;
class SyncManager;
struct SyncClientConfig;
class SyncAppMetadata;

namespace app {

class App;

typedef std::shared_ptr<App> SharedApp;

/// The `App` has the fundamental set of methods for communicating with a Atlas App Services backend.
///
/// This class provides access to login and authentication.
///
/// You can also use it to execute [Functions](https://docs.mongodb.com/stitch/functions/).
class App : public std::enable_shared_from_this<App>,
            public AuthRequestClient,
            public AppServiceClient,
            public Subscribable<App> {
public:
    struct Config {
        // Information about the device where the app is running
        struct DeviceInfo {
            std::string platform_version;  // json: platformVersion
            std::string sdk_version;       // json: sdkVersion
            std::string sdk;               // json: sdk
            std::string device_name;       // json: deviceName
            std::string device_version;    // json: deviceVersion
            std::string framework_name;    // json: frameworkName
            std::string framework_version; // json: frameworkVersion
            std::string bundle_id;         // json: bundleId

            DeviceInfo();
            DeviceInfo(std::string, std::string, std::string, std::string, std::string, std::string, std::string,
                       std::string);

        private:
            friend App;

            std::string platform;     // json: platform
            std::string cpu_arch;     // json: cpuArch
            std::string core_version; // json: coreVersion
        };

        std::string app_id;
        std::shared_ptr<GenericNetworkTransport> transport;
        util::Optional<std::string> base_url;
        util::Optional<uint64_t> default_request_timeout_ms;
        DeviceInfo device_info;
    };

    // `enable_shared_from_this` is unsafe with public constructors; use `get_shared_app` instead
    App(const Config& config);
    App(App&&) noexcept = default;
    App& operator=(App&&) noexcept = default;
    ~App();

    const Config& config() const
    {
        return m_config;
    }

    const std::string& base_url() const
    {
        return m_base_url;
    }

    /// Get the last used user.
    std::shared_ptr<SyncUser> current_user() const;

    /// Get all users.
    std::vector<std::shared_ptr<SyncUser>> all_users() const;

    std::shared_ptr<SyncManager> const& sync_manager() const
    {
        return m_sync_manager;
    }

    /// A struct representing a user API key as returned by the App server.
    struct UserAPIKey {
        // The ID of the key.
        ObjectId id;

        /// The actual key. Will only be included in
        /// the response when an API key is first created.
        util::Optional<std::string> key;

        /// The name of the key.
        std::string name;

        /// Whether or not the key is disabled.
        bool disabled;
    };

    /// A client for the user API key authentication provider which
    /// can be used to create and modify user API keys. This
    /// client should only be used by an authenticated user.
    class UserAPIKeyProviderClient {
    public:
        /// Creates a user API key that can be used to authenticate as the current user.
        /// @param name The name of the API key to be created.
        /// @param completion A callback to be invoked once the call is complete.
        void create_api_key(const std::string& name, const std::shared_ptr<SyncUser>& user,
                            util::UniqueFunction<void(UserAPIKey&&, util::Optional<AppError>)>&& completion);

        /// Fetches a user API key associated with the current user.
        /// @param id The id of the API key to fetch.
        /// @param completion A callback to be invoked once the call is complete.
        void fetch_api_key(const realm::ObjectId& id, const std::shared_ptr<SyncUser>& user,
                           util::UniqueFunction<void(UserAPIKey&&, util::Optional<AppError>)>&& completion);

        /// Fetches the user API keys associated with the current user.
        /// @param completion A callback to be invoked once the call is complete.
        void
        fetch_api_keys(const std::shared_ptr<SyncUser>& user,
                       util::UniqueFunction<void(std::vector<UserAPIKey>&&, util::Optional<AppError>)>&& completion);

        /// Deletes a user API key associated with the current user.
        /// @param id The id of the API key to delete.
        /// @param user The user to perform this operation.
        /// @param completion A callback to be invoked once the call is complete.
        void delete_api_key(const realm::ObjectId& id, const std::shared_ptr<SyncUser>& user,
                            util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

        /// Enables a user API key associated with the current user.
        /// @param id The id of the API key to enable.
        /// @param user The user to perform this operation.
        /// @param completion A callback to be invoked once the call is complete.
        void enable_api_key(const realm::ObjectId& id, const std::shared_ptr<SyncUser>& user,
                            util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

        /// Disables a user API key associated with the current user.
        /// @param id The id of the API key to disable.
        /// @param user The user to perform this operation.
        /// @param completion A callback to be invoked once the call is complete.
        void disable_api_key(const realm::ObjectId& id, const std::shared_ptr<SyncUser>& user,
                             util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

    private:
        friend class App;
        UserAPIKeyProviderClient(AuthRequestClient& auth_request_client)
            : m_auth_request_client(auth_request_client)
        {
        }

        std::string url_for_path(const std::string& path) const;
        AuthRequestClient& m_auth_request_client;
    };

    /// A client for the username/password authentication provider which
    /// can be used to obtain a credential for logging in,
    /// and to perform requests specifically related to the username/password provider.
    ///
    class UsernamePasswordProviderClient {
    public:
        /// Registers a new email identity with the username/password provider,
        /// and sends a confirmation email to the provided address.
        /// @param email The email address of the user to register.
        /// @param password The password that the user created for the new username/password identity.
        /// @param completion A callback to be invoked once the call is complete.
        void register_email(const std::string& email, const std::string& password,
                            util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

        /// Confirms an email identity with the username/password provider.
        /// @param token The confirmation token that was emailed to the user.
        /// @param token_id The confirmation token id that was emailed to the user.
        /// @param completion A callback to be invoked once the call is complete.
        void confirm_user(const std::string& token, const std::string& token_id,
                          util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

        /// Re-sends a confirmation email to a user that has registered but
        /// not yet confirmed their email address.
        /// @param email The email address of the user to re-send a confirmation for.
        /// @param completion A callback to be invoked once the call is complete.
        void resend_confirmation_email(const std::string& email,
                                       util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

        void send_reset_password_email(const std::string& email,
                                       util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

        /// Retries the custom confirmation function on a user for a given email.
        /// @param email The email address of the user to retry the custom confirmation for.
        /// @param completion A callback to be invoked once the retry is complete.
        void retry_custom_confirmation(const std::string& email,
                                       util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

        /// Resets the password of an email identity using the
        /// password reset token emailed to a user.
        /// @param password The desired new password.
        /// @param token The password reset token that was emailed to the user.
        /// @param token_id The password reset token id that was emailed to the user.
        /// @param completion A callback to be invoked once the call is complete.
        void reset_password(const std::string& password, const std::string& token, const std::string& token_id,
                            util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

        /// Resets the password of an email identity using the
        /// password reset function set up in the application.
        /// @param email The email address of the user.
        /// @param password The desired new password.
        /// @param args A bson array of arguments.
        /// @param completion A callback to be invoked once the call is complete.
        void call_reset_password_function(const std::string& email, const std::string& password,
                                          const bson::BsonArray& args,
                                          util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

    private:
        friend class App;
        UsernamePasswordProviderClient(SharedApp app)
            : m_parent(app)
        {
            REALM_ASSERT(app);
        }
        SharedApp m_parent;
    };

    /// Retrieve a cached app instance if one was previously generated for `config`'s app_id+base_url combo,
    /// otherwise generate and return a new instance and persist it in the cache.
    static SharedApp get_shared_app(const Config& config, const SyncClientConfig& sync_client_config);

    /// Generate and return a new app instance for the given config, bypassing the app cache.
    static SharedApp get_uncached_app(const Config& config, const SyncClientConfig& sync_client_config);

    /// Return a cached app instance if one was previously generated for the `app_id`+`base_url` combo using
    /// `get_shared_app`.
    /// If base_url is not provided, and there are multiple cached apps with the same app_id but different base_urls,
    /// then a non-determinstic one will be returned.
    ///
    /// Prefer using `get_shared_app` or populating `base_url` to avoid the non-deterministic behavior.
    static SharedApp get_cached_app(const std::string& app_id,
                                    const std::optional<std::string>& base_url = std::nullopt);

    /// Log in a user and asynchronously retrieve a user object.
    /// If the log in completes successfully, the completion block will be called, and a
    /// `SyncUser` representing the logged-in user will be passed to it. This user object
    /// can be used to open `Realm`s and retrieve `SyncSession`s. Otherwise, the
    /// completion block will be called with an error.
    ///
    /// @param credentials A `SyncCredentials` object representing the user to log in.
    /// @param completion A callback block to be invoked once the log in completes.
    void log_in_with_credentials(
        const AppCredentials& credentials,
        util::UniqueFunction<void(const std::shared_ptr<SyncUser>&, util::Optional<AppError>)>&& completion);

    /// Logout the current user.
    void log_out(util::UniqueFunction<void(util::Optional<AppError>)>&&);

    /// Refreshes the custom data for a specified user
    /// @param user The user you want to refresh
    /// @param update_location If true, the location metadata will be updated before refresh
    void refresh_custom_data(const std::shared_ptr<SyncUser>& user, bool update_location,
                             util::UniqueFunction<void(util::Optional<AppError>)>&& completion);
    void refresh_custom_data(const std::shared_ptr<SyncUser>& user,
                             util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

    /// Log out the given user if they are not already logged out.
    void log_out(const std::shared_ptr<SyncUser>& user,
                 util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

    /// Links the currently authenticated user with a new identity, where the identity is defined by the credential
    /// specified as a parameter. This will only be successful if this `SyncUser` is the currently authenticated
    /// with the client from which it was created. On success the user will be returned with the new identity.
    ///
    /// @param user The user which will have the credentials linked to, the user must be logged in
    /// @param credentials The `AppCredentials` used to link the user to a new identity.
    /// @param completion The completion handler to call when the linking is complete.
    ///                         If the operation is  successful, the result will contain the original
    ///                         `SyncUser` object representing the user.
    void
    link_user(const std::shared_ptr<SyncUser>& user, const AppCredentials& credentials,
              util::UniqueFunction<void(const std::shared_ptr<SyncUser>&, util::Optional<AppError>)>&& completion);

    /// Switches the active user with the specified one. The user must
    /// exist in the list of all users who have logged into this application, and
    /// the user must be currently logged in, otherwise this will throw an
    /// AppError.
    ///
    /// @param user The user to switch to
    /// @returns A shared pointer to the new current user
    std::shared_ptr<SyncUser> switch_user(const std::shared_ptr<SyncUser>& user) const;

    /// Logs out and removes the provided user.
    /// This invokes logout on the server.
    /// @param user the user to remove
    /// @param completion Will return an error if the user is not found or the http request failed.
    void remove_user(const std::shared_ptr<SyncUser>& user,
                     util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

    /// Deletes a user and all its data from the server.
    /// @param user The user to delete
    /// @param completion Will return an error if the user is not found or the http request failed.
    void delete_user(const std::shared_ptr<SyncUser>& user,
                     util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

    // Get a provider client for the given class type.
    template <class T>
    T provider_client()
    {
        return T(this);
    }

    void call_function(const std::shared_ptr<SyncUser>& user, const std::string& name, std::string_view args_ejson,
                       const util::Optional<std::string>& service_name,
                       util::UniqueFunction<void(const std::string*, util::Optional<AppError>)>&& completion) final;

    void call_function(
        const std::shared_ptr<SyncUser>& user, const std::string& name, const bson::BsonArray& args_bson,
        const util::Optional<std::string>& service_name,
        util::UniqueFunction<void(util::Optional<bson::Bson>&&, util::Optional<AppError>)>&& completion) final;

    void call_function(
        const std::shared_ptr<SyncUser>& user, const std::string&, const bson::BsonArray& args_bson,
        util::UniqueFunction<void(util::Optional<bson::Bson>&&, util::Optional<AppError>)>&& completion) final;

    void call_function(
        const std::string& name, const bson::BsonArray& args_bson, const util::Optional<std::string>& service_name,
        util::UniqueFunction<void(util::Optional<bson::Bson>&&, util::Optional<AppError>)>&& completion) final;

    void call_function(
        const std::string&, const bson::BsonArray& args_bson,
        util::UniqueFunction<void(util::Optional<bson::Bson>&&, util::Optional<AppError>)>&& completion) final;

    template <typename T>
    void call_function(const std::shared_ptr<SyncUser>& user, const std::string& name,
                       const bson::BsonArray& args_bson,
                       util::UniqueFunction<void(util::Optional<T>&&, util::Optional<AppError>)>&& completion)
    {
        call_function(
            user, name, args_bson, util::none,
            [completion = std::move(completion)](util::Optional<bson::Bson>&& value, util::Optional<AppError> error) {
                if (value) {
                    return completion(util::some<T>(static_cast<T>(*value)), std::move(error));
                }

                return completion(util::none, std::move(error));
            });
    }

    template <typename T>
    void call_function(const std::string& name, const bson::BsonArray& args_bson,
                       util::UniqueFunction<void(util::Optional<T>&&, util::Optional<AppError>)>&& completion)
    {
        call_function(current_user(), name, args_bson, std::move(completion));
    }

    // NOTE: only sets "Accept: text/event-stream" header. If you use an API that sets that but doesn't support
    // setting other headers (eg. EventSource() in JS), you can ignore the headers field on the request.
    Request make_streaming_request(const std::shared_ptr<SyncUser>& user, const std::string& name,
                                   const bson::BsonArray& args_bson,
                                   const util::Optional<std::string>& service_name) const;

    // MARK: Push notification client
    PushClient push_notification_client(const std::string& service_name);

    static void clear_cached_apps();

    // Immediately close all open sync sessions for all cached apps.
    // Used by JS SDK to ensure no sync clients remain open when a developer
    // reloads an app (#5411).
    static void close_all_sync_sessions();

private:
    friend class Internal;
    friend class OnlyForTesting;

    Config m_config;

    // mutable to allow locking for reads in const functions
    // this is a shared pointer to support the App move constructor
    mutable std::shared_ptr<std::mutex> m_route_mutex = std::make_shared<std::mutex>();
    std::string m_base_url;
    std::string m_base_route;
    std::string m_app_route;
    std::string m_auth_route;
    bool m_location_updated = false;

    uint64_t m_request_timeout_ms;
    std::shared_ptr<SyncManager> m_sync_manager;
    std::shared_ptr<util::Logger> m_logger_ptr;

    /// m_logger_ptr is not set until the first call to one of these functions.
    /// If configure() not been called, a logger will not be available yet.
    /// @returns true if the logger was set, otherwise false.
    bool init_logger();
    /// These helpers prevent all the checks for if(m_logger_ptr) throughout the
    /// code.
    bool would_log(util::Logger::Level level);
    template <class... Params>
    void log_debug(const char* message, Params&&... params);
    template <class... Params>
    void log_error(const char* message, Params&&... params);

    /// Refreshes the access token for a specified `SyncUser`
    /// @param completion Passes an error should one occur.
    /// @param update_location If true, the location metadata will be updated before refresh
    void refresh_access_token(const std::shared_ptr<SyncUser>& user, bool update_location,
                              util::UniqueFunction<void(util::Optional<AppError>)>&& completion);

    /// Checks if an auth failure has taken place and if so it will attempt to refresh the
    /// access token and then perform the orginal request again with the new access token
    /// @param error The error to check for auth failures
    /// @param response The original response to pass back should this not be an auth error
    /// @param request The request to perform
    /// @param completion returns the original response in the case it is not an auth error, or if a failure
    /// occurs, if the refresh was a success the newly attempted response will be passed back
    void handle_auth_failure(const AppError& error, const Response& response, Request&& request,
                             const std::shared_ptr<SyncUser>& user,
                             util::UniqueFunction<void(const Response&)>&& completion);

    std::string url_for_path(const std::string& path) const override;

    /// Return the app route for this App instance, or creates a new app route string if
    /// a new hostname is provided
    /// @param hostname The hostname to generate a new app route
    std::string get_app_route(const util::Optional<std::string>& hostname = util::none) const;

    /// Request the app metadata information from the server if it has not been processed yet. If
    /// a new hostname is provided, the app metadata will be refreshed using the new hostname.
    /// @param completion The server response if an error was encountered during the update
    /// @param new_hostname If provided, the metadata will be requested from this hostname
    void init_app_metadata(util::UniqueFunction<void(const util::Optional<Response>&)>&& completion,
                           const util::Optional<std::string>& new_hostname = util::none);

    /// Update the app metadata and resend the request with the updated metadata
    /// @param request The original request object that needs to be sent after the update
    /// @param completion The original completion object that will be called with the response to the request
    /// @param new_hostname If provided, the metadata will be requested from this hostname
    void update_metadata_and_resend(Request&& request, util::UniqueFunction<void(const Response&)>&& completion,
                                    const util::Optional<std::string>& new_hostname = util::none);

    void post(std::string&& route, util::UniqueFunction<void(util::Optional<AppError>)>&& completion,
              const bson::BsonDocument& body);

    /// Performs a request to the Stitch server. This request does not contain authentication state.
    /// @param request The request to be performed
    /// @param completion Returns the response from the server
    /// @param update_location Force the location metadata to be updated prior to sending the request
    void do_request(Request&& request, util::UniqueFunction<void(const Response&)>&& completion,
                    bool update_location = false);

    /// Check to see if hte response is a redirect and handle, otherwise pass the response to compleetion
    /// @param request The request to be performed (in case it needs to be sent again)
    /// @param response The response from the send_request_to_server operation
    /// @param completion Returns the response from the server if not a redirect
    void handle_possible_redirect_response(Request&& request, const Response& response,
                                           util::UniqueFunction<void(const Response&)>&& completion);

    /// Process the redirect response received from the last request that was sent to the server
    /// @param request The request to be performed (in case it needs to be sent again)
    /// @param response The response from the send_request_to_server operation
    /// @param completion Returns the response from the server if not a redirect
    void handle_redirect_response(Request&& request, const Response& response,
                                  util::UniqueFunction<void(const Response&)>&& completion);

    /// Performs an authenticated request to the Stitch server, using the current authentication state
    /// @param request The request to be performed
    /// @param completion Returns the response from the server
    void do_authenticated_request(Request&& request, const std::shared_ptr<SyncUser>& user,
                                  util::UniqueFunction<void(const Response&)>&& completion) override;


    /// Gets the social profile for a `SyncUser`
    /// @param completion Callback will pass the `SyncUser` with the social profile details
    void
    get_profile(const std::shared_ptr<SyncUser>& user,
                util::UniqueFunction<void(const std::shared_ptr<SyncUser>&, util::Optional<AppError>)>&& completion);

    /// Log in a user and asynchronously retrieve a user object.
    /// If the log in completes successfully, the completion block will be called, and a
    /// `SyncUser` representing the logged-in user will be passed to it. This user object
    /// can be used to open `Realm`s and retrieve `SyncSession`s. Otherwise, the
    /// completion block will be called with an error.
    ///
    /// @param credentials A `SyncCredentials` object representing the user to log in.
    /// @param linking_user A `SyncUser` you want to link these credentials too
    /// @param completion A callback block to be invoked once the log in completes.
    void log_in_with_credentials(
        const AppCredentials& credentials, const std::shared_ptr<SyncUser>& linking_user,
        util::UniqueFunction<void(const std::shared_ptr<SyncUser>&, util::Optional<AppError>)>&& completion);

    /// Provides MongoDB Realm Cloud with metadata related to the users session
    void attach_auth_options(bson::BsonDocument& body);

    std::string function_call_url_path() const;

    void configure(const SyncClientConfig& sync_client_config);

    std::string make_sync_route(const std::string& http_app_route);

    void update_hostname(const util::Optional<realm::SyncAppMetadata>& metadata);

    void update_hostname(const std::string& hostname, const util::Optional<std::string>& ws_hostname = util::none);

    bool verify_user_present(const std::shared_ptr<SyncUser>& user) const;
};

// MARK: Provider client templates
template <>
App::UsernamePasswordProviderClient App::provider_client<App::UsernamePasswordProviderClient>();
template <>
App::UserAPIKeyProviderClient App::provider_client<App::UserAPIKeyProviderClient>();

} // namespace app
} // namespace realm

#endif /* REALM_APP_HPP */
