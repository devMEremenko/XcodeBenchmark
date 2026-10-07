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

#ifndef REALM_REPLICATION_HPP
#define REALM_REPLICATION_HPP

#include <algorithm>
#include <limits>
#include <memory>
#include <exception>
#include <string>

#include <realm/util/assert.hpp>
#include <realm/util/safe_int_ops.hpp>
#include <realm/util/buffer.hpp>
#include <realm/impl/cont_transact_hist.hpp>
#include <realm/impl/transact_log.hpp>

namespace realm {
namespace util {
class Logger;
}

// FIXME: Be careful about the possibility of one modification function being called by another where both do
// transaction logging.

/// Replication is enabled by passing an instance of an implementation of this
/// class to the DB constructor.
class Replication {
public:
    virtual ~Replication() = default;

    // Formerly Replication:
    virtual void add_class(TableKey table_key, StringData table_name, Table::Type table_type);
    virtual void add_class_with_primary_key(TableKey, StringData table_name, DataType pk_type, StringData pk_field,
                                            bool nullable, Table::Type table_type);
    virtual void erase_class(TableKey table_key, size_t num_tables);
    virtual void rename_class(TableKey table_key, StringData new_name);
    virtual void insert_column(const Table*, ColKey col_key, DataType type, StringData name, Table* target_table);
    virtual void erase_column(const Table*, ColKey col_key);
    virtual void rename_column(const Table*, ColKey col_key, StringData name);

    virtual void add_int(const Table*, ColKey col_key, ObjKey key, int_fast64_t value);
    virtual void set(const Table*, ColKey col_key, ObjKey key, Mixed value,
                     _impl::Instruction variant = _impl::instr_Set);

    virtual void list_set(const CollectionBase& list, size_t list_ndx, Mixed value);
    virtual void list_insert(const CollectionBase& list, size_t list_ndx, Mixed value, size_t prior_size);
    virtual void list_move(const CollectionBase&, size_t from_link_ndx, size_t to_link_ndx);
    virtual void list_erase(const CollectionBase&, size_t link_ndx);
    virtual void list_clear(const CollectionBase&);

    virtual void set_insert(const CollectionBase& set, size_t list_ndx, Mixed value);
    virtual void set_erase(const CollectionBase& set, size_t list_ndx, Mixed value);
    virtual void set_clear(const CollectionBase& set);

    virtual void dictionary_insert(const CollectionBase& dict, size_t dict_ndx, Mixed key, Mixed value);
    virtual void dictionary_set(const CollectionBase& dict, size_t dict_ndx, Mixed key, Mixed value);
    virtual void dictionary_erase(const CollectionBase& dict, size_t dict_ndx, Mixed key);

    virtual void create_object(const Table*, GlobalKey);
    virtual void create_object_with_primary_key(const Table*, ObjKey, Mixed);
    virtual void remove_object(const Table*, ObjKey);

    virtual void typed_link_change(const Table*, ColKey, TableKey);

    //@{

    /// Implicit nullifications due to removal of target row. This is redundant
    /// information from the point of view of replication, as the removal of the
    /// target row will reproduce the implicit nullifications in the target
    /// Realm anyway. The purpose of this instruction is to allow observers
    /// (reactor pattern) to be explicitly notified about the implicit
    /// nullifications.

    virtual void nullify_link(const Table*, ColKey col_key, ObjKey key);
    virtual void link_list_nullify(const Lst<ObjKey>&, size_t link_ndx);


    // Be sure to keep this type aligned with what is actually used in DB.
    using version_type = _impl::History::version_type;
    using InputStream = util::InputStream;
    class TransactLogApplier;
    class Interrupted; // Exception
    class SimpleIndexTranslator;

    std::string get_database_path() const;

    /// Called during construction of the associated DB object.
    ///
    /// \param db The associated DB object.
    virtual void initialize(DB& db);


    /// \defgroup replication_transactions
    //@{

    /// From the point of view of the Replication class, a transaction is
    /// initiated when, and only when the associated Transaction object calls
    /// initiate_transact() and the call is successful. The associated
    /// Transaction object must terminate every initiated transaction either by
    /// calling finalize_commit() or by calling abort_transact(). It may only
    /// call finalize_commit(), however, after calling prepare_commit(), and
    /// only when prepare_commit() succeeds. If prepare_commit() fails (i.e.,
    /// throws) abort_transact() must still be called.
    ///
    /// The associated Transaction object is supposed to terminate a transaction
    /// as soon as possible, and is required to terminate it before attempting
    /// to initiate a new one.
    ///
    /// initiate_transact() is called by the associated Transaction object as
    /// part of the initiation of a transaction, and at a time where the caller
    /// has acquired exclusive write access to the local Realm. The Replication
    /// implementation is allowed to perform "precursor transactions" on the
    /// local Realm at this time. During the initiated transaction, the
    /// associated DB object must inform the Replication object of all
    /// modifying operations by calling set_value() and friends.
    ///
    /// FIXME: There is currently no way for implementations to perform
    /// precursor transactions, since a regular transaction would cause a dead
    /// lock when it tries to acquire a write lock. Consider giving access to
    /// special non-locking precursor transactions via an extra argument to this
    /// function.
    ///
    /// prepare_commit() serves as the first phase of a two-phase commit. This
    /// function is called by the associated Transaction object immediately
    /// before the commit operation on the local Realm. The associated
    /// Transaction object will then, as the second phase, either call
    /// finalize_commit() or abort_transact() depending on whether the commit
    /// operation succeeded or not. The Replication implementation is allowed to
    /// modify the Realm via the associated Transaction object at this time
    /// (important to in-Realm histories).
    ///
    /// initiate_transact() and prepare_commit() are allowed to block the
    /// calling thread if, for example, they need to communicate over the
    /// network. If a calling thread is blocked in one of these functions, it
    /// must be possible to interrupt the blocking operation by having another
    /// thread call interrupt(). The contract is as follows: When interrupt() is
    /// called, then any execution of initiate_transact() or prepare_commit(),
    /// initiated before the interruption, must complete without blocking, or
    /// the execution must be aborted by throwing an Interrupted exception. If
    /// initiate_transact() or prepare_commit() throws Interrupted, it counts as
    /// a failed operation.
    ///
    /// finalize_commit() is called by the associated Transaction object
    /// immediately after a successful commit operation on the local Realm. This
    /// happens at a time where modification of the Realm is no longer possible
    /// via the associated Transaction object. In the case of in-Realm
    /// histories, the changes are automatically finalized as part of the commit
    /// operation performed by the caller prior to the invocation of
    /// finalize_commit(), so in that case, finalize_commit() might not need to
    /// do anything.
    ///
    /// abort_transact() is called by the associated Transaction object to
    /// terminate a transaction without committing. That is, any transaction
    /// that is not terminated by finalize_commit() is terminated by
    /// abort_transact(). This could be due to an explicit rollback, or due to a
    /// failed commit attempt.
    ///
    /// Note that finalize_commit() and abort_transact() are not allowed to
    /// throw.
    ///
    /// \param current_version The version of the snapshot that the current
    /// transaction is based on.
    ///
    /// \param history_updated Pass true only when the history has already been
    /// updated to reflect the currently bound snapshot, such as when
    /// _impl::History::update_early_from_top_ref() was called during the
    /// transition from a read transaction to the current write transaction.
    ///
    /// \throw Interrupted Thrown by initiate_transact() and prepare_commit() if
    /// a blocking operation was interrupted.

    void initiate_transact(Group& group, version_type current_version, bool history_updated);
    /// \param current_version The version of the snapshot that the current
    /// transaction is based on.
    /// \return prepare_commit() returns the version of the new snapshot
    /// produced by the transaction.
    version_type prepare_commit(version_type current_version);
    void finalize_commit() noexcept;

    //@}

    /// Get the list of uncommitted changes accumulated so far in the current
    /// write transaction.
    ///
    /// The callee retains ownership of the referenced memory. The ownership is
    /// not handed over to the caller.
    ///
    /// This function may be called only during a write transaction (prior to
    /// initiation of commit operation). In that case, the caller may assume that the
    /// returned memory reference stays valid for the remainder of the transaction (up
    /// until initiation of the commit operation).
    BinaryData get_uncommitted_changes() const noexcept;

    /// CAUTION: These values are stored in Realm files, so value reassignment
    /// is not allowed.
    enum HistoryType {
        /// No history available. No support for either continuous transactions
        /// or inter-client synchronization.
        hist_None = 0,

        /// Out-of-Realm history supporting continuous transactions.
        ///
        /// NOTE: This history type is no longer in use. The value needs to stay
        /// reserved in case someone tries to open an old Realm file.
        hist_OutOfRealm = 1,

        /// In-Realm history supporting continuous transactions
        /// (make_in_realm_history()).
        hist_InRealm = 2,

        /// In-Realm history supporting continuous transactions and client-side
        /// synchronization protocol (realm::sync::ClientHistory).
        hist_SyncClient = 3,

        /// In-Realm history supporting continuous transactions and server-side
        /// synchronization protocol (realm::_impl::ServerHistory).
        hist_SyncServer = 4
    };

    static const char* history_type_name(int);

    /// Returns the type of history maintained by this Replication
    /// implementation, or \ref hist_None if no history is maintained by it.
    ///
    /// This type is used to ensure that all session participants agree on
    /// history type, and that the Realm file contains a compatible type of
    /// history, at the beginning of a new session.
    ///
    /// As a special case, if there is no top array (Group::m_top) at the
    /// beginning of a new session, then the history type is still undecided and
    /// all history types (as returned by get_history_type()) are threfore
    /// allowed for the session initiator. Note that this case only arises if
    /// there was no preceding session, or if no transaction was sucessfully
    /// committed during any of the preceding sessions. As soon as a transaction
    /// is successfully committed, the Realm contains at least a top array, and
    /// from that point on, the history type is generally fixed, although still
    /// subject to certain allowed changes (as mentioned below).
    ///
    /// For the sake of backwards compatibility with older Realm files that does
    /// not store any history type, the following rule shall apply:
    ///
    ///   - If the top array of a Realm file (Group::m_top) does not contain a
    ///     history type, because it is too short, it shall be understood as
    ///     implicitly storing the type \ref hist_None.
    ///
    /// Note: In what follows, the meaning of *preceding session* is: The last
    /// preceding session that modified the Realm by sucessfully committing a
    /// new snapshot.
    ///
    /// It shall be allowed to switch to a \ref hist_InRealm history if the
    /// stored history type is \ref hist_None. This can be done simply by adding
    /// a new history to the Realm file. This is possible because histories of
    /// this type a transient in nature, and need not survive from one session
    /// to the next.
    ///
    /// On the other hand, as soon as a history of type \ref hist_InRealm is
    /// added to a Realm file, that history type is binding for all subsequent
    /// sessions. In theory, this constraint is not necessary, and a later
    /// switch to \ref hist_None would be possible because of the transient
    /// nature of it, however, because the \ref hist_InRealm history remains in
    /// the Realm file, there are practical complications, and for that reason,
    /// such switching shall not be supported.
    ///
    /// The \ref hist_SyncClient history type can only be used if the stored
    /// history type is also \ref hist_SyncClient, or when there is no top array
    /// yet. Likewise, the \ref hist_SyncServer history type can only be used if
    /// the stored history type is also \ref hist_SyncServer, or when there is
    /// no top array yet. Additionally, when the stored history type is \ref
    /// hist_SyncClient or \ref hist_SyncServer, then all subsequent sessions
    /// must have the same type. These restrictions apply because such a history
    /// needs to be maintained persistently across sessions.
    ///
    /// In general, if there is no stored history type (no top array) at the
    /// beginning of a new session, or if the stored type disagrees with what is
    /// returned by get_history_type() (which is possible due to particular
    /// allowed changes of history type), the actual history type (as returned
    /// by get_history_type()) used during that session, must be stored in the
    /// Realm during the first successfully committed transaction in that
    /// session. But note that there is still no need to expand the top array to
    /// store the history type \ref hist_None, due to the rule mentioned above.
    ///
    /// This function must return \ref hist_None when, and only when
    /// get_history() returns null.
    virtual HistoryType get_history_type() const noexcept
    {
        return HistoryType::hist_None;
    }

    /// Returns the schema version of the history maintained by this Replication
    /// implementation, or 0 if no history is maintained by it. All session
    /// participants must agree on history schema version.
    ///
    /// Must return 0 if get_history_type() returns \ref hist_None.
    virtual int get_history_schema_version() const noexcept
    {
        return 0;
    }

    /// Implementation may assume that this function is only ever called with a
    /// stored schema version that is less than what was returned by
    /// get_history_schema_version().
    virtual bool is_upgradable_history_schema(int /* stored_schema_version */) const noexcept
    {
        return false;
    }

    /// The implementation may assume that this function is only ever called if
    /// is_upgradable_history_schema() was called with the same stored schema
    /// version, and returned true. This implies that the specified stored
    /// schema version is always strictly less than what was returned by
    /// get_history_schema_version().
    virtual void upgrade_history_schema(int /* stored_schema_version */) {}

    /// Returns an object that gives access to the history of changesets
    /// used by writers. All writers can share the same object as all write
    /// transactions are serialized.
    ///
    /// This function must return null when, and only when get_history_type()
    /// returns \ref hist_None.
    virtual _impl::History* _get_history_write()
    {
        return nullptr;
    }

    /// Returns an object that gives access to the history of changesets in a
    /// way that allows for continuous transactions to work. All readers must
    /// get their own exclusive object as readers are not blocking each other.
    /// (Group::advance_transact() in particular).
    ///
    /// This function must return null when, and only when get_history_type()
    /// returns \ref hist_None.
    virtual std::unique_ptr<_impl::History> _create_history_read()
    {
        return nullptr;
    }

    void set_logger(util::Logger* logger)
    {
        m_logger = logger;
    }

    util::Logger* get_logger() const noexcept
    {
        return m_logger;
    }

protected:
    Replication() = default;


    //@{

    /// do_initiate_transact() is called by initiate_transact(), and likewise
    /// for do_prepare_commit()
    ///
    /// With respect to exception safety, the Replication implementation has two
    /// options: It can prepare to accept the accumulated changeset in
    /// do_prepapre_commit() by allocating all required resources, and delay the
    /// actual acceptance to finalize_commit(), which requires that the final
    /// acceptance can be done without any risk of failure. Alternatively, the
    /// Replication implementation can fully accept the changeset in
    /// do_prepapre_commit() (allowing for failure), and then discard that
    /// changeset during the next invocation of do_initiate_transact() if
    /// `current_version` indicates that the previous transaction failed.

    virtual void do_initiate_transact(Group& group, version_type current_version, bool history_updated);

    //@}


    // Formerly part of TrivialReplication:
    virtual version_type prepare_changeset(const char*, size_t, version_type orig_version)
    {
        return orig_version + 1;
    }
    virtual void finalize_changeset() noexcept {}

private:
    struct CollectionId {
        TableKey table_key;
        ObjKey object_key;
        ColKey col_id;

        CollectionId() = default;
        CollectionId(const CollectionBase& list)
            : table_key(list.get_table()->get_key())
            , object_key(list.get_owner_key())
            , col_id(list.get_col_key())
        {
        }
        CollectionId(TableKey t, ObjKey k, ColKey c)
            : table_key(t)
            , object_key(k)
            , col_id(c)
        {
        }
        bool operator!=(const CollectionId& other)
        {
            return object_key != other.object_key || table_key != other.table_key || col_id != other.col_id;
        }
    };

    _impl::TransactLogBufferStream m_stream;
    _impl::TransactLogEncoder m_encoder{m_stream};
    util::Logger* m_logger = nullptr;
    mutable const Table* m_selected_table = nullptr;
    mutable CollectionId m_selected_list;

    void unselect_all() noexcept;
    void select_table(const Table*); // unselects link list
    void select_collection(const CollectionBase&);

    void do_select_table(const Table*);
    void do_select_collection(const CollectionBase&);

    void do_set(const Table*, ColKey col_key, ObjKey key, _impl::Instruction variant = _impl::instr_Set);

    size_t transact_log_size();
};

class Replication::Interrupted : public std::exception {
public:
    const char* what() const noexcept override
    {
        return "Interrupted";
    }
};


// Implementation:

inline void Replication::initiate_transact(Group& group, version_type current_version, bool history_updated)
{
    if (auto hist = _get_history_write()) {
        hist->set_group(&group, history_updated);
    }
    do_initiate_transact(group, current_version, history_updated);
    unselect_all();
}

inline void Replication::finalize_commit() noexcept
{
    finalize_changeset();
}

inline BinaryData Replication::get_uncommitted_changes() const noexcept
{
    const char* data = m_stream.get_data();
    size_t size = m_encoder.write_position() - data;
    return BinaryData(data, size);
}

inline size_t Replication::transact_log_size()
{
    return m_encoder.write_position() - m_stream.get_data();
}


inline void Replication::unselect_all() noexcept
{
    m_selected_table = nullptr;
    m_selected_list = CollectionId();
}

inline void Replication::select_table(const Table* table)
{
    if (table != m_selected_table)
        do_select_table(table); // Throws
    m_selected_list = CollectionId();
}

inline void Replication::select_collection(const CollectionBase& list)
{
    if (CollectionId(list) != m_selected_list) {
        do_select_collection(list); // Throws
    }
}

inline void Replication::erase_class(TableKey table_key, size_t)
{
    unselect_all();
    m_encoder.erase_class(table_key); // Throws
}

inline void Replication::rename_class(TableKey table_key, StringData)
{
    unselect_all();
    m_encoder.rename_class(table_key); // Throws
}

inline void Replication::insert_column(const Table* t, ColKey col_key, DataType, StringData, Table*)
{
    select_table(t);                  // Throws
    m_encoder.insert_column(col_key); // Throws
}

inline void Replication::erase_column(const Table* t, ColKey col_key)
{
    select_table(t);                 // Throws
    m_encoder.erase_column(col_key); // Throws
}


inline void Replication::rename_column(const Table* t, ColKey col_key, StringData)
{
    select_table(t);                  // Throws
    m_encoder.rename_column(col_key); // Throws
}

inline void Replication::do_set(const Table* t, ColKey col_key, ObjKey key, _impl::Instruction variant)
{
    if (variant != _impl::Instruction::instr_SetDefault) {
        select_table(t);                       // Throws
        m_encoder.modify_object(col_key, key); // Throws
    }
}

inline void Replication::set(const Table* t, ColKey col_key, ObjKey key, Mixed, _impl::Instruction variant)
{
    do_set(t, col_key, key, variant); // Throws
}

inline void Replication::add_int(const Table* t, ColKey col_key, ObjKey key, int_fast64_t)
{
    do_set(t, col_key, key); // Throws
}

inline void Replication::nullify_link(const Table* t, ColKey col_key, ObjKey key)
{
    select_table(t);                       // Throws
    m_encoder.modify_object(col_key, key); // Throws
}

inline void Replication::list_set(const CollectionBase& list, size_t list_ndx, Mixed)
{
    select_collection(list);                            // Throws
    m_encoder.collection_set(list.translate_index(list_ndx)); // Throws
}

inline void Replication::list_insert(const CollectionBase& list, size_t list_ndx, Mixed, size_t)
{
    select_collection(list);                               // Throws
    m_encoder.collection_insert(list.translate_index(list_ndx)); // Throws
}

inline void Replication::set_insert(const CollectionBase& set, size_t set_ndx, Mixed)
{
    select_collection(set);        // Throws
    m_encoder.collection_insert(set_ndx); // Throws
}

inline void Replication::set_erase(const CollectionBase& set, size_t set_ndx, Mixed)
{
    select_collection(set);       // Throws
    m_encoder.collection_erase(set_ndx); // Throws
}

inline void Replication::set_clear(const CollectionBase& set)
{
    select_collection(set);          // Throws
    m_encoder.collection_clear(set.size()); // Throws
}

inline void Replication::remove_object(const Table* t, ObjKey key)
{
    select_table(t);              // Throws
    m_encoder.remove_object(key); // Throws
}

inline void Replication::list_move(const CollectionBase& list, size_t from_link_ndx, size_t to_link_ndx)
{
    select_collection(list);                                                                     // Throws
    m_encoder.collection_move(list.translate_index(from_link_ndx), list.translate_index(to_link_ndx)); // Throws
}

inline void Replication::list_erase(const CollectionBase& list, size_t link_ndx)
{
    select_collection(list);                              // Throws
    m_encoder.collection_erase(list.translate_index(link_ndx)); // Throws
}

inline void Replication::typed_link_change(const Table* source_table, ColKey col, TableKey dest_table)
{
    select_table(source_table);
    m_encoder.typed_link_change(col, dest_table);
}

} // namespace realm

#endif // REALM_REPLICATION_HPP
