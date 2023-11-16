
#ifndef REALM_IMPL_INSTRUCTIONS_HPP
#define REALM_IMPL_INSTRUCTIONS_HPP

#include <iosfwd> // string conversion, debug prints
#include <memory> // shared_ptr
#include <type_traits>
#include <unordered_map>
#include <vector>

#include <external/mpark/variant.hpp>
#include <realm/binary_data.hpp>
#include <realm/data_type.hpp>
#include <realm/string_data.hpp>
#include <realm/sync/object_id.hpp>
#include <realm/table_ref.hpp>
#include <realm/timestamp.hpp>
#include <realm/util/input_stream.hpp>
#include <realm/util/overload.hpp>

namespace realm {

namespace sync {

#define REALM_FOR_EACH_INSTRUCTION_TYPE(X)                                                                           \
    X(AddTable)                                                                                                      \
    X(EraseTable)                                                                                                    \
    X(AddColumn)                                                                                                     \
    X(EraseColumn)                                                                                                   \
    X(CreateObject)                                                                                                  \
    X(EraseObject)                                                                                                   \
    X(Update)                                                                                                        \
    X(AddInteger)                                                                                                    \
    X(ArrayInsert)                                                                                                   \
    X(ArrayMove)                                                                                                     \
    X(ArrayErase)                                                                                                    \
    X(Clear)                                                                                                         \
    X(SetInsert)                                                                                                     \
    X(SetErase)

struct StringBufferRange {
    uint32_t offset, size;

    friend bool operator==(const StringBufferRange& lhs, const StringBufferRange& rhs) noexcept
    {
        return lhs.offset == rhs.offset && lhs.size == rhs.size;
    }
};

struct InternString {
    static const InternString npos;
    explicit constexpr InternString(uint32_t v = uint32_t(-1)) noexcept
        : value(v)
    {
    }

    uint32_t value;

    constexpr bool operator==(const InternString& other) const noexcept
    {
        return value == other.value;
    }
    constexpr bool operator!=(const InternString& other) const noexcept
    {
        return value != other.value;
    }
    constexpr bool operator<(const InternString& other) const noexcept
    {
        return value < other.value;
    }

    explicit operator bool() const noexcept
    {
        return (value != npos.value);
    }
};

struct Instruction;

namespace instr {

using PrimaryKey = mpark::variant<mpark::monostate, int64_t, GlobalKey, InternString, ObjectId, UUID>;

struct Path {
    using Element = mpark::variant<InternString, uint32_t>;

    // FIXME: Use a "small_vector" type for this -- most paths are very short.
    // Alternatively, we could use some kind of interning with copy-on-write,
    // but that seems complicated.
    std::vector<Element> m_path;

    size_t size() const noexcept
    {
        return m_path.size();
    }

    // If this path is referring to an element of an array (the last path
    // element is an integer index), return true.
    bool is_array_index() const noexcept
    {
        return !m_path.empty() && mpark::holds_alternative<uint32_t>(m_path.back());
    }

    uint32_t& index() noexcept
    {
        REALM_ASSERT(is_array_index());
        return mpark::get<uint32_t>(m_path.back());
    }

    uint32_t index() const noexcept
    {
        REALM_ASSERT(is_array_index());
        return mpark::get<uint32_t>(m_path.back());
    }

    Element& back() noexcept
    {
        REALM_ASSERT(!m_path.empty());
        return m_path.back();
    }

    const Element& back() const noexcept
    {
        REALM_ASSERT(!m_path.empty());
        return m_path.back();
    }

    Element& operator[](size_t idx) noexcept
    {
        REALM_ASSERT(idx < m_path.size());
        return m_path[idx];
    }

    const Element& operator[](size_t idx) const noexcept
    {
        REALM_ASSERT(idx < m_path.size());
        return m_path[idx];
    }

    void push_back(Element element)
    {
        m_path.push_back(element);
    }

    friend bool operator==(const Path& lhs, const Path& rhs) noexcept
    {
        return lhs.m_path == rhs.m_path;
    }

    using const_iterator = typename std::vector<Element>::const_iterator;
    const_iterator begin() const noexcept
    {
        return m_path.begin();
    }
    const_iterator end() const noexcept
    {
        return m_path.end();
    }
};

struct Payload {
    /// Create a new object in-place (embedded object).
    struct ObjectValue {
    };
    /// Create an empty dictionary in-place (does not clear an existing dictionary).
    struct Dictionary {
    };
    /// Sentinel value for an erased dictionary element.
    struct Erased {
    };

    /// Payload data types, corresponding loosely to the `DataType` enum in
    /// Core, but with some special values:
    ///
    /// - Null (0) indicates a NULL value of any type.
    /// - GlobalKey (-1) indicates an internally generated object ID.
    /// - ObjectValue (-2) indicates the creation of an embedded object.
    /// - Dictionary (-3) indicates the creation of a dictionary.
    /// - Erased (-4) indicates that a dictionary element should be erased.
    /// - Undefined (-5) indicates the
    ///
    /// Furthermore, link values for both Link and LinkList columns are
    /// represented by a single Link type.
    ///
    /// Note: For Mixed columns (including typed links), no separate value is required, because the
    /// instruction set encodes the type of each value in the instruction.
    enum class Type : int8_t {
        // Special value indicating that a dictionary element should be erased.
        Erased = -4,

        // Special value indicating that a dictionary should be created at the position.
        Dictionary = -3,

        // Special value indicating that an embedded object should be created at
        // the position.
        ObjectValue = -2,
        GlobalKey = -1,
        Null = 0,
        Int = 1,
        Bool = 2,
        String = 3,
        Binary = 4,
        Timestamp = 5,
        Float = 6,
        Double = 7,
        Decimal = 8,
        Link = 9,
        ObjectId = 10,
        UUID = 11,
    };

    struct Link {
        InternString target_table;
        PrimaryKey target;

        friend bool operator==(const Link& lhs, const Link& rhs) noexcept
        {
            return lhs.target_table == rhs.target_table && lhs.target == rhs.target;
        }
    };

    union Data {
        GlobalKey key;
        int64_t integer;
        bool boolean;
        StringBufferRange str;
        StringBufferRange binary;
        Timestamp timestamp;
        float fnum;
        double dnum;
        Decimal128 decimal;
        ObjectId object_id;
        UUID uuid;
        Link link;
        ObjLink typed_link;

        Data() {}
    };

    Data data;
    Type type;

    Payload()
        : Payload(realm::util::none)
    {
    }
    explicit Payload(bool value) noexcept
        : type(Type::Bool)
    {
        data.boolean = value;
    }
    explicit Payload(int64_t value) noexcept
        : type(Type::Int)
    {
        data.integer = value;
    }
    explicit Payload(float value) noexcept
        : type(Type::Float)
    {
        data.fnum = value;
    }
    explicit Payload(double value) noexcept
        : type(Type::Double)
    {
        data.dnum = value;
    }
    explicit Payload(Link value) noexcept
        : type(Type::Link)
    {
        data.link = value;
    }
    explicit Payload(StringBufferRange value, bool is_binary = false) noexcept
        : type(is_binary ? Type::Binary : Type::String)
    {
        if (is_binary) {
            data.binary = value;
        }
        else {
            data.str = value;
        }
    }
    explicit Payload(realm::util::None) noexcept
        : type(Type::Null)
    {
    }

    // Note: Intentionally implicit.
    Payload(const ObjectValue&) noexcept
        : type(Type::ObjectValue)
    {
    }

    // Note: Intentionally implicit.
    Payload(const Erased&) noexcept
        : type(Type::Erased)
    {
    }

    explicit Payload(Timestamp value) noexcept
        : type(value.is_null() ? Type::Null : Type::Timestamp)
    {
        if (value.is_null()) {
            type = Type::Null;
        }
        else {
            type = Type::Timestamp;
            data.timestamp = value;
        }
    }

    explicit Payload(ObjectId value) noexcept
        : type(Type::ObjectId)
    {
        data.object_id = value;
    }

    explicit Payload(Decimal128 value) noexcept
    {
        if (value.is_null()) {
            type = Type::Null;
        }
        else {
            type = Type::Decimal;
            data.decimal = value;
        }
    }

    explicit Payload(UUID value) noexcept
        : type(Type::UUID)
    {
        data.uuid = value;
    }

    Payload(const Payload&) noexcept = default;
    Payload& operator=(const Payload&) noexcept = default;

    bool is_null() const noexcept
    {
        return type == Type::Null;
    }

    friend bool operator==(const Payload& lhs, const Payload& rhs) noexcept
    {
        if (lhs.type == rhs.type) {
            switch (lhs.type) {
                case Type::Erased:
                    return true;
                case Type::Dictionary:
                    return true;
                case Type::ObjectValue:
                    return true;
                case Type::GlobalKey:
                    return lhs.data.key == rhs.data.key;
                case Type::Null:
                    return true;
                case Type::Int:
                    return lhs.data.integer == rhs.data.integer;
                case Type::Bool:
                    return lhs.data.boolean == rhs.data.boolean;
                case Type::String:
                    return lhs.data.str == rhs.data.str;
                case Type::Binary:
                    return lhs.data.binary == rhs.data.binary;
                case Type::Timestamp:
                    return lhs.data.timestamp == rhs.data.timestamp;
                case Type::Float:
                    return lhs.data.fnum == rhs.data.fnum;
                case Type::Double:
                    return lhs.data.dnum == rhs.data.dnum;
                case Type::Decimal:
                    return lhs.data.decimal == rhs.data.decimal;
                case Type::Link:
                    return lhs.data.link == rhs.data.link;
                case Type::ObjectId:
                    return lhs.data.object_id == rhs.data.object_id;
                case Type::UUID:
                    return lhs.data.uuid == rhs.data.uuid;
            }
        }
        return false;
    }

    friend bool operator!=(const Payload& lhs, const Payload& rhs) noexcept
    {
        return !(lhs == rhs);
    }
};

/// All instructions are TableInstructions.
struct TableInstruction {
    InternString table;

protected:
    bool operator==(const TableInstruction& rhs) const noexcept
    {
        return table == rhs.table;
    }
};

/// All instructions except schema instructions are ObjectInstructions.
struct ObjectInstruction : TableInstruction {
    PrimaryKey object;

protected:
    bool operator==(const ObjectInstruction& rhs) const noexcept
    {
        return TableInstruction::operator==(rhs) && object == rhs.object;
    }
};

/// All instructions except schema instructions and CreateObject/EraseObject are PathInstructions.
struct PathInstruction : ObjectInstruction {
    InternString field;
    Path path;

    uint32_t& index() noexcept
    {
        return path.index();
    }

    uint32_t index() const noexcept
    {
        return path.index();
    }

protected:
    bool operator==(const PathInstruction& rhs) const noexcept
    {
        return ObjectInstruction::operator==(rhs) && field == rhs.field && path == rhs.path;
    }
};

struct AddTable : TableInstruction {
    // Note: Tables "without" a primary key have a secret primary key of type
    // ObjKey. The field name of such primary keys is assumed to be "_id".
    struct TopLevelTable {
        InternString pk_field;
        Payload::Type pk_type;
        bool pk_nullable;
        bool is_asymmetric;

        bool operator==(const TopLevelTable& rhs) const noexcept
        {
            return pk_field == rhs.pk_field && pk_type == rhs.pk_type && pk_nullable == rhs.pk_nullable &&
                   is_asymmetric == rhs.is_asymmetric;
        }
    };

    struct EmbeddedTable {
        bool operator==(const EmbeddedTable&) const noexcept
        {
            return true;
        }
    };

    mpark::variant<TopLevelTable, EmbeddedTable> type;

    bool operator==(const AddTable& rhs) const noexcept
    {
        return TableInstruction::operator==(rhs) && type == rhs.type;
    }
};

struct EraseTable : TableInstruction {
    using TableInstruction::TableInstruction;

    bool operator==(const EraseTable& rhs) const noexcept
    {
        return TableInstruction::operator==(rhs);
    }
};

struct AddColumn : TableInstruction {
    using TableInstruction::TableInstruction;

    // This is backwards compatible with previous boolean type where 0
    // indicated simple type and 1 indicated list.
    enum class CollectionType : uint8_t { Single, List, Dictionary, Set };

    InternString field;

    // `Type::Null` for Mixed columns. Mixed columns are always nullable.
    Payload::Type type;
    // `Type::Null` for other than dictionary columns
    Payload::Type key_type;

    bool nullable;

    // For Mixed columns, this is `none`. Mixed columns are always nullable.
    //
    // For dictionaries, this must always be `Type::String`.
    CollectionType collection_type;

    InternString link_target_table;

    bool operator==(const AddColumn& rhs) const noexcept
    {
        return TableInstruction::operator==(rhs) && field == rhs.field && type == rhs.type &&
               key_type == rhs.key_type && nullable == rhs.nullable && collection_type == rhs.collection_type &&
               link_target_table == rhs.link_target_table;
    }
};

struct EraseColumn : TableInstruction {
    using TableInstruction::TableInstruction;
    InternString field;

    bool operator==(const EraseColumn& rhs) const noexcept
    {
        return TableInstruction::operator==(rhs) && field == rhs.field;
    }
};

struct CreateObject : ObjectInstruction {
    using ObjectInstruction::ObjectInstruction;

    bool operator==(const CreateObject& rhs) const noexcept
    {
        return ObjectInstruction::operator==(rhs);
    }
};

struct EraseObject : ObjectInstruction {
    using ObjectInstruction::ObjectInstruction;

    bool operator==(const EraseObject& rhs) const noexcept
    {
        return ObjectInstruction::operator==(rhs);
    }
};

struct Update : PathInstruction {
    using PathInstruction::PathInstruction;

    // Note: For "ArrayUpdate", the path ends with an integer.
    Payload value;
    union {
        bool is_default;     // For fields
        uint32_t prior_size; // For "ArrayUpdate"
    };

    Update()
        : prior_size(0)
    {
    }

    bool is_array_update() const noexcept
    {
        return path.is_array_index();
    }

    bool operator==(const Update& rhs) const noexcept
    {
        return PathInstruction::operator==(rhs) && value == rhs.value &&
               (is_array_update() ? prior_size == rhs.prior_size : is_default == rhs.is_default);
    }
};

struct AddInteger : PathInstruction {
    using PathInstruction::PathInstruction;
    int64_t value;

    bool operator==(const AddInteger& rhs) const noexcept
    {
        return PathInstruction::operator==(rhs) && value == rhs.value;
    }
};

struct ArrayInsert : PathInstruction {
    // Note: The insertion index is the last path component.
    using PathInstruction::PathInstruction;
    Payload value;
    uint32_t prior_size;

    bool operator==(const ArrayInsert& rhs) const noexcept
    {
        return PathInstruction::operator==(rhs) && value == rhs.value && prior_size == rhs.prior_size;
    }
};

struct ArrayMove : PathInstruction {
    // Note: The move-from index is the last path component.
    using PathInstruction::PathInstruction;
    uint32_t ndx_2;
    uint32_t prior_size;

    bool operator==(const ArrayMove& rhs) const noexcept
    {
        return PathInstruction::operator==(rhs) && ndx_2 == rhs.ndx_2 && prior_size == rhs.prior_size;
    }
};

struct ArrayErase : PathInstruction {
    // Note: The erased index is the last path component.
    using PathInstruction::PathInstruction;
    uint32_t prior_size;

    bool operator==(const ArrayErase& rhs) const noexcept
    {
        return PathInstruction::operator==(rhs) && prior_size == rhs.prior_size;
    }
};

struct Clear : PathInstruction {
    using PathInstruction::PathInstruction;

    bool operator==(const Clear& rhs) const noexcept
    {
        return PathInstruction::operator==(rhs);
    }
};

struct SetInsert : PathInstruction {
    using PathInstruction::PathInstruction;
    Payload value;

    bool operator==(const SetInsert& rhs) const noexcept
    {
        return PathInstruction::operator==(rhs) && value == rhs.value;
    }
};

struct SetErase : PathInstruction {
    using PathInstruction::PathInstruction;
    Payload value;

    bool operator==(const SetErase& rhs) const noexcept
    {
        return PathInstruction::operator==(rhs) && value == rhs.value;
    }
};


} // namespace instr

struct Instruction {
#define REALM_DECLARE_INSTRUCTION_STRUCT(X) using X = instr::X;
    REALM_FOR_EACH_INSTRUCTION_TYPE(REALM_DECLARE_INSTRUCTION_STRUCT)
#undef REALM_DECLARE_INSTRUCTION_STRUCT

    using TableInstruction = instr::TableInstruction;
    using ObjectInstruction = instr::ObjectInstruction;
    using PathInstruction = instr::PathInstruction;
    using PrimaryKey = instr::PrimaryKey;
    using Payload = instr::Payload;
    using Path = instr::Path;
    using Vector = std::vector<Instruction>;

    // CAUTION: Any change to the enum values for the instruction types is a protocol-breaking
    // change!
    enum class Type : uint8_t {
        AddTable = 0,
        EraseTable = 1,
        CreateObject = 2,
        EraseObject = 3,
        Update = 4, // Note: Also covers ArrayUpdate
        AddInteger = 5,
        AddColumn = 6,
        EraseColumn = 7,
        ArrayInsert = 8,
        ArrayMove = 9,
        ArrayErase = 10,
        Clear = 11,
        SetInsert = 12,
        SetErase = 13,
    };

    template <Type t>
    struct GetType;
    template <class T>
    struct GetInstructionType;

    template <class T>
    Instruction(T instr);

    mpark::variant<Vector
#define REALM_INSTRUCTION_VARIANT_ALTERNATIVE(X) , X
                       REALM_FOR_EACH_INSTRUCTION_TYPE(REALM_INSTRUCTION_VARIANT_ALTERNATIVE)
#undef REALM_INSTRUCTION_VARIANT_ALTERNATIVE
                   >
        m_instr;

    Type type() const noexcept;

    template <class F>
    decltype(auto) visit(F&& lambda);
    template <class F>
    decltype(auto) visit(F&& lambda) const;

    template <class T>
    T* get_if() noexcept;

    template <class T>
    const T* get_if() const noexcept
    {
        return const_cast<Instruction&>(*this).get_if<T>();
    }

    template <class T>
    T& get_as()
    {
        auto ptr = get_if<T>();
        REALM_ASSERT(ptr);
        return *ptr;
    }

    template <class T>
    const T& get_as() const
    {
        auto ptr = get_if<T>();
        REALM_ASSERT(ptr);
        return *ptr;
    }

    bool operator==(const Instruction& other) const noexcept;
    bool operator!=(const Instruction& other) const noexcept
    {
        return !(*this == other);
    }

    bool is_vector() const noexcept
    {
        return mpark::holds_alternative<Vector>(m_instr);
    }

    size_t path_length() const noexcept;

    Vector& convert_to_vector();
    void insert(size_t pos, Instruction instr);
    void erase(size_t pos);
    size_t size() const noexcept;
    bool is_empty() const noexcept;
    Instruction& at(size_t) noexcept;
    const Instruction& at(size_t) const noexcept;

private:
    template <class>
    struct Visitor;
};

inline const char* get_type_name(Instruction::Type type)
{
    switch (type) {
#define REALM_INSTRUCTION_TYPE_TO_STRING(X)                                                                          \
    case Instruction::Type::X:                                                                                       \
        return #X;
        REALM_FOR_EACH_INSTRUCTION_TYPE(REALM_INSTRUCTION_TYPE_TO_STRING)
#undef REALM_INSTRUCTION_TYPE_TO_STRING
    }
    return "(invalid)";
}

inline std::ostream& operator<<(std::ostream& os, Instruction::Type type)
{
    return os << get_type_name(type);
}

inline const char* get_type_name(Instruction::Payload::Type type)
{
    using Type = Instruction::Payload::Type;
    switch (type) {
        case Type::Erased:
            return "Erased";
        case Type::Dictionary:
            return "Dictionary";
        case Type::ObjectValue:
            return "ObjectValue";
        case Type::GlobalKey:
            return "GlobalKey";
        case Type::Null:
            return "Null";
        case Type::Int:
            return "Int";
        case Type::Bool:
            return "Bool";
        case Type::String:
            return "String";
        case Type::Binary:
            return "Binary";
        case Type::Timestamp:
            return "Timestamp";
        case Type::Float:
            return "Float";
        case Type::Double:
            return "Double";
        case Type::Decimal:
            return "Decimal";
        case Type::Link:
            return "Link";
        case Type::ObjectId:
            return "ObjectId";
        case Type::UUID:
            return "UUID";
    }
    return "(unknown)";
}

inline const char* get_collection_type(Instruction::AddColumn::CollectionType type)
{
    using Type = Instruction::AddColumn::CollectionType;
    switch (type) {
        case Type::Single:
            return "Single";
        case Type::List:
            return "List";
        case Type::Dictionary:
            return "Dictionary";
        case Type::Set:
            return "Set";
    }
    return "(unknown)";
}

inline const char* get_type_name(util::Optional<Instruction::Payload::Type> type)
{
    if (type) {
        return get_type_name(*type);
    }
    else {
        return "Mixed";
    }
}

inline std::ostream& operator<<(std::ostream& os, Instruction::Payload::Type type)
{
    return os << get_type_name(type);
}

inline bool is_valid_key_type(Instruction::Payload::Type type) noexcept
{
    using Type = Instruction::Payload::Type;
    switch (type) {
        case Type::Int:
            [[fallthrough]];
        case Type::String:
            [[fallthrough]];
        case Type::ObjectId:
            [[fallthrough]];
        case Type::UUID:
            [[fallthrough]];
        case Type::GlobalKey:
            return true;
        case Type::Null: // Mixed is not a valid primary key
            [[fallthrough]];
        default:
            return false;
    }
}

inline DataType get_data_type(Instruction::Payload::Type type) noexcept
{
    using Type = Instruction::Payload::Type;
    switch (type) {
        case Type::Int:
            return type_Int;
        case Type::Bool:
            return type_Bool;
        case Type::String:
            return type_String;
        case Type::Binary:
            return type_Binary;
        case Type::Timestamp:
            return type_Timestamp;
        case Type::Float:
            return type_Float;
        case Type::Double:
            return type_Double;
        case Type::Decimal:
            return type_Decimal;
        case Type::Link:
            return type_Link;
        case Type::ObjectId:
            return type_ObjectId;
        case Type::UUID:
            return type_UUID;
        case Type::Null: // Mixed is encoded as null
            return type_Mixed;
        case Type::Erased:
            [[fallthrough]];
        case Type::Dictionary:
            [[fallthrough]];
        case Type::ObjectValue:
            [[fallthrough]];
        case Type::GlobalKey:
            REALM_TERMINATE(util::format("Invalid data type: %1", int8_t(type)).c_str());
    }
    return type_Int; // Make compiler happy
}

// 0x3f is the largest value that fits in a single byte in the variable-length
// encoded integer instruction format.
static constexpr uint8_t InstrTypeInternString = 0x3f;

// This instruction code is only ever used internally by the Changeset class
// to allow insertion/removal while keeping iterators stable. Should never
// make it onto the wire.
static constexpr uint8_t InstrTypeMultiInstruction = 0xff;

struct InstructionHandler {
    /// Notify the handler that an InternString meta-instruction was found.
    virtual void set_intern_string(uint32_t index, StringBufferRange) = 0;

    /// Notify the handler of the string value. The handler guarantees that the
    /// returned string range is valid at least until the next invocation of
    /// add_string_range().
    ///
    /// Instances of `StringBufferRange` passed to operator() after invoking
    /// this function are assumed to refer to ranges in this buffer.
    virtual StringBufferRange add_string_range(StringData) = 0;

    /// Handle an instruction.
    virtual void operator()(const Instruction&) = 0;
};


/// Implementation:

#define REALM_DEFINE_INSTRUCTION_GET_TYPE(X)                                                                         \
    template <>                                                                                                      \
    struct Instruction::GetType<Instruction::Type::X> {                                                              \
        using Type = Instruction::X;                                                                                 \
    };                                                                                                               \
    template <>                                                                                                      \
    struct Instruction::GetInstructionType<Instruction::X> {                                                         \
        static const Instruction::Type value = Instruction::Type::X;                                                 \
    };
REALM_FOR_EACH_INSTRUCTION_TYPE(REALM_DEFINE_INSTRUCTION_GET_TYPE)
#undef REALM_DEFINE_INSTRUCTION_GET_TYPE

template <class T>
Instruction::Instruction(T instr)
    : m_instr(std::move(instr))
{
    static_assert(!std::is_same_v<T, Vector>);
}

template <class F>
struct Instruction::Visitor {
    F lambda; // reference type
    Visitor(F lambda)
        : lambda(lambda)
    {
    }

    template <class T>
    decltype(auto) operator()(T& instr)
    {
        return lambda(instr);
    }

    template <class T>
    decltype(auto) operator()(const T& instr)
    {
        return lambda(instr);
    }

    auto operator()(const Instruction::Vector&) -> decltype(lambda(std::declval<const Instruction::Update&>()))
    {
        REALM_TERMINATE("visiting instruction vector");
    }
    auto operator()(Instruction::Vector&) -> decltype(lambda(std::declval<Instruction::Update&>()))
    {
        REALM_TERMINATE("visiting instruction vector");
    }
};

template <class F>
inline decltype(auto) Instruction::visit(F&& lambda)
{
    // Cannot use std::visit, because it does not pass lvalue references to the visitor.
    if (mpark::holds_alternative<Vector>(m_instr)) {
        REALM_TERMINATE("visiting instruction vector");
    }
#define REALM_VISIT_VARIANT(X)                                                                                       \
    else if (mpark::holds_alternative<Instruction::X>(m_instr))                                                      \
    {                                                                                                                \
        return lambda(mpark::get<Instruction::X>(m_instr));                                                          \
    }
    REALM_FOR_EACH_INSTRUCTION_TYPE(REALM_VISIT_VARIANT)
#undef REALM_VISIT_VARIANT
    else
    {
        REALM_TERMINATE("Unhandled instruction variant entry");
    }
}

template <class F>
inline decltype(auto) Instruction::visit(F&& lambda) const
{
    // Cannot use std::visit, because it does not pass lvalue references to the visitor.
    if (mpark::holds_alternative<Vector>(m_instr)) {
        REALM_TERMINATE("visiting instruction vector");
    }
#define REALM_VISIT_VARIANT(X)                                                                                       \
    else if (mpark::holds_alternative<Instruction::X>(m_instr))                                                      \
    {                                                                                                                \
        return lambda(mpark::get<Instruction::X>(m_instr));                                                          \
    }
    REALM_FOR_EACH_INSTRUCTION_TYPE(REALM_VISIT_VARIANT)
#undef REALM_VISIT_VARIANT
    else
    {
        REALM_TERMINATE("Unhandled instruction variant entry");
    }
}

inline Instruction::Type Instruction::type() const noexcept
{
    return visit([](auto&& instr) {
        using T = std::remove_cv_t<std::remove_reference_t<decltype(instr)>>;
        return GetInstructionType<T>::value;
    });
}

inline bool Instruction::operator==(const Instruction& other) const noexcept
{
    return m_instr == other.m_instr;
}

template <class T>
REALM_NOINLINE T* Instruction::get_if() noexcept
{
    // FIXME: Is there a way to express this without giant switch statements? Note: Putting the
    // base class into a union does not seem to be allowed by the standard.
    if constexpr (std::is_same_v<TableInstruction, T>) {
        // This should compile to nothing but a comparison of the type.
        return visit([](auto& instr) -> TableInstruction* {
            return &instr;
        });
    }
    else if constexpr (std::is_same_v<ObjectInstruction, T>) {
        // This should compile to nothing but a comparison of the type.
        return visit(util::overload{
            [](AddTable&) -> ObjectInstruction* {
                return nullptr;
            },
            [](EraseTable&) -> ObjectInstruction* {
                return nullptr;
            },
            [](AddColumn&) -> ObjectInstruction* {
                return nullptr;
            },
            [](EraseColumn&) -> ObjectInstruction* {
                return nullptr;
            },
            [](auto& instr) -> ObjectInstruction* {
                return &instr;
            },
        });
    }
    else if constexpr (std::is_same_v<PathInstruction, T>) {
        // This should compile to nothing but a comparison of the type.
        return visit(util::overload{
            [](AddTable&) -> PathInstruction* {
                return nullptr;
            },
            [](EraseTable&) -> PathInstruction* {
                return nullptr;
            },
            [](AddColumn&) -> PathInstruction* {
                return nullptr;
            },
            [](EraseColumn&) -> PathInstruction* {
                return nullptr;
            },
            [](CreateObject&) -> PathInstruction* {
                return nullptr;
            },
            [](EraseObject&) -> PathInstruction* {
                return nullptr;
            },
            [](auto& instr) -> PathInstruction* {
                return &instr;
            },
        });
    }
    else {
        return mpark::get_if<T>(&m_instr);
    }
}

inline size_t Instruction::size() const noexcept
{
    if (auto vec = mpark::get_if<Vector>(&m_instr)) {
        return vec->size();
    }
    return 1;
}

inline bool Instruction::is_empty() const noexcept
{
    return size() == 0;
}

inline Instruction& Instruction::at(size_t idx) noexcept
{
    if (auto vec = mpark::get_if<Vector>(&m_instr)) {
        REALM_ASSERT(idx < vec->size());
        return (*vec)[idx];
    }
    REALM_ASSERT(idx == 0);
    return *this;
}

inline const Instruction& Instruction::at(size_t idx) const noexcept
{
    if (auto vec = mpark::get_if<Vector>(&m_instr)) {
        REALM_ASSERT(idx < vec->size());
        return (*vec)[idx];
    }
    REALM_ASSERT(idx == 0);
    return *this;
}

inline size_t Instruction::path_length() const noexcept
{
    // Find the path length of the instruction. This affects how OT decides
    // which instructions are potentially nesting.
    //
    // AddTable/EraseTable:   Length 1
    // AddColumn/EraseColumn: Length 2 (table, field)
    // Object instructions:   Length 2 (table, object)
    // Path instructions:     Length 3 + m_path.size (table, object, field, path...)
    if (auto path_instr = get_if<Instruction::PathInstruction>()) {
        return 3 + path_instr->path.size();
    }
    if (get_if<Instruction::ObjectInstruction>()) {
        return 2;
    }
    switch (type()) {
        case Instruction::Type::AddColumn:
            [[fallthrough]];
        case Instruction::Type::EraseColumn: {
            return 2;
        }
        case Instruction::Type::AddTable:
            [[fallthrough]];
        case Instruction::Type::EraseTable: {
            return 1;
        }
        default:
            REALM_TERMINATE("Unhandled instruction type in Instruction::path_len()");
    }
}

inline Instruction::Vector& Instruction::convert_to_vector()
{
    if (auto v = mpark::get_if<Vector>(&m_instr)) {
        return *v;
    }
    else {
        Vector vec;
        vec.emplace_back(std::move(*this));
        m_instr = std::move(vec);
        return mpark::get<Vector>(m_instr);
    }
}

inline void Instruction::insert(size_t idx, Instruction instr)
{
    auto& vec = convert_to_vector();
    REALM_ASSERT(idx <= vec.size());
    vec.emplace(vec.begin() + idx, std::move(instr));
}

inline void Instruction::erase(size_t idx)
{
    auto& vec = convert_to_vector();
    REALM_ASSERT(idx < vec.size());
    vec.erase(vec.begin() + idx);
}

} // namespace sync
} // namespace realm

#endif // REALM_IMPL_INSTRUCTIONS_HPP
