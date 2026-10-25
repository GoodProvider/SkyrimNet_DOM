#include "Obedience/DomObedience.h"

#include <cctype>
#include <chrono>
#include <mutex>
#include <unordered_map>

namespace SkyrimNetDOM::Obedience {
    namespace {
        constexpr std::uint32_t kDefaultSkipMs = 4000;

        std::mutex g_mutex;
        std::unordered_map<RE::FormID, std::uint64_t> g_skipUntil;

        [[nodiscard]] std::uint64_t NowMs() {
            return static_cast<std::uint64_t>(
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::steady_clock::now().time_since_epoch())
                    .count());
        }

        [[nodiscard]] std::string Display(std::string_view a_name) {
            return a_name.empty() ? std::string("someone") : std::string{a_name};
        }
    }

    std::string NormalizeKind(std::string_view a_raw) {
        std::string result;
        result.reserve(a_raw.size());
        for (const char ch : a_raw) {
            if (ch == ' ' || ch == '\t' || ch == '-' || ch == '_') {
                if (!result.empty() && result.back() != '_') {
                    result += '_';
                }
                continue;
            }
            result += static_cast<char>(std::tolower(static_cast<unsigned char>(ch)));
        }
        if (!result.empty() && result.back() == '_') {
            result.pop_back();
        }
        return result;
    }

    KindSpec Lookup(std::string_view a_kind) {
        const std::string key = NormalizeKind(a_kind);

        // Player-performed / ungated.
        static const char* kUngated[] = {
            "strip", "stripall", "rip", "ripall", "inventory", "inspect", "kiss", "feed",
            "praise", "scold", "flatter", "insult", "threaten", "comfort", "promise",
            "punish", "restrain", "tie", "gag", "plug", "blindfold", "cuff", "uncuff",
            "untie", "rape", "brand", "mark", "equip",
        };
        for (const char* token : kUngated) {
            if (key == token) {
                return KindSpec{0, 0, 0, Mode::Ungated};
            }
        }

        // Pose family: didnt_pose / flexibility / pose_training — vanilla DoDance/DoMusic/DoDrinks.
        if (key == "pose" || key == "dance" || key == "music" || key == "drinks" ||
            key == "light" || key == "flowers") {
            return KindSpec{15, 21, 22, Mode::OrderDn};
        }
        if (key == "chair" || key == "ass" || key == "breasts" || key == "pussy") {
            return KindSpec{15, 21, 2, Mode::OrderDn};
        }
        if (key == "cute") {
            return KindSpec{15, 21, 3, Mode::OrderDn};
        }
        if (key == "display" || key == "submissive") {
            return KindSpec{15, -36, 22, Mode::OrderDn};
        }

        // Kneel / salute / attention: being disrespectful / discipline / respect.
        if (key == "kneel" || key == "salute" || key == "attention") {
            return KindSpec{13, -36, 5, Mode::OrderDn};
        }

        if (key == "favor") {
            return KindSpec{18, -36, 4, Mode::OrderDn};
        }
        if (key == "look") {
            return KindSpec{18, -31, 5, Mode::OrderDn};
        }
        if (key == "turn") {
            return KindSpec{18, -15, 5, Mode::OrderDn};
        }
        if (key == "come") {
            return KindSpec{18, -36, 5, Mode::OrderDn};
        }
        if (key == "walk4" || key == "walk_on_four" || key == "walking") {
            return KindSpec{32, -13, 2, Mode::OrderDn};
        }
        if (key == "masturbate" || key == "masturbate_harder" || key == "masturbate_stop") {
            return KindSpec{20, -15, 2, Mode::OrderDn};
        }
        if (key == "sex") {
            return KindSpec{21, -15, 19, Mode::SexEvent};
        }
        if (key == "naked" || key == "undress") {
            return KindSpec{2, -15, 2, Mode::OrderDn};
        }
        if (key == "respectful") {
            return KindSpec{13, -31, 5, Mode::OrderDn};
        }
        if (key == "maid") {
            return KindSpec{10, 28, 23, Mode::OrderDn};
        }
        if (key == "work") {
            return KindSpec{10, 25, 24, Mode::OrderDn};
        }
        if (key == "shower" || key == "bath" || key == "bath_me" || key == "bath_you") {
            return KindSpec{28, -15, 2, Mode::OrderDn};
        }

        // follow, wait, stand, bag, silent, fight, drink, jail, dress, orgasm, generic.
        if (key.empty()) {
            return KindSpec{0, 0, 0, Mode::Ungated};
        }
        return KindSpec{18, 1, 0, Mode::OrderDn};
    }

    void ArmSkip(RE::Actor* a_slave, std::uint32_t a_ms) {
        if (!a_slave) {
            return;
        }
        const std::uint32_t ms = a_ms > 0 ? a_ms : kDefaultSkipMs;
        std::lock_guard lock{g_mutex};
        g_skipUntil[a_slave->GetFormID()] = NowMs() + ms;
    }

    bool ShouldSkip(RE::Actor* a_slave) {
        if (!a_slave) {
            return false;
        }
        const auto now = NowMs();
        std::lock_guard lock{g_mutex};
        const auto it = g_skipUntil.find(a_slave->GetFormID());
        if (it == g_skipUntil.end()) {
            return false;
        }
        if (now >= it->second) {
            g_skipUntil.erase(it);
            return false;
        }
        return true;
    }

    std::string MakeRefuse(std::string_view a_superior, std::string_view a_slave, std::string_view a_action) {
        const std::string superior = Display(a_superior);
        const std::string slave = Display(a_slave);
        const std::string action = a_action.empty() ? std::string("obey") : std::string{a_action};
        return slave + " refuses " + superior + "'s command to " + action + ".";
    }

    std::string MakeObey(std::string_view a_superior, std::string_view a_slave, std::string_view a_action) {
        const std::string superior = Display(a_superior);
        const std::string slave = Display(a_slave);
        const std::string action = a_action.empty() ? std::string("obey") : std::string{a_action};
        // Match OrderNarration: "{superior} orders {slave} to {action}."
        return superior + " orders " + slave + " to " + action + ".";
    }

    std::string MakeSexOrder(std::string_view a_superior, std::string_view a_slave, std::string_view a_action) {
        const std::string action = a_action.empty() ? std::string("sex") : std::string{a_action};
        return MakeObey(a_superior, a_slave, action);
    }

    void ClearSkipTable() {
        std::lock_guard lock{g_mutex};
        g_skipUntil.clear();
    }
}
