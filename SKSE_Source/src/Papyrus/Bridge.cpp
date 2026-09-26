#include "Papyrus/Bridge.h"

#include "Obedience/DomObedience.h"

namespace SkyrimNetDOM::Papyrus {
    namespace {
        constexpr std::string_view kScriptName = "SkyrimNet_DOM_Native";

        std::int32_t KindMode(RE::StaticFunctionTag*, RE::BSFixedString a_kind) {
            const auto spec = Obedience::Lookup(a_kind.c_str() ? a_kind.c_str() : "");
            return static_cast<std::int32_t>(spec.mode);
        }

        std::int32_t KindReason(RE::StaticFunctionTag*, RE::BSFixedString a_kind) {
            return Obedience::Lookup(a_kind.c_str() ? a_kind.c_str() : "").reason;
        }

        std::int32_t KindFacet(RE::StaticFunctionTag*, RE::BSFixedString a_kind) {
            return Obedience::Lookup(a_kind.c_str() ? a_kind.c_str() : "").facet;
        }

        std::int32_t KindTraining(RE::StaticFunctionTag*, RE::BSFixedString a_kind) {
            return Obedience::Lookup(a_kind.c_str() ? a_kind.c_str() : "").training;
        }

        void ArmSkip(RE::StaticFunctionTag*, RE::Actor* a_slave, std::int32_t a_ms) {
            const std::uint32_t ms = a_ms > 0 ? static_cast<std::uint32_t>(a_ms) : 4000u;
            Obedience::ArmSkip(a_slave, ms);
        }

        bool ShouldSkipEventNarration(RE::StaticFunctionTag*, RE::Actor* a_slave) {
            return Obedience::ShouldSkip(a_slave);
        }

        RE::BSFixedString MakeRefuseNarration(RE::StaticFunctionTag*, RE::BSFixedString a_superior, RE::BSFixedString a_slave, RE::BSFixedString a_action) {
            const char* superior = a_superior.c_str() ? a_superior.c_str() : "";
            const char* slave = a_slave.c_str() ? a_slave.c_str() : "";
            const char* action = a_action.c_str() ? a_action.c_str() : "";
            return RE::BSFixedString{Obedience::MakeRefuse(superior, slave, action).c_str()};
        }

        RE::BSFixedString MakeObeyNarration(RE::StaticFunctionTag*, RE::BSFixedString a_superior, RE::BSFixedString a_slave, RE::BSFixedString a_action) {
            const char* superior = a_superior.c_str() ? a_superior.c_str() : "";
            const char* slave = a_slave.c_str() ? a_slave.c_str() : "";
            const char* action = a_action.c_str() ? a_action.c_str() : "";
            return RE::BSFixedString{Obedience::MakeObey(superior, slave, action).c_str()};
        }

        RE::BSFixedString MakeSexOrderEvent(RE::StaticFunctionTag*, RE::BSFixedString a_superior, RE::BSFixedString a_slave, RE::BSFixedString a_action) {
            const char* superior = a_superior.c_str() ? a_superior.c_str() : "";
            const char* slave = a_slave.c_str() ? a_slave.c_str() : "";
            const char* action = a_action.c_str() ? a_action.c_str() : "";
            return RE::BSFixedString{Obedience::MakeSexOrder(superior, slave, action).c_str()};
        }
    }

    bool Register(RE::BSScript::IVirtualMachine* a_vm) {
        if (!a_vm) {
            return false;
        }
        a_vm->RegisterFunction("KindMode", kScriptName, KindMode);
        a_vm->RegisterFunction("KindReason", kScriptName, KindReason);
        a_vm->RegisterFunction("KindFacet", kScriptName, KindFacet);
        a_vm->RegisterFunction("KindTraining", kScriptName, KindTraining);
        a_vm->RegisterFunction("ArmSkip", kScriptName, ArmSkip);
        a_vm->RegisterFunction("ShouldSkipEventNarration", kScriptName, ShouldSkipEventNarration);
        a_vm->RegisterFunction("MakeRefuseNarration", kScriptName, MakeRefuseNarration);
        a_vm->RegisterFunction("MakeObeyNarration", kScriptName, MakeObeyNarration);
        a_vm->RegisterFunction("MakeSexOrderEvent", kScriptName, MakeSexOrderEvent);
        SKSE::log::info("Registered {} Papyrus functions", kScriptName);
        return true;
    }
}
