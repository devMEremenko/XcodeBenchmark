/*************************************************************************
 *
 * Copyright 2016 Realm Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 **************************************************************************/

#ifndef REALM_DB_HPP
#define REALM_DB_HPP

#include <realm/db_options.hpp>
#include <realm/group.hpp>
#include <realm/handover_defs.hpp>
#include <realm/impl/changeset_input_stream.hpp>
#include <realm/impl/transact_log.hpp>
#include <realm/replication.hpp>
#include <realm/util/checked_mutex.hpp>
#include <realm/util/features.h>
#include <realm/util/functional.hpp>
#include <realm/util/interprocess_condvar.hpp>
#include <realm/util/interprocess_mutex.hpp>
#include <realm/util/encrypted_file_mapping.hpp>
#include <realm/version_id.hpp>

#include <functional>
#include <cstdint>
#include <limits>
#include <condition_variable>

namespace realm {

class Transaction;
using TransactionRef = std::shared_ptr<Transaction>;

/// Thrown by DB::create() if the lock file is already open in another
/// process which can't share mutexes with this process
struct IncompatibleLockFile : FileAccessError {
    IncompatibleLockFile(const std::string& path, const std::string& msg)
        : FileAccessError(
              ErrorCodes::IncompatibleLockFile,
              util::format(
                  "Realm file '%1' is currently open in another process which cannot share access with this process. "
                  "This could either be due to the existing process being a different architecture or due to the "
                  "existing process using an incompatible version of Realm. "
                  "If the other process is Realm Studio, you may need to update it (or update Realm if your Studio "
                  "version is too new), and if using an iOS simulator, make sure that you are using a 64-bit "
                  "simulator. Underlying problem: %2",
                  path, msg),
              path)
    {
    }
};

/// Thrown by DB::create() if the type of history
/// (Replication::HistoryType) in the opened Realm file is incompatible with the
/// mode in which the Realm file is opened. For example, if there is a mismatch
/// between the history type in the file, and the history type associated with
/// the replication plugin passed to DB::create().
///
/// This exception will also be thrown if the history schema version is lower
/// than required, and no migration is possible
/// (Replication::is_upgradable_history_schema()).
struct IncompatibleHistories : FileAccessError {
    IncompatibleHistories(const std::string& msg, const std::string& path)
        : FileAccessError(ErrorCodes::IncompatibleHistories,
                          msg + " Synchronized Realms cannot be opened in non-sync mode, and vice versa.", path)
    {
    }
};

/// The FileFormatUpgradeRequired exception can be thrown by the DB
/// constructor when opening a database that uses a deprecated file format
/// and/or a deprecated history schema, and the user has indicated he does not
/// want automatic upgrades to be performed. This exception indicates that until
/// an upgrade of the file format is performed, the database will be unavailable
/// for read or write operations.
/// It will also be thrown if a realm which requires upgrade is opened in read-only
/// mode (Group::open).
struct FileFormatUpgradeRequired : FileAccessError {
    FileFormatUpgradeRequired(const std::string& path)
        : FileAccessError(ErrorCodes::FileFormatUpgradeRequired, "Database upgrade required but prohibited.", path, 0)
    {
    }
};


/// A DB facilitates transactions.
///
/// Access to a database is done through transactions. Transactions
/// are created by a DB object. No matter how many transactions you
/// use, you only need a single DB object per file. Methods on the DB
/// object are thread-safe.
///
/// Realm has 3 types of Transactions:
/// * A frozen transaction allows read only access
/// * A read transaction allows read only access but can be promoted
///   to a write transaction.
/// * A write transaction allows write access. A write transaction can
///   be demoted to a read transaction.
///
/// Frozen transactions are thread safe. Read and write transactions are not.
///
/// Two processes that want to share a database file must reside on
/// the same host.
///

class DB;
using DBRef = std::shared_ptr<DB>;

class DB : public std::enable_shared_from_this<DB> {
    struct ReadLockInfo;

public:
    // Create a DB and associate it with a file. DB Objects can only be associated with one file,
    // the association determined on creation of the DB Object. The association can be broken by
    // calling DB::close(), but after that no new association can be established. To reopen the
    // file (or another file), a new DB object is needed. The specified Replication instance, if
    // any, must remain in existence for as long as the DB.
    static DBRef create(const std::string& file, bool no_create = false, const DBOptions& options = DBOptions());
    static DBRef create(Replication& repl, const std::string& file, const DBOptions& options = DBOptions());
    static DBRef create(std::unique_ptr<Replication> repl, const std::string& file,
                        const DBOptions& options = DBOptions());
    static DBRef create(BinaryData, bool take_ownership = true);
    static DBRef create(std::unique_ptr<Replication> repl, const DBOptions& options = DBOptions());
    // file is used to set the `db_path` used to register and associate a users's SyncSession with the Realm path (see
    // SyncUser::register_session) SyncSession::path() relies on the registered `m_db->get_path`
    static DBRef create_in_memory(std::unique_ptr<Replication> repl, const std::string& file,
                                  const DBOptions& options = DBOptions());

    ~DB() noexcept;

    // Disable copying to prevent accessor errors. If you really want another
    // instance, open another DB object on the same file. But you don't.
    DB(const DB&) = delete;
    DB& operator=(const DB&) = delete;
    /// Close an open database. Calling close() is thread-safe with respect to
    /// other calls to close and with respect to deleting transactions.
    /// Calling close() while a write transaction is open is an error and close()
    /// will throw a LogicError::wrong_transact_state.
    /// Calling close() while a read transaction is open is by default treated
    /// in the same way, but close(true) will allow the error to be ignored and
    /// release resources despite open read transactions.
    /// As successfull call to close() leaves transactions (and any associated
    /// accessors) in a defunct state and the actual close() operation is not
    /// interlocked with access through those accessors, so any access through accessors
    /// may constitute a race with a call to close().
    /// Instead of using DB::close() to release resources, we recommend using transactions
    /// to control release as follows:
    ///  * explicitly nullify TransactionRefs at earliest time possible and
    ///  * for read or write transactions - but not frozen transactions, explicitly call
    ///    close() at earliest time possible
    ///  * explicitly nullify any DBRefs you may have.
    void close(bool allow_open_read_transactions = false) REQUIRES(!m_mutex);

    bool is_attached() const noexcept;

    Allocator& get_alloc()
    {
        return m_alloc;
    }

    Replication* get_replication() const
    {
        return m_replication;
    }

    void set_replication(Replication* repl) noexcept
    {
        m_replication = repl;
    }

    void set_logger(const std::shared_ptr<util::Logger>& logger) noexcept;
    util::Logger* get_logger() const noexcept
    {
        return m_logger.get();
    }

    void create_new_history(Replication& repl) REQUIRES(!m_mutex);
    void create_new_history(std::unique_ptr<Replication> repl) REQUIRES(!m_mutex);

    const std::string& get_path() const noexcept
    {
        return m_db_path;
    }

    const char* get_encryption_key() const noexcept
    {
        return m_alloc.m_file.get_encryption_key();
    }

#ifdef REALM_DEBUG
    /// Deprecated method, only called from a unit test
    ///
    /// Reserve disk space now to avoid allocation errors at a later
    /// point in time, and to minimize on-disk fragmentation. In some
    /// cases, less fragmentation translates into improved
    /// performance.
    ///
    /// When supported by the system, a call to this function will
    /// make the database file at least as big as the specified size,
    /// and cause space on the target device to be allocated (note
    /// that on many systems on-disk allocation is done lazily by
    /// default). If the file is already bigger than the specified
    /// size, the size will be unchanged, and on-disk allocation will
    /// occur only for the initial section that corresponds to the
    /// specified size.
    ///
    /// It is an error to call this function on an unattached shared
    /// group. Doing so will result in undefined behavior.
    void reserve(size_t size_in_bytes);
#endif

    /// Querying for changes:
    ///
    /// NOTE:
    /// "changed" means that one or more commits has been made to the database
    /// since the presented transaction was made.
    ///
    /// No distinction is made between changes done by another process
    /// and changes done by another thread in the same process as the caller.
    ///
    /// Has db been changed ?
    bool has_changed(TransactionRef&);

    /// The calling thread goes to sleep until the database is changed, or
    /// until wait_for_change_release() is called. After a call to
    /// wait_for_change_release() further calls to wait_for_change() will return
    /// immediately. To restore the ability to wait for a change, a call to
    /// enable_wait_for_change() is required. Return true if the database has
    /// changed, false if it might have.
    bool wait_for_change(TransactionRef&);
    /// release any thread waiting in wait_for_change().
    void wait_for_change_release();

    /// re-enable waiting for change
    void enable_wait_for_change();
    // Transactions:

    using version_type = _impl::History::version_type;
    using VersionID = realm::VersionID;

    /// Returns the version of the latest snapshot.
    version_type get_version_of_latest_snapshot();
    VersionID get_version_id_of_latest_snapshot();

    /// Thrown by start_read() if the specified version does not correspond to a
    /// bound (AKA tethered) snapshot.
    struct BadVersion;

    /// Transactions are obtained from one of the following 3 methods:
    TransactionRef start_read(VersionID = VersionID()) REQUIRES(!m_mutex);
    TransactionRef start_frozen(VersionID = VersionID()) REQUIRES(!m_mutex);
    // If nonblocking is true and a write transaction is already active,
    // an invalid TransactionRef is returned.
    TransactionRef start_write(bool nonblocking = false) REQUIRES(!m_mutex);

    // ask for write mutex. Callback takes place when mutex has been acquired.
    // callback may occur on ANOTHER THREAD. Must not be called if write mutex
    // has already been acquired.
    void async_request_write_mutex(TransactionRef& tr, util::UniqueFunction<void()>&& when_acquired);

    // report statistics of last commit done on THIS DB.
    // The free space reported is what can be expected to be freed
    // by compact(). This may not correspond to the space which is free
    // at the point where get_stats() is called, since that will include
    // memory required to hold older versions of data, which still
    // needs to be available. The locked space is the amount of memory
    // that is free in current version, but being used in still live versions.
    // Notice that we will always have two live versions - the current and the
    // previous.
    void get_stats(size_t& free_space, size_t& used_space, size_t* locked_space = nullptr) const REQUIRES(!m_mutex);
    //@}

    enum TransactStage {
        transact_Ready,
        transact_Reading,
        transact_Writing,
        transact_Frozen,
    };

    enum class EvacStage { idle, evacuating, waiting, blocked };

    EvacStage get_evacuation_stage() const
    {
        return m_evac_stage;
    }

    /// Report the number of distinct versions stored in the database at the time
    /// of latest commit.
    /// Note: the database only cleans up versions as part of commit, so ending
    /// a read transaction will not immediately release any versions.
    uint_fast64_t get_number_of_versions();

    /// Get the size of the currently allocated slab area
    size_t get_allocated_size() const;

    /// Compact the database file.
    /// - The method will throw if called inside a transaction.
    /// - The method will throw if called in unattached state.
    /// - The method will return false if other DBs are accessing the
    ///    database in which case compaction is not done. This is not
    ///    necessarily an error.
    /// It will return true following successful compaction.
    /// While compaction is in progress, attempts by other
    /// threads or processes to open the database will wait.
    /// Likewise, attempts to create new transactions will wait.
    /// Be warned that resource requirements for compaction is proportional to
    /// the amount of live data in the database.
    /// Compaction works by writing the database contents to a temporary
    /// database file and then replacing the database with the temporary one.
    /// The name of the temporary file is formed by appending
    /// ".tmp_compaction_space" to the name of the database
    ///
    /// If the output_encryption_key is `none` then the file's existing key will
    /// be used (if any). If the output_encryption_key is nullptr, the resulting
    /// file will be unencrypted. Any other value will change the encryption of
    /// the file to the new 64 byte key.
    ///
    /// WARNING: Compact() is not thread-safe with respect to a concurrent close()
    bool compact(bool bump_version_number = false, util::Optional<const char*> output_encryption_key = util::none)
        REQUIRES(!m_mutex);

    void write_copy(StringData path, const char* output_encryption_key) REQUIRES(!m_mutex);

#ifdef REALM_DEBUG
    void test_ringbuf();
#endif

    /// The relation between accessors, threads and the Transaction object.
    ///
    /// Once created, accessors belong to a transaction and can only be used for
    /// access as long as that transaction is still active. Copies of accessors
    /// can be created in association with another transaction, the importing transaction,
    /// using said transactions import_copy_of() method. This process is called
    /// accessor import. Prior to Core 6, the corresponding mechanism was known
    /// as "handover".
    ///
    /// For TableViews, there are 3 forms of import determined by the PayloadPolicy.
    ///
    /// - with payload move: the payload imported ends up as a payload
    ///   held by the accessor at the importing side. The accessor on the
    ///   exporting side will rerun its query and generate a new payload, if
    ///   TableView::sync_if_needed() is called. If the original payload was in
    ///   sync at the exporting side, it will also be in sync at the importing
    ///   side. This policy is selected by PayloadPolicy::Move
    ///
    /// - with payload copy: a copy of the payload is imported, so both the
    ///   accessors on the exporting side *and* the accessors created at the
    ///   importing side has their own payload. This is policy is selected
    ///   by PayloadPolicy::Copy
    ///
    /// - without payload: the payload stays with the accessor on the exporting
    ///   side. On the importing side, the new accessor is created without
    ///   payload. A call to TableView::sync_if_needed() will trigger generation
    ///   of a new payload. This policy is selected by PayloadPolicy::Stay.
    ///
    /// For all other (non-TableView) accessors, importing is done with payload
    /// copy, since the payload is trivial.
    ///
    /// Importing *without* payload is useful when you want to ship a tableview
    /// with its query for execution in a background thread. Handover with
    /// *payload move* is useful when you want to transfer the result back.
    ///
    /// Importing *without* payload or with payload copy is guaranteed *not* to
    /// change the accessors on the exporting side.
    ///
    /// Importing is generally *not* thread safe and should be carried out
    /// by the thread that "owns" the involved accessors. However, importing
    /// *is* thread-safe when it occurs from a *frozen* accessor.
    ///
    /// Importing is transitive:
    /// If the object being imported depends on other views
    /// (table- or link- ), those objects will be imported as well. The mode
    /// (payload copy, payload move, without payload) is applied
    /// recursively. Note: If you are importing a tableview dependent upon
    /// another tableview and using MutableSourcePayload::Move,
    /// you are on thin ice!
    ///
    /// On the importing side, the top-level accessor being created during
    /// import takes ownership of all other accessors (if any) being created as
    /// part of the import.

    // Try to grab an exclusive lock of the given realm path's lock file. If the lock
    // can be acquired, the callback will be executed with the lock and then return true.
    // Otherwise false will be returned directly.
    // The lock taken precludes races with other threads or processes accessing the
    // files through a DB.
    // It is safe to delete/replace realm files inside the callback.
    // WARNING: It is not safe to delete the lock file in the callback.
    using CallbackWithLock = util::FunctionRef<void(const std::string& realm_path)>;
    static bool call_with_lock(const std::string& realm_path, CallbackWithLock&& callback);

    enum CoreFileType : uint8_t {
        Lock,
        Storage,
        Management,
        Note,
        Log,
    };

    /// Get the path for the given type of file for a base Realm file path.
    /// \param realm_path The path for the main Realm file.
    /// \param type The type of associated file to get the path for.
    /// \return The base path with the appropriate type-specific suffix appended to it.
    static std::string get_core_file(const std::string& realm_path, CoreFileType type);

    /// Delete a Realm file and all associated control files.
    ///
    /// This function does not perform any locking and requires external
    /// synchronization to ensure that it is safe to call. If called within
    /// call_with_lock(), \p delete_lockfile must be false as the lockfile is not
    /// safe to delete while it is in use.
    ///
    /// \param base_path The Realm file to delete, which auxiliary file paths will be derived from.
    /// \param[out] did_delete_realm If non-null, will be set to true if the Realm file was deleted (even if a
    ///             subsequent deletion failed)
    /// \param delete_lockfile By default the lock file is not deleted as it is unsafe to
    ///        do so. If this is true, the lock file is deleted along with the other files.
    static void delete_files(const std::string& base_path, bool* did_delete_realm = nullptr,
                             bool delete_lockfile = false);

    /// Mark this DB as the sync agent for the file.
    /// \throw MultipleSyncAgents if another DB is already the sync agent.
    void claim_sync_agent();
    void release_sync_agent();

    /// Returns true if there are threads waiting to acquire the write lock, false otherwise.
    /// To be used only when already holding the lock.
    bool other_writers_waiting_for_lock() const;

protected:
    explicit DB(const DBOptions& options);

private:
    class AsyncCommitHelper;
    class VersionManager;
    class EncryptionMarkerObserver;
    class FileVersionManager;
    class InMemoryVersionManager;
    struct SharedInfo;
    struct ReadCount;
    struct ReadLockInfo {
        enum Type { Frozen, Live, Full };
        uint_fast64_t m_version = std::numeric_limits<version_type>::max();
        uint_fast32_t m_reader_idx = 0;
        ref_type m_top_ref = 0;
        size_t m_file_size = 0;
        Type m_type = Live;
        // a little helper
        static std::unique_ptr<ReadLockInfo> make_fake(ref_type top_ref, size_t file_size)
        {
            auto res = std::make_unique<ReadLockInfo>();
            res->m_top_ref = top_ref;
            res->m_file_size = file_size;
            res->m_version = 1;
            return res;
        }
        void check() const noexcept
        {
            REALM_ASSERT_RELEASE_EX((m_top_ref & 7) == 0 && m_top_ref < m_file_size, m_version, m_reader_idx,
                                    m_top_ref, m_file_size);
        }
    };
    class ReadLockGuard;

    // Member variables
    mutable util::CheckedMutex m_mutex;
    int m_transaction_count GUARDED_BY(m_mutex) = 0;
    SlabAlloc m_alloc;
    std::unique_ptr<Replication> m_history;
    std::unique_ptr<VersionManager> m_version_manager;
    std::unique_ptr<EncryptionMarkerObserver> m_marker_observer;
    Replication* m_replication = nullptr;
    size_t m_free_space GUARDED_BY(m_mutex) = 0;
    size_t m_locked_space GUARDED_BY(m_mutex) = 0;
    size_t m_used_space GUARDED_BY(m_mutex) = 0;
    std::vector<ReadLockInfo> m_local_locks_held GUARDED_BY(m_mutex); // tracks all read locks held by this DB
    std::atomic<EvacStage> m_evac_stage = EvacStage::idle;
    util::File m_file;
    util::File::Map<SharedInfo> m_file_map; // Never remapped, provides access to everything but the ringbuffer
    std::unique_ptr<SharedInfo> m_in_memory_info;
    SharedInfo* m_info = nullptr;
    bool m_wait_for_change_enabled = true; // Initially wait_for_change is enabled
    bool m_write_transaction_open GUARDED_BY(m_mutex) = false;
    std::string m_db_path;
    int m_file_format_version = 0;
    util::InterprocessMutex m_writemutex;
    std::unique_ptr<ReadLockInfo> m_fake_read_lock_if_immutable;
    util::InterprocessMutex m_controlmutex;
    util::InterprocessMutex m_versionlist_mutex;
    util::InterprocessCondVar m_new_commit_available;
    util::InterprocessCondVar m_pick_next_writer;
    std::function<void(int, int)> m_upgrade_callback;
    std::unique_ptr<AsyncCommitHelper> m_commit_helper;
    std::shared_ptr<util::Logger> m_logger;
    bool m_is_sync_agent = false;
    // Id for this DB to be used in logging. We will just use some bits from the pointer.
    // The path cannot be used as this would not allow us to distinguish between two DBs opening
    // the same realm.
    unsigned m_log_id;

    /// Attach this DB instance to the specified database file.
    ///
    /// While at least one instance of DB exists for a specific
    /// database file, a "lock" file will be present too. The lock file will be
    /// placed in the same directory as the database file, and its name will be
    /// derived by appending ".lock" to the name of the database file.
    ///
    /// When multiple DB instances refer to the same file, they must
    /// specify the same durability level, otherwise an exception will be
    /// thrown.
    ///
    /// \param file Filesystem path to a Realm database file.
    ///
    /// \param no_create If the database file does not already exist, it will be
    /// created (unless this is set to true.) When multiple threads are involved,
    /// it is safe to let the first thread, that gets to it, create the file.
    ///
    /// \param options See DBOptions for details of each option.
    /// Sensible defaults are provided if this parameter is left out.
    ///
    /// \throw FileAccessError If the file could not be opened. If the
    /// reason corresponds to one of the exception types that are derived from
    /// FileAccessError, the derived exception type is thrown. Note that
    /// InvalidDatabase is among these derived exception types.
    ///
    /// \throw FileFormatUpgradeRequired if \a DBOptions::allow_upgrade
    /// is `false` and an upgrade is required.
    ///
    /// \throw LogicError if both DBOptions::allow_upgrade and is_immutable is true.
    /// \throw UnsupportedFileFormatVersion if the file format version or
    /// history schema version is one which this version of Realm does not know
    /// how to migrate from.
    void open(const std::string& file, bool no_create = false, const DBOptions& options = DBOptions())
        REQUIRES(!m_mutex);
    void open(BinaryData, bool take_ownership = true) REQUIRES(!m_mutex);
    void open(Replication&, const std::string& file, const DBOptions& options = DBOptions()) REQUIRES(!m_mutex);
    void open(Replication& repl, const DBOptions options = DBOptions()) REQUIRES(!m_mutex);

    void do_open(const std::string& file, bool no_create, const DBOptions& options);

    Replication* const* get_repl() const noexcept
    {
        return &m_replication;
    }

    // Ring buffer management
    bool ringbuf_is_empty() const noexcept;
    size_t ringbuf_size() const noexcept;
    size_t ringbuf_capacity() const noexcept;
    bool ringbuf_is_first(size_t ndx) const noexcept;
    void ringbuf_remove_first() noexcept;
    size_t ringbuf_find(uint64_t version) const noexcept;
    ReadCount& ringbuf_get(size_t ndx) noexcept;
    ReadCount& ringbuf_get_first() noexcept;
    ReadCount& ringbuf_get_last() noexcept;
    void ringbuf_put(const ReadCount& v);
    void ringbuf_expand();

    /// Grab a read lock on the snapshot associated with the specified
    /// version. If `version_id == VersionID()`, a read lock will be grabbed on
    /// the latest available snapshot. Fails if the snapshot is no longer
    /// available.
    ///
    /// As a side effect update memory mapping to ensure that the ringbuffer
    /// entries referenced in the readlock info is accessible.
    ReadLockInfo grab_read_lock(ReadLockInfo::Type, VersionID) REQUIRES(!m_mutex);

    // Release a specific read lock. The read lock MUST have been obtained by a
    // call to grab_read_lock().
    void release_read_lock(ReadLockInfo&) noexcept REQUIRES(!m_mutex);
    void do_release_read_lock(ReadLockInfo&) noexcept REQUIRES(m_mutex);
    // Stop tracking a read lock without actually releasing it.
    void leak_read_lock(ReadLockInfo&) noexcept REQUIRES(!m_mutex);

    // Release all read locks held by this DB object. After release, further calls to
    // release_read_lock for locks already released must be avoided.
    void release_all_read_locks() noexcept REQUIRES(!m_mutex);

    /// return true if write transaction can commence, false otherwise.
    bool do_try_begin_write() REQUIRES(!m_mutex);
    void do_begin_write() REQUIRES(!m_mutex);
    void do_begin_possibly_async_write() REQUIRES(!m_mutex);
    version_type do_commit(Transaction&, bool commit_to_disk = true) REQUIRES(!m_mutex);
    void do_end_write() noexcept REQUIRES(!m_mutex);
    void end_write_on_correct_thread() noexcept REQUIRES(!m_mutex);
    // Must be called only by someone that has a lock on the write mutex.
    void low_level_commit(uint_fast64_t new_version, Transaction& transaction, bool commit_to_disk = true)
        REQUIRES(!m_mutex);

    void do_async_commits();

    /// Upgrade file format and/or history schema
    void upgrade_file_format(bool allow_file_format_upgrade, int target_file_format_version,
                             int current_hist_schema_version, int target_hist_schema_version) REQUIRES(!m_mutex);

    int get_file_format_version() const noexcept;

    /// finish up the process of starting a write transaction. Internal use only.
    void finish_begin_write() REQUIRES(!m_mutex);

    void reset_free_space_tracking()
    {
        m_alloc.reset_free_space_tracking();
    }

    void close_internal(std::unique_lock<util::InterprocessMutex>, bool allow_open_read_transactions)
        REQUIRES(!m_mutex);

    void async_begin_write(util::UniqueFunction<void()> fn);
    void async_end_write();
    void async_sync_to_disk(util::UniqueFunction<void()> fn);

    friend class SlabAlloc;
    friend class Transaction;
};

inline void DB::get_stats(size_t& free_space, size_t& used_space, size_t* locked_space) const
{
    util::CheckedLockGuard lock(m_mutex);
    free_space = m_free_space;
    used_space = m_used_space;
    if (locked_space) {
        *locked_space = m_locked_space;
    }
}


class DisableReplication {
public:
    DisableReplication(Transaction& t);
    ~DisableReplication();

private:
    Transaction& m_tr;
    DBRef m_owner;
    Replication* m_repl;
    DB::version_type m_version;
};

// Implementation:

struct DB::BadVersion : Exception {
    BadVersion(version_type version)
        : Exception(ErrorCodes::BadVersion,
                    util::format("Unable to lock version %1 as it does not exist or has been cleaned up.", version))
    {
    }
};

inline bool DB::is_attached() const noexcept
{
    return bool(m_fake_read_lock_if_immutable) || m_info;
}

class DB::ReadLockGuard {
public:
    ReadLockGuard(DB& shared_group, ReadLockInfo& read_lock) noexcept
        : m_db(shared_group)
        , m_read_lock(&read_lock)
    {
    }
    ~ReadLockGuard() noexcept
    {
        if (m_read_lock)
            m_db.release_read_lock(*m_read_lock);
    }
    void release() noexcept
    {
        m_read_lock = 0;
    }

private:
    DB& m_db;
    ReadLockInfo* m_read_lock;
};

inline int DB::get_file_format_version() const noexcept
{
    return m_file_format_version;
}

} // namespace realm

#endif // REALM_DB_HPP
