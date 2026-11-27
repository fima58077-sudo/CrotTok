#import <Foundation/Foundation.h>

extern NSString *const CTChanged;

BOOL CTBool(NSString *key, BOOL def);
void CTSetBool(NSString *key, BOOL v);
NSInteger CTInt(NSString *key, NSInteger def);
void CTSetInt(NSString *key, NSInteger v);
void CTSetIntQuiet(NSString *key, NSInteger v);
NSString *CTStr(NSString *key, NSString *def);
void CTSetStr(NSString *key, NSString *v);
