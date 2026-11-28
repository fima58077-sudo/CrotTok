#import "CTMole.h"

static CAShapeLayer *Oval(CGRect r, UIColor *c) {
    CAShapeLayer *l = [CAShapeLayer layer];
    l.path = [UIBezierPath bezierPathWithOvalInRect:r].CGPath;
    l.fillColor = c.CGColor;
    return l;
}

@implementation CTMoleView {
    CALayer *_wrap;
    CAShapeLayer *_body, *_head, *_nose, *_eye, *_foot1, *_foot2, *_tail;
    UILabel *_zzz;
    BOOL _sleeping;
    BOOL _closed;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(0, 0, 60, 48)];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _wrap = [CALayer layer];
        _wrap.frame = CGRectMake(0, 0, 60, 48);
        [self.layer addSublayer:_wrap];

        UIColor *fur = [UIColor colorWithRed:0.35 green:0.29 blue:0.32 alpha:1];
        UIColor *pink = [UIColor colorWithRed:1.0 green:0.56 blue:0.64 alpha:1];
        UIColor *paw = [UIColor colorWithRed:0.95 green:0.72 blue:0.66 alpha:1];

        _tail = Oval(CGRectMake(0, 24, 9, 5), fur);
        _foot1 = Oval(CGRectMake(12, 37, 13, 8), paw);
        _foot2 = Oval(CGRectMake(30, 37, 13, 8), paw);
        _body = Oval(CGRectMake(4, 12, 40, 30), fur);
        _head = Oval(CGRectMake(30, 8, 26, 24), fur);
        _nose = Oval(CGRectMake(50, 17, 9, 8), pink);
        _eye = [CAShapeLayer layer];
        [self openEye];
        for (CALayer *l in @[_tail, _foot1, _foot2, _body, _head, _nose, _eye]) [_wrap addSublayer:l];

        _zzz = [UILabel new];
        _zzz.text = @"💤";
        _zzz.font = [UIFont systemFontOfSize:14];
        _zzz.frame = CGRectMake(40, -12, 20, 18);
        _zzz.alpha = 0;
        [self addSubview:_zzz];
        _facingRight = YES;
    }
    return self;
}

- (void)openEye {
    _closed = NO;
    _eye.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(41.5, 14.5, 4, 4)].CGPath;
    _eye.fillColor = [UIColor blackColor].CGColor;
    _eye.strokeColor = nil;
}

- (void)closeEye {
    _closed = YES;
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(40, 17.5)];
    [p addQuadCurveToPoint:CGPointMake(46, 17.5) controlPoint:CGPointMake(43, 12.5)];
    _eye.path = p.CGPath;
    _eye.fillColor = nil;
    _eye.strokeColor = [UIColor blackColor].CGColor;
    _eye.lineWidth = 1.6;
    _eye.lineCap = kCALineCapRound;
}

- (void)setFacingRight:(BOOL)right {
    _facingRight = right;
    _wrap.transform = right ? CATransform3DIdentity : CATransform3DMakeScale(-1, 1, 1);
}

- (CABasicAnimation *)anim:(NSString *)path from:(double)a to:(double)b dur:(double)d {
    CABasicAnimation *x = [CABasicAnimation animationWithKeyPath:path];
    x.fromValue = @(a);
    x.toValue = @(b);
    x.duration = d;
    x.autoreverses = YES;
    x.repeatCount = HUGE_VALF;
    x.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return x;
}

- (void)startWalking {
    if (_sleeping) return;
    [_foot1 addAnimation:[self anim:@"transform.translation.x" from:-3 to:3 dur:0.2] forKey:@"walk"];
    [_foot2 addAnimation:[self anim:@"transform.translation.x" from:3 to:-3 dur:0.2] forKey:@"walk"];
    for (CALayer *l in @[_body, _head, _nose, _eye]) {
        [l addAnimation:[self anim:@"transform.translation.y" from:0 to:-1.5 dur:0.2] forKey:@"walk"];
    }
}

- (void)stopWalking {
    for (CALayer *l in @[_foot1, _foot2, _body, _head, _nose, _eye]) [l removeAnimationForKey:@"walk"];
}

- (void)happy {
    [self closeEye];
    CAKeyframeAnimation *rot = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    rot.values = @[@0, @(-0.14), @0.14, @(-0.14), @0.14, @0];
    rot.duration = 0.8;
    [_wrap addAnimation:rot forKey:@"happy"];
    CAKeyframeAnimation *pulse = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    pulse.values = @[@0, @(-6), @0, @(-4), @0];
    pulse.duration = 0.8;
    [_wrap addAnimation:pulse forKey:@"jump"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self->_sleeping) [self openEye];
    });
}

- (void)eat {
    UILabel *cookie = [UILabel new];
    cookie.text = @"🍪";
    cookie.font = [UIFont systemFontOfSize:16];
    [cookie sizeToFit];
    cookie.center = CGPointMake(_facingRight ? 58 : 2, 22);
    [self addSubview:cookie];
    [UIView animateWithDuration:0.9 animations:^{
        cookie.transform = CGAffineTransformMakeScale(0.2, 0.2);
        cookie.alpha = 0;
        cookie.center = CGPointMake(self->_facingRight ? 50 : 10, 24);
    } completion:^(BOOL f) { [cookie removeFromSuperview]; }];

    CAKeyframeAnimation *chew = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.y"];
    chew.values = @[@0, @2, @0, @2, @0, @2, @0];
    chew.duration = 0.9;
    for (CALayer *l in @[_head, _nose, _eye]) [l addAnimation:chew forKey:@"chew"];
    [self happy];
}

- (void)setSleeping:(BOOL)sleeping {
    if (_sleeping == sleeping) return;
    _sleeping = sleeping;
    if (sleeping) {
        [self stopWalking];
        [self closeEye];
        [UIView animateWithDuration:1.2 delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
            self->_zzz.alpha = 1;
            self->_zzz.transform = CGAffineTransformMakeTranslation(0, -5);
        } completion:nil];
    } else {
        [_zzz.layer removeAllAnimations];
        _zzz.alpha = 0;
        _zzz.transform = CGAffineTransformIdentity;
        [self openEye];
    }
}

@end
