////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#ifndef REALM_REALM_HPP
#define REALM_REALM_HPP

#include <realm/object-store/schema.hpp>

#include <realm/util/optional.hpp>
#include <realm/util/functional.hpp>
#include <realm/binary_data.hpp>
#include <realm/transaction.hpp>
#include <realm/version_id.hpp>

#include <memory>
#include <deque>

namespace realm {
class AuditInterface;
class AsyncOpenTask;
class BindingContext;
class DB;
class Group;
class Obj;
class Realm;
class Replication;
class StringData;
class Table;
class ThreadSafeReference;
class Transaction;
class SyncSession;
struct AuditConfig;
struct SyncConfig;
typedef std::shared_ptr<Realm> SharedRealm;
typedef std::weak_ptr<Realm> WeakRealm;

namespace sync {
class SubscriptionSet;
}

namespace util {
class Scheduler;
}

namespace _impl {
class AnyHandover;
class CollectionNotifier;
class RealmCoordinator;
class RealmFriend;
} // namespace _impl

// A callback function to be called during a migration for Automatic and
// Manual schema modes. It is passed a SharedRealm at the version before
// the migration, the SharedRealm in the migration, and a mutable reference
// to the realm's Schema. Updating the schema with changes made within the
// migration function is only required if you wish to use the ObjectStore
// functions which take a Schema from within the migration function.
using MigrationFunction = std::function<void(SharedRealm old_realm, SharedRealm realm, Schema&)>;

// A callback function to be called the first time when a schema is created.
// It is passed a SharedRealm which is in a write transaction with the schema
// initialized. So it is possible to create some initial objects inside the callback
// with the given SharedRealm. Those changes will be committed together with the
// schema creation in a single transaction.
using DataInitializationFunction = std::function<void(SharedRealm realm)>;

// A callback function called when opening a SharedRealm when no cached
// version of this Realm exists. It is passed the total bytes allocated for
// the file (file size) and the total bytes used by data in the file.
// Return `true` to indicate that an attempt to compact the file should be made
// if it is possible to do so.
// Won't compact the file if another process is accessing it.
//
// WARNING / FIXME: compact() should NOT be exposed publicly on Windows
// because it's not crash safe! It may corrupt your database if something fails
using ShouldCompactOnLaunchFunction = std::function<bool(uint64_t total_bytes, uint64_t used_bytes)>;

struct RealmConfig {
    // Path and binary data are mutually exclusive
    std::string path;
    BinaryData realm_data;
    // User-supplied encryption key. Must be either empty or 64 bytes.
    std::vector<char> encryption_key;

    // Core and Object Store will in some cases need to create named pipes alongside the Realm file.
    // But on some filesystems this can be a problem (e.g. external storage on Android that uses FAT32).
    // In order to work around this, a separate path can be specified for these files.
    std::string fifo_files_fallback_path;

    bool in_memory = false;
    SchemaMode schema_mode = SchemaMode::Automatic;
    SchemaSubsetMode schema_subset_mode = SchemaSubsetMode::Strict;

    // Optional schema for the file.
    // If the schema and schema version are supplied, update_schema() is
    // called with the supplied schema, version and migration function when
    // the Realm is actually opened and not just retrieved from the cache
    util::Optional<Schema> schema;
    uint64_t schema_version = uint64_t(-1);
    MigrationFunction migration_function;

    DataInitializationFunction initialization_function;

    // A callback function called when opening a SharedRealm when no cached
    // version of this Realm exists. It is passed the total bytes allocated for
    // the file (file size) and the total bytes used by data in the file.
    // Return `true` to indicate that an attempt to compact the file should be made
    // if it is possible to do so.
    // Won't compact the file if another process is accessing it.
    //
    // WARNING / FIXME: compact() should NOT be exposed publicly on Windows
    // because it's not crash safe! It may corrupt your database if something fails
    ShouldCompactOnLaunchFunction should_compact_on_launch_function;

    // WARNING: The original read_only() has been renamed to immutable().
    bool immutable() const
    {
        return schema_mode == SchemaMode::Immutable;
    }
    bool read_only() const
    {
        return schema_mode == SchemaMode::ReadOnly;
    }

    // If false, always return a new Realm instance, and don't return
    // that Realm instance for other requests for a cached Realm. Useful
    // for dynamic Realms and for tests that need multiple instances on
    // one thread
    bool cache = false;

    // Throw an exception rather than automatically upgrading the file
    // format. Used by the browser to warn the user that it'll modify
    // the file.
    bool disable_format_upgrade = false;

    // The Scheduler which this Realm should be bound to. If not supplied,
    // a default one for the current thread will be used.
    std::shared_ptr<util::Scheduler> scheduler;

    /// A data structure storing data used to configure the Realm for sync support.
    std::shared_ptr<SyncConfig> sync_config;

    // Open the Realm using the sync history mode even if a sync
    // configuration is not supplied.
    bool force_sync_history = false;

    // A factory function which produces an audit implementation.
    std::shared_ptr<AuditConfig> audit_config;

    // Maximum number of active versions in the Realm file allowed before an exception
    // is thrown.
    uint_fast64_t max_number_of_active_versions = std::numeric_limits<uint_fast64_t>::max();

    // Disable automatic backup at file format upgrade by setting to false
    bool backup_at_file_format_change = true;

    // By default converting a top-level table to embedded will fail if there
    // are any objects without exactly one incoming link. Enabling this makes
    // it instead delete orphans and duplicate objects with multiple incoming links.
    bool automatically_handle_backlinks_in_migrations = false;

    // Only for internal testing. Not to be exposed by SDKs.
    //
    // Disable the background worker thread for producing change
    // notifications. Useful for tests for those notifications so that
    // everything can be done deterministically on one thread, and
    // speeds up tests that don't need notifications.
    bool automatic_change_notifications = true;
};

class Realm : public std::enable_shared_from_this<Realm> {
public:
    using Config = RealmConfig;

    // Returns a thread-confined live Realm for the given configuration
    static SharedRealm get_shared_realm(Config config);

    // Get a Realm for the given scheduler (or current thread if `none`)
    // from the thread safe reference.
    static SharedRealm get_shared_realm(ThreadSafeReference, std::shared_ptr<util::Scheduler> = nullptr);

#if REALM_ENABLE_SYNC
    // Open a synchronized Realm and make sure it is fully up to date before
    // returning it.
    //
    // It is possible to both cancel the download and listen to download progress
    // using the `AsyncOpenTask` returned. Note that the download doesn't actually
    // start until you call `AsyncOpenTask::start(callback)`
    static std::shared_ptr<AsyncOpenTask> get_synchronized_realm(Config config);

    std::shared_ptr<SyncSession> sync_session() const;

    // Returns the latest/active subscription set for a FLX-sync enabled realm.
    // Throws an exception for a non-FLX realm
    sync::SubscriptionSet get_latest_subscription_set();
    sync::SubscriptionSet get_active_subscription_set();
#endif

    // Returns a frozen Realm for the given Realm. This Realm can be accessed from any thread.
    static SharedRealm get_frozen_realm(Config config, VersionID version);

    // Updates a Realm to a given schema, using the Realm's pre-set schema mode.
    void update_schema(Schema schema, uint64_t version = 0, MigrationFunction migration_function = nullptr,
                       DataInitializationFunction initialization_function = nullptr, bool in_transaction = false);

    void rename_property(Schema schema, StringData object_type, StringData old_name, StringData new_name);

    // Set the schema used for this Realm, but do not update the file's schema
    // if it is not compatible (and instead throw an error).
    // Cannot be called multiple times on a single Realm instance or an instance
    // which has already had update_schema() called on it.
    void set_schema_subset(Schema schema);

    // Read the schema version from the file specified by the given config, or
    // ObjectStore::NotVersioned if it does not exist
    static uint64_t get_schema_version(Config const& config);

    Config const& config() const
    {
        return m_config;
    }
    Schema const& schema() const
    {
        return m_schema;
    }
    uint64_t schema_version() const noexcept
    {
        return m_schema_version;
    }

    void begin_transaction();
    void commit_transaction();
    void cancel_transaction();
    bool is_in_transaction() const noexcept;

    // Asynchronous (write)transaction.
    // * 'the_write_block' is queued for execution on the scheduler
    //   associated with the current realm. It will run after the write
    //   mutex has been acquired.
    // * If 'notify_only' is false, 'the_block' should end by calling commit_transaction(),
    //   cancel_transaction() or async_commit_transaction().
    // * If 'notify_only' is false, returning without one of these calls will be equivalent to calling
    //   cancel_transaction().
    // * If 'notify_only' is true, 'the_block' should only be used for signalling that
    //   a write transaction can proceed, but must not itself call async_commit() or cancel_transaction()
    // * The call returns immediately allowing the caller to proceed
    //   while the write mutex is held by someone else.
    // * Write blocks from multiple calls to async_transaction() will be
    //   executed in order.
    // * A later call to async_begin_transaction() will wait for any earlier write blocks.
    using AsyncHandle = unsigned;
    AsyncHandle async_begin_transaction(util::UniqueFunction<void()>&& the_block, bool notify_only = false);

    // Asynchronous commit.
    // * 'the_done_block' is queued for execution on the scheduler associated with
    //   the current realm. It will run after the commit has reached stable storage.
    // * The call returns immediately allowing the caller to proceed while
    //   the I/O is performed on a dedicated background thread.
    // * Callbacks to 'the_done_block' will occur in the order of async_commit()
    // * If 'allow_grouping' is set, the next async_commit *may* run without an
    //   intervening synchronization of stable storage.
    // * Such a sequence of commits form a group. In case of a platform crash,
    //   either none or all of the commits in a group will reach stable storage.
    AsyncHandle async_commit_transaction(util::UniqueFunction<void(std::exception_ptr)>&& the_done_block = nullptr,
                                         bool allow_grouping = false);

    // Returns true when a queued code block (either for an async_transaction or for an async_commit)
    // is found and cancelled (dequeued). False, if not found.
    // * Cancelling a commit will not abort the commit, it will only cancel the callback
    //   informing of commit completion.
    bool async_cancel_transaction(AsyncHandle);

    // Returns true when async transactiona has been created and the result of the last
    // commit has not yet reached permanent storage.
    bool is_in_async_transaction() const noexcept;

    void set_async_error_handler(util::UniqueFunction<void(AsyncHandle, std::exception_ptr)>&& hndlr)
    {
        m_async_exception_handler = std::move(hndlr);
    }

    // Returns a frozen copy for the current version of this Realm
    // If called from within a write transaction, the returned Realm will
    // reflect the state at the beginning of the write transaction. Any
    // accumulated state changes will not be part of it. To obtain a frozen
    // transaction reflecting a current write transaction, you need to first
    // commit the write and then freeze.
    // possible better name: freeze_at_transaction_start ?
    SharedRealm freeze();

    // Returns `true` if the Realm is frozen, `false` otherwise.
    bool is_frozen() const;

    // Returns true if the Realm is either in a read or frozen transaction
    bool is_in_read_transaction() const
    {
        return m_transaction != nullptr;
    }
    uint64_t last_seen_transaction_version()
    {
        return m_schema_transaction_version;
    }

    // Returns the number of versions in the Realm file.
    uint_fast64_t get_number_of_versions() const;

    VersionID read_transaction_version() const;
    Group& read_group();
    // Get the version of the current read or frozen transaction, or `none` if the Realm
    // is not in a read transaction
    util::Optional<VersionID> current_transaction_version() const;
    // Get the version of the latest snapshot
    util::Optional<DB::version_type> latest_snapshot_version() const;

    TransactionRef duplicate() const;

    void enable_wait_for_change();
    bool wait_for_change();
    void wait_for_change_release();

    bool is_in_migration() const noexcept
    {
        return m_in_migration;
    }

    void notify();
    bool refresh();
    void set_auto_refresh(bool auto_refresh);
    bool auto_refresh() const
    {
        return m_auto_refresh;
    }

    void invalidate();

    // WARNING / FIXME: compact() should NOT be exposed publicly on Windows
    // because it's not crash safe! It may corrupt your database if something fails
    bool compact();

    /**
     * Copy this Realm's data into another Realm file.
     *
     * If the file at `config.path` already exists and \a merge_into_existing
     * is true, the contents of this Realm will be copied into the existing
     * Realm at that path. If \a merge_into_existing is false, an exception
     * will be thrown instead.
     *
     * If the destination file does not exist, the action performed depends on
     * the type of the source and destimation files. If the destination
     * configuration is a non-sync local Realm configuration, a compacted copy
     * of the current Transaction's data (which includes uncommitted changes if
     * applicable!) is written in streaming form, with no history.
     *
     * If the target configuration is a sync configuration and the source Realm
     * is a local Realm, a sync Realm with no file identifier is created and
     * sync history is synthesized for all of the current objects in the Realm.
     *
     * If the target configuration is a sync configuration and the source Realm
     * is also a sync Realm, a sync Realm with no file identifier is created,
     * but the existing history is retained instead of synthesizing new
     * history. This mode requires that the source Realm does not have any
     * unuploaded changesets, and will thrown an exception if that is not the
     * case.
     *
     * @param config The realm configuration that specifies what file should be
     *               produced. This can be a local or a synced Realm, encrypted or not.
     * @param merge_into_existing If true, converting into an existing file
     *                            will write this Realm's data into that file
     *                            rather than throwing an exception.
     */
    void convert(const Config& config, bool merge_into_existing = true);

    OwnedBinaryData write_copy();

    void verify_thread() const;
    void verify_in_write() const;
    void verify_open() const;
    bool verify_notifications_available(bool throw_on_error = true) const;

    bool can_deliver_notifications() const noexcept;
    std::shared_ptr<util::Scheduler> scheduler() const noexcept
    {
        return m_scheduler;
    }

    // Close this Realm. Continuing to use a Realm after closing it will throw Exception(ClosedRealm)
    // Closing a Realm will wait for any asynchronous writes which have been commited but not synced
    // to sync. Asynchronous writes which have not yet started are canceled.
    void close();
    bool is_closed() const
    {
        return !m_transaction && !m_coordinator;
    }

    /**
     * Deletes the following files for the given `realm_file_path` if they exist:
     * - the Realm file itself
     * - the .management folder
     * - the .note file
     * - the .log file
     *
     * The .lock file for this Realm cannot and will not be deleted as this is unsafe.
     * If a different process / thread is accessing the Realm at the same time a corrupt state
     * could be the result and checking for a single process state is not possible here.
     *
     * @param realm_file_path The path to the Realm file. All files will be derived from this.
     * @param[out] did_delete_realm If non-null, set to true if the primary Realm file was deleted.
     *
     * @throws PermissionDenied if the operation was not permitted.
     * @throws AccessError for any other error while trying to delete the file or folder.
     * @throws Exception(DeleteOnOpenRealm) if the function was called on an open Realm.
     */
    static void delete_files(const std::string& realm_file_path, bool* did_delete_realm = nullptr);

    bool has_pending_async_work() const;

    Realm(const Realm&) = delete;
    Realm& operator=(const Realm&) = delete;
    Realm(Realm&&) = delete;
    Realm& operator=(Realm&&) = delete;
    ~Realm();

    AuditInterface* audit_context() const noexcept;

    template <typename... Args>
    auto import_copy_of(Args&&... args)
    {
        return transaction().import_copy_of(std::forward<Args>(args)...);
    }

    static SharedRealm make_shared_realm(Config config, util::Optional<VersionID> version,
                                         std::shared_ptr<_impl::RealmCoordinator> coordinator)
    {
        return std::make_shared<Realm>(std::move(config), std::move(version), std::move(coordinator),
                                       MakeSharedTag{});
    }

    // Expose some internal functionality which isn't intended to be used directly
    // by SDKS to other parts of the ObjectStore
    class Internal {
        friend class _impl::CollectionNotifier;
        friend class _impl::RealmCoordinator;
        friend class TestHelper;
        friend class ThreadSafeReference;

        static Transaction& get_transaction(Realm& realm)
        {
            return realm.transaction();
        }
        static std::shared_ptr<Transaction> get_transaction_ref(Realm& realm)
        {
            return realm.transaction_ref();
        }

        static void run_writes(Realm& realm)
        {
            realm.run_writes();
        }

        static void copy_schema(Realm& target_realm, const Realm& source_realm)
        {
            target_realm.copy_schema_from(source_realm);
        }

        // CollectionNotifier needs to be able to access the owning
        // coordinator to wake up the worker thread when a callback is
        // added, and coordinators need to be able to get themselves from a Realm
        static _impl::RealmCoordinator& get_coordinator(Realm& realm)
        {
            return *realm.m_coordinator;
        }

        static std::shared_ptr<DB>& get_db(Realm& realm);
        static void begin_read(Realm&, VersionID);
    };

private:
    struct MakeSharedTag {
    };

    std::shared_ptr<_impl::RealmCoordinator> m_coordinator;

    Config m_config;
    util::Optional<VersionID> m_frozen_version;
    std::shared_ptr<util::Scheduler> m_scheduler;
    bool m_auto_refresh = true;

    TransactionRef m_transaction;

    uint64_t m_schema_version;
    Schema m_schema;
    util::Optional<Schema> m_new_schema;
    uint64_t m_schema_transaction_version = -1;

    // FIXME: this should be a Dynamic schema mode instead, but only once
    // that's actually fully working
    bool m_dynamic_schema = true;

    // Non-zero while sending the notifications caused by advancing the read
    // transaction version, to avoid recursive notifications where possible
    size_t m_is_sending_notifications = 0;

    // True while we're performing a schema migration via this Realm instance
    // to allow for different behavior (such as allowing modifications to
    // primary key values)
    bool m_in_migration = false;

    struct AsyncWriteDesc {
        util::UniqueFunction<void()> writer;
        bool notify_only;
        unsigned handle;
    };
    std::deque<AsyncWriteDesc> m_async_write_q;
    struct AsyncCommitDesc {
        util::UniqueFunction<void(std::exception_ptr)> when_completed;
        unsigned handle;
    };
    std::vector<AsyncCommitDesc> m_async_commit_q;
    unsigned m_async_commit_handle = 0;
    size_t m_is_running_async_writes = 0;
    bool m_notify_only = false;
    size_t m_is_running_async_commit_completions = 0;
    bool m_async_commit_barrier_requested = false;
    util::UniqueFunction<void(AsyncHandle, std::exception_ptr)> m_async_exception_handler;

    void begin_read(VersionID);
    bool do_refresh();
    void do_begin_transaction();
    void do_invalidate();

    void set_schema(Schema const& reference, Schema schema);
    bool reset_file(Schema& schema, std::vector<SchemaChange>& changes_required);
    bool schema_change_needs_write_transaction(Schema& schema, std::vector<SchemaChange>& changes, uint64_t version);
    Schema get_full_schema();

    // Ensure that m_schema and m_schema_version match that of the current
    // version of the file
    void read_schema_from_group_if_needed();

    void add_schema_change_handler();
    void cache_new_schema();
    void translate_schema_error();
    void notify_schema_changed();
    void copy_schema_from(const Realm&);

    Transaction& transaction();
    Transaction& transaction() const;
    std::shared_ptr<Transaction> transaction_ref();

    void run_writes_on_proper_thread();
    void check_pending_write_requests();
    void end_current_write(bool check_pending = true);
    void call_completion_callbacks();
    void run_writes();
    void run_async_completions();

public:
    std::unique_ptr<BindingContext> m_binding_context;

    // `enable_shared_from_this` is unsafe with public constructors; use `make_shared_realm` instead
    Realm(Config config, util::Optional<VersionID> version, std::shared_ptr<_impl::RealmCoordinator> coordinator,
          MakeSharedTag);
};

} // namespace realm

#endif /* defined(REALM_REALM_HPP) */
