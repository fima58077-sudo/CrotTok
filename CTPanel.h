#import <UIKit/UIKit.h>

@protocol CTPanelDelegate <NSObject>
- (void)panelClose;
- (void)panelPet;
- (void)panelFeed;
- (void)panelPickRegion;
- (void)panelRename;
- (void)panelClearCache;
- (void)panelThemeChanged;
@end

/// Нижняя панель настроек в стиле Material You
@interface CTPanelView : UIView
@property (nonatomic, weak) id<CTPanelDelegate> delegate;
- (void)reload;
@end
