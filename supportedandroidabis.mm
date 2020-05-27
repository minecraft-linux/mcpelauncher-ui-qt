#include <Foundation/NSProcessInfo.h>
#include "supportedandroidabis.h"
#include "cpuid.h"

std::vector<std::string> SupportedAndroidAbis::getSupportedAbis() {
    CpuId cpuid;
    bool hasssse3 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSSE3);
    bool hassse41 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSE41);
    bool hassse42 = cpuid.queryFeatureFlag(CpuId::FeatureFlag::SSE42);
    bool haspopcnt = cpuid.queryFeatureFlag(CpuId::FeatureFlag::POPCNT);
    std::vector<std::string> abis;
#if !defined(DISABLE_64BIT)
    if (hasssse3 && hassse41 && hassse42 && haspopcnt) {
        abis.emplace_back("x86_64");
    }
#endif
#if !defined(DISABLE_32BIT)
    if (hasssse3 && ![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 10, .minorVersion = 15, .patchVersion = 0}]) {
        abis.emplace_back("x86");
    }
#endif
    return abis;
}
