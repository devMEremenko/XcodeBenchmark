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

#ifndef REALM_UTIL_FUNCTIONAL
#define REALM_UTIL_FUNCTIONAL

#include <realm/util/assert.hpp>
#include <realm/util/type_traits.hpp>

#include <functional>
#include <memory>
#include <type_traits>

namespace realm::util {

template <typename Function>
class UniqueFunction;

/**
 * A `UniqueFunction` is a move-only, type-erased functor object similar to `std::function`.
 * It is useful in situations where a functor cannot be wrapped in `std::function` objects because
 * it is incapable of being copied.  Often this happens with C++14 or later lambdas which capture a
 * `std::unique_ptr` by move.  The interface of `UniqueFunction` is nearly identical to
 * `std::function`, except that it is not copyable.
 */
template <typename RetType, typename... Args>
class UniqueFunction<RetType(Args...)> {
private:
    template <typename Functor>
    using EnableIfCallable =
        std::enable_if_t<std::conjunction_v<std::is_invocable_r<RetType, Functor, Args...>,
                                            std::negation<std::is_same<std::decay_t<Functor>, UniqueFunction>>>,
                         int>;

    struct Impl {
        virtual ~Impl() noexcept = default;
        virtual RetType call(Args&&... args) = 0;
    };

public:
    using result_type = RetType;

    ~UniqueFunction() noexcept = default;
    UniqueFunction() = default;

    UniqueFunction(const UniqueFunction&) = delete;
    UniqueFunction& operator=(const UniqueFunction&) = delete;

    UniqueFunction(UniqueFunction&&) noexcept = default;
    UniqueFunction& operator=(UniqueFunction&&) noexcept = default;

    void swap(UniqueFunction& that) noexcept
    {
        using std::swap;
        swap(this->impl, that.impl);
    }

    friend void swap(UniqueFunction& a, UniqueFunction& b) noexcept
    {
        a.swap(b);
    }

    template <typename Functor, EnableIfCallable<Functor> = 0>
    /* implicit */
    UniqueFunction(Functor&& functor)
        // This does not use make_unique() because
        // std::unique_ptr<Base>(std::make_unique<Derived>()) results in
        // std::unique_ptr<Derived> being instantiated, which can have
        // surprisingly negative effects on debug build performance.
        : impl(new SpecificImpl<std::decay_t<Functor>>(std::forward<Functor>(functor)))
    {
    }

    UniqueFunction(std::nullptr_t) noexcept {}

    RetType operator()(Args... args) const
    {
        REALM_ASSERT(static_cast<bool>(*this));
        return impl->call(std::forward<Args>(args)...);
    }

    explicit operator bool() const noexcept
    {
        return static_cast<bool>(this->impl);
    }

    template <typename T>
    const T* target() const noexcept
    {
        if (impl && typeid(*impl) == typeid(SpecificImpl<T>)) {
            return &static_cast<SpecificImpl<T>*>(impl.get())->f;
        }
        return nullptr;
    }

    /// Release ownership of the owned implementation pointer, if any.
    ///
    /// If not null, the returned pointer _must_ be used at a later point to
    /// construct a new UniqueFunction. This can be used to move UniqueFunction
    /// instances over API boundaries which do not support C++ move semantics.
    Impl* release()
    {
        return impl.release();
    }

    /// Construct a UniqueFunction using a pointer returned by release().
    ///
    /// This takes ownership of the passed pointer.
    UniqueFunction(Impl* impl)
        : impl(impl)
    {
    }

    // Needed to make `std::is_convertible<util::UniqueFunction<...>, std::function<...>>` be
    // `std::false_type`.  `UniqueFunction` objects are not convertible to any kind of
    // `std::function` object, since the latter requires a copy constructor, which the former does
    // not provide.  If you see a compiler error which references this line, you have tried to
    // assign a `UniqueFunction` object to a `std::function` object which is impossible -- please
    // check your variables and function signatures.
    template <typename Signature>
    operator std::function<Signature>() = delete;
    template <typename Signature>
    operator std::function<Signature>() const = delete;

private:
    template <typename Functor>
    struct SpecificImpl : Impl {
        template <typename F>
        explicit SpecificImpl(F&& func)
            : f(std::forward<F>(func))
        {
        }

        RetType call(Args&&... args) override
        {
            if constexpr (std::is_void_v<RetType>) {
                // The result of this call is not cast to void, to help preserve detection of
                // `[[nodiscard]]` violations.
                f(std::forward<Args>(args)...);
            }
            else {
                return f(std::forward<Args>(args)...);
            }
        }

        Functor f;
    };

    std::unique_ptr<Impl> impl;
};

/**
 * Helper to pattern-match the signatures for all combinations of const and l-value-qualifed member
 * function pointers. We don't currently support r-value-qualified call operators.
 */
template <typename>
struct UFDeductionHelper {
};
template <typename Class, typename Ret, typename... Args>
struct UFDeductionHelper<Ret (Class::*)(Args...)> : TypeIdentity<Ret(Args...)> {
};
template <typename Class, typename Ret, typename... Args>
struct UFDeductionHelper<Ret (Class::*)(Args...)&> : TypeIdentity<Ret(Args...)> {
};
template <typename Class, typename Ret, typename... Args>
struct UFDeductionHelper<Ret (Class::*)(Args...) const> : TypeIdentity<Ret(Args...)> {
};
template <typename Class, typename Ret, typename... Args>
struct UFDeductionHelper<Ret (Class::*)(Args...) const&> : TypeIdentity<Ret(Args...)> {
};

/**
 * Deduction guides for UniqueFunction<Sig> that pluck the signature off of function pointers and
 * non-overloaded, non-generic function objects such as lambdas that don't use `auto` arguments.
 */
template <typename Ret, typename... Args>
UniqueFunction(Ret (*)(Args...)) -> UniqueFunction<Ret(Args...)>;
template <typename T, typename Sig = typename UFDeductionHelper<decltype(&T::operator())>::type>
UniqueFunction(T) -> UniqueFunction<Sig>;

template <typename Signature>
bool operator==(const UniqueFunction<Signature>& lhs, std::nullptr_t) noexcept
{
    return !lhs;
}

template <typename Signature>
bool operator!=(const UniqueFunction<Signature>& lhs, std::nullptr_t) noexcept
{
    return static_cast<bool>(lhs);
}

template <typename Signature>
bool operator==(std::nullptr_t, const UniqueFunction<Signature>& rhs) noexcept
{
    return !rhs;
}

template <typename Signature>
bool operator!=(std::nullptr_t, const UniqueFunction<Signature>& rhs) noexcept
{
    return static_cast<bool>(rhs);
}

} // namespace realm::util

#endif // REALM_UTIL_FUNCTIONAL
