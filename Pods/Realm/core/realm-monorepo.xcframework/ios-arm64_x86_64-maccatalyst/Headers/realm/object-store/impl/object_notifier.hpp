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

#ifndef REALM_OS_OBJECT_NOTIFIER_HPP
#define REALM_OS_OBJECT_NOTIFIER_HPP

#include <realm/object-store/impl/collection_notifier.hpp>

#include <realm/keys.hpp>
#include <realm/table.hpp>

namespace realm::_impl {
class ObjectNotifier : public CollectionNotifier {
public:
    ObjectNotifier(std::shared_ptr<Realm> realm, TableKey table_key, ObjKey obj_key);

private:
    TableRef m_table;
    ObjKey m_obj_key;
    TransactionChangeInfo* m_info = nullptr;

    void run() override REQUIRES(!m_callback_mutex);
    void reattach() override;
    bool do_add_required_change_info(TransactionChangeInfo& info) override;
};
} // namespace realm::_impl

#endif // REALM_OS_OBJECT_NOTIFIER_HPP
