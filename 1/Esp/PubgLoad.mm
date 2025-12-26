//
//  PubgLoad.m
//  pubg
//
//  Created by 李良林 on 2021/2/14.
//

#import "PubgLoad.h"
#import <UIKit/UIKit.h>
#import "JHPP.h"
#import "JHDragView.h"
#import "ImGuiLoad.h"
#import "ImGuiDrawView.h"
#import <Foundation/Foundation.h>
#import "APIKey.h"
#include "Obfuscate.h"
@interface PubgLoad()
@property (nonatomic, strong) ImGuiDrawView *vna;
@end

@implementation PubgLoad
static BOOL MenDeal;
static PubgLoad *extraInfo;


UIWindow *mainWindow;


+ (void)load
{
[super load];
 
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					
				PPAPIKey *APIKey = [[PPAPIKey alloc] init];
        [APIKey setPackageToken:NSSENCRYPT("GDK3HJ0iCQYuSDbSugzjTbfI6mVT79Y1dGhwNBO4MMngmg4mpQ39WHXNse1KMXO9WzlrLUoMRymrqK8MJKBJllOlA8pvp5AhjtUx")]; 
        [APIKey setOKText:NSSENCRYPT("OK")];
        [APIKey setContactText:NSSENCRYPT("Liên Hệ")];
        [APIKey setAppVersion:NSSENCRYPT("1.0")];
        [APIKey setENLanguage:NO];
        [APIKey loading:^{
        
					mainWindow = [UIApplication sharedApplication].keyWindow;
					extraInfo =  [PubgLoad new];
            [extraInfo initTapGes];
            [extraInfo tapIconView];
            [extraInfo initTapGes2];
            [extraInfo tapIconView2];
            [extraInfo tapmenuicon];
						}];
});
        
    }

-(void)tapmenuicon
{
    JHDragView *view = [[JHPP currentViewController].view viewWithTag:100];
    if (!view) {
        view = [[JHDragView alloc] init];
        view.tag = 100;
        [[JHPP currentViewController].view addSubview:view];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapIconView)];
        tap.numberOfTapsRequired = 1;
        [view addGestureRecognizer:tap];
    }
    if (!MenDeal) {
        view.hidden = NO;
    } else {
        view.hidden = YES;
    }
    MenDeal = !MenDeal;
}



-(void)initTapGes
{
    

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    tap.numberOfTapsRequired = 2;//số ngón chạm
    tap.numberOfTouchesRequired = 3;//số lần chạm
    [[JHPP currentViewController].view addGestureRecognizer:tap];
    [tap addTarget:self action:@selector(tapIconView)];
}

-(void)initTapGes2
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    tap.numberOfTapsRequired = 2;//点击次数
    tap.numberOfTouchesRequired = 2;//手指数
    [[JHPP currentViewController].view addGestureRecognizer:tap];
    [tap addTarget:self action:@selector(tapIconView2)];
}

-(void)tapIconView2
{
 if (!_vna) {
     ImGuiDrawView *vc = [[ImGuiDrawView alloc] init];
     _vna = vc;
 }
 
 [ImGuiDrawView showChange:false];
 [[UIApplication sharedApplication].windows[0].rootViewController.view addSubview:_vna.view];
}

-(void)tapIconView
{
 if (!_vna) {
     ImGuiDrawView *vc = [[ImGuiDrawView alloc] init];
     _vna = vc;
 }
 
 [ImGuiDrawView showChange:true];
 [[UIApplication sharedApplication].windows[0].rootViewController.view addSubview:_vna.view];
}



@end
