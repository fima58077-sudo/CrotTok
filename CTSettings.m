#import "CTSettings.h"
#import "CTMaterial.h"
#import "CTConfig.h"
#import "CTRegion.h"
#import "CTPet.h"
#import "CTMole.h"
#import "CTOverlay.h"
#import "CTCore.h"

static NSString *const kNet = @"Сеть";
static NSString *const kLook = @"Оформление";
static NSString *const kFun = @"Рофлы";
static NSString *const kMain = @"Основное";

#pragma mark - Переключатель Material You

@implementation CTToggle {
    UIView *_track;
    UIView *_thumb;
}

- (instancetype)initWithFrame:(CGRect)f {
    self = [super initWithFrame:CGRectMake(0, 0, 52, 32)];
    if (self) {
        _track = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 52, 32)];
        _track.layer.cornerRadius = 16;
        _track.userInteractionEnabled = NO;
        [self addSubview:_track];
        _thumb = [UIView new];
        _thumb.userInteractionEnabled = NO;
        [self addSubview:_thumb];
        [self addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        [self apply:NO];
    }
    return self;
}

- (CGSize)intrinsicContentSize { return CGSizeMake(52, 32); }

- (void)tapped {
    [self setOn:!_on animated:YES];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _on = on;
    [self apply:animated];
}

- (void)apply:(BOOL)animated {
    void (^change)(void) = ^{
        if (self->_on) {
            self->_track.backgroundColor = CTPrimary();
            self->_track.layer.borderWidth = 0;
            self->_thumb.frame = CGRectMake(24, 4, 24, 24);
            self->_thumb.layer.cornerRadius = 12;
            self->_thumb.backgroundColor = CTOnPrimary();
        } else {
            self->_track.backgroundColor = CTDyn(0xE6E0E9, 0x36343B);
            self->_track.layer.borderWidth = 2;
            self->_track.layer.borderColor = CTOnVar().CGColor;
            self->_thumb.frame = CGRectMake(8, 8, 16, 16);
            self->_thumb.layer.cornerRadius = 8;
            self->_thumb.backgroundColor = CTOnVar();
        }
    };
    if (animated) {
        [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.6 options:0 animations:change completion:nil];
    } else {
        change();
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)prev {
    [super traitCollectionDidChange:prev];
    [self apply:NO];
}

@end

#pragma mark - Вспомогательные элементы

static UILabel *L(NSString *t, CGFloat sz, UIFontWeight w, UIColor *c) {
    UILabel *l = [UILabel new];
    l.text = t;
    l.font = [UIFont systemFontOfSize:sz weight:w];
    l.textColor = c;
    l.numberOfLines = 0;
    return l;
}

static UIButton *Btn(NSString *t, BOOL filled, id target, SEL sel) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:t forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    b.titleLabel.adjustsFontSizeToFitWidth = YES;
    b.titleLabel.minimumScaleFactor = 0.8;
    b.layer.cornerRadius = 22;
    b.backgroundColor = filled ? CTPrimary() : CTContainer();
    [b setTitleColor:(filled ? CTOnPrimary() : CTOnContainer()) forState:UIControlStateNormal];
    [b.heightAnchor constraintEqualToConstant:44].active = YES;
    [b addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}

static UIStackView *Stack(UILayoutConstraintAxis axis, CGFloat spacing) {
    UIStackView *s = [UIStackView new];
    s.axis = axis;
    s.spacing = spacing;
    return s;
}

@interface CTBarView : UIView
@property (nonatomic) CGFloat progress;
@end
@implementation CTBarView {
    UIView *_fill;
}
- (instancetype)initWithFrame:(CGRect)f {
    self = [super initWithFrame:f];
    if (self) {
        self.layer.cornerRadius = 6;
        self.clipsToBounds = YES;
        self.backgroundColor = [CTPrimary() colorWithAlphaComponent:0.2];
        _fill = [UIView new];
        _fill.backgroundColor = CTPrimary();
        [self addSubview:_fill];
    }
    return self;
}
- (void)setProgress:(CGFloat)p { _progress = p; [self setNeedsLayout]; }
- (void)layoutSubviews {
    [super layoutSubviews];
    _fill.frame = CGRectMake(0, 0, self.bounds.size.width * MAX(0, MIN(1, _progress)), self.bounds.size.height);
}
@end

static void StyleNav(UINavigationController *nav) {
    UINavigationBarAppearance *a = [UINavigationBarAppearance new];
    [a configureWithOpaqueBackground];
    a.backgroundColor = CTBg();
    a.shadowColor = [UIColor clearColor];
    a.titleTextAttributes = @{NSForegroundColorAttributeName: CTOnSurface()};
    a.largeTitleTextAttributes = @{NSForegroundColorAttributeName: CTOnSurface(), NSFontAttributeName: [UIFont systemFontOfSize:32 weight:UIFontWeightBold]};
    nav.navigationBar.standardAppearance = a;
    nav.navigationBar.scrollEdgeAppearance = a;
    nav.navigationBar.tintColor = CTPrimary();
}

static NSString *ShapeName(NSInteger s) {
    NSArray *n = @[@"Круглая", @"Скруглённый квадрат", @"Квадратная", @"Капсула"];
    return n[(s < 0 || s > 3) ? 0 : s];
}

#pragma mark - Модель настроек

typedef NS_ENUM(NSInteger, CTKind) { CTKSwitch, CTKChoice, CTKButton, CTKSlider, CTKLink, CTKNote };

@interface CTItem : NSObject
@property (nonatomic, copy) NSString *cat, *title, *sub, *key, *kw, *strDef;
@property (nonatomic) CTKind kind;
@property (nonatomic) BOOL def, strChoice;
@property (nonatomic) double min, max, defNum;
@property (nonatomic, copy) NSArray<NSDictionary *> *choices;
@property (nonatomic, copy) NSString *(^valueText)(void);
@property (nonatomic, copy) NSString *(^noteText)(void);
@property (nonatomic, copy) void (^action)(UIViewController *host);
@end
@implementation CTItem
@end

static CTItem *Mk(CTKind k, NSString *cat, NSString *title, NSString *sub, NSString *key) {
    CTItem *i = [CTItem new];
    i.kind = k;
    i.cat = cat;
    i.title = title;
    i.sub = sub;
    i.key = key;
    i.kw = (k == CTKNote) ? @"" : [NSString stringWithFormat:@"%@ %@ %@", title, sub ?: @"", cat];
    return i;
}

@class CTAccentVC, CTAvatarVC;
static UIViewController *MakeAccentVC(void);
static UIViewController *MakeAvatarVC(void);

static NSArray<CTItem *> *Items(void) {
    NSMutableArray *a = [NSMutableArray array];
    CTItem *i;

    // ---- Сеть
    i = Mk(CTKSwitch, kNet, @"Подмена региона", @"Оператор SIM и региональные настройки для TikTok", @"region_on");
    [a addObject:i];
    i = Mk(CTKChoice, kNet, @"Регион", @"Страна, которую увидит TikTok", @"region");
    i.strChoice = YES;
    i.strDef = @"US";
    NSMutableArray *rc = [NSMutableArray array];
    for (NSDictionary *r in [CTRegion all]) {
        [rc addObject:@{@"t": [NSString stringWithFormat:@"%@ %@", CTFlag(r[@"code"]), r[@"name"]], @"v": r[@"code"]}];
    }
    i.choices = rc;
    [a addObject:i];
    i = Mk(CTKNote, kNet, @"", @"Применится после перезапуска TikTok. Лента и аккаунт зависят ещё и от IP-адреса, поэтому рекомендации могут не измениться.", nil);
    [a addObject:i];

    // ---- Оформление
    i = Mk(CTKSwitch, kLook, @"Тема Material You", @"Акцент, переключатели, ползунки, окна и меню TikTok", @"mat_on");
    i.def = YES;
    [a addObject:i];
    i = Mk(CTKLink, kLook, @"Акцентный цвет", @"Палитра, свой HEX и предпросмотр", nil);
    i.valueText = ^NSString *{ return [@"#" stringByAppendingString:CTHexString(CTCurrentPrimaryHex())]; };
    i.action = ^(UIViewController *host) { [host.navigationController pushViewController:MakeAccentVC() animated:YES]; };
    [a addObject:i];
    i = Mk(CTKLink, kLook, @"Форма аватарки", @"Круг, скруглённый квадрат, квадрат, капсула", nil);
    i.valueText = ^NSString *{ return ShapeName(CTInt(@"avatar_shape", 0)); };
    i.action = ^(UIViewController *host) { [host.navigationController pushViewController:MakeAvatarVC() animated:YES]; };
    [a addObject:i];
    i = Mk(CTKSwitch, kLook, @"Material-поля ввода", @"Скруглённые поля ввода (экспериментально)", @"mat_fields");
    [a addObject:i];

    // ---- Рофлы
    i = Mk(CTKSwitch, kFun, @"Скример", @"Неожиданный Крот со спокойным звуком. Выключается здесь в любой момент", @"joke_on");
    [a addObject:i];
    i = Mk(CTKChoice, kFun, @"Интервал срабатывания", @"По умолчанию 5 минут", @"joke_int");
    i.defNum = 5;
    NSMutableArray *jc = [NSMutableArray array];
    for (NSNumber *m in @[@1, @3, @5, @10, @15, @30]) [jc addObject:@{@"t": [NSString stringWithFormat:@"%@ мин", m], @"v": m}];
    i.choices = jc;
    [a addObject:i];
    i = Mk(CTKButton, kFun, @"Показать сейчас", @"Проверить эффект. Касание по экрану закрывает его", nil);
    i.action = ^(UIViewController *host) { [[CTOverlay shared] fireJoke]; };
    [a addObject:i];

    // ---- Основное
    i = Mk(CTKSwitch, kMain, @"Показывать питомца", @"Крот гуляет по экранам TikTok", @"pet_show");
    i.def = YES;
    [a addObject:i];
    i = Mk(CTKButton, kMain, @"Скрыть питомца на час", @"Потом Крот вернётся сам", nil);
    i.action = ^(UIViewController *host) { [[CTOverlay shared] hidePetForHour]; };
    [a addObject:i];
    i = Mk(CTKSwitch, kMain, @"Автолистание", @"Сама листает ленту (экспериментально)", @"auto_on");
    [a addObject:i];
    i = Mk(CTKChoice, kMain, @"Интервал автолистания", @"Как часто переключать видео", @"auto_int");
    i.defNum = 10;
    NSMutableArray *ac = [NSMutableArray array];
    for (NSNumber *m in @[@5, @10, @15, @30]) [ac addObject:@{@"t": [NSString stringWithFormat:@"%@ с", m], @"v": m}];
    i.choices = ac;
    [a addObject:i];
    i = Mk(CTKSwitch, kMain, @"Не гасить экран", @"Пока открыт TikTok", @"awake");
    [a addObject:i];
    i = Mk(CTKSwitch, kMain, @"Тёплый фильтр", @"Меньше синего света вечером", @"warm");
    [a addObject:i];
    i = Mk(CTKSwitch, kMain, @"Напоминание об отдыхе", @"Крот подскажет, когда пора сделать паузу", @"rest_on");
    [a addObject:i];
    i = Mk(CTKChoice, kMain, @"Интервал напоминаний", @"Через сколько минут напоминать", @"rest_int");
    i.defNum = 30;
    NSMutableArray *rr = [NSMutableArray array];
    for (NSNumber *m in @[@15, @30, @45, @60]) [rr addObject:@{@"t": [NSString stringWithFormat:@"%@ мин", m], @"v": m}];
    i.choices = rr;
    [a addObject:i];
    i = Mk(CTKSwitch, kMain, @"Вибро при листании", @"Лёгкий отклик на каждое видео", @"haptic");
    [a addObject:i];
    i = Mk(CTKSwitch, kMain, @"Заблокировать ленту", @"Защита от случайных свайпов", @"lock");
    [a addObject:i];
    i = Mk(CTKSwitch, kMain, @"Приглушить яркость", @"Только пока открыт TikTok", @"bright_on");
    [a addObject:i];
    i = Mk(CTKSlider, kMain, @"Уровень яркости", @"", @"bright_lvl");
    i.min = 10;
    i.max = 100;
    i.defNum = 50;
    [a addObject:i];
    i = Mk(CTKSwitch, kMain, @"Чистые ссылки", @"Убирает трекинг из скопированных ссылок TikTok", @"clean");
    [a addObject:i];
    i = Mk(CTKButton, kMain, @"Очистить кэш TikTok", @"Освободить место на устройстве", nil);
    i.action = ^(UIViewController *host) { [[CTOverlay shared] clearCache]; };
    [a addObject:i];
    i = Mk(CTKNote, kMain, @"", nil, nil);
    i.noteText = ^NSString *{
        return [NSString stringWithFormat:@"Сегодня: %ld видео, %ld мин в TikTok", (long)CTInt(@"stat_swipes", 0), (long)CTInt(@"stat_min", 0)];
    };
    [a addObject:i];
    i = Mk(CTKButton, kMain, @"Диагностика экрана", @"Скопировать список элементов текущего экрана TikTok", nil);
    i.action = ^(UIViewController *host) {
        NSString *dump = CTHierarchyDump();
        [UIPasteboard generalPasteboard].string = dump;
        UIAlertController *al = [UIAlertController alertControllerWithTitle:@"Скопировано"
            message:[NSString stringWithFormat:@"Описание экрана TikTok под настройками скопировано (%lu символов). Чтобы снять другой экран, закрой настройки, открой нужный раздел TikTok, зажми Крота и вызови диагностику ещё раз.", (unsigned long)dump.length]
            preferredStyle:UIAlertControllerStyleAlert];
        [al addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [host presentViewController:al animated:YES completion:nil];
    };
    [a addObject:i];
    i = Mk(CTKButton, kMain, @"Сбросить все настройки", @"Вернуть CrotTok к начальному состоянию", nil);
    i.action = ^(UIViewController *host) {
        UIAlertController *al = [UIAlertController alertControllerWithTitle:@"Сбросить настройки?" message:@"Все параметры CrotTok вернутся к стандартным." preferredStyle:UIAlertControllerStyleAlert];
        [al addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
        [al addAction:[UIAlertAction actionWithTitle:@"Сбросить" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *x) {
            NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
            for (NSString *k in [[d dictionaryRepresentation] allKeys]) {
                if ([k hasPrefix:@"crot."]) [d removeObjectForKey:k];
            }
            CTSetBool(@"mat_on", YES);
            [[CTOverlay shared] toast:@"Настройки сброшены"];
        }]];
        [host presentViewController:al animated:YES completion:nil];
    };
    [a addObject:i];
    return a;
}

static NSArray<NSDictionary *> *Cats(void) {
    return @[
        @{@"n": kNet, @"e": @"🌐", @"d": @"Регион и сетевые настройки"},
        @{@"n": kLook, @"e": @"🎨", @"d": @"Material You, акцент, форма аватарки"},
        @{@"n": kFun, @"e": @"🎭", @"d": @"Скример и шутки"},
        @{@"n": kMain, @"e": @"⚙️", @"d": @"Крот, функции ленты, система"}
    ];
}

static NSString *ChoiceText(CTItem *it) {
    if (it.strChoice) {
        NSString *cur = CTStr(it.key, it.strDef);
        for (NSDictionary *d in it.choices) if ([d[@"v"] isEqual:cur]) return d[@"t"];
        return cur;
    }
    NSInteger cur = CTInt(it.key, (NSInteger)it.defNum);
    for (NSDictionary *d in it.choices) if ([d[@"v"] integerValue] == cur) return d[@"t"];
    return [NSString stringWithFormat:@"%ld", (long)cur];
}

#pragma mark - Ячейки

@interface CTItemCell : UITableViewCell
@property (nonatomic, strong) CTItem *item;
- (void)configure:(CTItem *)it showCat:(BOOL)showCat;
@end

@implementation CTItemCell {
    UIView *_card;
    UILabel *_t, *_s, *_v, *_ch;
    CTToggle *_tg;
    UISlider *_sl;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)st reuseIdentifier:(NSString *)rid {
    self = [super initWithStyle:st reuseIdentifier:rid];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _card = [UIView new];
        _card.translatesAutoresizingMaskIntoConstraints = NO;
        _card.layer.cornerRadius = 24;
        [self.contentView addSubview:_card];

        _t = L(@"", 16, UIFontWeightSemibold, CTOnSurface());
        _s = L(@"", 12, UIFontWeightRegular, CTOnVar());
        _v = L(@"", 14, UIFontWeightMedium, CTPrimary());
        _v.numberOfLines = 1;
        [_v setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        _ch = L(@"›", 22, UIFontWeightMedium, CTOnVar());
        _tg = [CTToggle new];
        [_tg setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_tg addTarget:self action:@selector(toggled) forControlEvents:UIControlEventValueChanged];
        _sl = [UISlider new];
        [_sl addTarget:self action:@selector(slid) forControlEvents:UIControlEventValueChanged];

        UIStackView *text = Stack(UILayoutConstraintAxisVertical, 2);
        [text addArrangedSubview:_t];
        [text addArrangedSubview:_s];
        UIStackView *row = Stack(UILayoutConstraintAxisHorizontal, 10);
        row.alignment = UIStackViewAlignmentCenter;
        [row addArrangedSubview:text];
        [row addArrangedSubview:_v];
        [row addArrangedSubview:_ch];
        [row addArrangedSubview:_tg];
        UIStackView *col = Stack(UILayoutConstraintAxisVertical, 10);
        col.translatesAutoresizingMaskIntoConstraints = NO;
        [col addArrangedSubview:row];
        [col addArrangedSubview:_sl];
        [_card addSubview:col];

        [NSLayoutConstraint activateConstraints:@[
            [_card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
            [_card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
            [_card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14],
            [_card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-14],
            [col.topAnchor constraintEqualToAnchor:_card.topAnchor constant:14],
            [col.bottomAnchor constraintEqualToAnchor:_card.bottomAnchor constant:-14],
            [col.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:16],
            [col.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-16]
        ]];
    }
    return self;
}

- (void)toggled { CTSetBool(_item.key, _tg.on); }
- (void)slid { CTSetInt(_item.key, (NSInteger)_sl.value); }

- (void)configure:(CTItem *)it showCat:(BOOL)showCat {
    self.item = it;
    BOOL note = (it.kind == CTKNote);
    _card.backgroundColor = note ? [UIColor clearColor] : CTSurface();

    _t.text = it.title;
    _t.hidden = note || !it.title.length;
    _t.textColor = (it.kind == CTKButton) ? CTPrimary() : CTOnSurface();

    NSString *sub = (note && it.noteText) ? it.noteText() : it.sub;
    if (showCat && !note) sub = sub.length ? [NSString stringWithFormat:@"%@ · %@", sub, it.cat] : it.cat;
    _s.text = sub;
    _s.hidden = !sub.length;

    _tg.hidden = (it.kind != CTKSwitch);
    if (!_tg.hidden) [_tg setOn:CTBool(it.key, it.def) animated:NO];

    _sl.hidden = (it.kind != CTKSlider);
    if (!_sl.hidden) {
        _sl.minimumValue = it.min;
        _sl.maximumValue = it.max;
        _sl.value = (float)CTInt(it.key, (NSInteger)it.defNum);
        _sl.minimumTrackTintColor = CTPrimary();
    }

    BOOL hasValue = (it.kind == CTKChoice || it.kind == CTKLink);
    _v.hidden = !hasValue;
    if (hasValue) _v.text = it.valueText ? it.valueText() : ChoiceText(it);
    _v.textColor = CTPrimary();
    _ch.hidden = !(it.kind == CTKChoice || it.kind == CTKLink);
    _ch.textColor = CTOnVar();
    _s.textColor = CTOnVar();
}
@end

@interface CTCatCell : UITableViewCell
- (void)configure:(NSDictionary *)c;
@end

@implementation CTCatCell {
    UIView *_card;
    UILabel *_e, *_t, *_d, *_ch;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)st reuseIdentifier:(NSString *)rid {
    self = [super initWithStyle:st reuseIdentifier:rid];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _card = [UIView new];
        _card.translatesAutoresizingMaskIntoConstraints = NO;
        _card.layer.cornerRadius = 28;
        [self.contentView addSubview:_card];
        _e = L(@"", 30, UIFontWeightRegular, CTOnSurface());
        _t = L(@"", 18, UIFontWeightBold, CTOnSurface());
        _d = L(@"", 13, UIFontWeightRegular, CTOnVar());
        _ch = L(@"›", 26, UIFontWeightMedium, CTOnVar());
        UIStackView *text = Stack(UILayoutConstraintAxisVertical, 2);
        [text addArrangedSubview:_t];
        [text addArrangedSubview:_d];
        UIStackView *row = Stack(UILayoutConstraintAxisHorizontal, 14);
        row.alignment = UIStackViewAlignmentCenter;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [row addArrangedSubview:_e];
        [row addArrangedSubview:text];
        [row addArrangedSubview:_ch];
        [_card addSubview:row];
        [NSLayoutConstraint activateConstraints:@[
            [_card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:5],
            [_card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-5],
            [_card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14],
            [_card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-14],
            [row.topAnchor constraintEqualToAnchor:_card.topAnchor constant:18],
            [row.bottomAnchor constraintEqualToAnchor:_card.bottomAnchor constant:-18],
            [row.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:18],
            [row.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-18]
        ]];
    }
    return self;
}
- (void)configure:(NSDictionary *)c {
    _card.backgroundColor = CTSurface();
    _e.text = c[@"e"];
    _t.text = c[@"n"];
    _t.textColor = CTOnSurface();
    _d.text = c[@"d"];
    _d.textColor = CTOnVar();
    _ch.textColor = CTOnVar();
}
- (void)setHighlighted:(BOOL)h animated:(BOOL)a {
    [super setHighlighted:h animated:a];
    [UIView animateWithDuration:0.15 animations:^{ self.transform = h ? CGAffineTransformMakeScale(0.97, 0.97) : CGAffineTransformIdentity; }];
}
@end

#pragma mark - Список настроек

@interface CTListVC : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (nonatomic, copy) NSString *cat;
@end

@implementation CTListVC {
    UITableView *_table;
    NSArray *_rows;
    NSString *_query;
    UITextField *_search;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = _cat ?: @"CrotTok";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    if (!_cat) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть" style:UIBarButtonItemStylePlain target:self action:@selector(closeTapped)];
    }
    _table = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _table.dataSource = self;
    _table.delegate = self;
    _table.separatorStyle = UITableViewCellSeparatorStyleNone;
    _table.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    _table.rowHeight = UITableViewAutomaticDimension;
    _table.estimatedRowHeight = 76;
    [_table registerClass:[CTItemCell class] forCellReuseIdentifier:@"item"];
    [_table registerClass:[CTCatCell class] forCellReuseIdentifier:@"cat"];
    [self.view addSubview:_table];
    [self applyTheme];
    [self rebuild];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyTheme];
    [_table reloadData];
}

- (void)traitCollectionDidChange:(UITraitCollection *)prev {
    [super traitCollectionDidChange:prev];
    [self applyTheme];
    [_table reloadData];
}

- (void)closeTapped { [self.navigationController dismissViewControllerAnimated:YES completion:nil]; }

- (void)applyTheme {
    self.view.backgroundColor = CTBg();
    _table.backgroundColor = CTBg();
    if (self.navigationController) {
        StyleNav(self.navigationController);
        self.navigationController.navigationBar.prefersLargeTitles = YES;
    }
    if (!_cat) _table.tableHeaderView = [self searchHeader];
    else if ([_cat isEqualToString:kMain]) _table.tableHeaderView = [self petHeader];
}

- (void)rebuild {
    NSMutableArray *r = [NSMutableArray array];
    if (!_cat) {
        if (_query.length) {
            for (CTItem *i in Items()) if (i.kind != CTKNote && [i.kw localizedCaseInsensitiveContainsString:_query]) [r addObject:i];
        } else {
            [r addObjectsFromArray:Cats()];
        }
    } else {
        for (CTItem *i in Items()) if ([i.cat isEqualToString:_cat]) [r addObject:i];
    }
    _rows = r;
    [_table reloadData];
}

#pragma mark Поиск

- (UIView *)searchHeader {
    NSString *keep = _search.text;
    UIView *wrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64)];
    wrap.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _search = [[UITextField alloc] initWithFrame:CGRectMake(14, 8, wrap.bounds.size.width - 28, 48)];
    _search.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _search.backgroundColor = CTSurface();
    _search.layer.cornerRadius = 24;
    _search.textColor = CTOnSurface();
    _search.tintColor = CTPrimary();
    _search.font = [UIFont systemFontOfSize:16];
    _search.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Поиск по настройкам" attributes:@{NSForegroundColorAttributeName: CTOnVar()}];
    _search.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 18, 10)];
    _search.leftViewMode = UITextFieldViewModeAlways;
    _search.clearButtonMode = UITextFieldViewModeWhileEditing;
    _search.returnKeyType = UIReturnKeySearch;
    _search.text = keep;
    _search.delegate = self;
    [_search addTarget:self action:@selector(searchChanged) forControlEvents:UIControlEventEditingChanged];
    CTMarkSkip(_search);
    [wrap addSubview:_search];
    return wrap;
}

- (void)searchChanged {
    _query = [_search.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self rebuild];
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf { [tf resignFirstResponder]; return YES; }

#pragma mark Карточка Крота

- (UIView *)petHeader {
    CGFloat W = self.view.bounds.size.width;
    UIView *wrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, W, 400)];
    UIView *card = [UIView new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = CTContainer();
    card.layer.cornerRadius = 28;
    [wrap addSubview:card];

    UIStackView *col = Stack(UILayoutConstraintAxisVertical, 12);
    col.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:col];

    UIStackView *top = Stack(UILayoutConstraintAxisHorizontal, 12);
    top.alignment = UIStackViewAlignmentCenter;
    UIView *moleBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 84, 70)];
    [moleBox.widthAnchor constraintEqualToConstant:84].active = YES;
    [moleBox.heightAnchor constraintEqualToConstant:70].active = YES;
    CTMoleView *m = [CTMoleView new];
    m.center = CGPointMake(42, 35);
    m.transform = CGAffineTransformMakeScale(1.3, 1.3);
    CTMarkSkip(m);
    [moleBox addSubview:m];
    UIStackView *info = Stack(UILayoutConstraintAxisVertical, 2);
    UIButton *name = [UIButton buttonWithType:UIButtonTypeSystem];
    [name setTitle:[NSString stringWithFormat:@"%@  ✎", [CTPet name]] forState:UIControlStateNormal];
    name.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    [name setTitleColor:CTOnContainer() forState:UIControlStateNormal];
    name.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
    [name addTarget:self action:@selector(renamePet) forControlEvents:UIControlEventTouchUpInside];
    [info addArrangedSubview:name];
    [info addArrangedSubview:L([NSString stringWithFormat:@"%@ %@", [CTPet moodEmoji], [CTPet moodText]], 14, UIFontWeightRegular, CTOnContainer())];
    [top addArrangedSubview:moleBox];
    [top addArrangedSubview:info];
    [col addArrangedSubview:top];

    for (NSArray *b in @[@[@"Сытость", @([CTPet food])], @[@"Настроение", @([CTPet joy])]]) {
        UIStackView *row = Stack(UILayoutConstraintAxisHorizontal, 10);
        row.alignment = UIStackViewAlignmentCenter;
        UILabel *l = L(b[0], 13, UIFontWeightMedium, CTOnContainer());
        [l.widthAnchor constraintEqualToConstant:90].active = YES;
        CTBarView *bar = [CTBarView new];
        bar.progress = [b[1] doubleValue] / 100.0;
        [bar.heightAnchor constraintEqualToConstant:12].active = YES;
        [row addArrangedSubview:l];
        [row addArrangedSubview:bar];
        [col addArrangedSubview:row];
    }
    [col addArrangedSubview:L([NSString stringWithFormat:@"🍪 Печенек: %ld  ·  +1 за каждые 10 видео", (long)[CTPet coins]], 13, UIFontWeightMedium, CTOnContainer())];
    UIStackView *btns = Stack(UILayoutConstraintAxisHorizontal, 10);
    btns.distribution = UIStackViewDistributionFillEqually;
    [btns addArrangedSubview:Btn(@"Погладить", NO, self, @selector(petTapped))];
    [btns addArrangedSubview:Btn(@"Покормить 🍪", YES, self, @selector(feedTapped))];
    [col addArrangedSubview:btns];

    [NSLayoutConstraint activateConstraints:@[
        [card.topAnchor constraintEqualToAnchor:wrap.topAnchor constant:8],
        [card.bottomAnchor constraintEqualToAnchor:wrap.bottomAnchor constant:-8],
        [card.leadingAnchor constraintEqualToAnchor:wrap.leadingAnchor constant:14],
        [card.trailingAnchor constraintEqualToAnchor:wrap.trailingAnchor constant:-14],
        [col.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [col.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
        [col.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [col.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16]
    ]];
    [wrap setNeedsLayout];
    [wrap layoutIfNeeded];
    CGFloat h = [wrap systemLayoutSizeFittingSize:CGSizeMake(W, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;
    wrap.frame = CGRectMake(0, 0, W, h);
    return wrap;
}

- (void)reloadPet { _table.tableHeaderView = [self petHeader]; }
- (void)petTapped { [[CTOverlay shared] petPet]; [self reloadPet]; }
- (void)feedTapped { [[CTOverlay shared] petFeed]; [self reloadPet]; }

- (void)renamePet {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Имя питомца" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *tf) { tf.text = [CTPet name]; }];
    [a addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"Сохранить" style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
        [CTPet setName:a.textFields.firstObject.text];
        [self reloadPet];
    }]];
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark Таблица

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return _rows.count; }

- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    id row = _rows[ip.row];
    if ([row isKindOfClass:[NSDictionary class]]) {
        CTCatCell *c = [t dequeueReusableCellWithIdentifier:@"cat" forIndexPath:ip];
        [c configure:row];
        return c;
    }
    CTItemCell *c = [t dequeueReusableCellWithIdentifier:@"item" forIndexPath:ip];
    [c configure:row showCat:(!_cat && _query.length > 0)];
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [t deselectRowAtIndexPath:ip animated:YES];
    id row = _rows[ip.row];
    if ([row isKindOfClass:[NSDictionary class]]) {
        CTListVC *vc = [CTListVC new];
        vc.cat = row[@"n"];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    CTItem *it = row;
    if (it.kind == CTKChoice) {
        [self pick:it];
    } else if ((it.kind == CTKButton || it.kind == CTKLink) && it.action) {
        it.action(self);
    }
}

- (void)pick:(CTItem *)it {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:it.title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSDictionary *d in it.choices) {
        [a addAction:[UIAlertAction actionWithTitle:d[@"t"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *x) {
            if (it.strChoice) CTSetStr(it.key, d[@"v"]);
            else CTSetInt(it.key, [d[@"v"] integerValue]);
            [self->_table reloadData];
        }]];
    }
    [a addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    a.popoverPresentationController.sourceView = self.view;
    a.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, 1, 1);
    [self presentViewController:a animated:YES completion:nil];
}

@end

#pragma mark - Акцентный цвет

@interface CTAccentVC : UIViewController <UITextFieldDelegate>
@end

@implementation CTAccentVC {
    UIScrollView *_scroll;
    UIStackView *_stack;
    UITextField *_hex;
    UILabel *_msg;
    unsigned int _preview;
    NSString *_hexKeep;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Акцентный цвет";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    _preview = CTCurrentPrimaryHex();
    _scroll = [UIScrollView new];
    _scroll.translatesAutoresizingMaskIntoConstraints = NO;
    _scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:_scroll];
    _stack = Stack(UILayoutConstraintAxisVertical, 14);
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scroll addSubview:_stack];
    [NSLayoutConstraint activateConstraints:@[
        [_scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_stack.topAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.topAnchor constant:12],
        [_stack.bottomAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.bottomAnchor constant:-40],
        [_stack.leadingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.leadingAnchor constant:16],
        [_stack.trailingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.trailingAnchor constant:-16],
        [_stack.widthAnchor constraintEqualToAnchor:_scroll.frameLayoutGuide.widthAnchor constant:-32]
    ]];
    [self build];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    StyleNav(self.navigationController);
}

- (void)build {
    self.view.backgroundColor = CTBg();
    for (UIView *v in [_stack.arrangedSubviews copy]) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    [_stack addArrangedSubview:[self previewCard]];

    UIView *pal = [UIView new];
    pal.backgroundColor = CTSurface();
    pal.layer.cornerRadius = 28;
    UIStackView *pc = Stack(UILayoutConstraintAxisVertical, 12);
    pc.translatesAutoresizingMaskIntoConstraints = NO;
    [pc addArrangedSubview:L(@"Палитра", 18, UIFontWeightBold, CTOnSurface())];
    NSArray *colors = CTPalettes();
    for (int r = 0; r < 2; r++) {
        UIStackView *row = Stack(UILayoutConstraintAxisHorizontal, 12);
        row.distribution = UIStackViewDistributionFillEqually;
        for (int c = 0; c < 4; c++) {
            NSInteger idx = r * 4 + c;
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.tag = idx;
            unsigned int p = [colors[idx][@"p"] unsignedIntValue];
            b.backgroundColor = CTHex(p);
            b.layer.cornerRadius = 22;
            [b.heightAnchor constraintEqualToConstant:44].active = YES;
            if (p == _preview) {
                b.layer.borderWidth = 3;
                b.layer.borderColor = CTOnSurface().CGColor;
            }
            [b addTarget:self action:@selector(paletteTapped:) forControlEvents:UIControlEventTouchUpInside];
            [row addArrangedSubview:b];
        }
        [pc addArrangedSubview:row];
    }
    [pal addSubview:pc];
    [NSLayoutConstraint activateConstraints:@[
        [pc.topAnchor constraintEqualToAnchor:pal.topAnchor constant:16],
        [pc.bottomAnchor constraintEqualToAnchor:pal.bottomAnchor constant:-16],
        [pc.leadingAnchor constraintEqualToAnchor:pal.leadingAnchor constant:16],
        [pc.trailingAnchor constraintEqualToAnchor:pal.trailingAnchor constant:-16]
    ]];
    [_stack addArrangedSubview:pal];

    UIView *hx = [UIView new];
    hx.backgroundColor = CTSurface();
    hx.layer.cornerRadius = 28;
    UIStackView *hc = Stack(UILayoutConstraintAxisVertical, 10);
    hc.translatesAutoresizingMaskIntoConstraints = NO;
    [hc addArrangedSubview:L(@"Свой цвет (HEX)", 18, UIFontWeightBold, CTOnSurface())];
    _hex = [UITextField new];
    _hex.placeholder = @"Например 7E57D1";
    _hex.text = _hexKeep ?: CTHexString(_preview);
    _hex.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    _hex.autocorrectionType = UITextAutocorrectionTypeNo;
    _hex.textColor = CTOnSurface();
    _hex.tintColor = CTPrimary();
    _hex.backgroundColor = CTContainer();
    _hex.layer.cornerRadius = 22;
    _hex.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 10)];
    _hex.leftViewMode = UITextFieldViewModeAlways;
    _hex.delegate = self;
    [_hex.heightAnchor constraintEqualToConstant:44].active = YES;
    [_hex addTarget:self action:@selector(hexChanged) forControlEvents:UIControlEventEditingChanged];
    CTMarkSkip(_hex);
    [hc addArrangedSubview:_hex];
    UIStackView *br = Stack(UILayoutConstraintAxisHorizontal, 10);
    br.distribution = UIStackViewDistributionFillEqually;
    [br addArrangedSubview:Btn(@"Сбросить", NO, self, @selector(resetTapped))];
    [br addArrangedSubview:Btn(@"Применить", YES, self, @selector(applyTapped))];
    [hc addArrangedSubview:br];
    _msg = L(@"", 12, UIFontWeightMedium, CTOnVar());
    [hc addArrangedSubview:_msg];
    [hx addSubview:hc];
    [NSLayoutConstraint activateConstraints:@[
        [hc.topAnchor constraintEqualToAnchor:hx.topAnchor constant:16],
        [hc.bottomAnchor constraintEqualToAnchor:hx.bottomAnchor constant:-16],
        [hc.leadingAnchor constraintEqualToAnchor:hx.leadingAnchor constant:16],
        [hc.trailingAnchor constraintEqualToAnchor:hx.trailingAnchor constant:-16]
    ]];
    [_stack addArrangedSubview:hx];
}

- (UIView *)previewCard {
    BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    UIColor *p = CTHex(_preview);
    UIColor *cont = CTHex(dark ? CTMix(_preview, 0x000000, 0.55) : CTMix(_preview, 0xFFFFFF, 0.78));
    UIColor *onCont = CTHex(dark ? CTMix(_preview, 0xFFFFFF, 0.8) : CTMix(_preview, 0x000000, 0.6));
    CGFloat lum = (((_preview >> 16) & 0xFF) * 0.2126 + ((_preview >> 8) & 0xFF) * 0.7152 + (_preview & 0xFF) * 0.0722) / 255.0;
    UIColor *onP = lum > 0.55 ? [UIColor blackColor] : [UIColor whiteColor];

    UIView *card = [UIView new];
    card.backgroundColor = cont;
    card.layer.cornerRadius = 28;
    UIStackView *col = Stack(UILayoutConstraintAxisVertical, 12);
    col.translatesAutoresizingMaskIntoConstraints = NO;
    [col addArrangedSubview:L(@"Предпросмотр", 18, UIFontWeightBold, onCont)];

    UIStackView *row = Stack(UILayoutConstraintAxisHorizontal, 12);
    row.alignment = UIStackViewAlignmentCenter;
    UILabel *btn = L(@"Кнопка", 15, UIFontWeightSemibold, onP);
    btn.textAlignment = NSTextAlignmentCenter;
    btn.backgroundColor = p;
    btn.layer.cornerRadius = 20;
    btn.clipsToBounds = YES;
    [btn.widthAnchor constraintEqualToConstant:100].active = YES;
    [btn.heightAnchor constraintEqualToConstant:40].active = YES;
    UIView *track = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 52, 32)];
    track.backgroundColor = p;
    track.layer.cornerRadius = 16;
    UIView *thumb = [[UIView alloc] initWithFrame:CGRectMake(24, 4, 24, 24)];
    thumb.backgroundColor = onP;
    thumb.layer.cornerRadius = 12;
    [track addSubview:thumb];
    [track.widthAnchor constraintEqualToConstant:52].active = YES;
    [track.heightAnchor constraintEqualToConstant:32].active = YES;
    NSInteger shape = CTInt(@"avatar_shape", 0);
    UILabel *av = L(@"К", 20, UIFontWeightBold, onP);
    av.textAlignment = NSTextAlignmentCenter;
    av.backgroundColor = p;
    av.clipsToBounds = YES;
    [av.widthAnchor constraintEqualToConstant:44].active = YES;
    [av.heightAnchor constraintEqualToConstant:44].active = YES;
    av.layer.cornerRadius = shape == 1 ? 13 : (shape == 2 ? 0 : 22);
    CTMarkSkip(av);
    [row addArrangedSubview:btn];
    [row addArrangedSubview:track];
    [row addArrangedSubview:av];
    [col addArrangedSubview:row];
    [col addArrangedSubview:L([NSString stringWithFormat:@"#%@", CTHexString(_preview)], 14, UIFontWeightMedium, onCont)];
    [card addSubview:col];
    [NSLayoutConstraint activateConstraints:@[
        [col.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [col.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16],
        [col.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [col.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16]
    ]];
    return card;
}

- (void)paletteTapped:(UIButton *)b {
    CTSetStr(@"accent_hex", @"");
    CTSetInt(@"accent", b.tag);
    _preview = CTCurrentPrimaryHex();
    _hexKeep = nil;
    [self build];
    StyleNav(self.navigationController);
}

- (void)hexChanged {
    unsigned int v;
    if (CTParseHex(_hex.text, &v)) {
        _preview = v;
        _msg.text = @"";
        UIView *old = _stack.arrangedSubviews.firstObject;
        UIView *fresh = [self previewCard];
        [_stack insertArrangedSubview:fresh atIndex:0];
        [_stack removeArrangedSubview:old];
        [old removeFromSuperview];
    } else {
        _msg.text = @"Нужно 6 символов: цифры 0–9 и буквы A–F";
    }
}

- (void)applyTapped {
    unsigned int v;
    if (!CTParseHex(_hex.text, &v)) {
        _msg.text = @"Нужно 6 символов: цифры 0–9 и буквы A–F";
        return;
    }
    [_hex resignFirstResponder];
    CTSetStr(@"accent_hex", CTHexString(v));
    _preview = v;
    _hexKeep = CTHexString(v);
    [self build];
    _msg.text = @"Применено ✓";
    StyleNav(self.navigationController);
}

- (void)resetTapped {
    [_hex resignFirstResponder];
    CTResetAccent();
    _preview = CTCurrentPrimaryHex();
    _hexKeep = nil;
    [self build];
    _msg.text = @"Цвет сброшен к стандартному";
    StyleNav(self.navigationController);
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf { [tf resignFirstResponder]; return YES; }

- (void)traitCollectionDidChange:(UITraitCollection *)prev {
    [super traitCollectionDidChange:prev];
    [self build];
}

@end

static UIViewController *MakeAccentVC(void) { return [CTAccentVC new]; }

#pragma mark - Форма аватарки

@interface CTAvatarVC : UIViewController
@end

@implementation CTAvatarVC {
    UIStackView *_stack;
    UIScrollView *_scroll;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Форма аватарки";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    _scroll = [UIScrollView new];
    _scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_scroll];
    _stack = Stack(UILayoutConstraintAxisVertical, 12);
    _stack.translatesAutoresizingMaskIntoConstraints = NO;
    [_scroll addSubview:_stack];
    [NSLayoutConstraint activateConstraints:@[
        [_scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_stack.topAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.topAnchor constant:12],
        [_stack.bottomAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.bottomAnchor constant:-40],
        [_stack.leadingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.leadingAnchor constant:16],
        [_stack.trailingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.trailingAnchor constant:-16],
        [_stack.widthAnchor constraintEqualToAnchor:_scroll.frameLayoutGuide.widthAnchor constant:-32]
    ]];
    [self build];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    StyleNav(self.navigationController);
}

- (UIView *)sampleForShape:(NSInteger)s size:(CGFloat)size {
    CGFloat w = (s == 3) ? size * 1.6 : size;
    UILabel *l = L(@"К", size * 0.42, UIFontWeightBold, CTOnPrimary());
    l.textAlignment = NSTextAlignmentCenter;
    l.backgroundColor = CTPrimary();
    l.clipsToBounds = YES;
    l.frame = CGRectMake(0, 0, w, size);
    l.layer.cornerRadius = (s == 1) ? size * 0.3 : ((s == 2) ? 0 : size / 2);
    if (s == 1) l.layer.cornerCurve = kCACornerCurveContinuous;
    [l.widthAnchor constraintEqualToConstant:w].active = YES;
    [l.heightAnchor constraintEqualToConstant:size].active = YES;
    CTMarkSkip(l);
    return l;
}

- (void)build {
    self.view.backgroundColor = CTBg();
    for (UIView *v in [_stack.arrangedSubviews copy]) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    NSInteger cur = CTInt(@"avatar_shape", 0);

    UIView *big = [UIView new];
    big.backgroundColor = CTContainer();
    big.layer.cornerRadius = 28;
    UIStackView *bc = Stack(UILayoutConstraintAxisVertical, 12);
    bc.alignment = UIStackViewAlignmentCenter;
    bc.translatesAutoresizingMaskIntoConstraints = NO;
    [bc addArrangedSubview:L(@"Предпросмотр", 14, UIFontWeightMedium, CTOnContainer())];
    [bc addArrangedSubview:[self sampleForShape:cur size:96]];
    [bc addArrangedSubview:L(ShapeName(cur), 18, UIFontWeightBold, CTOnContainer())];
    [big addSubview:bc];
    [NSLayoutConstraint activateConstraints:@[
        [bc.topAnchor constraintEqualToAnchor:big.topAnchor constant:18],
        [bc.bottomAnchor constraintEqualToAnchor:big.bottomAnchor constant:-18],
        [bc.leadingAnchor constraintEqualToAnchor:big.leadingAnchor constant:16],
        [bc.trailingAnchor constraintEqualToAnchor:big.trailingAnchor constant:-16]
    ]];
    [_stack addArrangedSubview:big];

    NSArray *descs = @[@"Как в TikTok по умолчанию", @"Мягкие углы, как в Material You", @"Строгие прямые углы", @"Закруглённые края. У квадратной аватарки выглядит как круг, форма заметна у прямоугольных"];
    for (NSInteger i = 0; i < 4; i++) {
        UIControl *card = [UIControl new];
        card.tag = i;
        card.backgroundColor = CTSurface();
        card.layer.cornerRadius = 24;
        if (i == cur) {
            card.layer.borderWidth = 2;
            card.layer.borderColor = CTPrimary().CGColor;
        }
        UIStackView *row = Stack(UILayoutConstraintAxisHorizontal, 14);
        row.alignment = UIStackViewAlignmentCenter;
        row.userInteractionEnabled = NO;
        row.translatesAutoresizingMaskIntoConstraints = NO;
        UIView *smp = [self sampleForShape:i size:48];
        UIView *smpBox = [[UIView alloc] init];
        [smpBox.widthAnchor constraintEqualToConstant:78].active = YES;
        [smpBox.heightAnchor constraintEqualToConstant:48].active = YES;
        smp.translatesAutoresizingMaskIntoConstraints = NO;
        [smpBox addSubview:smp];
        [smp.centerXAnchor constraintEqualToAnchor:smpBox.centerXAnchor].active = YES;
        [smp.centerYAnchor constraintEqualToAnchor:smpBox.centerYAnchor].active = YES;
        UIStackView *text = Stack(UILayoutConstraintAxisVertical, 2);
        [text addArrangedSubview:L(ShapeName(i), 16, UIFontWeightSemibold, CTOnSurface())];
        [text addArrangedSubview:L(descs[i], 12, UIFontWeightRegular, CTOnVar())];
        UILabel *mark = L(i == cur ? @"✓" : @"", 20, UIFontWeightBold, CTPrimary());
        [row addArrangedSubview:smpBox];
        [row addArrangedSubview:text];
        [row addArrangedSubview:mark];
        [card addSubview:row];
        [NSLayoutConstraint activateConstraints:@[
            [row.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
            [row.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
            [row.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
            [row.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16]
        ]];
        [card addTarget:self action:@selector(pickShape:) forControlEvents:UIControlEventTouchUpInside];
        [_stack addArrangedSubview:card];
    }
    UILabel *foot = L(@"Форма применяется к круглым аватаркам TikTok: в профилях, комментариях, ленте и списках. Для этого CrotTok находит круглые картинки по размеру и скруглению.", 12, UIFontWeightRegular, CTOnVar());
    [_stack addArrangedSubview:foot];
}

- (void)pickShape:(UIControl *)c {
    CTSetInt(@"avatar_shape", c.tag);
    [self build];
}

- (void)traitCollectionDidChange:(UITraitCollection *)prev {
    [super traitCollectionDidChange:prev];
    [self build];
}

@end

static UIViewController *MakeAvatarVC(void) { return [CTAvatarVC new]; }

#pragma mark - Показ настроек

@implementation CTSettings

+ (void)presentFrom:(UIViewController *)host {
    if (!host) host = CTTopVC();
    if (!host) return;
    if ([host.presentedViewController isKindOfClass:[UINavigationController class]]) return;
    CTListVC *root = [CTListVC new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    nav.navigationBar.prefersLargeTitles = YES;
    StyleNav(nav);
    [host presentViewController:nav animated:YES completion:nil];
}

@end
