#pragma once

#include "ImGuiDrawView.h"
#include "MenuLoad.h"

#include "../ImGui/imgui.h"
#include "../ImGui/imgui_internal.h"
#include "../ImGui/imgui_impl_metal.h"

#include <vector>
#include <map>
#include <unistd.h>
#include <string.h>
#include <vector>
#include <functional>
#include <iostream>
#include <queue>
#include <pthread/pthread.h>
#include <substrate.h>
#include <unordered_map>

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import <os/log.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <stdio.h>
#import <mach/mach.h>

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define SCREEN_SCALE [UIScreen mainScreen].scale
#define timer(sec) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, sec * NSEC_PER_SEC), dispatch_get_main_queue(), ^


struct GlobalVariables
{
    static GlobalVariables& GetInstance() {
        static GlobalVariables Instance;
        return Instance;
    }

    void SaveSettings() {
        NSFileManager* FileManager = [NSFileManager defaultManager];
        NSString* DocumentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];

        @autoreleasepool {
            NSString* FilePath = [DocumentsDirectory stringByAppendingPathComponent:@"Preferences.txt"];

            if ([FileManager fileExistsAtPath:FilePath]) {
                NSData* SettingsData = [NSData dataWithBytes:this length:sizeof(GlobalVariables)];
                [SettingsData writeToFile:FilePath options:NSDataWritingAtomic error:nil];
            }
            else {
                [FileManager createFileAtPath:FilePath contents:[NSData data] attributes:nil];
            }
        }
    }

    void LoadSettings() {
        NSFileManager* FileManager = [NSFileManager defaultManager];
        NSString* DocumentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];

        @autoreleasepool {
            NSString* FilePath = [DocumentsDirectory stringByAppendingPathComponent:@"Preferences.txt"];

            if ([FileManager fileExistsAtPath:FilePath]) {
                NSData* SettingsData = [NSData dataWithContentsOfFile:FilePath options:NSDataReadingMappedIfSafe error:nil];
                if (SettingsData) [SettingsData getBytes:this length:sizeof(GlobalVariables)];
            }
            else {
                [FileManager createFileAtPath:FilePath contents:[NSData data] attributes:nil];
            }
        }
    }

    ImVec2 MenuSize   = ImVec2(0, 0);
    ImVec2 MenuOrigin = ImVec2(0, 0);

    bool StreamerMode = false;
    bool MoveMenu = false;


    float FOV = 90.0f;
    float Zoom = 200.0f;

    float DayCycleSpeed = 1.0f;
    float NightCycleSpeed = 1.0f;

    float LocalSpeed = 1.0f;

    float EspDrawDistance = 300.0f;
    bool espEnabled = false;
    bool showActorCount = false;
    bool Draw2DBoxes = false;
};






static GlobalVariables& Variables = GlobalVariables::GetInstance();
