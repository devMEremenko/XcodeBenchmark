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

#ifndef REALM_OS_SYNC_METADATA_HPP
#define REALM_OS_SYNC_METADATA_HPP

#include <realm/object-store/results.hpp>
#include <realm/object-store/shared_realm.hpp>
#include <realm/object-store/sync/sync_user.hpp>

#include <realm/obj.hpp>
#include <realm/table.hpp>
#include <realm/util/optional.hpp>
#include <string>

namespace realm {
class SyncMetadataManager;

// A facade for a metadata Realm object representing app metadata
class SyncAppMetadata {
public:
    struct Schema {
        ColKey id_col;
        ColKey deployment_model_col;
        ColKey location_col;
        ColKey hostname_col;
        ColKey ws_hostname_col;
    };

    std::string deployment_model;
    std::string location;
    std::string hostname;
    std::string ws_hostname;
};

// A facade for a metadata Realm object representing a sync user.
class SyncUserMetadata {
public:
    struct Schema {
        // The server-supplied user_id for the user. Unique per App.
        ColKey identity_col;
        // Locally generated UUIDs for the user. These are tracked to be able
        // to open pre-existing Realm files, but are no longer generated or
        // used for anything else.
        ColKey legacy_uuids_col;
        // The cached refresh token for this user.
        ColKey refresh_token_col;
        // The cached access token for this user.
        ColKey access_token_col;
        // The identities for this user.
        ColKey identities_col;
        // The current state of this user.
        ColKey state_col;
        // The device id of this user.
        ColKey device_id_col;
        // Any additional profile attributes, formatted as a bson string.
        ColKey profile_dump_col;
        // The set of absolute file paths to Realms belonging to this user.
        ColKey realm_file_paths_col;
    };

    // Cannot be set after creation.
    std::string identity() const;

    std::vector<std::string> legacy_identities() const;
    // for testing purposes only
    void set_legacy_identities(const std::vector<std::string>&);

    std::vector<realm::SyncUserIdentity> identities() const;
    void set_identities(std::vector<SyncUserIdentity>);

    void set_state_and_tokens(SyncUser::State state, const std::string& access_token,
                              const std::string& refresh_token);

    std::string refresh_token() const;
    void set_refresh_token(const std::string& token);

    std::string access_token() const;
    void set_access_token(const std::string& token);

    std::string device_id() const;
    void set_device_id(const std::string&);

    SyncUserProfile profile() const;
    void set_user_profile(const SyncUserProfile&);

    std::vector<std::string> realm_file_paths() const;
    void add_realm_file_path(const std::string& path);

    void set_state(SyncUser::State);

    SyncUser::State state() const;

    void remove();

    bool is_valid() const
    {
        return !m_invalid;
    }

    // INTERNAL USE ONLY
    SyncUserMetadata(Schema schema, SharedRealm realm, const Obj& obj);

private:
    bool m_invalid = false;
    SharedRealm m_realm;
    Schema m_schema;
    Obj m_obj;
};

// A facade for a metadata Realm object representing a pending action to be carried out upon a specific file(s).
class SyncFileActionMetadata {
public:
    struct Schema {
        // The original path on disk of the file (generally, the main file for an on-disk Realm).
        ColKey idx_original_name;
        // A new path on disk for a file to be written to. Context-dependent.
        ColKey idx_new_name;
        // An enum describing the action to take.
        ColKey idx_action;
        // The partition key of the Realm.
        ColKey idx_partition;
        // The local UUID of the user to whom the file action applies (despite the internal column name).
        ColKey idx_user_identity;
    };

    enum class Action {
        // The Realm files at the given directory will be deleted.
        DeleteRealm,
        // The Realm file will be copied to a 'recovery' directory, and the original Realm files will be deleted.
        BackUpThenDeleteRealm
    };

    // The absolute path to the Realm file in question.
    std::string original_name() const;

    // The meaning of this parameter depends on the `Action` specified.
    // For `BackUpThenDeleteRealm`, it is the absolute path where the backup copy
    // of the Realm file found at `original_name()` will be placed.
    // For all other `Action`s, it is ignored.
    util::Optional<std::string> new_name() const;

    // Get the local UUID of the user associated with this file action metadata.
    std::string user_local_uuid() const;

    Action action() const;
    std::string partition() const;
    void remove();
    void set_action(Action new_action);

    // INTERNAL USE ONLY
    SyncFileActionMetadata(Schema schema, SharedRealm realm, const Obj& obj);

private:
    SharedRealm m_realm;
    Schema m_schema;
    Obj m_obj;
};

template <class T>
class SyncMetadataResults {
public:
    size_t size() const
    {
        m_results.get_realm()->refresh();
        return m_results.size();
    }

    T get(size_t idx) const
    {
        m_results.get_realm()->refresh();
        auto row = m_results.get(idx);
        return T(m_schema, m_results.get_realm(), row);
    }

    SyncMetadataResults(Results results, typename T::Schema schema)
        : m_schema(std::move(schema))
        , m_results(std::move(results))
    {
    }

private:
    typename T::Schema m_schema;
    mutable Results m_results;
};
using SyncUserMetadataResults = SyncMetadataResults<SyncUserMetadata>;
using SyncFileActionMetadataResults = SyncMetadataResults<SyncFileActionMetadata>;

// A facade for the application's metadata Realm.
class SyncMetadataManager {
    friend class SyncUserMetadata;
    friend class SyncFileActionMetadata;

public:
    // Return a Results object containing all users not marked for removal.
    SyncUserMetadataResults all_unmarked_users() const;

    // Return a Results object containing all users marked for removal. It is the binding's responsibility to call
    // `remove()` on each user to actually remove it from the database. (This is so that already-open Realm files can
    // be safely cleaned up the next time the host is launched.)
    SyncUserMetadataResults all_users_marked_for_removal() const;

    // Return a Results object containing all pending actions.
    SyncFileActionMetadataResults all_pending_actions() const;

    // Retrieve or create user metadata.
    // Note: if `make_is_absent` is true and the user has been marked for deletion, it will be unmarked.
    util::Optional<SyncUserMetadata> get_or_make_user_metadata(const std::string& identity,
                                                               bool make_if_absent = true) const;

    // Retrieve file action metadata.
    util::Optional<SyncFileActionMetadata> get_file_action_metadata(StringData path) const;

    // Create file action metadata.
    void make_file_action_metadata(StringData original_name, StringData partition_key_value, StringData local_uuid,
                                   SyncFileActionMetadata::Action action, StringData new_name = {}) const;

    util::Optional<std::string> get_current_user_identity() const;
    void set_current_user_identity(const std::string& identity);

    util::Optional<SyncAppMetadata> get_app_metadata();
    /// Set or update the cached app server metadata. The metadata will not be updated if it has already been
    /// set and the provided values are not different than the cached information. Returns true if the metadata
    /// was updated.
    /// @param deployment_model The deployment model reported by the app server
    /// @param location The location name where the app server is located
    /// @param hostname The hostname to use for the app server admin api
    /// @param ws_hostname The hostname to use for the app server websocket connections
    bool set_app_metadata(const std::string& deployment_model, const std::string& location,
                          const std::string& hostname, const std::string& ws_hostname);

    /// Construct the metadata manager.
    ///
    /// If the platform supports it, setting `should_encrypt` to `true` and not specifying an encryption key will make
    /// the object store handle generating and persisting an encryption key for the metadata database. Otherwise, an
    /// exception will be thrown.
    SyncMetadataManager(std::string path, bool should_encrypt,
                        util::Optional<std::vector<char>> encryption_key = none);

private:
    SyncUserMetadataResults get_users(bool marked) const;
    Realm::Config m_metadata_config;
    SyncUserMetadata::Schema m_user_schema;
    SyncFileActionMetadata::Schema m_file_action_schema;
    SyncAppMetadata::Schema m_app_metadata_schema;

    std::shared_ptr<Realm> get_realm() const;
    std::shared_ptr<Realm> try_get_realm() const;
    std::shared_ptr<Realm> open_realm(bool should_encrypt, bool caller_supplied_key);


    util::Optional<SyncAppMetadata> m_app_metadata;
};

} // namespace realm

#endif // REALM_OS_SYNC_METADATA_HPP
