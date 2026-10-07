
#ifndef REALM_SYNC_CHANGESET_ENCODER_HPP
#define REALM_SYNC_CHANGESET_ENCODER_HPP

#include <realm/sync/changeset.hpp>

namespace realm {
namespace sync {

struct ChangesetEncoder {
    using Buffer = util::AppendBuffer<char>;

    Buffer release() noexcept;
    void reset() noexcept;
    Buffer& buffer() noexcept;
    InternString intern_string(StringData);

    void set_intern_string(uint32_t index, StringBufferRange);
    // FIXME: This doesn't copy the input, but the drawback is that there can
    // only be a single StringBufferRange per instruction. Luckily, no
    // instructions exist that require two or more.
    StringBufferRange add_string_range(StringData);
    void operator()(const Instruction&);

#define REALM_DEFINE_INSTRUCTION_HANDLER(X) void operator()(const Instruction::X&);
    REALM_FOR_EACH_INSTRUCTION_TYPE(REALM_DEFINE_INSTRUCTION_HANDLER)
#undef REALM_DEFINE_INSTRUCTION_HANDLER

    void encode_single(const Changeset& log);

protected:
    template <class E>
    static void encode(E& encoder, const Instruction&);

    StringData get_string(StringBufferRange) const noexcept;

private:
    template <class... Args>
    void append(Instruction::Type t, Args&&...);
    template <class... Args>
    void append_path_instr(Instruction::Type t, const Instruction::PathInstruction&, Args&&...);
    void append_string(StringBufferRange); // does not intern the string
    void append_bytes(const void*, size_t);

    template <class T>
    void append_int(T);
    void append_value(const Instruction::PrimaryKey&);
    void append_value(const Instruction::Payload&);
    void append_value(const Instruction::Payload::Link&);
    void append_value(Instruction::Payload::Type);
    void append_value(util::Optional<Instruction::Payload::Type>);
    void append_value(Instruction::AddColumn::CollectionType);
    void append_value(const Instruction::Path&);
    void append_value(DataType);
    void append_value(bool);
    void append_value(uint8_t);
    void append_value(int64_t);
    void append_value(uint32_t);
    void append_value(uint64_t);
    void append_value(float);
    void append_value(double);
    void append_value(InternString);
    void append_value(GlobalKey);
    void append_value(Timestamp);
    void append_value(ObjectId);
    void append_value(Decimal128);
    void append_value(UUID);

    Buffer m_buffer;
    std::map<std::string, uint32_t, std::less<>> m_intern_strings_rev;
    std::string_view m_string_range;
};

// Implementation

inline auto ChangesetEncoder::buffer() noexcept -> Buffer&
{
    return m_buffer;
}

inline void ChangesetEncoder::operator()(const Instruction& instr)
{
    encode(*this, instr); // Throws
}

template <class E>
inline void ChangesetEncoder::encode(E& encoder, const Instruction& instr)
{
    instr.visit(encoder); // Throws
}

inline StringData ChangesetEncoder::get_string(StringBufferRange range) const noexcept
{
    const char* data = m_string_range.data() + range.offset;
    std::size_t size = std::size_t(range.size);
    return StringData{data, size};
}

inline void encode_changeset(const Changeset& changeset, ChangesetEncoder::Buffer& out_buffer)
{
    ChangesetEncoder encoder;
    swap(encoder.buffer(), out_buffer);
    encoder.encode_single(changeset); // Throws
    swap(encoder.buffer(), out_buffer);
}

} // namespace sync
} // namespace realm

#endif // REALM_SYNC_CHANGESET_ENCODER_HPP
