/*************************************************************************
 *
 * Copyright 2017 Realm Inc.
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

#ifndef REALM_SYNC_IMPL_INSTRUCTION_REPLICATION_HPP
#define REALM_SYNC_IMPL_INSTRUCTION_REPLICATION_HPP

#include <realm/replication.hpp>
#include <realm/sync/instructions.hpp>
#include <realm/sync/changeset_encoder.hpp>

namespace realm {
namespace sync {


class SyncReplication : public Replication {
public:
    // This will be called for any instruction that mutates an object (instead of instructions that mutates
    // schema) with the class name (without the "class_" prefix) of the object being modified. If The
    // validator needs to reject the write, it should throw an exception.
    using WriteValidator = void(const Table&);

    void set_short_circuit(bool) noexcept;
    bool is_short_circuited() const noexcept;

    // reset() resets the encoder, the selected tables and the cache. It is
    // called by do_initiate_transact(), but can be called at the other times
    // as well.
    void reset();

    ChangesetEncoder& get_instruction_encoder() noexcept;
    const ChangesetEncoder& get_instruction_encoder() const noexcept;

    void add_class(TableKey tk, StringData table_name, Table::Type table_type = Table::Type::TopLevel) final;
    void add_class_with_primary_key(TableKey tk, StringData table_name, DataType pk_type, StringData pk_field,
                                    bool nullable, Table::Type table_type) final;
    void create_object(const Table*, GlobalKey) final;
    void create_object_with_primary_key(const Table*, ObjKey, Mixed) final;

    void erase_class(TableKey table_key, size_t num_tables) final;
    void rename_class(TableKey table_key, StringData new_name) final;
    void insert_column(const Table*, ColKey col_key, DataType type, StringData name, Table* target_table) final;
    void erase_column(const Table*, ColKey col_key) final;
    void rename_column(const Table*, ColKey col_key, StringData name) final;

    void add_int(const Table*, ColKey col_key, ObjKey key, int_fast64_t value) final;
    void set(const Table*, ColKey col_key, ObjKey key, Mixed value, _impl::Instruction variant) final;

    void list_set(const CollectionBase& list, size_t list_ndx, Mixed value) final;
    void list_insert(const CollectionBase& list, size_t list_ndx, Mixed value, size_t prior_size) final;
    void list_move(const CollectionBase&, size_t from_link_ndx, size_t to_link_ndx) final;
    void list_erase(const CollectionBase&, size_t link_ndx) final;
    void list_clear(const CollectionBase&) final;

    void set_insert(const CollectionBase& list, size_t list_ndx, Mixed value) final;
    void set_erase(const CollectionBase& list, size_t list_ndx, Mixed value) final;
    void set_clear(const CollectionBase& list) final;

    void dictionary_insert(const CollectionBase&, size_t ndx, Mixed key, Mixed val) final;
    void dictionary_set(const CollectionBase&, size_t ndx, Mixed key, Mixed val) final;
    void dictionary_erase(const CollectionBase&, size_t ndx, Mixed key) final;

    void remove_object(const Table*, ObjKey) final;

    //@{

    /// Implicit nullifications due to removal of target row. This is redundant
    /// information from the point of view of replication, as the removal of the
    /// target row will reproduce the implicit nullifications in the target
    /// Realm anyway. The purpose of this instruction is to allow observers
    /// (reactor pattern) to be explicitly notified about the implicit
    /// nullifications.

    void nullify_link(const Table*, ColKey col_key, ObjKey key) final;
    void link_list_nullify(const Lst<ObjKey>&, size_t link_ndx) final;
    //@}

protected:
    // Replication interface:
    void do_initiate_transact(Group& group, version_type current_version, bool history_updated) override;

    virtual util::UniqueFunction<WriteValidator> make_write_validator(Transaction&)
    {
        return {};
    }

private:
    bool m_short_circuit = false;

    ChangesetEncoder m_encoder;
    Transaction* m_transaction;

    template <class T>
    void emit(T instruction);

    // Returns true and populates m_last_table_name if instructions for the
    // table should be emitted.
    bool select_table(const Table&);

    REALM_NORETURN void unsupported_instruction() const; // Throws TransformError

    // Returns true and populates m_last_class_name if instructions for the
    // owning table should be emitted.
    bool select_collection(const CollectionBase&); // returns true if table behavior != ignored

    InternString emit_class_name(StringData table_name);
    InternString emit_class_name(const Table& table);
    Instruction::Payload::Type get_payload_type(DataType) const;

    Instruction::Payload as_payload(Mixed value);
    Instruction::Payload as_payload(const CollectionBase& collection, Mixed value);
    Instruction::Payload as_payload(const Table& table, ColKey col_key, Mixed value);

    Instruction::PrimaryKey as_primary_key(Mixed);
    Instruction::PrimaryKey primary_key_for_object(const Table&, ObjKey key);
    void populate_path_instr(Instruction::PathInstruction&, const Table&, ObjKey key, ColKey field);
    void populate_path_instr(Instruction::PathInstruction&, const CollectionBase&);
    void populate_path_instr(Instruction::PathInstruction&, const CollectionBase&, uint32_t ndx);

    void dictionary_update(const CollectionBase&, const Mixed& key, const Mixed& val);

    // Cache information for the purpose of avoiding excessive string comparisons / interning
    // lookups.
    const Table* m_last_table = nullptr;
    ObjKey m_last_object;
    ColKey m_last_field;
    InternString m_last_class_name;
    util::Optional<Instruction::PrimaryKey> m_last_primary_key;
    InternString m_last_field_name;
    util::UniqueFunction<WriteValidator> m_write_validator;
};

inline void SyncReplication::set_short_circuit(bool b) noexcept
{
    m_short_circuit = b;
}

inline bool SyncReplication::is_short_circuited() const noexcept
{
    return m_short_circuit;
}

inline ChangesetEncoder& SyncReplication::get_instruction_encoder() noexcept
{
    return m_encoder;
}

inline const ChangesetEncoder& SyncReplication::get_instruction_encoder() const noexcept
{
    return m_encoder;
}

template <class T>
inline void SyncReplication::emit(T instruction)
{
    REALM_ASSERT(!m_short_circuit);
    m_encoder(instruction);
}


// Temporarily short-circuit replication
class TempShortCircuitReplication {
public:
    TempShortCircuitReplication(SyncReplication& bridge)
        : m_bridge(bridge)
    {
        m_was_short_circuited = bridge.is_short_circuited();
        bridge.set_short_circuit(true);
    }

    ~TempShortCircuitReplication()
    {
        m_bridge.set_short_circuit(m_was_short_circuited);
    }

    bool was_short_circuited() const noexcept
    {
        return m_was_short_circuited;
    }

private:
    SyncReplication& m_bridge;
    bool m_was_short_circuited;
};

} // namespace sync
} // namespace realm

#endif // REALM_SYNC_IMPL_INSTRUCTION_REPLICATION_HPP
