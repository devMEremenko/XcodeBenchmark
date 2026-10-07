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

#ifndef REALM_COORDINATOR_HPP
#define REALM_COORDINATOR_HPP

#include <realm/object-store/shared_realm.hpp>

#include <realm/util/checked_mutex.hpp>
#include <realm/version_id.hpp>

#include <condition_variable>
#include <mutex>

namespace realm {
class DB;
class Schema;
class StringData;
class SyncSession;
class Transaction;

namespace _impl {
class CollectionNotifier;
class ExternalCommitHelper;
class WeakRealmNotifier;

// RealmCoordinator manages the weak cache of Realm instances and communication
// between per-thread Realm instances for a given file
class RealmCoordinator : public std::enable_shared_from_this<RealmCoordinator> {
public:
    // Get the coordinator for the given path, creating it if neccesary
    static std::shared_ptr<RealmCoordinator> get_coordinator(StringData path);
    // Get the coordinator for the given config, creating it if neccesary
    static std::shared_ptr<RealmCoordinator> get_coordinator(const Realm::Config&);
    // Get the coordinator for the given path, or null if there is none
    static std::shared_ptr<RealmCoordinator> get_existing_coordinator(StringData path);

    // Get a shared Realm with the given configuration
    // If the Realm is already opened on another thread, validate that the given
    // configuration is compatible with the existing one.
    // If no version is provided a live thread-confined Realm is returned.
    // Otherwise, a frozen Realm at the given version is returned. This
    // can be read from any thread.
    std::shared_ptr<Realm> get_realm(Realm::Config config, util::Optional<VersionID> version)
        REQUIRES(!m_realm_mutex, !m_schema_cache_mutex);
    std::shared_ptr<Realm> get_realm(std::shared_ptr<util::Scheduler> = nullptr, bool first_time_open = false)
        REQUIRES(!m_realm_mutex, !m_schema_cache_mutex);

    // Return a frozen copy of the source Realm. May return a cached instance
    // if the source Realm has caching enabled.
    std::shared_ptr<Realm> freeze_realm(const Realm& source_realm) REQUIRES(!m_realm_mutex);

#if REALM_ENABLE_SYNC
    // Get a thread-local shared Realm with the given configuration
    // If the Realm is not already present, it will be fully downloaded before being returned.
    // If the Realm is already on disk, it will be fully synchronized before being returned.
    // Timeouts and interruptions are not handled by this method and must be handled by upper layers.
    std::shared_ptr<AsyncOpenTask> get_synchronized_realm(Realm::Config config)
        REQUIRES(!m_realm_mutex, !m_schema_cache_mutex);

    std::shared_ptr<SyncSession> sync_session() REQUIRES(!m_realm_mutex)
    {
        util::CheckedLockGuard lock(m_realm_mutex);
        return m_sync_session;
    }
#endif

    // Get the existing cached Realm if it exists for the specified scheduler or config.scheduler
    std::shared_ptr<Realm> get_cached_realm(Realm::Config const& config,
                                            std::shared_ptr<util::Scheduler> scheduler = nullptr)
        REQUIRES(!m_realm_mutex);
    // Get a Realm which is not bound to the current execution context
    ThreadSafeReference get_unbound_realm() REQUIRES(!m_realm_mutex);

    // Bind an unbound Realm to a specific execution context. The Realm must
    // be managed by this coordinator.
    void bind_to_context(Realm& realm) REQUIRES(!m_realm_mutex);

    Realm::Config get_config() const REQUIRES(!m_realm_mutex)
    {
        util::CheckedLockGuard lock(m_realm_mutex);
        return m_config;
    }

    uint64_t get_schema_version() const noexcept REQUIRES(!m_schema_cache_mutex);
    const std::string& get_path() const noexcept
    {
        return m_config.path;
    }
    const std::vector<char>& get_encryption_key() const noexcept
    {
        return m_config.encryption_key;
    }
    bool is_in_memory() const noexcept
    {
        return m_config.in_memory;
    }
    // Returns the number of versions in the Realm file.
    uint_fast64_t get_number_of_versions() const
    {
        return m_db->get_number_of_versions();
    }

    // To avoid having to re-read and validate the file's schema every time a
    // new read transaction is begun, RealmCoordinator maintains a cache of the
    // most recently seen file schema and the range of transaction versions
    // which it applies to. Note that this schema may not be identical to that
    // of any Realm instances managed by this coordinator, as individual Realms
    // may only be using a subset of it.

    // Get the latest cached schema and the transaction version which it applies
    // to. Returns false if there is no cached schema.
    bool get_cached_schema(Schema& schema, uint64_t& schema_version, uint64_t& transaction) const noexcept
        REQUIRES(!m_schema_cache_mutex);

    // Cache the state of the schema at the given transaction version
    void cache_schema(Schema const& new_schema, uint64_t new_schema_version, uint64_t transaction_version)
        REQUIRES(!m_schema_cache_mutex);
    // If there is a schema cached for transaction version `previous`, report
    // that it is still valid at transaction version `next`
    void advance_schema_cache(uint64_t previous, uint64_t next) REQUIRES(!m_schema_cache_mutex);
    void clear_schema_cache_and_set_schema_version(uint64_t new_schema_version) REQUIRES(!m_schema_cache_mutex);


    // Asynchronously call notify() on every Realm instance for this coordinator's
    // path, including those in other processes
    void send_commit_notifications(Realm&);
    void wake_up_notifier_worker();

    // Clear the weak Realm cache for all paths
    // Should only be called in test code, as continuing to use the previously
    // cached instances will have odd results
    static void clear_cache();

    // Clears all caches on existing coordinators
    static void clear_all_caches();

    // Verify that there are no Realms open for any paths
    static void assert_no_open_realms() noexcept;

    // Explicit constructor/destructor needed for the unique_ptrs to forward-declared types
    RealmCoordinator();
    ~RealmCoordinator();

    // Called by Realm's destructor to ensure the cache is cleaned up promptly
    // Do not call directly
    void unregister_realm(Realm* realm) REQUIRES(!m_realm_mutex, !m_notifier_mutex);

    // Called by m_notifier when there's a new commit to send notifications for
    void on_change() REQUIRES(!m_realm_mutex, !m_notifier_mutex, !m_running_notifiers_mutex);

    static void register_notifier(std::shared_ptr<CollectionNotifier> notifier);

    TransactionRef begin_read(VersionID version = {}, bool frozen_transaction = false);

    // Returns true if there are any versions after the Realm's read version
    bool can_advance(Realm& realm);

    // Advance the Realm to the most recent transaction version which all async
    // work is complete for
    void advance_to_ready(Realm& realm) REQUIRES(!m_notifier_mutex);

    // Advance the Realm to the most recent transaction version, running the
    // async notifiers if they aren't ready for that version
    // returns true if actually changed the version
    bool advance_to_latest(Realm& realm) REQUIRES(!m_notifier_mutex, !m_running_notifiers_mutex);

    // Deliver any notifications which are ready for the Realm's version
    void process_available_async(Realm& realm) REQUIRES(!m_notifier_mutex);

    // Deliver notifications for the Realm, blocking if some aren't ready yet
    // The calling Realm must be in a write transaction
    void promote_to_write(Realm& realm) REQUIRES(!m_notifier_mutex);

    // Commit a Realm's current write transaction and send notifications to all
    // other Realm instances for that path, including in other processes
    void commit_write(Realm& realm, bool commit_to_disk = true) REQUIRES(!m_notifier_mutex);

    void enable_wait_for_change();
    bool wait_for_change(std::shared_ptr<Transaction> tr);
    void wait_for_change_release();

    void close();
    bool compact();
    void write_copy(StringData path, const char* key);

    // Close the DB, delete the file, and then reopen it. This operation is *not*
    // implemented in a safe manner and will only work in fairly specific circumstances
    void delete_and_reopen() REQUIRES(!m_realm_mutex);

    using NotifierVector = std::vector<std::shared_ptr<_impl::CollectionNotifier>>;
    // Called by NotifierPackage in the cases where we don't know what version
    // we need notifiers for until after we begin advancing (e.g. when
    // starting a write transaction). Will return a Transaction at the packaged
    // version if any notifiers were packaged, and null otherwise.
    TransactionRef package_notifiers(NotifierVector& notifiers, VersionID::version_type)
        REQUIRES(!m_notifier_mutex, !m_running_notifiers_mutex);

    // testing hook only to verify that notifiers are not being run at times
    // they shouldn't be
    std::unique_lock<std::mutex> block_notifier_execution() REQUIRES(!m_running_notifiers_mutex)
    {
        return std::move(util::CheckedUniqueLock(m_running_notifiers_mutex).native_handle());
    }

    void async_request_write_mutex(Realm& realm);

    AuditInterface* audit_context() const noexcept
    {
        return m_audit_context.get();
    }

private:
    friend Realm::Internal;
    Realm::Config m_config;
    std::shared_ptr<DB> m_db;

    mutable util::CheckedMutex m_schema_cache_mutex;
    util::Optional<Schema> m_cached_schema GUARDED_BY(m_schema_cache_mutex);
    uint64_t m_schema_version GUARDED_BY(m_schema_cache_mutex) = -1;
    uint64_t m_schema_transaction_version_min GUARDED_BY(m_schema_cache_mutex) = 0;
    uint64_t m_schema_transaction_version_max GUARDED_BY(m_schema_cache_mutex) = 0;

    util::CheckedMutex m_realm_mutex;
    std::vector<WeakRealmNotifier> m_weak_realm_notifiers GUARDED_BY(m_realm_mutex);

    util::CheckedMutex m_notifier_mutex;
    NotifierVector m_new_notifiers GUARDED_BY(m_notifier_mutex);
    NotifierVector m_notifiers GUARDED_BY(m_notifier_mutex);
    TransactionRef m_notifier_skip_version GUARDED_BY(m_notifier_mutex);

    util::CheckedMutex m_running_notifiers_mutex;
    // Transaction used for actually running async notifiers
    // Will be non-null iff m_notifiers is non-empty
    std::shared_ptr<Transaction> m_notifier_transaction;
    // Transaction used to pin the version which notifiers are currently ready
    // to deliver to
    std::shared_ptr<Transaction> m_notifier_handover_transaction;

    std::unique_ptr<_impl::ExternalCommitHelper> m_notifier;

#if REALM_ENABLE_SYNC
    std::shared_ptr<SyncSession> m_sync_session;
#endif

    std::shared_ptr<AuditInterface> m_audit_context;

    // returns true the first time the database is opened, false otherwise.
    bool open_db() REQUIRES(m_realm_mutex);

    void set_config(const Realm::Config&) REQUIRES(m_realm_mutex, !m_schema_cache_mutex);
    void init_external_helpers() REQUIRES(m_realm_mutex);
    std::shared_ptr<Realm> do_get_cached_realm(Realm::Config const& config,
                                               std::shared_ptr<util::Scheduler> scheduler = nullptr)
        REQUIRES(m_realm_mutex);
    void do_get_realm(Realm::Config&& config, std::shared_ptr<Realm>& realm, util::Optional<VersionID> version,
                      util::CheckedUniqueLock& realm_lock, bool first_time_open = false) REQUIRES(m_realm_mutex);
    void run_async_notifiers() REQUIRES(!m_notifier_mutex, m_running_notifiers_mutex);
    void clean_up_dead_notifiers() REQUIRES(m_notifier_mutex);

    NotifierVector notifiers_for_realm(Realm&) REQUIRES(m_notifier_mutex);
};

void translate_file_exception(StringData path, bool immutable = false);

} // namespace _impl
} // namespace realm

#endif /* REALM_COORDINATOR_HPP */
