#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface EVSCLINotifier : NSObject<NSUserNotificationCenterDelegate>

@property (nonatomic, retain) NSFileHandle *stdinFileHandle;
@property (nonatomic, retain) NSUserNotificationCenter *userNotificationCenter;

- (void)run;

- (void)postMessage:(NSString *)message;

@end

@implementation EVSCLINotifier

- (id)init {
    self = [super init];
    if (!self) { return nil; }

    self.stdinFileHandle = [NSFileHandle fileHandleWithStandardInput];
    self.stdinFileHandle.readabilityHandler = ^(NSFileHandle *fileHandle){
        NSString* rawStr = [[[NSString alloc] initWithData:fileHandle.availableData encoding:NSUTF8StringEncoding] autorelease];
        NSString *str = [rawStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        if (str.length == 0) { return; }
        [self postMessage:str];
    };

    self.userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    self.userNotificationCenter.delegate = self;

    return self;
}

- (void)dealloc {
    self.stdinFileHandle = nil;

    self.userNotificationCenter.delegate = nil;
    self.userNotificationCenter = nil;

    [super dealloc];
}

- (void)run {
    [self.stdinFileHandle waitForDataInBackgroundAndNotify];
    [[NSRunLoop currentRunLoop] run];
}

- (void)postMessage:(NSString *)message {
    NSUserNotification *notification = [[[NSUserNotification alloc] init] autorelease];
    notification.title = @"CLI Notifier";
    notification.informativeText = message;

    NSLog(@"scheduling: %@", notification);

    [self.userNotificationCenter scheduleNotification:notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification {
    NSLog(@"delivered: %@", notification);
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    NSLog(@"activated: %@", notification);
}

@end

// don't try this at home
@implementation NSBundle(swizleBundleIdentifier)

- (NSString *)clinotifier__bundleIdentifier
{
    if (self == [NSBundle mainBundle]) {
        // since this app doesn't use NSApplication we cannot pass any
        // arbitary app id, we only can pass some existing app id
        // otherwise notifications will be send to daemon, but not
        // presented to the user
        // radar://11956694
        return @"com.apple.finder";
    } else {
        // after swizzling original method will have the same name
        // as current
        return [self clinotifier__bundleIdentifier]; 
    }
}

@end

int main(int argc, char const *argv[])
{
    // it turns out that NSUserNotificationCenter doesn't want to work with CLI Foundation apps
    // and the only reason for this is the app identifier
    // I haven't found a way to 'fake' Info.plist, pass a dictionary directly to NSBundle construction
    // so I just swizzled -[NSBundle bundleIdentifier] method for [NSBundle mainBundle]
    Class class = objc_getClass("NSBundle");
    method_exchangeImplementations(class_getInstanceMethod(class, @selector(bundleIdentifier)),
                                   class_getInstanceMethod(class, @selector(clinotifier__bundleIdentifier)));

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    EVSCLINotifier *cliNotifier = [[[EVSCLINotifier alloc] init] autorelease];
    [cliNotifier run];

    [pool drain];
    return 0;
}