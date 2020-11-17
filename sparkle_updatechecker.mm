#include <Cocoa/Cocoa.h>
#include <Sparkle/Sparkle.h>
#include "updatechecker.h"

class SparkleUpdater {
    NSAutoreleasePool* pool;
    SUUpdater * updater;
public:
    SparkleUpdater() {
        NSApplicationLoad();
        pool = [[NSAutoreleasePool alloc] init];
        updater = nil;
    }
    void initSparkleUpdater() {
        updater = [SUUpdater sharedUpdater];
	    [updater retain];
        NSURL* url = [NSURL URLWithString:
			[NSString stringWithUTF8String: SPARKLE_UPDATE_CHECK_URL]];
	    [updater setFeedURL: url];
        [updater checkForUpdatesInBackground];
    }
    void checkForUpdates() {
        if (!updater) {
            initSparkleUpdater();
        }
        [updater checkForUpdates:nil];
    }
    ~SparkleUpdater() {
        if (updater) {
            [updater release];
        }
        [pool release];
    }
};

static SparkleUpdater sparkleUpdater;

void UpdateChecker::checkForUpdates() {
    sparkleUpdater.checkForUpdates();
}
