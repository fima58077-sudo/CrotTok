#import "CTConfig.h"

NSString *const CTChanged = @"CrotTokChanged";

static NSString *K(NSString *k) { return [@"crot." stringByAppendingString:k]; }

static void Notify(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:CTChanged object:nil];
    });
}

BOOL CTBool(NSString *key, BOOL def) {
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:K(key)];
    return v ? [v boolValue] : def;
}

void CTSetBool(NSString *key, BOOL v) {
    [[NSUserDefaults standardUserDefaults] setBool:v forKey:K(key)];
    Notify();
}

NSInteger CTInt(NSString *key, NSInteger def) {
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:K(key)];
    return v ? [v integerValue] : def;
}

void CTSetInt(NSString *key, NSInteger v) {
    [[NSUserDefaults standardUserDefaults] setInteger:v forKey:K(key)];
    Notify();
}

void CTSetIntQuiet(NSString *key, NSInteger v) {
    [[NSUserDefaults standardUserDefaults] setInteger:v forKey:K(key)];
}

NSString *CTStr(NSString *key, NSString *def) {
    NSString *v = [[NSUserDefaults standardUserDefaults] stringForKey:K(key)];
    return v.length ? v : def;
}

void CTSetStr(NSString *key, NSString *v) {
    [[NSUserDefaults standardUserDefaults] setObject:v forKey:K(key)];
    Notify();
}
