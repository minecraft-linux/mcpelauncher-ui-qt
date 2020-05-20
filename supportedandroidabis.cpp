#include "supportedandroidabis.h"
#ifndef __APPLE__
#if defined(__i386__) || defined(__x86_64__)
#include "cpuid.h"
#endif

std::vector<std::string> SupportedAndroidAbis::getSupportedAbis() {
    std::vector<std::string> abis = { };
#if defined(__i386__) || defined(__x86_64__)
    CpuId cpuid;
    bool hasssse3 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSSE3);
    bool hassse41 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSE41);
    bool hassse42 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSE42);
    bool haspopcnt = cpuid.queryFeatureFlag(CpuId::FeatureFlag::POPCNT);
#if defined(__x86_64__) && !defined(DISABLE_64BIT)
    if (hasssse3 && hassse41 && hassse42 && haspopcnt) {
        abis.emplace_back("x86_64");
    }
#endif
    if (hasssse3) {
        abis.emplace_back("x86");
    }
#endif
#if defined(__arm__) || defined(__aarch64__)
#if defined(__aarch64__) && !defined(DISABLE_64BIT)
    abis.emplace_back("arm64-v8a");
#endif
    abis.emplace_back("armeabi-v7a");
#endif
#ifdef PREFER_32BIT
    std::reverse(abis.begin(), abis.end()); 
#endif
    return abis;
}
#endif

std::vector<std::string> SupportedAndroidAbis::getAbis() {
    return { "armeabi-v7a", "x86", "arm64-v8a", "x86_64" };
}
