#import "CTRegion.h"
#import "CTConfig.h"

static NSDictionary *gCurrent = nil;

NSString *CTFlag(NSString *code) {
    if (code.length < 2) return @"";
    NSMutableString *s = [NSMutableString string];
    for (int i = 0; i < 2; i++) {
        uint32_t cp = 0x1F1E6 + ([code characterAtIndex:i] - 'A');
        NSString *c = [[NSString alloc] initWithBytes:&cp length:4 encoding:NSUTF32LittleEndianStringEncoding];
        if (c) [s appendString:c];
    }
    return s;
}

@implementation CTRegion

+ (NSArray<NSDictionary *> *)all {
    static NSArray *a;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        a = @[
            @{@"code":@"US", @"name":@"США", @"mcc":@"310", @"mnc":@"260", @"carrier":@"T-Mobile"},
            @{@"code":@"GB", @"name":@"Великобритания", @"mcc":@"234", @"mnc":@"15", @"carrier":@"Vodafone"},
            @{@"code":@"DE", @"name":@"Германия", @"mcc":@"262", @"mnc":@"01", @"carrier":@"Telekom"},
            @{@"code":@"FR", @"name":@"Франция", @"mcc":@"208", @"mnc":@"01", @"carrier":@"Orange"},
            @{@"code":@"ES", @"name":@"Испания", @"mcc":@"214", @"mnc":@"07", @"carrier":@"Movistar"},
            @{@"code":@"IT", @"name":@"Италия", @"mcc":@"222", @"mnc":@"01", @"carrier":@"TIM"},
            @{@"code":@"NL", @"name":@"Нидерланды", @"mcc":@"204", @"mnc":@"08", @"carrier":@"KPN"},
            @{@"code":@"PL", @"name":@"Польша", @"mcc":@"260", @"mnc":@"06", @"carrier":@"Play"},
            @{@"code":@"UA", @"name":@"Украина", @"mcc":@"255", @"mnc":@"01", @"carrier":@"Vodafone"},
            @{@"code":@"TR", @"name":@"Турция", @"mcc":@"286", @"mnc":@"01", @"carrier":@"Turkcell"},
            @{@"code":@"BR", @"name":@"Бразилия", @"mcc":@"724", @"mnc":@"05", @"carrier":@"Claro"},
            @{@"code":@"MX", @"name":@"Мексика", @"mcc":@"334", @"mnc":@"020", @"carrier":@"Telcel"},
            @{@"code":@"AR", @"name":@"Аргентина", @"mcc":@"722", @"mnc":@"310", @"carrier":@"Claro"},
            @{@"code":@"CA", @"name":@"Канада", @"mcc":@"302", @"mnc":@"720", @"carrier":@"Rogers"},
            @{@"code":@"AU", @"name":@"Австралия", @"mcc":@"505", @"mnc":@"01", @"carrier":@"Telstra"},
            @{@"code":@"JP", @"name":@"Япония", @"mcc":@"440", @"mnc":@"10", @"carrier":@"NTT DOCOMO"},
            @{@"code":@"KR", @"name":@"Южная Корея", @"mcc":@"450", @"mnc":@"05", @"carrier":@"SKT"},
            @{@"code":@"ID", @"name":@"Индонезия", @"mcc":@"510", @"mnc":@"10", @"carrier":@"Telkomsel"},
            @{@"code":@"TH", @"name":@"Таиланд", @"mcc":@"520", @"mnc":@"01", @"carrier":@"AIS"},
            @{@"code":@"VN", @"name":@"Вьетнам", @"mcc":@"452", @"mnc":@"04", @"carrier":@"Viettel"},
            @{@"code":@"PH", @"name":@"Филиппины", @"mcc":@"515", @"mnc":@"02", @"carrier":@"Globe"},
            @{@"code":@"SA", @"name":@"Саудовская Аравия", @"mcc":@"420", @"mnc":@"01", @"carrier":@"STC"},
            @{@"code":@"AE", @"name":@"ОАЭ", @"mcc":@"424", @"mnc":@"02", @"carrier":@"Etisalat"},
            @{@"code":@"EG", @"name":@"Египет", @"mcc":@"602", @"mnc":@"02", @"carrier":@"Vodafone"},
            @{@"code":@"KZ", @"name":@"Казахстан", @"mcc":@"401", @"mnc":@"02", @"carrier":@"Kcell"},
            @{@"code":@"UZ", @"name":@"Узбекистан", @"mcc":@"434", @"mnc":@"04", @"carrier":@"Beeline"}
        ];
    });
    return a;
}

+ (NSDictionary *)byCode:(NSString *)code {
    for (NSDictionary *r in [self all]) {
        if ([r[@"code"] isEqualToString:code]) return r;
    }
    return nil;
}

+ (NSDictionary *)current { return gCurrent; }

+ (void)reload {
    if (!CTBool(@"region_on", NO)) { gCurrent = nil; return; }
    gCurrent = [self byCode:CTStr(@"region", @"US")];
}

@end
