#include "launcherapp.h"

#import <AppKit/AppKit.h>

void LauncherApp::setVisibleInDock(bool visible) {
    if (!visible)
        [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];
    else
        [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
}

void LauncherApp::fixWindowStyle() {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSWindow *win in [NSApp windows]) {
            if (win.styleMask & NSWindowStyleMaskFullSizeContentView)
                win.styleMask &= ~NSWindowStyleMaskFullSizeContentView;
            [[win standardWindowButton:NSWindowCloseButton] setEnabled:YES];
            [[win standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
            [[win standardWindowButton:NSWindowZoomButton] setEnabled:YES];
            win.titlebarAppearsTransparent = NO;
        }
    });
}