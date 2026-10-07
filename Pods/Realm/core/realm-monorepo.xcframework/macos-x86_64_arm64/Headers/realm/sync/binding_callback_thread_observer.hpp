////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#ifndef REALM_OS_BINDING_CALLBACK_THREAD_OBSERVER_HPP
#define REALM_OS_BINDING_CALLBACK_THREAD_OBSERVER_HPP

#include <exception>
#include <functional>
#include <optional>


namespace realm {
// Interface for bindings interested in registering callbacks before/after the ObjectStore thread runs.
// This is for example helpful to attach/detach the pthread to the JavaVM in order to be able to perform JNI calls.
struct BindingCallbackThreadObserver {
    using NotificationCallback = std::function<void()>;
    using ErrorCallback = std::function<bool(const std::exception&)>;

    // Create a BindingCallbackThreadObserver that can be used in SyncClientConfig
    BindingCallbackThreadObserver(std::optional<NotificationCallback>&& did_create_thread,
                                  std::optional<NotificationCallback>&& will_destroy_thread,
                                  std::optional<ErrorCallback>&& error_handler)
        : m_create_thread_callback{std::move(did_create_thread)}
        , m_destroy_thread_callback{std::move(will_destroy_thread)}
        , m_handle_error_callback{std::move(error_handler)}
    {
    }

    virtual ~BindingCallbackThreadObserver() = default;

    ///
    /// Execution Functions - check for a valid instance and if the function was set
    ///

    // Call the stored create thread callback function with the id of this thread
    // Can be overridden to provide a custom implementation
    virtual void did_create_thread()
    {
        if (m_create_thread_callback) {
            (*m_create_thread_callback)();
        }
    }

    // Call the stored destroy thread callback function with the id of this thread
    // Can be overridden to provide a custom implementation
    virtual void will_destroy_thread()
    {
        if (m_destroy_thread_callback) {
            (*m_destroy_thread_callback)();
        }
    }

    // Call the stored handle error callback function with the id of this thread
    // IMPORTANT: If a function is supplied that handles the exception, it must
    // call abort() or cause the application to crash since the SyncClient will
    // be in a bad state if this occurs and will not be able to shut down properly.
    // Can be overridden to provide a custom implementation
    // Return true if the exception was handled by this function, otherwise false
    virtual bool handle_error(const std::exception& e)
    {
        if (!m_handle_error_callback)
            return false;

        return (*m_handle_error_callback)(e);
    }

    // Return true if this event loop observer has a handle error callback defined
    virtual bool has_handle_error()
    {
        return bool(m_handle_error_callback);
    }

protected:
    // Default constructor
    BindingCallbackThreadObserver() = default;

    std::optional<NotificationCallback> m_create_thread_callback;
    std::optional<NotificationCallback> m_destroy_thread_callback;
    std::optional<ErrorCallback> m_handle_error_callback;
};

} // namespace realm

#endif // REALM_OS_BINDING_CALLBACK_THREAD_OBSERVER_HPP
