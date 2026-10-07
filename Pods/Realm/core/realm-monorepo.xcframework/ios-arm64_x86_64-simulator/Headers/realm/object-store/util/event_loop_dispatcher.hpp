////////////////////////////////////////////////////////////////////////////
//
// Copyright 2019 Realm Inc.
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

#ifndef REALM_OS_UTIL_EVENT_LOOP_DISPATCHER_HPP
#define REALM_OS_UTIL_EVENT_LOOP_DISPATCHER_HPP

#include <realm/object-store/util/scheduler.hpp>

#include <tuple>

namespace realm {

namespace util {
template <class F>
class EventLoopDispatcher;

template <typename... Args>
class EventLoopDispatcher<void(Args...)> {
    using Tuple = std::tuple<typename std::remove_reference<Args>::type...>;

private:
    const std::shared_ptr<util::UniqueFunction<void(Args...)>> m_func;
    const std::shared_ptr<util::Scheduler> m_scheduler = util::Scheduler::make_default();

public:
    EventLoopDispatcher(util::UniqueFunction<void(Args...)> func)
        : m_func(std::make_shared<util::UniqueFunction<void(Args...)>>(std::move(func)))
    {
    }

    const util::UniqueFunction<void(Args...)>& func() const
    {
        return *m_func;
    }

    void operator()(Args... args)
    {
        if (m_scheduler->is_on_thread()) {
            (*m_func)(std::forward<Args>(args)...);
            return;
        }
        m_scheduler->invoke(
            [scheduler = m_scheduler, func = m_func, args = std::make_tuple(std::forward<Args>(args)...)]() mutable {
                std::apply(*func, std::move(args));
                // Each invocation block will retain the scheduler, so the scheduler
                // will not be released until all blocks are called
            });
    }
};

} // namespace util

namespace _impl::ForEventLoopDispatcher {
template <typename Sig>
struct ExtractSignatureImpl {
};
template <typename T, typename... Args>
struct ExtractSignatureImpl<void (T::*)(Args...)> {
    using signature = void(Args...);
};
template <typename T, typename... Args>
struct ExtractSignatureImpl<void (T::*)(Args...) const> {
    using signature = void(Args...);
};
template <typename T, typename... Args>
struct ExtractSignatureImpl<void (T::*)(Args...)&> {
    using signature = void(Args...);
};
template <typename T, typename... Args>
struct ExtractSignatureImpl<void (T::*)(Args...) const&> {
    using signature = void(Args...);
};
template <typename T, typename... Args>
struct ExtractSignatureImpl<void (T::*)(Args...) noexcept> {
    using signature = void(Args...);
};
template <typename T, typename... Args>
struct ExtractSignatureImpl<void (T::*)(Args...) const noexcept> {
    using signature = void(Args...);
};
template <typename T, typename... Args>
struct ExtractSignatureImpl<void (T::*)(Args...)& noexcept> {
    using signature = void(Args...);
};
template <typename T, typename... Args>
struct ExtractSignatureImpl<void (T::*)(Args...) const& noexcept> {
    using signature = void(Args...);
};
// Note: no && specializations since util::UniqueFunction doesn't support them, so you can't construct an
// EventLoopDispatcher from something with that anyway.

template <typename T>
using ExtractSignature = typename ExtractSignatureImpl<T>::signature;
} // namespace _impl::ForEventLoopDispatcher

namespace util {

// Deduction guide for function pointers.
template <typename... Args>
EventLoopDispatcher(void (*)(Args...)) -> EventLoopDispatcher<void(Args...)>;

// Deduction guide for callable objects, such as lambdas. Only supports types with a non-overloaded, non-templated
// call operator, so no polymorphic (auto argument) lambdas.
template <typename T, typename Sig = _impl::ForEventLoopDispatcher::ExtractSignature<decltype(&T::operator())>>
EventLoopDispatcher(const T&) -> EventLoopDispatcher<Sig>;


} // namespace util
} // namespace realm

#endif
