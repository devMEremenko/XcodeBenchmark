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

#include <string>
#include <vector>

#include <realm/util/logger.hpp>

namespace realm {

class BackupHandler {
public:
    using VersionList = std::vector<int>;
    using VersionTimeList = std::vector<std::pair<int, int>>;

    BackupHandler(const std::string& path, const VersionList& accepted, const VersionTimeList& to_be_deleted);
    bool is_accepted_file_format(int current_file_format_version) const noexcept;
    bool must_restore_from_backup(int current_file_format_version) const;
    void restore_from_backup();
    void cleanup_backups();
    void backup_realm_if_needed(int current_file_format_version, int target_file_format_version);
    std::string get_prefix();

    static std::string get_prefix_from_path(const std::string& path);
    // default lists of accepted versions and backups to delete when they get old enough
    static const VersionList accepted_versions_;
    static const VersionTimeList delete_versions_;

private:
    void prep_logging();
    void ensure_logger();
    std::string m_path;
    std::string m_prefix;
    char m_time_buf[100];
    VersionList m_accepted_versions;
    VersionTimeList m_delete_versions;
    std::unique_ptr<util::AppendToFileLogger> m_logger;
};

} // namespace realm
