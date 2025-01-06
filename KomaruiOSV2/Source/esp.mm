#include "esp.h"
#include "../MenuLoad/Includes.h"

// Draw cache vector
std::vector<Actor> DrawCache;

// camera information
MinimalViewInfo ESP::camInfo = {};


// ----------------------------------------------
//Offsets
// ----------------------------------------------
constexpr uintptr_t OFFSET_GWORLD = 0x4D57380;
constexpr uintptr_t OFFSET_LEVEL = 0x1D0;
constexpr uintptr_t OFFSET_ACTOR_ARRAY = 0x98;
constexpr uintptr_t OFFSET_ACTOR_COUNT = 0xA0;
constexpr uintptr_t OFFSET_GAME_INSTANCE = 0x320;
constexpr uintptr_t OFFSET_LOCAL_PLAYERS = 0x38;
constexpr uintptr_t OFFSET_PLAYER_CONTROLLER = 0x30;
constexpr uintptr_t OFFSET_CAMERA_MANAGER = 0x480;
constexpr uintptr_t OFFSET_VIEW_TARGET = 0x1150;
constexpr uintptr_t OFFSET_POV = 0x10;

uintptr_t GetBaseAddress() {
    static uintptr_t DylibAddress = 0;
    if (DylibAddress != 0) return DylibAddress;

    for (uint32_t i = 0; i < _dyld_image_count(); ++i) {
        const char* DylibName = _dyld_get_image_name(i);
        if (strstr(DylibName, "ShooterGame")) { // Binary Name
            DylibAddress = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }
    return DylibAddress;
}

bool IsValidPointer(uintptr_t ptr) {
    return ptr != 0 && ptr != (uintptr_t)-1;
}

void ESP::CacheActors() {
    std::lock_guard<std::mutex> lock(espMutex);
    DrawCache.clear();

    uintptr_t baseAddr = GetBaseAddress();
    if (!IsValidPointer(baseAddr)) return;

    uintptr_t gWorld = *reinterpret_cast<uintptr_t*>(baseAddr + OFFSET_GWORLD);
    if (!IsValidPointer(gWorld)) return;

    uintptr_t uLevel = *reinterpret_cast<uintptr_t*>(gWorld + OFFSET_LEVEL);
    if (!IsValidPointer(uLevel)) return;

    uintptr_t actorArray = *reinterpret_cast<uintptr_t*>(uLevel + OFFSET_ACTOR_ARRAY);
    if (!IsValidPointer(actorArray)) return;

    int actorCount = *reinterpret_cast<int*>(uLevel + OFFSET_ACTOR_COUNT);
    if (actorCount <= 0) return; //return if no valid actors to cache, prevents crash.

    uintptr_t owningGameInstance = *reinterpret_cast<uintptr_t*>(gWorld + OFFSET_GAME_INSTANCE);
    if (!IsValidPointer(owningGameInstance)) return;

    uintptr_t localPlayers = *reinterpret_cast<uintptr_t*>(owningGameInstance + OFFSET_LOCAL_PLAYERS);
    if (!IsValidPointer(localPlayers)) return;

    uintptr_t localPlayer = *reinterpret_cast<uintptr_t*>(localPlayers);
    if (!IsValidPointer(localPlayer)) return;

    uintptr_t localPlayerController = *reinterpret_cast<uintptr_t*>(localPlayer + OFFSET_PLAYER_CONTROLLER);
    if (!IsValidPointer(localPlayerController)) return;

    uintptr_t playerCameraManager = *reinterpret_cast<uintptr_t*>(localPlayerController + OFFSET_CAMERA_MANAGER);
    if (!IsValidPointer(playerCameraManager)) return;

    uintptr_t ftViewTarget = playerCameraManager + OFFSET_VIEW_TARGET;
    if (!IsValidPointer(ftViewTarget)) return;

    uintptr_t povAddr = ftViewTarget + OFFSET_POV;
    if (!IsValidPointer(povAddr)) return;

    // Update camera info
    MinimalViewInfo camInfo;
    camInfo.Location.X = *reinterpret_cast<float*>(povAddr);
    camInfo.Location.Y = *reinterpret_cast<float*>(povAddr + 4);
    camInfo.Location.Z = *reinterpret_cast<float*>(povAddr + 8);
    camInfo.Rotation.Pitch = *reinterpret_cast<float*>(povAddr + 0xC);
    camInfo.Rotation.Yaw = *reinterpret_cast<float*>(povAddr + 0xC + 4);
    camInfo.Rotation.Roll = *reinterpret_cast<float*>(povAddr + 0xC + 8);
    camInfo.FOV = *reinterpret_cast<float*>(povAddr + 0x18);
    ESP::camInfo = camInfo;

    // Iterate through actors
    for (int i = 0; i < actorCount; i++) {
        uintptr_t actorPtr = *reinterpret_cast<uintptr_t*>(actorArray + (i * sizeof(uintptr_t)));
        if (!IsValidPointer(actorPtr)) continue;

        uintptr_t rootComponent = *reinterpret_cast<uintptr_t*>(actorPtr + 0x2E0);
        if (!IsValidPointer(rootComponent)) continue;

        // Reading FVector directly from memory
        FVector location = *reinterpret_cast<FVector*>(rootComponent + 0x134);
        FVector worldPos = location;

        // Calculate distance manually
        float distance = sqrtf(
            powf(camInfo.Location.X - location.X, 2) +
            powf(camInfo.Location.Y - location.Y, 2) +
            powf(camInfo.Location.Z - location.Z, 2)
        );

        if (distance > Variables.EspDrawDistance) continue;

        FVector w2sPos = worldPos;
        w2sPos.Z += 80.0f;

        // Reading uint16_t directly from memory
        uint16_t actorId = *reinterpret_cast<uint16_t*>(actorPtr) & 0x0FFF;
        Actor ent(actorPtr, location, worldPos, w2sPos, actorId);
        DrawCache.push_back(ent);
    }
}

//tracer ESP + Actor IDS
void ESP::RenderESP(ImDrawList* drawList) {
    if (!Variables.espEnabled) return;

    CacheActors();
    for (const auto& actor : DrawCache) {
        FVector screenData = W2S(actor.W2SPos, camInfo, camInfo.Rotation);
        FVector extraScreenData = W2S(FVector{actor.W2SPos.X, actor.W2SPos.Y, actor.W2SPos.Z - 80.0f}, camInfo, camInfo.Rotation);
        float height = extraScreenData.Y - screenData.Y;
        float width = height / 2;

        drawList->AddText(
            ImVec2(screenData.X - width * 0.5f, screenData.Y + 10),
            IM_COL32(255, 255, 255, 255),
            ("ID: " + std::to_string(actor.id)).c_str()
        );

        ImGui::GetBackgroundDrawList()->AddLine(
            ImVec2(SCREEN_WIDTH / 2, SCREEN_HEIGHT),
            ImVec2(screenData.X, screenData.Y),
            IM_COL32(255, 0, 0, 255)
        );

        drawList->AddCircleFilled(
            ImVec2(screenData.X, screenData.Y),
            5.0f,
            IM_COL32(255, 0, 0, 255)
        );
    }
}


void ESP::RenderDrawCacheNum(ImDrawList* drawList) {
    if (!Variables.showActorCount) return;

    int actorCount = DrawCache.size();

    // Calculate position for the text
    ImVec2 position(SCREEN_WIDTH / 2.0f, 30.0f);
    position.y += 20.0f;

    // Render the number of actors
    drawList->AddText(position, IM_COL32(255, 255, 255, 255), 
    ("DrawCache: " + std::to_string(actorCount)).c_str());
}


FVector ESP::W2S(const FVector& ActorPos, const MinimalViewInfo& camInfo, const FRotator& CamRotation) {
    float radPitch = CamRotation.Pitch * (M_PI / 180.0);
    float radYaw = CamRotation.Yaw * (M_PI / 180.0);
    float radRoll = CamRotation.Roll * (M_PI / 180.0);

    float SP = sin(radPitch);
    float CP = cos(radPitch);
    float SY = sin(radYaw);
    float CY = cos(radYaw);
    float SR = sin(radRoll);
    float CR = cos(radRoll);

    FVector AxisX;
    AxisX.X = (CP * CY);
    AxisX.Y = (CP * SY);
    AxisX.Z = (SP);
    FVector AxisY;
    AxisY.X = (SR * SP * CY - CR * SY);
    AxisY.Y = (SR * SP * SY + CR * CY);
    AxisY.Z = (-SR * CP);
    FVector AxisZ;
    AxisZ.X = (-(CR * SP * CY + SR * SY));
    AxisZ.Y = (CY * SR - CR * SP * SY);
    AxisZ.Z = (CR * CP);
    FVector vDelta;
    vDelta.X = (ActorPos.X - camInfo.Location.X);
    vDelta.Y = (ActorPos.Y - camInfo.Location.Y);
    vDelta.Z = (ActorPos.Z - camInfo.Location.Z);
    FVector vTransformed;
    vTransformed.X = vDelta.X * AxisY.X + vDelta.Y * AxisY.Y + vDelta.Z * AxisY.Z;
    vTransformed.Y = vDelta.X * AxisZ.X + vDelta.Y * AxisZ.Y + vDelta.Z * AxisZ.Z;
    vTransformed.Z = vDelta.X * AxisX.X + vDelta.Y * AxisX.Y + vDelta.Z * AxisX.Z;

    if (vTransformed.Z < 1.0) {
        vTransformed.Z = 1.0;
    }
    FVector ScreenCenter;
    ScreenCenter.X = (SCREEN_WIDTH / 2.0);
    ScreenCenter.Y = (SCREEN_HEIGHT / 2.0);
    FVector results;
    results.X = (ScreenCenter.X + vTransformed.X * (ScreenCenter.X / tan(camInfo.FOV * (M_PI / 360.0))) / vTransformed.Z);
    results.Y = (ScreenCenter.Y - vTransformed.Y * (ScreenCenter.X / tan(camInfo.FOV * (M_PI / 360.0))) / vTransformed.Z);
    results.Z = 0;
    return results;
}
