export THEOS = /home/nqn/theos
ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
IGNORE_WARNINGS = 1
# THEOS_PACKAGE_SCHEME = rootless
TARGET = iphone:clang:latest:13.6

include $(THEOS)/makefiles/common.mk

FRAMEWORK_NAME = AWSCognito



# $(TWEAK_NAME)_FILES = ImGuiDrawView.mm $(wildcard Esp/*.mm) $(wildcard Esp/*.m) $(SECURITY_SRC) $(LOADVIEW_SRC) $(IMGUI_SRC) $(wildcard FileRac/*.m) $(wildcard FileRac/*.mm) $(wildcard FileRac/SSZipArchive/*.m) $(wildcard FileRac/SSZipArchive/minizip/*.m) $(wildcard hook/*.c)

# $(TWEAK_NAME)_FRAMEWORKS =  UIKit Foundation Security QuartzCore CoreGraphics CoreText  AVFoundation Accelerate GLKit SystemConfiguration GameController UIKit SafariServices Accelerate Foundation QuartzCore CoreGraphics AudioToolbox CoreText Metal MobileCoreServices Security SystemConfiguration IOKit CoreTelephony CoreImage CFNetwork AdSupport AVFoundation 

SECURITY_SRC = $(wildcard Security/*.mm) $(wildcard Security/oxorany/*.cpp)
LOADVIEW_SRC = $(wildcard LoadView/*.mm) $(wildcard LoadView/*.m)
IMGUI_SRC = $(wildcard IMGUI/*.cpp) $(wildcard IMGUI/*.mm)

$(FRAMEWORK_NAME)_CCFLAGS = -std=c++17 -fno-rtti -fno-exceptions -DNDEBUG -Wall -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value -Wno-unused-function -fvisibility=hidden -fexceptions

$(FRAMEWORK_NAME)_CFLAGS = -fobjc-arc -Wall -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value -Wno-unused-function -fvisibility=hidden
$(FRAMEWORK_NAME)_LDFLAGS = hok/libdaubuoi.a hok/libmonostring.a main.a Esp/libAPIKey.a
ifeq ($(IGNORE_WARNINGS),1)
  $(FRAMEWORK_NAME)_CFLAGS += -w 
  $(FRAMEWORK_NAME)_CCFLAGS += -w
endif

$(FRAMEWORK_NAME)_FILES = ImGuiDrawView.mm $(wildcard Esp/*.mm) $(wildcard Esp/*.m) $(SECURITY_SRC) $(LOADVIEW_SRC) $(IMGUI_SRC) $(wildcard FileRac/*.m) $(wildcard FileRac/*.mm) $(wildcard FileRac/SSZipArchive/*.m) $(wildcard FileRac/SSZipArchive/minizip/*.m) $(wildcard hook/*.c) $(wildcard AntiHook/*.c) $(wildcard AntiHook/*.m)

$(FRAMEWORK_NAME)_FRAMEWORKS =  UIKit Foundation Security QuartzCore CoreGraphics CoreText  AVFoundation Accelerate GLKit SystemConfiguration GameController UIKit SafariServices Accelerate Foundation QuartzCore CoreGraphics AudioToolbox CoreText Metal MobileCoreServices Security SystemConfiguration IOKit CoreTelephony CoreImage CFNetwork AdSupport AVFoundation 





include $(THEOS_MAKE_PATH)/framework.mk