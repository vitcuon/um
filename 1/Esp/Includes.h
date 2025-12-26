#include <MetalKit/MetalKit.h>
#include <Metal/Metal.h>
#include <iostream>
#import <QuartzCore/QuartzCore.h>
#include <UIKit/UIKit.h>
#include <vector>
#import "pthread.h"
#include <array>


#import "ImGuiDrawView.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_internal.h"
#import "IMGUI/imgui_impl_metal.h"



#include "Utils/hack/monoString.h"
#include "Utils/EspManager.h"
#include "Utils/Monostring.h"
#include "Utils/Alert.h"
#include "Utils/Color.hpp"


#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale

extern UIView* hideRecordView;
extern UITextField* hideRecordTextfield;