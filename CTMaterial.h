#import <UIKit/UIKit.h>

UIColor *CTHex(unsigned int v);
UIColor *CTDyn(unsigned int light, unsigned int dark);
unsigned int CTMix(unsigned int a, unsigned int b, CGFloat t);
NSArray<NSDictionary *> *CTPalettes(void);
NSInteger CTAccentIndex(void);

UIColor *CTBg(void);
UIColor *CTSurface(void);
UIColor *CTOnSurface(void);
UIColor *CTOnVar(void);
UIColor *CTPrimary(void);
UIColor *CTContainer(void);
UIColor *CTOnContainer(void);
UIColor *CTOnPrimary(void);

BOOL CTParseHex(NSString *s, unsigned int *out);
NSString *CTHexString(unsigned int v);
unsigned int CTCurrentPrimaryHex(void);
void CTResetAccent(void);
