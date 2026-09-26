#pragma once

#include "PCH.h"

#include <cstdint>
#include <string>
#include <string_view>

namespace SkyrimNetDOM::Obedience {
    enum class Mode : std::int32_t {
        Ungated = 0,
        OrderDn = 1,
        SexEvent = 2,
    };

    struct KindSpec {
        std::int32_t reason{18};
        std::int32_t facet{1};
        std::int32_t training{0};
        Mode mode{Mode::OrderDn};
    };

    [[nodiscard]] std::string NormalizeKind(std::string_view a_raw);
    [[nodiscard]] KindSpec Lookup(std::string_view a_kind);

    void ArmSkip(RE::Actor* a_slave, std::uint32_t a_ms = 4000);
    [[nodiscard]] bool ShouldSkip(RE::Actor* a_slave);

    [[nodiscard]] std::string MakeRefuse(std::string_view a_superior, std::string_view a_slave, std::string_view a_action);
    [[nodiscard]] std::string MakeObey(std::string_view a_superior, std::string_view a_slave, std::string_view a_action);
    [[nodiscard]] std::string MakeSexOrder(std::string_view a_superior, std::string_view a_slave, std::string_view a_action);

    void ClearSkipTable();
}
