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

#ifndef REALM_AGGREGATE_OPS_HPP
#define REALM_AGGREGATE_OPS_HPP

#include <realm/column_type_traits.hpp>
#include <realm/mixed.hpp>

#include <algorithm>

namespace realm::aggregate_operations {


template <class T>
inline bool valid_for_agg(T)
{
    return true;
}

template <class T>
inline bool valid_for_agg(util::Optional<T> val)
{
    return !!val;
}
template <>
inline bool valid_for_agg(Timestamp val)
{
    return !val.is_null();
}
inline bool valid_for_agg(StringData val)
{
    return !val.is_null();
}
inline bool valid_for_agg(BinaryData val)
{
    return !val.is_null();
}
template <>
inline bool valid_for_agg(float val)
{
    return !null::is_null_float(val) && !std::isnan(val);
}
template <>
inline bool valid_for_agg(double val)
{
    return !null::is_null_float(val) && !std::isnan(val);
}
template <>
inline bool valid_for_agg(Decimal128 val)
{
    return !val.is_null() && !val.is_nan();
}
template <>
inline bool valid_for_agg(Mixed val)
{
    return !val.is_null() && (val.get_type() != type_Decimal || !val.get_decimal().is_nan());
}

template <typename T, typename Compare>
class MinMaxAggregateOperator {
public:
    bool accumulate(T value)
    {
        if (valid_for_agg(value) && (!m_result || Compare()(value, *m_result))) {
            m_result = value;
            return true;
        }
        return false;
    }

    bool accumulate(util::Optional<T> value)
    {
        if (value) {
            return accumulate(*value);
        }
        return false;
    }

    template <typename Type = T>
    std::enable_if_t<!std::is_same_v<Type, Mixed>, bool> accumulate(const Mixed& value)
    {
        if (!value.is_null()) {
            return accumulate(value.get<T>());
        }
        return false;
    }

    bool is_null() const
    {
        return !m_result;
    }
    T result() const
    {
        REALM_ASSERT(m_result);
        return *m_result;
    }

private:
    util::Optional<T> m_result;
};

template <typename T>
class Minimum : public MinMaxAggregateOperator<T, std::less<>> {
public:
    static const char* description()
    {
        return "@min";
    }
};

template <typename T>
class Maximum : public MinMaxAggregateOperator<T, std::greater<>> {
public:
    static const char* description()
    {
        return "@max";
    }
};


template <typename T>
class Sum {
public:
    using ResultType = typename realm::ColumnSumType<T>;

    bool accumulate(T value)
    {
        if constexpr (std::is_same_v<T, Mixed>) {
            if (value.accumulate_numeric_to(m_result)) {
                ++m_count;
                return true;
            }
        }
        else if constexpr (std::is_integral_v<T> && std::is_signed_v<T>) {
            m_result = std::make_unsigned_t<T>(m_result) + value;
            ++m_count;
            return true;
        }
        else {
            if (valid_for_agg(value)) {
                m_result += value;
                ++m_count;
                return true;
            }
        }
        return false;
    }

    bool accumulate(const util::Optional<T>& value)
    {
        if (value) {
            return accumulate(*value);
        }
        return false;
    }
    template <typename Type = T>
    std::enable_if_t<!std::is_same_v<Type, Mixed>, bool> accumulate(const Mixed& value)
    {
        if (!value.is_null()) {
            return accumulate(value.get<Type>());
        }
        return false;
    }

    bool is_null() const
    {
        return false;
    }
    ResultType result() const
    {
        return m_result;
    }
    size_t items_counted() const
    {
        return m_count;
    }
    static const char* description()
    {
        return "@sum";
    }

private:
    ResultType m_result = {};
    size_t m_count = 0;
};

template <typename T>
class Average {
public:
    using ResultType = typename std::conditional<realm::is_any_v<T, Decimal128, Mixed>, Decimal128, double>::type;

    bool accumulate(T value)
    {
        if constexpr (std::is_same_v<T, Mixed>) {
            if (value.accumulate_numeric_to(m_result)) {
                m_count++;
                return true;
            }
        }
        else {
            if (valid_for_agg(value)) {
                m_count++;
                m_result += value;
                return true;
            }
        }
        return false;
    }
    bool accumulate(const util::Optional<T>& value)
    {
        if (value) {
            return accumulate(*value);
        }
        return false;
    }

    template <typename Type = T>
    std::enable_if_t<!std::is_same_v<Type, Mixed>, bool> accumulate(const Mixed& value)
    {
        if (!value.is_null()) {
            return accumulate(value.get<Type>());
        }
        return false;
    }

    bool is_null() const
    {
        return m_count == 0;
    }
    ResultType result() const
    {
        REALM_ASSERT_EX(m_count > 0, m_count);
        return m_result / m_count;
    }
    static const char* description()
    {
        return "@avg";
    }
    size_t items_counted() const
    {
        return m_count;
    }

private:
    size_t m_count = 0;
    ResultType m_result = {};
};

} // namespace realm::aggregate_operations

#endif // REALM_AGGREGATE_OPS_HPP
