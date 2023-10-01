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

#ifndef REALM_UTIL_SERIALIZER_HPP
#define REALM_UTIL_SERIALIZER_HPP

#include <realm/table_ref.hpp>
#include <realm/util/features.h>
#include <realm/util/optional.hpp>

#include <string>
#include <sstream>
#include <vector>

namespace realm {

class BinaryData;
struct ColKey;
struct null;
class ObjectId;
struct ObjKey;
struct ObjLink;
class StringData;
class Timestamp;
class LinkMap;
class UUID;
class TypeOfValue;
class Group;
enum class ExpressionComparisonType : unsigned char;

#if REALM_ENABLE_GEOSPATIAL
class Geospatial;
#endif // REALM_ENABLE_GEOSPATIAL

namespace util::serializer {

// Definitions
template <typename T>
std::string print_value(T value);

template <typename T>
std::string print_value(Optional<T> value);

constexpr static const char value_separator[] = ".";

// Specializations declared here to be defined in the cpp file
template <> std::string print_value<>(BinaryData);
template <> std::string print_value<>(bool);
template <>
std::string print_value<>(float);
template <>
std::string print_value<>(double);
template <> std::string print_value<>(realm::null);
template <> std::string print_value<>(StringData);
template <> std::string print_value<>(realm::Timestamp);
template <>
std::string print_value<>(realm::ObjectId);
template <>
std::string print_value<>(realm::ObjKey);

std::string print_value(realm::ObjLink, Group*);

template <>
std::string print_value<>(realm::UUID);
template <>
std::string print_value<>(realm::TypeOfValue);

#if REALM_ENABLE_GEOSPATIAL
template <>
std::string print_value<>(const realm::Geospatial&);
#endif // REALM_ENABLE_GEOSPATIAL

// General implementation for most types
template <typename T>
std::string print_value(T value)
{
    std::stringstream ss;
    ss << value;
    return ss.str();
}

template <typename T>
std::string print_value(Optional<T> value)
{
    if (bool(value)) {
        return print_value(*value);
    } else {
        return "NULL";
    }
}

struct SerialisationState {
    SerialisationState(Group* g = nullptr) noexcept
        : group(g)
    {
    }
    std::string describe_column(ConstTableRef table, ColKey col_key);
    std::string describe_columns(const LinkMap& link_map, ColKey target_col_key);
    std::string describe_expression_type(util::Optional<ExpressionComparisonType> type);
    std::string get_column_name(ConstTableRef table, ColKey col_key);
    std::string get_backlink_column_name(ConstTableRef from, ColKey col_key);
    std::string get_variable_name(ConstTableRef table);
    std::vector<std::string> subquery_prefix_list;
    Group* group;
    ConstTableRef target_table;
};

} // namespace util::serializer
} // namespace realm

#endif // REALM_UTIL_SERIALIZER_HPP
