#include <Foundation/NSProcessInfo.h>
#include "supportedandroidabis.h"

bool Supports32Bit() {
    return ![[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 10, .minorVersion = 15, .patchVersion = 0}];
}