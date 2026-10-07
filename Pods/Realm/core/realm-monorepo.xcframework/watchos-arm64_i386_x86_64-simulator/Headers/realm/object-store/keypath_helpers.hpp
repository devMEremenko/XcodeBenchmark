////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#include <realm/object-store/object_schema.hpp>
#include <realm/object-store/object_store.hpp>
#include <realm/object-store/shared_realm.hpp>

#include <realm/parser/keypath_mapping.hpp>

namespace realm {
/// Populate the mapping from public name to internal name for queries.
inline void populate_keypath_mapping(query_parser::KeyPathMapping& mapping, Realm& realm)
{
    for (auto& object_schema : realm.schema()) {
        TableRef table;
        auto get_table = [&] {
            if (!table)
                table = realm.read_group().get_table(object_schema.table_key);
            return table;
        };

        if (!object_schema.alias.empty()) {
            mapping.add_table_mapping(get_table(), object_schema.alias);
        }

        for (auto& property : object_schema.persisted_properties) {
            if (!property.public_name.empty() && property.public_name != property.name)
                mapping.add_mapping(get_table(), property.public_name, property.name);
        }

        for (auto& property : object_schema.computed_properties) {
            if (property.type != PropertyType::LinkingObjects)
                continue;
            auto native_name = util::format("@links.%1.%2", property.object_type, property.link_origin_property_name);
            mapping.add_mapping(get_table(), property.name, std::move(native_name));
        }
    }
}

} // namespace realm
