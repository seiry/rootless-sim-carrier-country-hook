ARCHS = arm64 arm64e
TARGET = iphone:clang:14.5
INSTALL_TARGET_PROCESSES = TikTok

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

PREFIX = $(THEOS)/toolchain/XcodeDefault.xctoolchain/usr/bin/

TWEAK_NAME = TikTokUSregion

TikTokUSregion_FILES = $(wildcard *.xm *.m)
TikTokUSregion_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-nullability-completeness -std=c++11

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 TikTok"