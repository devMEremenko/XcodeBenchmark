/*************************************************************************
 *
 * Copyright 2020 Realm Inc.
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

#ifndef REALM_BSON_REGULAR_EXPRESSION_HPP
#define REALM_BSON_REGULAR_EXPRESSION_HPP

#include <ostream>
#include <string>
#include <unordered_set>

namespace realm {
namespace bson {

/// Provides regular expression capabilities for pattern matching strings in queries.
/// MongoDB uses Perl compatible regular expressions (i.e. "PCRE") version 8.42 with UTF-8 support.
struct RegularExpression {
    enum class Option { None, IgnoreCase = 1, Multiline = 2, Dotall = 4, Extended = 8 };

    RegularExpression()
        : m_pattern("")
        , m_options(Option::None)
    {
    }

    RegularExpression(const std::string pattern, const std::string& options);

    RegularExpression(const std::string pattern, Option options);

    RegularExpression(const RegularExpression&) = default;
    RegularExpression(RegularExpression&&) = default;
    RegularExpression& operator=(const RegularExpression& regex) = default;

    const std::string pattern() const;
    Option options() const;

private:
    static constexpr Option option_char_to_option(const char option);

    friend std::ostream& operator<<(std::ostream& out, const Option& o);
    std::string m_pattern;
    Option m_options;
};

inline bool operator==(const RegularExpression& lhs, const RegularExpression& rhs) noexcept
{
    return lhs.pattern() == rhs.pattern() && lhs.options() == rhs.options();
}

inline bool operator!=(const RegularExpression& lhs, const RegularExpression& rhs) noexcept
{
    return !(lhs.pattern() == rhs.pattern() && lhs.options() == rhs.options());
}

inline RegularExpression::Option operator|(const RegularExpression::Option& lhs,
                                           const RegularExpression::Option& rhs) noexcept
{
    return RegularExpression::Option(static_cast<int>(lhs) | static_cast<int>(rhs));
}

inline RegularExpression::Option operator&(const RegularExpression::Option& lhs,
                                           const RegularExpression::Option& rhs) noexcept
{
    return RegularExpression::Option(static_cast<int>(lhs) & static_cast<int>(rhs));
}

std::ostream& operator<<(std::ostream& out, const RegularExpression::Option& option);

} // namespace bson
} // namespace realm

#endif /* REALM_BSON_REGULAR_EXPRESSION_HPP */
