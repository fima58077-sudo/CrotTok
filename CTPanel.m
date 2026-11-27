#import "CTPanel.h"
#import "CTMaterial.h"
#import "CTConfig.h"
#import "CTPet.h"
#import "CTRegion.h"

@interface CTSwitch : UISwitch
@property (nonatomic, copy) NSString *key;
@end
@implementation CTSwitch
@end

@interface CTSlider : UISlider
@property (nonatomic, copy) NSString *key;
@end
@implementation CTSlider
@end

@interface CTBar : UIView
@property (nonatomic) CGFloat progress;
@end

@implementation CTBar {
    UIView *_fill;
}
- (instancetype)initWithFrame:(CGRect)f {
    self = [super initWithFrame:f];
    if (self) {
        self.layer.cornerRadius = 6;
        self.clipsToBounds = YES;
        self.backgroundColor = CTContainer();
        _fill = [UIView new];
        _fill.backgroundColor = CTPrimary();
        [self addSubview:_fill];
    }
    return self;
}
- (void)setProgress:(CGFloat)p {
    _progress = p;
    [self setNeedsLayout];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat p = MAX(0, MIN(1, _progress));
    _fill.frame = CGRectMake(0, 0, self.bounds.size.width * p, self.bounds.size.height);
}
@end

static UILabel *L(NSString *t, CGFloat sz, UIFontWeight w, UIColor *c) {
    UILabel *l = [UILabel new];
    l.text = t;
    l.font = [UIFont systemFontOfSize:sz weight:w];
    l.textColor = c;
    l.numberOfLines = 0;
    return l;
}

static UIButton *B(NSString *t, BOOL filled, id target, SEL sel) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:t forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    b.layer.cornerRadius = 22;
    b.backgroundColor = filled ? CTPrimary() : CTContainer();
    [b setTitleColor:(filled ? CTOnPrimary() : CTOnContainer()) forState:UIControlStateNormal];
    [b.heightAnchor constraintEqualToConstant:44].active = YES;
    [b addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

static UIStackView *VStack(CGFloat spacing) {
    UIStackView *s = [UIStackView new];
    s.axis = UILayoutConstraintAxisVertical;
    s.spacing = spacing;
    return s;
}

static UIStackView *HStack(CGFloat spacing) {
    UIStackView *s = [UIStackView new];
    s.axis = UILayoutConstraintAxisHorizontal;
    s.spacing = spacing;
    s.alignment = UIStackViewAlignmentCenter;
    return s;
}

/// Карточка с внутренними отступами
static UIView *Card(UIView *inner) {
    UIView *card = [UIView new];
    card.backgroundColor = CTSurface();
    card.layer.cornerRadius = 28;
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:inner];
    [NSLayoutConstraint activateConstraints:@[
        [inner.topAnchor constraintEqualToAnchor:card.topAnchor constant:18],
        [inner.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-18],
        [inner.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:18],
        [inner.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-18]
    ]];
    return card;
}

@implementation CTPanelView {
    UIScrollView *_scroll;
    UIStackView *_stack;
}

- (instancetype)initWithFrame:(CGRect)f {
    self = [super initWithFrame:f];
    if (self) {
        self.layer.cornerRadius = 32;
        self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        self.clipsToBounds = YES;

        _scroll = [UIScrollView new];
        _scroll.translatesAutoresizingMaskIntoConstraints = NO;
        _scroll.alwaysBounceVertical = YES;
        [self addSubview:_scroll];

        _stack = VStack(12);
        _stack.translatesAutoresizingMaskIntoConstraints = NO;
        [_scroll addSubview:_stack];

        [NSLayoutConstraint activateConstraints:@[
            [_scroll.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_scroll.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_scroll.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_scroll.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_stack.topAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.topAnchor constant:8],
            [_stack.bottomAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.bottomAnchor constant:-48],
            [_stack.leadingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.leadingAnchor constant:16],
            [_stack.trailingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.trailingAnchor constant:-16],
            [_stack.widthAnchor constraintEqualToAnchor:_scroll.frameLayoutGuide.widthAnchor constant:-32]
        ]];
        [self reload];
    }
    return self;
}

#pragma mark - Построение

- (void)reload {
    for (UIView *v in [_stack.arrangedSubviews copy]) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    self.backgroundColor = CTBg();

    [_stack addArrangedSubview:[self headerView]];
    [_stack addArrangedSubview:[self petCard]];
    [_stack addArrangedSubview:[self regionCard]];
    [_stack addArrangedSubview:[self featuresCard]];
    [_stack addArrangedSubview:[self statsCard]];
    [_stack addArrangedSubview:[self accentCard]];

    UILabel *foot = L(@"Crot Tok 1.0", 12, UIFontWeightRegular, CTOnVar());
    foot.textAlignment = NSTextAlignmentCenter;
    [_stack addArrangedSubview:foot];
}

- (UIView *)headerView {
    UIStackView *row = HStack(8);
    UILabel *title = L(@"Crot Tok", 28, UIFontWeightBold, CTOnSurface());
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [close setTitleColor:CTOnSurface() forState:UIControlStateNormal];
    close.backgroundColor = CTContainer();
    close.layer.cornerRadius = 20;
    [close.widthAnchor constraintEqualToConstant:40].active = YES;
    [close.heightAnchor constraintEqualToConstant:40].active = YES;
    [close addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [row addArrangedSubview:title];
    [row addArrangedSubview:close];
    UIView *wrap = [UIView new];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [wrap addSubview:row];
    [NSLayoutConstraint activateConstraints:@[
        [row.topAnchor constraintEqualToAnchor:wrap.topAnchor constant:10],
        [row.bottomAnchor constraintEqualToAnchor:wrap.bottomAnchor constant:-4],
        [row.leadingAnchor constraintEqualToAnchor:wrap.leadingAnchor constant:4],
        [row.trailingAnchor constraintEqualToAnchor:wrap.trailingAnchor]
    ]];
    return wrap;
}

- (UIView *)petCard {
    UIStackView *col = VStack(12);

    UIStackView *top = HStack(14);
    UILabel *emoji = L(@"🐹", 56, UIFontWeightRegular, CTOnSurface());
    UIStackView *info = VStack(2);
    UIButton *name = [UIButton buttonWithType:UIButtonTypeSystem];
    [name setTitle:[NSString stringWithFormat:@"%@  ✎", [CTPet name]] forState:UIControlStateNormal];
    name.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    [name setTitleColor:CTOnSurface() forState:UIControlStateNormal];
    name.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
    [name addTarget:self action:@selector(renameTapped) forControlEvents:UIControlEventTouchUpInside];
    [info addArrangedSubview:name];
    [info addArrangedSubview:L([NSString stringWithFormat:@"%@ %@", [CTPet moodEmoji], [CTPet moodText]], 14, UIFontWeightRegular, CTOnVar())];
    [top addArrangedSubview:emoji];
    [top addArrangedSubview:info];
    [col addArrangedSubview:top];

    [col addArrangedSubview:[self barRow:@"Сытость" value:[CTPet food]]];
    [col addArrangedSubview:[self barRow:@"Настроение" value:[CTPet joy]]];
    [col addArrangedSubview:L([NSString stringWithFormat:@"🍪 Печенек: %ld  ·  +1 за каждые 10 видео", (long)[CTPet coins]], 13, UIFontWeightMedium, CTOnVar())];

    UIStackView *btns = HStack(10);
    btns.distribution = UIStackViewDistributionFillEqually;
    [btns addArrangedSubview:B(@"Погладить", NO, self, @selector(petTapped))];
    [btns addArrangedSubview:B(@"Покормить 🍪", YES, self, @selector(feedTapped))];
    [col addArrangedSubview:btns];
    return Card(col);
}

- (UIView *)barRow:(NSString *)title value:(NSInteger)v {
    UIStackView *row = HStack(10);
    UILabel *l = L(title, 13, UIFontWeightMedium, CTOnSurface());
    [l.widthAnchor constraintEqualToConstant:92].active = YES;
    CTBar *bar = [CTBar new];
    bar.progress = v / 100.0;
    [bar.heightAnchor constraintEqualToConstant:12].active = YES;
    [row addArrangedSubview:l];
    [row addArrangedSubview:bar];
    return row;
}

- (UIView *)regionCard {
    UIStackView *col = VStack(10);
    [col addArrangedSubview:L(@"Регион", 18, UIFontWeightBold, CTOnSurface())];
    [col addArrangedSubview:[self switchRow:@"Подмена региона" sub:@"Оператор SIM и региональные настройки для TikTok" key:@"region_on" def:NO]];

    NSDictionary *r = [CTRegion byCode:CTStr(@"region", @"US")];
    NSString *t = [NSString stringWithFormat:@"%@ %@  ▾", CTFlag(r[@"code"]), r[@"name"]];
    [col addArrangedSubview:B(t, NO, self, @selector(regionTapped))];
    [col addArrangedSubview:L(@"Применится после перезапуска TikTok. Лента и аккаунт зависят ещё и от IP-адреса, поэтому подмена может не изменить рекомендации.", 12, UIFontWeightRegular, CTOnVar())];
    return Card(col);
}

- (UIView *)featuresCard {
    UIStackView *col = VStack(12);
    [col addArrangedSubview:L(@"Функции", 18, UIFontWeightBold, CTOnSurface())];

    [col addArrangedSubview:[self switchRow:@"Автолистание" sub:@"Сама листает ленту (экспериментально)" key:@"auto_on" def:NO]];
    NSInteger ai = CTInt(@"auto_int", 10);
    [col addArrangedSubview:B([NSString stringWithFormat:@"Интервал: %ld с", (long)ai], NO, self, @selector(cycleAuto))];

    [col addArrangedSubview:[self switchRow:@"Не гасить экран" sub:@"Пока открыт TikTok" key:@"awake" def:NO]];
    [col addArrangedSubview:[self switchRow:@"Тёплый фильтр" sub:@"Меньше синего света вечером" key:@"warm" def:NO]];

    [col addArrangedSubview:[self switchRow:@"Напоминание об отдыхе" sub:@"Крот подскажет, когда пора сделать паузу" key:@"rest_on" def:NO]];
    NSInteger ri = CTInt(@"rest_int", 30);
    [col addArrangedSubview:B([NSString stringWithFormat:@"Напоминать каждые %ld мин", (long)ri], NO, self, @selector(cycleRest))];

    [col addArrangedSubview:[self switchRow:@"Вибро при листании" sub:@"Лёгкий отклик на каждое видео" key:@"haptic" def:NO]];
    [col addArrangedSubview:[self switchRow:@"Заблокировать ленту" sub:@"Защита от случайных свайпов" key:@"lock" def:NO]];

    [col addArrangedSubview:[self switchRow:@"Приглушить яркость" sub:@"Только пока открыт TikTok" key:@"bright_on" def:NO]];
    CTSlider *sl = [CTSlider new];
    sl.key = @"bright_lvl";
    sl.minimumValue = 10;
    sl.maximumValue = 100;
    sl.value = (float)CTInt(@"bright_lvl", 50);
    sl.minimumTrackTintColor = CTPrimary();
    [sl addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [col addArrangedSubview:sl];

    [col addArrangedSubview:[self switchRow:@"Чистые ссылки" sub:@"Убирает трекинг из скопированных ссылок TikTok" key:@"clean" def:NO]];
    return Card(col);
}

- (UIView *)statsCard {
    UIStackView *col = VStack(10);
    [col addArrangedSubview:L(@"Статистика за сегодня", 18, UIFontWeightBold, CTOnSurface())];
    NSString *s = [NSString stringWithFormat:@"🎞 Видео: %ld   ·   ⏱ Минут: %ld", (long)CTInt(@"stat_swipes", 0), (long)CTInt(@"stat_min", 0)];
    [col addArrangedSubview:L(s, 15, UIFontWeightMedium, CTOnSurface())];
    [col addArrangedSubview:B(@"Очистить кэш TikTok", NO, self, @selector(clearTapped))];
    return Card(col);
}

- (UIView *)accentCard {
    UIStackView *col = VStack(10);
    [col addArrangedSubview:L(@"Акцентный цвет", 18, UIFontWeightBold, CTOnSurface())];
    UIStackView *row = HStack(10);
    row.distribution = UIStackViewDistributionFillEqually;
    NSArray *pal = CTPalettes();
    for (NSInteger i = 0; i < (NSInteger)pal.count; i++) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.tag = i;
        b.backgroundColor = CTHex([pal[i][@"p"] unsignedIntValue]);
        b.layer.cornerRadius = 16;
        [b.heightAnchor constraintEqualToConstant:32].active = YES;
        if (i == CTAccentIndex()) {
            b.layer.borderWidth = 3;
            b.layer.borderColor = CTOnSurface().CGColor;
        }
        [b addTarget:self action:@selector(accentTapped:) forControlEvents:UIControlEventTouchUpInside];
        [row addArrangedSubview:b];
    }
    [col addArrangedSubview:row];
    return Card(col);
}

- (UIView *)switchRow:(NSString *)title sub:(NSString *)sub key:(NSString *)key def:(BOOL)d {
    UIStackView *row = HStack(12);
    UIStackView *text = VStack(2);
    [text addArrangedSubview:L(title, 16, UIFontWeightSemibold, CTOnSurface())];
    if (sub.length) [text addArrangedSubview:L(sub, 12, UIFontWeightRegular, CTOnVar())];
    CTSwitch *sw = [CTSwitch new];
    sw.key = key;
    sw.on = CTBool(key, d);
    sw.onTintColor = CTPrimary();
    [sw setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [sw setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [row addArrangedSubview:text];
    [row addArrangedSubview:sw];
    return row;
}

#pragma mark - Действия

- (void)switchChanged:(CTSwitch *)s { CTSetBool(s.key, s.on); }
- (void)sliderChanged:(CTSlider *)s { CTSetInt(s.key, (NSInteger)s.value); }
- (void)closeTapped { [self.delegate panelClose]; }
- (void)petTapped { [self.delegate panelPet]; [self reload]; }
- (void)feedTapped { [self.delegate panelFeed]; [self reload]; }
- (void)renameTapped { [self.delegate panelRename]; }
- (void)regionTapped { [self.delegate panelPickRegion]; }
- (void)clearTapped { [self.delegate panelClearCache]; }

- (void)cycleAuto {
    NSArray *v = @[@5, @10, @15, @30];
    NSInteger cur = CTInt(@"auto_int", 10);
    NSUInteger i = [v indexOfObject:@(cur)];
    CTSetInt(@"auto_int", [v[(i == NSNotFound ? 0 : (i + 1) % v.count)] integerValue]);
    [self reload];
}

- (void)cycleRest {
    NSArray *v = @[@15, @30, @45, @60];
    NSInteger cur = CTInt(@"rest_int", 30);
    NSUInteger i = [v indexOfObject:@(cur)];
    CTSetInt(@"rest_int", [v[(i == NSNotFound ? 0 : (i + 1) % v.count)] integerValue]);
    [self reload];
}

- (void)accentTapped:(UIButton *)b {
    CTSetInt(@"accent", b.tag);
    [self reload];
    [self.delegate panelThemeChanged];
}

@end
