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
        [updater checkForUpdatesInBackground];
    }
    ~SparkleUpdater() {
        if (updater) {
            [updater release];
        }
        [pool release];
    }
};

static SparkleUpdater sparkleUpdater;

void UpdateChecker::sendRequest() {
    sparkleUpdater.initSparkleUpdater();
}