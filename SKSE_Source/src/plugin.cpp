#include "PCH.h"

#include "Obedience/DomObedience.h"
#include "Papyrus/Bridge.h"

namespace {
    void OnSKSEMessage(SKSE::MessagingInterface::Message* a_msg) {
        if (!a_msg) {
            return;
        }
        switch (a_msg->type) {
            case SKSE::MessagingInterface::kPreLoadGame:
            case SKSE::MessagingInterface::kNewGame:
                SkyrimNetDOM::Obedience::ClearSkipTable();
                break;
            default:
                break;
        }
    }
}

SKSEPluginLoad(const SKSE::LoadInterface* a_skse) {
    SKSE::Init(a_skse);
    spdlog::set_level(spdlog::level::info);

    SKSE::log::info("{} loading", SKSE::PluginDeclaration::GetSingleton()->GetName());

    if (const auto* messaging = SKSE::GetMessagingInterface(); !messaging || !messaging->RegisterListener(OnSKSEMessage)) {
        SKSE::log::error("Failed to register SKSE messaging listener");
        return false;
    }

    if (const auto* papyrus = SKSE::GetPapyrusInterface(); !papyrus || !papyrus->Register(SkyrimNetDOM::Papyrus::Register)) {
        SKSE::log::error("Failed to register Papyrus functions");
        return false;
    }

    SKSE::log::info("{} loaded", SKSE::PluginDeclaration::GetSingleton()->GetName());
    return true;
}
