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

#ifndef REALM_EXCEPTIONS_HPP
#define REALM_EXCEPTIONS_HPP

#include <realm/status.hpp>

#include <stdexcept>
#include <system_error>

namespace realm {

class Exception : public std::exception {
public:
    Exception(ErrorCodes::Error err, std::string_view str);
    explicit Exception(Status status);

    const char* what() const noexcept final;
    const Status& to_status() const;
    std::string_view reason() const noexcept;
    ErrorCodes::Error code() const noexcept;
    ErrorCategory category() const noexcept;
    std::string_view code_string() const noexcept;

private:
    Status m_status;
};

/*
 * This will convert an exception in a catch(...) block into a Status. For `Exception`s, it returns the
 * status held in the exception directly. Otherwise it returns a status with an UnknownError error code and a
 * reason string holding the exception type and message.
 *
 * Currently this works for exceptions that derive from std::exception or Exception only.
 */
Status exception_to_status() noexcept;


/// The UnsupportedFileFormatVersion exception is thrown by DB::open()
/// constructor when opening a database that uses a deprecated file format
/// and/or a deprecated history schema which this version of Realm cannot
/// upgrade from.
struct UnsupportedFileFormatVersion : Exception {
    UnsupportedFileFormatVersion(int version);
    ~UnsupportedFileFormatVersion() noexcept override;
    /// The unsupported version of the file.
    int source_version = 0;
};


/// Thrown when a key is already existing when trying to create a new object
struct KeyAlreadyUsed : Exception {
    KeyAlreadyUsed(std::string_view msg)
        : Exception(ErrorCodes::KeyAlreadyUsed, msg)
    {
    }
    ~KeyAlreadyUsed() noexcept override;
};

/// The \c LogicError exception class is intended to be thrown only when
/// applications (or bindings) violate rules that are stated (or ought to have
/// been stated) in the documentation of the public API, and only in cases
/// where the violation could have been easily and efficiently predicted by the
/// application. In other words, this exception class is for the cases where
/// the error is due to incorrect use of the public API.
///
/// This class is not supposed to be caught by applications. It is not even
/// supposed to be considered part of the public API, and therefore the
/// documentation of the public API should **not** mention the \c LogicError
/// exception class by name. Note how this contrasts with other exception
/// classes, such as \c NoSuchTable, which are part of the public API, and are
/// supposed to be mentioned in the documentation by name. The \c LogicError
/// exception is part of Realm's private API.
///
/// In other words, the \c LogicError class should exclusively be used in
/// replacement (or in addition to) asserts (debug or not) in order to
/// guarantee program interruption, while still allowing for complete
/// test-cases to be written and run.
///
/// To this effect, the special `CHECK_LOGIC_ERROR()` macro is provided as a
/// test framework plugin to allow unit tests to check that the functions in
/// the public API do throw \c LogicError when rules are violated.
///
/// The reason behind hiding this class from the public API is to prevent users
/// from getting used to the idea that "Undefined Behaviour" equates a specific
/// exception being thrown. The whole point of properly documenting "Undefined
/// Behaviour" cases is to help the user know what the limits are, without
/// constraining the database to handle every and any use-case thrown at it.
struct LogicError : Exception {
    LogicError(ErrorCodes::Error code, std::string_view msg);
    ~LogicError() noexcept override;
};

struct RuntimeError : Exception {
    RuntimeError(ErrorCodes::Error code, std::string_view msg);
    RuntimeError(Status&& status);
    ~RuntimeError() noexcept override;
};

/// Thrown when creating references that are too large to be contained in our ref_type (size_t)
struct MaximumFileSizeExceeded : RuntimeError {
    MaximumFileSizeExceeded(std::string_view msg)
        : RuntimeError(ErrorCodes::MaximumFileSizeExceeded, msg)
    {
    }
    ~MaximumFileSizeExceeded() noexcept override;
};

/// Thrown when writing fails because the disk is full.
struct OutOfDiskSpace : RuntimeError {
    OutOfDiskSpace(std::string_view msg)
        : RuntimeError(ErrorCodes::OutOfDiskSpace, msg)
    {
    }
    ~OutOfDiskSpace() noexcept override;
};

/// Thrown when a sync agent attempts to join a session in which there is
/// already a sync agent. A session may only contain one sync agent at any given
/// time.
struct MultipleSyncAgents : RuntimeError {
    MultipleSyncAgents()
        : RuntimeError(ErrorCodes::MultipleSyncAgents, "Multiple sync agents attempted to join the same session")
    {
    }
    ~MultipleSyncAgents() noexcept override;
};


/// Thrown when memory can no longer be mapped to. When mmap/remap fails.
struct AddressSpaceExhausted : RuntimeError {
    AddressSpaceExhausted(std::string_view msg)
        : RuntimeError(ErrorCodes::AddressSpaceExhausted, msg)
    {
    }
    ~AddressSpaceExhausted() noexcept override;
};

struct InvalidArgument : LogicError {
    InvalidArgument(std::string_view msg);
    InvalidArgument(ErrorCodes::Error code, std::string_view msg);
    ~InvalidArgument() noexcept override;
};

struct InvalidColumnKey : InvalidArgument {
    template <class T>
    InvalidColumnKey(const T& name)
        : InvalidArgument(ErrorCodes::InvalidProperty, util::format("Invalid property for object type %1", name))
    {
    }
    InvalidColumnKey()
        : InvalidArgument(ErrorCodes::InvalidProperty, "Invalid column key")
    {
    }
    ~InvalidColumnKey() noexcept override;
};

/// Thrown by various functions to indicate that a specified table does not
/// exist.
struct NoSuchTable : InvalidArgument {
    NoSuchTable()
        : InvalidArgument(ErrorCodes::NoSuchTable, "No such table exists")
    {
    }
    ~NoSuchTable() noexcept override;
};

/// Thrown by various functions to indicate that a specified table name is
/// already in use.
struct TableNameInUse : InvalidArgument {
    TableNameInUse()
        : InvalidArgument(ErrorCodes::TableNameInUse, "The specified table name is already in use")
    {
    }
    ~TableNameInUse() noexcept override;
};


/// Thrown when a key can not by found
struct KeyNotFound : InvalidArgument {
    KeyNotFound(std::string_view msg)
        : InvalidArgument(ErrorCodes::KeyNotFound, msg)
    {
    }
    ~KeyNotFound() noexcept override;
};


struct NotNullable : InvalidArgument {
    NotNullable(std::string_view msg)
        : InvalidArgument(ErrorCodes::PropertyNotNullable, msg)
    {
    }
    template <class T, class U>
    NotNullable(const T& object_type, const U& property_name)
        : NotNullable(
              util::format("Invalid null value for non-nullable property '%1.%2'.", object_type, property_name))
    {
    }
    ~NotNullable() noexcept override;
};

struct PropertyTypeMismatch : InvalidArgument {
    template <class T, class U>
    PropertyTypeMismatch(const T& object_type, const U& property_name)
        : InvalidArgument(ErrorCodes::TypeMismatch,
                          util::format("Type mismatch for property '%1.%2'.", object_type, property_name))
    {
    }
    ~PropertyTypeMismatch() noexcept override;
};

struct OutOfBounds : InvalidArgument {
    OutOfBounds(std::string_view msg, size_t idx, size_t sz);
    ~OutOfBounds() noexcept override;
    size_t index;
    size_t size;
};

struct InvalidEncryptionKey : InvalidArgument {
    InvalidEncryptionKey()
        : InvalidArgument(ErrorCodes::InvalidEncryptionKey, "Encryption key must be 64 bytes.")
    {
    }
    ~InvalidEncryptionKey() noexcept override;
};

struct StaleAccessor : LogicError {
    StaleAccessor(std::string_view msg)
        : LogicError(ErrorCodes::StaleAccessor, msg)
    {
    }
    ~StaleAccessor() noexcept override;
};

struct IllegalOperation : LogicError {
    IllegalOperation(std::string_view msg)
        : LogicError(ErrorCodes::IllegalOperation, msg)
    {
    }
    ~IllegalOperation() noexcept override;
};

struct NoSubscriptionForWrite : RuntimeError {
    NoSubscriptionForWrite(std::string_view msg)
        : RuntimeError(ErrorCodes::NoSubscriptionForWrite, msg)
    {
    }
    ~NoSubscriptionForWrite() noexcept override;
};


struct WrongTransactionState : LogicError {
    WrongTransactionState(std::string_view msg)
        : LogicError(ErrorCodes::WrongTransactionState, msg)
    {
    }
    ~WrongTransactionState() noexcept override;
};

struct InvalidTableRef : LogicError {
    InvalidTableRef(const char* cause)
        : LogicError(ErrorCodes::InvalidTableRef, cause)
    {
    }
    ~InvalidTableRef() noexcept override;
};

struct SerializationError : LogicError {
    SerializationError(std::string_view msg)
        : LogicError(ErrorCodes::SerializationError, msg)
    {
    }
    ~SerializationError() noexcept override;
};

struct NotImplemented : LogicError {
    NotImplemented()
        : LogicError(ErrorCodes::IllegalOperation, "Not implemented")
    {
    }
    ~NotImplemented() noexcept override;
};

struct MigrationFailed : LogicError {
    MigrationFailed(std::string_view msg)
        : LogicError(ErrorCodes::MigrationFailed, msg)
    {
    }
    ~MigrationFailed() noexcept override;
};

struct ObjectAlreadyExists : RuntimeError {
    template <class T, class U>
    ObjectAlreadyExists(const U& object_type, T pk_val)
        : RuntimeError(
              ErrorCodes::ObjectAlreadyExists,
              util::format("Attempting to create an object of type '%1' with an existing primary key value '%2'",
                           object_type, pk_val))
    {
    }
    ~ObjectAlreadyExists() noexcept override;
};

// Thrown by functions that require a table to **not** be the target of link
// columns, unless those link columns are part of the table itself.
struct CrossTableLinkTarget : LogicError {
    template <class T>
    CrossTableLinkTarget(T table_name)
        : LogicError(ErrorCodes::CrossTableLinkTarget,
                     util::format("Cannot remove %1 that is target of outside links", table_name))
    {
    }
    ~CrossTableLinkTarget() noexcept override;
};


/// Used for any I/O related exception. Note the derived exception
/// types that are used for various specific types of errors.
class FileAccessError : public RuntimeError {
public:
    FileAccessError(ErrorCodes::Error code, std::string_view msg, std::string_view path, int err = 0);
    ~FileAccessError() noexcept override;

    /// Return the associated file system path, or the empty string if there is
    /// no associated file system path, or if the file system path is unknown.
    std::string_view get_path() const
    {
        return m_path;
    }
    int get_errno() const
    {
        return m_errno;
    }

private:
    std::string m_path;
    int m_errno = 0;
};

struct SystemError : RuntimeError {
    SystemError(std::error_code err, std::string_view msg)
        : RuntimeError(make_status(err, msg, false))
    {
    }

    SystemError(int err_no, std::string_view msg)
        : RuntimeError(make_status(std::error_code(err_no, std::generic_category()), msg, true))
    {
    }

    ~SystemError() noexcept override;

private:
    static Status make_status(std::error_code err, std::string_view msg, bool msg_is_prefix)
    {
        return Status(ErrorCodes::SystemError,
                      msg_is_prefix ? util::format("%1: %2 (%3)", msg, err.message(), err.value()) : msg);
    }
};

namespace query_parser {

/// Exception thrown when parsing fails due to invalid syntax.
struct SyntaxError : InvalidArgument {
    SyntaxError(std::string_view msg)
        : InvalidArgument(ErrorCodes::SyntaxError, msg)
    {
    }
    ~SyntaxError() noexcept override;
};

/// Exception thrown when binding a syntactically valid query string in a
/// context where it does not make sense.
struct InvalidQueryError : InvalidArgument {
    InvalidQueryError(std::string_view msg)
        : InvalidArgument(ErrorCodes::InvalidQuery, msg)
    {
    }
    ~InvalidQueryError() noexcept override;
};

/// Exception thrown when there is a problem accessing the arguments in a query string
struct InvalidQueryArgError : InvalidArgument {
    InvalidQueryArgError(std::string_view msg)
        : InvalidArgument(ErrorCodes::InvalidQueryArg, msg)
    {
    }
    ~InvalidQueryArgError() noexcept override;
};

} // namespace query_parser
} // namespace realm

#endif // REALM_EXCEPTIONS_HPP
