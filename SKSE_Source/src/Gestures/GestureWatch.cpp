#include "Gestures/GestureWatch.h"

#include <atomic>
#include <chrono>
#include <mutex>
#include <shared_mutex>
#include <string>
#include <unordered_map>
#include <vector>

namespace SkyrimNetDOM::Gestures {
    namespace {
        constexpr std::uint32_t kDefaultCooldownMs = 20000;
        constexpr auto kModEventName = "SkyrimNet_DOM_Gesture"sv;

        // BSFixedString is pooled case-insensitively, so the pool pointer identifies the event name.
        std::shared_mutex g_eventsMutex;
        std::unordered_map<const char*, std::string> g_events;
        std::vector<RE::BSFixedString> g_eventNames;  // keeps the pool entries alive

        std::atomic<bool> g_enabled{true};
        std::atomic<bool> g_debug{false};
        std::atomic<bool> g_hasEvents{false};
        std::atomic<std::uint32_t> g_cooldownMs{kDefaultCooldownMs};
        std::atomic<RE::TESFaction*> g_faction{nullptr};

        // Main thread only (task queue and SKSE messages).
        std::unordered_map<RE::FormID, std::uint64_t> g_nextAllowed;

        [[nodiscard]] std::uint64_t NowMs() {
            return static_cast<std::uint64_t>(
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::steady_clock::now().time_since_epoch())
                    .count());
        }

        [[nodiscard]] bool IsWatched(RE::Actor* a_actor) {
            const auto* faction = g_faction.load();
            return a_actor && faction && a_actor->IsInFaction(faction);
        }

        void SendGesture(RE::ActorHandle a_handle, std::string a_key) {
            const auto actor = a_handle.get();
            if (!actor || !IsWatched(actor.get())) {
                return;
            }
            const auto now = NowMs();
            const auto id = actor->GetFormID();
            if (const auto it = g_nextAllowed.find(id); it != g_nextAllowed.end() && now < it->second) {
                return;
            }
            g_nextAllowed[id] = now + g_cooldownMs.load();

            SKSE::log::info("Gesture {} on {:08X} {}", a_key, id, actor->GetDisplayFullName());
            SKSE::ModCallbackEvent modEvent{
                RE::BSFixedString{kModEventName},
                RE::BSFixedString{a_key.c_str()},
                0.0f,
                actor.get()};
            SKSE::GetModCallbackEventSource()->SendEvent(&modEvent);
        }

        struct NotifyAnimationGraphHook {
            static bool Thunk(RE::IAnimationGraphManagerHolder* a_this, const RE::BSFixedString& a_eventName) {
                const bool result = func(a_this, a_eventName);
                if (!result || !g_enabled.load(std::memory_order_relaxed)) {
                    return result;
                }
                const bool debug = g_debug.load(std::memory_order_relaxed);
                if (!debug && !g_hasEvents.load(std::memory_order_relaxed)) {
                    return result;
                }

                std::string key;
                {
                    std::shared_lock lock{g_eventsMutex};
                    if (const auto it = g_events.find(a_eventName.data()); it != g_events.end()) {
                        key = it->second;
                    }
                }

                auto* actor = static_cast<RE::Character*>(a_this);
                if (debug && IsWatched(actor)) {
                    SKSE::log::info("AnimEvent {:08X} {} -> {}", actor->GetFormID(), a_eventName.c_str(), key.empty() ? "-" : key);
                }
                if (key.empty()) {
                    return result;
                }
                // Faction check, cooldown and ModEvent run on the main thread.
                SKSE::GetTaskInterface()->AddTask([handle = actor->GetHandle(), key = std::move(key)]() mutable {
                    SendGesture(handle, std::move(key));
                });
                return result;
            }

            static inline REL::Relocation<decltype(Thunk)> func;
        };
    }

    void Install() {
        // VTABLE_Character[3] is the IAnimationGraphManagerHolder base; vfunc 0x1 is NotifyAnimationGraph.
        REL::Relocation<std::uintptr_t> vtbl{RE::VTABLE_Character[3]};
        NotifyAnimationGraphHook::func = vtbl.write_vfunc(0x1, NotifyAnimationGraphHook::Thunk);
        SKSE::log::info("Installed Character::NotifyAnimationGraph hook");
    }

    void RegisterEvent(std::string_view a_animEvent, std::string_view a_key) {
        if (a_animEvent.empty() || a_key.empty()) {
            return;
        }
        RE::BSFixedString name{std::string{a_animEvent}.c_str()};
        std::unique_lock lock{g_eventsMutex};
        g_events[name.data()] = std::string{a_key};
        g_eventNames.push_back(std::move(name));
        g_hasEvents.store(true);
    }

    void RegisterIdle(RE::TESIdleForm* a_idle, std::string_view a_key) {
        if (!a_idle) {
            return;
        }
        RegisterEvent(a_idle->animEventName.c_str() ? a_idle->animEventName.c_str() : "", a_key);
    }

    void ClearEvents() {
        std::unique_lock lock{g_eventsMutex};
        g_events.clear();
        g_eventNames.clear();
        g_hasEvents.store(false);
    }

    void SetFaction(RE::TESFaction* a_faction) {
        g_faction.store(a_faction);
    }

    void SetEnabled(bool a_enabled, std::uint32_t a_cooldownMs) {
        g_enabled.store(a_enabled);
        g_cooldownMs.store(a_cooldownMs > 0 ? a_cooldownMs : kDefaultCooldownMs);
    }

    void SetDebug(bool a_debug) {
        g_debug.store(a_debug);
    }

    void ClearCooldowns() {
        g_nextAllowed.clear();
    }
}
