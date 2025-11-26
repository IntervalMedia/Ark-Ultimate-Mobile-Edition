# Ark: Ultimate Mobile Edition IOS Mod Menu
Works only with offline + single player with ark version 1.89

Non Jailbreak mod menu built for Ark: Ultimate Mobile Edition for iOS. 

## Source Code
Thanks to the Mercenary Dev Team for the original base code.
I have updated some design choices. This is a good Unreal Engine base template for iOS.
Renders uses external dear imgui and Metal backend, which can cause extra overhead compared to hooking post render and rendering internally.
Tweak has been designed to use Apple native Objc API's for efficient memory management to minimise the overhead.
SDK dumped with iOS_UEDUMPER to get base offsets for Unreal Engine 4.26

## Build
Build with THEOS make clean package
Inject into a decrypted copy of the ipa file. Search the web for "Decrypted IPA store" to get the version 1.89 Ark

## Detected / EOS Anti Cheat
As of 2025 the Epic Online Services detect the modified game install, mode menu injected dylib, and prevent any servers loading. 
This server side detection makes multiplayer impossible as game will crash if injecting a dylib for side loading or jailbreak.