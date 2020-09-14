#include "supportedandroidabis.h"

bool AndroidAbiComparer::operator()(const std::string &a, const std::string &b) const {
    return
#if defined(__i386__) || defined(__x86_64__)
    a.length() && a.at(0) == 'x' && b.length() && b.at(0) != 'x'
#elif defined(__arm__) || defined(__aarch64__)
    a.length() && a.at(0) == 'a' && b.length() && b.at(0) != 'a'
#endif
    || a.find("64")
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
    std::string::npos;
}

std::size_t AndroidAbiComparer::operator()(const std::string &a) const {
    return std::hash<std::string>()(a);
}

#ifndef __APPLE__
#if defined(__i386__) || defined(__x86_64__)
#include "cpuid.h"
#endif
#include <sstream>
#include <vector>

std::map<std::string, std::string, AndroidAbiComparer> SupportedAndroidAbis::getAbis() {
    std::map<std::string, std::string, AndroidAbiComparer> abis = { };
#if defined(__i386__) || defined(__x86_64__)
    CpuId cpuid;
    bool hasssse3 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSSE3);
    bool hassse41 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSE41);
    bool hassse42 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSE42);
    bool haspopcnt = cpuid.queryFeatureFlag(CpuId::FeatureFlag::POPCNT);
    if (hasssse3 && hassse41 && hassse42 && haspopcnt) {
#if !defined(DISABLE_64BIT) && !defined(__i386__)
        abis["x86_64"] = "";
#else
        abis["x86_64"] = "Disabled in this Launcher Release, please download a different distribution";
#endif
    } else {
        std::stringstream error;
        error << "The CPU of this Computer is to old for running Android x86_64 Games<br/>";
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
        abis["x86_64"] = error.str();
    }
    if (hasssse3) {
#if !defined(DISABLE_32BIT)
        abis["x86"] = "";
#else
        abis["x86"] = "Disabled in this Launcher Release, please download a different distribution";
#endif
    } else {
        std::stringstream error;
        error << "The CPU of this Computer is to old for running Android x86 Games<br/>";
#ifdef DISABLE_32BIT
        error << "Disabled in this Launcher Release, please download a different distribution<br/>";
#endif
        error << "Android expect the following unavailable Instruction Sets to be available:<br/>";
        std::vector<std::string> missing;
        if (!hasssse3) {
            missing.push_back("SSSE3");
        }
        for (size_t i = 0; i < missing.size(); i++) {
            if (i) {
                error << ", ";
            }
            error << missing[i];
        }
        abis["x86"] = error.str();
    }
    abis["armeabi-v7a"] = "Not an armv7 System";
    abis["arm64-v8a"] = "Not an aarch64 System";
#elif defined(__arm__) || defined(__aarch64__)
#if defined(__aarch64__)
#if !defined(DISABLE_64BIT)
        abis["arm64-v8a"] = "";
#else
        abis["arm64-v8a"] = "Disabled in this Launcher Release, not supported yet";
#endif
    abis["x86"] = "Not a x86 System";
    abis["x86_64"] = "Not a x86_64 System";
#else
    abis["arm64-v8a"] = "Not an aarch64 System";
    abis["x86"] = "Not a x86 System";
    abis["x86_64"] = "Not a x86_64 System";
#endif
#if !defined(DISABLE_32BIT)
        abis["armeabi-v7a"] = "";
#else
        abis["armeabi-v7a"] = "Disabled in this Launcher Release, please download a different distribution";
#endif
#endif
    return abis;
}
#endif