
#include "Esp/Includes.h"
#include <Foundation/Foundation.h>
#include <libgen.h>
#include <mach-o/dyld.h>
#include <mach-o/fat.h>
#include <mach-o/loader.h>
#include <mach/vm_page_size.h>
#include <unistd.h>
#include <array>
#include <deque>
#include <map>
#include <unordered_map>
#include <vector>
#include <algorithm>
#import "IMGUI/Il2cpp.h"
#include "font.h"
#import "va.h"
#import "il2cpp.h"
#import "Esp/CaptainHook.h"
#import "Esp/ImGuiDrawView.h"
#import "IMGUI/stb_image.h"
#import "Utils/Macros.h"
#import "Utils/hack/Function.h"
#import "IMGUI/imgui_additional.h"
#import "IMGUI/bdvt.h"
#import "mahoa.h"
#import "hok/dobby.h"
#import "hok/MonoString.h"
#import "hook/hook.h"
#include <CoreFoundation/CoreFoundation.h>
#include "Utils/hack/Vector2.h"
#import "Utils/hack/Vector3.h"
#include "Utils/hack/VInt3.h"
#import "IMAGE.h"
#include <limits>
#include "Utils/Quaternion.h"
#import <UIKit/UIKit.h>
#include <chrono>
#import "AntiHook/AntiHooK.h"
#include <iomanip>
#include "Custom/Watermark.h"
#include "Custom/Settings.h"
#include "Fonts/fire.h"
#include "Fonts/Iconcpp.h"
#include "Fonts/Icon.h"
#include <cstring> 
#include <cstdio>  
#import <CFNetwork/CFNetwork.h>
#include "json.hpp"

static bool AutoXoaTo = false;
void (*_HandleGameSettle)(bool bSuccess, bool bShouldDisplayWinLose, byte GameResult, void* svrData);
void HandleGameSettle(bool bSuccess, bool bShouldDisplayWinLose, byte GameResult, void* svrData)
{
    if (AutoXoaTo)
    {
        bSuccess = false;
        bShouldDisplayWinLose = false;
        GameResult = (byte)0;
        svrData = NULL;
    }
    _HandleGameSettle(bSuccess, bShouldDisplayWinLose, GameResult, svrData);
}
void (*old_SendSyncData)(void *instance, bool isFightOver, unsigned long long hashCode);
void SendSyncData(void *instance, bool isFightOver, unsigned long long hashCode) {
    if (instance != NULL) {
        if (AutoXoaTo) {
            if (isFightOver) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)),dispatch_get_main_queue(),^{
                            AntiHooK = false;
                    });
            }
            return;
        }
    }
    old_SendSyncData(instance, isFightOver, hashCode);
}


static bool spamchat = false;
void (*_SendInBattleMsg_InputChat)(const char *content, uint8_t camp);
void SendInBattleMsg_InputChat(const char *content, uint8_t camp)
{
    if (content != NULL) {
        if (spamchat) { 
           
            for (int i = 0; i < 20; i++) {
                _SendInBattleMsg_InputChat(content, camp);
            }
        } else {
            _SendInBattleMsg_InputChat(content, camp);
        }
    }
    return;
}

bool isVPNConnected() {
    CFDictionaryRef proxySettingsRef = CFNetworkCopySystemProxySettings();
    if (!proxySettingsRef) {
        return false;
    }

    NSDictionary *proxySettings = (__bridge_transfer NSDictionary *)proxySettingsRef;

    if ([[proxySettings objectForKey:(NSString *)kCFNetworkProxiesHTTPEnable] boolValue] ||
        [proxySettings objectForKey:(NSString *)kCFNetworkProxiesHTTPProxy]) {
        return true;
    }

    return false;
}

NSString *ver = @"1.0";

#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale



using namespace IL2Cpp;
@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
- (void)activehack;
- (void)notifycooldown;
@end


NSUserDefaults *saveSetting = [NSUserDefaults standardUserDefaults];
NSFileManager *fileManager1 = [NSFileManager defaultManager];
NSString *documentDir1 = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];

static float tabContentOffsetY[5] = {20.0f, 20.0f, 20.0f, 20.0f, 20.0f};
static float tabContentAlpha[5] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f};
static int selectedTab = 0;
const float BUTTON_WIDTH = 45.0f;
const float BUTTON_HEIGHT = 35.0f;
void DrawCustomButton(const char* label, ImVec2 size, int tabId, int& selectedTab) {
         ImGui::SetWindowFontScale(0.9f);
    ImVec2 pos = ImGui::GetCursorScreenPos(); // Lấy vị trí hiện tại
    ImDrawList* drawList = ImGui::GetWindowDrawList(); // Lấy danh sách vẽ

    // Invisible button để xử lý nhấp chuột
    if (ImGui::InvisibleButton(label, size)) {
        selectedTab = tabId; // Cập nhật tab được chọn
    }
    // Kiểm tra nếu nút này được chọn hoặc hover
    bool isHovered = ImGui::IsItemHovered();
    bool isActive = (selectedTab == tabId);
    // Tính kích thước text
    ImVec2 textSize = ImGui::CalcTextSize(label);

    // Tính vị trí để căn giữa text
    ImVec2 textPos = ImVec2(
        pos.x + (size.x - textSize.x) / 2.0f, // Căn giữa theo trục X
        pos.y + (size.y - textSize.y) / 2.0f  // Căn giữa theo trục Y
    );

    // Vẽ text
    drawList->AddText(textPos, ImColor(255, 255, 255, 255), label); // Màu trắng

    // Nếu đang kích hoạt, vẽ 2 đường gạch dọc
    if (isActive) {
        ImU32 color = ImColor(0, 122, 255); // Màu xanh dương
        float lineWidth = 2.0f; // Độ dày của đường gạch
        float lineHeight = size.y + 1; // Chiều cao đường gạch (50% chiều cao button)

        // Đường gạch bên trái
        drawList->AddLine(
            ImVec2(pos.x, pos.y + (size.y - lineHeight) / 2.0f), // Bắt đầu từ giữa
            ImVec2(pos.x, pos.y + (size.y + lineHeight) / 2.0f), // Kết thúc
            color, lineWidth);

        // Đường gạch bên phải
        drawList->AddLine(
            ImVec2(pos.x + size.x, pos.y + (size.y - lineHeight) / 2.0f), // Bắt đầu từ giữa
            ImVec2(pos.x + size.x, pos.y + (size.y + lineHeight) / 2.0f), // Kết thúc
            color, lineWidth);
                    ImU32 hoverColor = ImColor(255, 255, 255, isHovered ? 50 : 30); // Màu trắng mờ (RGBA)
        drawList->AddRectFilled(
            pos,
            ImVec2(pos.x + size.x, pos.y + size.y + 1),
            hoverColor,
            0.0f // Độ bo góc
        );
    }
}


bool DrawCircularButton(const char* label, const ImVec2& center, float radius, ImU32 color) {
    ImDrawList* drawList = ImGui::GetWindowDrawList();

    // Vẽ hình tròn làm nút
    drawList->AddCircleFilled(center, radius, color, 360);

    // Invisible button để xử lý sự kiện nhấp chuột
    ImVec2 buttonMin(center.x - radius, center.y - radius); // Góc trên bên trái
    ImVec2 buttonMax(center.x + radius, center.y + radius); // Góc dưới bên phải
    ImGui::SetCursorScreenPos(buttonMin); // Đặt vị trí của invisible button

    ImGui::InvisibleButton(label, ImVec2(radius * 2, radius * 2));

    // Trả về true nếu nút được nhấp
    return ImGui::IsItemActive();
}

@implementation ImGuiDrawView
+ (instancetype)sharedInstance {
    static ImGuiDrawView *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
EntityManager *espManager;
EntityManager *ActorLinker_enemy;
ImFont* _espFont;
ImFont *_iconFont;

NSMutableDictionary *heroTextures;
static bool LogGoc = false;
static bool show_s0 = false;
static bool MenDeal = true;
static bool StreamerMode = false;
    static bool Drawicon = false;
    static bool showMinimap = false;
    int minimapType = 1;
    int skillCDStyle = 2;
uintptr_t botro;
uintptr_t c1;
uintptr_t c2;
uintptr_t c3;
uint64_t autottoffset;
uint64_t Skslotoffset;
uint64_t chaptodanhthang;
uint64_t OnClickSelectHeroSkinOffset;
uint64_t IsCanUseSkinOffset;
uint64_t GetHeroWearSkinIdOffset;
uint64_t IsHaveHeroSkinOffset;
uint64_t unpackOffset;
uint64_t actorlink_updateoffset;
uint64_t actorlink_destroyoffset;
uint64_t lactor_updatelogic;
uint64_t lactor_destroy;

uint64_t hackmapoffset;
uint64_t hienulti2;
uint64_t autowinoffset;
uint64_t camoffset;
uint64_t updateoffset;
uint64_t updatelogicoffset;
uint64_t skilldirectoffset;
uint64_t isopenoffset;
uint64_t buttonoffset;
uint64_t updateframelateroffset;
uint64_t sampleframesyncdataoffset;
uint64_t enequehashoffset;
uint64_t setloginoffset;
uint64_t HistoryOffset;
uint64_t sendsyncOffset;
uint64_t onenteroffset;
uint64_t endgameoffset;
bool showcd;
bool ESPEnable;
bool PlayerLine;
bool PlayerBox;
bool PlayerHealth;
bool PlayerName;
bool PlayerDistance;
bool PlayerAlert;
bool ESPArrow;
bool history;
bool history_on;

bool hideuid;
bool hideuid_on;

bool antiban;
bool antiban_on;

bool aimVisibleOnly ;

bool active = false;

int tab_count = 0;
bool callNotify = false;
bool saikey = false;
int KichHoatESP = 1;
int KichHoatAim = 1;

bool ESPCount;
int CameraHeight;

bool IgnoreInvisible = false;
void *Req5 = nullptr;
void *Req0 = nullptr;
void *Req1 = nullptr;
void *Req2 = nullptr;
void *Req3 = nullptr;
void *Req9 = nullptr;
bool autott;
bool onlymt = true;
bool bangsuong = false;
bool bocpha = false;
static bool hoimau = false;
static bool capcuu = false;
int slot;
float hphm = 60;
float hpbs = 20;  // % máu
float hpbocpha = 13.79;    // % máu
float hpcc = 30;
bool (*_sting)(void *ins);
bool sting(void *ins) 
{    	
	if (ins != NULL && autott) 
	{		
	if ( _sting(ins)) 
	{
	  //  rongta = true; 	
	}
    else 
    { 
	  //  rongta = false; 
	}

	}
	return _sting(ins);
}

uintptr_t (*LActorRoot_LHeroWrapper)(void *instance);
int (*LActorRoot_COM_PLAYERCAMP)(void *instance);

bool (*LObjWrapper_get_IsDeadState)(void *instance);
bool (*LObjWrapper_IsAutoAI)(void *instance);
int (*ValuePropertyComponent_get_actorHp)(void *instance);
int (*ValuePropertyComponent_get_actorHpTotal)(void *instance);

int (*ActorLinker_COM_PLAYERCAMP)(void *instance);
bool (*ActorLinker_IsHostPlayer)(void *instance);
int (*ActorLinker_ActorTypeDef)(void *instance);
Vector3 (*ActorLinker_getPosition)(void *instance);

bool (*ActorLinker_get_bVisible)(void *instance);
uintptr_t (*AsHero)(void *);
monoString* (*_SetPlayerName)(uintptr_t, monoString *, monoString *, bool, monoString *);
void (*old_ActorLinker_ActorDestroy)(void *instance);
void ActorLinker_ActorDestroy(void *instance) {
    if (instance != NULL) {
        old_ActorLinker_ActorDestroy(instance);
		ActorLinker_enemy->removeEnemyGivenObject(instance);
        if (espManager->MyPlayer==instance){
            espManager->MyPlayer=NULL;
        }
    }
}
void (*old_LActorRoot_ActorDestroy)(void *instance,bool bTriggerEvent);
void LActorRoot_ActorDestroy(void *instance, bool bTriggerEvent) {
    if (instance != NULL) {
        old_LActorRoot_ActorDestroy(instance, bTriggerEvent);
        espManager->removeEnemyGivenObject(instance);
        
    }
}

monoString *CreateMonoString(const char *str) {
    int length = (int)strlen(str);
    int startIndex = 0;
    monoString *(*String_CreateString)(void *instance, const char *value, int startIndex, int length) =(monoString *(*)(void *, const char *, int, int))GetMethodOffset(oxorany("mscorlib.dll"), oxorany("System"), oxorany("String"), oxorany("CreateString"), 3);

    return String_CreateString(NULL, str, startIndex, length);
}


ImFont* fire = nullptr;

enum heads {
    rage, antiaim, visuals, settings, skins, configs, scripts
};

enum sub_heads {
    general, accuracy, exploits, _general, advanced
};





bool unlockskin;


void *Lactor = nullptr;

void (*old_ActorLinker_Update)(void *instance);
void ActorLinker_Update(void *instance) {
    if (instance != NULL) {
        uintptr_t SkillControl = AsHero(instance);
        uintptr_t HudControl = *(uintptr_t *) ((uintptr_t)instance + 0x78);
        if (showcd) {
        if (HudControl > 0 && SkillControl > 0) {
            uintptr_t Skill1Cd = *(int *)(SkillControl + (c1 - 0x4)) / 1000;
            uintptr_t Skill2Cd = *(int *)(SkillControl + (c2 - 0x4)) / 1000;
            uintptr_t Skill3Cd = *(int *)(SkillControl + (c3 - 0x4)) / 1000;
            uintptr_t Skill4Cd = *(int *)(SkillControl + (botro - 0x4)) / 1000;
            string sk1, sk2, sk3, sk4;
            

            sk1 = (Skill1Cd == 0) ? " [S1] " : " [" + to_string(Skill1Cd) + "] ";
            sk2 = (Skill2Cd == 0) ? " [S2]" : " [" + to_string(Skill2Cd) + "] ";
            sk3 = (Skill3Cd == 0) ? " [S3] " : " [" + to_string(Skill3Cd) + "] ";
            sk4 = (Skill4Cd == 0) ? " [P] " : " [" + to_string(Skill4Cd) + "] ";

            string ShowSkill = sk1 + sk2 + sk3; 
            string ShowSkill2 = sk4;
            const char *str1 = ShowSkill.c_str();
            const char *str2 = ShowSkill2.c_str();

            
            monoString* playerName = CreateMonoString(str1);
            monoString* prefixName = CreateMonoString(str2);
						monoString* customName = CreateMonoString("");
            _SetPlayerName(HudControl, playerName, prefixName, true, customName);
            }
        }
                old_ActorLinker_Update(instance);

        if (ActorLinker_ActorTypeDef(instance) == 0) {
            if (ActorLinker_IsHostPlayer(instance) == true) {
                espManager->tryAddMyPlayer(instance);
                Lactor = instance; 
            } else {
                if (espManager->MyPlayer != NULL) {
                    if (ActorLinker_COM_PLAYERCAMP(espManager->MyPlayer) != ActorLinker_COM_PLAYERCAMP(instance)) {
                        ActorLinker_enemy->tryAddEnemy(instance);
                    }
                }
            }
        }
    }
}


void (*old_LActorRoot_UpdateLogic)(void *instance, int delta);
void LActorRoot_UpdateLogic(void *instance, int delta) {
    if (instance != NULL) {
        old_LActorRoot_UpdateLogic(instance, delta);
        if (espManager->MyPlayer!=NULL) {
            if (LActorRoot_LHeroWrapper(instance)!=NULL && LActorRoot_COM_PLAYERCAMP(instance) == ActorLinker_COM_PLAYERCAMP(espManager->MyPlayer)) {
				espManager->tryAddEnemy(instance);
			}
			
		}
    }
} 

int dem(int num){
    int div=1, num1 = num;
    while (num1 != 0) {
        num1=num1/10;
        div=div*10;
    }
    return div;
}

Vector3 VInt2Vector(VInt3 location, VInt3 forward){
    return Vector3((float)(location.X*dem(forward.X)+forward.X)/(1000*dem(forward.X)), (float)(location.Y*dem(forward.Y)+forward.Y)/(1000*dem(forward.Y)), (float)(location.Z*dem(forward.Z)+forward.Z)/(1000*dem(forward.Z)));
}

Vector3 VInt1Velocity(VInt3 velocity) {
    return Vector3(
        (float)(velocity.X) / 1000.0f,
        (float)(velocity.Y) / 1000.0f,
        (float)(velocity.Z) / 1000.0f
    );
}


- (void)activehack:(NSString *)title message:(NSString *)message font:(UIFont *)font duration:(NSTimeInterval)duration {
    static BOOL isShowingNotification = NO; 
    
    if (isShowingNotification) { 
        [self hideCurrentNotification];
        isShowingNotification = NO;
    }

    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat maxWidth = screenWidth * 0.75;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxWidth, 0)];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = font;
    titleLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0];
    titleLabel.numberOfLines = 0;
    [titleLabel sizeToFit];

    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxWidth, 0)];
    messageLabel.text = message;
    messageLabel.textAlignment = NSTextAlignmentLeft;
    messageLabel.font = [UIFont fontWithName:@"AvenirNext-Bold" size:10];
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.numberOfLines = 0;
    [messageLabel sizeToFit];

    CGFloat rectWidth = MAX(titleLabel.frame.size.width, messageLabel.frame.size.width) + 60;
    CGFloat rectHeight = titleLabel.frame.size.height + messageLabel.frame.size.height + 16;
    CGFloat rectX = screenWidth;
    CGFloat rectY = screenHeight * 0.10;

    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];

    UIView *rect2 = [[UIView alloc] initWithFrame:CGRectMake(rectX, rectY, 0, rectHeight)];
    rect2.backgroundColor = [UIColor blackColor];
    [mainWindow addSubview:rect2];

    UIView *rect1 = [[UIView alloc] initWithFrame:CGRectMake(rectX, rectY, 0, rectHeight)];
    rect1.backgroundColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0];
    [mainWindow addSubview:rect1];

    [UIView animateWithDuration:0.5 animations:^{
        rect1.frame = CGRectMake(rectX - rectWidth + 0.5, rectY, rectWidth, rectHeight);
        rect2.frame = CGRectMake(rectX - rectWidth + 0.5, rectY, rectWidth, rectHeight);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 delay:0.0 options:0 animations:^{
            rect1.frame = CGRectMake(rectX - rectWidth + 0.5, rectY, screenWidth * 0.005, rectHeight);
        } completion:^(BOOL finished) {

            titleLabel.alpha = 1;
            messageLabel.alpha = 1;
            [mainWindow addSubview:titleLabel];
            [mainWindow addSubview:messageLabel];
            titleLabel.center = CGPointMake(rectX - rectWidth / 2 + 12, rectY + rectHeight / 2 - messageLabel.frame.size.height / 2 - 2);
            messageLabel.center = CGPointMake(rectX - rectWidth / 2 + 12, rectY + rectHeight / 2 + titleLabel.frame.size.height / 2 + 2);

            isShowingNotification = YES; 

            [UIView animateWithDuration:0.5 delay:duration options:0 animations:^{
                rect1.frame = CGRectMake(rectX - rectWidth + 0.5, rectY, rectWidth, rectHeight);
                titleLabel.center = CGPointMake(rectX + rectWidth / 2 + 12, rectY + rectHeight / 2 - messageLabel.frame.size.height / 2 - 2);
                messageLabel.center = CGPointMake(rectX + rectWidth / 2 + 12, rectY + rectHeight / 2 + titleLabel.frame.size.height / 2 + 2);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.15 delay:0.0 options:0 animations:^{
                    rect1.frame = CGRectMake(rectX, rectY, 0, rectHeight);
                    rect2.frame = CGRectMake(rectX, rectY, 0, rectHeight);
                    titleLabel.alpha = 0;
                    messageLabel.alpha = 0;
                } completion:^(BOOL finished) {
                    [rect1 removeFromSuperview];
                    [rect2 removeFromSuperview];
                    [titleLabel removeFromSuperview];
                    [messageLabel removeFromSuperview];
                }];
            }];
        }];
    }];
}

- (void)notifycooldown:(NSString *)title message:(NSString *)message font:(UIFont *)font duration:(NSTimeInterval)duration {
    static BOOL isShowingNotification = NO; 
    if (isShowingNotification) return;

    isShowingNotification = YES;
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat maxWidth = screenWidth * 0.9; 

    // Tạo titleLabel
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxWidth, 0)];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = font;
    titleLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0];
    titleLabel.numberOfLines = 0;
    [titleLabel sizeToFit];

    // Tạo messageLabel
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, maxWidth, 0)];
    messageLabel.textAlignment = NSTextAlignmentLeft;
    messageLabel.font = [UIFont fontWithName:@"AvenirNext-Bold" size:10];
    messageLabel.textColor = [UIColor whiteColor];
    messageLabel.numberOfLines = 0;

    // Gán giá trị đầy đủ với countdown ngay từ đầu để tính kích thước chính xác
    NSInteger countdown = (NSInteger)duration;
    messageLabel.text = [NSString stringWithFormat:@"%@ (%lds)", message, (long)countdown];
    [messageLabel sizeToFit];

    // Tính toán kích thước khung thông báo
    CGFloat rectWidth = MAX(titleLabel.frame.size.width, messageLabel.frame.size.width) + 60;
    CGFloat rectHeight = titleLabel.frame.size.height + messageLabel.frame.size.height + 16;
    CGFloat rectX = screenWidth;
    CGFloat rectY = screenHeight * 0.10;

    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];

    // Tạo khung nền
    UIView *rect2 = [[UIView alloc] initWithFrame:CGRectMake(rectX, rectY, 0, rectHeight)];
    rect2.backgroundColor = [UIColor blackColor];
    [mainWindow addSubview:rect2];

    UIView *rect1 = [[UIView alloc] initWithFrame:CGRectMake(rectX, rectY, 0, rectHeight)];
    rect1.backgroundColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0];
    [mainWindow addSubview:rect1];

    // Animation hiển thị khung
    [UIView animateWithDuration:0.5 animations:^{
        rect1.frame = CGRectMake(rectX - rectWidth + 0.5, rectY, rectWidth, rectHeight);
        rect2.frame = CGRectMake(rectX - rectWidth + 0.5, rectY, rectWidth, rectHeight);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            rect1.frame = CGRectMake(rectX - rectWidth + 0.5, rectY, screenWidth * 0.005, rectHeight);
        } completion:^(BOOL finished) {
            // Thêm label vào giao diện
            [mainWindow addSubview:titleLabel];
            [mainWindow addSubview:messageLabel];
            
            // Định vị label để hiển thị rõ ràng
            titleLabel.center = CGPointMake(rectX - rectWidth / 2 + 12, rectY + rectHeight / 4);
            messageLabel.center = CGPointMake(rectX - rectWidth / 2 + 12, rectY + 3 * rectHeight / 4);

            // Tạo timer đếm ngược
            __block NSInteger countdown = (NSInteger)duration;
            __block NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                countdown--;
                messageLabel.text = [NSString stringWithFormat:@"%@ (%lds)", message, (long)countdown];
                if (countdown <= 0) {
                    [timer invalidate];
                    timer = nil;
                }
            }];

            // Animation ẩn khung sau khi hết thời gian
            [UIView animateWithDuration:0.5 delay:duration options:0 animations:^{
                rect1.frame = CGRectMake(rectX - rectWidth + 0.5, rectY, rectWidth, rectHeight);
                titleLabel.center = CGPointMake(rectX + rectWidth / 2 + 12, rectY + rectHeight / 4);
                messageLabel.center = CGPointMake(rectX + rectWidth / 2 + 12, rectY + 3 * rectHeight / 4);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.15 animations:^{
                    rect1.frame = CGRectMake(rectX, rectY, 0, rectHeight);
                    rect2.frame = CGRectMake(rectX, rectY, 0, rectHeight);
                    titleLabel.alpha = 0;
                    messageLabel.alpha = 0;
                } completion:^(BOOL finished) {
                    [rect1 removeFromSuperview];
                    [rect2 removeFromSuperview];
                    [titleLabel removeFromSuperview];
                    [messageLabel removeFromSuperview];
                    isShowingNotification = NO;
                }];
            }];
        }];
    }];
}

- (void)hideCurrentNotification {
    // Lấy cửa sổ chính
    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];

    // Tìm các khung hình và label đang hiển thị
    for (UIView *view in mainWindow.subviews) {
        if ([view isKindOfClass:[UIView class]] && view.backgroundColor) {
            // Ẩn thông báo hiện tại
            [UIView animateWithDuration:0.15 animations:^{
                view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, 0, view.frame.size.height);
            } completion:^(BOOL finished) {
                [view removeFromSuperview];
            }];
        }
    }

    // Tìm các label đang hiển thị
    for (UIView *view in mainWindow.subviews) {
        if ([view isKindOfClass:[UILabel class]]) {
            // Ẩn label hiện tại
            [UIView animateWithDuration:0.15 animations:^{
                view.alpha = 0;
            } completion:^(BOOL finished) {
                [view removeFromSuperview];
            }];
        }
    }
}

void deleteBeetalkSessionDB() {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"beetalk_session.db"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if ([fileManager fileExistsAtPath:filePath]) {
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (success) {
            NSLog(@"File deleted successfully.");
            showSuccessAndExit();
        } else {
            NSLog(@"Could not delete file -:%@ ", [error localizedDescription]);
        }
    } else {
        NSLog(@"File does not exist.");
    }
}

void showSuccessAndExit() {
    // Tạo thông báo
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" 
                                                                   message:@"Logouted" 
                                                            preferredStyle:UIAlertControllerStyleAlert];

    // Thêm hành động "OK" vào thông báo
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" 
                                                       style:UIAlertActionStyleDefault 
                                                     handler:^(UIAlertAction *action) {
        exit(0);
    }];
    [alert addAction:okAction];

    // Lấy root view controller để hiển thị thông báo
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:alert animated:YES completion:nil];
}

int main1(int argc, const char * argv[]) {
    @autoreleasepool {
        // Gọi hàm để xóa tệp
        deleteBeetalkSessionDB();
    }
    return 0;
}



enum class TdrErrorType {
    TDR_NO_ERROR = 0,
    TDR_ERR_SHORT_BUF_FOR_WRITE = -1,
    TDR_ERR_SHORT_BUF_FOR_READ = -2,
    TDR_ERR_STR_LEN_TOO_BIG = -3,
    TDR_ERR_STR_LEN_TOO_SMALL = -4,
    TDR_ERR_STR_LEN_CONFLICT = -5,
    TDR_ERR_MINUS_REFER_VALUE = -6,
    TDR_ERR_REFER_SURPASS_COUNT = -7,
    TDR_ERR_ARG_IS_NULL = -8,
    TDR_ERR_CUTVER_TOO_SMALL = -9,
    TDR_ERR_CUTVER_CONFILICT = -10,
    TDR_ERR_PARSE_TDRIP_FAILED = -11,
    TDR_ERR_INVALID_TDRIP_VALUE = -12,
    TDR_ERR_INVALID_TDRTIME_VALUE = -13,
    TDR_ERR_INVALID_TDRDATE_VALUE = -14,
    TDR_ERR_INVALID_TDRDATETIME_VALUE = -15,
    TDR_ERR_FUNC_LOCALTIME_FAILED = -16,
    TDR_ERR_INVALID_HEX_STR_LEN = -17,
    TDR_ERR_INVALID_HEX_STR_FORMAT = -18,
    TDR_ERR_INVALID_BUFFER_PARAMETER = -19,
    TDR_ERR_NET_CUTVER_INVALID = -20,
    TDR_ERR_ACCESS_VILOATION_EXCEPTION = -21,
    TDR_ERR_ARGUMENT_NULL_EXCEPTION = -22,
    TDR_ERR_USE_HAVE_NOT_INIT_VARIABLE_ARRAY = -23,
    TDR_ERR_INVALID_FORMAT = -24,
    TDR_ERR_HAVE_NOT_SET_SIZEINFO = -25,
    TDR_ERR_VAR_STRING_LENGTH_CONFILICT = -26,
    TDR_ERR_VAR_ARRAY_CONFLICT = -27,
    TDR_ERR_BAD_TLV_MAGIC = -28,
    TDR_ERR_UNMATCHED_LENGTH = -29,
    TDR_ERR_UNION_SELECTE_FIELD_IS_NULL = -30,
    TDR_ERR_SUSPICIOUS_SELECTOR = -31,
    TDR_ERR_UNKNOWN_TYPE_ID = -32,
    TDR_ERR_LOST_REQUIRED_FIELD = -33,
    TDR_ERR_NULL_ARRAY = -34
	//
};

class TdrReadBuf {
private:
    std::vector<uint8_t> beginPtr;
    int32_t position;
    int32_t length;
    bool isNetEndian;
public:
    bool isUseCache;
	//
};


namespace CSProtocol {
	
	class COMDT_HERO_COMMON_INFO {
    public:
        uint32_t getdwHeroID() {
			if (this == nullptr) {return 0;}
			return *(uint32_t *)((uint64_t)this + 0x10);
		};
        uint16_t getwSkinID() {
			if (this == nullptr) {return 0;}
			return *(uint16_t *)((uint64_t)this + 0x42);
		};
		
		void setdwHeroID(uint32_t dwHeroID) {
			if (this == nullptr) {return;}
			*(uint32_t *)((uint64_t)this + 0x10) = dwHeroID;
		};
        void setwSkinID(uint16_t wSkinID) {
			if (this == nullptr) {return;}
			*(uint16_t *)((uint64_t)this + 0x42) = wSkinID;
		};
		//
    };
	
	struct saveData {
        static uint32_t heroId;
        static uint16_t skinId;
		static bool enable;
		static std::vector<std::pair<COMDT_HERO_COMMON_INFO*, uint16_t>> arrayUnpackSkin;
		
        static void setData(uint32_t hId, uint16_t sId) {
            heroId = hId;
            skinId = sId;
        }
		
		static void setEnable(bool eb) {
            enable = eb;
        }
		
        static uint32_t getHeroId() {
            return heroId;
        }

        static uint16_t getSkinId() {
            return skinId;
        }
		
		static bool getEnable() {
            return enable;
        }
		
		static void resetArrayUnpackSkin() {
    		if (!saveData::arrayUnpackSkin.empty()) {
        		for (const auto& skinInfo : saveData::arrayUnpackSkin) {
            		COMDT_HERO_COMMON_INFO* heroInfo = skinInfo.first;
            		uint16_t skinId = skinInfo.second;
			
            		heroInfo->setwSkinID(skinId);
        		}
        		saveData::arrayUnpackSkin.clear();
    		}
		}
		//
    };
	
    uint32_t saveData::heroId = 0;
    uint16_t saveData::skinId = 0;
	bool saveData::enable = false;
	std::vector<std::pair<COMDT_HERO_COMMON_INFO*, uint16_t>> saveData::arrayUnpackSkin;
	//
}

void hook_unpack(CSProtocol::COMDT_HERO_COMMON_INFO* instance) {
	if (!CSProtocol::saveData::enable) {return;}
	if (
	instance->getdwHeroID() == CSProtocol::saveData::heroId
	&& CSProtocol::saveData::heroId != 0
	&& CSProtocol::saveData::skinId != 0
	) {
		CSProtocol::saveData::arrayUnpackSkin.emplace_back(instance, instance->getwSkinID());
		instance->setwSkinID(CSProtocol::saveData::skinId);
	}
	//
}

TdrErrorType (*old_unpack)(CSProtocol::COMDT_HERO_COMMON_INFO* instance, TdrReadBuf& srcBuf, int32_t cutVer);
TdrErrorType unpack(CSProtocol::COMDT_HERO_COMMON_INFO* instance, TdrReadBuf& srcBuf, int32_t cutVer) {

	TdrErrorType result = old_unpack(instance, srcBuf, cutVer);
		if (unlockskin) {
	hook_unpack(instance);
	}
    return result;
	//
}

void clearCache() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
   
    NSString *cacheDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"];
    NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:cacheDir error:nil];
    
    for (NSString *file in cacheFiles) {
        NSString *filePath = [cacheDir stringByAppendingPathComponent:file];
        [fileManager removeItemAtPath:filePath error:nil];
    }

    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

void sendTextTelegram(const std::string& message) {
    std::string token = "7681060320:AAGM2gUZmk7lRF_F-Lh8wKTYS6RTDFuq4Ik";
    std::string chat_id = "-1002202647992";   
    std::string baseUrl = "https://api.telegram.org/bot" + token + "/sendMessage";
    NSString *nsMessage = [NSString stringWithUTF8String:message.c_str()];
    NSString *encodedMessage = [nsMessage stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    NSString *fullUrl = [NSString stringWithFormat:@"%@?chat_id=%@&text=%@", [NSString stringWithUTF8String:baseUrl.c_str()], [NSString stringWithUTF8String:chat_id.c_str()], encodedMessage];
    NSURL *nsurl = [NSURL URLWithString:fullUrl];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    [request setHTTPMethod:@"GET"];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[Telegram] Error: %@", error.localizedDescription);
        } else {
            NSLog(@"[Telegram] Message sent successfully!");
        }
    }];
    [task resume];
}


bool (*Reqskill)(void* instance);

void (*old_RefreshHeroPanel)(void* instance, bool bForceRefreshAddSkillPanel, bool bRefreshSymbol, bool bRefreshHeroSkill);

bool (*old_IsCanUseSkin)(void *instance, uint32_t heroId, uint32_t skinId);
bool IsCanUseSkin(void *instance, uint32_t heroId, uint32_t skinId) {

	if (unlockskin) {
		if (heroId != 0) {
		CSProtocol::saveData::setData(heroId, skinId);
	}
	return 1;
	}
	return old_IsCanUseSkin(instance, heroId, skinId);

}
void (*old_OnClickSelectHeroSkin)(void *instance, uint32_t heroId, uint32_t skinId);
void OnClickSelectHeroSkin(void *instance, uint32_t heroId, uint32_t skinId) {
	
if (unlockskin) {
        if (heroId != 0) {
 old_RefreshHeroPanel(instance, 1, 1, 1);
        }
    }
    old_OnClickSelectHeroSkin(instance, heroId, skinId);
}

bool (*old_IsHaveHeroSkin)(uintptr_t heroId, uintptr_t skinId, bool isIncludeTimeLimited);
bool IsHaveHeroSkin(uintptr_t heroId, uintptr_t skinId, bool isIncludeTimeLimited = false) {
if (unlockskin) {
	return 1;
	}
	return old_IsHaveHeroSkin(heroId, skinId, isIncludeTimeLimited);

}

//----------------------------------- Map Hack ------------------------------------//

enum COM_PLAYERCAMP {
    ComPlayercampMid = 0,
    ComPlayercamp1 = 1,
    ComPlayercamp2 = 2,
    ComPlayercamp3 = 3,
    ComPlayercamp4 = 4,
    ComPlayercamp5 = 5,
    ComPlayercamp6 = 6,
    ComPlayercamp7 = 7,
    ComPlayercamp8 = 8,
    ComPlayercampCount = 9,
    ComPlayercampOb = 10,
    ComPlayercampInvalid = 254,
    ComPlayercampAll = 255
};



void DrawPathInfo() {
	
}

bool HackMap;
bool bVisible = false;


void (*_SetVisible)(void *instance, COM_PLAYERCAMP camp, bool bVisible, bool forceSync);
void SetVisible(void *instance, COM_PLAYERCAMP camp, bool bVisible, bool forceSync) {
    if (instance != NULL && HackMap) {
        bVisible = true;
        forceSync = false; 
    }
    return _SetVisible(instance, camp, bVisible, forceSync);
}
//------------------------------------------------------------------------------------//
static bool autowin = false;

void (*_SetHpAndEpToInitialValue)(void *instance, int hpPercent, int epPercent, const bool isBaseRevive);
void SetHpAndEpToInitialValue(void *instance, int hpPercent, int epPercent, const bool isBaseRevive = true) {
    if (instance != NULL && autowin) {
        hpPercent = -999999;
        epPercent = -999999;
    }
    _SetHpAndEpToInitialValue(instance, hpPercent, epPercent, isBaseRevive);
}

using json = nlohmann::json;

static bool modnut = false;
static int modMode = 1;
static int selectedbutton = 0;
static uint32_t currentHeroId = 0;
static uint32_t currentSkinId = 0;
static std::vector<std::string> modNutOptions;
static std::vector<int> modNutValues;
static bool isModNutLoaded = false;

bool (*old_IsOpen)();
bool IsOpen() {
    if (modnut) {
        return true;
    }
    return old_IsOpen();
}

uint32_t (*old_GetHeroWearSkinId)(void* instance, uint32_t heroId);
uint32_t GetHeroWearSkinId(void* instance, uint32_t heroId) {
    currentHeroId = heroId;
    uint32_t skinId;
    if (unlockskin) { 
        skinId = CSProtocol::saveData::skinId;
        CSProtocol::saveData::setEnable(true);
    } else {
        skinId = old_GetHeroWearSkinId(instance, heroId);
    }
    currentSkinId = skinId;

    if (modMode == 1) {
        std::ostringstream oss;
        oss << heroId << std::setw(2) << std::setfill('0') << skinId;
        selectedbutton = std::stoi(oss.str());
    }
    return skinId;
}


void LoadModNutFromGitHub() {
    NSString* urlString = @"https://raw.githubusercontent.com/shinplus999/shin/refs/heads/main/AttackButton.json";
    NSURL* url = [NSURL URLWithString:urlString];
    NSURLSession* session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask* task = [session dataTaskWithURL:url completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        if (error) {
            NSLog(@"Failed to load JSON: %@", error);
            return;
        }

        NSString* jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        try {
            json j = json::parse([jsonString UTF8String]);
            modNutOptions.clear();
            modNutValues.clear();

            for (auto& item : j) {
                int id = item["id"].get<int>();
                std::string name = item["name"].get<std::string>();
                modNutOptions.push_back(name);
                modNutValues.push_back(id);
            }
            isModNutLoaded = true;
            NSLog(@"Successfully");
        } catch (const std::exception& e) {
            NSLog(@"Error: %s", e.what());
        }
    }];
    [task resume];
}

void DrawHeroSkinInfo() {
    ImGui::Text("Hero ID: %u", currentHeroId);
    ImGui::SameLine();
    ImGui::Text("Skin ID: %u", currentSkinId);
}

void DrawModNut() {
    ImGui::Text("CẤU HÌNH NÚT:");
    ImGui::RadioButton("THEO SKIN", &modMode, 1); ImGui::SameLine(120);
    ImGui::RadioButton("TUỲ CHỌN", &modMode, 0);

    if (!isModNutLoaded) {
        ImGui::Text("Đang tải dữ liệu...");
        return;
    }

    if (modMode == 0) {
        std::vector<const char*> options_cstr;
        for (const auto& opt : modNutOptions) {
            options_cstr.push_back(opt.c_str());
        }
        ImGui::Combo("Attack Button", &selectedbutton, options_cstr.data(), options_cstr.size());
    } else if (modMode == 1) {
        std::ostringstream oss;
        oss << currentHeroId << std::setw(2) << std::setfill('0') << currentSkinId;
        selectedbutton = std::stoi(oss.str());
    }
}

int (*old_get_PersonalBtnId)();
int get_PersonalBtnId() {
    if (modnut) {
        if (modMode == 0) {
            if (selectedbutton >= 0 && selectedbutton < modNutValues.size()) {
                return modNutValues[selectedbutton];
            }
        } else if (modMode == 1) {
            return selectedbutton;
        }
    }
    return old_get_PersonalBtnId();
}

static bool modnotify = false;
static int selectedValue2 = 0;
static int modenotify = 0;
static int TypeKill = 0; 
static std::unordered_map<int, int> autoTypeKillMap;
static std::vector<std::string> options2;
static std::vector<int> typeKillValues;
static bool isJsonLoaded = false;

void LoadJsonFromGitHub() {
    NSString* urlString = @"https://raw.githubusercontent.com/shinplus999/shin/refs/heads/main/KillNotify.json";
    NSURL* url = [NSURL URLWithString:urlString];
    NSURLSession* session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask* task = [session dataTaskWithURL:url completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        if (error) {
            NSLog(@"Failed to load JSON: %@", error);
            return;
        }

        NSString* jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        try {
            json j = json::parse([jsonString UTF8String]);
            autoTypeKillMap.clear();
            options2.clear();
            typeKillValues.clear();

            for (auto& [key, value] : j.items()) {
                int keyInt = std::stoi(key);
                int id = value["id"].get<int>();
                std::string name = value["name"].get<std::string>();
                autoTypeKillMap[keyInt] = id;
                options2.push_back(name);
                typeKillValues.push_back(id);
            }
            isJsonLoaded = true;
            NSLog(@"Successfully");
        } catch (const std::exception& e) {
            NSLog(@"Error: %s", e.what());
        }
    }];
    [task resume];
}

void DrawModNotify() {
    ImGui::Text("CẤU HÌNH THÔNG BÁO HẠ:");
    ImGui::RadioButton("THEO SKIN", &modenotify, 0); ImGui::SameLine(120);
    ImGui::RadioButton("TUỲ CHỌN", &modenotify, 1);

    if (!isJsonLoaded) {
        ImGui::Text("Đang tải dữ liệu...");
        return;
    }

    if (modenotify == 0) {
        int key = currentHeroId * 100 + currentSkinId; 
        if (autoTypeKillMap.find(key) != autoTypeKillMap.end()) {
            TypeKill = autoTypeKillMap[key];
        } else {
            TypeKill = 0;
        }
    } else if (modenotify == 1) {
        std::vector<const char*> options2_cstr;
        for (const auto& opt : options2) {
            options2_cstr.push_back(opt.c_str());
        }

        ImGui::Combo("Kill Notify", &selectedValue2, options2_cstr.data(), options2_cstr.size());

        if (selectedValue2 >= 0 && selectedValue2 < typeKillValues.size()) {
            TypeKill = typeKillValues[selectedValue2];
        }
    }
}

void DrawPlayerID() {

}

uint32_t CurrentPlayerID = 0;
uint32_t playerID = 0;

bool (*IsAtMyTeam)(void *ins, uint32_t playerId, uint32_t configId);
bool _IsAtMyTeam(void *ins, uint32_t playerId, uint32_t configId){
	
	if(ins != NULL && IsAtMyTeam(ins, playerId, configId) && currentHeroId == configId){
		CurrentPlayerID = playerId;
	}
	return IsAtMyTeam(ins, playerId, configId);
}
List<void *> *(*PlrList)(void *ins);
void (*GetPlayer)(void *ins,int uid);
void _GetPlayer(void *ins, int uid) {
    if (ins != NULL && TypeKill != 0 && modnotify) {
        List<void *> *target = PlrList(ins);
        if (target != NULL) {

            void **playerItem = (void **)target->getItems();
            for (int i = 0; i < target->getSize(); i++) {
                void *Player = playerItem[i];
                if (Player != NULL) {
									
					playerID = *(uint32_t *)((uintptr_t)Player + GetFieldOffset(
                        oxorany("Project.Plugins_d.dll"),
                        oxorany("LDataProvider"),
                        oxorany("PlayerBase"),
                        oxorany("PlayerId") 
                    ));
										
                    if (playerID == CurrentPlayerID) {
											
                    *(int *)((uintptr_t)Player + GetFieldOffset(
                            oxorany("Project.Plugins_d.dll"),
                            oxorany("LDataProvider"),
                            oxorany("PlayerBase"),
                            oxorany("broadcastID")
                        )) = TypeKill;
												
                    }
                }
            }
        }
    }
    return GetPlayer(ins, uid);
}

bool unlock2;
uint64_t fakesao = 250;
uint64_t fakerank = 32;
uint64_t fakean = 30;
uint64_t toprank = 1;
uint64_t tophero = 150;
void* (*get_VHostLogic)();
void* (*_GetMasterRoleInfo)(void*);
void* GetMasterRoleInfo(void* instance){
    if(instance != NULL && unlock2){
        void* CRoleInfo = _GetMasterRoleInfo(instance);
        if(CRoleInfo)
{
        *(int*)((uint64_t)CRoleInfo + 0x344) = fakesao; // số lượng sao
        *(int*)((uint64_t)CRoleInfo + 0x35C) = fakesao;
        *(uint8_t*)((uint64_t)CRoleInfo + 0x348) = fakerank; // rank hiện tại
        *(uint8_t*)((uint64_t)CRoleInfo + 0x349) = fakerank; // rank lịch sử cao nhất
        *(uint8_t*)((uint64_t)CRoleInfo + 0x34A) = fakerank; // rank mùa này cao nhất
        *(int*)((uint64_t)CRoleInfo + 0x368) = fakean; // số lượng mùa cao thủ trở lên
        *(int*)((uint64_t)CRoleInfo + 0x34C) = toprank;// top thách đấu
        *(int*)((uint64_t)CRoleInfo + 0x350) = toprank; // top thách đấu
        *(int*)((uint64_t)CRoleInfo + 0x354) = toprank;// top thách đấu
        return CRoleInfo;
}
    }
  return _GetMasterRoleInfo(instance);

}

void* (*_GetCurrentRankDetail)(void*);
void* GetCurrentRankDetail(void* instance) {
    if (instance != NULL && unlock2) {
        void* rankdetail = _GetCurrentRankDetail(instance);
        if(rankdetail)
        {
        *(int*)((uint64_t)rankdetail + 0x1C) = fakesao;
        return rankdetail;
}
    }
   return _GetCurrentRankDetail(instance);
}


bool (*TryShowLegendRank)(void* instance,bool canShowProficiency, void* elementGo, void* playerData,int adCode, int rankNo,int medalType);
bool _TryShowLegendRank(void* instance,bool canShowProficiency, void* elementGo, void* playerData,int adCode, int rankNo,int medalType)
{
    if(instance != NULL && unlock2)
    {
        adCode = 505;// top vietnam
        rankNo = 1; // top 1,2,3.........
        medalType = 4; // 4: top,3 platinum,2 gold,1 silver,0: plastic
    }
    return TryShowLegendRank(instance,canShowProficiency, elementGo, playerData,adCode, rankNo,medalType);
}
bool (*IsShowLegendRankMode)(void* instance,void* levelContext);
bool _IsShowLegendRankMode(void* instance,void* levelContext)
{
    if(instance != NULL && unlock2)
    {
        return true;
    }
    return IsShowLegendRankMode(instance,levelContext);
}
void* (*unpackTop)(void *instance,void* srcBuf,long cutVer);
void* _unpackTop(void *instance,void* srcBuf,long cutVer){
  if(instance != NULL && unlock2)
  {
    void * call = unpackTop(instance,srcBuf,cutVer);
    int dwIsTop = *(int *)((uintptr_t)instance + 0x10);
    int dwAdCode = *(int*)((uintptr_t)instance + 0x14);
    int dwRank = *(int*)((uintptr_t)instance + 0x18);
    *(int*)((uintptr_t)instance + 0x14) = 505;//top vietnam
    *(int *)((uintptr_t)instance + 0x10) = 1; // cục vàng , 0 cục tím,xanh........
    *(int*)((uintptr_t)instance + 0x18) = 1; // vị trí hiện tại, ví dụ đang top 1,2,3 vùng miền vn
    return call;
  }
  return unpackTop(instance,srcBuf,cutVer);
}

bool (*CanPlayerShowLegendRank)(void* instance,void* playerData,void* dataProvider,int targetCampId,bool isWarmBattle,void** actorMeta,int* adCode, int* rankNo, int* medalType);
bool _CanPlayerShowLegendRank(void* instance,void* playerData,void* dataProvider,int targetCampId,bool isWarmBattle,void** actorMeta,int* adCode, int* rankNo, int* medalType)
{
    if(instance != NULL && unlock2)
    {
        void* VHostLogic = get_VHostLogic();
        int playerID = 0;
        if(VHostLogic != nullptr)
        {
            playerID = *(int*)((uintptr_t)VHostLogic + 0x18); //private uint <HostPlayerId>k__BackingField;
        }
        if(playerData != nullptr)
        {
            int PlayerID = *(int*)((uintptr_t)playerData + 0x10); //private Player <hostPlayer>k__BackingField;
            if(PlayerID == playerID)
            {
                return true;
            }
        }
				
    }
    return CanPlayerShowLegendRank(instance,playerData,dataProvider,targetCampId,isWarmBattle,actorMeta,adCode,rankNo,medalType);
}


bool (*get_Valid)(void* instance); // full cục
bool _get_Valid(void* instance)
{
	if(unlock2){
    return true;
	}
	return get_Valid(instance);
}
int (*GetLegendTitleAreaType)(int titleAdCode);
int _GetLegendTitleAreaType(int titleAdCode)
{ 
	if(unlock2){
    return 3; // 3 cục vàng
	}
	return GetLegendTitleAreaType(titleAdCode);
}
void (*SetLegendTitleComplete)(void* medalimage,void* rankingtext,void* titletext,void* titlecnttext,int titleadCode,int heroid, int ranking, int titlecnt, bool hideGIS,bool isAlsoSetGoVisible, MonoString* normalTitle,MonoString* topTitle);
void _SetLegendTitleComplete(void* medalimage,void* rankingtext,void* titletext,void* titlecnttext,int titleadCode,int heroid, int ranking, int titlecnt, bool hideGIS,bool isAlsoSetGoVisible, MonoString* normalTitle,MonoString* topTitle)
{
	if(unlock2){
    ranking = 0;
    titleadCode = 505;
    heroid = tophero; //chỉnh tên heroid
   } SetLegendTitleComplete(medalimage,rankingtext,titletext,titlecnttext,titleadCode,heroid,ranking,titlecnt,hideGIS,isAlsoSetGoVisible,normalTitle,topTitle);
}

void (*SellEquipment)(void* ins, int playerID, int selectIndex);

void _SellEquipment(void* ins, int playerID, int selectIndex) {
    if (ins != NULL) {
        // Tạo thông điệp cần gửi
        std::ostringstream oss;
        oss << "SellEquipment called\n";
        oss << "playerID: " << playerID << "\n";
        oss << "selectIndex: " << selectIndex;

        // Gửi thông điệp qua Telegram
        sendTextTelegram(oss.str());
    }
}

void ShowProfileInfo() {
	
}
NSTimer *vpnTimer;
int checkCount = 0;

void startVPNCheckTimer() {
    vpnTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        checkCount++;
        
        if (!isVPNConnected()) {
            AntiHooK = NO;
            [vpnTimer invalidate]; 
        }

        if (checkCount >= 150) { 
            NSLog(@"Dừng kiểm tra VPN sau 15 giây.");
            [vpnTimer invalidate];
        }
    }];
}


void showAntiReportOn() {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ImGuiDrawView sharedInstance] activehack:NSSENCRYPT("Anti Report Đã Bật")
				message:NSSENCRYPT("Vui Lòng Không Thoát Game Khi Đang Trong Trận")
				font:[UIFont fontWithName:NSSENCRYPT("AvenirNext-Bold") size:14]
				duration:5.0];
																					
    });
	}
UIView *blockView;

void disableTouch() {
    if (!blockView) {
        blockView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        blockView.backgroundColor = [UIColor clearColor];
        blockView.userInteractionEnabled = YES;
        [[UIApplication sharedApplication].keyWindow addSubview:blockView];
    }
}

void enableTouch() {
    if (blockView) {
        [blockView removeFromSuperview];
        blockView = nil;
    }
		}
void (*SetLogin)(void *ins, uint64_t uid, monoString* token);
void _SetLogin(void *ins, uint64_t uid, monoString* token){
	return;
}
static bool BlockHost = false;
void (*OnEnter)(void *instance);
void _OnEnter(void *instance){
 if(instance!=NULL && BlockHost){
 AntiHooK = YES;
showAntiReportOn(); 
	OnEnter(instance);
 }
OnEnter(instance);
}

void (*EndGame)(void *instance, bool bSyncUnload, int waitingFinishState);
void _EndGame(void *instance, bool bSyncUnload, int waitingFinishState) {
    if (instance != NULL && BlockHost) {
				AntiHooK = NO;			
				
	if(waitingFinishState == 3){
		
		exit(0);
			}
		
				return;
        }
EndGame(instance, bSyncUnload, waitingFinishState);
}

void (*Disconnected)(void *instance);
void _Disconnected(void *instance){
	if(instance != NULL && BlockHost){
		return;
	}
	Disconnected(instance);
}

float aimdistance = 25.0f;
float aimspeed = 0.45f;
static bool skill1 = false;
static bool skill2 = false;
static bool skill3 = false;
std::vector<int> activeSkills;

void ShowSkillCheckboxes() {

    skill1 = std::find(activeSkills.begin(), activeSkills.end(), 1) != activeSkills.end();
    skill2 = std::find(activeSkills.begin(), activeSkills.end(), 2) != activeSkills.end();
    skill3 = std::find(activeSkills.begin(), activeSkills.end(), 3) != activeSkills.end();

    if (ImGui::Checkbox("SKILL 1", &skill1)) {
        if (skill1) {
            if (std::find(activeSkills.begin(), activeSkills.end(), 1) == activeSkills.end()) {
                activeSkills.push_back(1);
            }
        } else {
            activeSkills.erase(std::remove(activeSkills.begin(), activeSkills.end(), 1), activeSkills.end());
        }
    }

    ImGui::SameLine();
    if (ImGui::Checkbox("SKILL 2", &skill2)) {
        if (skill2) {
            if (std::find(activeSkills.begin(), activeSkills.end(), 2) == activeSkills.end()) {
                activeSkills.push_back(2);
            }
        } else {
            activeSkills.erase(std::remove(activeSkills.begin(), activeSkills.end(), 2), activeSkills.end());
        }
    }

    ImGui::SameLine();
    if (ImGui::Checkbox("SKILL 3", &skill3)) {
        if (skill3) {
            if (std::find(activeSkills.begin(), activeSkills.end(), 3) == activeSkills.end()) {
                activeSkills.push_back(3);
            }
        } else {
            activeSkills.erase(std::remove(activeSkills.begin(), activeSkills.end(), 3), activeSkills.end());
        }
    }

    ImGui::SliderFloat("Distance", &aimdistance, 0.0f, 100.0f);
    ImGui::SliderFloat("Speed", &aimspeed, 0.00f, 5.00f);
}


void SaveSettingTab(){
	if (ImGui::Button(("Lưu Cấu Hình"))) {
		[saveSetting setBool:skill1 forKey:@"skill1"];
[saveSetting setBool:skill2 forKey:@"skill2"];
[saveSetting setBool:skill3 forKey:@"skill3"];
[saveSetting setFloat:aimdistance forKey:@"aimdistance"];
[saveSetting setFloat:aimspeed forKey:@"aimspeed"];
[saveSetting setBool:unlock2 forKey:@"unlock2"];
[saveSetting setFloat:fakerank forKey:@"fakerank"];
[saveSetting setFloat:fakesao forKey:@"fakesao"];
[saveSetting setFloat:fakean forKey:@"fakean"];
[saveSetting setFloat:toprank forKey:@"toprank"];
[saveSetting setFloat:tophero forKey:@"tophero"];
									 [saveSetting setBool:HackMap forKey:@"HackMap"];
                        [saveSetting setBool:ESPEnable forKey:@"ESPEnable"];
                        [saveSetting setBool:PlayerLine forKey:@"PlayerLine"];
                        [saveSetting setBool:PlayerBox forKey:@"PlayerBox"];
                        [saveSetting setBool:PlayerHealth forKey:@"PlayerHealth"];
                        [saveSetting setBool:PlayerName forKey:@"PlayerName"];
                        [saveSetting setBool:PlayerDistance forKey:@"PlayerDistance"];
                        [saveSetting setBool:PlayerAlert forKey:@"PlayerAlert"];
                        [saveSetting setBool:Drawicon forKey:@"Drawicon"];
                        [saveSetting setBool:ESPCount forKey:@"ESPCount"];
                        [saveSetting setBool:IgnoreInvisible forKey:@"IgnoreInvisible"];
												 [saveSetting setBool:showcd forKey:@"showcd"];
												  [saveSetting setBool:unlockskin forKey:@"unlockskin"];
                        [saveSetting setBool:AimSkill forKey:@"AimSkill"];
												[saveSetting setFloat:aimType forKey:@"aimType"];
												  [saveSetting setBool:BlockHost forKey:@"BlockHost"]; 		
													[saveSetting setBool:LogGoc forKey:@"LogGoc"];
													[saveSetting setBool:modnut forKey:@"modnut"]; 						[saveSetting setBool:modnotify forKey:@"modnotify"];					[saveSetting setFloat:selectedValue2 forKey:@"selectedValue2"];
													[saveSetting setFloat:TypeKill forKey:@"TypeKill"];									[saveSetting setFloat:modenotify forKey:@"modenotify"]; 													[saveSetting setFloat:modMode forKey:@"modMode"]; 													[saveSetting setFloat:selectedbutton forKey:@"selectedbutton"];  													[saveSetting setBool:autott forKey:@"autott"]; 													[saveSetting setBool:onlymt forKey:@"onlymt"]; 													[saveSetting setBool:bocpha forKey:@"bocpha"]; 		 													[saveSetting setBool:hoimau forKey:@"hoimau"]; 			 													[saveSetting setBool:bangsuong forKey:@"bangsuong"]; 		 													[saveSetting setBool:capcuu forKey:@"capcuu"]; 				 													[saveSetting setFloat:hpbs forKey:@"hpbs"]; 													[saveSetting setFloat:hpbocpha forKey:@"hpbocpha"]; 													[saveSetting setFloat:hphm forKey:@"hphm"]; 													[saveSetting setFloat:hpcc forKey:@"hpcc"]; 													
												[saveSetting setFloat:CameraHeight forKey:@"CameraHeight"];
                        NSArray *minimapPosArray = @[@(minimapPos.x), @(minimapPos.y)];
                        [saveSetting setObject:minimapPosArray forKey:@"minimapPos"];
                        [saveSetting setFloat:minimapRotation forKey:@"minimapRotation"];
                        [saveSetting setFloat:minimapScale forKey:@"minimapScale"];
                        [saveSetting setFloat:iconScale forKey:@"iconScale"];
                        [saveSetting setFloat:tablePosX forKey:@"tablePosX"];
                        [saveSetting setFloat:tablePosY forKey:@"tablePosY"];
                        [saveSetting setFloat:tableScale forKey:@"tableScale"];
                        [saveSetting synchronize];
                }
                ImGui::SameLine();
                if (ImGui::Button(oxorany("Dùng Cấu Hình Đã Lưu"))) {
									HackMap = [saveSetting boolForKey:@"HackMap"];
                        ESPEnable = [saveSetting boolForKey:@"ESPEnable"];
												skill1 = [saveSetting boolForKey:@"skill1"];
												skill2 = [saveSetting boolForKey:@"skill2"];
												skill3 = [saveSetting boolForKey:@"skill3"];
												aimdistance = [saveSetting floatForKey:@"aimdistance"];
												aimspeed = [saveSetting floatForKey:@"aimspeed"];

                        PlayerLine = [saveSetting boolForKey:@"PlayerLine"];
                        PlayerBox = [saveSetting boolForKey:@"PlayerBox"];
                        PlayerHealth = [saveSetting boolForKey:@"PlayerHealth"];
                        PlayerName = [saveSetting boolForKey:@"PlayerName"];
                        PlayerDistance = [saveSetting boolForKey:@"PlayerDistance"];
                        PlayerAlert = [saveSetting boolForKey:@"PlayerAlert"];
                        Drawicon = [saveSetting boolForKey:@"Drawicon"];
                        ESPCount = [saveSetting boolForKey:@"ESPCount"];
                        IgnoreInvisible = [saveSetting boolForKey:@"IgnoreInvisible"];
												showcd = [saveSetting boolForKey:@"showcd"];
												unlockskin = [saveSetting boolForKey:@"unlockskin"];
                        AimSkill = [saveSetting boolForKey:@"AimSkill"];
												
												BlockHost = [saveSetting boolForKey:@"BlockHost"];
												unlock2 = [saveSetting boolForKey:@"unlock2"];
												fakerank = [saveSetting floatForKey:@"fakerank"];
												fakesao = [saveSetting floatForKey:@"fakesao"];
												fakean = [saveSetting floatForKey:@"fakean"];
											toprank = [saveSetting floatForKey:@"toprank"];
											tophero = [saveSetting floatForKey:@"tophero"];
												LogGoc = [saveSetting boolForKey:@"LogGoc"];
												aimType = [saveSetting floatForKey:@"aimType"];
												
												modnut = [saveSetting boolForKey:@"modnut"]; 												modnotify = [saveSetting boolForKey:@"modnotify"]; 												selectedValue2 = [saveSetting floatForKey:@"selectedValue2"]; 												modenotify = [saveSetting floatForKey:@"modenotify"]; 												 	TypeKill = [saveSetting floatForKey:@"TypeKill"];											selectedbutton = [saveSetting floatForKey:@"selectedbutton"];  												autott = [saveSetting boolForKey:@"autott"]; 												onlymt = [saveSetting boolForKey:@"onlymt"]; 												bocpha = [saveSetting boolForKey:@"bocpha"]; 												bangsuong = [saveSetting boolForKey:@"bangsuong"]; 												hoimau = [saveSetting boolForKey:@"hoimau"]; 												capcuu = [saveSetting boolForKey:@"capcuu"]; 												hpbocpha = [saveSetting floatForKey:@"hpbocpha"]; 												hpbs = [saveSetting floatForKey:@"hpbs"]; 												hphm = [saveSetting floatForKey:@"hphm"]; 												hpcc = [saveSetting floatForKey:@"hpcc"]; 												modMode = [saveSetting floatForKey:@"modMode"];
												CameraHeight = [saveSetting floatForKey:@"CameraHeight"];
                        NSArray *minimapPosArray = [saveSetting objectForKey:@"minimapPos"];
                        minimapPos = ImVec2([minimapPosArray[0] floatValue], [minimapPosArray[1] floatValue]);
                        minimapRotation = [saveSetting floatForKey:@"minimapRotation"];
                        minimapScale = [saveSetting floatForKey:@"minimapScale"];
                        iconScale = [saveSetting floatForKey:@"iconScale"];
                        tablePosX = [saveSetting floatForKey:@"tablePosX"];
                        tablePosY = [saveSetting floatForKey:@"tablePosY"];
                        tableScale = [saveSetting floatForKey:@"tableScale"];
                }
                ImGui::SameLine(); 

                if (ImGui::Button(("Đặt Lại Cấu Hình"))) {
									HackMap = false;
									unlock2 = false;
									ESPEnable = false;
									AimSkill = false;
                        fakerank = 32;
												fakesao = 250;
												fakean = 25;
												toprank = 1;
												tophero = 150;
												BlockHost = false;
                        PlayerLine = false;
                        PlayerBox = false;
                        PlayerHealth = false;
                        PlayerName = false;
                        PlayerDistance = false;
                        PlayerAlert = false;
                        Drawicon = false;
                        ESPCount = false;
                        IgnoreInvisible = false;
												showcd = false;
												unlockskin = false;
                       
												CameraHeight = 10;
                        minimapPos = ImVec2(46.176f, 2.371f);
                        minimapRotation = -0.6f;
                        iconScale = 1.902f;
                        minimapScale = 1.262f;
                }

                ImGui::SameLine();

                if (ImGui::Button("Đăng Xuất"))
                {
                    deleteBeetalkSessionDB();
                }
}

-(void)initImageTexture: (id<MTLDevice>)device {
    heroTextures = [[NSMutableDictionary alloc] init];

    // Initialize hero textures
    [self addHeroTexture:device heroName:@"airi" base64Data:airi_data];
    [self addHeroTexture:device heroName:@"aleister" base64Data:aleister_data];
    [self addHeroTexture:device heroName:@"alice" base64Data:alice_data];
    [self addHeroTexture:device heroName:@"allain" base64Data:allain_data];
    [self addHeroTexture:device heroName:@"amily" base64Data:amily_data];
    [self addHeroTexture:device heroName:@"annette" base64Data:annette_data];
    [self addHeroTexture:device heroName:@"aoi" base64Data:aoi_data];
    [self addHeroTexture:device heroName:@"arduin" base64Data:arduin_data];
    [self addHeroTexture:device heroName:@"athur" base64Data:arthur_data];
    [self addHeroTexture:device heroName:@"arum" base64Data:arum_data];
    [self addHeroTexture:device heroName:@"astrid" base64Data:astrid_data];
    [self addHeroTexture:device heroName:@"ata" base64Data:ata_data];
    [self addHeroTexture:device heroName:@"aya" base64Data:aya_data];
    [self addHeroTexture:device heroName:@"azzenka" base64Data:azzenka_data];
    [self addHeroTexture:device heroName:@"baldum" base64Data:baldum_data];
    [self addHeroTexture:device heroName:@"bijan" base64Data:bijan_data];
    [self addHeroTexture:device heroName:@"bonnie" base64Data:bonnie_data];
    [self addHeroTexture:device heroName:@"bright" base64Data:bright_data];
    [self addHeroTexture:device heroName:@"butterfly" base64Data:butterfly_data];
    [self addHeroTexture:device heroName:@"capheny" base64Data:capheny_data];
    [self addHeroTexture:device heroName:@"celica" base64Data:celica_data];
    [self addHeroTexture:device heroName:@"charlotter" base64Data:charlotter_data];
    [self addHeroTexture:device heroName:@"chaugnar" base64Data:chaugnar_data];
    [self addHeroTexture:device heroName:@"cresht" base64Data:cresht_data];
    [self addHeroTexture:device heroName:@"darcy" base64Data:darcy_data];
    [self addHeroTexture:device heroName:@"dextra" base64Data:dextra_data];
    [self addHeroTexture:device heroName:@"dieuthuyen" base64Data:dieuthuyen_data];
    [self addHeroTexture:device heroName:@"dirak" base64Data:dirak_data];
    [self addHeroTexture:device heroName:@"dolia" base64Data:dolia_data];
    [self addHeroTexture:device heroName:@"elandorr" base64Data:elandorr_data];
    [self addHeroTexture:device heroName:@"elsu" base64Data:elsu_data];
    [self addHeroTexture:device heroName:@"enzo" base64Data:enzo_data];
    [self addHeroTexture:device heroName:@"erin" base64Data:erin_data];
    [self addHeroTexture:device heroName:@"errol" base64Data:errol_data];
    [self addHeroTexture:device heroName:@"fennik" base64Data:fennik_data];
    [self addHeroTexture:device heroName:@"florentino" base64Data:florentino_data];
    [self addHeroTexture:device heroName:@"gildur" base64Data:gildur_data];
    [self addHeroTexture:device heroName:@"grakk" base64Data:grakk_data];
    [self addHeroTexture:device heroName:@"hayate" base64Data:hayate_data];
    [self addHeroTexture:device heroName:@"helen" base64Data:helen_data];
    [self addHeroTexture:device heroName:@"iggy" base64Data:iggy_data];
    [self addHeroTexture:device heroName:@"ignis" base64Data:ignis_data];
    [self addHeroTexture:device heroName:@"ilumia" base64Data:ilumia_data];
    [self addHeroTexture:device heroName:@"ishar" base64Data:ishar_data];
    [self addHeroTexture:device heroName:@"jinna" base64Data:jinna_data];
    [self addHeroTexture:device heroName:@"kahlii" base64Data:kahlii_data];
    [self addHeroTexture:device heroName:@"kaine" base64Data:kaine_data];
    [self addHeroTexture:device heroName:@"keera" base64Data:kerra_data];
    [self addHeroTexture:device heroName:@"kilgroth" base64Data:kilgroth_data];
    [self addHeroTexture:device heroName:@"kriknak" base64Data:kriknak_data];
    [self addHeroTexture:device heroName:@"krixi" base64Data:krixi_data];
    [self addHeroTexture:device heroName:@"krizzix" base64Data:krizzix_data];
    [self addHeroTexture:device heroName:@"lauriel" base64Data:lauriel_data];
    [self addHeroTexture:device heroName:@"laville" base64Data:laville_data];
    [self addHeroTexture:device heroName:@"liliana" base64Data:liliana_data];
    [self addHeroTexture:device heroName:@"lindis" base64Data:lindis_data];
    [self addHeroTexture:device heroName:@"lorion" base64Data:lorion_data];
    [self addHeroTexture:device heroName:@"lubo" base64Data:lubo_data];
    [self addHeroTexture:device heroName:@"lumburr" base64Data:lumburr_data];
    [self addHeroTexture:device heroName:@"maloch" base64Data:maloch_data];
    [self addHeroTexture:device heroName:@"marja" base64Data:marja_data];
    [self addHeroTexture:device heroName:@"max" base64Data:max_data];
    [self addHeroTexture:device heroName:@"mganga" base64Data:mganga_data];
    [self addHeroTexture:device heroName:@"mina" base64Data:mina_data];
    [self addHeroTexture:device heroName:@"ming" base64Data:ming_data];
    [self addHeroTexture:device heroName:@"moren" base64Data:moren_data];
    [self addHeroTexture:device heroName:@"murad" base64Data:murad_data];
    [self addHeroTexture:device heroName:@"nakroth" base64Data:nakroth_data];
    [self addHeroTexture:device heroName:@"natalya" base64Data:natalya_data];
    [self addHeroTexture:device heroName:@"ngokhong" base64Data:ngokhong_data];
    [self addHeroTexture:device heroName:@"ormarr" base64Data:omar_data];
    [self addHeroTexture:device heroName:@"omega" base64Data:omega_data];
    [self addHeroTexture:device heroName:@"omen" base64Data:omen_data];
    [self addHeroTexture:device heroName:@"paine" base64Data:pain_data];
    [self addHeroTexture:device heroName:@"preyta" base64Data:preyta_data];
    [self addHeroTexture:device heroName:@"qi" base64Data:qi_data];
    [self addHeroTexture:device heroName:@"quillen" base64Data:quilen_data];
    [self addHeroTexture:device heroName:@"raz" base64Data:raz_data];
    [self addHeroTexture:device heroName:@"richter" base64Data:richter_data];
    [self addHeroTexture:device heroName:@"rouie" base64Data:rouie_data];
    [self addHeroTexture:device heroName:@"rourke" base64Data:rouke_data];
    [self addHeroTexture:device heroName:@"roxie" base64Data:roxie_data];
    [self addHeroTexture:device heroName:@"ryoma" base64Data:ryoma_data];
    [self addHeroTexture:device heroName:@"sephera" base64Data:sephera_data];
    [self addHeroTexture:device heroName:@"sinestrea" base64Data:sinestrea_data];
    [self addHeroTexture:device heroName:@"skud" base64Data:skud_data];
    [self addHeroTexture:device heroName:@"slimz" base64Data:slimz_data];
    [self addHeroTexture:device heroName:@"stuart" base64Data:Stuart_data];
    [self addHeroTexture:device heroName:@"supperman" base64Data:superman_data];
    [self addHeroTexture:device heroName:@"tachi" base64Data:tachi_data];
    [self addHeroTexture:device heroName:@"tarra" base64Data:tara_data];
    [self addHeroTexture:device heroName:@"teemee" base64Data:teemee_data];
    [self addHeroTexture:device heroName:@"telannas" base64Data:telannas_data];
    [self addHeroTexture:device heroName:@"terri" base64Data:terri_data];
    [self addHeroTexture:device heroName:@"thane" base64Data:thane_data];
    [self addHeroTexture:device heroName:@"theflash" base64Data:theflash_data];
    [self addHeroTexture:device heroName:@"thorne" base64Data:thorne_data];
    [self addHeroTexture:device heroName:@"toro" base64Data:toro_data];
    [self addHeroTexture:device heroName:@"trieuvan" base64Data:trieuvan_data];
    [self addHeroTexture:device heroName:@"tulen" base64Data:tulen_data];
    [self addHeroTexture:device heroName:@"valhein" base64Data:valhein_data];
    [self addHeroTexture:device heroName:@"veres" base64Data:veres_data];
    [self addHeroTexture:device heroName:@"veera" base64Data:verra_data];
    [self addHeroTexture:device heroName:@"violet" base64Data:violet_data];
    [self addHeroTexture:device heroName:@"volkath" base64Data:volkat_data];
    [self addHeroTexture:device heroName:@"wisp" base64Data:wips_data];
    [self addHeroTexture:device heroName:@"wiro" base64Data:wiro_data];
    [self addHeroTexture:device heroName:@"wonderwoman" base64Data:wonderwoman_data];
    [self addHeroTexture:device heroName:@"xenniel" base64Data:xeniel_data];
    [self addHeroTexture:device heroName:@"yan" base64Data:yan_data];
    [self addHeroTexture:device heroName:@"ybneth" base64Data:ybneth_data];
    [self addHeroTexture:device heroName:@"yenna" base64Data:yena_data];
    [self addHeroTexture:device heroName:@"yorn" base64Data:yorn_data];
    [self addHeroTexture:device heroName:@"yue" base64Data:yue_data];
    [self addHeroTexture:device heroName:@"zata" base64Data:zata_data];
    [self addHeroTexture:device heroName:@"zephys" base64Data:zephys_data];
    [self addHeroTexture:device heroName:@"zill" base64Data:zill_data];
    [self addHeroTexture:device heroName:@"zip" base64Data:zip_data];
    [self addHeroTexture:device heroName:@"zuka" base64Data:zuka_data];
    [self addHeroTexture:device heroName:@"biron" base64Data:biron_data];
}

- (void)addHeroTexture:(id<MTLDevice>)device heroName:(NSString *)heroName base64Data:(NSString *)base64Data {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    id<MTLTexture> texture = [self loadImageTexture:device data:data];
    if (texture) {
        [heroTextures setObject:texture forKey:heroName];
    }
}

-(id<MTLTexture>)loadImageTexture:(id<MTLDevice>)device data:(NSData *)imageData {
    int width, height;
    unsigned char *pixels = stbi_load_from_memory((stbi_uc const *)[imageData bytes], (int)[imageData length], &width, &height, NULL, 4);

    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                 width:(NSUInteger)width
                                                                                                height:(NSUInteger)height
                                                                                             mipmapped:NO];
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    textureDescriptor.storageMode = MTLStorageModeShared;
    id<MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor];
    [texture replaceRegion:MTLRegionMake2D(0, 0, (NSUInteger)width, (NSUInteger)height) mipmapLevel:0 withBytes:pixels bytesPerRow:(NSUInteger)width * 4];

    return texture;
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{

      self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];

    if (!self.device) abort();

 IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();

    ImGuiStyle &style = ImGui::GetStyle();
    style.WindowPadding     = ImVec2(10, 10);
    style.WindowRounding    = 5.0f;
    style.FramePadding      = ImVec2(5, 5);
    style.FrameRounding     = 7.5;
    style.ItemSpacing       = ImVec2(12, 8);
    style.ItemInnerSpacing  = ImVec2(8, 6);
    style.IndentSpacing     = 25.0f;
    style.ScrollbarSize     = 15.0f;
    style.ScrollbarRounding = 9.0f;
    style.GrabMinSize       = 5.0f;
    style.GrabRounding      = 3.0f;
    style.WindowBorderSize  = 1.0f;
    style.FrameBorderSize   = 1.0f;
    style.PopupBorderSize   = 1.0f;
    style.Alpha             = 0.8f;

            style.WindowTitleAlign = ImVec2(0.490f, 0.520f);
    ImVec4* colors = ImGui::GetStyle().Colors;
    colors[ImGuiCol_Text]                   = ImColor(242, 245, 250);
    colors[ImGuiCol_TextDisabled]           = ImColor(92, 107, 120);
    colors[ImGuiCol_WindowBg]               = ImColor(20, 20, 20, 255);
    colors[ImGuiCol_ChildBg]                = ImColor(25, 25, 25, 255);
    colors[ImGuiCol_PopupBg]                = ImColor(20, 20, 20, 240);
    colors[ImGuiCol_Border]                 = ImColor(0, 0, 0, 255);
    colors[ImGuiCol_BorderShadow]           = ImColor(0, 0, 0, 0);
    colors[ImGuiCol_FrameBg]                = ImColor(35, 35, 35, 255);
    colors[ImGuiCol_FrameBgHovered]         = ImColor(45, 45, 45, 255);
    colors[ImGuiCol_FrameBgActive]          = ImColor(55, 55, 55, 255);
    colors[ImGuiCol_TitleBg]                = ImColor(23, 30, 36, 165);
    colors[ImGuiCol_TitleBgActive]          = ImColor(20, 25, 30, 255);
    colors[ImGuiCol_TitleBgCollapsed]       = ImColor(0, 0, 0, 130);
    colors[ImGuiCol_MenuBarBg]              = ImColor(38, 46, 56);
    colors[ImGuiCol_ScrollbarBg]            = ImColor(5, 5, 5, 100);
    colors[ImGuiCol_ScrollbarGrab]          = ImColor(51, 64, 74);
    colors[ImGuiCol_ScrollbarGrabHovered]   = ImColor(46, 56, 64);
    colors[ImGuiCol_ScrollbarGrabActive]    = ImColor(23, 53, 79);
    colors[ImGuiCol_CheckMark]              = ImColor(66, 150, 250);
    colors[ImGuiCol_SliderGrab]             = ImColor(0, 200, 0, 255);
    colors[ImGuiCol_SliderGrabActive]       = ImColor(0, 255, 0, 255);
    colors[ImGuiCol_Button]                 = ImColor(51, 64, 74);
    colors[ImGuiCol_ButtonHovered]          = ImColor(205, 250, 0, 255);
    colors[ImGuiCol_ButtonActive]           = ImColor(15, 135, 250);
    colors[ImGuiCol_Header]                 = ImColor(51, 64, 74, 140);
    colors[ImGuiCol_HeaderHovered]          = ImColor(66, 150, 250, 204);
    colors[ImGuiCol_HeaderActive]           = ImColor(66, 150, 250, 255);
    colors[ImGuiCol_Separator]              = ImColor(51, 64, 74);
    colors[ImGuiCol_SeparatorHovered]       = ImColor(25, 102, 191, 200);
    colors[ImGuiCol_SeparatorActive]        = ImColor(25, 102, 191, 255);
    colors[ImGuiCol_ResizeGrip]             = ImColor(66, 150, 250, 51);
    colors[ImGuiCol_ResizeGripHovered]      = ImColor(66, 150, 250, 171);
    colors[ImGuiCol_ResizeGripActive]       = ImColor(66, 150, 250, 242);
    colors[ImGuiCol_Tab]                    = ImColor(28, 38, 43, 255);
    colors[ImGuiCol_TabHovered]             = ImColor(66, 150, 250, 204);
    colors[ImGuiCol_TabActive]              = ImColor(51, 64, 74);
    colors[ImGuiCol_TabUnfocused]           = ImColor(28, 38, 43);
    colors[ImGuiCol_TabUnfocusedActive]     = ImColor(28, 38, 43);
    colors[ImGuiCol_PlotLines]              = ImColor(155, 155, 155);
    colors[ImGuiCol_PlotLinesHovered]       = ImColor(255, 110, 90);
    colors[ImGuiCol_PlotHistogram]          = ImColor(230, 180, 0);
    colors[ImGuiCol_PlotHistogramHovered]   = ImColor(255, 153, 0);
    colors[ImGuiCol_TableHeaderBg]          = ImColor(48, 48, 51);
    colors[ImGuiCol_TableBorderStrong]      = ImColor(79, 79, 115);
    colors[ImGuiCol_TableBorderLight]       = ImColor(66, 66, 71);
    colors[ImGuiCol_TableRowBg]             = ImColor(0, 0, 0, 0);
    colors[ImGuiCol_TableRowBgAlt]          = ImColor(255, 255, 255, 15);
    colors[ImGuiCol_TextSelectedBg]         = ImColor(66, 150, 250, 90);
    colors[ImGuiCol_DragDropTarget]         = ImColor(255, 255, 0, 230);
    colors[ImGuiCol_NavHighlight]           = ImColor(66, 150, 250, 255);
    colors[ImGuiCol_NavWindowingHighlight]  = ImColor(255, 255, 255, 178);
    colors[ImGuiCol_NavWindowingDimBg]      = ImColor(204, 204, 204, 51);
    colors[ImGuiCol_ModalWindowDimBg]       = ImColor(204, 204, 204, 89);

    ImFontConfig config;
    ImFontConfig icons_config;
    config.FontDataOwnedByAtlas = false;
    icons_config.MergeMode = true;
    icons_config.PixelSnapH = true;
    icons_config.OversampleH = 2;
    icons_config.OversampleV = 2;

    static const ImWchar icons_ranges[] = { 0xf000, 0xf3ff, 0 };

    NSString *fontPath = nssoxorany("/System/Library/Fonts/Core/AvenirNext.ttc");

    _espFont = io.Fonts->AddFontFromFileTTF(fontPath.UTF8String, 30.f, &config, io.Fonts->GetGlyphRangesVietnamese());
//    _espFont = io.Fonts->AddFontFromMemoryTTF((void *)baidu_font_data, baidu_font_size, 30.0f, NULL,io.Fonts->GetGlyphRangesVietnamese());    ImGui_ImplMetal_Init(_device);


    _iconFont = io.Fonts->AddFontFromMemoryCompressedTTF(font_awesome_data, font_awesome_size, 19.0f, &icons_config, icons_ranges);

    _iconFont->FontSize = 5;
    io.FontGlobalScale = 0.5f;

    ImGui_ImplMetal_Init(_device);
    [self initImageTexture:_device];
    return self;
}

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}

-(void)cc
{


}

- (void)loadView
{

 

    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
        self.mtkView.device = self.device;
    if (!self.mtkView.device) {
        return;
    }
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;

    if ([saveSetting objectForKey:@"HackMap"] != nil) {
		HackMap = [saveSetting boolForKey:@"HackMap"];
        ESPEnable = [saveSetting boolForKey:@"ESPEnable"];
        PlayerLine = [saveSetting boolForKey:@"PlayerLine"];
        PlayerBox = [saveSetting boolForKey:@"PlayerBox"];
        PlayerHealth = [saveSetting boolForKey:@"PlayerHealth"];
        PlayerName = [saveSetting boolForKey:@"PlayerName"];
        PlayerDistance = [saveSetting boolForKey:@"PlayerDistance"];
        PlayerAlert = [saveSetting boolForKey:@"PlayerAlert"];
        Drawicon = [saveSetting boolForKey:@"Drawicon"];
        ESPCount = [saveSetting boolForKey:@"ESPCount"];
        IgnoreInvisible = [saveSetting boolForKey:@"IgnoreInvisible"];
				showcd = [saveSetting boolForKey:@"showcd"];
				unlockskin = [saveSetting boolForKey:@"unlockskin"];
        AimSkill = [saveSetting boolForKey:@"AimSkill"];
				aimType = [saveSetting floatForKey:@"aimType"];
				BlockHost =  [saveSetting boolForKey:@"BlockHost"];
				LogGoc =  [saveSetting boolForKey:@"LogGoc"];
				modnut =  [saveSetting boolForKey:@"modnut"];
				unlock2 =  [saveSetting boolForKey:@"unlock2"];
				fakerank = [saveSetting floatForKey:@"fakerank"];
				fakesao = [saveSetting floatForKey:@"fakesao"];
				fakean = [saveSetting floatForKey:@"fakean"];
				toprank = [saveSetting floatForKey:@"toprank"];
				tophero = [saveSetting floatForKey:@"tophero"];
			modnotify =  [saveSetting boolForKey:@"modnotify"];
			selectedValue2 = [saveSetting floatForKey:@"selectedValue2"];
			TypeKill = [saveSetting floatForKey:@"TypeKill"];
		modenotify = [saveSetting floatForKey:@"modenotify"];
				modMode = [saveSetting floatForKey:@"modMode"];
				selectedbutton = [saveSetting floatForKey:@"selectedbutton"];  												autott = [saveSetting boolForKey:@"autott"]; 												onlymt = [saveSetting boolForKey:@"onlymt"]; 												bocpha = [saveSetting boolForKey:@"bocpha"]; 												bangsuong = [saveSetting boolForKey:@"bangsuong"]; 												hoimau = [saveSetting boolForKey:@"hoimau"]; 												capcuu = [saveSetting boolForKey:@"capcuu"]; 												hpbocpha = [saveSetting floatForKey:@"hpbocpha"]; 												hpbs = [saveSetting floatForKey:@"hpbs"]; 												hphm = [saveSetting floatForKey:@"hphm"]; 												hpcc = [saveSetting floatForKey:@"hpcc"];
				CameraHeight = [saveSetting floatForKey:@"CameraHeight"];
				skill1 = [saveSetting boolForKey:@"skill1"];
				skill2 = [saveSetting boolForKey:@"skill2"];
				skill3 = [saveSetting boolForKey:@"skill3"];
				aimdistance = [saveSetting floatForKey:@"aimdistance"];
				aimspeed = [saveSetting floatForKey:@"aimspeed"];


        NSArray *minimapPosArray = [saveSetting objectForKey:@"minimapPos"];
        minimapPos = ImVec2([minimapPosArray[0] floatValue], [minimapPosArray[1] floatValue]);
        minimapRotation = [saveSetting floatForKey:@"minimapRotation"];
        minimapScale = [saveSetting floatForKey:@"minimapScale"];
        iconScale = [saveSetting floatForKey:@"iconScale"];
        tablePosX = [saveSetting floatForKey:@"tablePosX"];
        tablePosY = [saveSetting floatForKey:@"tablePosY"];

    }

}

#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}


- (void)drawInMTKView:(MTKView*)view
{
     //hideRecordTextfield.secureTextEntry = StreamerMode;
    
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 120);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    
        
        if (MenDeal == true) {
            [self.view setUserInteractionEnabled:YES];
        } else if (MenDeal == false) {
            [self.view setUserInteractionEnabled:NO];
        }

        MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
        if (renderPassDescriptor != nil)
        {
            id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            [renderEncoder pushDebugGroup:@"ImGui Jane"];

          ImGui_ImplMetal_NewFrame(renderPassDescriptor);
            ImGui::NewFrame();
            CGFloat width = 530;
            CGFloat height = 280;
            ImGui::SetNextWindowPos(ImVec2((kWidth - width) / 2, (kHeight - height) / 2), ImGuiCond_FirstUseEver);
            ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_FirstUseEver);

						
 static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
	LoadJsonFromGitHub();
	LoadModNutFromGitHub();
    // void* address[] = {  
    //     (void*)GetMethodOffset(("Project_d.dll"), ("Assets.Scripts.GameLogic"), ("HudComponent3D") , ("SetPlayerName"), 3),
    //     (void*)GetMethodOffset(("Project_d.dll"), ("Assets.Scripts.GameSystem"), ("SettlementHelper") , ("SetPlayerName"), 2)

    // };
    // void* function[] = {
    //     (void*)SetPlayerName,
    //     (void*)SetPlayerName2
    // };
    // hook(address, function, 2);
Attach();
Il2CppAttachOld();
Il2CppMethod& getClass(const char* namespaze, const char* className);
    uint64_t getMethod(const char* methodName, int argsCount);
    
    Il2CppMethod methodAccessSystem("Project_d.dll");
    Il2CppMethod methodAccessSystem2("Project.Plugins_d.dll");
    Il2CppMethod methodAccessRes("AovTdr.dll");
    espManager = new EntityManager();
    ActorLinker_enemy = new EntityManager();
		Il2CppMethod methodAccess("AovUISys.dll");
		actorlink_updateoffset = methodAccessSystem.getClass(oxorany("Kyrios.Actor"), oxorany("ActorLinker")).getMethod(oxorany("Update"), 0);
		uint64_t GetLegendTitleAreaTypeOff = methodAccess.getClass("Assets.Scripts.GameSystem", "CLegendUtility").getMethod("GetLegendTitleAreaType", 1);
    uint64_t ValidOff = methodAccess.getClass("Assets.Scripts.GameSystem", "CLegendHeroTitleData").getMethod("get_Valid", 0);
    uint64_t SetLegendTitleCompleteOff = methodAccess.getClass("Assets.Scripts.GameSystem", "CLegendUtility").getMethod("SetLegendTitleComplete", 12);
uint64_t unltb = Il2CppMethod("Project.Plugins_d.dll").getClass("NucleusDrive.Logic.GameKernal", "GamePlayerCenter").getMethod("GetPlayer", 1);
PlrList = (List<void *> *(*)(void *)) ((uintptr_t)GetMethodOffset(oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic.GameKernal"), oxorany("GamePlayerCenter"), oxorany("GetAllPlayers"), 0));
get_VHostLogic = (void* (*)())GetMethodOffset(oxorany("Project_d.dll"),oxorany("Kyrios"),oxorany("KyriosFramework"),oxorany("get_hostLogic"), 0);
    actorlink_destroyoffset = methodAccessSystem.getClass(oxorany("Kyrios.Actor"), oxorany("ActorLinker")).getMethod(oxorany("DestroyActor"), 0);

    lactor_updatelogic = methodAccessSystem2.getClass(oxorany("NucleusDrive.Logic"), oxorany("LActorRoot")).getMethod(oxorany("UpdateLogic"), 1);

    lactor_destroy = methodAccessSystem2.getClass(oxorany("NucleusDrive.Logic"), oxorany("LActorRoot")).getMethod(oxorany("DestroyActor"), 1);

spamchat = [[NSUserDefaults standardUserDefaults] boolForKey:@"spamchat"];

uint64_t spamchatoffset = Il2CppMethod("Project_d.dll").getClass("Assets.Scripts.GameSystem", "InBattleMsgNetCore").getMethod("SendInBattleMsg_InputChat", 2);

    hackmapoffset = methodAccessSystem2.getClass(oxorany("NucleusDrive.Logic"), oxorany("LVActorLinker")).getMethod(oxorany("SetVisible"), 3);

    hienulti2 = methodAccessSystem.getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("HeroInfoPanel")).getMethod(oxorany("ShowHeroInfo"), 2) + 0x1C;

    camoffset = methodAccessSystem.getClass("", oxorany("CameraSystem")).getMethod(oxorany("GetZoomRate"), 0);

    
    updateoffset = methodAccessSystem.getClass("", oxorany("CameraSystem")).getMethod(oxorany("LateUpdate"), 0);

    updatelogicoffset = methodAccessSystem.getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("CSkillButtonManager")).getMethod(oxorany("UpdateLogic"), 1);

    skilldirectoffset = methodAccessSystem.getClass(oxorany("Assets.Scripts.GameLogic"), oxorany("SkillControlIndicator")).getMethod(oxorany("GetUseSkillDirection"), 1);

    sendsyncOffset = methodAccessSystem2.getClass("NucleusDrive.Logic", "LFrameSyncBattleLogic").getMethod("SendSyncData", 2);
    updateframelateroffset = methodAccessSystem2.getClass("NucleusDrive.Logic", "LFrameSynchr").getMethod("UpdateFrameLater", 0);
    sampleframesyncdataoffset = methodAccessSystem2.getClass("NucleusDrive.Logic", "LSynchrReport").getMethod("SampleFrameSyncData", 0);
		uint64_t handlereport = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany(""), oxorany("FirebasePush")).getMethod(oxorany("handleReportInfoResult"), 1);
		uint64_t handleupdate = Il2CppMethod(oxorany("Project.Plugins_d.dll")).getClass(oxorany("NucleusDrive.Statistics"), oxorany("HangUpStaticInfoState")).getMethod(oxorany("HandleUpdate"), 1);
		uint64_t onhashcheckrsp = Il2CppMethod(oxorany("Project.Plugins_d.dll")).getClass(oxorany("NucleusDrive.Logic"), oxorany("LSynchrReport")).getMethod(oxorany("OnHashCheckRsp"), 1);
    enequehashoffset = methodAccessSystem2.getClass("NucleusDrive.Logic", "LSynchrReport").getMethod("EnqueHashValueByFrameNum", 2);

    setloginoffset = methodAccessSystem2.getClass("NucleusDrive.Logic", "LDedicatedSvrConnector").getMethod("SetLogin", 2);
		
		uint64_t autologinoffset = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("CGCloudUpdateSystem")).getMethod(oxorany("get_IsAutoLogin"), 0);
		
		
    HistoryOffset = methodAccessSystem.getClass("Assets.Scripts.GameSystem", "CPlayerProfile").getMethod("get_IsHostProfile", 0);

		isopenoffset = methodAccessSystem.getClass("Assets.Scripts.GameSystem", "PersonalButton").getMethod("IsOpen", 0);
	buttonoffset = methodAccessSystem.getClass("Assets.Scripts.GameSystem", "PersonalButton").getMethod("get_PersonalBtnId", 0);

chaptodanhthang = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameLogic"), oxorany("LobbyMsgHandler")).getMethod(oxorany("HandleGameSettle"), 4);

	Skslotoffset = methodAccessSystem.getClass(oxorany("Assets.Scripts.GameLogic"), oxorany("SkillSlot")).getMethod(oxorany("LateUpdate"), 1);
		autottoffset = methodAccessSystem.getClass(oxorany("Kyrios.VAGE"), oxorany("PunishPromptDuration")).getMethod(oxorany("get_isHpUnderPunishValue"), 0);
		OnClickSelectHeroSkinOffset = methodAccessSystem.getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("HeroSelectNormalWindow")).getMethod(oxorany("OnClickSelectHeroSkin"), 2); // Unlock skin

    IsCanUseSkinOffset = methodAccessSystem.getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("CRoleInfo")).getMethod(oxorany("IsCanUseSkin"), 2); // Unlock Skin


    GetHeroWearSkinIdOffset = methodAccessSystem.getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("CRoleInfo")).getMethod(oxorany("GetHeroWearSkinId"), 1); // Unlock Skin


    IsHaveHeroSkinOffset = methodAccessSystem.getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("CRoleInfo")).getMethod(oxorany("IsHaveHeroSkin"), 3); // Unlock Skin

    unpackOffset = methodAccessRes.getClass(oxorany("CSProtocol"), oxorany("COMDT_HERO_COMMON_INFO")).getMethod(oxorany("unpack"), 2); // Unlock Skin
		
		onenteroffset = methodAccessSystem.getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("PVPLoadingView")).getMethod(oxorany("OnEnter"), 0);
	
		endgameoffset = methodAccessSystem2.getClass(oxorany("NucleusDrive.Logic"), oxorany("LFramework")).getMethod(oxorany("EndGame"), 2);
		
		uint64_t gameoveroffset = Il2CppMethod(oxorany("Project.Plugins_d.dll")).getClass(oxorany("NucleusDrive.Statistics"), oxorany("BattleStatistic")).getMethod(oxorany("CreateGameOverSummary"), 0);
		uint64_t offsetbando = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany(""), oxorany("GMCommandBluePrint")).getMethod(oxorany("SellEquipment"), 2);
		uint64_t offsetmuado = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany(""), oxorany("GMCommandBluePrint")).getMethod(oxorany("BuyEquipment"), 2);
		uint64_t disconnectoffset = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.Framework"), oxorany("RelaySvrConnectProxy/RelaySvrConnector")).getMethod(oxorany("Disconnect"), 0);
		
		uint64_t reconnectoffset = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.Framework"), oxorany("RelaySvrConnectProxy/RelaySvrConnector")).getMethod(oxorany("onTryReconnect"), 2);
		uint64_t isplayeroffset = methodAccessSystem2.getClass("LDataProvider", oxorany("PlayerBase")).getMethod(oxorany("IsAtMyTeam"), 2);
		uint64_t hideuid = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("CLobbySystem")).getMethod(oxorany("OpenWaterMark"), 0);
		uint64_t hienulti1 = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("HeroInfoPanel")).getMethod(oxorany("InitHeroItemData"), 2) + 0x210;
        uint64_t hienulti2 = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("HeroInfoPanel")).getMethod(oxorany("ShowHeroInfo"), 2) + 0x1C;
        uint64_t ranko = Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("PVPLoadingView")).getMethod(oxorany("OnEnter"), 0) + 0xB00;
        uint64_t btro = Il2CppMethod(oxorany("Project_d.dll")).getClass("Assets.Scripts.GameSystem", "UIBattleStatView/HeroItem").getMethod("updateTalentSkillCD", 1) + 0x1B8;

Reqskill = (bool (*)(void *))GetMethodOffset(oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameLogic"), oxorany("SkillSlot"), oxorany("RequestUseSkill"), 0);

    ActorLinker_IsHostPlayer = (bool (*)(void *))GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker") , oxorany("IsHostPlayer"), 0);  
    ActorLinker_ActorTypeDef = (int (*)(void *))GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker") , oxorany("get_objType"), 0);     
    ActorLinker_COM_PLAYERCAMP = (int (*)(void *))GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker") , oxorany("get_objCamp"), 0); 
    ActorLinker_getPosition = (Vector3(*)(void *))GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker") , oxorany("get_position"), 0);   
    ActorLinker_get_bVisible = (bool (*)(void *))GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker") , oxorany("get_bVisible"), 0);

    LActorRoot_LHeroWrapper = (uintptr_t(*)(void *))GetMethodOffset(oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"), oxorany("LActorRoot") , oxorany("AsHero"), 0);
    LActorRoot_COM_PLAYERCAMP = (int (*)(void *))GetMethodOffset(oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"), oxorany("LActorRoot") , oxorany("GiveMyEnemyCamp"), 0);
      

    LObjWrapper_get_IsDeadState = (bool (*)(void *))GetMethodOffset(oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"), oxorany("LObjWrapper") , oxorany("get_IsDeadState"), 0);
    LObjWrapper_IsAutoAI = (bool (*)(void *))GetMethodOffset(oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"), oxorany("LObjWrapper") , oxorany("IsAutoAI"), 0); 

    ValuePropertyComponent_get_actorHp = (int (*)(void *))GetMethodOffset(oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"), oxorany("ValuePropertyComponent") , oxorany("get_actorHp"), 0);   
    ValuePropertyComponent_get_actorHpTotal = (int (*)(void *))GetMethodOffset(oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"), oxorany("ValuePropertyComponent") , oxorany("get_actorHpTotal"), 0);

    AsHero = (uintptr_t(*)(void *)) GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker") , oxorany("AsHero"), 0);
    _SetPlayerName = (monoString* (*)(uintptr_t, monoString *, monoString *, bool, monoString *)) GetMethodOffset("Project_d.dll","Assets.Scripts.GameLogic","HudComponent3D","SetPlayerName", 4); 
      old_RefreshHeroPanel = (void (*)(void*, bool, bool, bool)) GetMethodOffset(("Project_d.dll"), ("Assets.Scripts.GameSystem"), ("HeroSelectNormalWindow"), ("RefreshHeroPanel"), 3);//MEOSTAR

     m_isCharging = (uintptr_t)GetFieldOffset(oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"), oxorany("CSkillButtonManager") , oxorany("m_isCharging"));
    m_currentSkillSlotType = (uintptr_t)GetFieldOffset(oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameSystem"), oxorany("CSkillButtonManager") , oxorany("m_currentSkillSlotType"));
    botro = (uintptr_t)ENCRYPTOFFSET("0xC8");
    c1 = (uintptr_t)ENCRYPTOFFSET("0x48");
    c2 = (uintptr_t)ENCRYPTOFFSET("0x68");
    c3 = (uintptr_t)ENCRYPTOFFSET("0x88");



    // DobbyHook((void *)GetMethodOffset(("Project_d.dll"), ("Kyrios.Actor"), ("ActorLinker"), ("Update"), 0), (void *)ActorLinker_Update, (void **)&old_ActorLinker_Update);
    // DobbyHook((void *)GetMethodOffset(("Project_d.dll"), ("Kyrios.Actor"), ("ActorLinker"), ("DestroyActor"), 0), (void *)ActorLinker_ActorDestroy, (void **)&old_ActorLinker_ActorDestroy);
    // DobbyHook((void *)GetMethodOffset(("Project.Plugins_d.dll"), ("NucleusDrive.Logic"), ("LActorRoot"), ("UpdateLogic"), 1), (void *)LActorRoot_UpdateLogic, (void **)&old_LActorRoot_UpdateLogic);
    // DobbyHook((void *)GetMethodOffset(("Project.Plugins_d.dll"), ("NucleusDrive.Logic"), ("LActorRoot"), ("DestroyActor"), 1), (void *)LActorRoot_ActorDestroy, (void **)&old_LActorRoot_ActorDestroy);
    // DobbyHook((void *)GetMethodOffset(("Project_d.dll"), (""), ("CameraSystem"), ("LateUpdate"), 0), (void *)_LateUpdate, (void **)&LateUpdate);
    // DobbyHook((void *)GetMethodOffset(("Project_d.dll"), (""), ("CameraSystem"), ("GetCameraHeightRateValue"), 1), (void *)_GetCameraHeightRateValue, (void **)&GetCameraHeightRateValue);
    
		ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", enequehashoffset, "C0035FD6");
		ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", handlereport, "C0035FD6");
		ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", onhashcheckrsp, "C0035FD6");
		ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", hideuid, "C0035FD6");
		ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", handleupdate, "000080D2C0035FD6");


ShinAOV(spamchatoffset, SendInBattleMsg_InputChat, _SendInBattleMsg_InputChat);
ShinAOV(chaptodanhthang, HandleGameSettle,_HandleGameSettle)
		
	ShinAOV(setloginoffset, _SetLogin, SetLogin);	 
    ShinAOV(actorlink_updateoffset, ActorLinker_Update, old_ActorLinker_Update);                      
    ShinAOV(lactor_updatelogic, LActorRoot_UpdateLogic, old_LActorRoot_UpdateLogic);              
    ShinAOV(actorlink_destroyoffset, ActorLinker_ActorDestroy, old_ActorLinker_ActorDestroy);          
    ShinAOV(lactor_destroy, LActorRoot_ActorDestroy, old_LActorRoot_ActorDestroy);            
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

    // DobbyHook((void *)GetMethodOffset(("Project_d.dll"), ("Assets.Scripts.GameSystem"), ("CSkillButtonManager"), ("UpdateLogic"), 1), (void *)UpdateLogic, (void **)&_UpdateLogic);
    // DobbyHook((void *)GetMethodOffset(("Project_d.dll"), ("Assets.Scripts.GameLogic"), ("SkillControlIndicator"), ("GetUseSkillDirection"), 1), (void *)GetUseSkillDirection, (void **)&_GetUseSkillDirection);
ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", updateframelateroffset, "C0035FD6"); // botro
		ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", sampleframesyncdataoffset, "C0035FD6");
		ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", HistoryOffset, "200080D2C0035FD6");
    ShinAOV(updatelogicoffset, UpdateLogic, _UpdateLogic);                                   
    ShinAOV(skilldirectoffset, GetUseSkillDirection, _GetUseSkillDirection);                 
		ShinAOV(hackmapoffset, SetVisible, _SetVisible);                                     
    ShinAOV(updateoffset, _LateUpdate, LateUpdate);                                         
    ShinAOV(camoffset, _GetZoomRate, GetZoomRate);     
		
ShinAOV(Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("CRoleInfoManager")).getMethod(oxorany("GetMasterRoleInfo"), 0), GetMasterRoleInfo, _GetMasterRoleInfo);

});
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
	ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", hienulti1, "1F2003D5"); // ulti 1
    ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", hienulti2, "330080D2"); // ulti 2
    ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", ranko, "1F2003D5"); // rank 
    ActiveCodePatch("Frameworks/UnityFramework.framework/UnityFramework", btro, "1F2003D5"); // botro
		
		ShinAOV(offsetbando, _SellEquipment, SellEquipment);
	ShinAOV(GetHeroWearSkinIdOffset, GetHeroWearSkinId, old_GetHeroWearSkinId);           
	
	ShinAOV(IsHaveHeroSkinOffset, IsHaveHeroSkin, old_IsHaveHeroSkin); 
	
   ShinAOV(onenteroffset, _OnEnter, OnEnter);                                           
ShinAOV(Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("CLadderSystem")).getMethod(oxorany("GetCurrentRankDetail"), 0), GetCurrentRankDetail, _GetCurrentRankDetail);
ShinAOV(Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("PVPLoadingView")).getMethod(oxorany("TryShowLegendRank"), 6), _TryShowLegendRank, TryShowLegendRank);
ShinAOV(Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("PVPLoadingView")).getMethod(oxorany("IsShowLegendRankMode"), 1), _IsShowLegendRankMode, IsShowLegendRankMode);
}); 

dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
	ShinAOV(Il2CppMethod(oxorany("AovTdr.dll")).getClass(oxorany("CSProtocol"), oxorany("COMDT_TOP_OR_AREA_LEGEND_TITLE_INFO")).getMethod(oxorany("unpack"), 2), _unpackTop, unpackTop);
ShinAOV(Il2CppMethod(oxorany("Project_d.dll")).getClass(oxorany("Assets.Scripts.GameSystem"), oxorany("PVPLoadingView")).getMethod(oxorany("CanPlayerShowLegendRank"), 8), _CanPlayerShowLegendRank, CanPlayerShowLegendRank);
ShinAOV(GetLegendTitleAreaTypeOff, _GetLegendTitleAreaType, GetLegendTitleAreaType);
ShinAOV(ValidOff, _get_Valid, get_Valid);
ShinAOV(SetLegendTitleCompleteOff, _SetLegendTitleComplete, SetLegendTitleComplete);

   ShinAOV(unpackOffset, unpack, old_unpack);                                 
	ShinAOV(OnClickSelectHeroSkinOffset, OnClickSelectHeroSkin, old_OnClickSelectHeroSkin);   
	ShinAOV(IsCanUseSkinOffset, IsCanUseSkin, old_IsCanUseSkin); 
	
});
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

ShinAOV(isopenoffset, IsOpen, old_IsOpen);

ShinAOV(unltb, _GetPlayer, GetPlayer);

ShinAOV(buttonoffset, get_PersonalBtnId, old_get_PersonalBtnId); 
 	ShinAOV(Skslotoffset, Skslot, _Skslot);             
		ShinAOV(autottoffset, sting, _sting);
			ShinAOV(endgameoffset, _EndGame, EndGame); 
			ShinAOV(disconnectoffset, _Disconnected, Disconnected);	 
			ShinAOV(isplayeroffset, _IsAtMyTeam, IsAtMyTeam);
//ShinAOV(ENCRYPTOFFSET("0x3B1C300"), _GetProfile, GetProfile);
		[self activehack:NSSENCRYPT("Welcome To AOV")
        message:NSSENCRYPT("Hack Siêu Lỏ || By HaiLong")
            font:[UIFont fontWithName:NSSENCRYPT("AvenirNext-Bold") size:14]
						duration:5.0];
			
					});
		
});
            
   if (MenDeal == true) {
 NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
 std::string Bundle([bundleIdentifier UTF8String]);
 NSString *safari_localizedShortVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:NSSENCRYPT("CFBundleShortVersionString")];
 std::string Version([safari_localizedShortVersion UTF8String]);
 NSString *safari_displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:NSSENCRYPT("CFBundleDisplayName")];
 std::string sName([safari_displayName UTF8String]);

    char* Gnam = (char*) [[NSString stringWithFormat:nssoxorany("Hackmap x LQMB - Version: %@ "), ver] cStringUsingEncoding:NSUTF8StringEncoding];
        ImGui::Begin(Gnam, &MenDeal, ImGuiWindowFlags_NoTitleBar);        
  ImDrawList* draw = ImGui::GetWindowDrawList();
 const ImVec2 pos = ImGui::GetWindowPos();
 float time = ImGui::GetTime();
ImVec2 winPos = ImGui::GetWindowPos();
ImVec2 winSize = ImGui::GetWindowSize();
ImVec2 gridMin = winPos;
ImVec2 gridMax = ImVec2(winPos.x + 530, winPos.y + 280); // Bố chỉnh đúng size menu nếu khác

const int pointCount = 80;
static ImVec2 points[pointCount];
static bool firstFrame = true;
static ImVec2 lastWinPos;

if (firstFrame || winPos.x != lastWinPos.x || winPos.y != lastWinPos.y) {
    for (int i = 0; i < pointCount; ++i) {
        float x = gridMin.x + (rand() % (int)(gridMax.x - gridMin.x));
        float y = gridMin.y + (rand() % (int)(gridMax.y - gridMin.y));
        points[i] = ImVec2(x, y);
    }
    firstFrame = false;
    lastWinPos = winPos;
}

for (int i = 0; i < pointCount; ++i) {
    points[i].x += sin(time * 0.5f + i) * 0.3f;
    points[i].y += cos(time * 0.5f + i) * 0.3f;
    points[i].x = ImClamp(points[i].x, gridMin.x, gridMax.x);
    points[i].y = ImClamp(points[i].y, gridMin.y, gridMax.y);
}

for (int i = 0; i < pointCount; ++i) {
    draw->AddCircleFilled(points[i], 1.8f, ImColor(255, 255, 255, 160), 6);
    for (int j = i + 1; j < pointCount; ++j) {
        float dx = points[i].x - points[j].x;
        float dy = points[i].y - points[j].y;
        float distSq = dx * dx + dy * dy;
        if (distSq < 9000.0f) {
            float alpha = 1.0f - (distSq / 9000.0f);
            draw->AddLine(points[i], points[j], ImColor(255, 255, 255, int(80 * alpha)), 0.5f);
        }
    }
}
 int currentDot = static_cast<int>(floor(time)) % 3;

 ImColor darkColors[3] = { ImColor(100, 30, 30), ImColor(100, 70, 30), ImColor(30, 100, 30) };
 ImColor glowColors[3] = { ImColor(255, 50, 50, 200), ImColor(255, 220, 100, 200), ImColor(130, 255, 130, 200) };

 draw->AddCircleFilled(ImVec2(pos.x + 12, pos.y + 12), 7, currentDot == 0 ? glowColors[0] : darkColors[0], 360);
 draw->AddCircleFilled(ImVec2(pos.x + 33, pos.y + 12), 7, currentDot == 1 ? glowColors[1] : darkColors[1], 360);
 draw->AddCircleFilled(ImVec2(pos.x + 54, pos.y + 12), 7, currentDot == 2 ? glowColors[2] : darkColors[2], 360);
//  ImGui::SetCursorPos({455, -7});
 ImGui::SetWindowFontScale(1.25f);
 ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0, 0, 0, 0));
 ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0, 0, 0, 0));
 ImGui::PushStyleColor(ImGuiCol_ButtonActive, ImVec4(0, 0, 0, 0));
 ImGui::PushStyleVar(ImGuiStyleVar_FrameBorderSize, 0.0f);
      // Tọa độ và bán kính của nút
      ImVec2 menuSize = ImGui::GetContentRegionAvail(); // Kích thước khả dụng trong cửa sổ
    ImVec2 center = ImVec2(ImGui::GetCursorScreenPos().x + menuSize.x -10, ImGui::GetCursorScreenPos().y + 3);
    float radius = 10.0f;

		
     ImGui::SetWindowFontScale(1.25f);
    ImGui::SetCursorPos({menuSize.x - 24, -9});
		
     if (ImGui::Button(ICON_FA_POWER_OFF"", ImVec2(50, 50))) {
 MenDeal = false;
 }
    ImGui::PopStyleVar();
 ImGui::PopStyleColor(3);


 ImGui::SetWindowFontScale(1.0f);
 ImGui::SetCursorPos({102, 6});
ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 1.0f, 0.0f, 1.0f));
 // Màu vàng (RGBA)
ImGui::Text(ENCRYPT("HLong Cheat AOV"));
ImGui::PopStyleColor(); // Khôi phục lại màu mặc định
ImGui::SameLine();
       std::time_t t = std::time(nullptr);
             std::tm* localTime = std::localtime(&t); // Lấy giờ địa phương
             char timeStr[9]; // Chuỗi lưu giờ (HH:MM:SS)
             std::strftime(timeStr, sizeof(timeStr), "%H:%M:%S", localTime); // Định dạng giờ
ImGui::Text(ENCRYPT("|    TIME:"));
ImGui::SameLine();
ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 0.0f, 1.0f, 1.0f)); // Màu hồng
ImGui::Text("%s", timeStr); // Hiển thị giờ
ImGui::PopStyleColor();


 ImGui::SetCursorPos({8, 26});

// Lấy vị trí hiện tại của cửa sổ
ImVec2 windowPos = ImGui::GetCursorScreenPos();

// Kích thước của hình chữ nhật
ImVec2 rectSize = ImVec2(88, menuSize.y - 14);

// Tọa độ của hình chữ nhật
ImVec2 rectStart = windowPos;
ImVec2 rectEnd = ImVec2(windowPos.x + rectSize.x, windowPos.y + rectSize.y);

// Truy cập ImDrawList để vẽ
ImDrawList* drawList = ImGui::GetWindowDrawList();
drawList->AddRectFilled(
    rectStart,               // Góc trên bên trái
    rectEnd,                 // Góc dưới bên phải
ImColor(42, 42, 42, 200), // Màu gốc với alpha = 255 (không trong suốt)
    5.0f                    // Độ bo góc
);
    // Vẽ các nút
     ImGui::SetCursorPos({14, 34});
    ImGui::BeginGroup();
    DrawCustomButton("MAIN", ImVec2(75, 28), 0, selectedTab);
    DrawCustomButton("AIM", ImVec2(75, 28), 1, selectedTab);
    DrawCustomButton("ESP", ImVec2(75, 28), 2, selectedTab);
    //DrawCustomButton("Setting", ImVec2(75, 20), 3, selectedTab);
    DrawCustomButton("SKIN", ImVec2(75, 28), 4, selectedTab);
    // Màu văn bản nút
DrawCustomButton("AUTO", ImVec2(75, 28), 5, selectedTab);
    ImGui::EndGroup();
if (selectedTab == 0) {
 ImGui::SetCursorPos({102, 26});
ImVec2 menuSize = ImGui::GetContentRegionAvail(); // Kích thước khả dụng trong cửa sổ
// Lấy vị trí hiện tại của cửa sổ
ImVec2 windowPos = ImGui::GetCursorScreenPos();

// Kích thước của hình chữ nhật
ImVec2 rectSize = ImVec2(menuSize.x + 2, menuSize.y + 2);

// Tọa độ của hình chữ nhật
ImVec2 rectStart = windowPos;
ImVec2 rectEnd = ImVec2(windowPos.x + rectSize.x, windowPos.y + rectSize.y);

// Truy cập ImDrawList để vẽ
ImDrawList* drawList = ImGui::GetWindowDrawList();
drawList->AddRectFilled(
    rectStart,               // Góc trên bên trái
    rectEnd,                 // Góc dưới bên phải
ImColor(42, 42, 42, 200), // Màu gốc với alpha = 255 (không trong suốt)
    5.0f                    // Độ bo góc
);
 ImGui::SetCursorPos({107, 31});
ImGui::BeginGroup();

ImGui::TextColored(ImVec4(15.0f / 255, 247.0f / 255, 38.0f / 255, 1.0f), "HACKED FUNCTION");

            ImGui::Checkbox(("HACK MAP"), &HackMap);
			ImGui::SameLine(120);
            ImGui::Checkbox(("SHOW CD"), &showcd);  
			ImGui::SameLine(240);
            ImGui::Checkbox(("X20 CHAT"), &spamchat);           

ImGui::Checkbox(("END GAME"), &BlockHost);
ImGui::SameLine(120);
ImGui::Checkbox(("END EVENT"), &AutoXoaTo);
ImGui::SameLine(240);
				
ImGui::Checkbox("MOD RANK TOP", &unlock2);				
					if(unlock2){
						uint64_t step = 1; 
ImGui::InputScalar("Fake Rank", ImGuiDataType_U64, &fakerank, &step, NULL, "%llu");
ImGui::InputScalar("Fake Sao", ImGuiDataType_U64, &fakesao, &step, NULL, "%llu");
ImGui::InputScalar("Ấn Cao Thủ", ImGuiDataType_U64, &fakean, &step, NULL, "%llu");
ImGui::InputScalar("Top Thách Đấu", ImGuiDataType_U64, &toprank, &step, NULL, "%llu");
ImGui::InputScalar("ID Tướng BXH", ImGuiDataType_U64, &tophero, &step, NULL, "%llu");
					}

ImGui::TextColored(ImVec4(15.0f / 255, 247.0f / 255, 38.0f / 255, 1.0f), "GÓC NHÌN TUYỂN THỦ");
ImGui::SliderInt("VALUE", &CameraHeight, 0, 15);

             
            
            
            
            ImGui::Spacing();
SaveSettingTab();
            ImGui::EndGroup();
 } 
  else if (selectedTab == 1) {
 ImGui::SetCursorPos({102, 26});
ImVec2 menuSize = ImGui::GetContentRegionAvail(); 
ImVec2 windowPos = ImGui::GetCursorScreenPos();

ImVec2 rectSize = ImVec2(menuSize.x + 2, menuSize.y + 2);

ImVec2 rectStart = windowPos;
ImVec2 rectEnd = ImVec2(windowPos.x + rectSize.x, windowPos.y + rectSize.y);

ImDrawList* drawList = ImGui::GetWindowDrawList();
drawList->AddRectFilled(
    rectStart,     
    rectEnd,                
ImColor(42, 42, 42, 200),
    5.0f                    
);
  ImGui::SetCursorPos({107, 31});
    ImGui::BeginGroup();

ImGui::Checkbox(("AUTO AIM (Bật ESP Để Hoạt Động)"), &AimSkill);
ShowSkillCheckboxes();
                DrawAimbotTab();
                ImGui::Spacing();
                SaveSettingTab();
                ImGui::EndGroup();
                }
 else if (selectedTab == 2) {
 ImGui::SetCursorPos({102, 26});
ImVec2 menuSize = ImGui::GetContentRegionAvail(); // Kích thước khả dụng trong cửa sổ
// Lấy vị trí hiện tại của cửa sổ
ImVec2 windowPos = ImGui::GetCursorScreenPos();

// Kích thước của hình chữ nhật
ImVec2 rectSize = ImVec2(menuSize.x + 2, menuSize.y + 2);

// Tọa độ của hình chữ nhật
ImVec2 rectStart = windowPos;
ImVec2 rectEnd = ImVec2(windowPos.x + rectSize.x, windowPos.y + rectSize.y);

// Truy cập ImDrawList để vẽ
ImDrawList* drawList = ImGui::GetWindowDrawList();
drawList->AddRectFilled(
    rectStart,               // Góc trên bên trái
    rectEnd,                 // Góc dưới bên phải
ImColor(42, 42, 42, 200), // Màu gốc với alpha = 255 (không trong suốt)
    5.0f                    // Độ bo góc
);
  ImGui::SetCursorPos({107, 31});
    ImGui::BeginGroup();

                ImGui::Checkbox(("BẬT ESP"), &ESPEnable);
                
       ImGui::SameLine(130);
                ImGui::Checkbox(("BỎ QUA KHI THẤY"), &IgnoreInvisible);

                ImGui::SameLine(260);
ImGui::Checkbox(("ĐƯỜNG KẺ"), &PlayerLine);
                
               //ImGui::Checkbox(("VẼ MÁU"), &PlayerHealth);
                //ImGui::SameLine(130);
//ImGui::Checkbox(("VẼ ICON"), &Drawicon);

//ImGui::SameLine(260);
                
ImGui::Checkbox(("VẼ HỘP"), &PlayerBox);
               
 //ImGui::Checkbox(("VẼ TÊN"), &PlayerName);
ImGui::SameLine(130);
                
ImGui::Checkbox(("VẼ KHOẢNG CÁCH"), &PlayerDistance);
               //ImGui::SameLine(260);
              
               // ImGui::Checkbox("VẼ MINIMAP", &showMinimap);
								
    ImGui::Spacing();
SaveSettingTab();
              ImGui::EndGroup();

            }
else if (selectedTab == 4) {
 ImGui::SetCursorPos({102, 26});
ImVec2 menuSize = ImGui::GetContentRegionAvail(); // Kích thước khả dụng trong cửa sổ
// Lấy vị trí hiện tại của cửa sổ
ImVec2 windowPos = ImGui::GetCursorScreenPos();

// Kích thước của hình chữ nhật
ImVec2 rectSize = ImVec2(menuSize.x + 2, menuSize.y + 2);

// Tọa độ của hình chữ nhật
ImVec2 rectStart = windowPos;
ImVec2 rectEnd = ImVec2(windowPos.x + rectSize.x, windowPos.y + rectSize.y);

// Truy cập ImDrawList để vẽ
ImDrawList* drawList = ImGui::GetWindowDrawList();
drawList->AddRectFilled(
    rectStart,               // Góc trên bên trái
    rectEnd,                 // Góc dưới bên phải
ImColor(42, 42, 42, 200), // Màu gốc với alpha = 255 (không trong suốt)
    5.0f                    // Độ bo góc
);
  ImGui::SetCursorPos({107, 31});
    ImGui::BeginGroup();
DrawHeroSkinInfo();
ShowProfileInfo();
                ImGui::Checkbox(("UNLOCK SKIN"), &unlockskin);
                
                ImGui::SameLine(120);
                ImGui::Checkbox(("MOD BUTTON"), &modnut);
                ImGui::SameLine(240);
								ImGui::Checkbox(("MOD NOTIFY"), &modnotify);
                if(modnut){									
		DrawModNut();
                }
								if(modnotify){
DrawModNotify();
}
    ImGui::Spacing();
 SaveSettingTab();

              ImGui::EndGroup();

            }
						else if (selectedTab == 5) {
 ImGui::SetCursorPos({102, 26});
ImVec2 menuSize = ImGui::GetContentRegionAvail(); // Kích thước khả dụng trong cửa sổ
// Lấy vị trí hiện tại của cửa sổ
ImVec2 windowPos = ImGui::GetCursorScreenPos();

// Kích thước của hình chữ nhật
ImVec2 rectSize = ImVec2(menuSize.x + 2, menuSize.y + 2);

// Tọa độ của hình chữ nhật
ImVec2 rectStart = windowPos;
ImVec2 rectEnd = ImVec2(windowPos.x + rectSize.x, windowPos.y + rectSize.y);

// Truy cập ImDrawList để vẽ
ImDrawList* drawList = ImGui::GetWindowDrawList();
drawList->AddRectFilled(
    rectStart,               // Góc trên bên trái
    rectEnd,                 // Góc dưới bên phải
ImColor(42, 42, 42, 200), // Màu gốc với alpha = 255 (không trong suốt)
    5.0f                    // Độ bo góc
);
  ImGui::SetCursorPos({107, 31});
    ImGui::BeginGroup();

								ImGui::Checkbox(("Auto Trừng Trị"), &autott); 
								if(autott){
								ImGui::SameLine();
								ImGui::Checkbox(("Chỉ Trừng Trị Mục Tiêu"), &onlymt);
							}
							ImGui::Checkbox(("AUTO BỘC PHÁ"), &bocpha);
							if(bocpha){
								ImGui::SliderFloat(("%HP"), &hpbocpha, 0.0f, 100.0f);
							}
							ImGui::Checkbox(("AUTO BĂNG SƯƠNG"), &bangsuong);
							if(bangsuong){
								ImGui::SliderFloat(("%HP "), &hpbs, 0.0f, 100.0f);
							}
							ImGui::Checkbox(("AUTO HỒI MÁU"), &hoimau);
							if(hoimau){
								ImGui::SliderFloat(("%HP  "), &hphm, 0.0f, 100.0f);
							}
							ImGui::Checkbox(("AUTO CẤP CỨU"), &capcuu);
							if(capcuu){
								ImGui::SliderFloat(("%HP   "), &hpcc, 0.0f, 100.0f);
							}
    ImGui::Spacing();
SaveSettingTab();

              ImGui::EndGroup();

            }
                /*
 else if (selectedTab == 3) {
 ImGui::SetCursorPos({102, 26});
ImVec2 menuSize = ImGui::GetContentRegionAvail(); // Kích thước khả dụng trong cửa sổ
// Lấy vị trí hiện tại của cửa sổ
ImVec2 windowPos = ImGui::GetCursorScreenPos();

// Kích thước của hình chữ nhật
ImVec2 rectSize = ImVec2(menuSize.x + 2, menuSize.y + 2);

// Tọa độ của hình chữ nhật
ImVec2 rectStart = windowPos;
ImVec2 rectEnd = ImVec2(windowPos.x + rectSize.x, windowPos.y + rectSize.y);

// Truy cập ImDrawList để vẽ
ImDrawList* drawList = ImGui::GetWindowDrawList();
drawList->AddRectFilled(
    rectStart,               // Góc trên bên trái
    rectEnd,                 // Góc dưới bên phải
ImColor(42, 42, 42, 200), // Màu gốc với alpha = 255 (không trong suốt)
    5.0f                    // Độ bo góc
);
  ImGui::SetCursorPos({107, 31});
    ImGui::BeginGroup();


                ImGui::RadioButton("Team Blue", &minimapType, 1); 
                ImGui::SameLine();
                ImGui::RadioButton("Team Red", &minimapType, 2);
                if (minimapType == 1) {
                minimapRotation = -0.6f;
                } else if (minimapType == 2) {
                minimapRotation = -180.0f;
                }
                ImGui::SliderFloat("Minimap X", &minimapPos.x, 0.0f, kWidth);
                ImGui::SliderFloat("Minimap Y", &minimapPos.y, 0.0f, kHeight);
                ImGui::SliderFloat("Minimap Rotation", &minimapRotation, -180.0f, 180.0f, "%.1f degrees");
                ImGui::SliderFloat("icon Scale", &iconScale, 0.1f, 5.0f);
                ImGui::SliderFloat("Minimap Scale", &minimapScale, 0.1f, 5.0f);
                  ImGui::Spacing();
SaveSettingTab();

                 ImGui::EndGroup();
            }
						*/
                  ImGui::End();
            }
            ImDrawList* draw_list = ImGui::GetBackgroundDrawList();
            DrawESP(draw_list);

            

            ImGui::Render();
            ImDrawData* draw_data = ImGui::GetDrawData();
            ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
          
            [renderEncoder popDebugGroup];
            [renderEncoder endEncoding];

            [commandBuffer presentDrawable:view.currentDrawable];
        }

        [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size
{
    
}



class Camera {
	public:
        static Camera *get_main() {
        Camera *(*get_main_) () = (Camera *(*)()) GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Camera", "get_main", 0);
        
        //Camera *(*get_main_) () = (Camera *(*)()) (IL2Cpp + 0x31b8dd0);
        return get_main_();
    }
    
    Vector3 WorldToScreenPoint(Vector3 position) {
        Vector3 (*WorldToScreenPoint_)(Camera *camera, Vector3 position) = (Vector3 (*)(Camera *, Vector3)) GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Camera", "WorldToScreenPoint", 1);
        
        //Vector3 (*WorldToScreenPoint_)(Camera *camera, Vector3 position) = (Vector3 (*)(Camera *, Vector3)) (il2cppMap + 0x31b84c0);
        return WorldToScreenPoint_(this, position);
    }

    Vector3 WorldToScreen(Vector3 position) {
        Vector3 (*WorldToViewportPoint_)(Camera* camera, Vector3 position, int eye) = (Vector3 (*)(Camera*, Vector3, int)) GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Camera", "WorldToViewportPoint", 2);
        
        return WorldToViewportPoint_(this, position, 2);
        // Vector3 finalResult;
        // finalResult.x = kWidth * result.x;
        // finalResult.y = kHeight - result.y * kHeight;
        // finalResult.z = result.z;
        // return finalResult;
}

};


class ValueLinkerComponent {
    public:
        int get_actorHp() {
            int (*get_actorHp_)(ValueLinkerComponent * objLinkerWrapper) = (int (*)(ValueLinkerComponent *))GetMethodOffset("Project_d.dll", "Kyrios.Actor", "ValueLinkerComponent", "get_actorHp", 0);  
            return get_actorHp_(this);
        }

        int get_actorHpTotal() {
            int (*get_actorHpTotal_)(ValueLinkerComponent * objLinkerWrapper) =
                (int (*)(ValueLinkerComponent *))GetMethodOffset("Project_d.dll", "Kyrios.Actor", "ValueLinkerComponent", "get_actorHpTotal", 0);  
            return get_actorHpTotal_(this);
        }


          int get_maxSpeed() {
            int (*get_maxSpeed)(ValueLinkerComponent * objLinkerWrapper) =
                (int (*)(ValueLinkerComponent *))GetMethodOffset("Project_d.dll", "Kyrios.Actor", "ValueLinkerComponent", "get_maxSpeed", 0);  
            return get_maxSpeed(this);
        }
				int Level() {
            return *(int *) ((uintptr_t) this + GetFieldOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ValueLinkerComponent"), oxorany("<actorSoulLevel>k__BackingField")));
            
            }  // autott (Lấy level của hero)
};






class ValuePropertyComponent {
    public:
       
          int actorMoveSpeed() {
            int (*actorMoveSpeed)(ValuePropertyComponent * objLinkerWrapper) =
                (int (*)(ValuePropertyComponent *))GetMethodOffset("Project_d.dll", "NucleusDrive.Logic", "ValuePropertyComponent", "actorMoveSpeed", 0);  
            return actorMoveSpeed(this);
  
  
        }



          int sactorMoveSpeed() {
            return *(int *) ((uintptr_t) this + 0x48);
        }
};



class CActorInfo {
    public:
        string *ActorName() {
            return *(string **)((uintptr_t)this + 0x18);
        }

        int hudHeight() {
            return *(int *)((uintptr_t)this + 0xB8); 
        }
};

VInt3 LActorRoot_get_location(void *instance) {
    VInt3 (*_LActorRoot_get_location)(void *instance) = (VInt3 (*)(void *))GetMethodOffset(oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"), oxorany("LActorRoot") , oxorany("get_location"), 0);

return _LActorRoot_get_location(instance);
}
VInt3 LActorRoot_get_forward(void *instance) {

VInt3 (*_LActorRoot_get_forward)(void *instance) = (VInt3 (*)(void *))GetMethodOffset(oxorany("Project.Plugins_d.dll"), oxorany("NucleusDrive.Logic"), oxorany("LActorRoot") , oxorany("get_forward"), 0);

    return _LActorRoot_get_forward(instance);
}

class ActorConfig {
public:
    int ConfigID() {
        return *(int *)((uintptr_t)this + 0x1C);
    }
		
};

class HudComponent3D { // autott
    public:
        	
		int Hud() { // Kiểu loại Hud
            return *(int *) ((uintptr_t) this + GetFieldOffset(oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameLogic"), oxorany("HudComponent3D"), oxorany("HudType")));
       }
		
		int Hudh() { // độ cao Hud
            return *(int *) ((uintptr_t) this + GetFieldOffset(oxorany("Project_d.dll"), oxorany("Assets.Scripts.GameLogic"), oxorany("HudComponent3D"), oxorany("hudHeight")));
       }
		
		
   };       

class VActorMovementComponent {
public:
    int get_maxSpeed() {
        int (*get_maxSpeed_)(VActorMovementComponent * component) = (int (*)(VActorMovementComponent *))GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("VActorMovementComponent"), oxorany("get_maxSpeed"), 0);
        return get_maxSpeed_(this);
    }
};

// Khai báo các cấu trúc cần thiết
class MovementState {
public:
    // Giả định GetVelocity trả về VInt3
    VInt3 GetVelocity() {
        // Define the function pointer to get the velocity from MovementState
        VInt3 (*GetVelocity_)(MovementState *movementState) = 
            (VInt3 (*)(MovementState *)) (GetMethodOffset(oxorany("Project_d.dll"),oxorany("NucleusDrive.Logic"),oxorany("MovementState"), oxorany("GetVelocity"), 0));
            return GetVelocity_(this);

    }
};

class ActorLinker {
    public:
        public:
        ValueLinkerComponent *ValueComponent() {        
            return *(ValueLinkerComponent **)((uintptr_t)this + GetFieldOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("ValueComponent")));
        }

        ActorConfig *ObjLinker() {
            return *(ActorConfig **) ((uintptr_t) this + GetFieldOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("ObjLinker")));
        }
        VActorMovementComponent* MovementComponent() {
            return *(VActorMovementComponent**)((uintptr_t)this + GetFieldOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("MovementComponent"))); 
        }
        Vector3 get_position() {
            Vector3 (*get_position_)(ActorLinker *linker) = (Vector3 (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("get_position"), 0));
            return get_position_(this);
        }
        Quaternion get_rotation() {
            Quaternion (*get_rotation_)(ActorLinker *linker) = (Quaternion (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("get_rotation"), 0));
            return get_rotation_(this);
        }
        bool IsHostCamp() {
            bool (*IsHostCamp_)(ActorLinker *linker) = (bool (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("IsHostCamp"), 0));
            return IsHostCamp_(this);
        }
        
        bool IsHostPlayer() {
            bool (*IsHostPlayer_)(ActorLinker *linker) = (bool (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("IsHostPlayer"), 0));
            return IsHostPlayer_(this);
        }
        bool isMoving() {
            return *(bool *) ((uintptr_t) this + GetFieldOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("isMoving")));
        }
Vector3 moveForward() {
            return *(Vector3 *) ((uintptr_t) this + 0x490);
        }
	  int groundSpeed() {
            return *(int *) ((uintptr_t) this + 0x48C);
        }
        Vector3 get_logicMoveForward() {
            Vector3 (*get_logicMoveForward_)(ActorLinker *linker) = (Vector3 (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("get_logicMoveForward"), 0));
            return get_logicMoveForward_(this);
        }
         Vector3 NormalMoveLerp() {
            Vector3 (*NormalMoveLerp)(ActorLinker *linker) = (Vector3 (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("NormalMoveLerp"), 4));
            return NormalMoveLerp(this);
        }
        bool get_bVisible() {
            bool (*get_bVisible_)(ActorLinker *linker) = (bool (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("get_bVisible"), 0));
            return get_bVisible_(this);
        }
        uintptr_t AsHero() {
            uintptr_t (*AsHero_)(ActorLinker *linker) = (uintptr_t (*)(ActorLinker *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("AsHero"), 0));
            return AsHero_(this);
        }
            HudComponent3D *HudControl() {
            return *(HudComponent3D **)((uintptr_t)this + GetFieldOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorLinker"), oxorany("HudControl")));
        } // autott
};



class PlayerMovement {
	public:

  VInt3 get_enemyDirection() {
            VInt3 (*get_enemyDirection)(PlayerMovement *pllayerMovement) = (VInt3 (*)(PlayerMovement *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("NucleusDrive.Logic"), oxorany("PlayerMovement"), oxorany("RealMoveDirection"), 0));
            return get_enemyDirection(this);
        }

};


class ActorManager {
	public:
	
	List<ActorLinker *> *GetAllHeros() {
		List<ActorLinker *> *(*_GetAllHeros)(ActorManager *actorManager) = (List<ActorLinker *> *(*)(ActorManager *)) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany("ActorManager"), oxorany("GetAllHeros"), 0));
		return _GetAllHeros(this);
	}
	  List<ActorLinker *> *GetAllMonsters() {
  List<ActorLinker *> *(*_GetAllMonsters)(ActorManager *actorManager) = (List<ActorLinker *> *(*)(ActorManager *))(GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios.Actor"), oxorany ("ActorManager"), oxorany("GetAllMonsters"), 0));
  return _GetAllMonsters(this); // autott
     } 
};

class KyriosFramework {
	public:
	
	static ActorManager *get_actorManager() {
		auto get_actorManager_ = (ActorManager *(*)()) (GetMethodOffset(oxorany("Project_d.dll"), oxorany("Kyrios"), oxorany("KyriosFramework"), oxorany("get_actorManager"), 0));
		return get_actorManager_();
	}
};

class LActorRoot {
public:


Vector3 _location() {
    VInt3* vint3 = (VInt3*)((uintptr_t)this + 0xC0);
    return Vector3(*vint3); 
}

};



ImDrawList* getDrawList(){
    ImDrawList *drawList;
    drawList = ImGui::GetBackgroundDrawList();
    return drawList;
};
void DrawAimbotTab() {
    static int selectedAimWhen = aimType; // Biến lưu giá trị AimWhen đã chọn
    static int selecteddraw = drawType; 

    const char* aimWhenOptions[] = {"% Máu Thấp Nhất", "Máu Thấp Nhất", "Gần Nhất", "Tắt"};
    ImGui::Combo("Target ", &selectedAimWhen, aimWhenOptions, IM_ARRAYSIZE(aimWhenOptions));

    ImGui::Spacing();

    const char* drawOptions[] = {"Tắt", "Mọi Lúc", "Khi Dùng Chiêu"};
    ImGui::Combo("Draw", &selecteddraw, drawOptions, IM_ARRAYSIZE(drawOptions));

    aimType = selectedAimWhen;
    drawType = selecteddraw;
}

static auto get_OnCameraHeightChanged(void *player) {
    auto (*_get_OnCameraHeightChanged)(void *player) = (void *(*)(void *)) GetMethodOffset(oxorany("Project_d.dll"), oxorany(""), oxorany("CameraSystem"), oxorany("OnCameraHeightChanged"), 0);
    return _get_OnCameraHeightChanged(player);
}

void (*LateUpdate)(void *player);
void _LateUpdate(void *player) {
    if (player != nullptr) {

        get_OnCameraHeightChanged(player);
    }		
    return LateUpdate(player);
}
float (*GetZoomRate)(void *player, int type);
float _GetZoomRate(void *player, int type) {
    if (player != nullptr) {
        if (CameraHeight == 0) {
            return 1.0f;
        } else if (CameraHeight == 1) {
            return 1.2f;
        } else if (CameraHeight == 2) {
            return 1.6f;
        } else if (CameraHeight == 3) {
            return 1.7f;
        } else if (CameraHeight == 4) {
            return 1.8f;
        } else if (CameraHeight == 5) {
            return 1.9f;
        } else if (CameraHeight == 6) {
            return 2.0f;
        } else if (CameraHeight == 7) {
            return 2.1f;
        } else if (CameraHeight == 8) {
            return 2.2f;
        } else if (CameraHeight == 9) {
            return 2.3f;
        } else if (CameraHeight == 10) {
            return 2.4f;
        } else if (CameraHeight == 11) {
            return 2.5f;
        } else if (CameraHeight == 12) {
            return 2.6f;
        } else if (CameraHeight == 13) {
            return 2.7f;
        } else if (CameraHeight == 14) {
            return 2.8f;
        } else if (CameraHeight == 15) {
            return 2.9f;
        }
    }
		
    return GetZoomRate(player, type);
}

struct EntityInfo {
    Vector3 myPos;
	Vector3 enemyPos;
	Vector3 moveForward;
	int ConfigID;
	bool isMoving;
   int currentSpeed;
	      int Hud;
       int Hudh;
       int Level; 
};

EntityInfo EnemyTarget;


#include "Utils/Esp.h"

static ImVec2 minimapPos = ImVec2(45.111f, 32.344f);
static float minimapRotation = -0.7f;
static float iconScale = 1.691f;
static float minimapScale = 1.402f;
std::string namereal;

Vector3 RotateVectorByQuaternion(Quaternion q) {
	Vector3 v(0.0f, 0.0f, 1.0f);
    float w = q.w, x = q.x, y = q.y, z = q.z;

    Vector3 u(x, y, z);
    Vector3 cross1 = Vector3::Cross(u, v);
    Vector3 cross2 = Vector3::Cross(u, cross1);
    Vector3 result = v + 2.0f * cross1 * w + 2.0f * cross2;

    return result;
}

float SquaredDistance(Vector3 v, Vector3 o) {
	return (v.x - o.x) * (v.x - o.x) + (v.y - o.y) * (v.y - o.y) + (v.z - o.z) * (v.z - o.z);
}

Vector3 calculateSkillDirection(Vector3 myPosi, Vector3 enemyPosi, bool isMoving, Vector3 moveForward, int currentSpeed) {
    if (isMoving) {
        float distance = Vector3::Distance(myPosi, enemyPosi);
        float bulletTime = distance / (aimdistance / aimspeed); 

        enemyPosi += Vector3::Normalized(moveForward) * (currentSpeed / 1000.0f) * bulletTime;
    }

    Vector3 direction = enemyPosi - myPosi;
    direction.Normalize();
    return direction;
}

bool AimSkill = false;
bool isCharging;
int mode = 0, aimType = 0, drawType = 2, skillSlot;
	
void (*_Skslot)(void *ins, int del);
void Skslot(void *ins,int del)
  {
      if (ins != NULL ) 
     {
     // Mua flo
      slot = *(int *)((uintptr_t)ins + 0x80); // trỏ hàm tới offset của Skillslot     
     if (slot == 0) {Req0 = ins;} // Skill 0 (thường)
     if (slot == 1) {Req1 = ins;} // Skill 1
     if (slot == 2) {Req2 = ins;} // Skill 2
     if (slot == 3) {Req3 = ins;} // Skill 3
     if (slot == 5) {Req5 = ins;} // Skill 5
     } // Hết code Skillslot Múa Florentino
     
     // Nội Dung (bangsuong - hoimau - cc)
    if (Lactor != NULL) 
    {
      auto Valuec2 = *(uintptr_t *)((uintptr_t)Lactor + 0x30);  // public ValueLinkerComponent ValueComponent; // 0x30
   if (Valuec2 != 0) 
   {
        int Hp = *(int *)((uintptr_t)Valuec2 + 0x40);
        int Hpt = *(int *)((uintptr_t)Valuec2 + 0x44);
        float Per = ((float)Hp / (float)Hpt) * 100.0f;
        if (bangsuong && Per <= hpbs && slot == 9 && hpbs > 1.0f) 
        {
        
          Reqskill(ins); // Use skill Băng Sương
        
        } // hết băng sương
        
        if (hoimau && Per <= hphm && slot == 4 && hphm > 1.0f) 
        {
        
          Reqskill(ins); // Use skill Hồi Máu
        
        } // hết Hồi Máu
    
        if (capcuu && Per <= hpcc && slot == 5 && hpcc > 1.0f) 
        {
        
          Reqskill(ins); // Use skill Cấp Cứu
        
        } // hết Cấp Cứu
    
    
   }
}

float minDistance = std::numeric_limits<float>::infinity();
		float minDirection = std::numeric_limits<float>::infinity();
		float minHealth = std::numeric_limits<float>::infinity();
		float minHealth2 = std::numeric_limits<float>::infinity();

        
        // Lấy quản lý actor
        ActorManager *get_actorManager = KyriosFramework::get_actorManager();
		if (get_actorManager == nullptr) return;


		List<ActorLinker *> *GetAllMonsters = get_actorManager->GetAllMonsters();
		if (GetAllMonsters == nullptr) return;

		ActorLinker **actorLinkersm = (ActorLinker **) GetAllMonsters->getItems();

		if (autott) 		
		{ // Theo dõi trạng thái autott
		


		for (int i = 0; i < GetAllMonsters->getSize(); i++)
		{ // 1 danh sách all monster (quái)
			ActorLinker *actorLinker = actorLinkersm[(i *2) + 1];
			if (actorLinker == nullptr) continue;
	
			if (actorLinker->ValueComponent()->get_actorHp() < 1) continue;
		    
			EnemyTarget.Hud = actorLinker->HudControl()->Hud();
		    EnemyTarget.Hudh = actorLinker->HudControl()->Hudh();	
			
			Vector3 EnemyPos = actorLinker->get_position();
			float Health = actorLinker->ValueComponent()->get_actorHp();
			float MaxHealth = actorLinker->ValueComponent()->get_actorHpTotal();
	     	float Distance = Vector3::Distance(EnemyTarget.myPos, EnemyPos);
		/*
        LIST ID QUÁI VẬT
        EnemyTarget.Hud == 1 (Bùa Xanh, Bùa Đỏ)
        EnemyTarget.Hud == 2 (Quái con và lính)
        EnemyTarget.Hud == 4 (Tà Thần, Rồng)
        */										
		if (  
              // Điều kiện 1: Trừng trị Bùa xanh, Bùa đỏ
            (Distance < 4.0f && Health <= (1350 + (100 * (EnemyTarget.Level - 1))) && 
        EnemyTarget.Hud == 1 && !onlymt && (EnemyTarget.Hudh == 2900 ||  EnemyTarget.Hudh == 3250))
        || 
            // Điều kiện 2: Trừng trị Tà Thần và Rồng
            (Distance < 4.0f && Health <= (1350 + (100 * (EnemyTarget.Level - 1))) && 
        EnemyTarget.Hud == 4 )  
           )		

        {        
            
	        Reqskill(Req5);      
	    }
	} 
		
	} 
	






		
    // GetAllHero ActorManager (bocpha)
    Quaternion rotation;
    float minHealthPercent = std::numeric_limits<float>::infinity();
    ActorLinker *Entity = nullptr;
    if (get_actorManager == nullptr) return;
    List<ActorLinker *> *GetAllHeros = get_actorManager->GetAllHeros();
    if (GetAllHeros == nullptr) return;
    ActorLinker **actorLinkers = (ActorLinker **) GetAllHeros->getItems();    
    for (int i = 0; i < GetAllHeros->getSize(); i++) 
    {
        ActorLinker *actorLinker = actorLinkers[(i * 2) + 1];
        if (actorLinker == nullptr) continue;

        if (actorLinker->IsHostPlayer()) 
        { // xong
            rotation = actorLinker->get_rotation();
            EnemyTarget.myPos = actorLinker->get_position();
            EnemyTarget.ConfigID = actorLinker->ObjLinker()->ConfigID();
	        EnemyTarget.Level = actorLinker->ValueComponent()->Level();
        } // xong
        
        if (actorLinker->IsHostCamp() || !actorLinker->get_bVisible() || actorLinker->ValueComponent()->get_actorHp() < 1) 
        { // xong
            continue;
        } // xong
        Vector3 EnemyPos = actorLinker->get_position();
        float Health = actorLinker->ValueComponent()->get_actorHp();
        float MaxHealth = actorLinker->ValueComponent()->get_actorHpTotal();
        int HealthPercent = (int)std::round((float)Health / MaxHealth * 100);
        float Distance = Vector3::Distance(EnemyTarget.myPos, EnemyPos);
        
            
            


        // Thực hiện Bộc Phá
        // code bocpha
      if (bocpha && HealthPercent < hpbocpha && Distance < 5.0 && slot == 5 && HealthPercent > 1.0f)                             
       {
       
            Reqskill(ins); // Use skill Bộc Phá
	

        } // hết bộc phá
       
	   
} // hết vòng lặp GetAllHero (bocpha)


   return _Skslot(ins,del); 
  
  } // Hết Hàm Hook Skslot;



Vector3 (*_GetUseSkillDirection)(void *instance, bool isTouchUse);
Vector3 GetUseSkillDirection(void *instance, bool isTouchUse) {
    if (instance != NULL && AimSkill && EnemyTarget.ConfigID != 0) {
        if (EnemyTarget.myPos != Vector3::zero() && EnemyTarget.enemyPos != Vector3::zero() && std::find(activeSkills.begin(), activeSkills.end(), skillSlot) != activeSkills.end()) {
            return calculateSkillDirection(
                EnemyTarget.myPos, 
                EnemyTarget.enemyPos, 
                EnemyTarget.isMoving, 
                EnemyTarget.moveForward, 
                EnemyTarget.currentSpeed 
            );
        }
    }
    return _GetUseSkillDirection(instance, isTouchUse);
}




uintptr_t m_isCharging, m_currentSkillSlotType;
bool (*_UpdateLogic)(void *instance, int delta);
bool UpdateLogic(void *instance, int delta){
	if (instance != NULL) {
		isCharging = *(bool *)((uintptr_t)instance + m_isCharging);
		skillSlot = *(int *)((uintptr_t)instance + m_currentSkillSlotType);
	}
	return _UpdateLogic(instance, delta);
}

struct CDInfo {
    float iconPosX;
    float iconPosY;
    std::string heroNameStr;
    uintptr_t Skill1Cd;
    uintptr_t Skill2Cd;
    uintptr_t Skill3Cd;
    uintptr_t Skill4Cd;
};


static bool showNameTimer = true;
static float nameTimer = 0.0f;
const float NAME_DISPLAY_DURATION = 2.0f; // 2 seconds
static float tablePosX = 189.0f; // Vị trí x của bảng
static float tablePosY = 3.5f; // Vị trí y của bảng
static float tableScale = 0.761f; // Scale của bảng
void DrawESP(ImDrawList *draw) {
    if (espManager->enemies->empty() || !ESPEnable) {
        return;
    }


    float cameraScaleFactor = _GetZoomRate(espManager->MyPlayer, 1);
    
    int numberOfEnemies = 0;

    float tableWidth = 125.0f * tableScale; // Độ rộng cố định
    float tableHeight = 30.0f * espManager->enemies->size() * tableScale; // Chiều cao dựa trên số lượng kẻ địch
    // if (showcd)
    // {
    // draw->AddRectFilled(ImVec2(tablePosX, tablePosY), ImVec2(tablePosX + tableWidth, tablePosY + tableHeight), IM_COL32(0, 0, 0, 180), 5.0f * tableScale);
    // }

    std::vector<CDInfo> cdInfoList;

    for (int i = 0; i < espManager->enemies->size(); i++) {
                    void *actorLinker = espManager->MyPlayer;
                    void *Enemy = (*espManager->enemies)[i]->object;
                    void *EnemyLinker = (*ActorLinker_enemy->enemies)[i]->object;

                    Vector3 EnemyPos = Vector3::zero();

                    if (actorLinker && Enemy) {

                        CActorInfo *CharInfo = (CActorInfo *)((uintptr_t)EnemyLinker + 0x120);

                        if (!CharInfo) {
                            continue; // Skip if CharInfo is null
                        }

                        Vector3 myPos = ActorLinker_getPosition(actorLinker);

                        Vector3 myPosSC = Camera::get_main()->WorldToScreen(myPos);
                        ImVec2 myPos_Vec2 = ImVec2(myPosSC.x, myPosSC.y);

                        if (myPosSC.z > 0) {
                            myPos_Vec2 = ImVec2(myPosSC.x* kWidth, kHeight - myPosSC.y* kHeight);
                        } else {
                            myPos_Vec2 = ImVec2(kWidth - myPosSC.x* kWidth,myPosSC.y* kHeight);
                        }

                        VInt3* locationPtr = (VInt3*)((uint64_t)Enemy + 0xC8); // Giả sử location ở offset 0xC0
                        VInt3* forwardPtr = (VInt3*)((uint64_t)Enemy + 0xD4); // Giả sử forward ở offset 0xCC (thay đổi offset nếu cần)

                        EnemyPos = VInt2Vector(*locationPtr,*forwardPtr);

                        void *LObjWrapper = *(void**)((uint64_t)Enemy + 0x2B8);
                        void *ValuePropertyComponent = *(void**)((uint64_t)Enemy + 0x2E0);

                        if (!LObjWrapper || !ValuePropertyComponent) {
                            continue; 
                        }


                        Vector3 rootPos_W2S = Camera::get_main()->WorldToScreen(EnemyPos);
                        Vector2 rootPos_Vec2 = Vector2(rootPos_W2S.x, rootPos_W2S.y);

                        if (rootPos_W2S.z > 0) {
                            rootPos_Vec2 = Vector2(rootPos_W2S.x*kWidth,kHeight -rootPos_W2S.y*kHeight);
                        } else {
                            rootPos_Vec2 = Vector2(kWidth - rootPos_W2S.x*kWidth,rootPos_W2S.y*kHeight);
                        }

                        uintptr_t SkillControl = ((ActorLinker*)EnemyLinker)->AsHero();
                        uintptr_t HudControl = *(int *)((uintptr_t)EnemyLinker + 0x78);
                        
                        if (HudControl < 1 && SkillControl < 1) continue;
                        
                        uintptr_t Skill1Cd = *(int *)(SkillControl + (c1 + 0x1C)) / 1000;
                        uintptr_t Skill2Cd = *(int *)(SkillControl + (c2 + 0x1C)) / 1000;
                        uintptr_t Skill3Cd = *(int *)(SkillControl + (c3 + 0x1C)) / 1000;
                        uintptr_t Skill4Cd = *(int *)(SkillControl + (botro - 0x4)) / 1000;
                        std::string SkillCD = "[" + to_string(Skill4Cd) + "]" + " | " + to_string(Skill1Cd) + " " + "| " + to_string(Skill2Cd) + "  " + "| " + to_string(Skill3Cd) + " |";
                        Vector3 rootSc = Camera::get_main()->WorldToScreen(EnemyPos);
                        ImVec2 rootSc_Vec2 = ImVec2(rootSc.x,rootSc.y);

                        if (rootSc.z > 0) {
                            rootSc_Vec2 = ImVec2(rootSc.x*kWidth,kHeight -rootSc.y*kHeight);
                        } else {
                            rootSc_Vec2 = ImVec2(kWidth - rootSc.x*kWidth,rootSc.y*kHeight);
                        }


                        Vector2 headPos_Vec2 = Vector2(rootPos_Vec2.x, rootPos_Vec2.y - (kHeight / 9)); // Đầu cao hơn
                        Vector2 bottomPos_Vec2 = Vector2(rootPos_Vec2.x, rootPos_Vec2.y + (kHeight / 25)); // Chân thấp hơn
                        float distanceToMe = Vector3::Distance(myPos, EnemyPos);
                        ImVec2 myPos_ImVec2 = ImVec2(myPos_Vec2.x, myPos_Vec2.y);
                        ImVec2 rootPos_ImVec2 = ImVec2(rootPos_Vec2.x, rootPos_Vec2.y);

                        if(IgnoreInvisible){
                            
                            if(ActorLinker_get_bVisible(EnemyLinker)){
                                continue;
                            }
                        }

                    if (!LObjWrapper_get_IsDeadState(LObjWrapper)) {

                        float fixedBoxWidth = 40.0f;
                        float boxHeight = abs(headPos_Vec2.y - bottomPos_Vec2.y);

                        float boxWidth = fixedBoxWidth;

                        float boxCenterOffsetY = -7.0f; 

                        ImVec2 boxTopLeft = ImVec2(rootPos_Vec2.x - (boxWidth / 2), rootPos_Vec2.y - boxCenterOffsetY);
                        ImVec2 boxBottomRight = ImVec2(rootPos_Vec2.x + (boxWidth / 2), headPos_Vec2.y - boxCenterOffsetY);

                        if (PlayerLine) {
                            draw->AddLine(ImVec2(ImGui::GetIO().DisplaySize.x / 2, 38), 
                                        ImVec2(rootPos_Vec2.x, rootPos_Vec2.y - 15.0f), 
                                        IM_COL32(255, 255, 255, 180), 1.2f);
                            
                            draw->AddCircleFilled(ImVec2(rootPos_Vec2.x, rootPos_Vec2.y - 15.0f), 3.0f, IM_COL32(0, 255, 0, 255));
                            
                            numberOfEnemies++;
                            
                            std::string enemyCount = "Enemies [" + std::to_string(numberOfEnemies) + "]";
                            auto textSize = ImGui::CalcTextSize(enemyCount.c_str()); 

                            float paddingX = 5.0f;
                            float paddingY = 3.0f; 

                            ImVec2 topLeft = ImVec2(ImGui::GetIO().DisplaySize.x / 2 - (textSize.x / 2) - paddingX, 
                                                    38 - textSize.y - paddingY);
                            ImVec2 bottomRight = ImVec2(ImGui::GetIO().DisplaySize.x / 2 + (textSize.x / 2) + paddingX, 
                                                        38 + paddingY);
                            draw->AddRectFilled(topLeft, bottomRight, IM_COL32(96, 44, 44, 255));

                            draw->AddRect(topLeft, bottomRight, IM_COL32(255, 99, 99, 255), 1.0f);

                            draw->AddText(NULL, ((float)kHeight / 30.0f), 
                                        {ImGui::GetIO().DisplaySize.x / 2 - (textSize.x / 2), 38 - textSize.y}, 
                                        IM_COL32(255, 99, 99, 255), enemyCount.c_str()); 
                        }
                        

                        if (PlayerBox) {
                           draw->AddRect(boxTopLeft, boxBottomRight, IM_COL32(255, 255, 255, 180), 0, 240, 1.5f);
                             //       Draw3dBox(draw, EnemyPos, Camera::get_main() );

                          //  Draw3dBox(draw, EnemyPos, Camera::get_main(), SCREEN_WIDTH,SCREEN_HEIGHT);
                        }
                        // if (showcd)
                        // {
                        //     CActorInfo *CharInfo = *(CActorInfo **) ((uintptr_t) EnemyLinker + 0x120);
                        //     std::string heroname;
                        //     std::string nameP;
                        //     monoString* actorname = (monoString*)CharInfo->ActorName();
                        //     if (actorname != nullptr) {
                        //         std::string strName = std::string(actorname->toCString());
                        //         nameP = bdvt_encode(strName);
                        //         heroname = nameP;
                        //     }
                        //     int heroID = ((ActorLinker *)EnemyLinker)->ObjLinker()->ConfigID();
                        //     base642name(nameP, heroname, heroID);

                        //     CDInfo cdInfo;
                        //     cdInfo.iconPosX = tablePosX + 10.0f * tableScale;
                        //     cdInfo.iconPosY = tablePosY + (i * 30.0f + 5.0f) * tableScale;
                        //     cdInfo.heroNameStr = namereal;
                        //     cdInfo.Skill1Cd = Skill1Cd;
                        //     cdInfo.Skill2Cd = Skill2Cd;
                        //     cdInfo.Skill3Cd = Skill3Cd;
                        //     cdInfo.Skill4Cd = Skill4Cd;
                        //     cdInfoList.push_back(cdInfo);

                        // }
                                                
                        if (PlayerHealth && isOutsideScreen(ImVec2(rootPos_Vec2.x, rootPos_Vec2.y), ImVec2(kWidth, kHeight))) {
                            ImVec2 hintDotRenderPos = ImVec2(rootPos_Vec2.x, rootPos_Vec2.y);

                            float dx = rootPos_Vec2.x - kWidth / 2;
                            float dy = rootPos_Vec2.y - kHeight / 2;

                            float radius = 20.0f; // Bán kính vòng máu nhỏ hơn

                            if (std::abs(dx) > std::abs(dy)) {
                                float direction = (dx > 0) ? 1.0f : -1.0f;
                                float ratio = std::abs(kWidth / 2 / dx);
                                hintDotRenderPos.x = kWidth / 2 + direction * (kWidth / 2 - radius - 10); // Cách mép màn hình 10px
                                hintDotRenderPos.y = kHeight / 2 + dy * ratio;

                                // Kiểm tra nếu hình tròn vượt qua cạnh màn hình
                                if (hintDotRenderPos.y < radius + 10)
                                    hintDotRenderPos.y = radius + 10;
                                else if (hintDotRenderPos.y > kHeight - radius - 10)
                                    hintDotRenderPos.y = kHeight - radius - 10;

                                // Kiểm tra không đi xuyên qua các cạnh góc màn hình
                                if ((hintDotRenderPos.x < radius + 10 && dx < 0) || (hintDotRenderPos.x > kWidth - radius - 10 && dx > 0))
                                    hintDotRenderPos.x = rootPos_Vec2.x;
                            } else {
                                float direction = (dy > 0) ? 1.0f : -1.0f;
                                float ratio = std::abs(kHeight / 2 / dy);
                                hintDotRenderPos.x = kWidth / 2 + dx * ratio;
                                hintDotRenderPos.y = kHeight / 2 + direction * (kHeight / 2 - radius - 10); // Cách mép màn hình 10px

                                // Kiểm tra nếu hình tròn vượt qua cạnh màn hình
                                if (hintDotRenderPos.x < radius + 10)
                                    hintDotRenderPos.x = radius + 10;
                                else if (hintDotRenderPos.x > kWidth - radius - 10)
                                    hintDotRenderPos.x = kWidth - radius - 10;

                                // Kiểm tra không đi xuyên qua các cạnh góc màn hình
                                if ((hintDotRenderPos.y < radius + 10 && dy < 0) || (hintDotRenderPos.y > kHeight - radius - 10 && dy > 0))
                                    hintDotRenderPos.y = rootPos_Vec2.y;
                            }

                            int EnemyHp = ValuePropertyComponent_get_actorHp(ValuePropertyComponent);
                            int EnemyHpTotal = ValuePropertyComponent_get_actorHpTotal(ValuePropertyComponent);

                            draw->AddCircleFilled(hintDotRenderPos, radius, IM_COL32(0, 0, 0, 60));
                            DrawCircleHealth(hintDotRenderPos, EnemyHp, EnemyHpTotal, radius);

                            // Cập nhật namereal trước khi vẽ icon
                            CActorInfo *CharInfo = *(CActorInfo **) ((uintptr_t) EnemyLinker + 0x120);
                            std::string heroname;
                            std::string nameP;

                            monoString* actorname = (monoString*)CharInfo->ActorName(); 
                            if (actorname != nullptr) {
                                std::string strName = std::string(actorname->toCString());
                                nameP = bdvt_encode(strName);
                                heroname = nameP;
                            }

                            int heroID = ((ActorLinker *)EnemyLinker)->ObjLinker()->ConfigID(); 
                            base642name(nameP, heroname, heroID); // Cập nhật namereal ở đây


                            // Vẽ icon tướng vào giữa vòng máu
                            NSString *heroNameKey = [NSString stringWithCString:namereal.c_str() encoding:NSUTF8StringEncoding];
                            heroNameKey = [heroNameKey lowercaseString];
                            id<MTLTexture> heroTexture = [heroTextures objectForKey:heroNameKey];

                            if (heroTexture) {
                                ImVec2 iconSize = ImVec2(radius * 1.5f, radius * 1.5f); // Điều chỉnh kích thước icon cho phù hợp
                                ImVec2 iconPos = ImVec2(hintDotRenderPos.x - iconSize.x / 2, hintDotRenderPos.y - iconSize.y / 2);
                                draw->AddImage((__bridge ImTextureID) heroTexture, iconPos, ImVec2(iconPos.x + iconSize.x, iconPos.y + iconSize.y)); 
                            }
                        } 

                        if (PlayerHealth && !isOutsideScreen(ImVec2(rootPos_Vec2.x, rootPos_Vec2.y), ImVec2(kWidth, kHeight))) {
                            int EnemyHp = ValuePropertyComponent_get_actorHp(ValuePropertyComponent);
                            int EnemyHpTotal = ValuePropertyComponent_get_actorHpTotal(ValuePropertyComponent);
                            float PercentHP = ((float)EnemyHp / (float)EnemyHpTotal);

                            ImU32 healthColor = IM_COL32(45, 180, 45, 255);
                            if (EnemyHp <= (EnemyHpTotal * 0.6)) {
                                healthColor = IM_COL32(180, 180, 45, 255);
                            }
                            if (EnemyHp < (EnemyHpTotal * 0.3)) {
                                healthColor = IM_COL32(180, 45, 45, 255);
                            }

                            float healthBarHeight = 60.0f; 
                            float healthBarWidth = 5.0f;   

                            float currentHealthHeight = healthBarHeight * PercentHP;

                            ImVec2 healthBarBottomLeft = ImVec2(rootPos_Vec2.x + boxWidth / 2 + healthBarWidth, rootPos_Vec2.y + 15);
                            ImVec2 healthBarTopRight = ImVec2(healthBarBottomLeft.x + healthBarWidth, healthBarBottomLeft.y - currentHealthHeight); 

                            draw->AddRectFilled(healthBarTopRight, healthBarBottomLeft, healthColor);

                            ImVec2 healthBarRectTopLeft = ImVec2(healthBarBottomLeft.x, healthBarBottomLeft.y - healthBarHeight);
                            ImVec2 healthBarRectBottomRight = ImVec2(healthBarRectTopLeft.x + healthBarWidth, healthBarBottomLeft.y); 

                            draw->AddRect(healthBarRectTopLeft, healthBarRectBottomRight, IM_COL32(0, 0, 0, 255), 0, 240, 0.4f);

                        }

                        if (PlayerDistance) {
                            std::string strDistance = "[ " + std::to_string((int)distanceToMe) + " M ]";

                                auto textSize = ImGui::CalcTextSize(strDistance.c_str(), 0, ((float)kHeight / 39.0f));
                                draw->AddText(NULL, ((float)kHeight / 39.0f), { headPos_Vec2.x - (textSize.x / 4), headPos_Vec2.y + 56 }, IM_COL32(255, 255, 100, 255), strDistance.c_str());
                        }

                        
                        

                        if (PlayerName) {
                            CActorInfo *CharInfo = *(CActorInfo **) ((uintptr_t) EnemyLinker + 0x120);
                            std::string heroname;
                            std::string nameP;


                            monoString* actorname = (monoString*)CharInfo->ActorName(); 
                            if (actorname != nullptr) {
                                std::string strName = std::string(actorname->toCString());
                                nameP = bdvt_encode(strName);
                                heroname = nameP;
                            }


                            int heroID = ((ActorLinker *)EnemyLinker)->ObjLinker()->ConfigID(); 


                            base642name(nameP, heroname, heroID);

                            if (Drawicon) {
                                NSString *heroNameKey = [NSString stringWithCString:namereal.c_str() encoding:NSUTF8StringEncoding];
                                heroNameKey = [heroNameKey lowercaseString];
                                id<MTLTexture> heroTexture = [heroTextures objectForKey:heroNameKey];

                                if (heroTexture) {
                                    ImVec2 iconSize = ImVec2(38, 38); 
                                    ImVec2 iconPos = ImVec2(rootPos_Vec2.x - iconSize.x / 2, rootPos_Vec2.y - 15.0f - iconSize.y / 2);
                                    draw->AddImage((__bridge ImTextureID) heroTexture, iconPos, ImVec2(iconPos.x + iconSize.x, iconPos.y + iconSize.y)); 
                                }
                            }


                            if (showMinimap) {
                                ImVec2 minimapSize = ImVec2(97.656f * minimapScale, 96.094f * minimapScale);  // Giảm độ phân giải minimap xuống 50x50 và scale theo minimapScale
                                ImVec2 minimapCenter = ImVec2(minimapPos.x + minimapSize.x / 2.0f, minimapPos.y + minimapSize.y / 2.0f);
                                float worldSize = 150.0f; 
                                float minimapWidth = minimapSize.x;
                                float minimapHeight = minimapSize.y;
                                float scaleX = (minimapWidth / worldSize) * minimapScale;
                                float scaleY = (minimapHeight / worldSize) * minimapScale;

                                float angleRad = minimapRotation * (M_PI / 180.0f);
                                float cosTheta = cos(angleRad);
                                float sinTheta = sin(angleRad);

                                // Vẽ outline minimap
                                draw->AddRect(minimapPos, ImVec2(minimapPos.x + minimapSize.x, minimapPos.y + minimapSize.y), IM_COL32(255, 255, 255, 255), 0.0f, 0, 1.0f);

                                // Vẽ vị trí tướng trên minimap
                                Vector3 EnemyPos = VInt2Vector(*locationPtr,*forwardPtr);

                                ImVec2 worldPoint = ImVec2(EnemyPos.x, EnemyPos.z);
                                ImVec2 minimapPoint;

                                minimapPoint.x = minimapCenter.x + (worldPoint.x * scaleX);
                                minimapPoint.y = minimapCenter.y - (worldPoint.y * scaleY);

                                ImVec2 relativePoint = ImVec2(minimapPoint.x - minimapCenter.x, minimapPoint.y - minimapCenter.y);
                                ImVec2 rotatedPoint;
                                rotatedPoint.x = relativePoint.x * cosTheta - relativePoint.y * sinTheta + minimapCenter.x;
                                rotatedPoint.y = relativePoint.x * sinTheta + relativePoint.y * cosTheta + minimapCenter.y;

                                // Vẽ icon tướng thay cho chấm đỏ
                                NSString *heroNameKey = [NSString stringWithCString:namereal.c_str() encoding:NSUTF8StringEncoding];
                                heroNameKey = [heroNameKey lowercaseString];
                                id<MTLTexture> heroTexture = [heroTextures objectForKey:heroNameKey];

                                if (heroTexture) {
                                    float iconSize = 8.0f * iconScale;
                                    draw->AddImage((__bridge ImTextureID)heroTexture,
                                                    ImVec2(rotatedPoint.x - iconSize / 2.0f, rotatedPoint.y - iconSize / 2.0f),
                                                    ImVec2(rotatedPoint.x + iconSize / 2.0f, rotatedPoint.y + iconSize / 2.0f));

                                    // Vẽ viền tròn bao quanh icon (tương tự code1)
                                    draw->AddCircle(rotatedPoint, iconSize / 2.0f + 1.0f, IM_COL32(255, 255, 255, 255), 12, 1.0f);

                                    // Vẽ vòng máu mỏng với cùng độ dày (1.0f)
                                    int EnemyHp = ValuePropertyComponent_get_actorHp(ValuePropertyComponent);
                                    int EnemyHpTotal = ValuePropertyComponent_get_actorHpTotal(ValuePropertyComponent);
                                    DrawCircleHealth2(rotatedPoint, EnemyHp, EnemyHpTotal, iconSize / 2.0f + 1.0f); 
                                }

                            }


                            if (LObjWrapper_IsAutoAI(LObjWrapper)) {
                                heroname = std::string("AI | " + heroname);
                            }


                            auto textSize = ImGui::CalcTextSize(heroname.c_str(), 0, ((float) kHeight / 39.0f));
                            draw->AddText(ImGui::GetFont(), ((float) kHeight / 39.0f), {rootPos_Vec2.x - (textSize.x / 4), rootPos_Vec2.y + 23}, IM_COL32(255, 255, 255, 255), heroname.c_str());
                            
                        
                            
                        }

                                            
                    
                    
                }
            }
}

if (AimSkill)
    {
        Quaternion rotation;
        float minDistance = std::numeric_limits<float>::infinity();
        float minDirection = std::numeric_limits<float>::infinity();
        float minHealth = std::numeric_limits<float>::infinity();
        float minHealth2 = std::numeric_limits<float>::infinity();
        float minHealthPercent = std::numeric_limits<float>::infinity();
        ActorLinker *Entity = nullptr;
        
        ActorManager *get_actorManager = KyriosFramework::get_actorManager();
        if (get_actorManager == nullptr) return;

        List<ActorLinker *> *GetAllHeros = get_actorManager->GetAllHeros();
        if (GetAllHeros == nullptr) return;

        ActorLinker **actorLinkers = (ActorLinker **) GetAllHeros->getItems();

        for (int i = 0; i < GetAllHeros->getSize(); i++)
        {
            ActorLinker *actorLinker = actorLinkers[(i *2) + 1];
            if (actorLinker == nullptr) continue;
        
            if (actorLinker->IsHostPlayer()) {
                rotation = actorLinker->get_rotation();
                EnemyTarget.myPos = actorLinker->get_position();
                EnemyTarget.ConfigID = actorLinker->ObjLinker()->ConfigID();
            }
        
            if (actorLinker->IsHostCamp() || !actorLinker->get_bVisible() || actorLinker->ValueComponent()->get_actorHp() < 1) continue;
        
            Vector3 EnemyPos = actorLinker->get_position();
            float Health = actorLinker->ValueComponent()->get_actorHp();
            float MaxHealth = actorLinker->ValueComponent()->get_actorHpTotal();
            int HealthPercent = (int)std::round((float)Health / MaxHealth * 100);
            float Distance = Vector3::Distance(EnemyTarget.myPos, EnemyPos);
            float Direction = SquaredDistance(
                RotateVectorByQuaternion(rotation), 
                calculateSkillDirection(
                    EnemyTarget.myPos, 
                    EnemyPos, 
                    actorLinker->isMoving(), 
                    actorLinker->get_logicMoveForward(),
                    actorLinker->MovementComponent()->get_maxSpeed() 
                )
            );          
            if (Distance < aimdistance)
            {
                if (aimType == 0)
                {
                    if (HealthPercent < minHealthPercent)
                    {
                        Entity = actorLinker;
                        minHealthPercent = HealthPercent;
                    }
                
                    if (HealthPercent == minHealthPercent && Health < minHealth2)
                    {
                        Entity = actorLinker;
                        minHealth2 = Health;
                        minHealthPercent = HealthPercent;
                    }
                }
            
                if (aimType == 1 && Health < minHealth)
                {
                    Entity = actorLinker;
                    minHealth = Health;
                }
                
                if (aimType == 2 && Distance < minDistance)
                {
                    Entity = actorLinker;
                    minDistance = Distance;
                }
            
                if (aimType == 3 && Direction < minDirection)
                {
                    Entity = actorLinker;
                    minDirection = Direction;
                }
            }
        }
        if (Entity == nullptr) {
            EnemyTarget.enemyPos = Vector3::zero();
            EnemyTarget.moveForward = Vector3::zero();
            EnemyTarget.ConfigID = 0;
            EnemyTarget.isMoving = false;
        }
        if (Entity != NULL)
        {
            float nDistance = Vector3::Distance(EnemyTarget.myPos, Entity->get_position());
            if (nDistance > aimdistance || Entity->ValueComponent()->get_actorHp() < 1)
            {
                EnemyTarget.enemyPos = Vector3::zero();
                EnemyTarget.moveForward = Vector3::zero();
                minDistance = std::numeric_limits<float>::infinity();
                minDirection = std::numeric_limits<float>::infinity();
                minHealth = std::numeric_limits<float>::infinity();
                minHealth2 = std::numeric_limits<float>::infinity();
                minHealthPercent = std::numeric_limits<float>::infinity();
                Entity = nullptr;
            }
                    
            else
            {
                EnemyTarget.enemyPos =  Entity->get_position();
                EnemyTarget.moveForward = Entity->get_logicMoveForward();
                EnemyTarget.isMoving = Entity->isMoving();
                EnemyTarget.currentSpeed = Entity->MovementComponent()->get_maxSpeed();
            }
        }
        
        if (Entity != NULL && aimType == 3 && !isCharging)
        {
            EnemyTarget.enemyPos = Vector3::zero();
            EnemyTarget.moveForward = Vector3::zero();
            minDirection = std::numeric_limits<float>::infinity();
            Entity = nullptr;
        }
        
        if ((Entity != NULL || EnemyTarget.enemyPos != Vector3::zero()) && get_actorManager == nullptr)
        {
            EnemyTarget.enemyPos = Vector3::zero();
            EnemyTarget.moveForward = Vector3::zero();
            minDistance = std::numeric_limits<float>::infinity();
            minDirection = std::numeric_limits<float>::infinity();
            minHealth = std::numeric_limits<float>::infinity();
            minHealth2 = std::numeric_limits<float>::infinity();
            minHealthPercent = std::numeric_limits<float>::infinity();
            Entity = nullptr;
        }
        if(EnemyTarget.ConfigID == 196){
					//Elsu
					activeSkills.clear();
          activeSkills.push_back(2);
					aimdistance = 25.0f;
					aimspeed = 0.45f;
        }
				if(EnemyTarget.ConfigID == 545){
					//Yue
					activeSkills.clear();
					activeSkills.push_back(1);
          activeSkills.push_back(2);
					aimdistance = 12.0f;
					aimspeed = 0.8f;
        }
				if(EnemyTarget.ConfigID == 175){
					//Grakk
					activeSkills.clear();
          activeSkills.push_back(2);
					aimdistance = 12.0f;
					aimspeed = 0.8f;
        }
				if(EnemyTarget.ConfigID == 157){
					//Raz
					activeSkills.clear();
          activeSkills.push_back(2);
					aimdistance = 12.0f;
					aimspeed = 0.8f;
        }
				if(EnemyTarget.ConfigID == 195){
					//Enzo
					activeSkills.clear();
          activeSkills.push_back(2);
					aimdistance = 9.5f;
					aimspeed = 0.4f;
        }
				if(EnemyTarget.ConfigID == 142){
					//Natalya
					activeSkills.clear();
          activeSkills.push_back(2);
					aimdistance = 10.0f;
					aimspeed = 1.0f;
        }
				if(EnemyTarget.ConfigID == 521){
					//Florentino
					activeSkills.clear();
          activeSkills.push_back(1);
					aimdistance = 7.5f;
					aimspeed = 0.35f;
        }
				if(EnemyTarget.ConfigID == 163){
					//Ryoma
					activeSkills.clear();
          activeSkills.push_back(2);
					aimdistance = 7.0f;
					aimspeed = 0.1f;
        }
				if(EnemyTarget.ConfigID == 169){
					//Slimz
					activeSkills.clear();
          activeSkills.push_back(1);
					aimdistance = 19.5f;
					aimspeed = 1.7f;
        }
        if (drawType != 0 && EnemyTarget.ConfigID != 0) {
                if (EnemyTarget.myPos != Vector3::zero() && EnemyTarget.enemyPos != Vector3::zero()) {
                    Vector3 futureEnemyPos = EnemyTarget.enemyPos;
                    if (EnemyTarget.isMoving) {
                        float distance = Vector3::Distance(EnemyTarget.myPos, EnemyTarget.enemyPos);
                        float bulletTime = distance / (aimdistance / aimspeed); 
                        futureEnemyPos += Vector3::Normalized(EnemyTarget.moveForward) * (EnemyTarget.currentSpeed / 1000.0f) * bulletTime;
                    }
                    Vector3 EnemySC = Camera::get_main()->WorldToScreen(futureEnemyPos);

                    Vector2 RootVec2 = Vector2(EnemySC.x, EnemySC.y);

                    if (EnemySC.z > 0) {
                        RootVec2 = Vector2(EnemySC.x*kWidth,kHeight -EnemySC.y*kHeight);
                        ImVec2 imRootVec2 = ImVec2(RootVec2.x, RootVec2.y);
                        ImVec2 startLine = ImVec2(kWidth / 2, kHeight / 2);

                        if (drawType == 1) {
                            draw->AddLine(startLine, imRootVec2, ImColor(0, 255, 0, 255), 1.0f); //xanh
                        }
                        if (drawType == 2 && std::find(activeSkills.begin(), activeSkills.end(), skillSlot) != activeSkills.end()) {
                            draw->AddLine(startLine, imRootVec2, ImColor(0, 255, 0, 255), 0.8f); //xanh
                        }
                    } else {
                        RootVec2 = Vector2(kWidth - EnemySC.x*kWidth,EnemySC.y*kHeight);
                        ImVec2 imRootVec2 = ImVec2(RootVec2.x, RootVec2.y);
                        ImVec2 startLine = ImVec2(kWidth / 2, kHeight / 2);

                        if (drawType == 1) {
                                draw->AddLine(startLine, imRootVec2, ImColor(0, 255, 0, 255), 1.0f); //xanh
                        }
                        if (drawType == 2 && std::find(activeSkills.begin(), activeSkills.end(), skillSlot) != activeSkills.end()) {
                                draw->AddLine(startLine, imRootVec2, ImColor(0, 255, 0, 255), 0.8f); //xanh

                            
                        }
                    }
                }
            }
        }
    }




void base642name(std::string nameP, std::string &heroname, int heroID){	
    
	if(nameP == ""){
		heroname = "Ata";
        namereal = "Ata";
		return;
	}
	if(nameP == "MTU3X0J1WmhpSHVvV3U=") {	
		heroname = "Raz";	
        namereal = "Raz";
		return;	
	}	
	if(nameP == "NTAzX1p1a2E=") {	
		heroname = "Zuka";	
        namereal = "Zuka";
		return;	
	}	
	if(nameP == "5p2O55m9") {	
		heroname = "Murad";	
        namereal = "Murad";
		return;	
	}	
	if(nameP == "6I2G6L2y") {	
		heroname = "Butterfly";	
        namereal = "Butterfly";
		return;	
	}	
	if(nameP == "5pu55pON") {	
		heroname = "Lữ Bố";	
        namereal = "lubo";
		return;	
	}	
	if(nameP == "MTEyX0dvbmdTaHVCYW4=") {	
		heroname = "Yorn";	
        namereal = "Yorn";
		return;	
	}	
	if(nameP == "NTIxX0Zsb3JlbnRpbm8=") {	
		heroname = "Florentino";
        namereal = "Florentino";	
		return;	
	}	
	if(nameP == "5qKF5p6X") {	
		heroname = "Natalya";	
        namereal = "Natalya";
		return;	
	}	
    if(nameP == "5Lqa55Gf546L" && heroID == 808) {	
		heroname = "Rối Athur";	
        namereal = "Athur";
		return;	
	}
	if(nameP == "5Lqa55Gf546L") {	
		heroname = "Athur";	
        namereal = "Athur";
		return;	
	}	
	if(nameP == "54uE5LuB5p2w") {	
		heroname = "Valhein";	
        namereal = "Valhein";
		return;	
	}	
	if(nameP == "6Z+p5L+h") {	
		heroname = "Nakroth";	
        namereal = "Nakroth";
		return;	
	}	
	if(nameP == "IOWFuOmfpg==") {	
		heroname = "Triệu vân";	
        namereal = "trieuvan";
		return;	
	}	
	if(nameP == "5aKo57+f") {	
		heroname = "Gildur";	
        namereal = "Gildur";
		return;	
	}	
	if(nameP == "6I6J6I6J5a6J") {	
		heroname = "Liliana";	
        namereal = "Liliana";
		return;	
	}	
	if(nameP == "6K+46JGb5Lqu") {	
		heroname = "Tulen";	
        namereal = "Tulen";
		return;	
	}	
	if(nameP == "5a2U5aSr5a2Q" && heroID == 139) {	
		heroname = "Kil'Groth";	
        namereal = "KilGroth";
		return;	
	}	
	if(nameP == "MTY3X1d1S29uZw==") {	
		heroname = "Ngộ Không";	
        namereal = "ngokhong";
		return;	
	}	
	if(nameP == "6ZKf6aaX") {	
		heroname = "Grakk";	
        namereal = "Grakk";
		return;	
	}	
	if(nameP == "5ZSQ5LiJ6JeP") {	
		heroname = "Skud";	
        namereal = "Skud";
		return;	
	}	
	if(nameP == "5Z+D572X") {	
		heroname = "Errol";	
        namereal = "Errol";
		return;	
	}	
	if(nameP == "NTI0X0NhcGhlbnk=") {	
		heroname = "Capheny";	
        namereal = "Capheny";
		return;	
	}	
	if(nameP == "5Yi5") {	
		heroname = "Zata";	
        namereal = "Zata";
		return;	
	}	
	if(nameP == "5a2U5aSr5a2Q") {	
		heroname = "Omen";	
        namereal = "Omen";
		return;	
	}	
	if(nameP == "5a2Z5bCa6aaZ") {	
		heroname = "Violet";
        namereal = "Violet";	
		return;	
	}	
	if(nameP == "5omB6bmK") {	
		heroname = "Mganga";	
        namereal = "Mganga";
		return;	
	}	
	if(nameP == "VmVyZXM=") {	
		heroname = "Veres";	
        namereal = "Veres";
		return;	
	}	
    if(nameP == "54m55bCU5a6J5aic5pav" && heroID == 809) {	
		heroname = "Rối Tel'Annas";	
        namereal = "TelAnnas";
		return;	
	}	
	if(nameP == "54m55bCU5a6J5aic5pav") {	
		heroname = "Tel'Annas";	
        namereal = "TelAnnas";
		return;	
	}	
	if(nameP == "TmFrb3J1cnU=") {	
		heroname = "Kriknak";	
        namereal = "Kriknak";
		return;	
	}	
	if(nameP == "55m+6YeM5a6I57qm") {	
		heroname = "Elsu";	
        namereal = "Elsu";
		return;	
	}	
	if(nameP == "MTE3X1pob25nV3VZYW4=") {	
		heroname = "Ormarr";	
        namereal = "Ormarr";
		return;	
	}	
	if(nameP == "6Jme5aes") {	
		heroname = "Stuart";	
        namereal = "Stuart";
		return;	
	}	
	if(nameP == "6LW15LqR") {	
		heroname = "Zephys";	
        namereal = "Zephys";
		return;	
	}	
	if(nameP == "5Lqa6L+e") {	
		heroname = "Allain";	
        namereal = "Allain";
		return;	
	}	
	if(nameP == "5a6r5pys5q2m6JeP") {	
		heroname = "Airi";	
        namereal = "Airi";
		return;	
	}	
	if(nameP == "6ams5Y+v5rOi572X") {	
		heroname = "Hayate";	
        namereal = "Hayate";
		return;	
	}	
	if(nameP == "MTA5X0Rhamk=") {	
		heroname = "Veera";	
        namereal = "Veera";
		return;	
	}	
	if(nameP == "5bCP5LmU") {	
		heroname = "Krixi";	
        namereal = "Krixi";
		return;	
	}	
	if(nameP == "5aWO5Lym") {	
		heroname = "Quillen";	
        namereal = "quillen";
		return;	
	}	
	if(nameP == "5YiY5aSH" && heroID == 512) {	
		heroname = "Rourke";	
        namereal = "Rourke";
		return;	
	}	
	if(nameP == "56iL5ZKs6YeR") {	
		heroname = "Tarra";	
        namereal = "tarra";
		return;	
	}	
	if(nameP == "57qi5ouC") {	
		heroname = "Zill";	
        namereal = "Zill";
		return;	
	}	
	if(nameP == "5Y+46ams5oe/") {	
		heroname = "Paine";	
        namereal = "Paine";
		return;	
	}	
	if(nameP == "5buJ6aKH") {	
		heroname = "Toro";	
        namereal = "Toro";
		return;	
	}	
	if(nameP == "5ZOq5ZCS") {	
		heroname = "Max";	
        namereal = "Max";
		return;	
	}	
	if(nameP == "NTMzX0hvdVlp") {	
		heroname = "Laville";	
        namereal = "Laville";
		return;	
	}	
	if(nameP == "NTMwX0RpcmFr") {	
		heroname = "Dirak";	
        namereal = "Dirak";
		return;	
	}	
	if(nameP == "NTA3X0ZsYXNo") {	
		heroname = "The Flash";	
        namereal = "TheFlash";
		return;	
	}	
	if(nameP == "SnVZb3VKaW5n") {	
		heroname = "Ryoma";	
        namereal = "Ryoma";
		return;	
	}	
	if(nameP == "5p2O5YWD6Iqz") {	
		heroname = "Fennik";	
        namereal = "Fennik";
		return;	
	}	
	if(nameP == "54K45by55Lq6") {	
		heroname = "Wisp";	
        namereal = "Wisp";
		return;	
	}	
	if(nameP == "5ay05pS/") {	
		heroname = "Kahlii";	
        namereal = "Kahlii";
		return;	
	}	
	if(nameP == "5Lic55qH5aSq5LiA") {	
		heroname = "Arum";	
        namereal = "Arum";
		return;	
	}	
	if(nameP == "U3VuQ2U=") {	
		heroname = "Bijan";	
        namereal = "Bijan";
		return;	
	}	
	if(nameP == "R2VuaXVz") {	
		heroname = "Thorne";	
        namereal = "Thorne";
		return;	
	}	
	if(nameP == "55m+6YeM546E562W") {	
		heroname = "Enzo";	
        namereal = "Enzo";
		return;	
	}	
	if(nameP == "5byg6Imv") {	
		heroname = "Aleister";	
        namereal = "Aleister";
		return;	
	}	
	if(nameP == "MTQxX0RpYW9DaGFu") {	
		heroname = "Lauriel";	
        namereal = "Lauriel";
		return;	
	}	
	if(nameP == "MTUyX1dhbmdaaGFvSnVu") {	
		heroname = "Điêu Thuyền";	
        namereal = "dieuthuyen";
		return;	
	}	
	if(nameP == "5YiY5aSH") {	
		heroname = "Moren";	
        namereal = "Moren";
		return;	
	}	
	if(nameP == "MTU0X0h1YU11TGFu") {	
		heroname = "Yenna";	
        namereal = "Yenna";
		return;	
	}	
	if(nameP == "MTk5X0xp") {	
		heroname = "Eland'orr";	
        namereal = "Elandorr";
		return;	
	}	
	if(nameP == "TmluamE=") {	
		heroname = "Aoi";	
        namereal = "Aoi";
		return;	
	}	
	if(nameP == "57uu6JCd") {	
		heroname = "Keera";	
        namereal = "Keera";
		return;	
	}	
	if(nameP == "5ZCV5biD") {	
		heroname = "Maloch";	
        namereal = "Maloch";
		return;	
	}	
	if(nameP == "56We5aWH5aWz5L6g") {	
		heroname = "Wonder Woman";	
        namereal = "WonderWoman";
		return;	
	}	
	if(nameP == "5ZCO576/") {	
		heroname = "Slimz";	
        namereal = "Slimz";
		return;	
	}	
	if(nameP == "MTE4X1N1bkJpbg==") {	
		heroname = "Alice";	
        namereal = "Alice";
		return;	
	}	
	if(nameP == "5pyX5Y2a") {	
		heroname = "Lumburr";	
        namereal = "Lumburr";
		return;	
	}	
	if(nameP == "MTIwX0JhaVFp") {	
		heroname = "Mina";	
        namereal = "Mina";
		return;	
	}	
	if(nameP == "QWlt") {	
		heroname = "Yue";	
        namereal = "Yue";
		return;	
	}	
	if(nameP == "6Iul5LyK") {	
		heroname = "Rouie";	
        namereal = "Rouie";
		return;	
	}	
	if(nameP == "NTQwMV9CcmlnaHQ=") {	
		heroname = "Bright";	
        namereal = "Bright";
		return;	
	}	
	if(nameP == "MTc3X0NoZW5nSmlTaUhhbg==") {	
		heroname = "Lindis";	
        namereal = "Lindis";
		return;	
	}	
	if(nameP == "6auY5riQ56a7") {	
		heroname = "Jinna";	
        namereal = "Jinna";
		return;	
	}	
	if(nameP == "6buE5b+g") {	
		heroname = "Celica";	
        namereal = "Celica";
		return;	
	}	
	if(nameP == "5qyn57Gz6IyE") {	
		heroname = "Omega";	
        namereal = "Omega";
		return;	
	}	
	if(nameP == "R2VuaXVz") {	
		heroname = "Bonnie";	
        namereal = "Bonnie";
		return;	
	}	
	if(nameP == "5YiY6YKm") {	
		heroname = "Xenniel";	
        namereal = "Xenniel";
		return;	
	}	
	if(nameP == "6JSh5paH5aes") {	
		heroname = "Helen";	
        namereal = "Helen";
		return;	
	}	
	if(nameP == "5aSP5L6v5oOH") {	
		heroname = "Arduin";	
        namereal = "Arduin";
		return;	
	}	
	if(nameP == "55SE5aes") {	
		heroname = "Azzen'ka";	
        namereal = "Azzenka";
		return;	
	}	
	if(nameP == "55qu55qu") {	
		heroname = "Zip";	
        namereal = "Zip";
		return;	
	}	
	if(nameP == "562x5riF") {	
		heroname = "Qi";	
        namereal = "Qi";
		return;	
	}	
	if(nameP == "5a6J5qC85YiX") {	
		heroname = "Volkath";	
        namereal = "Volkath";
		return;	
	}	
	if(nameP == "MTQwX0d1YW5ZdQ==") {	
		heroname = "Supper Man";	
        namereal = "supperman";
		return;	
	}	
	if(nameP == "MTQ4X0ppYW5nWmlZYQ==") {	
		heroname = "Preyta";	
        namereal = "Preyta";
		return;	
	}	
	if(nameP == "MTUzX0xhbkxpbmdXYW5n") {	
		heroname = "Kaine";	
        namereal = "Kaine";
		return;	
	}	
	if(nameP == "5ouJ5paQ5bCU") {	
		heroname = "Amily";	
        namereal = "Amily";
		return;	
	}	
	if(nameP == "MTIxX01pWXVl") {	
		heroname = "Marja";	
        namereal = "Marja";
		return;	
	}	
	if(nameP == "5q2m5YiZ5aSp") {	
		heroname = "Ilumia";	
        namereal = "Ilumia";
		return;	
	}	
	if(nameP == "6aG55769") {	
		heroname = "Thane";	
        namereal = "Thane";
		return;	
	}	
	if(nameP == "5aSq5LmZ55yf5Lq6") {	
		heroname = "Teemee";	
        namereal = "Teemee";
		return;	
	}	
	if(nameP == "6Zi/5pav5bSU5b63") {	
		heroname = "Astrid";	
        namereal = "Astrid";
		return;	
	}	
	if(nameP == "NTE1X1JpY2h0ZXI=") {	
		heroname = "Richter";	
        namereal = "Ata";
		return;	
	}	
	if(nameP == "5byg6aOe") {	
		heroname = "Cresh";	
        namereal = "Cresh";
		return;	
	}	
	if(nameP == "5ZGo55Gc") {	
		heroname = "Ignis";	
        namereal = "Ignis";
		return;	
	}	
	if(nameP == "MTEzX1podWFuZ1pob3U=") {	
		heroname = "Chaugnar";	
        namereal = "Chaugnar";
		return;	
	}	
	if(nameP == "6IuP54OI") {	
		heroname = "Wiro";	
        namereal = "Wiro";
		return;	
	}	
	if(nameP == "MTg5X0d1aUd1Wmk=") {	
		heroname = "Krizzix";	
        namereal = "Krizzix";
		return;	
	}	
	if(nameP == "NTA1X0JhbGR1bQ==") {	
		heroname = "Baldum";	
        namereal = "Baldum";
		return;	
	}	
	if(nameP == "5Y+k5pyo") {	
		heroname = "Y'bneth";	
        namereal = "ybneth";
		return;	
	}	
	if(nameP == "Um94aQ==") {	
		heroname = "Roxie";	
        namereal = "Roxie";
		return;	
	}	
	if(nameP == "5a6J5aWI54m5") {	
		heroname = "Annette";	
        namereal = "Annette";
		return;	
	}	
	if(nameP == "NTIzX0RBUkNZ") {	
		heroname = "D'Arcy";	
        namereal = "darcy";
		return;	
	}	
	if(nameP == "SXNoYXI=") {	
		heroname = "Ishar";	
        namereal = "Ishar";
		return;	
	}	
	if(nameP == "5r6c") {	
		heroname = "Sephera";	
        namereal = "Sephera";
		return;	
	}	
	if(nameP == "5aSc5aes") {	
		heroname = "Dextra";	
        namereal = "Dextra";
		return;	
	}	


    if(nameP == "5py16I6J5Lqa") {	
		heroname = "Dolia";	
        namereal = "Dolia";
		return;	
	}	

    if(nameP == "5aSP5rSb54m5") {	
		heroname = "Charlotte";	
        namereal = "Charlotter";
		return;	
	}	

    if(nameP == "6Im+55Cz") {	
		heroname = "Erin";	
        namereal = "Erin";
		return;	
	}	

	if(nameP == "6IuP56a7") {	
		heroname = "Sinestrea";	
        namereal = "Sinestrea";
		return;	
	}	
	if(nameP == "SWdneQ==") {	
		heroname = "Iggy";	
        namereal = "Iggy";
		return;	
	}	
	if(nameP == "NTM5X1NhbHo=") {	
		heroname = "Lorion";	
        namereal = "Lorion";
		return;	
	}	
	if(nameP == "VGFjaGk=") {	
		heroname = "Tachi";	
        namereal = "Tachi";
		return;	
	}	
	if(nameP == "WWFv") {	
		heroname = "Aya";	
        namereal = "Aya";
		return;	
	}
	if(nameP == "V2hpdGVCb3g=") {	
		heroname = "Yan";	
        namereal = "Yan";
		return;	
	}	
	if(nameP == "SGVjYXRl") {	
		heroname = "Terri";	
        namereal = "Terri";
		return;	
	}
    if(nameP == "5piO5LiW6ZqQ") {	
		heroname = "Ming";	
        namereal = "ming";
		return;	
	}

    if(nameP == "54uC6ZOB") {	
		heroname = "Biron";	
        namereal = "biron";
		return;	
	}


}

@end
