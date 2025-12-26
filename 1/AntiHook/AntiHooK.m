#import <mach/mach.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import "AntiHooKz.h"
#import "AntiHooK.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>

@interface NemSelf()
@property (nonatomic, weak) NSTimer *NemG;
@end

BOOL AntiHooK = NO;

static ssize_t (*orig_send)(int, const void *, size_t, int);
ssize_t hook_send(int a, const void *b, size_t c, int d) {
    if (AntiHooK) {
        return 0;
    } else {
        return orig_send(a, b, c, d);
    }
}

@implementation NemSelf

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NemSelf *view = [NemSelf Timer];
        [view start];
        [[[[UIApplication sharedApplication] windows] lastObject] addSubview:view];
    });
}

+ (instancetype)Timer {
    return [[NemSelf alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)Shin {
    AntiHooK = YES;
    rebind_symbols((struct rebinding[1]){{"send", hook_send, (void*)&orig_send}}, 1);
}

- (void)start {
    self.NemG.fireDate = [NSDate distantPast];
}

- (NSTimer *)NemG {
    if (!_NemG) {
        _NemG = [NSTimer scheduledTimerWithTimeInterval:3
                                                 repeats:YES
                                                   block:^(NSTimer * _Nonnull timer) {
            if (AntiHooK) {
                [self Shin];
            }
        }];
    }
    return _NemG;
}

@end
