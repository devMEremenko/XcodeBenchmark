#ifndef REALM_UTIL_PLATFORM_INFO_HPP
#define REALM_UTIL_PLATFORM_INFO_HPP

#include <string>


namespace realm {
namespace util {

/// Get a description of the current system platform.
///
/// Returns a space-separated concatenation of `osname`, `sysname`, `release`,
/// `version`, and `machine` as returned by get_platform_info(PlatformInfo&).
std::string get_platform_info();


struct PlatformInfo {
    std::string osname;  ///< Equivalent to `uname -o` (Linux).
    std::string sysname; ///< Equivalent to `uname -s`.
    std::string release; ///< Equivalent to `uname -r`.
    std::string version; ///< Equivalent to `uname -v`.
    std::string machine; ///< Equivalent to `uname -m`.
};

/// Get a description of the current system platform.
void get_platform_info(PlatformInfo&);


// Implementation

inline std::string get_platform_info()
{
    PlatformInfo info;
    get_platform_info(info); // Throws
    return (info.osname + " " + info.sysname + " " + info.release + " " + info.version + " " +
            info.machine); // Throws
}

inline std::string get_library_platform()
{
#if REALM_ANDROID
    return "Android";
#elif REALM_WINDOWS
    return "Windows";
#elif REALM_UWP
    return "UWP";
#elif REALM_MACCATALYST // test Catalyst first because it's a subset of iOS
    return "Mac Catalyst";
#elif REALM_IOS
    return "iOS";
#elif REALM_TVOS
    return "tvOS";
#elif REALM_WATCHOS
    return "watchOS";
#elif REALM_PLATFORM_APPLE
    return "macOS";
#elif REALM_LINUX
    return "Linux";
#endif

    return "unknown";
}

inline std::string get_library_cpu_arch()
{
#if REALM_ARCHITECTURE_ARM32
    return "arm";
#elif REALM_ARCHITECTURE_ARM64
    return "arm64";
#elif REALM_ARCHITECTURE_X86_32
    return "x86";
#elif REALM_ARCHITECTURE_X86_64
    return "x86_64";
#endif

    return "unknown";
}

} // namespace util
} // namespace realm

#endif // REALM_UTIL_PLATFORM_INFO_HPP
