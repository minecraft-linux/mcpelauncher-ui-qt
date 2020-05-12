#include "launcherapp.h"

#import <AppKit/AppKit.h>

void LauncherApp::setVisibleInDock(bool visible) {
    if (!visible)
        [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];
    else
        [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
}