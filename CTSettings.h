#import <UIKit/UIKit.h>

/// Переключатель в стиле Material You
@interface CTToggle : UIControl
@property (nonatomic, assign) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

@interface CTSettings : NSObject
+ (void)presentFrom:(UIViewController *)host;
@end
