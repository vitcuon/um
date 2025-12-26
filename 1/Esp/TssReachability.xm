// TssReachability.xm
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <dobby.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>

// MARK: - Fake SCNetworkReachability Functions
// ============================================

static SCNetworkReachabilityRef (*orig_CreateWithAddress)(CFAllocatorRef, const struct sockaddr *);
static SCNetworkReachabilityRef fake_CreateWithAddress(CFAllocatorRef allocator, const struct sockaddr *address) {
    return NULL; // 
}

static SCNetworkReachabilityRef (*orig_CreateWithName)(CFAllocatorRef, const char *);
static SCNetworkReachabilityRef fake_CreateWithName(CFAllocatorRef allocator, const char *hostname) {
    return NULL; // Return NULL
}

// 
static Boolean (*orig_GetFlags)(SCNetworkReachabilityRef, SCNetworkReachabilityFlags *);
static Boolean fake_GetFlags(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags) {
    *flags = kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsIsWWAN;
    return TRUE; 
}

// 3. Hook management functions callback
static Boolean (*orig_SetCallback)(SCNetworkReachabilityRef, SCNetworkReachabilityCallBack, SCNetworkReachabilityContext *);
static Boolean fake_SetCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityCallBack callback, SCNetworkReachabilityContext *context) {
    return FALSE; 
}

// MARK: - Hook Class Methods
// =========================

__attribute__((constructor)) static void disable_tss_network() {
    @autoreleasepool {
        const char *image_name = "Frameworks/anogs.framework/anogs";
        
        void *symbols[] = {
            DobbySymbolResolver(image_name, "_SCNetworkReachabilityCreateWithAddress"),
            DobbySymbolResolver(image_name, "_SCNetworkReachabilityCreateWithName"),
            DobbySymbolResolver(image_name, "_SCNetworkReachabilityGetFlags"),
            DobbySymbolResolver(image_name, "_SCNetworkReachabilitySetCallback")
        };
        
        for (int i = 0; i < sizeof(symbols)/sizeof(symbols[0]); i++) {
            if (!symbols[i]) continue;
            
            switch(i) {
                case 0:
                    DobbyHook(symbols[i], (void *)fake_CreateWithAddress, (void **)&orig_CreateWithAddress);
                    break;
                case 1:
                    DobbyHook(symbols[i], (void *)fake_CreateWithName, (void **)&orig_CreateWithName);
                    break;
                case 2:
                    DobbyHook(symbols[i], (void *)fake_GetFlags, (void **)&orig_GetFlags);
                    break;
                case 3:
                    DobbyHook(symbols[i], (void *)fake_SetCallback, (void **)&orig_SetCallback);
                    break;
            }
        }
        
        // Hook method Objective-C
        Class TssClass = objc_getClass("TssReachability");
        if (TssClass) {
            Method methods[] = {
                class_getInstanceMethod(TssClass, @selector(startNotifier)),
                class_getInstanceMethod(TssClass, @selector(currentReachabilityStatus))
            };
            
            for (int i = 0; i < 2; i++) {
                if (!methods[i]) continue;
                
                IMP original = method_getImplementation(methods[i]);
                IMP replacement = NULL;
                
                if (i == 0) { // startNotifier
                    replacement = imp_implementationWithBlock(^BOOL(id self) {
                        return NO; 
                    });
                } else if (i == 1) { // currentReachabilityStatus
                    replacement = imp_implementationWithBlock(^long long(id self) {
                        return 2; // Return ReachableViaWWAN
                    });
                }
                
                if (replacement) method_setImplementation(methods[i], replacement);
            }
        }
    }
}