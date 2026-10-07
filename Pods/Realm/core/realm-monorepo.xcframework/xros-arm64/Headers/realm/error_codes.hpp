/*************************************************************************
 *
 * Copyright 2021 Realm Inc.
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

#pragma once

#include <cstdint>
#include <type_traits>
#include <string>
#include <vector>
#include <realm/error_codes.h>

namespace realm {

// ErrorExtraInfo subclasses:

struct ErrorCategory {
    enum Type {
        logic_error = RLM_ERR_CAT_LOGIC,
        runtime_error = RLM_ERR_CAT_RUNTIME,
        invalid_argument = RLM_ERR_CAT_INVALID_ARG,
        file_access = RLM_ERR_CAT_FILE_ACCESS,
        system_error = RLM_ERR_CAT_SYSTEM_ERROR,
        app_error = RLM_ERR_CAT_APP_ERROR,
        client_error = RLM_ERR_CAT_CLIENT_ERROR,
        json_error = RLM_ERR_CAT_JSON_ERROR,
        service_error = RLM_ERR_CAT_SERVICE_ERROR,
        http_error = RLM_ERR_CAT_HTTP_ERROR,
        custom_error = RLM_ERR_CAT_CUSTOM_ERROR,
        websocket_error = RLM_ERR_CAT_WEBSOCKET_ERROR,
        sync_error = RLM_ERR_CAT_SYNC_ERROR,
    };
    constexpr ErrorCategory() = default;
    constexpr bool test(Type cat)
    {
        return (m_value & cat) != 0;
    }
    constexpr ErrorCategory& set(Type cat)
    {
        m_value |= cat;
        return *this;
    }
    constexpr void reset(Type cat)
    {
        m_value &= ~cat;
    }
    constexpr bool operator==(const ErrorCategory& other) const
    {
        return m_value == other.m_value;
    }
    constexpr bool operator!=(const ErrorCategory& other) const
    {
        return m_value != other.m_value;
    }
    constexpr int value() const
    {
        return m_value;
    }

private:
    unsigned m_value = 0;
};

class ErrorCodes {
public:
    // Explicitly 32-bits wide so that non-symbolic values,
    // like uassert codes, are valid.
    enum Error : std::int32_t {
        OK = RLM_ERR_NONE,
        RuntimeError = RLM_ERR_RUNTIME,
        RangeError = RLM_ERR_RANGE_ERROR,
        BrokenInvariant = RLM_ERR_BROKEN_INVARIANT,
        OutOfMemory = RLM_ERR_OUT_OF_MEMORY,
        OutOfDiskSpace = RLM_ERR_OUT_OF_DISK_SPACE,
        AddressSpaceExhausted = RLM_ERR_ADDRESS_SPACE_EXHAUSTED,
        MaximumFileSizeExceeded = RLM_ERR_MAXIMUM_FILE_SIZE_EXCEEDED,
        IncompatibleSession = RLM_ERR_INCOMPATIBLE_SESSION,
        IncompatibleLockFile = RLM_ERR_INCOMPATIBLE_LOCK_FILE,
        UnsupportedFileFormatVersion = RLM_ERR_UNSUPPORTED_FILE_FORMAT_VERSION,
        MultipleSyncAgents = RLM_ERR_MULTIPLE_SYNC_AGENTS,
        ObjectAlreadyExists = RLM_ERR_OBJECT_ALREADY_EXISTS,
        NotCloneable = RLM_ERR_NOT_CLONABLE,
        BadChangeset = RLM_ERR_BAD_CHANGESET,
        SubscriptionFailed = RLM_ERR_SUBSCRIPTION_FAILED,
        FileOperationFailed = RLM_ERR_FILE_OPERATION_FAILED,
        PermissionDenied = RLM_ERR_FILE_PERMISSION_DENIED,
        FileNotFound = RLM_ERR_FILE_NOT_FOUND,
        FileAlreadyExists = RLM_ERR_FILE_ALREADY_EXISTS,
        InvalidDatabase = RLM_ERR_INVALID_DATABASE,
        DecryptionFailed = RLM_ERR_DECRYPTION_FAILED,
        IncompatibleHistories = RLM_ERR_INCOMPATIBLE_HISTORIES,
        FileFormatUpgradeRequired = RLM_ERR_FILE_FORMAT_UPGRADE_REQUIRED,
        SchemaVersionMismatch = RLM_ERR_SCHEMA_VERSION_MISMATCH,
        NoSubscriptionForWrite = RLM_ERR_NO_SUBSCRIPTION_FOR_WRITE,
        BadVersion = RLM_ERR_BAD_VERSION,
        OperationAborted = RLM_ERR_OPERATION_ABORTED,

        AutoClientResetFailed = RLM_ERR_AUTO_CLIENT_RESET_FAILED,
        BadSyncPartitionValue = RLM_ERR_BAD_SYNC_PARTITION_VALUE,
        ConnectionClosed = RLM_ERR_CONNECTION_CLOSED,
        InvalidSubscriptionQuery = RLM_ERR_INVALID_SUBSCRIPTION_QUERY,
        SyncClientResetRequired = RLM_ERR_SYNC_CLIENT_RESET_REQUIRED,
        SyncCompensatingWrite = RLM_ERR_SYNC_COMPENSATING_WRITE,
        SyncConnectFailed = RLM_ERR_SYNC_CONNECT_FAILED,
        SyncConnectTimeout = RLM_ERR_SYNC_CONNECT_TIMEOUT,
        SyncInvalidSchemaChange = RLM_ERR_SYNC_INVALID_SCHEMA_CHANGE,
        SyncPermissionDenied = RLM_ERR_SYNC_PERMISSION_DENIED,
        SyncProtocolInvariantFailed = RLM_ERR_SYNC_PROTOCOL_INVARIANT_FAILED,
        SyncProtocolNegotiationFailed = RLM_ERR_SYNC_PROTOCOL_NEGOTIATION_FAILED,
        SyncServerPermissionsChanged = RLM_ERR_SYNC_SERVER_PERMISSIONS_CHANGED,
        SyncUserMismatch = RLM_ERR_SYNC_USER_MISMATCH,
        TlsHandshakeFailed = RLM_ERR_TLS_HANDSHAKE_FAILED,
        WrongSyncType = RLM_ERR_WRONG_SYNC_TYPE,
        SyncWriteNotAllowed = RLM_ERR_SYNC_WRITE_NOT_ALLOWED,

        SystemError = RLM_ERR_SYSTEM_ERROR,

        LogicError = RLM_ERR_LOGIC,
        NotSupported = RLM_ERR_NOT_SUPPORTED,
        BrokenPromise = RLM_ERR_BROKEN_PROMISE,
        CrossTableLinkTarget = RLM_ERR_CROSS_TABLE_LINK_TARGET,
        KeyAlreadyUsed = RLM_ERR_KEY_ALREADY_USED,
        WrongTransactionState = RLM_ERR_WRONG_TRANSACTION_STATE,
        WrongThread = RLM_ERR_WRONG_THREAD,
        IllegalOperation = RLM_ERR_ILLEGAL_OPERATION,
        SerializationError = RLM_ERR_SERIALIZATION_ERROR,
        StaleAccessor = RLM_ERR_STALE_ACCESSOR,
        InvalidatedObject = RLM_ERR_INVALIDATED_OBJECT,
        ReadOnlyDB = RLM_ERR_READ_ONLY_DB,
        DeleteOnOpenRealm = RLM_ERR_DELETE_OPENED_REALM,
        MismatchedConfig = RLM_ERR_MISMATCHED_CONFIG,
        ClosedRealm = RLM_ERR_CLOSED_REALM,
        InvalidTableRef = RLM_ERR_INVALID_TABLE_REF,
        SchemaValidationFailed = RLM_ERR_SCHEMA_VALIDATION_FAILED,
        SchemaMismatch = RLM_ERR_SCHEMA_MISMATCH,
        InvalidSchemaVersion = RLM_ERR_INVALID_SCHEMA_VERSION,
        InvalidSchemaChange = RLM_ERR_INVALID_SCHEMA_CHANGE,
        MigrationFailed = RLM_ERR_MIGRATION_FAILED,
        InvalidQuery = RLM_ERR_INVALID_QUERY,

        BadServerUrl = RLM_ERR_BAD_SERVER_URL,
        InvalidArgument = RLM_ERR_INVALID_ARGUMENT,
        TypeMismatch = RLM_ERR_PROPERTY_TYPE_MISMATCH,
        PropertyNotNullable = RLM_ERR_PROPERTY_NOT_NULLABLE,
        ReadOnlyProperty = RLM_ERR_READ_ONLY_PROPERTY,
        MissingPropertyValue = RLM_ERR_MISSING_PROPERTY_VALUE,
        MissingPrimaryKey = RLM_ERR_MISSING_PRIMARY_KEY,
        UnexpectedPrimaryKey = RLM_ERR_UNEXPECTED_PRIMARY_KEY,
        ModifyPrimaryKey = RLM_ERR_MODIFY_PRIMARY_KEY,
        SyntaxError = RLM_ERR_INVALID_QUERY_STRING,
        InvalidProperty = RLM_ERR_INVALID_PROPERTY,
        InvalidName = RLM_ERR_INVALID_NAME,
        InvalidDictionaryKey = RLM_ERR_INVALID_DICTIONARY_KEY,
        InvalidDictionaryValue = RLM_ERR_INVALID_DICTIONARY_VALUE,
        InvalidSortDescriptor = RLM_ERR_INVALID_SORT_DESCRIPTOR,
        InvalidEncryptionKey = RLM_ERR_INVALID_ENCRYPTION_KEY,
        InvalidQueryArg = RLM_ERR_INVALID_QUERY_ARG,
        KeyNotFound = RLM_ERR_NO_SUCH_OBJECT,
        OutOfBounds = RLM_ERR_INDEX_OUT_OF_BOUNDS,
        LimitExceeded = RLM_ERR_LIMIT_EXCEEDED,
        ObjectTypeMismatch = RLM_ERR_OBJECT_TYPE_MISMATCH,
        NoSuchTable = RLM_ERR_NO_SUCH_TABLE,
        TableNameInUse = RLM_ERR_TABLE_NAME_IN_USE,
        IllegalCombination = RLM_ERR_ILLEGAL_COMBINATION,
        TopLevelObject = RLM_ERR_TOP_LEVEL_OBJECT,

        CustomError = RLM_ERR_CUSTOM_ERROR,

        ClientUserNotFound = RLM_ERR_CLIENT_USER_NOT_FOUND,
        ClientUserNotLoggedIn = RLM_ERR_CLIENT_USER_NOT_LOGGED_IN,
        ClientAppDeallocated = RLM_ERR_CLIENT_APP_DEALLOCATED,
        ClientRedirectError = RLM_ERR_CLIENT_REDIRECT_ERROR,
        ClientTooManyRedirects = RLM_ERR_CLIENT_TOO_MANY_REDIRECTS,

        BadToken = RLM_ERR_BAD_TOKEN,
        MalformedJson = RLM_ERR_MALFORMED_JSON,
        MissingJsonKey = RLM_ERR_MISSING_JSON_KEY,
        BadBsonParse = RLM_ERR_BAD_BSON_PARSE,

        MissingAuthReq = RLM_ERR_MISSING_AUTH_REQ,
        InvalidSession = RLM_ERR_INVALID_SESSION,
        UserAppDomainMismatch = RLM_ERR_USER_APP_DOMAIN_MISMATCH,
        DomainNotAllowed = RLM_ERR_DOMAIN_NOT_ALLOWED,
        ReadSizeLimitExceeded = RLM_ERR_READ_SIZE_LIMIT_EXCEEDED,
        InvalidParameter = RLM_ERR_INVALID_PARAMETER,
        MissingParameter = RLM_ERR_MISSING_PARAMETER,
        TwilioError = RLM_ERR_TWILIO_ERROR,
        GCMError = RLM_ERR_GCM_ERROR,
        HTTPError = RLM_ERR_HTTP_ERROR,
        AWSError = RLM_ERR_AWS_ERROR,
        MongoDBError = RLM_ERR_MONGODB_ERROR,
        ArgumentsNotAllowed = RLM_ERR_ARGUMENTS_NOT_ALLOWED,
        FunctionExecutionError = RLM_ERR_FUNCTION_EXECUTION_ERROR,
        NoMatchingRuleFound = RLM_ERR_NO_MATCHING_RULE_FOUND,
        InternalServerError = RLM_ERR_INTERNAL_SERVER_ERROR,
        AuthProviderNotFound = RLM_ERR_AUTH_PROVIDER_NOT_FOUND,
        AuthProviderAlreadyExists = RLM_ERR_AUTH_PROVIDER_ALREADY_EXISTS,
        ServiceNotFound = RLM_ERR_SERVICE_NOT_FOUND,
        ServiceTypeNotFound = RLM_ERR_SERVICE_TYPE_NOT_FOUND,
        ServiceAlreadyExists = RLM_ERR_SERVICE_ALREADY_EXISTS,
        ServiceCommandNotFound = RLM_ERR_SERVICE_COMMAND_NOT_FOUND,
        ValueNotFound = RLM_ERR_VALUE_NOT_FOUND,
        ValueAlreadyExists = RLM_ERR_VALUE_ALREADY_EXISTS,
        ValueDuplicateName = RLM_ERR_VALUE_DUPLICATE_NAME,
        FunctionNotFound = RLM_ERR_FUNCTION_NOT_FOUND,
        FunctionAlreadyExists = RLM_ERR_FUNCTION_ALREADY_EXISTS,
        FunctionDuplicateName = RLM_ERR_FUNCTION_DUPLICATE_NAME,
        FunctionSyntaxError = RLM_ERR_FUNCTION_SYNTAX_ERROR,
        FunctionInvalid = RLM_ERR_FUNCTION_INVALID,
        IncomingWebhookNotFound = RLM_ERR_INCOMING_WEBHOOK_NOT_FOUND,
        IncomingWebhookAlreadyExists = RLM_ERR_INCOMING_WEBHOOK_ALREADY_EXISTS,
        IncomingWebhookDuplicateName = RLM_ERR_INCOMING_WEBHOOK_DUPLICATE_NAME,
        RuleNotFound = RLM_ERR_RULE_NOT_FOUND,
        APIKeyNotFound = RLM_ERR_API_KEY_NOT_FOUND,
        RuleAlreadyExists = RLM_ERR_RULE_ALREADY_EXISTS,
        RuleDuplicateName = RLM_ERR_RULE_DUPLICATE_NAME,
        AuthProviderDuplicateName = RLM_ERR_AUTH_PROVIDER_DUPLICATE_NAME,
        RestrictedHost = RLM_ERR_RESTRICTED_HOST,
        APIKeyAlreadyExists = RLM_ERR_API_KEY_ALREADY_EXISTS,
        IncomingWebhookAuthFailed = RLM_ERR_INCOMING_WEBHOOK_AUTH_FAILED,
        ExecutionTimeLimitExceeded = RLM_ERR_EXECUTION_TIME_LIMIT_EXCEEDED,
        NotCallable = RLM_ERR_NOT_CALLABLE,
        UserAlreadyConfirmed = RLM_ERR_USER_ALREADY_CONFIRMED,
        UserNotFound = RLM_ERR_USER_NOT_FOUND,
        UserDisabled = RLM_ERR_USER_DISABLED,
        AuthError = RLM_ERR_AUTH_ERROR,
        BadRequest = RLM_ERR_BAD_REQUEST,
        AccountNameInUse = RLM_ERR_ACCOUNT_NAME_IN_USE,
        InvalidPassword = RLM_ERR_INVALID_PASSWORD,
        SchemaValidationFailedWrite = RLM_ERR_SCHEMA_VALIDATION_FAILED_WRITE,
        AppUnknownError = RLM_ERR_APP_UNKNOWN,
        MaintenanceInProgress = RLM_ERR_MAINTENANCE_IN_PROGRESS,
        UserpassTokenInvalid = RLM_ERR_USERPASS_TOKEN_INVALID,
        InvalidServerResponse = RLM_ERR_INVALID_SERVER_RESPONSE,
        AppServerError = RLM_ERR_APP_SERVER_ERROR,

        CallbackFailed = RLM_ERR_CALLBACK,
        UnknownError = RLM_ERR_UNKNOWN,
    };

    static ErrorCategory error_categories(Error code);
    static std::string_view error_string(Error code);
    static Error from_string(std::string_view str);
    static std::vector<Error> get_all_codes();
    static std::vector<std::string_view> get_all_names();
    static std::vector<std::pair<std::string_view, ErrorCodes::Error>> get_error_list();
};

std::ostream& operator<<(std::ostream& stream, ErrorCodes::Error code);

} // namespace realm
