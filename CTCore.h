#import <UIKit/UIKit.h>

/// Верхний контроллер приложения TikTok (не наше окно)
UIViewController *CTTopVC(void);
/// Вью принадлежит экрану CrotTok (его не нужно перекрашивать)
BOOL CTOwnedByCT(UIView *v);
void CTMarkSkip(UIView *v);

// Тема Material You на стандартных элементах UIKit
void CTThemeApplyWindow(UIWindow *w);
void CTThemeApplyControl(UIView *v);
void CTThemeRefreshAll(void);

// Форма аватарок
void CTAvatarCheck(UIView *v);
void CTAvatarRefreshAll(void);

// Вход CrotTok в настройки TikTok и диагностика
void CTInjectCheck(UIViewController *vc);
NSString *CTHierarchyDump(void);
