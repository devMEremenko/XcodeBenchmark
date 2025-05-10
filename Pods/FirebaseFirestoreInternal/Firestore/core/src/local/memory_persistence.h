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

#ifndef FIRESTORE_CORE_SRC_LOCAL_MEMORY_PERSISTENCE_H_
#define FIRESTORE_CORE_SRC_LOCAL_MEMORY_PERSISTENCE_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

#include "Firestore/core/src/credentials/user.h"
#include "Firestore/core/src/local/memory_bundle_cache.h"
#include "Firestore/core/src/local/memory_document_overlay_cache.h"
#include "Firestore/core/src/local/memory_globals_cache.h"
#include "Firestore/core/src/local/memory_index_manager.h"
#include "Firestore/core/src/local/memory_mutation_queue.h"
#include "Firestore/core/src/local/memory_remote_document_cache.h"
#include "Firestore/core/src/local/memory_target_cache.h"
#include "Firestore/core/src/local/overlay_migration_manager.h"
#include "Firestore/core/src/local/persistence.h"

namespace firebase {
namespace firestore {
namespace local {

struct LruParams;
class MemoryIndexManager;
class MemoryMutationQueue;
class MemoryOverlayMigrationManager;
class MemoryRemoteDocumentCache;
class MemoryTargetCache;
class MutationQueue;
class TargetCache;
class ReferenceDelegate;
class RemoteDocumentCache;
class Sizer;

/**
 * An in-memory implementation of the Persistence interface. Values are stored
 * only in RAM and are never persisted to any durable storage.
 */
class MemoryPersistence : public Persistence {
 public:
  using MutationQueues =
      std::unordered_map<credentials::User,
                         std::unique_ptr<MemoryMutationQueue>,
                         firebase::firestore::credentials::HashUser>;

  using DocumentOverlayCaches =
      std::unordered_map<credentials::User,
                         std::unique_ptr<MemoryDocumentOverlayCache>,
                         firebase::firestore::credentials::HashUser>;

  static std::unique_ptr<MemoryPersistence> WithEagerGarbageCollector();

  static std::unique_ptr<MemoryPersistence> WithLruGarbageCollector(
      LruParams params, std::unique_ptr<Sizer> sizer);

  ~MemoryPersistence() override;

  const MutationQueues& mutation_queues() const {
    return mutation_queues_;
  }

  // MARK: Persistence overrides

  model::ListenSequenceNumber current_sequence_number() const override;

  void Shutdown() override;

  MemoryMutationQueue* GetMutationQueue(const credentials::User& user,
                                        IndexManager* manager) override;

  MemoryTargetCache* target_cache() override;

  MemoryBundleCache* bundle_cache() override;

  MemoryGlobalsCache* globals_cache() override;

  MemoryDocumentOverlayCache* GetDocumentOverlayCache(
      const credentials::User& user) override;

  OverlayMigrationManager* GetOverlayMigrationManager(
      const credentials::User& user) override;

  MemoryRemoteDocumentCache* remote_document_cache() override;

  MemoryIndexManager* GetIndexManager(const credentials::User& user) override;

  ReferenceDelegate* reference_delegate() override;

  void ReleaseOtherUserSpecificComponents(const std::string& uid) override;

 protected:
  void RunInternal(absl::string_view label,
                   std::function<void()> block) override;

 private:
  MemoryPersistence();

  void set_reference_delegate(std::unique_ptr<ReferenceDelegate> delegate);

  void DeleteAllFieldIndexes() override;

  MutationQueues mutation_queues_;

  /**
   * The TargetCache representing the persisted cache of queries.
   *
   * Note that this is retained here to make it easier to write tests affecting
   * both the in-memory and LevelDB-backed persistence layers. Tests can create
   * a new LocalStore wrapping this Persistence instance and this will make
   * the in-memory persistence layer behave as if it were actually persisting
   * values.
   */
  MemoryTargetCache target_cache_;

  /**
   * The RemoteDocumentCache representing the persisted cache of remote
   * documents.
   */
  MemoryRemoteDocumentCache remote_document_cache_;

  MemoryIndexManager index_manager_;

  MemoryBundleCache bundle_cache_;

  MemoryGlobalsCache globals_cache_;

  DocumentOverlayCaches document_overlay_caches_;
  MemoryOverlayMigrationManager overlay_migration_manager_;

  std::unique_ptr<ReferenceDelegate> reference_delegate_;

  bool started_ = false;
};

}  // namespace local
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_LOCAL_MEMORY_PERSISTENCE_H_
