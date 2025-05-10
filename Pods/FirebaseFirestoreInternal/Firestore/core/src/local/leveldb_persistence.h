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

#ifndef FIRESTORE_CORE_SRC_LOCAL_LEVELDB_PERSISTENCE_H_
#define FIRESTORE_CORE_SRC_LOCAL_LEVELDB_PERSISTENCE_H_

#include <memory>
#include <set>
#include <string>
#include <unordered_map>

#include "Firestore/core/src/credentials/user.h"
#include "Firestore/core/src/local/leveldb_bundle_cache.h"
#include "Firestore/core/src/local/leveldb_document_overlay_cache.h"
#include "Firestore/core/src/local/leveldb_globals_cache.h"
#include "Firestore/core/src/local/leveldb_index_manager.h"
#include "Firestore/core/src/local/leveldb_lru_reference_delegate.h"
#include "Firestore/core/src/local/leveldb_migrations.h"
#include "Firestore/core/src/local/leveldb_mutation_queue.h"
#include "Firestore/core/src/local/leveldb_overlay_migration_manager.h"
#include "Firestore/core/src/local/leveldb_remote_document_cache.h"
#include "Firestore/core/src/local/leveldb_target_cache.h"
#include "Firestore/core/src/local/leveldb_transaction.h"
#include "Firestore/core/src/local/local_serializer.h"
#include "Firestore/core/src/local/persistence.h"
#include "Firestore/core/src/util/path.h"
#include "Firestore/core/src/util/statusor.h"

namespace firebase {
namespace firestore {

namespace core {
class DatabaseInfo;
}  // namespace core

namespace local {

class LevelDbLruReferenceDelegate;
struct LruParams;

/** A LevelDB-backed implementation of the Persistence interface. */
class LevelDbPersistence : public Persistence {
 public:
  /**
   * Creates a LevelDB in the given directory and returns it or a Status object
   * containing details of the failure.
   */
  static util::StatusOr<std::unique_ptr<LevelDbPersistence>> Create(
      util::Path dir, LocalSerializer serializer, const LruParams& lru_params);

  ~LevelDbPersistence();

  LevelDbTransaction* current_transaction();

  leveldb::DB* ptr() {
    return db_.get();
  }

  const std::set<std::string> users() const {
    return users_;
  }

  static util::Status ClearPersistence(const core::DatabaseInfo& database_info);

  util::StatusOr<int64_t> CalculateByteSize();

  // MARK: Persistence overrides

  model::ListenSequenceNumber current_sequence_number() const override;

  void Shutdown() override;

  LevelDbBundleCache* bundle_cache() override;

  LevelDbGlobalsCache* globals_cache() override;

  LevelDbDocumentOverlayCache* GetDocumentOverlayCache(
      const credentials::User& user) override;
  LevelDbOverlayMigrationManager* GetOverlayMigrationManager(
      const credentials::User& user) override;

  LevelDbMutationQueue* GetMutationQueue(const credentials::User& user,
                                         IndexManager* index_manager) override;

  LevelDbTargetCache* target_cache() override;

  LevelDbRemoteDocumentCache* remote_document_cache() override;

  LevelDbIndexManager* GetIndexManager(const credentials::User& user) override;

  LevelDbLruReferenceDelegate* reference_delegate() override;

  void ReleaseOtherUserSpecificComponents(const std::string& uid) override;

 protected:
  void RunInternal(absl::string_view label,
                   std::function<void()> block) override;

 private:
  friend class LevelDbOverlayMigrationManagerTest;
  friend class LevelDbLocalStoreTest;
  friend class LevelDbIndexManager;

  LevelDbPersistence(std::unique_ptr<leveldb::DB> db,
                     util::Path directory,
                     std::set<std::string> users,
                     LocalSerializer serializer,
                     const LruParams& lru_params);

  /**
   * The maximum number of operation per transaction.
   */
  static const size_t kMaxOperationPerTransaction = 1000U;

  /**
   * Ensures that the given directory exists.
   */
  static util::Status EnsureDirectory(const util::Path& dir);

  /** Opens the database within the given directory. */
  static util::StatusOr<std::unique_ptr<leveldb::DB>> OpenDb(
      const util::Path& dir);

  static util::StatusOr<std::unique_ptr<LevelDbPersistence>> Create(
      util::Path dir,
      LevelDbMigrations::SchemaVersion schema_version,
      LocalSerializer serializer,
      const LruParams& lru_params);

  void DeleteAllFieldIndexes() override;

  /**
   * Remove the database entry (if any) for all "key" starting with given
   * prefix. It is a no-op if the key does not exist.
   */
  void DeleteEverythingWithPrefix(absl::string_view label,
                                  const std::string& prefix);

  std::unique_ptr<leveldb::DB> db_;

  util::Path directory_;
  std::set<std::string> users_;
  LocalSerializer serializer_;
  bool started_ = false;

  std::unique_ptr<LevelDbBundleCache> bundle_cache_;
  std::unique_ptr<LevelDbGlobalsCache> globals_cache_;
  std::unordered_map<std::string, std::unique_ptr<LevelDbDocumentOverlayCache>>
      document_overlay_caches_;
  std::unordered_map<std::string,
                     std::unique_ptr<LevelDbOverlayMigrationManager>>
      overlay_migration_managers_;
  std::unordered_map<std::string, std::unique_ptr<LevelDbMutationQueue>>
      mutation_queues_;
  std::unique_ptr<LevelDbTargetCache> target_cache_;
  std::unique_ptr<LevelDbRemoteDocumentCache> document_cache_;
  std::unordered_map<std::string, std::unique_ptr<LevelDbIndexManager>>
      index_managers_;
  std::unique_ptr<LevelDbLruReferenceDelegate> reference_delegate_;

  std::unique_ptr<LevelDbTransaction> transaction_;
};

/** Returns a standard set of read options. */
leveldb::ReadOptions StandardReadOptions();

}  // namespace local
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_LOCAL_LEVELDB_PERSISTENCE_H_
