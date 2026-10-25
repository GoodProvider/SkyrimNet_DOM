#pragma once

#include "PCH.h"

#include <cstdint>
#include <string_view>

// Detects DOM ChooseIdle gestures (salute, cross arms, cover self, ...) on slaves.
// DOM plays them with Debug.SendAnimationEvent / Actor.PlayIdle and fires no event, so we hook
// Character::NotifyAnimationGraph, match whitelisted event names and send ModEvent
// "SkyrimNet_DOM_Gesture" (strArg = gesture key, sender = actor) from the main thread.
namespace SkyrimNetDOM::Gestures {
    void Install();

    void RegisterEvent(std::string_view a_animEvent, std::string_view a_key);
    void RegisterIdle(RE::TESIdleForm* a_idle, std::string_view a_key);
    void ClearEvents();

    void SetFaction(RE::TESFaction* a_faction);
    void SetEnabled(bool a_enabled, std::uint32_t a_cooldownMs);
    void SetDebug(bool a_debug);

    void ClearCooldowns();
}
