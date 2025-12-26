#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImGuiDrawView : UIViewController

+ (instancetype)sharedInstance; 
+ (void)showChange:(BOOL)open;


@end

NS_ASSUME_NONNULL_END