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

#ifndef FIRESTORE_CORE_SRC_LOCAL_MEMORY_INDEX_MANAGER_H_
#define FIRESTORE_CORE_SRC_LOCAL_MEMORY_INDEX_MANAGER_H_

#include <set>
#include <string>
#include <unordered_map>
#include <vector>

#include "Firestore/core/src/local/index_manager.h"

namespace firebase {
namespace firestore {
namespace local {

/**
 * Internal implementation of the collection-parent index. Also used for
 * in-memory caching by LevelDbIndexManager and initial index population during
 * schema migration.
 */
class MemoryCollectionParentIndex {
 public:
  // Returns false if the entry already existed.
  bool Add(const model::ResourcePath& collection_path);

  std::vector<model::ResourcePath> GetEntries(
      const std::string& collection_id) const;

 private:
  std::unordered_map<std::string, std::set<model::ResourcePath>> index_;
};

/** An in-memory implementation of IndexManager. */
class MemoryIndexManager : public IndexManager {
 public:
  MemoryIndexManager() = default;

  void Start() override;

  void AddToCollectionParentIndex(
      const model::ResourcePath& collection_path) override;

  std::vector<model::ResourcePath> GetCollectionParents(
      const std::string& collection_id) override;

  void AddFieldIndex(const model::FieldIndex& index) override;

  void DeleteFieldIndex(const model::FieldIndex& index) override;

  std::vector<model::FieldIndex> GetFieldIndexes(
      const std::string& collection_group) const override;

  std::vector<model::FieldIndex> GetFieldIndexes() const override;

  void DeleteAllFieldIndexes() override;

  void CreateTargetIndexes(const core::Target&) override;

  model::IndexOffset GetMinOffset(const core::Target&) override;

  model::IndexOffset GetMinOffset(const std::string&) const override;

  IndexType GetIndexType(const core::Target&) override;

  absl::optional<std::vector<model::DocumentKey>> GetDocumentsMatchingTarget(
      const core::Target&) override;

  absl::optional<std::string> GetNextCollectionGroupToUpdate() const override;

  void UpdateCollectionGroup(const std::string&, model::IndexOffset) override;

  void UpdateIndexEntries(const model::DocumentMap&) override;

 private:
  MemoryCollectionParentIndex collection_parents_index_;
};

}  // namespace local
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_LOCAL_MEMORY_INDEX_MANAGER_H_
