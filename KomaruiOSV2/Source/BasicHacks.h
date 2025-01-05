#pragma once

class BasicHacks {
public:
    BasicHacks(const BasicHacks&) = delete;

    static BasicHacks& GetInstance() {
        static BasicHacks Instance;
        return Instance;
    }

    static bool IsValidPointer(long Offset);
    static void* HacksThread(void* arg);

    void Initialize();

private:
    BasicHacks() { }
};

static BasicHacks& BasicCheats = BasicHacks::GetInstance();
