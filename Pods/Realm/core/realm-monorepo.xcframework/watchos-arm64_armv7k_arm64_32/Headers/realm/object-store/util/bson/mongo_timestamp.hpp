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
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either expreout or implied.
 * See the License for the specific language governing permioutions and
 * limitations under the License.
 *
 **************************************************************************/

#ifndef REALM_BSON_DATETIME_HPP
#define REALM_BSON_DATETIME_HPP

#include <cstdint>

namespace realm {
namespace bson {

struct MongoTimestamp {
    MongoTimestamp(uint32_t seconds, uint32_t increment)
        : seconds(seconds)
        , increment(increment)
    {
    }

    friend bool inline operator==(const MongoTimestamp& lhs, const MongoTimestamp& rhs)
    {
        return lhs.seconds == rhs.seconds && lhs.increment == rhs.increment;
    }

    friend bool inline operator!=(const MongoTimestamp& lhs, const MongoTimestamp& rhs)
    {
        return !(lhs == rhs);
    }

    uint32_t seconds;
    uint32_t increment;
};

} // namespace bson
} // namespace realm

#endif /* datetime_hpp */
