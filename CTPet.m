#import "CTPet.h"
#import "CTConfig.h"

// Значения хранятся вместе со временем записи, текущее считается с учётом убывания
static NSInteger Eff(NSString *key, double perMinute) {
    NSInteger stored = CTInt(key, 70);
    NSInteger t0 = CTInt([key stringByAppendingString:@"_t"], (NSInteger)[[NSDate date] timeIntervalSince1970]);
    double minutes = ([[NSDate date] timeIntervalSince1970] - t0) / 60.0;
    NSInteger v = stored - (NSInteger)(minutes * perMinute);
    return v < 0 ? 0 : (v > 100 ? 100 : v);
}

static void Put(NSString *key, NSInteger v) {
    v = v < 0 ? 0 : (v > 100 ? 100 : v);
    CTSetIntQuiet(key, v);
    CTSetIntQuiet([key stringByAppendingString:@"_t"], (NSInteger)[[NSDate date] timeIntervalSince1970]);
}

@implementation CTPet

+ (NSString *)name { return CTStr(@"pet_name", @"Крот"); }
+ (void)setName:(NSString *)name { if (name.length) CTSetStr(@"pet_name", name); }
+ (NSInteger)food { return Eff(@"pet_food", 0.3); }
+ (NSInteger)joy { return Eff(@"pet_joy", 0.25); }
+ (NSInteger)coins { return CTInt(@"pet_coins", 2); }
+ (void)addCoins:(NSInteger)n { CTSetIntQuiet(@"pet_coins", [self coins] + n); }

+ (void)pet {
    Put(@"pet_joy", [self joy] + 8);
}

+ (BOOL)feed {
    if ([self coins] < 1) return NO;
    CTSetIntQuiet(@"pet_coins", [self coins] - 1);
    Put(@"pet_food", [self food] + 25);
    Put(@"pet_joy", [self joy] + 5);
    return YES;
}

+ (NSString *)moodEmoji {
    NSInteger m = ([self food] + [self joy]) / 2;
    if (m > 70) return @"😊";
    if (m > 40) return @"😐";
    if (m > 15) return @"😟";
    return @"😢";
}

+ (NSString *)moodText {
    NSInteger m = ([self food] + [self joy]) / 2;
    if (m > 70) return @"Всё отлично";
    if (m > 40) return @"Нормально";
    if (m > 15) return @"Грустит";
    return @"Очень голодный и грустный";
}

+ (NSString *)phrase {
    NSArray *p = @[
        @"Привет! Я Крот 🐹",
        @"Погладь меня!",
        @"Хочу печеньку 🍪",
        @"Не забывай моргать 👀",
        @"Попей водички 💧",
        @"Классное видео!",
        @"Я копаю нору под ленту… 🕳️",
        @"Давай немного отдохнём?"
    ];
    return p[arc4random_uniform((uint32_t)p.count)];
}

@end
