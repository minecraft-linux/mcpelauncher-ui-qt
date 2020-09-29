#include "supportedandroidabis.h"

bool AndroidAbiComparer::operator()(const std::string &a, const std::string &b) const {
    return (
#if defined(__i386__) || defined(__x86_64__)
    a.length() && a.at(0) == 'x' && b.length() && b.at(0) != 'x'
#elif defined(__arm__) || defined(__aarch64__)
    a.length() && a.at(0) == 'a' && b.length() && b.at(0) != 'a'
#endif
    ) || (a.find("64")
#ifdef PREFER_32BIT
    ==
#else
    !=
#endif
    std::string::npos && b.find("64")
#ifdef PREFER_32BIT
    !=
#else
    ==
#endif
    std::string::npos);
}

std::size_t AndroidAbiComparer::operator()(const std::string &a) const {
    return std::hash<std::string>()(a);
}

#if defined(__i386__) || defined(__x86_64__)
#include "cpuid.h"
#endif
#include <sstream>
#include <vector>

#ifndef __APPLE__
bool Supports32Bit() {
    // ToDo really check it
    return true;
}
#endif

std::map<std::string, SupportReport, AndroidAbiComparer> SupportedAndroidAbis::getAbis() {
    std::map<std::string, SupportReport, AndroidAbiComparer> abis = { };
#if defined(__i386__) || defined(__x86_64__)
    CpuId cpuid;
    bool hasssse3 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSSE3);
    bool hassse41 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSE41);
    bool hassse42 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSE42);
    bool haspopcnt = cpuid.queryFeatureFlag(CpuId::FeatureFlag::POPCNT);
    if (hasssse3 && hassse41 && hassse42 && haspopcnt) {
#if !defined(DISABLE_64BIT) && !defined(__i386__)
        abis["x86_64"] = { .compatible = true, .launchername = "mcpelauncher-client" };
#else
        abis["x86_64"] = { .compatible = false, .details = "Disabled in this Launcher Release, please download a different distribution" };
#endif
    } else {
        std::stringstream error;
        error << "Your Computer is to old for running Android x86_64 64bit Games<br/>";
#if defined(DISABLE_64BIT) || defined(__i386__)
        error << "Disabled in this Launcher Release, please download a different distribution<br/>";
#endif
        error << "Android expect the following unavailable Instruction Sets to be available:<br/>";
        std::vector<std::string> missing;
        if (!hasssse3) {
            missing.push_back("SSSE3");
        }
        if (!hassse41) {
            missing.push_back("SSE4.1");
        }
        if (!hassse42) {
            missing.push_back("SSE4.2");
        }
        if (!haspopcnt) {
            missing.push_back("POPCNT");
        }
        for (size_t i = 0; i < missing.size(); i++) {
            if (i) {
                error << ", ";
            }
            error << missing[i];
        }
        abis["x86_64"] = { .compatible = false, .launchername = "mcpelauncher-client", .details = error.str() };
    }
    auto&& x86 = abis["x86"];
    x86.launchername = "mcpelauncher-client"
#if !defined(DISABLE_64BIT) || !defined(__i386__)
        "32"
#endif
    ;
    if (hasssse3 && Supports32Bit()) {
#if !defined(DISABLE_32BIT)
        x86.compatible = true;
#else
        x86.compatible = false;
        x86.details = "Disabled in this Launcher Release, please download a different distribution";
#endif
    } else {
        std::stringstream error;
        if (!Supports32Bit()) {
            x86.details = "Your Operating System doesn't support (old) x86 32bit games<br/>";
        }
        if(!hasssse3) {
            error << "Your Computer is to old for running Android x86 32bit Games<br/>";
#ifdef DISABLE_32BIT
            error << "Disabled in this Launcher Release, please download a different distribution<br/>";
#endif
            error << "Android expect the following unavailable Instruction Sets to be available:<br/>";
            error << "SSSE3<br/>";
        }
        x86.compatible = false;
        x86.details = error.str();
    }
    abis["armeabi-v7a"] = { .compatible = false, .launchername = "mcpelauncher-client-armeabi-v7a", .details ="Not an armv7 System"};
    abis["arm64-v8a"] = { .compatible = false, .launchername = "mcpelauncher-client-arm64-v8a", .details = "Not an aarch64 System"};
#elif defined(__arm__) || defined(__aarch64__)
    auto&& arm = abis["armeabi-v7a"];
    arm.launchername = "mcpelauncher-client"
#if !defined(DISABLE_64BIT) || !defined(__i386__)
        "32"
#endif
    ;
#if defined(__aarch64__)
#if !defined(DISABLE_64BIT)
        abis["arm64-v8a"].compatible = true;
#else
        abis["arm64-v8a"].compatible = false;
        abis["arm64-v8a"].details = "Disabled in this Launcher Release, not supported yet";
#endif
    abis["x86"] = { .compatible = false, .launchername = "mcpelauncher-client-x86", .details ="Not a x86 System"};
    abis["x86_64"] = { .compatible = false, .launchername = "mcpelauncher-client-x86_64", .details = "Not a x86_64 System"};
#else
    abis["arm64-v8a"] = { .compatible = false, .launchername = "mcpelauncher-client-arm64-v8a", .details = "Not an aarch64 System"};
    abis["x86"] = { .compatible = false, .launchername = "mcpelauncher-client-x86", .details ="Not a x86 System"};
    abis["x86_64"] = { .compatible = false, .launchername = "mcpelauncher-client-x86_64", .details = "Not a x86_64 System"};
#endif
#if !defined(DISABLE_32BIT)
        arm.compatible = true;
#else
        arm.compatible = false;
        arm.details = "Disabled in this Launcher Release, please download a different distribution";
#endif
#endif
    return abis;
}