#import <UIKit/UIKit.h>

/// Нарисованный Крот 60x48: ходит, радуется, ест, спит
@interface CTMoleView : UIView
@property (nonatomic, assign) BOOL facingRight;
- (void)startWalking;
- (void)stopWalking;
- (void)happy;
- (void)eat;
- (void)setSleeping:(BOOL)sleeping;
@end
