////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

#ifndef REALM_AUDIT_HPP
#define REALM_AUDIT_HPP

#include <realm/util/functional.hpp>
#include <realm/util/optional.hpp>
#include <realm/util/terminate.hpp>

#include <memory>
#include <string>
#include <vector>

namespace realm {
class DB;
class AuditObjectSerializer;
class Obj;
class SyncUser;
class TableView;
class Timestamp;
struct ColKey;
struct RealmConfig;
struct SyncError;
struct VersionID;
namespace util {
class Logger;
}

struct AuditConfig {
    // User to open the audit Realms with. If null, the user used to open the
    // Realm being audited is used
    std::shared_ptr<SyncUser> audit_user;
    // Prefix added to the start of generated partition keys for audit Realms.
    std::string partition_value_prefix = "audit";
    // Object serializer instance for converting objects to JSON payloads. If
    // null, a default implementation is used.
    std::shared_ptr<AuditObjectSerializer> serializer;
    // Logger for audit events. If null, the sync logger from the Realm under
    // audit is used.
    std::shared_ptr<util::Logger> logger;
    // Error handler which is called if fatal sync errors occur on the sync
    // Realm. If null, an error is logged then abort() is called.
    std::function<void(SyncError)> sync_error_handler;
    // Metadata to attach to each audit event. Each key used must be a property
    // in the server-side schema for AuditEvent. This is not validated and will
    // result in a sync error if violated.
    std::vector<std::pair<std::string, std::string>> metadata;
};

class AuditInterface {
public:
    virtual ~AuditInterface() = default;

    // Internal interface for recording auditable events. SDKs may need to call
    // record_read() if they do not go through Object; record_query() and
    // record_write() should be handled automatically
    virtual void record_query(VersionID, const TableView&) = 0;
    virtual void record_read(VersionID, const Obj& obj, const Obj& parent, ColKey col) = 0;
    virtual void prepare_for_write(VersionID old_version) = 0;
    virtual void record_write(VersionID old_version, VersionID new_version) = 0;

    // -- Audit functionality which should be exposed in the SDK

    // Update the metadata attached to subsequence audit events. Does not effect
    // the current audit scope if called while a scope is active.
    virtual void update_metadata(std::vector<std::pair<std::string, std::string>> new_metadata) = 0;

    // Begin an audit scope. The given `name` is stored in the activity field
    // of each generated event. Returns an id which must be used to either
    // commit or cancel the scope.
    virtual uint64_t begin_scope(std::string_view name) = 0;
    // End the scope with the given id and asynchronously save it to disk. The
    // optional completion function is called once it has been committed (or an
    // error ocurred while trying to do so).
    virtual void end_scope(uint64_t, util::UniqueFunction<void(std::exception_ptr)>&& completion = nullptr) = 0;
    // Cancel the scope with the given id, discarding all events generated.
    virtual void cancel_scope(uint64_t) = 0;
    // Check if the scope with the given id is currently active and can be
    // committed or cancelled.
    virtual bool is_scope_valid(uint64_t) = 0;
    // Record a custom audit event. Does not use the scope (and does not need to be inside a scope).
    virtual void record_event(std::string_view activity, util::Optional<std::string> event_type,
                              util::Optional<std::string> data,
                              util::UniqueFunction<void(std::exception_ptr)>&& completion) = 0;

    // -- Test helper functionality

    // Wait for all scopes to be written to disk. Does not wait for them to be
    // uploaded to the server.
    virtual void wait_for_completion() = 0;
    // Wait for there to be no more data to upload. This is not a precise check;
    // if more scopes are created while this is waiting they may or may not be
    // included in the wait.
    virtual void wait_for_uploads() = 0;
};

std::shared_ptr<AuditInterface> make_audit_context(std::shared_ptr<DB>, RealmConfig const& parent_config);

// Hooks for testing. Do not use outside of tests.
namespace audit_test_hooks {
void set_maximum_shard_size(int64_t max_size);
// Not thread-safe, so this must be called at a point when no audit contexts exist.
void set_clock(util::UniqueFunction<Timestamp()>&&);
} // namespace audit_test_hooks

#if !REALM_PLATFORM_APPLE
inline std::shared_ptr<AuditInterface> make_audit_context(std::shared_ptr<DB>, RealmConfig const&)
{
    REALM_TERMINATE("Audit not supported on this platform");
}
#endif

} // namespace realm

#endif // REALM_AUDIT_HPP
