#import "CTOverlay.h"
#import <AudioToolbox/AudioToolbox.h>
#import "CTMole.h"
#import "CTSettings.h"
#import "CTMaterial.h"
#import "CTConfig.h"
#import "CTPet.h"
#import "CTRegion.h"
#import "CTCore.h"

#pragma mark - Спокойный «писк» для скримера (без громкости и резких перепадов)

static SystemSoundID gSqueak;

static void W32(NSMutableData *d, uint32_t v) { [d appendBytes:&v length:4]; }
static void W16(NSMutableData *d, uint16_t v) { [d appendBytes:&v length:2]; }

static void PlaySqueak(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        int sr = 22050;
        double dur = 0.38;
        int n = (int)(sr * dur);
        NSMutableData *w = [NSMutableData data];
        [w appendBytes:"RIFF" length:4];
        W32(w, 36 + n * 2);
        [w appendBytes:"WAVEfmt " length:8];
        W32(w, 16); W16(w, 1); W16(w, 1); W32(w, sr); W32(w, sr * 2); W16(w, 2); W16(w, 16);
        [w appendBytes:"data" length:4];
        W32(w, n * 2);
        double phase = 0;
        for (int i = 0; i < n; i++) {
            double t = i / (double)sr;
            double f = 520 + 700 * (t / dur) + 40 * sin(2 * M_PI * 14 * t);
            phase += 2 * M_PI * f / sr;
            double att = MIN(1.0, t / 0.02);
            double rel = MIN(1.0, (dur - t) / 0.14);
            double amp = 0.28 * att * rel;
            int16_t s = (int16_t)(sin(phase) * amp * 32767);
            [w appendBytes:&s length:2];
        }
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"crot_squeak.wav"];
        [w writeToFile:path atomically:YES];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path], &gSqueak);
    });
    if (gSqueak) AudioServicesPlaySystemSound(gSqueak);
}

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

#pragma mark - Корневой контроллер: Крот, подсказки, шутки

@interface CTRootVC : UIViewController
@property (nonatomic, strong) UIView *warm, *bubble, *toastView, *menuDim, *menuCard, *jokeView;
@property (nonatomic, strong) UILabel *bubbleLabel, *toastLabel;
@property (nonatomic, strong) CTMoleView *mole;
@property (nonatomic) BOOL keyboardUp, jokeActive, petEnabled, dragging;
@property (nonatomic) NSTimeInterval hideUntil;
- (void)reloadFlags;
- (void)refreshTheme;
- (void)say:(NSString *)t;
- (void)toast:(NSString *)t;
- (void)petPet;
- (void)petFeed;
- (void)fireJoke;
- (void)hidePetHour;
@end

@implementation CTRootVC {
    CADisplayLink *_link;
    CGFloat _px, _py, _tx;
    int _state;                // 0 идёт, 1 стоит
    NSTimeInterval _idleUntil;
    BOOL _laidOut;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    self.warm = [[UIView alloc] initWithFrame:self.view.bounds];
    self.warm.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.warm.backgroundColor = [UIColor colorWithRed:1.0 green:0.55 blue:0.1 alpha:0.18];
    self.warm.userInteractionEnabled = NO;
    self.warm.alpha = 0;
    [self.view addSubview:self.warm];

    self.mole = [CTMoleView new];
    [self.mole addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moleTapped)]];
    [self.mole addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(moleLong:)]];
    [self.mole addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(molePan:)]];
    [self.view addSubview:self.mole];

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

    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) { self.keyboardUp = YES; }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) { self.keyboardUp = NO; }];

    _px = CTInt(@"pet_x", 40);
    [self reloadFlags];
    [self refreshTheme];

    _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(petFrame:)];
    [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!_laidOut && self.view.bounds.size.height > 0) {
        _laidOut = YES;
        _py = [self laneY];
        _state = 1;
        _idleUntil = [[NSDate date] timeIntervalSince1970] + 1;
    }
}

- (void)reloadFlags {
    self.petEnabled = CTBool(@"pet_show", YES);
    self.hideUntil = (NSTimeInterval)CTInt(@"pet_hide_until", 0);
}

- (void)refreshTheme {
    self.bubble.backgroundColor = CTContainer();
    self.bubbleLabel.textColor = CTOnContainer();
}

#pragma mark Движение Крота

/// Дорожка идёт чуть выше нижней панели TikTok и не заходит в правую колонку кнопок
- (CGFloat)laneY {
    return self.view.bounds.size.height - self.view.safeAreaInsets.bottom - 49 - 54;
}

- (void)chooseTarget {
    CGFloat minX = 12, maxX = self.view.bounds.size.width - 96;
    _tx = minX + arc4random_uniform((uint32_t)MAX(1, (int)(maxX - minX)));
    self.mole.facingRight = _tx > _px;
    [self.mole startWalking];
    _state = 0;
}

- (void)petFrame:(CADisplayLink *)l {
    if (!_laidOut) return;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    BOOL show = self.petEnabled && now > self.hideUntil && !self.keyboardUp && !self.jokeActive;
    self.mole.hidden = !show;
    if (!show || self.dragging) return;

    CGFloat dt = MIN(0.05, l.targetTimestamp - l.timestamp);
    CGFloat maxX = self.view.bounds.size.width - 90;
    _py += ([self laneY] - _py) * MIN(1.0, 6.0 * dt);

    if (_state == 0) {
        CGFloat dir = _tx > _px ? 1 : -1;
        _px += dir * 34 * dt;
        if ((dir > 0 && _px >= _tx) || (dir < 0 && _px <= _tx)) {
            _px = _tx;
            [self.mole stopWalking];
            _state = 1;
            _idleUntil = now + 2 + arc4random_uniform(5);
            [self.mole setSleeping:([CTPet joy] < 20)];
            CTSetIntQuiet(@"pet_x", (NSInteger)_px);
        }
    } else if (now >= _idleUntil) {
        [self.mole setSleeping:NO];
        [self chooseTarget];
    }
    _px = MAX(8, MIN(maxX, _px));
    self.mole.frame = CGRectMake(_px, _py, 60, 48);
}

- (void)molePan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.view];
    [g setTranslation:CGPointZero inView:self.view];
    if (g.state == UIGestureRecognizerStateBegan) {
        self.dragging = YES;
        [self.mole stopWalking];
        [self.mole setSleeping:NO];
        [self dismissMenu];
    }
    CGSize s = self.view.bounds.size;
    _px = MAX(0, MIN(s.width - 60, _px + t.x));
    _py = MAX(40, MIN(s.height - 60, _py + t.y));
    self.mole.frame = CGRectMake(_px, _py, 60, 48);
    if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled) {
        self.dragging = NO;
        _state = 1;
        _idleUntil = [[NSDate date] timeIntervalSince1970] + 1.5;
        CTSetIntQuiet(@"pet_x", (NSInteger)_px);
    }
}

- (void)moleLong:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) [self openSettings];
}

- (void)openSettings {
    [self dismissMenu];
    [CTSettings presentFrom:CTTopVC()];
}

#pragma mark Реплики и тосты

- (void)say:(NSString *)t {
    self.bubbleLabel.text = t;
    CGSize sz = [self.bubbleLabel sizeThatFits:CGSizeMake(190, 200)];
    self.bubbleLabel.frame = CGRectMake(12, 8, sz.width, sz.height);
    CGFloat w = sz.width + 24, h = sz.height + 16;
    CGFloat x = MIN(MAX(8, self.mole.center.x - w / 2), self.view.bounds.size.width - w - 8);
    self.bubble.frame = CGRectMake(x, self.mole.frame.origin.y - h - 6, w, h);
    [self.view bringSubviewToFront:self.bubble];
    [UIView animateWithDuration:0.25 animations:^{ self.bubble.alpha = 1; }];
    NSString *snap = t;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.bubbleLabel.text isEqualToString:snap]) {
            [UIView animateWithDuration:0.3 animations:^{ self.bubble.alpha = 0; }];
        }
    });
}

- (void)toast:(NSString *)t {
    self.toastLabel.text = t;
    CGSize sz = [self.toastLabel sizeThatFits:CGSizeMake(self.view.bounds.size.width - 64, 200)];
    self.toastLabel.frame = CGRectMake(16, 12, sz.width, sz.height);
    CGFloat w = sz.width + 32, h = sz.height + 24;
    self.toastView.frame = CGRectMake((self.view.bounds.size.width - w) / 2, self.view.bounds.size.height - h - 110, w, h);
    [self.view bringSubviewToFront:self.toastView];
    [UIView animateWithDuration:0.25 animations:^{ self.toastView.alpha = 1; }];
    NSString *snap = t;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.toastLabel.text isEqualToString:snap]) {
            [UIView animateWithDuration:0.3 animations:^{ self.toastView.alpha = 0; }];
        }
    });
}

- (void)hearts {
    for (int i = 0; i < 5; i++) {
        UILabel *h = [UILabel new];
        h.text = @"❤️";
        h.font = [UIFont systemFontOfSize:20];
        [h sizeToFit];
        h.center = CGPointMake(self.mole.center.x + (i - 2) * 10, self.mole.frame.origin.y);
        [self.view addSubview:h];
        [UIView animateWithDuration:1.1 delay:i * 0.08 options:UIViewAnimationOptionCurveEaseOut animations:^{
            h.center = CGPointMake(h.center.x + (i - 2) * 8, h.center.y - 90);
            h.alpha = 0;
        } completion:^(BOOL f) { [h removeFromSuperview]; }];
    }
}

#pragma mark Питомец: действия

- (void)petPet {
    [CTPet pet];
    [self.mole setSleeping:NO];
    [self.mole happy];
    [self hearts];
    [self say:[CTPet phrase]];
}

- (void)petFeed {
    if ([CTPet feed]) {
        [self.mole setSleeping:NO];
        [self.mole eat];
        [self say:@"Ням-ням! 🍪 Спасибо!"];
    } else {
        [self toast:@"Нет печенек. Смотри видео: +1 за каждые 10."];
    }
}

- (void)hidePetHour {
    CTSetInt(@"pet_hide_until", (NSInteger)([[NSDate date] timeIntervalSince1970] + 3600));
    [self toast:@"Крот спрятался на час 🕳️"];
}

- (void)moleTapped { [self showMenu]; }

- (void)showMenu {
    [self dismissMenu];
    UIButton *dim = [UIButton buttonWithType:UIButtonTypeCustom];
    dim.frame = self.view.bounds;
    dim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [dim addTarget:self action:@selector(dismissMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:dim belowSubview:self.mole];
    self.menuDim = dim;

    CGFloat w = 240, h = 150;
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    card.backgroundColor = CTSurface();
    card.layer.cornerRadius = 24;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.25;
    card.layer.shadowRadius = 12;
    card.layer.shadowOffset = CGSizeMake(0, 4);

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, w - 32, 22)];
    title.text = [NSString stringWithFormat:@"%@ %@", [CTPet name], [CTPet moodEmoji]];
    title.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    title.textColor = CTOnSurface();
    [card addSubview:title];

    NSArray *names = @[@"Погладить", @"Покормить 🍪", @"Скрыть на час", @"Настройки"];
    CGFloat bw = (w - 36) / 2;
    for (int i = 0; i < 4; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
        b.frame = CGRectMake(12 + (i % 2) * (bw + 12), 44 + (i / 2) * 50, bw, 42);
        b.tag = i;
        [b setTitle:names[i] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        b.titleLabel.adjustsFontSizeToFitWidth = YES;
        b.layer.cornerRadius = 21;
        b.backgroundColor = (i == 1) ? CTPrimary() : CTContainer();
        [b setTitleColor:((i == 1) ? CTOnPrimary() : CTOnContainer()) forState:UIControlStateNormal];
        [b addTarget:self action:@selector(menuTapped:) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:b];
    }
    CGFloat x = MIN(MAX(8, self.mole.center.x - w / 2), self.view.bounds.size.width - w - 8);
    CGFloat y = self.mole.frame.origin.y - h - 10;
    if (y < 60) y = CGRectGetMaxY(self.mole.frame) + 10;
    card.frame = CGRectMake(x, y, w, h);
    card.alpha = 0;
    card.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [self.view addSubview:card];
    self.menuCard = card;
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:0 animations:^{
        card.alpha = 1;
        card.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismissMenu {
    [self.menuDim removeFromSuperview];
    UIView *card = self.menuCard;
    self.menuDim = nil;
    self.menuCard = nil;
    [UIView animateWithDuration:0.15 animations:^{ card.alpha = 0; } completion:^(BOOL f) { [card removeFromSuperview]; }];
}

- (void)menuTapped:(UIButton *)b {
    NSInteger tag = b.tag;
    [self dismissMenu];
    switch (tag) {
        case 0: [self petPet]; break;
        case 1: [self petFeed]; break;
        case 2: [self hidePetHour]; break;
        default: [self openSettings]; break;
    }
}

#pragma mark Скример: шуточный Крот (без вспышек, звук тихий)

- (void)fireJoke {
    if (self.jokeActive) return;
    self.jokeActive = YES;
    [self dismissMenu];
    CGSize s = self.view.bounds.size;

    UIControl *j = [[UIControl alloc] initWithFrame:self.view.bounds];
    j.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    j.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    [j addTarget:self action:@selector(endJoke) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:j];
    self.jokeView = j;

    CTMoleView *m = [CTMoleView new];
    m.facingRight = YES;
    m.userInteractionEnabled = NO;
    m.transform = CGAffineTransformMakeScale(4.5, 4.5);
    m.center = CGPointMake(s.width / 2, s.height + 160);
    [j addSubview:m];

    UILabel *l = [UILabel new];
    l.text = @"КРОТ!";
    l.font = [UIFont systemFontOfSize:46 weight:UIFontWeightHeavy];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentCenter;
    l.alpha = 0;
    l.frame = CGRectMake(0, s.height * 0.5 + 110, s.width, 56);
    [j addSubview:l];

    PlaySqueak();
    [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];
    [UIView animateWithDuration:0.3 animations:^{ j.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55]; }];
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.62 initialSpringVelocity:0.9 options:0 animations:^{
        m.center = CGPointMake(s.width / 2, s.height * 0.5);
        l.alpha = 1;
    } completion:^(BOOL f) { [m happy]; }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.jokeView == j) [self endJoke];
    });
}

- (void)endJoke {
    UIView *j = self.jokeView;
    if (!j) return;
    self.jokeView = nil;
    [UIView animateWithDuration:0.3 animations:^{ j.alpha = 0; } completion:^(BOOL f) {
        [j removeFromSuperview];
        self.jokeActive = NO;
    }];
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
    NSInteger _sinceJoke;
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->_root say:[CTPet phrase]];
    });
}

- (void)apply {
    [CTRegion reload];
    [_root reloadFlags];
    [UIApplication sharedApplication].idleTimerDisabled = CTBool(@"awake", NO);
    _root.warm.alpha = CTBool(@"warm", NO) ? 1 : 0;
    [_root refreshTheme];

    if (CTBool(@"bright_on", NO) && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        if (!_brightApplied) {
            _origBrightness = UIScreen.mainScreen.brightness;
            _brightApplied = YES;
        }
        UIScreen.mainScreen.brightness = CTInt(@"bright_lvl", 50) / 100.0;
    } else {
        [self restoreBrightness];
    }
    // перекраска TikTok откладывается, чтобы не дёргать интерфейс при каждом движении ползунка
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshLooks) object:nil];
    [self performSelector:@selector(refreshLooks) withObject:nil afterDelay:0.3];
}

- (void)refreshLooks {
    CTThemeRefreshAll();
    CTAvatarRefreshAll();
}

- (void)restoreBrightness {
    if (_brightApplied) {
        UIScreen.mainScreen.brightness = _origBrightness;
        _brightApplied = NO;
    }
}

#pragma mark Публичные действия

- (void)petPet { [_root petPet]; }
- (void)petFeed { [_root petFeed]; }
- (void)hidePetForHour { [_root hidePetHour]; }
- (void)fireJoke { [_root fireJoke]; }
- (void)toast:(NSString *)text { [_root toast:text]; }
- (void)say:(NSString *)text { [_root say:text]; }

- (void)clearCache {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    unsigned long long freed = 0;
    for (NSString *name in [fm contentsOfDirectoryAtPath:dir error:nil]) {
        NSString *p = [dir stringByAppendingPathComponent:name];
        for (NSString *f in [fm enumeratorAtPath:p]) {
            freed += [[fm attributesOfItemAtPath:[p stringByAppendingPathComponent:f] error:nil] fileSize];
        }
        freed += [[fm attributesOfItemAtPath:p error:nil] fileSize];
        [fm removeItemAtPath:p error:nil];
    }
    [_root toast:[NSString stringWithFormat:@"Кэш очищен: %.1f МБ", freed / 1048576.0]];
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
    _lastChange = [[NSDate date] timeIntervalSince1970];
    NSInteger n = CTInt(@"stat_swipes", 0) + 1;
    CTSetIntQuiet(@"stat_swipes", n);
    if (CTBool(@"haptic", NO)) {
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    }
    if (n % 10 == 0) {
        [CTPet addCoins:1];
        [_root say:@"+1 🍪 за 10 видео!"];
    }
}

- (void)tick {
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) return;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];

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
            [_root say:[NSString stringWithFormat:@"Ты в TikTok уже %ld мин. Давай сделаем паузу? 💧", (long)(_sessionSecs / 60)]];
            [_root toast:@"Пора отдохнуть 💧"];
        }
    }

    // Скример: таймер идёт, только пока функция включена
    if (CTBool(@"joke_on", NO)) {
        _sinceJoke++;
        if (_sinceJoke >= CTInt(@"joke_int", 5) * 60 && !_root.keyboardUp && !_root.jokeActive) {
            _sinceJoke = 0;
            [_root fireJoke];
        }
    } else {
        _sinceJoke = 0;
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

    if (CTBool(@"lock", NO)) {
        if (f.scrollEnabled) { f.scrollEnabled = NO; _lockedByUs = YES; }
    } else if (_lockedByUs) {
        f.scrollEnabled = YES;
        _lockedByUs = NO;
    }

    CGFloat h = MAX(1, f.bounds.size.height);
    NSInteger idx = (NSInteger)lround(f.contentOffset.y / h);
    if (_lastIdx >= 0 && idx != _lastIdx && f.contentOffset.y >= 0) [self didSwipe];
    _lastIdx = idx;

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
