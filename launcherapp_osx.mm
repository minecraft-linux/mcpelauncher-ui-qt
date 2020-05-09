#include "launcherapp.h"

#import <AppKit/AppKit.h>

void LauncherApp::setVisibleInDock(bool visible) {
    if (!visible)
        [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];
    else
        [NSApp setActivationPolicy: NSApplicationActivationPolicyRegular];
}

#ifdef SPARKLE_FEED
class SparkleUpdater {
    NSAutoreleasePool* pool;
    SUUpdater * updater;
    SparkleUpdater() {
        NSApplicationLoad();
        pool = [[NSAutoreleasePool alloc] init];
        updater = [SUUpdater sharedUpdater];
	    [updater retain];
        NSURL* url = [NSURL URLWithString:
			[NSString stringWithUTF8String: SPARKLE_FEED]];
	    [updater setFeedURL: url];
        [updater checkForUpdatesInBackground];
    }
    SparkleUpdater() {
        [updater release];
        [pool release];
    }
};

static SparkleUpdater sparkleUpdater;
#endif