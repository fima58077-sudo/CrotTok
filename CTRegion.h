#import <Foundation/Foundation.h>

NSString *CTFlag(NSString *code);

@interface CTRegion : NSObject
+ (NSArray<NSDictionary *> *)all;
+ (NSDictionary *)byCode:(NSString *)code;
/// Выбранный регион или nil, если подмена выключена (читается из памяти, без обращения к NSUserDefaults)
+ (NSDictionary *)current;
+ (void)reload;
@end
