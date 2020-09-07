LIBRARY_NAME = librocketbootstrap
librocketbootstrap_FILES = Tweak.x Shims.x
librocketbootstrap_LIBRARIES = substrate
librocketbootstrap_FRAMEWORKS = Foundation
librocketbootstrap_USE_MODULES = 0

ADDITIONAL_CFLAGS = -std=c99 -Ioverlayheaders

arm64_CFLAGS += -Idefaultheaders
arm64e_CFLAGS += -Idefaultheaders
IPHONE_ARCHS = arm64 arm64e
TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 = 7.0
TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64e = 12.0

include framework/makefiles/common.mk
include framework/makefiles/library.mk
include framework/makefiles/tool.mk

stage::
	mkdir -p "$(THEOS_STAGING_DIR)/usr/include"
	cp -a rocketbootstrap.h rocketbootstrap_dynamic.h "$(THEOS_STAGING_DIR)/usr/include"
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/RocketBootstrap.plist"
	plutil -convert binary1 "$(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.rpetrich.rocketbootstrapd.plist"
