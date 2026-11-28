TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CrotTok

CrotTok_FILES = Tweak.x CTConfig.m CTRegion.m CTMaterial.m CTPet.m CTMole.m CTCore.m CTSettings.m CTOverlay.m
CrotTok_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable
CrotTok_FRAMEWORKS = UIKit CoreTelephony QuartzCore AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk
