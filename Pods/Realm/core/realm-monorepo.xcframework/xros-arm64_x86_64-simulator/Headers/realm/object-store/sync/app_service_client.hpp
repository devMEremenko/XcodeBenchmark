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

#ifndef APP_SERVICE_CLIENT_HPP
#define APP_SERVICE_CLIENT_HPP

#include <realm/object-store/util/bson/bson.hpp>
#include <realm/util/functional.hpp>
#include <realm/util/optional.hpp>

#include <string>

namespace realm {
class SyncUser;
namespace app {
struct AppError;

/// A class providing the core functionality necessary to make authenticated
/// function call requests for a particular Stitch service.
class AppServiceClient {
public:
    virtual ~AppServiceClient() = default;

    /// Calls the Realm Cloud function with the provided name and arguments.
    /// @param user The sync user to perform this request.
    /// @param name The name of the Realm Cloud function to be called.
    /// @param args_ejson The arguments array to be provided to the function encoded as an ejson string.
    /// @param service_name The name of the service, this is optional.
    /// @param completion Returns the result from the intended call, will return an Optional AppError is an
    ///        error is thrown and ejson-encoded reply if successful. The reply string will be a null pointer only in
    ///        the case of error. Using a string* rather than optional<string> to avoid copying a potentially large
    ///        string.
    virtual void
    call_function(const std::shared_ptr<SyncUser>& user, const std::string& name, std::string_view args_ejson,
                  const util::Optional<std::string>& service_name,
                  util::UniqueFunction<void(const std::string*, util::Optional<AppError>)>&& completion) = 0;

    /// Calls the Realm Cloud function with the provided name and arguments.
    /// @param user The sync user to perform this request.
    /// @param name The name of the Realm Cloud function to be called.
    /// @param args_bson The `BSONArray` of arguments to be provided to the function.
    /// @param service_name The name of the service, this is optional.
    /// @param completion Returns the result from the intended call, will return an Optional AppError is an
    /// error is thrown and bson if successful
    virtual void call_function(
        const std::shared_ptr<SyncUser>& user, const std::string& name, const bson::BsonArray& args_bson,
        const util::Optional<std::string>& service_name,
        util::UniqueFunction<void(util::Optional<bson::Bson>&&, util::Optional<AppError>)>&& completion) = 0;

    /// Calls the Realm Cloud function with the provided name and arguments.
    /// @param user The sync user to perform this request.
    /// @param name The name of the Realm Cloud function to be called.
    /// @param args_bson The `BSONArray` of arguments to be provided to the function.
    /// @param completion Returns the result from the intended call, will return an Optional AppError is an
    /// error is thrown and bson if successful
    virtual void call_function(
        const std::shared_ptr<SyncUser>& user, const std::string& name, const bson::BsonArray& args_bson,
        util::UniqueFunction<void(util::Optional<bson::Bson>&&, util::Optional<AppError>)>&& completion) = 0;

    /// Calls the Realm Cloud function with the provided name and arguments.
    /// This will use the current logged in user to perform the request
    /// @param name The name of the Realm Cloud function to be called.
    /// @param args_bson The `BSONArray` of arguments to be provided to the function.
    /// @param service_name The name of the service, this is optional.
    /// @param completion Returns the result from the intended call, will return an Optional AppError is an
    /// error is thrown and bson if successful
    virtual void call_function(
        const std::string& name, const bson::BsonArray& args_bson, const util::Optional<std::string>& service_name,
        util::UniqueFunction<void(util::Optional<bson::Bson>&&, util::Optional<AppError>)>&& completion) = 0;

    /// Calls the Realm Cloud function with the provided name and arguments.
    /// This will use the current logged in user to perform the request
    /// @param name The name of the Realm Cloud function to be called.
    /// @param args_bson The `BSONArray` of arguments to be provided to the function.
    /// @param completion Returns the result from the intended call, will return an Optional AppError is an
    /// error is thrown and bson if successful
    virtual void call_function(
        const std::string& name, const bson::BsonArray& args_bson,
        util::UniqueFunction<void(util::Optional<bson::Bson>&&, util::Optional<AppError>)>&& completion) = 0;
};

} // namespace app
} // namespace realm

#endif /* APP_SERVICE_CLIENT_HPP */
