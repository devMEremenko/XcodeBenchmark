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

#ifndef REALM_TRANSACTION_HPP
#define REALM_TRANSACTION_HPP

#include <realm/db.hpp>

namespace realm {
class Transaction : public Group {
public:
    Transaction(DBRef _db, SlabAlloc* alloc, DB::ReadLockInfo& rli, DB::TransactStage stage);
    // convenience, so you don't need to carry a reference to the DB around
    ~Transaction();

    DB::version_type get_version() const noexcept
    {
        return m_read_lock.m_version;
    }
    DB::version_type get_version_of_latest_snapshot()
    {
        return db->get_version_of_latest_snapshot();
    }
    /// Get a version id which may be used to request a different transaction locked to specific version.
    DB::VersionID get_version_of_current_transaction() const noexcept
    {
        return VersionID(m_read_lock.m_version, m_read_lock.m_reader_idx);
    }

    void close() REQUIRES(!m_async_mutex);
    bool is_attached()
    {
        return m_transact_stage != DB::transact_Ready && db->is_attached();
    }

    /// Get the approximate size of the data that would be written to the file if
    /// a commit were done at this point. The reported size will always be bigger
    /// than what will eventually be needed as we reserve a bit more memory than
    /// what will be needed.
    size_t get_commit_size() const;

    DB::version_type commit() REQUIRES(!m_async_mutex);
    void rollback() REQUIRES(!m_async_mutex);
    void end_read() REQUIRES(!m_async_mutex);

    template <class O>
    void parse_history(O& observer, DB::version_type begin, DB::version_type end);

    // Live transactions state changes, often taking an observer functor:
    VersionID commit_and_continue_as_read(bool commit_to_disk = true) REQUIRES(!m_async_mutex);
    VersionID commit_and_continue_writing();
    template <class O>
    void rollback_and_continue_as_read(O& observer) REQUIRES(!m_async_mutex);
    void rollback_and_continue_as_read() REQUIRES(!m_async_mutex);
    template <class O>
    void advance_read(O* observer, VersionID target_version = VersionID());
    void advance_read(VersionID target_version = VersionID())
    {
        _impl::NullInstructionObserver* o = nullptr;
        advance_read(o, target_version);
    }
    template <class O>
    bool promote_to_write(O* observer, bool nonblocking = false) REQUIRES(!m_async_mutex);
    bool promote_to_write(bool nonblocking = false) REQUIRES(!m_async_mutex)
    {
        _impl::NullInstructionObserver* o = nullptr;
        return promote_to_write(o, nonblocking);
    }
    TransactionRef freeze();
    // Frozen transactions are created by freeze() or DB::start_frozen()
    bool is_frozen() const noexcept override
    {
        return m_transact_stage == DB::transact_Frozen;
    }
    bool is_async() noexcept REQUIRES(!m_async_mutex)
    {
        util::CheckedLockGuard lck(m_async_mutex);
        return m_async_stage != AsyncState::Idle;
    }
    TransactionRef duplicate();

    void copy_to(TransactionRef dest) const;

    _impl::History* get_history() const;

    // direct handover of accessor instances
    Obj import_copy_of(const Obj& original);
    TableRef import_copy_of(const ConstTableRef original);
    LnkLst import_copy_of(const LnkLst& original);
    LnkSet import_copy_of(const LnkSet& original);
    LstBasePtr import_copy_of(const LstBase& original);
    SetBasePtr import_copy_of(const SetBase& original);
    CollectionBasePtr import_copy_of(const CollectionBase& original);
    LnkLstPtr import_copy_of(const LnkLstPtr& original);
    LnkSetPtr import_copy_of(const LnkSetPtr& original);
    LinkCollectionPtr import_copy_of(const LinkCollectionPtr& original);

    // handover of the heavier Query and TableView
    std::unique_ptr<Query> import_copy_of(Query&, PayloadPolicy);
    std::unique_ptr<TableView> import_copy_of(TableView&, PayloadPolicy);

    /// Get the current transaction type
    DB::TransactStage get_transact_stage() const noexcept
    {
        return m_transact_stage;
    }

    void upgrade_file_format(int target_file_format_version);

    /// Task oriented/async interface for continuous transactions.
    // true if this transaction already holds the write mutex
    bool holds_write_mutex() const noexcept REQUIRES(!m_async_mutex)
    {
        util::CheckedLockGuard lck(m_async_mutex);
        return m_async_stage == AsyncState::HasLock || m_async_stage == AsyncState::HasCommits;
    }

    // Convert an existing write transaction to an async write transaction
    void promote_to_async() REQUIRES(!m_async_mutex);

    // request full synchronization to stable storage for all writes done since
    // last sync - or just release write mutex.
    // The write mutex is released after full synchronization.
    void async_complete_writes(util::UniqueFunction<void()> when_synchronized = nullptr) REQUIRES(!m_async_mutex);

    // Complete all pending async work and return once the async stage is Idle.
    // If currently in an async write transaction that transaction is cancelled,
    // and any async writes which were committed are synchronized.
    void prepare_for_close() REQUIRES(!m_async_mutex);

    // true if sync to disk has been requested
    bool is_synchronizing() noexcept REQUIRES(!m_async_mutex)
    {
        util::CheckedLockGuard lck(m_async_mutex);
        return m_async_stage == AsyncState::Syncing;
    }

    std::exception_ptr get_commit_exception() noexcept REQUIRES(!m_async_mutex)
    {
        util::CheckedLockGuard lck(m_async_mutex);
        auto err = std::move(m_commit_exception);
        m_commit_exception = nullptr;
        return err;
    }

    bool has_unsynced_commits() noexcept REQUIRES(!m_async_mutex)
    {
        util::CheckedLockGuard lck(m_async_mutex);
        return static_cast<bool>(m_oldest_version_not_persisted);
    }

    util::Logger* get_logger() const noexcept
    {
        return db->m_logger.get();
    }

private:
    enum class AsyncState { Idle, Requesting, HasLock, HasCommits, Syncing };

    DBRef get_db() const
    {
        return db;
    }

    Replication* const* get_repl() const final
    {
        return db->get_repl();
    }

    template <class O>
    bool internal_advance_read(O* observer, VersionID target_version, _impl::History&, bool) REQUIRES(!db->m_mutex);
    void set_transact_stage(DB::TransactStage stage) noexcept;
    void do_end_read() noexcept REQUIRES(!m_async_mutex);
    void initialize_replication();

    void replicate(Transaction* dest, Replication& repl) const;
    void complete_async_commit();
    void acquire_write_lock() REQUIRES(!m_async_mutex);

    void cow_outliers(std::vector<size_t>& progress, size_t evac_limit, size_t work_limit);
    void close_read_with_lock() REQUIRES(!m_async_mutex, db->m_mutex);

    DBRef db;
    mutable std::unique_ptr<_impl::History> m_history_read;
    mutable _impl::History* m_history = nullptr;

    DB::ReadLockInfo m_read_lock;
    util::Optional<DB::ReadLockInfo> m_oldest_version_not_persisted;
    std::exception_ptr m_commit_exception GUARDED_BY(m_async_mutex);
    bool m_async_commit_has_failed = false;

    // Mutex is protecting access to members just below
    util::CheckedMutex m_async_mutex;
    std::condition_variable m_async_cv GUARDED_BY(m_async_mutex);
    AsyncState m_async_stage GUARDED_BY(m_async_mutex) = AsyncState::Idle;
    std::chrono::steady_clock::time_point m_request_time_point;
    bool m_waiting_for_write_lock GUARDED_BY(m_async_mutex) = false;
    bool m_waiting_for_sync GUARDED_BY(m_async_mutex) = false;

    DB::TransactStage m_transact_stage = DB::transact_Ready;
    unsigned m_log_id;

    friend class DB;
    friend class DisableReplication;
};

/*
 * classes providing backward Compatibility with the older
 * ReadTransaction and WriteTransaction types.
 */

class ReadTransaction {
public:
    ReadTransaction(DBRef sg)
        : trans(sg->start_read())
    {
    }

    ~ReadTransaction() noexcept {}

    operator Transaction&()
    {
        return *trans;
    }

    bool has_table(StringData name) const noexcept
    {
        return trans->has_table(name);
    }

    ConstTableRef get_table(TableKey key) const
    {
        return trans->get_table(key); // Throws
    }

    ConstTableRef get_table(StringData name) const
    {
        return trans->get_table(name); // Throws
    }

    const Group& get_group() const noexcept
    {
        return *trans.get();
    }

    /// Get the version of the snapshot to which this read transaction is bound.
    DB::version_type get_version() const noexcept
    {
        return trans->get_version();
    }

private:
    TransactionRef trans;
};


class WriteTransaction {
public:
    WriteTransaction(DBRef sg)
        : trans(sg->start_write())
    {
    }

    ~WriteTransaction() noexcept {}

    operator Transaction&()
    {
        return *trans;
    }

    bool has_table(StringData name) const noexcept
    {
        return trans->has_table(name);
    }

    TableRef get_table(TableKey key) const
    {
        return trans->get_table(key); // Throws
    }

    TableRef get_table(StringData name) const
    {
        return trans->get_table(name); // Throws
    }

    TableRef add_table(StringData name, Table::Type table_type = Table::Type::TopLevel) const
    {
        return trans->add_table(name, table_type); // Throws
    }

    TableRef get_or_add_table(StringData name, Table::Type table_type = Table::Type::TopLevel,
                              bool* was_added = nullptr) const
    {
        return trans->get_or_add_table(name, table_type, was_added); // Throws
    }

    Group& get_group() const noexcept
    {
        return *trans.get();
    }

    /// Get the version of the snapshot on which this write transaction is
    /// based.
    DB::version_type get_version() const noexcept
    {
        return trans->get_version();
    }

    DB::version_type commit()
    {
        return trans->commit();
    }

    void rollback() noexcept
    {
        trans->rollback();
    }

private:
    TransactionRef trans;
};


// Implementation:

template <class O>
inline void Transaction::advance_read(O* observer, VersionID version_id)
{
    if (m_transact_stage != DB::transact_Reading)
        throw WrongTransactionState("Not a read transaction");

    // It is an error if the new version precedes the currently bound one.
    if (version_id.version < m_read_lock.m_version)
        throw IllegalOperation("Requesting an older version when advancing");

    auto hist = get_history(); // Throws
    if (!hist)
        throw IllegalOperation("No transaction log when advancing");

    internal_advance_read(observer, version_id, *hist, false); // Throws
}

template <class O>
inline bool Transaction::promote_to_write(O* observer, bool nonblocking)
{
    if (m_transact_stage != DB::transact_Reading)
        throw WrongTransactionState("Not a read transaction");

    if (!holds_write_mutex()) {
        if (nonblocking) {
            bool succes = db->do_try_begin_write();
            if (!succes) {
                return false;
            }
        }
        else {
            auto t1 = std::chrono::steady_clock::now();
            acquire_write_lock(); // Throws
            if (db->m_logger) {
                auto t2 = std::chrono::steady_clock::now();
                db->m_logger->log(util::Logger::Level::trace, "Tr %1: Acquired write lock in %2 us", m_log_id,
                                  std::chrono::duration_cast<std::chrono::microseconds>(t2 - t1).count());
            }
        }
    }
    auto old_version = m_read_lock.m_version;
    try {
        Replication* repl = db->get_replication();
        if (!repl)
            throw IllegalOperation("No transaction log when promoting to write");

        VersionID version = VersionID(); // Latest
        m_history = repl->_get_history_write();
        bool history_updated = internal_advance_read(observer, version, *m_history, true); // Throws

        REALM_ASSERT(repl); // Presence of `repl` follows from the presence of `hist`
        DB::version_type current_version = m_read_lock.m_version;
        m_alloc.init_mapping_management(current_version);
        repl->initiate_transact(*this, current_version, history_updated); // Throws

        // If the group has no top array (top_ref == 0), create a new node
        // structure for an empty group now, to be ready for modifications. See
        // also Group::attach_shared().
        if (!m_top.is_attached())
            create_empty_group(); // Throws
    }
    catch (...) {
        if (!holds_write_mutex())
            db->end_write_on_correct_thread();
        m_history = nullptr;
        throw;
    }

    if (db->m_logger) {
        db->m_logger->log(util::Logger::Level::trace, "Tr %1: Promote to write: %2 -> %3", m_log_id, old_version,
                          m_read_lock.m_version);
    }

    set_transact_stage(DB::transact_Writing);
    return true;
}

template <class O>
inline void Transaction::rollback_and_continue_as_read(O& observer)
{
    if (m_transact_stage != DB::transact_Writing)
        throw WrongTransactionState("Not a write transaction");
    Replication* repl = db->get_replication();
    if (!repl)
        throw IllegalOperation("No transaction log when rolling back");

    BinaryData uncommitted_changes = repl->get_uncommitted_changes();
    if (uncommitted_changes.size()) {
        util::SimpleInputStream in(uncommitted_changes);
        _impl::parse_transact_log(in, observer); // Throws
    }

    rollback_and_continue_as_read();
}

inline void Transaction::rollback_and_continue_as_read()
{
    if (m_transact_stage != DB::transact_Writing)
        throw WrongTransactionState("Not a write transaction");

    Replication* repl = db->get_replication();
    if (!repl)
        throw IllegalOperation("No transaction log when rolling back");

    // Mark all managed space (beyond the attached file) as free.
    db->reset_free_space_tracking(); // Throws

    m_read_lock.check();
    ref_type top_ref = m_read_lock.m_top_ref;
    size_t file_size = m_read_lock.m_file_size;

    // since we had the write lock, we already have the latest encrypted pages in memory
    m_alloc.update_reader_view(file_size); // Throws
    update_allocator_wrappers(false);
    advance_transact(top_ref, nullptr, false); // Throws

    if (!holds_write_mutex())
        db->end_write_on_correct_thread();

    if (db->m_logger) {
        db->m_logger->log(util::Logger::Level::trace, "Tr %1, Rollback", m_log_id);
    }

    m_history = nullptr;
    set_transact_stage(DB::transact_Reading);
}

template <class O>
inline bool Transaction::internal_advance_read(O* observer, VersionID version_id, _impl::History& hist, bool writable)
{
    DB::ReadLockInfo new_read_lock = db->grab_read_lock(DB::ReadLockInfo::Live, version_id); // Throws
    REALM_ASSERT(new_read_lock.m_version >= m_read_lock.m_version);
    if (new_read_lock.m_version == m_read_lock.m_version) {
        db->release_read_lock(new_read_lock);
        // _impl::History::update_early_from_top_ref() was not called
        // update allocator wrappers merely to update write protection
        update_allocator_wrappers(writable);
        if (db->m_logger) {
            db->m_logger->log(util::Logger::Level::trace, "Tr %1: Already on version: %2", m_log_id,
                              m_read_lock.m_version);
        }
        return false;
    }

    DB::version_type old_version = m_read_lock.m_version;
    DB::ReadLockGuard g(*db, new_read_lock);
    DB::version_type new_version = new_read_lock.m_version;
    size_t new_file_size = new_read_lock.m_file_size;
    ref_type new_top_ref = new_read_lock.m_top_ref;

    // Synchronize readers view of the file
    SlabAlloc& alloc = m_alloc;
    alloc.update_reader_view(new_file_size);
    update_allocator_wrappers(writable);
    using gf = _impl::GroupFriend;
    ref_type hist_ref = gf::get_history_ref(alloc, new_top_ref);
    hist.update_from_ref_and_version(hist_ref, new_version);

    if (observer) {
        // This has to happen in the context of the originally bound snapshot
        // and while the read transaction is still in a fully functional state.
        _impl::ChangesetInputStream in(hist, old_version, new_version);
        _impl::parse_transact_log(in, *observer); // Throws
    }

    // The old read lock must be retained for as long as the change history is
    // accessed (until Group::advance_transact() returns). This ensures that the
    // oldest needed changeset remains in the history, even when the history is
    // implemented as a separate unversioned entity outside the Realm (i.e., the
    // old implementation and ShortCircuitHistory in
    // test_lang_Bind_helper.cpp). On the other hand, if it had been the case,
    // that the history was always implemented as a versioned entity, that was
    // part of the Realm state, then it would not have been necessary to retain
    // the old read lock beyond this point.
    _impl::ChangesetInputStream in(hist, old_version, new_version);
    advance_transact(new_top_ref, &in, writable); // Throws
    g.release();
    db->release_read_lock(m_read_lock);
    m_read_lock = new_read_lock;

    if (db->m_logger) {
        db->m_logger->log(util::Logger::Level::trace, "Tr %1: Advance read: %2 -> %3 ref %4", m_log_id, old_version,
                          m_read_lock.m_version, m_read_lock.m_top_ref);
    }

    return true; // _impl::History::update_early_from_top_ref() was called
}

template <class O>
void Transaction::parse_history(O& observer, DB::version_type begin, DB::version_type end)
{
    REALM_ASSERT(m_transact_stage != DB::transact_Ready);
    REALM_ASSERT(end <= m_read_lock.m_version);
    auto hist = get_history(); // Throws
    REALM_ASSERT(hist);
    hist->ensure_updated(m_read_lock.m_version);
    _impl::ChangesetInputStream in(*hist, begin, end);
    _impl::parse_transact_log(in, observer); // Throws
}

} // namespace realm

#endif /* REALM_TRANSACTION_HPP */
