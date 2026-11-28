
#import "CTCore.h"
#import "CTConfig.h"
#import "CTMaterial.h"
#import "CTSettings.h"
#import "CTMole.h"
#import <objc/runtime.h>

static char kSkip, kTint, kAvatar, kChecked, kField, kInjected;

#pragma mark - Вспомогательное

void CTMarkSkip(UIView *v) {
    objc_setAssociatedObject(v, &kSkip, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

BOOL CTOwnedByCT(UIView *v) {
    if ([objc_getAssociatedObject(v, &kSkip) boolValue]) return YES;

    UIResponder *r = v;
    int n = 0;

    while (r && n++ < 40) {
        if ([r isKindOfClass:[UIViewController class]]) {
            return [NSStringFromClass([r class]) hasPrefix:@"CT"];
        }
        r = r.nextResponder;
    }

    return NO;
}

static BOOL IsOurWindow(UIWindow *w) {
    return [NSStringFromClass([w class]) hasPrefix:@"CT"];
}

UIViewController *CTTopVC(void) {
    UIWindow *win = nil;

    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (IsOurWindow(w) || w.hidden || !w.rootViewController) continue;

        if (w.isKeyWindow) {
            win = w;
            break;
        }

        if (!win) win = w;
    }

    UIViewController *vc = win.rootViewController;

    for (int i = 0; i < 20 && vc; i++) {
        UIViewController *pres = vc.presentedViewController;

        if (pres) {
            if ([pres isKindOfClass:[UINavigationController class]] &&
                [NSStringFromClass([[(UINavigationController *)pres viewControllers].firstObject class]) hasPrefix:@"CT"]) {
                break;
            }

            vc = pres;
        }
        else if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = [(UINavigationController *)vc topViewController] ?: vc;
        }
        else if ([vc isKindOfClass:[UITabBarController class]] &&
                 [(UITabBarController *)vc selectedViewController]) {
            vc = [(UITabBarController *)vc selectedViewController];
        }
        else {
            break;
        }

        if (vc == nil) break;
    }

    return vc;
}

static void Walk(UIView *root, NSInteger limit, void (^block)(UIView *v)) {
    if (!root || !block) return;

    NSMutableArray *q = [NSMutableArray arrayWithObject:root];
    NSInteger n = 0;

    while (q.count && n < limit) {
        UIView *v = q.firstObject;
        [q removeObjectAtIndex:0];

        n++;
        block(v);

        [q addObjectsFromArray:v.subviews];
    }
}

#pragma mark - Тема Material You

static BOOL MatOn(void) {
    return CTBool(@"mat_on", YES);
}

void CTThemeApplyWindow(UIWindow *w) {
    if (!w || IsOurWindow(w)) return;

    if (MatOn()) {
        w.tintColor = CTPrimary();
        objc_setAssociatedObject(w, &kTint, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    else if ([objc_getAssociatedObject(w, &kTint) boolValue]) {
        w.tintColor = nil;
        objc_setAssociatedObject(w, &kTint, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void CTStyleTextField(UITextField *tf) {
    CGFloat h = tf.bounds.size.height;

    if (h < 30 || h > 60) return;

    objc_setAssociatedObject(tf, &kField, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    tf.layer.cornerRadius = h / 2;
    tf.layer.cornerCurve = kCACornerCurveContinuous;
    tf.backgroundColor = [CTContainer() colorWithAlphaComponent:0.55];
}

void CTThemeApplyControl(UIView *v) {
    if (!v || !MatOn() || CTOwnedByCT(v)) return;

    UIColor *p = CTPrimary();

    if ([v isKindOfClass:[UISwitch class]]) {
        ((UISwitch *)v).onTintColor = p;
    }
    else if ([v isKindOfClass:[UISlider class]]) {
        ((UISlider *)v).minimumTrackTintColor = p;
    }
    else if ([v isKindOfClass:[UIProgressView class]]) {
        ((UIProgressView *)v).progressTintColor = p;
    }
    else if ([v isKindOfClass:[UIPageControl class]]) {
        ((UIPageControl *)v).currentPageIndicatorTintColor = p;
    }
    else if ([v isKindOfClass:[UITextField class]]) {
        v.tintColor = p;

        if (CTBool(@"mat_fields", NO)) {
            CTStyleTextField((UITextField *)v);
        }
        else if ([objc_getAssociatedObject(v, &kField) boolValue]) {
            v.backgroundColor = nil;
            v.layer.cornerRadius = 0;

            objc_setAssociatedObject(v, &kField, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

void CTThemeRefreshAll(void) {
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (IsOurWindow(w)) continue;

        CTThemeApplyWindow(w);
        Walk(w, 6000, ^(UIView *v) {
            CTThemeApplyControl(v);
        });
    }
}

#pragma mark - Форма аватарок

static NSHashTable *Registry(void) {
    static NSHashTable *t;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
        t = [NSHashTable weakObjectsHashTable];
    });

    return t;
}

static CGFloat RadiusFor(CGSize s, NSInteger shape) {
    CGFloat m = MIN(s.width, s.height);

    switch (shape) {
        case 1:
            return m * 0.30;
        case 2:
            return 0;
        default:
            return m / 2;
    }
}

static void ApplyShape(UIView *v) {
    NSInteger shape = CTInt(@"avatar_shape", 0);
    CGFloat r = RadiusFor(v.bounds.size, shape);

    if (fabs(v.layer.cornerRadius - r) > 0.5) {
        v.layer.cornerRadius = r;
        v.layer.cornerCurve = (shape == 1) ? kCACornerCurveContinuous : kCACornerCurveCircular;
        v.clipsToBounds = YES;
    }
}

static BOOL LooksCircular(UIView *v) {
    CGFloat w = v.bounds.size.width;
    CGFloat h = v.bounds.size.height;

    if (w < 20 || w > 170 || fabs(w - h) > 0.6) return NO;

    return v.layer.cornerRadius >= w / 2 - 1.0 &&
           (v.clipsToBounds || v.layer.masksToBounds);
}

void CTAvatarCheck(UIView *v) {
    if (!v) return;

    for (int i = 0; i < 2; i++) {
        UIView *c = (i == 0) ? v : v.superview;

        if (!c) continue;

        if ([objc_getAssociatedObject(c, &kAvatar) boolValue]) {
            ApplyShape(c);
            continue;
        }

        if (i == 1) {
            CGRect a = c.bounds;
            CGRect b = v.bounds;

            if (fabs(a.size.width - b.size.width) > 1 ||
                fabs(a.size.height - b.size.height) > 1) {
                continue;
            }
        }

        if (LooksCircular(c) && !CTOwnedByCT(c)) {
            objc_setAssociatedObject(c, &kAvatar, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [Registry() addObject:c];
            ApplyShape(c);
        }
    }
}

void CTAvatarRefreshAll(void) {
    for (UIView *v in [Registry().allObjects copy]) {
        ApplyShape(v);
    }
}

#pragma mark - Вход в настройки TikTok

static BOOL ContainsAny(NSString *s, NSArray *keys) {
    for (NSString *k in keys) {
        if ([s caseInsensitiveCompare:k] == NSOrderedSame) return YES;
    }

    return NO;
}

static UIView *EntryCard(CGFloat width, UIViewController *host) {
    UIControl *wrap = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, width, 88)];
    wrap.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    CTMarkSkip(wrap);

    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(12, 8, width - 24, 72)];
    card.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    card.backgroundColor = CTContainer();
    card.layer.cornerRadius = 24;
    card.userInteractionEnabled = NO;

    [wrap addSubview:card];

    CTMoleView *m = [CTMoleView new];
    m.frame = CGRectMake(14, 12, 60, 48);

    [card addSubview:m];

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(86, 14, card.bounds.size.width - 130, 24)];
    t.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    t.text = @"CrotTok";
    t.font = [UIFont systemFontOfSize:19 weight:UIFontWeightBold];
    t.textColor = CTOnContainer();

    [card addSubview:t];

    UILabel *s = [[UILabel alloc] initWithFrame:CGRectMake(86, 40, card.bounds.size.width - 130, 18)];
    s.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    s.text = @"Настройки мода: тема, аватарки, Крот, рофлы";
    s.font = [UIFont systemFontOfSize:12];
    s.textColor = [CTOnContainer() colorWithAlphaComponent:0.8];
    s.adjustsFontSizeToFitWidth = YES;

    [card addSubview:s];

    UILabel *chev = [[UILabel alloc] initWithFrame:CGRectMake(card.bounds.size.width - 34, 22, 20, 28)];
    chev.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    chev.text = @"›";
    chev.font = [UIFont systemFontOfSize:26 weight:UIFontWeightMedium];
    chev.textColor = CTOnContainer();

    [card addSubview:chev];

    __weak UIViewController *weakHost = host;

    [wrap addAction:[UIAction actionWithHandler:^(UIAction *a) {
        [CTSettings presentFrom:weakHost ?: CTTopVC()];
    }] forControlEvents:UIControlEventTouchUpInside];

    return wrap;
}

static void TryInject(UIViewController *vc, int attempt) {
    if (!vc.viewIfLoaded.window) return;

    __block UIScrollView *target = nil;
    __block NSInteger score = 0;

    NSArray *keys = @[
        @"Аккаунт", @"Account",
        @"Конфиденциальность", @"Privacy",
        @"Безопасность", @"Security",
        @"Выйти", @"Log out",
        @"Уведомления", @"Push notifications",
        @"Язык", @"Language",
        @"Баланс", @"Balance",
        @"Кэш", @"Free up space",
        @"Освободить место"
    ];

    Walk(vc.view, 1500, ^(UIView *v) {
        if (target) return;

        if (![v isKindOfClass:[UITableView class]] &&
            ![v isKindOfClass:[UICollectionView class]]) {
            return;
        }

        NSArray *cells = nil;

        if ([v isKindOfClass:[UITableView class]]) {
            cells = (NSArray *)[(UITableView *)v visibleCells];
        }
        else if ([v isKindOfClass:[UICollectionView class]]) {
            cells = (NSArray *)[(UICollectionView *)v visibleCells];
        }

        if (cells.count < 4) return;

        NSMutableSet *hits = [NSMutableSet set];

        for (UIView *cell in cells) {
            Walk(cell, 60, ^(UIView *x) {
                if ([x isKindOfClass:[UILabel class]]) {
                    NSString *tx = ((UILabel *)x).text;

                    if (tx.length && ContainsAny(tx, keys)) {
                        [hits addObject:tx.lowercaseString];
                    }
                }
            });
        }

        score = hits.count;

        if (score >= 3) {
            target = (UIScrollView *)v;
        }
    });

    if (!target) {
        if (attempt < 3) {
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                    TryInject(vc, attempt + 1);
                }
            );
        }

        return;
    }

    if ([objc_getAssociatedObject(target, &kInjected) boolValue]) return;

    objc_setAssociatedObject(target, &kInjected, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIView *card = EntryCard(target.bounds.size.width, vc);

    if ([target isKindOfClass:[UITableView class]] &&
        ((UITableView *)target).tableHeaderView == nil) {
        ((UITableView *)target).tableHeaderView = card;
    }
    else {
        UIEdgeInsets inset = target.contentInset;
        inset.top += 88;

        target.contentInset = inset;

        card.frame = CGRectMake(0, -88, target.bounds.size.width, 88);

        [target addSubview:card];
        [target setContentOffset:CGPointMake(0, -inset.top) animated:NO];
    }
}

void CTInjectCheck(UIViewController *vc) {
    if (!vc || [NSStringFromClass([vc class]) hasPrefix:@"CT"]) return;

    if ([objc_getAssociatedObject(vc, &kChecked) boolValue]) return;
    if (!vc.navigationController) return;

    objc_setAssociatedObject(vc, &kChecked, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    __weak UIViewController *w = vc;

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
            if (w) TryInject(w, 0);
        }
    );
}

#pragma mark - Диагностика

static void CTAppendHierarchy(
    NSMutableString *out,
    UIView *v,
    NSInteger depth,
    NSInteger *lines
) {
    if (!v || !out || !lines) return;
    if (*lines > 400 || depth > 7) return;

    (*lines)++;

    [out appendFormat:@"%*s%@ %@",
        (int)(depth * 2),
        "",
        NSStringFromClass([v class]),
        NSStringFromCGRect(v.frame)
    ];

    if ([v isKindOfClass:[UILabel class]] && ((UILabel *)v).text.length) {
        NSString *text = ((UILabel *)v).text;

        [out appendFormat:@" \"%@\"",
            [text substringToIndex:MIN((NSUInteger)24, text.length)]
        ];
    }

    [out appendString:@"\n"];

    for (UIView *s in v.subviews) {
        CTAppendHierarchy(out, s, depth + 1, lines);
    }
}

NSString *CTHierarchyDump(void) {
    UIViewController *vc = CTTopVC();

    NSMutableString *out = [NSMutableString string];

    [out appendFormat:@"Экран: %@\nTikTok: %@\n\n",
        NSStringFromClass([vc class]),
        [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?"
    ];

    NSInteger lines = 0;

    if (vc.viewIfLoaded) {
        CTAppendHierarchy(out, vc.view, 0, &lines);
    }

    return out;
}
