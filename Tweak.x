#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>
#import "CTConfig.h"
#import "CTRegion.h"
#import "CTOverlay.h"

// Убирает трекинг из ссылок TikTok при копировании
static NSString *CleanLink(NSString *s) {
    if (!CTBool(@"clean", NO) || ![s hasPrefix:@"http"] || ![s containsString:@"tiktok.com"] || [s containsString:@"\n"] || [s containsString:@" "]) return s;
    NSURLComponents *c = [NSURLComponents componentsWithString:s];
    if (!c) return s;
    c.query = nil;
    c.fragment = nil;
    return c.string ?: s;
}

// ---- Подмена региона: оператор SIM
%hook CTCarrier
- (NSString *)isoCountryCode {
    NSDictionary *r = [CTRegion current];
    return r ? [r[@"code"] lowercaseString] : %orig;
}
- (NSString *)mobileCountryCode {
    NSDictionary *r = [CTRegion current];
    return r ? r[@"mcc"] : %orig;
}
- (NSString *)mobileNetworkCode {
    NSDictionary *r = [CTRegion current];
    return r ? r[@"mnc"] : %orig;
}
- (NSString *)carrierName {
    NSDictionary *r = [CTRegion current];
    return r ? r[@"carrier"] : %orig;
}
%end

// ---- Подмена региона: региональные настройки (язык остаётся прежним)
%hook NSLocale
+ (id)currentLocale {
    id orig = %orig;
    NSDictionary *r = [CTRegion current];
    if (!r) return orig;
    NSString *lang = [orig objectForKey:NSLocaleLanguageCode] ?: @"en";
    return [NSLocale localeWithLocaleIdentifier:[NSString stringWithFormat:@"%@_%@", lang, r[@"code"]]];
}
+ (id)autoupdatingCurrentLocale {
    id orig = %orig;
    NSDictionary *r = [CTRegion current];
    if (!r) return orig;
    NSString *lang = [orig objectForKey:NSLocaleLanguageCode] ?: @"en";
    return [NSLocale localeWithLocaleIdentifier:[NSString stringWithFormat:@"%@_%@", lang, r[@"code"]]];
}
%end

// ---- Чистые ссылки
%hook UIPasteboard
- (void)setString:(NSString *)string {
    %orig(string ? CleanLink(string) : string);
}
- (void)setURL:(NSURL *)url {
    if (url && CTBool(@"clean", NO)) {
        NSURL *clean = [NSURL URLWithString:CleanLink(url.absoluteString)];
        %orig(clean ?: url);
    } else {
        %orig;
    }
}
%end

%ctor {
    [CTRegion reload];
    %init;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *n) {
        [[CTOverlay shared] start];
    }];
}
