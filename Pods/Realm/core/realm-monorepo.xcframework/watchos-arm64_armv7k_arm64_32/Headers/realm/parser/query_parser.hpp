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

#ifndef REALM_PARSER_QUERY_PARSER_HPP
#define REALM_PARSER_QUERY_PARSER_HPP

#include <realm/string_data.hpp>
#include <realm/binary_data.hpp>
#include <realm/timestamp.hpp>
#include <realm/keys.hpp>
#include <realm/object_id.hpp>
#include <realm/decimal128.hpp>
#include <realm/uuid.hpp>
#include <realm/util/any.hpp>
#include <realm/mixed.hpp>

namespace realm::query_parser {

struct AnyContext {
    template <typename T>
    T unbox(const std::any& wrapper)
    {
        return util::any_cast<T>(wrapper);
    }
    bool is_null(const std::any& wrapper)
    {
        if (!wrapper.has_value()) {
            return true;
        }
        if (wrapper.type() == typeid(realm::null)) {
            return true;
        }
        return false;
    }
    bool is_list(const std::any& wrapper)
    {
        if (!wrapper.has_value()) {
            return false;
        }
        if (wrapper.type() == typeid(std::vector<Mixed>)) {
            return true;
        }
        return false;
    }
    DataType get_type_of(const std::any& wrapper)
    {
        const std::type_info& type{wrapper.type()};
        if (type == typeid(int64_t)) {
            return type_Int;
        }
        if (type == typeid(StringData)) {
            return type_String;
        }
        if (type == typeid(Timestamp)) {
            return type_Timestamp;
        }
        if (type == typeid(double)) {
            return type_Double;
        }
        if (type == typeid(bool)) {
            return type_Bool;
        }
        if (type == typeid(float)) {
            return type_Float;
        }
        if (type == typeid(BinaryData)) {
            return type_Binary;
        }
        if (type == typeid(ObjKey)) {
            return type_Link;
        }
        if (type == typeid(ObjectId)) {
            return type_ObjectId;
        }
        if (type == typeid(Decimal128)) {
            return type_Decimal;
        }
        if (type == typeid(UUID)) {
            return type_UUID;
        }
        if (type == typeid(ObjLink)) {
            return type_TypedLink;
        }
        if (type == typeid(Mixed)) {
            return type_Mixed;
        }
        return DataType(-1);
    }
};

class Arguments {
public:
    Arguments(size_t num_args)
        : m_count(num_args)
    {
    }
    virtual ~Arguments() = default;
    virtual bool bool_for_argument(size_t argument_index) = 0;
    virtual long long long_for_argument(size_t argument_index) = 0;
    virtual float float_for_argument(size_t argument_index) = 0;
    virtual double double_for_argument(size_t argument_index) = 0;
    virtual StringData string_for_argument(size_t argument_index) = 0;
    virtual BinaryData binary_for_argument(size_t argument_index) = 0;
    virtual Timestamp timestamp_for_argument(size_t argument_index) = 0;
    virtual ObjKey object_index_for_argument(size_t argument_index) = 0;
    virtual ObjectId objectid_for_argument(size_t argument_index) = 0;
    virtual Decimal128 decimal128_for_argument(size_t argument_index) = 0;
    virtual UUID uuid_for_argument(size_t argument_index) = 0;
    virtual ObjLink objlink_for_argument(size_t argument_index) = 0;
#if REALM_ENABLE_GEOSPATIAL
    virtual Geospatial geospatial_for_argument(size_t argument_index) = 0;
#endif
    virtual std::vector<Mixed> list_for_argument(size_t argument_index) = 0;
    virtual bool is_argument_null(size_t argument_index) = 0;
    virtual bool is_argument_list(size_t argument_index) = 0;
    virtual DataType type_for_argument(size_t argument_index) = 0;
    size_t get_num_args() const
    {
        return m_count;
    }
protected:
    void verify_ndx(size_t ndx) const
    {
        if (ndx >= m_count) {
            std::string error_message;
            if (m_count) {
                error_message = util::format("Request for argument at index %1 but only %2 argument%3 provided", ndx,
                                             m_count, m_count == 1 ? " is" : "s are");
            }
            else {
                error_message = util::format("Request for argument at index %1 but no arguments are provided", ndx);
            }
            throw InvalidArgument(ErrorCodes::OutOfBounds, error_message);
        }
    }
    size_t m_count;
};


template <typename ValueType, typename ContextType>
class ArgumentConverter : public Arguments {
public:
    ArgumentConverter(ContextType& context, const ValueType* arguments, size_t count)
        : Arguments(count)
        , m_ctx(context)
        , m_arguments(arguments)
    {
    }

    bool bool_for_argument(size_t i) override
    {
        return get<bool>(i);
    }
    long long long_for_argument(size_t i) override
    {
        return get<int64_t>(i);
    }
    float float_for_argument(size_t i) override
    {
        return get<float>(i);
    }
    double double_for_argument(size_t i) override
    {
        return get<double>(i);
    }
    StringData string_for_argument(size_t i) override
    {
        return get<StringData>(i);
    }
    BinaryData binary_for_argument(size_t i) override
    {
        return get<BinaryData>(i);
    }
    Timestamp timestamp_for_argument(size_t i) override
    {
        return get<Timestamp>(i);
    }
    ObjectId objectid_for_argument(size_t i) override
    {
        return get<ObjectId>(i);
    }
    UUID uuid_for_argument(size_t i) override
    {
        return get<UUID>(i);
    }
    Decimal128 decimal128_for_argument(size_t i) override
    {
        return get<Decimal128>(i);
    }
    ObjKey object_index_for_argument(size_t i) override
    {
        return get<ObjKey>(i);
    }
    ObjLink objlink_for_argument(size_t i) override
    {
        return get<ObjLink>(i);
    }
#if REALM_ENABLE_GEOSPATIAL
    Geospatial geospatial_for_argument(size_t i) override
    {
        return get<Geospatial>(i);
    }
#endif
    std::vector<Mixed> list_for_argument(size_t i) override
    {
        return get<std::vector<Mixed>>(i);
    }
    bool is_argument_list(size_t i) override
    {
        return m_ctx.is_list(at(i));
    }
    bool is_argument_null(size_t i) override
    {
        return m_ctx.is_null(at(i));
    }

private:
    ContextType& m_ctx;
    const ValueType* m_arguments;

    const ValueType& at(size_t index) const
    {
        Arguments::verify_ndx(index);
        return m_arguments[index];
    }

    DataType type_for_argument(size_t i) override
    {
        return m_ctx.get_type_of(at(i));
    }

    template <typename T>
    T get(size_t index) const
    {
        return m_ctx.template unbox<T>(at(index));
    }
};

class NoArgsError : public InvalidQueryArgError {
public:
    NoArgsError()
        : InvalidQueryArgError("Attempt to retreive an argument when no arguments were given")
    {
    }
};

class NoArguments : public Arguments {
public:
    NoArguments()
        : Arguments(0)
    {
    }
    bool bool_for_argument(size_t)
    {
        throw NoArgsError();
    }
    long long long_for_argument(size_t)
    {
        throw NoArgsError();
    }
    float float_for_argument(size_t)
    {
        throw NoArgsError();
    }
    double double_for_argument(size_t)
    {
        throw NoArgsError();
    }
    StringData string_for_argument(size_t)
    {
        throw NoArgsError();
    }
    BinaryData binary_for_argument(size_t)
    {
        throw NoArgsError();
    }
    Timestamp timestamp_for_argument(size_t)
    {
        throw NoArgsError();
    }
    ObjectId objectid_for_argument(size_t)
    {
        throw NoArgsError();
    }
    Decimal128 decimal128_for_argument(size_t)
    {
        throw NoArgsError();
    }
    UUID uuid_for_argument(size_t)
    {
        throw NoArgsError();
    }
    ObjKey object_index_for_argument(size_t)
    {
        throw NoArgsError();
    }
    ObjLink objlink_for_argument(size_t)
    {
        throw NoArgsError();
    }
#if REALM_ENABLE_GEOSPATIAL
    Geospatial geospatial_for_argument(size_t)
    {
        throw NoArgsError();
    }
#endif
    bool is_argument_list(size_t)
    {
        throw NoArgsError();
    }
    std::vector<Mixed> list_for_argument(size_t)
    {
        throw NoArgsError();
    }
    bool is_argument_null(size_t)
    {
        throw NoArgsError();
    }
    DataType type_for_argument(size_t)
    {
        throw NoArgsError();
    }
};

void parse(const std::string&);

} // namespace realm::query_parser


#endif /* REALM_PARSER_QUERY_PARSER_HPP */
