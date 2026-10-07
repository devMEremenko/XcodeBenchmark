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

#ifndef AUTH_REQUEST_CLIENT_HPP
#define AUTH_REQUEST_CLIENT_HPP

#include <realm/util/functional.hpp>
#include <memory>
#include <string>

namespace realm {
class SyncUser;
namespace app {
struct Request;
struct Response;

class AuthRequestClient {
public:
    virtual ~AuthRequestClient() = default;

    virtual std::string url_for_path(const std::string& path) const = 0;

    virtual void do_authenticated_request(Request&&, const std::shared_ptr<SyncUser>& sync_user,
                                          util::UniqueFunction<void(const Response&)>&&) = 0;
};

} // namespace app
} // namespace realm

#endif /* AUTH_REQUEST_CLIENT_HPP */
