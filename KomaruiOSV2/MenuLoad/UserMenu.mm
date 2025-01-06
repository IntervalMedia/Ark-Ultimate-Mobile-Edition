#include "UserMenu.h"
#include "Includes.h"
#include "../Source/esp.h"

ESP espSystem; // Create an ESP system instance

const char* getCurrentDate()
{
    //pasted
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd-yyyy HH:mm:ss"]; // Customize the format if needed
    NSString *dateString = [formatter stringFromDate:currentDate];
    return [dateString UTF8String];
}

void UserMenu::DrawMenu()
{
    ImVec2 WindowSize = ImVec2(390, 370);
    ImGui::SetNextWindowSize(WindowSize, ImGuiCond_Once);

    ImVec2 WindowPosition = ImVec2((SCREEN_WIDTH - 390) - 10, 10);
    ImGui::SetNextWindowPos(WindowPosition, ImGuiCond_Once);

    ImGuiWindowFlags WindowFlags = Variables.MoveMenu ? ImGuiWindowFlags_NoCollapse : ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove;

    if (ImGui::Begin("Komaru V1.0", NULL, WindowFlags))
    {
        ImGuiWindow* CurrentWindow = ImGui::GetCurrentWindow();
        Variables.MenuSize   = CurrentWindow->Size;
        Variables.MenuOrigin = CurrentWindow->Pos;

        if (ImGui::CollapsingHeader("Parameter")) {
            ImGui::SliderFloat("PlayerSpeed", &Variables.LocalSpeed, 0.0f, 1.5f);
            ImGui::SliderFloat("FOV", &Variables.FOV, 60.0f, 160.0f);
            ImGui::SliderFloat("Zoom", &Variables.Zoom, 200.0f, 2000.0f);
            ImGui::SliderFloat("DaySpeed", &Variables.DayCycleSpeed, 0.1f, 20000.0f);
            ImGui::SliderFloat("NightSpeed", &Variables.NightCycleSpeed, 0.1f, 20000.0f);
        }

        if (ImGui::CollapsingHeader("ESP")) {
            ImGui::SliderFloat("Max ESP Distance", &Variables.EspDrawDistance, 300.0f, 100000.0f);
            ImGui::Checkbox("Enable ESP", &Variables.espEnabled);
            ImGui::Checkbox("Actor Count", &Variables.showActorCount);
        }

        if (ImGui::CollapsingHeader("Misc")) {
            ImGui::Text("Empty");
        }

        // Misc menu options
        ImGui::Checkbox("Move Menu", &Variables.MoveMenu);
        ImGui::SameLine();
        ImGui::Checkbox("Streamer Mode", &Variables.StreamerMode);

        // Time display
        const char* currentDate = getCurrentDate();
        ImGui::Text("Current Date: %s", currentDate);

        ImGui::End();
        //Variables.SaveSettings();
    }
}

// ------------------------------------------------------
// RenderBGUI
// ------------------------------------------------------
void UserMenu::RenderBGUI()
{
    ImGui::Begin("RenderMenu", nullptr,
        ImGuiWindowFlags_NoTitleBar |
        ImGuiWindowFlags_NoResize |
        ImGuiWindowFlags_NoMove |
        ImGuiWindowFlags_NoBackground |
        ImGuiWindowFlags_NoInputs);

    ImDrawList* drawList = ImGui::GetBackgroundDrawList();

    // Render tracers and actor IDS
    if (Variables.espEnabled) {
        espSystem.RenderESP(drawList);
    }
    
    // render actor count
    if (Variables.showActorCount) {
        espSystem.RenderDrawCacheNum(drawList);
    }

    ImGui::End();
}

void UserMenu::Initialize()
{
    DrawMenu();
    RenderBGUI();
}
