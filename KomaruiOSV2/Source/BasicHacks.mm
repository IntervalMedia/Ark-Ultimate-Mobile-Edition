#include "BasicHacks.h"
#include "../MenuLoad/Includes.h"

bool BasicHacks::IsValidPointer(long Offset) {
    return Offset > 0x100000000 && (uint64_t)Offset < 0x3000000000;
}

constexpr uintptr_t OFFSET_CustomTimeDilation = 0x234;
constexpr uintptr_t OFFSET_NormalFOV = 0x33c0;
constexpr uintptr_t OFFSET_FreeCamDistance = 0x2bc0;
constexpr uintptr_t OFFSET_DayCycleSpeed = 0xeac;
constexpr uintptr_t OFFSET_NightCycleSpeed = 0xeb0;

constexpr uintptr_t OFFSET_FNameConstructor = 0x01b526c0;
constexpr uintptr_t OFFSET_FindFunctionChecked = 0x01d08c2c;
constexpr uintptr_t OFFSET_ProcessEvent = 0x02def7e8;

void* BasicHacks::HacksThread(void* arg)
{

    while(true)
    {
        usleep(100);

        uintptr_t BaseAddr                =  (uintptr_t)_dyld_get_image_header(0);
        uintptr_t GWorld                  = *(uintptr_t*)(BaseAddr              + 0x04d5b510);    if (!IsValidPointer(GWorld))                     continue;
        uintptr_t Ulevel                  = *(uintptr_t*)(GWorld                + 0x1d0);         if (!IsValidPointer(Ulevel))                     continue;
        uintptr_t OwningGameInstance      = *(uintptr_t*)(GWorld                + 0x320);         if (!IsValidPointer(OwningGameInstance))         continue;
        uintptr_t LocalPlayers            = *(uintptr_t*)(OwningGameInstance    + 0x38);          if (!IsValidPointer(LocalPlayers))               continue;
        uintptr_t LocalPlayer             = *(uintptr_t*)(LocalPlayers);                          if (!IsValidPointer(LocalPlayer))                continue; 
        uintptr_t LocalPlayerController   = *(uintptr_t*)(LocalPlayer           + 0x30);          if (!IsValidPointer(LocalPlayerController))      continue;
        uintptr_t APawn                   = *(uintptr_t*)(LocalPlayerController + 0x408);         if (!IsValidPointer(APawn))                      continue;
        uintptr_t PlayerCameraManager     = *(uintptr_t*)(LocalPlayerController + 0x480);         if (!IsValidPointer(PlayerCameraManager))        continue;
        uintptr_t WorldSettings           = *(uintptr_t*)(Ulevel                + 0x258);         if (!IsValidPointer(WorldSettings))              continue;

        *(float*)(APawn + OFFSET_CustomTimeDilation) = Variables.LocalSpeed;
        *(float*)(PlayerCameraManager + OFFSET_NormalFOV) = Variables.FOV;
        *(float*)(PlayerCameraManager + OFFSET_FreeCamDistance) = Variables.Zoom;
        *(float*)(WorldSettings + OFFSET_DayCycleSpeed) = Variables.DayCycleSpeed;
        *(float*)(WorldSettings + OFFSET_NightCycleSpeed) = Variables.NightCycleSpeed;
    }

    return NULL;
}

void BasicHacks::Initialize()
{
    pthread_t BasicHacksThread;
    pthread_create(&BasicHacksThread, nullptr, HacksThread, nullptr);
}