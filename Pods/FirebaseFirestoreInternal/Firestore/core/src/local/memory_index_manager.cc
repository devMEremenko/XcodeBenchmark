/*
 * Copyright 2019 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "Firestore/core/src/local/memory_index_manager.h"

#include <algorithm>
#include <set>
#include <unordered_map>
#include <vector>

#include "Firestore/core/src/core/target.h"
#include "Firestore/core/src/model/field_index.h"
#include "Firestore/core/src/model/model_fwd.h"
#include "Firestore/core/src/model/resource_path.h"
#include "Firestore/core/src/util/hard_assert.h"

namespace firebase {
namespace firestore {
namespace local {

using model::ResourcePath;

bool MemoryCollectionParentIndex::Add(const ResourcePath& collection_path) {
  HARD_ASSERT(collection_path.size() % 2 == 1, "Expected a collection path.");

  std::string collection_id = collection_path.last_segment();
  ResourcePath parent_path = collection_path.PopLast();
  std::set<ResourcePath>& existing_parents = index_[collection_id];
  bool inserted = existing_parents.insert(parent_path).second;
  return inserted;
}

std::vector<ResourcePath> MemoryCollectionParentIndex::GetEntries(
    const std::string& collection_id) const {
  std::vector<ResourcePath> result;
  auto found = index_.find(collection_id);
  if (found != index_.end()) {
    const std::set<ResourcePath>& parent_paths = found->second;
    std::copy(parent_paths.begin(), parent_paths.end(),
              std::back_inserter(result));
  }
  return result;
}

void MemoryIndexManager::AddToCollectionParentIndex(
    const ResourcePath& collection_path) {
  collection_parents_index_.Add(collection_path);
}

std::vector<ResourcePath> MemoryIndexManager::GetCollectionParents(
    const std::string& collection_id) {
  return collection_parents_index_.GetEntries(collection_id);
}

// Below methods are only stubs because field indices are not supported with
// memory persistence.

void MemoryIndexManager::Start() {
}

void MemoryIndexManager::AddFieldIndex(const model::FieldIndex& index) {
  (void)index;
}

void MemoryIndexManager::DeleteFieldIndex(const model::FieldIndex& index) {
  (void)index;
}

std::vector<model::FieldIndex> MemoryIndexManager::GetFieldIndexes(
    const std::string& collection_group) const {
  (void)collection_group;
  return {};
}

std::vector<model::FieldIndex> MemoryIndexManager::GetFieldIndexes() const {
  return {};
}

void MemoryIndexManager::DeleteAllFieldIndexes() {
}

void MemoryIndexManager::CreateTargetIndexes(const core::Target&) {
}

model::IndexOffset MemoryIndexManager::GetMinOffset(const core::Target&) {
  return model::IndexOffset::None();
}

model::IndexOffset MemoryIndexManager::GetMinOffset(const std::string&) const {
  return model::IndexOffset::None();
}

IndexManager::IndexType MemoryIndexManager::GetIndexType(const core::Target&) {
  return IndexManager::IndexType::NONE;
}

absl::optional<std::vector<model::DocumentKey>>
MemoryIndexManager::GetDocumentsMatchingTarget(const core::Target&) {
  // Field indices are not supported with memory persistence.
  return absl::nullopt;
}

absl::optional<std::string> MemoryIndexManager::GetNextCollectionGroupToUpdate()
    const {
  return absl::nullopt;
}

void MemoryIndexManager::UpdateCollectionGroup(const std::string&,
                                               model::IndexOffset) {
  // Field indices are not supported with memory persistence.
}

void MemoryIndexManager::UpdateIndexEntries(const model::DocumentMap&) {
}

}  // namespace local
}  // namespace firestore
}  // namespace firebase
