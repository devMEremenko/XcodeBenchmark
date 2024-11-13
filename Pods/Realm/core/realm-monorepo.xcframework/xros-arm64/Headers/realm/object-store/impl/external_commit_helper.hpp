////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#ifndef REALM_EXTERNAL_COMMIT_HELPER_HPP
#define REALM_EXTERNAL_COMMIT_HELPER_HPP

#include <realm/util/features.h>

#if REALM_PLATFORM_APPLE
#include <realm/object-store/impl/apple/external_commit_helper.hpp>
#elif REALM_HAVE_EPOLL
#include <realm/object-store/impl/epoll/external_commit_helper.hpp>
#elif defined(_WIN32)
#include <realm/object-store/impl/windows/external_commit_helper.hpp>
#elif defined(__EMSCRIPTEN__)
#include <realm/object-store/impl/emscripten/external_commit_helper.hpp>
#else
#warning "The GenericExternalCommitHelper has been selected. Notifications won't be delivered properly"
#include <realm/object-store/impl/generic/external_commit_helper.hpp>
#endif

#endif // REALM_EXTERNAL_COMMIT_HELPER_HPP
