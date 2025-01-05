#pragma once

class UserMenu {
public:
    UserMenu(const UserMenu&) = delete;

    static UserMenu& GetInstance() {
        static UserMenu Instance;
        return Instance;
    }

    void DrawMenu();
    void RenderBGUI();
    void Initialize();

private:
    UserMenu() { }
};

static UserMenu& Menu = UserMenu::GetInstance();