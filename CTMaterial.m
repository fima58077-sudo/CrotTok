#import "CTMaterial.h"
#import "CTConfig.h"

UIColor *CTHex(unsigned int v) {
    return [UIColor colorWithRed:((v >> 16) & 0xFF) / 255.0
                           green:((v >> 8) & 0xFF) / 255.0
                            blue:(v & 0xFF) / 255.0
                           alpha:1.0];
}

UIColor *CTDyn(unsigned int light, unsigned int dark) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *t) {
        return t.userInterfaceStyle == UIUserInterfaceStyleDark ? CTHex(dark) : CTHex(light);
    }];
}

unsigned int CTMix(unsigned int a, unsigned int b, CGFloat t) {
    unsigned int out = 0;
    for (int s = 16; s >= 0; s -= 8) {
        CGFloat ca = (a >> s) & 0xFF;
        CGFloat cb = (b >> s) & 0xFF;
        unsigned int c = (unsigned int)lround(ca * (1 - t) + cb * t);
        out |= (c << s);
    }
    return out;
}

NSArray<NSDictionary *> *CTPalettes(void) {
    static NSArray *p;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        p = @[
            @{@"p": @0x7E57D1, @"c": @0xEADDFF},
            @{@"p": @0x4F83F1, @"c": @0xD3E3FD},
            @{@"p": @0x2E9E5B, @"c": @0xC4EED0},
            @{@"p": @0xD6407A, @"c": @0xFFD8E4},
            @{@"p": @0xE8710A, @"c": @0xFFE0B2},
            @{@"p": @0x00897B, @"c": @0xC4F0EE},
            @{@"p": @0xD93025, @"c": @0xFAD2CF},
            @{@"p": @0xF9AB00, @"c": @0xFFF1B0}
        ];
    });
    return p;
}

NSInteger CTAccentIndex(void) {
    NSInteger i = CTInt(@"accent", 0);
    NSInteger n = (NSInteger)CTPalettes().count;
    return i < 0 ? 0 : (i >= n ? n - 1 : i);
}

BOOL CTParseHex(NSString *s, unsigned int *out) {
    s = [[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ([s hasPrefix:@"#"]) s = [s substringFromIndex:1];
    if (s.length != 6) return NO;
    NSCharacterSet *hexSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"];
    if ([s rangeOfCharacterFromSet:[hexSet invertedSet]].location != NSNotFound) return NO;
    unsigned int v = 0;
    [[NSScanner scannerWithString:s] scanHexInt:&v];
    if (out) *out = v;
    return YES;
}

NSString *CTHexString(unsigned int v) { return [NSString stringWithFormat:@"%06X", v & 0xFFFFFF]; }

static BOOL Custom(unsigned int *out) {
    NSString *s = CTStr(@"accent_hex", @"");
    return s.length && CTParseHex(s, out);
}

static unsigned int P(void) {
    unsigned int c;
    if (Custom(&c)) return c;
    return [CTPalettes()[CTAccentIndex()][@"p"] unsignedIntValue];
}

static unsigned int C(void) {
    unsigned int c;
    if (Custom(&c)) return CTMix(c, 0xFFFFFF, 0.78);
    return [CTPalettes()[CTAccentIndex()][@"c"] unsignedIntValue];
}

unsigned int CTCurrentPrimaryHex(void) { return P(); }

void CTResetAccent(void) {
    CTSetStr(@"accent_hex", @"");
    CTSetInt(@"accent", 0);
}

UIColor *CTBg(void) { return CTDyn(0xFEF7FF, 0x141218); }
UIColor *CTSurface(void) { return CTDyn(0xF3EDF7, 0x211F26); }
UIColor *CTOnSurface(void) { return CTDyn(0x1D1B20, 0xE6E0E9); }
UIColor *CTOnVar(void) { return CTDyn(0x49454F, 0xCAC4D0); }
UIColor *CTPrimary(void) { return CTDyn(P(), CTMix(P(), 0xFFFFFF, 0.35)); }
UIColor *CTContainer(void) { return CTDyn(C(), CTMix(P(), 0x000000, 0.55)); }
UIColor *CTOnContainer(void) { return CTDyn(CTMix(P(), 0x000000, 0.6), C()); }

UIColor *CTOnPrimary(void) {
    unsigned int p = P();
    CGFloat lum = (((p >> 16) & 0xFF) * 0.2126 + ((p >> 8) & 0xFF) * 0.7152 + (p & 0xFF) * 0.0722) / 255.0;
    return CTDyn(lum > 0.55 ? 0x1D1B20 : 0xFFFFFF, 0x1D1B20);
}
