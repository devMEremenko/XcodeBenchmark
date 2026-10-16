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

#ifndef REALM_KEYPATH_MAPPING_HPP
#define REALM_KEYPATH_MAPPING_HPP

#include <realm/table.hpp>

#include <unordered_map>
#include <string>

namespace realm {

namespace util {
using KeyPath = std::vector<std::string>;
KeyPath key_path_from_string(const std::string& s);
} // namespace util

namespace query_parser {

struct KeyPathElement {
    ConstTableRef table;
    ColKey col_key;
    enum class KeyPathOperation { None, BacklinkTraversal, BacklinkCount, ListOfPrimitivesElementLength } operation;
    bool is_list_of_primitives() const
    {
        return bool(col_key) && col_key.get_type() != col_type_LinkList && col_key.get_attrs().test(col_attr_List);
    }
};

class MappingError : public std::runtime_error {
public:
    MappingError(const std::string& msg)
        : std::runtime_error(msg)
    {
    }
    /// runtime_error::what() returns the msg provided in the constructor.
};

struct TableAndColHash {
    std::size_t operator()(const std::pair<TableKey, std::string>& p) const;
};

// This class holds state which allows aliasing variable names in key paths used in queries.
// It is used to allow variable naming in subqueries such as 'SUBQUERY(list, $obj, $obj.intCol = 5).@count'
// It can also be used to allow querying named backlinks if bindings provide the mappings themselves.
class KeyPathMapping {
public:
    KeyPathMapping() = default;
    // returns true if added, false if duplicate key already exists
    bool add_mapping(ConstTableRef table, std::string name, std::string alias);
    bool remove_mapping(ConstTableRef table, std::string name);
    bool has_mapping(ConstTableRef table, const std::string& name) const;
    util::Optional<std::string> get_mapping(TableKey table_key, const std::string& name) const;
    // table names are only used in backlink queries with the syntax '@links.TableName.property'
    bool add_table_mapping(ConstTableRef table, std::string alias);
    bool remove_table_mapping(std::string alias_to_remove);
    bool has_table_mapping(const std::string& alias) const;
    util::Optional<std::string> get_table_mapping(const std::string name) const;
    std::string translate(const LinkChain&, const std::string& identifier);
    std::string translate(ConstTableRef table, const std::string& identifier);
    std::string translate_table_name(const std::string& identifier);

protected:
    std::unordered_map<std::pair<TableKey, std::string>, std::string, TableAndColHash> m_mapping;
    std::unordered_map<std::string, std::string> m_table_mappings;
};

} // namespace query_parser
} // namespace realm

#endif // REALM_KEYPATH_MAPPING_HPP
