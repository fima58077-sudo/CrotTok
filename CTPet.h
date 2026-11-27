#import <Foundation/Foundation.h>

/// Питомец Крот: сытость и настроение со временем падают, за видео копятся печеньки
@interface CTPet : NSObject
+ (NSString *)name;
+ (void)setName:(NSString *)name;
+ (NSInteger)food;
+ (NSInteger)joy;
+ (NSInteger)coins;
+ (void)addCoins:(NSInteger)n;
+ (void)pet;
+ (BOOL)feed;
+ (NSString *)moodEmoji;
+ (NSString *)moodText;
+ (NSString *)phrase;
@end
