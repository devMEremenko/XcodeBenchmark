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

#ifndef REALM_MIXED_HPP
#define REALM_MIXED_HPP

#include <cstdint> // int64_t - not part of C++03, not even required by C++11 (see C++11 section 18.4.1)

#include <cstddef> // size_t
#include <cstring>

#include <realm/keys.hpp>
#include <realm/binary_data.hpp>
#include <realm/data_type.hpp>
#if REALM_ENABLE_GEOSPATIAL
#include <realm/geospatial.hpp>
#endif
#include <realm/string_data.hpp>
#include <realm/timestamp.hpp>
#include <realm/decimal128.hpp>
#include <realm/object_id.hpp>
#include <realm/uuid.hpp>
#include <realm/util/assert.hpp>
#include <realm/utilities.hpp>

namespace realm {


/// This class represents a polymorphic Realm value.
///
/// At any particular moment an instance of this class stores a
/// definite value of a definite type. If, for instance, that is an
/// integer value, you may call get<int64_t>() to extract that value. You
/// may call get_type() to discover what type of value is currently
/// stored. Calling get<int64_t>() on an instance that does not store an
/// integer, has undefined behavior, and likewise for all the other
/// types that can be stored.
///
/// It is crucial to understand that the act of extracting a value of
/// a particular type requires definite knowledge about the stored
/// type. Calling a getter method for any particular type, that is not
/// the same type as the stored value, has undefined behavior.
///
/// While values of numeric types are contained directly in a Mixed
/// instance, character and binary data are merely referenced. A Mixed
/// instance never owns the referenced data, nor does it in any other
/// way attempt to manage its lifetime.
///
/// For compatibility with C style strings, when a string (character
/// data) is stored in a Realm database, it is always followed by a
/// terminating null character. This is also true when strings are
/// stored in a mixed type column. This means that in the following
/// code, if the 'mixed' value of the 8th row stores a string, then \c
/// c_str will always point to a null-terminated string:
///
/// \code{.cpp}
///
///   const char* c_str = my_table[7].mixed.data(); // Always null-terminated
///
/// \endcode
///
/// Note that this assumption does not hold in general for strings in
/// instances of Mixed. Indeed there is nothing stopping you from
/// constructing a new Mixed instance that refers to a string without
/// a terminating null character.
///
/// At the present time no soultion has been found that would allow
/// for a Mixed instance to directly store a reference to a table. The
/// problem is roughly as follows: From most points of view, the
/// desirable thing to do, would be to store the table reference in a
/// Mixed instance as a plain pointer without any ownership
/// semantics. This would have no negative impact on the performance
/// of copying and destroying Mixed instances, and it would serve just
/// fine for passing a table as argument when setting the value of an
/// entry in a mixed column. In that case a copy of the referenced
/// table would be inserted into the mixed column.
///
/// On the other hand, when retrieving a table reference from a mixed
/// column, storing it as a plain pointer in a Mixed instance is no
/// longer an acceptable option. The complex rules for managing the
/// lifetime of a Table instance, that represents a subtable,
/// necessitates the use of a "smart pointer" such as
/// TableRef. Enhancing the Mixed class to be able to act as a
/// TableRef would be possible, but would also lead to several new
/// problems. One problem is the risk of a Mixed instance outliving a
/// stack allocated Table instance that it references. This would be a
/// fatal error. Another problem is the impact that the nontrivial
/// table reference has on the performance of copying and destroying
/// Mixed instances.
///
/// \sa StringData
class Mixed {
public:
    Mixed() noexcept
        : m_type(0)
    {
    }

    Mixed(util::None) noexcept
        : Mixed()
    {
    }

    Mixed(realm::null) noexcept
        : Mixed()
    {
    }

    Mixed(int i) noexcept
        : Mixed(int64_t(i))
    {
    }

    Mixed(int64_t) noexcept;
    Mixed(bool) noexcept;
    explicit Mixed(std::vector<bool>::reference b) noexcept
        : Mixed(bool(b))
    {
    }
    Mixed(float) noexcept;
    Mixed(double) noexcept;
    Mixed(util::Optional<int64_t>) noexcept;
    Mixed(util::Optional<bool>) noexcept;
    Mixed(util::Optional<float>) noexcept;
    Mixed(util::Optional<double>) noexcept;
    Mixed(StringData) noexcept;
    Mixed(BinaryData) noexcept;
    Mixed(Timestamp) noexcept;
    Mixed(Decimal128);
    Mixed(ObjectId) noexcept;
    Mixed(util::Optional<ObjectId>) noexcept;
    Mixed(ObjKey) noexcept;
    Mixed(ObjLink) noexcept;
    Mixed(UUID) noexcept;
    Mixed(util::Optional<UUID>) noexcept;
    Mixed(const Obj&) noexcept;
#if REALM_ENABLE_GEOSPATIAL
    Mixed(Geospatial*) noexcept;
#endif

    // These are shortcuts for Mixed(StringData(c_str)), and are
    // needed to avoid unwanted implicit conversion of char* to bool.
    Mixed(char* c_str) noexcept
        : Mixed(StringData(c_str))
    {
    }
    Mixed(const char* c_str) noexcept
        : Mixed(StringData(c_str))
    {
    }
    Mixed(const std::string& s) noexcept
        : Mixed(StringData(s))
    {
    }

    DataType get_type() const noexcept
    {
        REALM_ASSERT(m_type);
        return DataType(m_type - 1);
    }

    template <class... Tail>
    bool is_type(DataType head, Tail... tail) const noexcept
    {
        return _is_type(head, tail...);
    }

    template <class... Tail>
    static bool is_numeric(DataType head, Tail... tail) noexcept
    {
        return _is_numeric(head, tail...);
    }

    static bool types_are_comparable(const Mixed& l, const Mixed& r);
    static bool data_types_are_comparable(DataType l_type, DataType r_type);

    template <class T>
    T get() const noexcept;

    template <class T>
    const T* get_if() const noexcept;

    template <class T>
    T export_to_type() const noexcept;

    // These functions are kept to be backwards compatible
    int64_t get_int() const noexcept;
    bool get_bool() const noexcept;
    float get_float() const noexcept;
    double get_double() const noexcept;
    StringData get_string() const noexcept;
    BinaryData get_binary() const noexcept;
    Timestamp get_timestamp() const noexcept;
    Decimal128 get_decimal() const noexcept;
    ObjectId get_object_id() const noexcept;
    UUID get_uuid() const noexcept;
    ObjLink get_link() const noexcept;

    bool is_null() const noexcept;
    bool accumulate_numeric_to(Decimal128& destination) const noexcept;
    bool is_unresolved_link() const noexcept;
    bool is_same_type(const Mixed& b) const noexcept;
    // Will use utf8_compare for strings
    int compare(const Mixed& b) const noexcept;
    // Will compare strings as arrays of signed chars
    int compare_signed(const Mixed& b) const noexcept;
    friend bool operator==(const Mixed& a, const Mixed& b) noexcept
    {
        return a.compare(b) == 0;
    }
    friend bool operator!=(const Mixed& a, const Mixed& b) noexcept
    {
        return a.compare(b) != 0;
    }
    friend bool operator<(const Mixed& a, const Mixed& b) noexcept
    {
        return a.compare(b) < 0;
    }
    friend bool operator>(const Mixed& a, const Mixed& b) noexcept
    {
        return a.compare(b) > 0;
    }
    friend bool operator<=(const Mixed& a, const Mixed& b) noexcept
    {
        return a.compare(b) <= 0;
    }
    friend bool operator>=(const Mixed& a, const Mixed& b) noexcept
    {
        return a.compare(b) >= 0;
    }

    Mixed operator+(const Mixed&) const noexcept;
    Mixed operator-(const Mixed&) const noexcept;
    Mixed operator*(const Mixed&) const noexcept;
    Mixed operator/(const Mixed&) const noexcept;

    size_t hash() const;
    StringData get_index_data(std::array<char, 16>&) const noexcept;
    void use_buffer(std::string& buf) noexcept;

protected:
    friend std::ostream& operator<<(std::ostream& out, const Mixed& m);

    uint32_t m_type;
    union {
        int64_t int_val;
        bool bool_val;
        float float_val;
        double double_val;
        StringData string_val;
        BinaryData binary_val;
        Timestamp date_val;
        ObjectId id_val;
        Decimal128 decimal_val;
        ObjLink link_val;
        UUID uuid_val;
#if REALM_ENABLE_GEOSPATIAL
        Geospatial* geospatial_val;
#endif
    };

private:
    static bool _is_type() noexcept
    {
        return false;
    }
    bool _is_type(DataType type) const noexcept
    {
        return m_type == unsigned(int(type) + 1);
    }
    template <class... Tail>
    bool _is_type(DataType head, Tail... tail) const noexcept
    {
        return _is_type(head) || _is_type(tail...);
    }
    static bool _is_numeric(DataType type) noexcept
    {
        return type == type_Int || type == type_Float || type == type_Double || type == type_Decimal ||
               type == type_Mixed;
    }
    template <class... Tail>
    static bool _is_numeric(DataType head, Tail... tail) noexcept
    {
        return _is_numeric(head) && _is_numeric(tail...);
    }
};
static_assert(std::is_trivially_destructible_v<Mixed>);

class OwnedMixed : public Mixed {
public:
    explicit OwnedMixed(std::string&& str)
        : m_owned_string(std::move(str))
    {
        m_type = int(type_String) + 1;
        string_val = m_owned_string;
    }

    OwnedMixed(OwnedMixed&& m) noexcept
        : Mixed(m)
        , m_owned_string(std::move(m.m_owned_string))
    {
        if (is_type(type_String)) {
            string_val = m_owned_string;
        }
    }

    OwnedMixed(const OwnedMixed& m)
        : Mixed(m)
        , m_owned_string(m.m_owned_string)
    {
        if (is_type(type_String)) {
            string_val = m_owned_string;
        }
    }

    OwnedMixed& operator=(OwnedMixed&& m) noexcept
    {
        *static_cast<Mixed*>(this) = m;
        if (is_type(type_String)) {
            m_owned_string = std::move(m.m_owned_string);
            string_val = m_owned_string;
        }
        return *this;
    }

    OwnedMixed& operator=(const OwnedMixed& m)
    {
        *static_cast<Mixed*>(this) = m;
        if (is_type(type_String)) {
            m_owned_string = m.m_owned_string;
            string_val = m_owned_string;
        }
        return *this;
    }

    explicit OwnedMixed(const Mixed& m)
        : Mixed(m)
    {
        if (m.is_type(type_String)) {
            m_owned_string = std::string(m.get_string());
            string_val = m_owned_string;
        }
    }

    OwnedMixed& operator=(const Mixed& m)
    {
        *static_cast<Mixed*>(this) = m;
        if (m.is_type(type_String)) {
            m_owned_string = std::string(m.get_string());
            string_val = m_owned_string;
        }
        return *this;
    }

    using Mixed::Mixed;

private:
    std::string m_owned_string;
};

// Implementation:

inline Mixed::Mixed(int64_t v) noexcept
{
    m_type = int(type_Int) + 1;
    int_val = v;
}

inline Mixed::Mixed(bool v) noexcept
{
    m_type = int(type_Bool) + 1;
    bool_val = v;
}

inline Mixed::Mixed(float v) noexcept
{
    if (null::is_null_float(v)) {
        m_type = 0;
    }
    else {
        m_type = int(type_Float) + 1;
        float_val = v;
    }
}

inline Mixed::Mixed(double v) noexcept
{
    if (null::is_null_float(v)) {
        m_type = 0;
    }
    else {
        m_type = int(type_Double) + 1;
        double_val = v;
    }
}

inline Mixed::Mixed(util::Optional<int64_t> v) noexcept
{
    if (v) {
        m_type = int(type_Int) + 1;
        int_val = *v;
    }
    else {
        m_type = 0;
    }
}

inline Mixed::Mixed(util::Optional<bool> v) noexcept
{
    if (v) {
        m_type = int(type_Bool) + 1;
        bool_val = *v;
    }
    else {
        m_type = 0;
    }
}

inline Mixed::Mixed(util::Optional<float> v) noexcept
{
    if (v && !null::is_null_float(*v)) {
        m_type = int(type_Float) + 1;
        float_val = *v;
    }
    else {
        m_type = 0;
    }
}

inline Mixed::Mixed(util::Optional<double> v) noexcept
{
    if (v && !null::is_null_float(*v)) {
        m_type = int(type_Double) + 1;
        double_val = *v;
    }
    else {
        m_type = 0;
    }
}

inline Mixed::Mixed(util::Optional<ObjectId> v) noexcept
{
    if (v) {
        m_type = int(type_ObjectId) + 1;
        id_val = *v;
    }
    else {
        m_type = 0;
    }
}

inline Mixed::Mixed(util::Optional<UUID> v) noexcept
{
    if (v) {
        m_type = int(type_UUID) + 1;
        uuid_val = *v;
    }
    else {
        m_type = 0;
    }
}

inline Mixed::Mixed(StringData v) noexcept
{
    if (!v.is_null()) {
        m_type = int(type_String) + 1;
        string_val = v;
    }
    else {
        m_type = 0;
    }
}

inline Mixed::Mixed(BinaryData v) noexcept
{
    if (!v.is_null()) {
        m_type = int(type_Binary) + 1;
        binary_val = v;
    }
    else {
        m_type = 0;
    }
}

inline Mixed::Mixed(Timestamp v) noexcept
{
    if (!v.is_null()) {
        m_type = int(type_Timestamp) + 1;
        date_val = v;
    }
    else {
        m_type = 0;
    }
}

inline Mixed::Mixed(Decimal128 v)
{
    if (!v.is_null()) {
        m_type = int(type_Decimal) + 1;
        decimal_val = v;
    }
    else {
        m_type = 0;
    }
}

#if REALM_ENABLE_GEOSPATIAL
inline Mixed::Mixed(Geospatial* store) noexcept
{
    m_type = int(type_Geospatial) + 1;
    geospatial_val = store;
}
#endif

inline Mixed::Mixed(ObjectId v) noexcept
{
    m_type = int(type_ObjectId) + 1;
    id_val = v;
}

inline Mixed::Mixed(UUID v) noexcept
{
    m_type = int(type_UUID) + 1;
    uuid_val = v;
}

inline Mixed::Mixed(ObjKey v) noexcept
{
    if (v) {
        m_type = int(type_Link) + 1;
        int_val = v.value;
    }
    else {
        m_type = 0;
    }
}

inline Mixed::Mixed(ObjLink v) noexcept
{
    if (v) {
        m_type = int(type_TypedLink) + 1;
        link_val = v;
    }
    else {
        m_type = 0;
    }
}

template <>
inline null Mixed::get<null>() const noexcept
{
    REALM_ASSERT(m_type == 0);
    return {};
}

template <>
inline int64_t Mixed::get<int64_t>() const noexcept
{
    REALM_ASSERT(get_type() == type_Int);
    return int_val;
}

template <>
inline int Mixed::get<int>() const noexcept
{
    REALM_ASSERT(get_type() == type_Int);
    return int(int_val);
}

inline int64_t Mixed::get_int() const noexcept
{
    return get<int64_t>();
}

template <>
inline const int64_t* Mixed::get_if<int64_t>() const noexcept
{
    return is_type(type_Int) ? &int_val : nullptr;
}

template <>
inline bool Mixed::get<bool>() const noexcept
{
    REALM_ASSERT(get_type() == type_Bool);
    return bool_val;
}

inline bool Mixed::get_bool() const noexcept
{
    return get<bool>();
}

template <>
inline const bool* Mixed::get_if<bool>() const noexcept
{
    return is_type(type_Bool) ? &bool_val : nullptr;
}

template <>
inline float Mixed::get<float>() const noexcept
{
    REALM_ASSERT(get_type() == type_Float);
    return float_val;
}

inline float Mixed::get_float() const noexcept
{
    return get<float>();
}

template <>
inline const float* Mixed::get_if<float>() const noexcept
{
    return is_type(type_Float) ? &float_val : nullptr;
}

template <>
inline double Mixed::get<double>() const noexcept
{
    REALM_ASSERT(get_type() == type_Double);
    return double_val;
}

inline double Mixed::get_double() const noexcept
{
    return get<double>();
}

template <>
inline const double* Mixed::get_if<double>() const noexcept
{
    return is_type(type_Double) ? &double_val : nullptr;
}

template <>
inline StringData Mixed::get<StringData>() const noexcept
{
    if (is_null())
        return StringData();
    REALM_ASSERT(get_type() == type_String);
    return string_val;
}

inline StringData Mixed::get_string() const noexcept
{
    return get<StringData>();
}

template <>
inline const StringData* Mixed::get_if<StringData>() const noexcept
{
    return is_type(type_String) ? &string_val : nullptr;
}

template <>
inline BinaryData Mixed::get<BinaryData>() const noexcept
{
    if (is_null())
        return BinaryData();
    if (get_type() == type_Binary) {
        return binary_val;
    }
    REALM_ASSERT(get_type() == type_String);
    return BinaryData(string_val.data(), string_val.size());
}

inline BinaryData Mixed::get_binary() const noexcept
{
    return get<BinaryData>();
}

template <>
inline const BinaryData* Mixed::get_if<BinaryData>() const noexcept
{
    return is_type(type_Binary) ? &binary_val : nullptr;
}

template <>
inline Timestamp Mixed::get<Timestamp>() const noexcept
{
    REALM_ASSERT(get_type() == type_Timestamp);
    return date_val;
}

inline Timestamp Mixed::get_timestamp() const noexcept
{
    return get<Timestamp>();
}

template <>
inline const Timestamp* Mixed::get_if<Timestamp>() const noexcept
{
    return is_type(type_Timestamp) ? &date_val : nullptr;
}

template <>
inline Decimal128 Mixed::get<Decimal128>() const noexcept
{
    REALM_ASSERT(get_type() == type_Decimal);
    return decimal_val;
}

inline Decimal128 Mixed::get_decimal() const noexcept
{
    return get<Decimal128>();
}

template <>
inline const Decimal128* Mixed::get_if<Decimal128>() const noexcept
{
    return is_type(type_Decimal) ? &decimal_val : nullptr;
}

template <>
inline ObjectId Mixed::get<ObjectId>() const noexcept
{
    REALM_ASSERT(get_type() == type_ObjectId);
    return id_val;
}

inline ObjectId Mixed::get_object_id() const noexcept
{
    return get<ObjectId>();
}

template <>
inline const ObjectId* Mixed::get_if<ObjectId>() const noexcept
{
    return is_type(type_ObjectId) ? &id_val : nullptr;
}

template <>
inline UUID Mixed::get<UUID>() const noexcept
{
    REALM_ASSERT(get_type() == type_UUID);
    return uuid_val;
}

inline UUID Mixed::get_uuid() const noexcept
{
    return get<UUID>();
}

template <>
inline const UUID* Mixed::get_if<UUID>() const noexcept
{
    return is_type(type_UUID) ? &uuid_val : nullptr;
}

template <>
inline ObjKey Mixed::get<ObjKey>() const noexcept
{
    if (get_type() == type_TypedLink)
        return link_val.get_obj_key();
    REALM_ASSERT(get_type() == type_Link);
    return ObjKey(int_val);
}

template <>
inline ObjLink Mixed::get<ObjLink>() const noexcept
{
    REALM_ASSERT(get_type() == type_TypedLink);
    return link_val;
}

#if REALM_ENABLE_GEOSPATIAL
template <>
inline Geospatial Mixed::get<Geospatial>() const noexcept
{
    auto type = get_type();
    REALM_ASSERT_EX(type == type_Geospatial, type);
    if (type == type_Geospatial) {
        return *geospatial_val;
    }
    REALM_UNREACHABLE();
}
#endif

template <>
inline Mixed Mixed::get<Mixed>() const noexcept
{
    return *this;
}

inline ObjLink Mixed::get_link() const noexcept
{
    return get<ObjLink>();
}

inline bool Mixed::is_null() const noexcept
{
    return (m_type == 0);
}

inline bool Mixed::is_same_type(const Mixed& b) const noexcept
{
    return (m_type == b.m_type);
}

inline bool Mixed::is_unresolved_link() const noexcept
{
    if (is_null()) {
        return false;
    }
    else if (get_type() == type_TypedLink) {
        return get<ObjLink>().is_unresolved();
    }
    else if (get_type() == type_Link) {
        return get<ObjKey>().is_unresolved();
    }
    return false;
}

std::ostream& operator<<(std::ostream& out, const Mixed& m);

} // namespace realm

namespace std {
template <>
struct hash<::realm::Mixed> {
    inline size_t operator()(const ::realm::Mixed& m) const noexcept
    {
        return m.hash();
    }
};
} // namespace std


#endif // REALM_MIXED_HPP
