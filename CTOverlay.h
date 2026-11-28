#import <UIKit/UIKit.h>

@interface CTOverlay : NSObject
+ (instancetype)shared;
- (void)start;
- (void)petPet;
- (void)petFeed;
- (void)hidePetForHour;
- (void)fireJoke;
- (void)clearCache;
- (void)toast:(NSString *)text;
- (void)say:(NSString *)text;
@end
