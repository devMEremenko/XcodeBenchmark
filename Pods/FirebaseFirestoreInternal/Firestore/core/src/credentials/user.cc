/*
 * Copyright 2018 Google
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

#include "Firestore/core/src/credentials/user.h"

#include <utility>

#include "Firestore/core/src/util/hard_assert.h"
#include "Firestore/core/src/util/no_destructor.h"

namespace firebase {
namespace firestore {
namespace credentials {

using util::NoDestructor;

User::User() : is_authenticated_{false} {
}

User::User(std::string uid) : uid_{std::move(uid)}, is_authenticated_{true} {
  HARD_ASSERT(!uid_.empty());
}

const User& User::Unauthenticated() {
  static const NoDestructor<User> kUnauthenticated;
  return *kUnauthenticated;
}

}  // namespace credentials
}  // namespace firestore
}  // namespace firebase
