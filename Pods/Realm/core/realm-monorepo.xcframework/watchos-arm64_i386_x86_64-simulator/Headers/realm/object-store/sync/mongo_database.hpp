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

#ifndef REALM_OS_MONGO_DATABASE_HPP
#define REALM_OS_MONGO_DATABASE_HPP

#include <memory>
#include <string>

namespace realm {
class SyncUser;
namespace app {

class AppServiceClient;
class MongoCollection;

class MongoDatabase {
public:
    ~MongoDatabase() = default;
    MongoDatabase(const MongoDatabase&) = default;
    MongoDatabase(MongoDatabase&&) = default;
    MongoDatabase& operator=(const MongoDatabase&) = default;
    MongoDatabase& operator=(MongoDatabase&&) = default;

    /// The name of this database
    const std::string& name() const
    {
        return m_name;
    }

    /// Gets a collection.
    /// @param collection_name The name of the collection to return
    /// @returns The collection as json
    MongoCollection collection(const std::string& collection_name);

    /// Gets a collection.
    /// @param collection_name The name of the collection to return
    /// @returns The collection as json
    MongoCollection operator[](const std::string& collection_name);

private:
    MongoDatabase(std::string name, std::shared_ptr<SyncUser> user, std::shared_ptr<AppServiceClient> service,
                  std::string service_name)
        : m_name(std::move(name))
        , m_user(std::move(user))
        , m_service(std::move(service))
        , m_service_name(std::move(service_name))
    {
    }

    friend class MongoClient;

    std::string m_name;
    std::shared_ptr<SyncUser> m_user;
    std::shared_ptr<AppServiceClient> m_service;
    std::string m_service_name;
};

} // namespace app
} // namespace realm

#endif /* REALM_OS_MONGO_DATABASE_HPP */
