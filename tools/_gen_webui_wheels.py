# One-shot generator for DOM TargetMenu JSON. Not shipped.
import json
from pathlib import Path

OUT = Path(r"c:\Skyrim\dev\mods\SkyrimNet_DOM\SKSE\Plugins\SkyrimNet_SexLab\webui\TargetMenu\Actor\options")
PLUGIN = "SkyrimNet_DOM.esp"
QUEST = "0x800"
SCRIPT = "SkyrimNet_DOM_Menu"
SL_PLUGIN = "SkyrimNet_SexLab.esp"
SL_SCRIPT = "SkyrimNet_SexLab_Actions"


def cond(name, op, expected, arguments=None):
    d = {"decoratorName": name, "comparisonOperator": op, "expectedValue": expected}
    if arguments is not None:
        d["arguments"] = arguments
    return d


C_ALL = cond("webui_focus_kind", "==", "all_slaves")
C_NOT_ALL = cond("webui_focus_kind", "!=", "all_slaves")
C_SLAVE = cond("get_faction_rank", ">", 0, ["currentActor", "DOMPlayerSlaveFaction"])
C_TRAINER = cond("get_faction_rank", "==", 2, ["currentActor", "DOMPlayerSlaveFaction"])
C_SLAVER = cond("is_in_faction", "==", True, ["currentActor", "DOMPlayerSlaverFaction"])
C_NOT_SLAVER = cond("is_in_faction", "==", False, ["currentActor", "DOMPlayerSlaverFaction"])
C_NOT_SLAVE = cond("get_faction_rank", "<=", 0, ["currentActor", "DOMPlayerSlaveFaction"])
C_DUTY = cond("is_in_faction", "==", True, ["currentActor", "DOMActionOnDuty"])
C_NOT_DUTY = cond("is_in_faction", "==", False, ["currentActor", "DOMActionOnDuty"])
C_MAST = cond("is_in_faction", "==", True, ["currentActor", "DOMActionMasturbating"])
C_NOT_MAST = cond("is_in_faction", "==", False, ["currentActor", "DOMActionMasturbating"])


def rules(*groups):
    return list(groups)


def g_and(*cs, required=True):
    return {"required": required, "conditions": list(cs)}


def g_or(*cs, required=True):
    return {"required": required, "logicalOperator": "OR", "conditions": list(cs)}


EL_SINGLE = rules(g_and(C_NOT_ALL))
EL_ALL = rules(g_and(C_ALL))
EL_SLAVE = rules(g_and(C_NOT_ALL, C_SLAVE))
EL_SLAVE_SLAVER = rules(g_and(C_NOT_ALL), g_or(C_SLAVE, C_SLAVER))
EL_SLAVE_SLAVER_NPC = rules(g_and(C_NOT_ALL))
EL_NOT_DUTY_SLAVE_SLAVER = rules(g_and(C_NOT_ALL, C_NOT_DUTY), g_or(C_SLAVE, C_SLAVER))
EL_NPC = rules(g_and(C_NOT_ALL, C_NOT_SLAVE, C_NOT_SLAVER))
EL_TRAINER = rules(g_and(C_NOT_ALL), g_or(C_TRAINER, C_SLAVER))
EL_MAST = rules(g_and(C_NOT_ALL, C_SLAVE, C_MAST, C_NOT_DUTY))
EL_NOT_MAST = rules(g_and(C_NOT_ALL, C_SLAVE, C_NOT_MAST, C_NOT_DUTY))


def mapping(*items):
    out = []
    for it in items:
        kind, name = it[0], it[1]
        if kind == "speaker":
            out.append({"type": "speaker", "name": name})
        elif kind == "target":
            out.append({"type": "target", "name": name})
        elif kind == "static":
            out.append({"type": "static", "name": name, "value": it[2]})
        elif kind == "dynamic":
            d = {"type": "dynamic", "name": name}
            if len(it) > 2:
                d["description"] = it[2]
            out.append(d)
        elif kind == "optionActor":
            out.append({"type": "optionActor", "name": name})
    return out


def pap(label, fn, maps, close=True, el=None, plugin=PLUGIN, script=SCRIPT, panel=None, panelDefaults=None):
    o = {
        "type": "papyrus",
        "label": label,
        "plugin": plugin,
        "questFormId": QUEST,
        "scriptName": script,
        "executionFunctionName": fn,
        "closeWebUI": close,
        "parameterMapping": maps,
    }
    if el:
        o["eligibilityRules"] = el
    if panel:
        o["panel"] = panel
    if panelDefaults:
        o["panelDefaults"] = panelDefaults
    return o


def named(label, fn, typ="", el=None, close=True):
    return pap(label, "TM_DoNamed", mapping(("speaker", "speaker"), ("target", "target"), ("static", "fn", fn), ("static", "type", typ)), close=close, el=el)


def order(label, event, typ="", flag="", el=None):
    return pap(label, "TM_DoOrder", mapping(("speaker", "speaker"), ("target", "target"), ("static", "eventName", event), ("static", "type", typ), ("static", "flag", flag)), el=el)


def follow(label, kind, typ="", el=None):
    return pap(label, "TM_DoFollow", mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", kind), ("static", "type", typ)), el=el)


def restrain(label, kind, flag="", el=None):
    return pap(label, "TM_DoRestrain", mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", kind), ("static", "flag", flag)), el=el)


def trainer(label, kind, other="", el=None, close=True):
    return pap(label, "TM_DoTrainer", mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", kind), ("static", "otherId", other)), close=close, el=el)


def pull(label, options, layout="buttons", el=None, options_from=None, option_template=None):
    o = {"type": "pulldown", "label": label, "layout": layout, "options": options}
    if el:
        o["eligibilityRules"] = el
    if options_from:
        o["optionsFrom"] = options_from
    if option_template:
        o["optionTemplate"] = option_template
    return o


def dump(name, obj):
    path = OUT / name
    path.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")
    print("wrote", path)


SCENE_MAP = mapping(
    ("dynamic", "intent", "sexual activities"),
    ("speaker", "speaker"),
    ("target", "target"),
    ("dynamic", "style", "forcefully|normally|gently"),
    ("dynamic", "tags", "comma-separated tags"),
    ("dynamic", "direction", "fucking|fucked in"),
    ("dynamic", "setting_name", "scene setting json name"),
)

SEX_DEFAULTS = {
    "subject": "player",
    "object": "currentActor",
    "objectRelation": "with",
    "andThird": "none",
    "intent": "sexual activities",
    "direction": "fucking",
    "method": "pussy",
    "style": "normally",
    "settingName": "default",
}

RAPE_DEFAULTS = {
    "subject": "player",
    "object": "currentActor",
    "objectRelation": "to victim",
    "andThird": "none",
    "intent": "sexual assault",
    "direction": "fucking",
    "method": "pussy",
    "style": "forcefully",
    "settingName": "punish_pleasure_pain_rape",
}


def scene_sex(label, el):
    return pap(
        label,
        "StartScene_Consensual_Two",
        SCENE_MAP,
        close=True,
        el=el,
        plugin=SL_PLUGIN,
        script=SL_SCRIPT,
        panel="scene_start",
        panelDefaults=SEX_DEFAULTS,
    )


def scene_rape(label, el):
    maps = mapping(
        ("dynamic", "intent", "sexual assault"),
        ("speaker", "speaker"),
        ("target", "target"),
        ("dynamic", "style", "forcefully|normally|gently"),
        ("dynamic", "tags", "comma-separated tags"),
        ("dynamic", "direction", "fucking|fucked in"),
        ("dynamic", "setting_name", "scene setting json name"),
    )
    return pap(
        label,
        "StartScene_Nonconsensual_Two_TargetVictim",
        maps,
        close=True,
        el=el,
        plugin=SL_PLUGIN,
        script=SL_SCRIPT,
        panel="scene_start",
        panelDefaults=RAPE_DEFAULTS,
    )


DIST_LABELS = [("tight", "0"), ("close", "1"), ("near", "2"), ("long", "3"), ("far", "4"), ("very far", "5")]
FOLLOW_DIST_NAMES = ["tight", "close", "short", "long"]
WALK_OPTS = [{"val": "0", "caption": "walking"}, {"val": "1", "caption": "crawling"}]
DIST_OPTS = [{"val": val, "caption": lab} for lab, val in DIST_LABELS]
WALKING_TYPES = [
    {"val": "walking", "caption": "walking"},
    {"val": "four", "caption": "follow on four"},
    {"val": "knees", "caption": "follow on hands and knees"},
]


def fields_pap(label, fn, field_list, defaults, maps, el=None):
    o = pap(label, fn, maps, close=True, el=el, panel="fields", panelDefaults=defaults)
    o["panelFields"] = field_list
    return o


def follow_distance_btn(name):
    return pap(
        name,
        "TM_DoFollowDistance",
        mapping(("speaker", "speaker"), ("target", "target"), ("static", "distance", name)),
        close=True,
    )


def follow_distance_children():
    return [follow_distance_btn(n) for n in FOLLOW_DIST_NAMES]


def follow_el_not_following():
    return rules(
        g_and(C_NOT_ALL, C_NOT_DUTY, cond("get_faction_rank", "!=", 1, ["currentActor", "DOMActionFollowing"])),
        g_or(C_SLAVE, C_SLAVER),
    )


def follow_el_mode(mode):
    return rules(
        g_and(
            C_NOT_ALL,
            C_NOT_DUTY,
            cond("get_faction_rank", "==", 1, ["currentActor", "DOMActionFollowing"]),
            cond("get_faction_rank", "==", mode, ["currentActor", "DOMFollowMode"]),
        ),
        g_or(C_SLAVE, C_SLAVER),
    )


FOLLOW_PULLS = [
    pull("follow", follow_distance_children(), el=follow_el_not_following()),
    pull("follow: tight", follow_distance_children(), el=follow_el_mode(0)),
    pull("follow: close", follow_distance_children(), el=follow_el_mode(1)),
    pull("follow: short", follow_distance_children(), el=follow_el_mode(2)),
    pull("follow: long", follow_distance_children(), el=follow_el_mode(3)),
]
WALKING_FIELDS = fields_pap(
    "walking",
    "TM_DoWalkingApply",
    [
        {
            "fieldId": "walkType",
            "caption": "type",
            "widget": "select",
            "applyOnChange": True,
            "choices": WALKING_TYPES,
        },
    ],
    {"walkType": "walking"},
    mapping(("speaker", "speaker"), ("target", "target"), ("dynamic", "walkType")),
    el=EL_NOT_DUTY_SLAVE_SLAVER,
)
WALK = pull("walk", [follow("standing", "walk4", "0"), follow("walk on 4", "walk4", "1")])
WALK_FOLLOW = pull("walk", [follow("standing", "follow_walk4", "0"), follow("walk on 4", "follow_walk4", "1")])
WAIT_DIST = pull("distance", [follow(lab, "wait_distance", val) for lab, val in DIST_LABELS])
FOLLOW_DIST = pull("distance", [follow(lab, "distance", val) for lab, val in DIST_LABELS])

POSES = [
    ("chair", "chair"),
    ("light", "light"),
    ("flowers", "flowers"),
    ("drinks", "drinks"),
    ("cute", "cute"),
    ("dance", "dance"),
    ("music", "music"),
    ("submissive", "submissive"),
    ("ass", "ass"),
    ("breasts", "breasts"),
    ("pussy", "pussy"),
]

TIE_POSES = [
    ("kneeling", "0"),
    ("standing", "1"),
    ("laying", "2"),
    ("hogtied", "3"),
    ("struggle rope", "4"),
    ("hands behind back", "5"),
    ("head down", "6"),
    ("random", "random"),
]


def furniture_open(kind):
    return pap(
        kind,
        "TM_ListRestrainVariants",
        mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", kind)),
        close=False,
        el=EL_SLAVE,
        panel="fields",
    )


# --- 0800 order ---
order_opts = [
    named("inventory", "inventory", el=EL_SLAVE_SLAVER),
    *FOLLOW_PULLS,
    named("follow all", "follow", "all", el=EL_ALL),
    WALKING_FIELDS,
    named("stand all", "stand", "all", el=EL_ALL),
    named("wait", "wait", el=EL_NOT_DUTY_SLAVE_SLAVER),
    named("wait all", "wait", "all", el=EL_ALL),
    named("favor", "favor", el=EL_SLAVE_SLAVER),
    named("put in bag", "bag", el=EL_SLAVE),
    order("all in bag", "InBag", flag="slaves", el=EL_ALL),
    order("open bags", "OutBag", flag="bags", el=EL_ALL),
    order("gather bags", "GatherBag", flag="bags", el=EL_ALL),
    pull("pose", [named(lab, "pose", typ, el=EL_SLAVE) for lab, typ in POSES], el=EL_SLAVE),
    named("pose all", "pose", "all", el=EL_ALL),
]
dump(
    "0800_dom_order.json",
    {
        "type": "pulldown",
        "label": "order",
        "source": "dom",
        "requiresPlugin": PLUGIN,
        "eligibilityRules": [g_or(C_ALL, C_SLAVE, C_SLAVER)],
        "options": order_opts,
    },
)

# --- 0810 abuse ---
insults = ["degrading", "dominating", "useless", "demeaning", "disgrace", "worthless"]
flatters = [("sexy", "sexy"), ("dirty", "dirty"), ("friendly", "praise"), ("romance", "romance")]
promises = [
    ("pain", "pain"),
    ("rapture", "rapture"),
    ("sacrifice", "to be sacrificed"),
    ("money", "money"),
    ("freedom", "freedom"),
    ("gentle", "to be gentle"),
]
threats = [
    "running away",
    "being angry",
    "being disrespectful",
    "crying",
    "didnt fight",
    "didnt pose",
    "refusing to masturbate",
    "covering self",
]
drinks = [("skooma", "narcotic"), ("alcohol", "alcohol"), ("love potion", "love"), ("lust potion", "lust"), ("lash potion", "lash"), ("mind potion", "mind")]

COMFORT_SEX_DEFAULTS = {
    "subject": "player",
    "object": "currentActor",
    "objectRelation": "with",
    "andThird": "none",
    "intent": "comfort with sex",
    "direction": "fucking",
    "method": "pussy",
    "style": "normally",
    "settingName": "default",
}
COMFORT_RAPE_DEFAULTS = {
    "subject": "player",
    "object": "currentActor",
    "objectRelation": "to victim",
    "andThird": "none",
    "intent": "pretend to comfort by sexual assault",
    "direction": "fucking",
    "method": "pussy",
    "style": "forcefully",
    "settingName": "punish_pleasure_pain_rape",
}


def comfort_scene_sex():
    maps = mapping(
        ("dynamic", "intent", "comfort with sex"),
        ("speaker", "speaker"),
        ("target", "target"),
        ("dynamic", "style", "forcefully|normally|gently"),
        ("dynamic", "tags", "comma-separated tags"),
        ("dynamic", "direction", "fucking|fucked in"),
        ("dynamic", "setting_name", "scene setting json name"),
    )
    return pap(
        "sex",
        "WebUI_StartScene_Comfort_Sex",
        maps,
        close=True,
        el=EL_SLAVE,
        plugin=PLUGIN,
        script="SkyrimNet_DOM_Actions",
        panel="scene_start",
        panelDefaults=COMFORT_SEX_DEFAULTS,
    )


def comfort_scene_rape():
    maps = mapping(
        ("dynamic", "intent", "pretend to comfort by sexual assault"),
        ("speaker", "speaker"),
        ("target", "target"),
        ("dynamic", "style", "forcefully|normally|gently"),
        ("dynamic", "tags", "comma-separated tags"),
        ("dynamic", "direction", "fucking|fucked in"),
        ("dynamic", "setting_name", "scene setting json name"),
    )
    return pap(
        "rape",
        "WebUI_StartScene_Comfort_Rape",
        maps,
        close=True,
        el=EL_SLAVE,
        plugin=PLUGIN,
        script="SkyrimNet_DOM_Actions",
        panel="scene_start",
        panelDefaults=COMFORT_RAPE_DEFAULTS,
    )

upkeep = [
    pull(
        "bathing",
        [
            named("shower", "shower", el=EL_SLAVE_SLAVER_NPC),
            named("bath me", "bath_me", el=EL_SLAVE_SLAVER_NPC),
            named("bath you", "bath_you", el=EL_SLAVE_SLAVER_NPC),
        ],
        el=EL_SLAVE_SLAVER_NPC,
    ),
    named("look at me", "look", el=EL_SLAVE),
    named("turn around", "turn", el=EL_SLAVE),
    named("come here", "come", el=EL_SLAVE),
    pull(
        "follow actor",
        [],
        el=EL_SLAVE,
        options_from="nearby_actors",
        option_template=pap(
            "follow actor",
            "TM_DoNamed",
            mapping(("speaker", "speaker"), ("target", "target"), ("static", "fn", "follow_actor"), ("optionActor", "type")),
        ),
    ),
    pull("drink", [named(lab, "drink", typ, el=EL_SLAVE) for lab, typ in drinks], el=EL_SLAVE),
    named("mark", "mark", el=EL_SLAVE),
    named("brand", "brand", el=EL_SLAVE),
]

abuse_opts = [
    pap("praise", "TM_ListPraiseReasons", mapping(("speaker", "speaker"), ("target", "target")), close=False, el=EL_SLAVE_SLAVER),
    named("praise all", "praise", "all", el=EL_ALL),
    named("scold", "scold", el=EL_SLAVE_SLAVER),
    named("scold all", "scold", "all", el=EL_ALL),
    pull("insult", [named(t, "insult", t) for t in insults], el=EL_SINGLE),
    named("insult all", "insult", "all", el=EL_ALL),
    pull("flatter", [named(lab, "flatter", typ) for lab, typ in flatters], el=EL_SINGLE),
    named("flatter all", "flatter", "all", el=EL_ALL),
    pull("threaten", [named(t, "threaten", t, el=EL_SLAVE) for t in threats], el=EL_SLAVE),
    named("threaten all", "threaten", "all", el=EL_ALL),
    pull(
        "comfort",
        [
            named("care", "comfort", "care", el=EL_SLAVE),
            named("guilt", "comfort", "guilt", el=EL_SLAVE),
            comfort_scene_sex(),
            comfort_scene_rape(),
            named("pain", "comfort", "pain", el=EL_SLAVE),
            named("threat", "comfort", "threat", el=EL_SLAVE),
            named("insult", "comfort", "insult", el=EL_SLAVE),
        ],
        el=EL_SLAVE,
    ),
    pull("promise", [order(lab, "Promise", typ, el=EL_SLAVE) for lab, typ in promises], el=EL_SLAVE),
    order("promise all (freedom)", "Promise", "freedom", "slaves", el=EL_ALL),
    pull("upkeeping", upkeep, el=EL_SLAVE_SLAVER_NPC),
    pap("punish", "TM_PunishPanelOpen", mapping(("speaker", "speaker"), ("target", "target")), close=False, el=EL_SLAVE, panel="fields"),
    named("shower", "shower", el=EL_NPC),
    named("bath me", "bath_me", el=EL_NPC),
    named("bath you", "bath_you", el=EL_NPC),
    named("hug", "comfort", "care", el=EL_NPC),
    named("feed", "feed", el=EL_NPC),
    follow("walk on 4", "walk4", "1", el=EL_NPC),
]
dump(
    "0810_dom_abuse.json",
    {
        "type": "pulldown",
        "label": "abuse",
        "source": "dom",
        "requiresPlugin": PLUGIN,
        "eligibilityRules": [g_or(C_ALL, C_SLAVE, C_SLAVER, C_NOT_ALL)],
        "options": abuse_opts,
    },
)

# --- 0820 training ---
attention = pull(
    "attention",
    [
        named("stand", "attention", el=EL_SLAVE),
        named("display", "display", el=EL_SLAVE),
        named("salute", "salute", el=EL_SLAVE),
        named("kneel", "kneel", el=EL_SLAVE),
    ],
    el=EL_SLAVE,
)
inspect = pull(
    "inspect",
    [
        named("front", "inspect", "Front", el=EL_SLAVE),
        named("back", "inspect", "Back", el=EL_SLAVE),
        named("floor", "inspect", "Floor", el=EL_SLAVE),
        named("display", "display", el=EL_SLAVE),
    ],
    el=EL_SLAVE,
)
kiss = pull(
    "kiss",
    [
        named("short", "kiss", "Short", el=EL_SLAVE_SLAVER),
        named("loving", "kiss", "Love", el=EL_SLAVE_SLAVER),
        named("long", "kiss", "Long", el=EL_SLAVE_SLAVER),
        named("forced", "kiss", "Forced", el=EL_SLAVE_SLAVER),
        named("dominant", "kiss", "Dominant", el=EL_SLAVE_SLAVER),
        named("side", "kiss", "Side", el=EL_SLAVE_SLAVER),
        named("feed", "kiss", "Vampire", el=EL_SLAVE_SLAVER),
    ],
    el=EL_SLAVE_SLAVER,
)
mast_idle = pull(
    "masturbate",
    [
        pap("standing", "TM_DoMasturbate", mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", "standing"))),
        pap("kneeling", "TM_DoMasturbate", mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", "kneeling"))),
        pap("laying", "TM_DoMasturbate", mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", "laying"))),
    ],
    el=EL_NOT_MAST,
)
mast_active = pull(
    "masturbate",
    [
        pap("stop", "TM_DoMasturbate", mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", "stop"))),
        pap("harder", "TM_DoMasturbate", mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", "harder"))),
    ],
    el=EL_MAST,
)
training_opts = [
    attention,
    named("attention all", "attention", "all", el=EL_ALL),
    named("kneel all", "kneel", "all", el=EL_ALL),
    inspect,
    kiss,
    mast_idle,
    mast_active,
    named("masturbate all", "masturbate", "all", el=EL_ALL),
    scene_sex("sex", EL_SLAVE_SLAVER),
    scene_rape("rape", EL_SLAVE),
]
dump(
    "0820_dom_training.json",
    {
        "type": "pulldown",
        "label": "training",
        "source": "dom",
        "requiresPlugin": PLUGIN,
        "eligibilityRules": [g_or(C_ALL, C_SLAVE, C_SLAVER)],
        "options": training_opts,
    },
)

# --- 0830 restrain ---
cuffs = pull(
    "cuffing",
    [
        restrain("cuffs back", "cuff", "0", el=EL_SLAVE),
        restrain("cuffs front", "cuff", "1", el=EL_SLAVE),
        restrain("cuffs crossed", "cuff", "2", el=EL_SLAVE),
        restrain("cuffs boxtied", "cuff", "3", el=EL_SLAVE),
        restrain("yoke", "cuff", "4", el=EL_SLAVE),
        restrain("armbinder", "cuff", "5", el=EL_SLAVE),
        restrain("uncuff", "uncuff", "", el=EL_SLAVE),
    ],
    el=EL_SLAVE,
)
gags = pull(
    "gag / plug",
    [
        restrain("gag cloth", "gag", "cloth", el=EL_SLAVE),
        restrain("ball gag", "gag", "ball", el=EL_SLAVE),
        restrain("ring gag", "gag", "ring", el=EL_SLAVE),
        restrain("log bit", "gag", "log", el=EL_SLAVE),
        restrain("vaginal plug", "plug", "vaginal", el=EL_SLAVE),
        restrain("anal plug", "plug", "anal", el=EL_SLAVE),
    ],
    el=EL_SLAVE,
)
blinds = pull(
    "blindfold",
    [
        restrain("leather", "blindfold", "0", el=EL_SLAVE),
        restrain("dd", "blindfold", "1", el=EL_SLAVE),
        restrain("black", "blindfold", "2", el=EL_SLAVE),
        restrain("cloth", "blindfold", "3", el=EL_SLAVE),
        restrain("hood", "blindfold", "4", el=EL_SLAVE),
        restrain("db", "blindfold", "5", el=EL_SLAVE),
        restrain("remove", "blindfold", "remove", el=EL_SLAVE),
        restrain("random", "blindfold", "random", el=EL_SLAVE),
    ],
    el=EL_SLAVE,
)
restrain_opts = [
    pull("tie", [restrain(lab, "tie", flag, el=EL_SLAVE) for lab, flag in TIE_POSES], el=EL_SLAVE),
    restrain("untie", "untie", el=EL_SINGLE),
    restrain("tie all", "tie", "all", el=EL_ALL),
    furniture_open("chains"),
    furniture_open("post"),
    furniture_open("cage"),
    furniture_open("cross"),
    furniture_open("pillory"),
    furniture_open("wheel"),
    gags,
    blinds,
    cuffs,
]
dump(
    "0830_dom_restrain.json",
    {
        "type": "pulldown",
        "label": "restrain",
        "source": "dom",
        "requiresPlugin": PLUGIN,
        "eligibilityRules": [g_or(C_ALL, C_SLAVE)],
        "options": restrain_opts,
    },
)

# --- 0840 clothes ---
clothes_opts = [
    named("rip-off", "rip", el=EL_SLAVE),
    named("rip-off everything", "ripall", el=EL_SLAVE),
    named("strip", "strip", el=EL_SLAVE),
    named("strip all (actor)", "stripall", el=EL_SLAVE),
    named("be naked", "naked", el=EL_SLAVE),
    pap("dress", "TM_DoDress", mapping(("speaker", "speaker"), ("target", "target")), el=EL_SLAVE),
    named("re-equip inventory", "equip", el=EL_SLAVE),
    named("no weapons", "noweapons", el=EL_SLAVE),
    named("hold weapons", "weapons", el=EL_SLAVE),
    named("no armor", "noarmor", el=EL_SLAVE),
    named("wear armor", "armor", el=EL_SLAVE),
    named("be naked all", "naked", "all", el=EL_ALL),
    named("wear clothes all", "clothed", "all", el=EL_ALL),
    named("strip all slaves", "strip", "all", el=EL_ALL),
    named("strip entirely all", "stripall", "all", el=EL_ALL),
    named("equip inventory all", "equip", "all", el=EL_ALL),
    named("no weapons all", "noweapons", "all", el=EL_ALL),
    named("no armor all", "noarmor", "all", el=EL_ALL),
]
dump(
    "0840_dom_clothes.json",
    {
        "type": "pulldown",
        "label": "clothes",
        "source": "dom",
        "requiresPlugin": PLUGIN,
        "eligibilityRules": [g_or(C_ALL, C_SLAVE)],
        "options": clothes_opts,
    },
)

# --- 0850 management ---
mgmt_opts = [
    trainer("list trainees", "list", el=EL_TRAINER),
    trainer("set base camp", "camp", el=EL_TRAINER),
    trainer("go to base / travel", "travel", el=EL_TRAINER),
    trainer("guard here", "guard", el=EL_TRAINER),
    trainer("gather trainees", "gather", el=EL_TRAINER),
    pull(
        "add trainee",
        [],
        el=EL_TRAINER,
        options_from="nearby_actors",
        option_template=trainer("add trainee", "add"),
    ),
    pull(
        "unload trainee",
        [],
        el=EL_TRAINER,
        options_from="nearby_actors",
        option_template=trainer("unload trainee", "unload_one"),
    ),
    trainer("unload all trainees", "unload_all", el=EL_TRAINER),
]
# fix add/unload templates to use optionActor for otherId
mgmt_opts[5]["optionTemplate"] = pap(
    "add trainee",
    "TM_DoTrainer",
    mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", "add"), ("optionActor", "otherId")),
)
mgmt_opts[6]["optionTemplate"] = pap(
    "unload trainee",
    "TM_DoTrainer",
    mapping(("speaker", "speaker"), ("target", "target"), ("static", "kind", "unload_one"), ("optionActor", "otherId")),
)
dump(
    "0850_dom_management.json",
    {
        "type": "pulldown",
        "label": "management",
        "source": "dom",
        "requiresPlugin": PLUGIN,
        "eligibilityRules": [g_or(C_TRAINER, C_SLAVER)],
        "options": mgmt_opts,
    },
)

# --- 0860 trainees ---
trainee_opts = [
    trainer("display trainees", "display", el=EL_TRAINER),
    trainer("tie-up trainees", "tie", el=EL_TRAINER),
    trainer("chain trainees", "chain", el=EL_TRAINER),
    trainer("restrain trainees", "restrain", el=EL_TRAINER),
    trainer("masturbate trainees", "masturbate", el=EL_TRAINER),
    trainer("punish trainees", "punish", el=EL_TRAINER),
    trainer("rape trainees", "rape", el=EL_TRAINER),
    trainer("orgy", "orgy", el=EL_TRAINER),
]
dump(
    "0860_dom_trainees.json",
    {
        "type": "pulldown",
        "label": "trainees",
        "source": "dom",
        "requiresPlugin": PLUGIN,
        "eligibilityRules": [g_or(C_TRAINER, C_SLAVER)],
        "options": trainee_opts,
    },
)

# --- 0870 services ---
svc_opts = [
    scene_rape("rape slave", EL_NPC),
    scene_sex("sex with", EL_NPC),
    scene_sex("player 3some", EL_NPC),
    named("re-equip inventory", "equip", el=EL_NPC),
    named("equip no clothes", "naked", el=EL_NPC),
]
# tweak 3some defaults
svc_opts[2] = pap(
    "player 3some",
    "StartScene_Consensual_Two",
    SCENE_MAP,
    close=True,
    el=EL_NPC,
    plugin=SL_PLUGIN,
    script=SL_SCRIPT,
    panel="scene_start",
    panelDefaults={**SEX_DEFAULTS, "andThird": "and", "subject": "currentActor", "object": "player"},
)
dump(
    "0870_dom_services.json",
    {
        "type": "pulldown",
        "label": "services",
        "source": "dom",
        "requiresPlugin": PLUGIN,
        "eligibilityRules": [g_and(C_NOT_ALL, C_NOT_SLAVE, C_NOT_SLAVER)],
        "options": svc_opts,
    },
)

# --- 0880 sack ---
sack = pap(
    "sack",
    "TM_ListSackOptions",
    mapping(("speaker", "speaker"), ("target", "target")),
    close=False,
)
sack["source"] = "dom"
sack["requiresPlugin"] = PLUGIN
sack["eligibilityRules"] = [g_or(C_ALL, C_NOT_ALL)]
dump("0880_dom_sack.json", sack)

print("done")
