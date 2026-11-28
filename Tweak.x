#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>
#import "CTConfig.h"
#import "CTRegion.h"
#import "CTOverlay.h"
#import "CTMaterial.h"
#import "CTCore.h"

// Убирает трекинг из ссылок TikTok при копировании
static NSString *CleanLink(NSString *s) {
    if (!CTBool(@"clean", NO) || ![s hasPrefix:@"http"] || ![s containsString:@"tiktok.com"] || [s containsString:@"\n"] || [s containsString:@" "]) return s;
    NSURLComponents *c = [NSURLComponents componentsWithString:s];
    if (!c) return s;
    c.query = nil;
    c.fragment = nil;
    return c.string ?: s;
}

// ================= Сеть: подмена региона =================

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

// ================= Основное: чистые ссылки =================

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

// ================= Оформление: Material You на стандартных элементах =================

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    CTThemeApplyWindow(self);
}
- (void)becomeKeyWindow {
    %orig;
    CTThemeApplyWindow(self);
}
%end

%hook UISwitch
- (void)didMoveToWindow {
    %orig;
    CTThemeApplyControl(self);
}
%end

%hook UISlider
- (void)didMoveToWindow {
    %orig;
    CTThemeApplyControl(self);
}
%end

%hook UIProgressView
- (void)didMoveToWindow {
    %orig;
    CTThemeApplyControl(self);
}
%end

%hook UIPageControl
- (void)didMoveToWindow {
    %orig;
    CTThemeApplyControl(self);
}
%end

%hook UITextField
- (void)didMoveToWindow {
    %orig;
    CTThemeApplyControl(self);
}
- (void)layoutSubviews {
    %orig;
    if (CTBool(@"mat_fields", NO)) CTThemeApplyControl(self);
}
%end

%hook UIAlertController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if (CTBool(@"mat_on", YES)) self.view.tintColor = CTPrimary();
}
%end

// ================= Оформление: форма аватарки =================

%hook UIImageView
- (void)layoutSubviews {
    %orig;
    CTAvatarCheck(self);
}
%end

// ================= Вход в настройки TikTok =================

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    CTInjectCheck(self);
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
