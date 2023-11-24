#include "supportedandroidabis.h"
#include <QObject>
#ifdef __APPLE__
#include <sys/sysctl.h>
#endif

bool AndroidAbiComparer::operator()(const std::string &a, const std::string &b) const {
    // Swap arm / x86 order for arm64 macbook running x86_64 GUI
    auto native = !ProcessIsTranslated() ? 
#if defined(__i386__) || defined(__x86_64__)
'x' : 'a'
#elif defined(__arm__) || defined(__aarch64__)
'a' : 'x'
#else
#error "Unsupported Platform"
#endif
;
return (a.length() && a.at(0) == native && b.length() && b.at(0) != native) || (a.find("64")
#if defined(PREFER_32BIT) || defined(__i386__) || defined(__arm__) || defined(DISABLE_64BIT)
    ==
#else
    !=
#endif
    std::string::npos && b.find("64")
#if defined(PREFER_32BIT) || defined(__i386__) || defined(__arm__) || defined(DISABLE_64BIT)
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
#if defined(__APPLE__) && defined(__x86_64__) && defined(LAUNCHER_MACOS_HAVE_ARMLAUNCHER)
    if(ProcessIsTranslated()) {
        abis["arm64-v8a"] = { .compatible = true, .launchername = "mcpelauncher-client-arm64-v8a" };
        abis["armeabi-v7a"] = { .compatible = false, .launchername = "mcpelauncher-client-armeabi-v7a", .details = QObject::tr("Not an armv7 System").toStdString() };
        abis["x86"] = { .compatible = false, .launchername = "mcpelauncher-client-x86", .details = QObject::tr("Not a x86 System").toStdString() };
        abis["x86_64"] = { .compatible = false, .launchername = "mcpelauncher-client-x86_64", .details = QObject::tr("The Game crashes under Rosetta 2, since macOS 14. However it used to work between macOS 11 and 13.").toStdString() };
        return abis;
    }
#endif
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
        abis["x86_64"] = { .compatible = false, .launchername = "mcpelauncher-client-x86_64", .details = QObject::tr("Disabled in this Launcher Release, please download a different distribution").toStdString() };
#endif
    } else {
        std::stringstream error;
        error << QObject::tr("Your Computer is to old for running Android x86_64 64bit Games").toStdString() << "<br/>";
#if defined(DISABLE_64BIT) || defined(__i386__)
        error << QObject::tr("Disabled in this Launcher Release, please download a different distribution").toStdString() << "<br/>";
#endif
        error << QObject::tr("Android expect the following unavailable Instruction Sets to be available:").toStdString() << "<br/>";
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
#if !defined(DISABLE_64BIT) && !defined(__i386__)
        "32"
#endif
    ;
    if (hasssse3 && Supports32Bit()) {
#if !defined(DISABLE_32BIT)
        x86.compatible = true;
#else
        x86.compatible = false;
        x86.details = QObject::tr("Disabled in this Launcher Release, please download a different distribution").toStdString();
#endif
    } else {
        std::stringstream error;
        if (!Supports32Bit()) {
            x86.details = QObject::tr("Your Operating System doesn't support (old) x86 32bit games").toStdString();
        }
        if(!hasssse3) {
            error << QObject::tr("Your Computer is to old for running Android x86 32bit Games").toStdString() << "<br/>";
#ifdef DISABLE_32BIT
            error << "Disabled in this Launcher Release, please download a different distribution<br/>";
#endif
            error << QObject::tr("Android expect the following unavailable Instruction Sets to be available:").toStdString() << "<br/>";
            error << "SSSE3<br/>";
        }
        x86.compatible = false;
        x86.details = error.str();
    }
    abis["armeabi-v7a"] = { .compatible = false, .launchername = "mcpelauncher-client-armeabi-v7a", .details = QObject::tr("Not an armv7 System").toStdString() };
    abis["arm64-v8a"] = { .compatible = ProcessIsTranslated() /* Should work on arm64 macbook, while using rosetta */, .launchername = "mcpelauncher-client-arm64-v8a", .details = QObject::tr("Not an aarch64 System").toStdString() };
#elif defined(__arm__) || defined(__aarch64__)
    auto&& arm = abis["armeabi-v7a"];
    arm.launchername = "mcpelauncher-client"
#if !defined(DISABLE_64BIT) && !defined(__arm__)
        "32"
#endif
    ;
#if defined(__aarch64__)
#if !defined(DISABLE_64BIT)
        abis["arm64-v8a"].launchername = "mcpelauncher-client";
        abis["arm64-v8a"].compatible = true;
#else
        abis["arm64-v8a"].launchername = "mcpelauncher-client-arm64-v8a";
        abis["arm64-v8a"].compatible = false;
        abis["arm64-v8a"].details = QObject::tr("Disabled in this Launcher Release").toStdString();
#endif
    abis["x86"] = { .compatible = false, .launchername = "mcpelauncher-client-x86", .details = QObject::tr("Not a x86 System").toStdString() };
    abis["x86_64"] = { .compatible = false, .launchername = "mcpelauncher-client-x86_64", .details = QObject::tr("Not a x86_64 System").toStdString() };
#else
    abis["arm64-v8a"] = { .compatible = false, .launchername = "mcpelauncher-client-arm64-v8a", .details = QObject::tr("Not an aarch64 System").toStdString() };
    abis["x86"] = { .compatible = false, .launchername = "mcpelauncher-client-x86", .details = QObject::tr("Not a x86 System").toStdString() };
    abis["x86_64"] = { .compatible = false, .launchername = "mcpelauncher-client-x86_64", .details = QObject::tr("Not a x86_64 System").toStdString() };
#endif
#if !defined(DISABLE_32BIT)
        arm.compatible = true;
#else
        arm.compatible = false;
        arm.details = QObject::tr("Disabled in this Launcher Release, please download a different distribution").toStdString();
#endif
#endif
    return abis;
}

bool ProcessIsTranslated() {
#if defined(__APPLE__) && defined(__x86_64__) && defined(LAUNCHER_MACOS_HAVE_ARMLAUNCHER)
// Reference https://developer.apple.com/documentation/apple_silicon/about_the_rosetta_translation_environment
// Returns true if x86_64 version runs under arm64 macbook
    int ret = 0;
    size_t size = sizeof(ret);
    return sysctlbyname("sysctl.proc_translated", &ret, &size, NULL, 0) != -1 && ret;
#else
    return 0;
#endif
}
