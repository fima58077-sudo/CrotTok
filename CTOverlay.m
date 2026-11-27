#import "CTOverlay.h"
#import "CTPanel.h"
#import "CTMaterial.h"
#import "CTConfig.h"
#import "CTPet.h"
#import "CTRegion.h"

#pragma mark - Окно, которое пропускает касания сквозь себя

@interface CTPassWindow : UIWindow
@end
@implementation CTPassWindow
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    UIView *v = [super hitTest:p withEvent:e];
    if (v == self || v == self.rootViewController.view) return nil;
    return v;
}
@end

#pragma mark - Корневой контроллер: питомец, тост, панель

@interface CTRootVC : UIViewController <CTPanelDelegate>
@property (nonatomic, strong) UIButton *fab;
@property (nonatomic, strong) UIView *warm;
@property (nonatomic, strong) UIView *bubble;
@property (nonatomic, strong) UILabel *bubbleLabel;
@property (nonatomic, strong) UIView *toastView;
@property (nonatomic, strong) UILabel *toastLabel;
@property (nonatomic, strong) UIView *dim;
@property (nonatomic, strong) CTPanelView *panel;
@property (nonatomic) BOOL panelOpen;
- (void)say:(NSString *)t;
- (void)toast:(NSString *)t;
- (void)refreshTheme;
@end

@implementation CTRootVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    CGSize s = UIScreen.mainScreen.bounds.size;

    self.warm = [[UIView alloc] initWithFrame:self.view.bounds];
    self.warm.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.warm.backgroundColor = [UIColor colorWithRed:1.0 green:0.55 blue:0.1 alpha:0.18];
    self.warm.userInteractionEnabled = NO;
    self.warm.alpha = 0;
    [self.view addSubview:self.warm];

    self.dim = [[UIView alloc] initWithFrame:self.view.bounds];
    self.dim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    self.dim.alpha = 0;
    self.dim.hidden = YES;
    [self.dim addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(panelClose)]];
    [self.view addSubview:self.dim];

    self.fab = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fab.frame = CGRectMake(s.width - 78, s.height * 0.62, 62, 62);
    self.fab.layer.cornerRadius = 31;
    self.fab.layer.shadowColor = [UIColor blackColor].CGColor;
    self.fab.layer.shadowOpacity = 0.25;
    self.fab.layer.shadowRadius = 8;
    self.fab.layer.shadowOffset = CGSizeMake(0, 3);
    [self.fab setTitle:@"🐹" forState:UIControlStateNormal];
    self.fab.titleLabel.font = [UIFont systemFontOfSize:32];
    [self.fab addTarget:self action:@selector(fabTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.fab addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(fabPan:)]];
    [self.view addSubview:self.fab];

    CABasicAnimation *bob = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    bob.fromValue = @(-3);
    bob.toValue = @(3);
    bob.duration = 1.4;
    bob.autoreverses = YES;
    bob.repeatCount = HUGE_VALF;
    bob.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.fab.layer addAnimation:bob forKey:@"bob"];

    self.bubble = [UIView new];
    self.bubble.layer.cornerRadius = 16;
    self.bubble.alpha = 0;
    self.bubble.userInteractionEnabled = NO;
    self.bubbleLabel = [UILabel new];
    self.bubbleLabel.numberOfLines = 0;
    self.bubbleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.bubble addSubview:self.bubbleLabel];
    [self.view addSubview:self.bubble];

    self.toastView = [UIView new];
    self.toastView.backgroundColor = [UIColor colorWithRed:0.2 green:0.18 blue:0.21 alpha:1];
    self.toastView.layer.cornerRadius = 14;
    self.toastView.alpha = 0;
    self.toastView.userInteractionEnabled = NO;
    self.toastLabel = [UILabel new];
    self.toastLabel.numberOfLines = 0;
    self.toastLabel.textColor = [UIColor whiteColor];
    self.toastLabel.font = [UIFont systemFontOfSize:14];
    [self.toastView addSubview:self.toastLabel];
    [self.view addSubview:self.toastView];

    [self refreshTheme];
}

- (void)refreshTheme {
    self.fab.backgroundColor = CTContainer();
    self.bubble.backgroundColor = CTContainer();
    self.bubbleLabel.textColor = CTOnContainer();
}

#pragma mark Питомец

- (void)fabTapped {
    if (self.panelOpen) { [self panelClose]; } else { [self openPanel]; }
}

- (void)fabPan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.view];
    CGSize s = self.view.bounds.size;
    CGPoint c = CGPointMake(self.fab.center.x + t.x, self.fab.center.y + t.y);
    c.x = MAX(40, MIN(s.width - 40, c.x));
    c.y = MAX(80, MIN(s.height - 80, c.y));
    self.fab.center = c;
    [g setTranslation:CGPointZero inView:self.view];
}

- (void)say:(NSString *)t {
    self.bubbleLabel.text = t;
    CGSize max = CGSizeMake(190, 200);
    CGSize sz = [self.bubbleLabel sizeThatFits:max];
    self.bubbleLabel.frame = CGRectMake(12, 8, sz.width, sz.height);
    CGFloat w = sz.width + 24, h = sz.height + 16;
    CGFloat x = MIN(MAX(8, self.fab.center.x - w / 2), self.view.bounds.size.width - w - 8);
    self.bubble.frame = CGRectMake(x, self.fab.frame.origin.y - h - 8, w, h);
    [UIView animateWithDuration:0.25 animations:^{ self.bubble.alpha = 1; }];
    NSString *snapshot = t;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.bubbleLabel.text isEqualToString:snapshot]) {
            [UIView animateWithDuration:0.3 animations:^{ self.bubble.alpha = 0; }];
        }
    });
}

- (void)hearts {
    for (int i = 0; i < 5; i++) {
        UILabel *h = [UILabel new];
        h.text = @"❤️";
        h.font = [UIFont systemFontOfSize:20];
        [h sizeToFit];
        h.center = CGPointMake(self.fab.center.x + (i - 2) * 10, self.fab.frame.origin.y);
        [self.view addSubview:h];
        [UIView animateWithDuration:1.1 delay:i * 0.08 options:UIViewAnimationOptionCurveEaseOut animations:^{
            h.center = CGPointMake(h.center.x + (i - 2) * 8, h.center.y - 90);
            h.alpha = 0;
        } completion:^(BOOL f) { [h removeFromSuperview]; }];
    }
}

- (void)toast:(NSString *)t {
    self.toastLabel.text = t;
    CGFloat maxW = self.view.bounds.size.width - 64;
    CGSize sz = [self.toastLabel sizeThatFits:CGSizeMake(maxW, 200)];
    self.toastLabel.frame = CGRectMake(16, 12, sz.width, sz.height);
    CGFloat w = sz.width + 32, h = sz.height + 24;
    self.toastView.frame = CGRectMake((self.view.bounds.size.width - w) / 2, self.view.bounds.size.height - h - 110, w, h);
    [self.view bringSubviewToFront:self.toastView];
    [UIView animateWithDuration:0.25 animations:^{ self.toastView.alpha = 1; }];
    NSString *snapshot = t;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.toastLabel.text isEqualToString:snapshot]) {
            [UIView animateWithDuration:0.3 animations:^{ self.toastView.alpha = 0; }];
        }
    });
}

#pragma mark Панель

- (void)openPanel {
    CGSize s = self.view.bounds.size;
    CGFloat ph = s.height * 0.82;
    if (!self.panel) {
        self.panel = [[CTPanelView alloc] initWithFrame:CGRectMake(0, s.height, s.width, ph)];
        self.panel.delegate = self;
        [self.view addSubview:self.panel];
    } else {
        [self.panel reload];
    }
    self.panel.frame = CGRectMake(0, s.height, s.width, ph);
    self.dim.hidden = NO;
    [self.view bringSubviewToFront:self.dim];
    [self.view bringSubviewToFront:self.panel];
    [self.view bringSubviewToFront:self.fab];
    [self.view bringSubviewToFront:self.toastView];
    self.panelOpen = YES;
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.86 initialSpringVelocity:0.4 options:0 animations:^{
        self.panel.frame = CGRectMake(0, s.height - ph, s.width, ph);
        self.dim.alpha = 1;
    } completion:nil];
}

- (void)panelClose {
    CGSize s = self.view.bounds.size;
    self.panelOpen = NO;
    [UIView animateWithDuration:0.28 animations:^{
        self.panel.frame = CGRectMake(0, s.height, s.width, self.panel.frame.size.height);
        self.dim.alpha = 0;
    } completion:^(BOOL f) { self.dim.hidden = YES; }];
}

- (void)panelPet {
    [CTPet pet];
    [self hearts];
    [self say:[CTPet phrase]];
}

- (void)panelFeed {
    if ([CTPet feed]) {
        [self say:@"Ням-ням! 🍪 Спасибо!"];
    } else {
        [self toast:@"Нет печенек. Смотри видео: +1 за каждые 10."];
    }
}

- (void)panelThemeChanged {
    [self refreshTheme];
}

- (void)panelRename {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Имя питомца" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.text = [CTPet name]; }];
    [a addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Сохранить" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        [CTPet setName:a.textFields.firstObject.text];
        [self.panel reload];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

- (void)panelPickRegion {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Регион" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSDictionary *r in [CTRegion all]) {
        NSString *t = [NSString stringWithFormat:@"%@ %@", CTFlag(r[@"code"]), r[@"name"]];
        [a addAction:[UIAlertAction actionWithTitle:t style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
            CTSetStr(@"region", r[@"code"]);
            CTSetBool(@"region_on", YES);
            [self.panel reload];
            [self toast:@"Регион применится после перезапуска TikTok"];
        }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    a.popoverPresentationController.sourceView = self.view;
    a.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, 1, 1);
    [self presentViewController:a animated:YES completion:nil];
}

- (void)panelClearCache {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    unsigned long long freed = 0;
    for (NSString *name in [fm contentsOfDirectoryAtPath:dir error:nil]) {
        NSString *p = [dir stringByAppendingPathComponent:name];
        NSDirectoryEnumerator *en = [fm enumeratorAtPath:p];
        for (NSString *f in en) {
            freed += [[fm attributesOfItemAtPath:[p stringByAppendingPathComponent:f] error:nil] fileSize];
        }
        freed += [[fm attributesOfItemAtPath:p error:nil] fileSize];
        [fm removeItemAtPath:p error:nil];
    }
    [self toast:[NSString stringWithFormat:@"Кэш очищен: %.1f МБ", freed / 1048576.0]];
    [self.panel reload];
}

@end

#pragma mark - CTOverlay: окно, таймер, слежение за лентой

@implementation CTOverlay {
    CTPassWindow *_win;
    CTRootVC *_root;
    NSTimer *_timer;
    __weak UIScrollView *_feed;
    NSInteger _lastIdx;
    NSTimeInterval _lastChange;
    NSTimeInterval _lastSearch;
    NSInteger _sessionSecs;
    BOOL _lockedByUs;
    BOOL _brightApplied;
    CGFloat _origBrightness;
}

+ (instancetype)shared {
    static CTOverlay *o;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ o = [CTOverlay new]; });
    return o;
}

- (void)start {
    if (_win) return;
    UIWindowScene *scene = nil;
    for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]] && s.activationState == UISceneActivationStateForegroundActive) {
            scene = (UIWindowScene *)s;
            break;
        }
    }
    if (!scene) return;

    _lastIdx = -1;
    _lastChange = [[NSDate date] timeIntervalSince1970];
    _root = [CTRootVC new];
    _win = [[CTPassWindow alloc] initWithWindowScene:scene];
    _win.frame = UIScreen.mainScreen.bounds;
    _win.windowLevel = UIWindowLevelAlert + 100;
    _win.backgroundColor = [UIColor clearColor];
    _win.rootViewController = _root;
    _win.hidden = NO;

    [CTRegion reload];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apply) name:CTChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apply) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restoreBrightness) name:UIApplicationWillResignActiveNotification object:nil];

    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [self apply];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->_root say:[CTPet phrase]];
    });
}

- (void)apply {
    [CTRegion reload];
    [UIApplication sharedApplication].idleTimerDisabled = CTBool(@"awake", NO);
    _root.warm.alpha = CTBool(@"warm", NO) ? 1 : 0;

    if (CTBool(@"bright_on", NO) && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        if (!_brightApplied) {
            _origBrightness = UIScreen.mainScreen.brightness;
            _brightApplied = YES;
        }
        UIScreen.mainScreen.brightness = CTInt(@"bright_lvl", 50) / 100.0;
    } else {
        [self restoreBrightness];
    }
}

- (void)restoreBrightness {
    if (_brightApplied) {
        UIScreen.mainScreen.brightness = _origBrightness;
        _brightApplied = NO;
    }
}

#pragma mark Лента

- (UIScrollView *)findFeed {
    CGFloat sh = UIScreen.mainScreen.bounds.size.height;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w == _win) continue;
        NSMutableArray *queue = [NSMutableArray arrayWithObject:w];
        NSInteger visited = 0;
        while (queue.count && visited < 4000) {
            UIView *v = queue.firstObject;
            [queue removeObjectAtIndex:0];
            visited++;
            if ([v isKindOfClass:[UIScrollView class]]) {
                UIScrollView *s = (UIScrollView *)v;
                if (s.isPagingEnabled && s.bounds.size.height > sh * 0.6 &&
                    s.contentSize.height > s.bounds.size.height * 1.5 &&
                    s.contentSize.width <= s.bounds.size.width * 1.01) {
                    return s;
                }
            }
            [queue addObjectsFromArray:v.subviews];
        }
    }
    return nil;
}

- (void)didSwipe {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    _lastChange = now;
    NSInteger n = CTInt(@"stat_swipes", 0) + 1;
    CTSetIntQuiet(@"stat_swipes", n);
    if (CTBool(@"haptic", NO)) {
        UIImpactFeedbackGenerator *g = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [g impactOccurred];
    }
    if (n % 10 == 0) {
        [CTPet addCoins:1];
        [_root say:@"+1 🍪 за 10 видео!"];
    }
}

- (void)tick {
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) return;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];

    // новый день: статистика с нуля
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"yyyyMMdd";
    NSInteger today = [[df stringFromDate:[NSDate date]] integerValue];
    if (CTInt(@"stat_day", 0) != today) {
        CTSetIntQuiet(@"stat_day", today);
        CTSetIntQuiet(@"stat_swipes", 0);
        CTSetIntQuiet(@"stat_min", 0);
    }

    _sessionSecs++;
    if (_sessionSecs % 60 == 0) CTSetIntQuiet(@"stat_min", CTInt(@"stat_min", 0) + 1);

    if (CTBool(@"rest_on", NO)) {
        NSInteger every = CTInt(@"rest_int", 30) * 60;
        if (every > 0 && _sessionSecs % every == 0) {
            NSString *msg = [NSString stringWithFormat:@"Ты в TikTok уже %ld мин. Давай сделаем паузу? 💧", (long)(_sessionSecs / 60)];
            [_root say:msg];
            [_root toast:@"Пора отдохнуть 💧"];
        }
    }

    if (!_feed || !_feed.window) {
        _feed = nil;
        if (now - _lastSearch > 2.0) {
            _lastSearch = now;
            _feed = [self findFeed];
            _lastIdx = -1;
        }
    }
    UIScrollView *f = _feed;
    if (!f) return;

    // блокировка ленты
    if (CTBool(@"lock", NO)) {
        if (f.scrollEnabled) { f.scrollEnabled = NO; _lockedByUs = YES; }
    } else if (_lockedByUs) {
        f.scrollEnabled = YES;
        _lockedByUs = NO;
    }

    // подсчёт листаний
    CGFloat h = MAX(1, f.bounds.size.height);
    NSInteger idx = (NSInteger)lround(f.contentOffset.y / h);
    if (_lastIdx >= 0 && idx != _lastIdx && f.contentOffset.y >= 0) [self didSwipe];
    _lastIdx = idx;

    // автолистание
    if (CTBool(@"auto_on", NO) && !CTBool(@"lock", NO)) {
        NSInteger every = CTInt(@"auto_int", 10);
        if (now - _lastChange >= every && !f.isTracking && !f.isDecelerating) {
            _lastChange = now;
            CGFloat maxY = f.contentSize.height - f.bounds.size.height;
            CGFloat next = f.contentOffset.y + h;
            if (next <= maxY) [f setContentOffset:CGPointMake(f.contentOffset.x, next) animated:YES];
        }
    }
}

@end
