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

#ifndef REALM_QUERY_VALUE_HPP
#define REALM_QUERY_VALUE_HPP

#include <string>

#include <realm/data_type.hpp>
#include <realm/mixed.hpp>

namespace realm {

class TypeOfValue {
public:
    enum Attribute {
        Null = 1,
        Int = 2,
        Double = 4,
        Float = 8,
        Bool = 16,
        Timestamp = 32,
        String = 64,
        Binary = 128,
        UUID = 256,
        ObjectId = 512,
        Decimal128 = 1024,
        ObjectLink = 2048,
        Numeric = Int + Double + Float + Decimal128,
    };
    explicit TypeOfValue(int64_t attributes);
    explicit TypeOfValue(const std::string& attribute_tags);
    explicit TypeOfValue(const class Mixed& value);
    explicit TypeOfValue(const ColKey& col_key);
    explicit TypeOfValue(const DataType& data_type);
    bool matches(const class Mixed& value) const;
    bool matches(const TypeOfValue& other) const
    {
        return (m_attributes & other.m_attributes) != 0;
    }
    int64_t get_attributes() const
    {
        return m_attributes;
    }
    std::string to_string() const;

private:
    int64_t m_attributes;
};

class QueryValue : public Mixed {
public:
    using Mixed::Mixed;

    QueryValue(const Mixed& other)
        : Mixed(other)
    {
    }

    QueryValue(TypeOfValue v) noexcept
    {
        m_type = int(type_TypeOfValue) + 1;
        int_val = v.get_attributes();
    }

    TypeOfValue get_type_of_value() const noexcept
    {
        REALM_ASSERT(get_type() == type_TypeOfValue);
        return TypeOfValue(int_val);
    }
};

} // namespace realm

#endif // REALM_QUERY_VALUE_HPP
