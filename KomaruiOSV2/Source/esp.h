#pragma once

#include "../MenuLoad/Includes.h"
#include "BasicHacks.h"
// Forward declarations
struct FVector {
    float X, Y, Z;
    static float Distance(const FVector& a, const FVector& b, float scale = 1.0f);
};

struct FRotator {
    float Pitch, Yaw, Roll;
};

struct MinimalViewInfo {
    FVector Location;
    FRotator Rotation;
    float FOV;
};

struct Actor {
    uintptr_t Pointer;
    FVector Location;
    FVector WorldPos;
    FVector W2SPos;
    uint16_t id;

    Actor(uintptr_t ptr, const FVector& loc, const FVector& world, const FVector& w2s, uint16_t identifier)
        : Pointer(ptr), Location(loc), WorldPos(world), W2SPos(w2s), id(identifier) {}
};

class ESP {
public:
    static MinimalViewInfo camInfo;
    void CacheActors();
    void RenderESP(ImDrawList* drawList);
    void RenderDrawCacheNum(ImDrawList* drawList);
    void RenderESP2DBox(ImDrawList* drawList);
    FVector W2S(const FVector& ActorPos, const MinimalViewInfo& camInfo, const FRotator& CamRotation);

private:
    std::mutex espMutex;
};
