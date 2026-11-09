Scriptname SkyrimNet_DOM_Obedience Hidden
import SkyrimNet_SexLab_Utilities

; Returns:
;  -1 ungated / native missing (caller executes and may OrderNarration)
;   0 refused (do not execute; refuse DN already emitted)
;   1 obeyed, unified DN already emitted
;   2 obeyed sex, order RegisterEvent already emitted (SexLab DN owns the scene)

Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_API.Trace_Helper("SkyrimNet_DOM_Obedience", func, msg, Notification)
EndFunction

Bool Function NativeReady() global
    return SKSE.GetPluginVersion("SkyrimNet_DOM") > 0
EndFunction

Bool Function ShouldSkipEventNarration(Actor slave) global
    if !slave
        return false
    endif
    if !NativeReady()
        return false
    endif
    return SkyrimNet_DOM_Native.ShouldSkipEventNarration(slave)
EndFunction

; rollObedience=false: LLM actions already decided the slave obeys; skip DOM WillObey.
Int Function TryOrder(Actor superior, Actor slave, String kind, String actionDesc, Bool rollObedience = true) global
    if !slave
        return -1
    endif
    ; An order during a bath moves or re-animates the slave and breaks the scene.
    if SkyrimNet_DOM_Bath.IsDriven(slave)
        Trace("TryOrder", GetDisplayName(slave)+" is in a bath, ignoring kind="+kind)
        return 0
    endif
    if !NativeReady()
        return -1
    endif
    int mode = SkyrimNet_DOM_Native.KindMode(kind)
    if mode <= 0
        return -1
    endif
    if !superior
        superior = Game.GetPlayer()
    endif
    if actionDesc == ""
        actionDesc = kind
    endif

    SkyrimNet_DOM_Native.ArmSkip(slave, 4000)

    DOM_Actor da = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Obedience", "TryOrder", slave, false)
    Bool obeyed = true
    if rollObedience && da && da.mind
        int reason = SkyrimNet_DOM_Native.KindReason(kind)
        int facet = SkyrimNet_DOM_Native.KindFacet(kind)
        int training = SkyrimNet_DOM_Native.KindTraining(kind)
        ; pass all 6 args: DOM added choose_not, and defaults are filled at our compile time
        obeyed = da.mind.WillObey(reason, facet, training, 1.0, false, true)
        if !obeyed
            da.ChooseAnswerNo(superior)
        endif
    endif

    String superiorName = GetDisplayName(superior)
    String slaveName = GetDisplayName(slave)
    if !obeyed
        String refuseMsg = SkyrimNet_DOM_Native.MakeRefuseNarration(superiorName, slaveName, actionDesc)
        DirectNarration(refuseMsg, slave, superior)
        RegisterRefusePunishment(superior, slave, actionDesc)
        Trace("TryOrder", slaveName+" refused kind="+kind+" "+actionDesc)
        return 0
    endif

    SkyrimNet_DOM_Actions act = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Actions
    if mode == 2
        String sexMsg = SkyrimNet_DOM_Native.MakeSexOrderEvent(superiorName, slaveName, actionDesc)
        SkyrimNetApi.RegisterEvent("Order", sexMsg, superior, slave)
        if act
            act.RegisterObeyCommand(slave, superior, actionDesc)
        endif
        Trace("TryOrder", slaveName+" sex order kind="+kind+" "+actionDesc)
        return 2
    endif

    String obeyMsg = SkyrimNet_DOM_Native.MakeObeyNarration(superiorName, slaveName, actionDesc)
    ; source=superior so DN attribution matches "{superior} orders {slave}…"
    DirectNarration(obeyMsg, superior, slave)
    if act
        act.RegisterObeyCommand(slave, superior, actionDesc)
    endif
    Trace("TryOrder", slaveName+" obeyed kind="+kind+" "+actionDesc)
    return 1
EndFunction

Function RegisterRefusePunishment(Actor superior, Actor slave, String actionDesc) global
    if !slave
        return
    endif
    String slaveName = GetDisplayName(slave)
    String superiorName = GetDisplayName(superior)
    String msg = slaveName+" refused to obey "+superiorName+"'s command to "+actionDesc+", this will be punished."
    SkyrimNetApi.RegisterEvent("Reason to Punish", msg, slave, superior)
EndFunction

; LLM orders: the LLM already chose to obey, but DOM's action handlers (e.g. SetShouldBeRespectful) roll WillObey
; again. Inside the timer WillObey takes its IsObedient branch. 10 is what DOM sets after a successful roll.
Function PassDomRoll(Actor slave) global
    if !slave
        return
    endif
    DOM_Actor da = SkyrimNet_DOM_API.GetSlave("SkyrimNet_DOM_Obedience", "PassDomRoll", slave, false)
    if da && da.mind
        da.mind.SetObedientTimer(10)
        Trace("PassDomRoll", GetDisplayName(slave)+" obedient timer armed")
    endif
EndFunction

; Estimated percent chance DOM_Mind.WillObey refuses this kind of order, -1 if unknown. Must stay free of side
; effects, so it never calls WillObey. Ignores the "remembers the punishment/warning" second chances.
Int Function RefusePercent(DOM_Mind mind, String kind) global
    if !mind || !NativeReady()
        return -1
    endif
    int ifacet = SkyrimNet_DOM_Native.KindFacet(kind)
    int itraining = SkyrimNet_DOM_Native.KindTraining(kind)
    Float[] facets
    int idx
    ; Same indexing as WillObey, which is not symmetric between the two arrays.
    if ifacet > 0
        facets = mind.HEXACO_InverseFacets
        idx = ifacet - 1
    else
        facets = mind.HEXACO_Facets
        idx = -ifacet + 1
    endif
    Float[] training = mind.TRAINING_Stats
    if !facets || !training || idx < 0 || idx >= facets.length || itraining < 0 || itraining >= training.length
        return -1
    endif
    Float chance = facets[idx] * (1.0 - training[itraining] / 100.0)
    if chance < 0.0
        chance = 0.0
    elseif chance > 1.0
        chance = 1.0
    endif
    Float moodChance = chance * mind.MoodReactionFactor()
    if moodChance < 0.0
        moodChance = 0.0
    elseif moodChance > 1.0
        moodChance = 1.0
    endif
    Float refuse = chance + (1.0 - chance) * moodChance
    return (refuse * 100.0 + 0.5) as Int
EndFunction

String Function RefuseLevel(Int percent) global
    if percent < 0
        return "unknown"
    elseif percent < 15
        return "trained"
    elseif percent < 40
        return "reluctant"
    elseif percent < 70
        return "resistant"
    endif
    return "defiant"
EndFunction

String Function AddLikelyRefusal(String list, DOM_Mind mind, String kind, String label) global
    if RefusePercent(mind, kind) < 50
        return list
    endif
    if list == ""
        return label
    endif
    return list+", "+label
EndFunction

; Writes actor_obj.obedience for the final instructions.
; Timer-gated moods override both IsObedient and MoodReactionFactor, so a factor above 0 means IsObedient only
; reflects a recent obeyed order. Those moods report their underlying odds, or the prompt would turn every order
; the LLM obeys into standing compliance.
Function FillObedience(Int actor_obj, DOM_Mind mind) global
    Float moodFactor = mind.MoodReactionFactor()
    Bool alwaysObeys = mind.IsObedient() && moodFactor <= 0.0
    Int percent = 0
    String level = "obedient"
    String likely = ""
    if !alwaysObeys
        percent = RefusePercent(mind, "generic")
        level = RefuseLevel(percent)
        likely = AddLikelyRefusal(likely, mind, "sex", "sexual orders")
        likely = AddLikelyRefusal(likely, mind, "respectful", "showing respect")
        likely = AddLikelyRefusal(likely, mind, "naked", "undressing")
        likely = AddLikelyRefusal(likely, mind, "pose", "posing")
    endif
    Int obedience = JMap.object()
    JMap.setObj(actor_obj, "obedience", obedience)
    JMap.setStr(obedience, "mood", mind.mood)
    JMap.setInt(obedience, "always_obeys", alwaysObeys as Int)
    JMap.setStr(obedience, "level", level)
    JMap.setInt(obedience, "refuse_pct", percent)
    JMap.setStr(obedience, "likely_refuses", likely)
EndFunction

; First method/tag token; skip style/direction leftovers from older concatenations.
String Function FirstSexToken(String raw) global
    if raw == ""
        return "sex"
    endif
    String s = raw
    int comma = StringUtil.Find(s, ",")
    if comma >= 0
        s = StringUtil.Substring(s, 0, comma)
    endif
    String[] parts = StringUtil.Split(s, " ")
    if !parts
        return "sex"
    endif
    int i = 0
    while i < parts.length
        String token = parts[i]
        if token != "" && token != "normally" && token != "forcefully" && token != "gently"
            if token != "forceful" && token != "normal" && token != "gentle"
                if token != "fucking" && token != "fucked" && token != "in" && token != "getting" && token != "giving"
                    if token != "with" && token != "have"
                        return token
                    endif
                endif
            endif
        endif
        i += 1
    endwhile
    return "sex"
EndFunction

String Function MapSexType(String token) global
    if token == "" || token == "sex"
        return "sex"
    endif
    if token == "vaginal" || token == "pussy"
        return "vaginal sex"
    endif
    if token == "oral" || token == "mouth" || token == "blowjob" || token == "cunnilingus"
        return "oral sex"
    endif
    if token == "anal" || token == "ass"
        return "anal sex"
    endif
    if StringUtil.Find(token, "sex") >= 0
        return token
    endif
    if token == "handjob" || token == "boobjob" || token == "thighjob" || token == "footjob"
        return token
    endif
    if token == "fingering" || token == "dildo" || token == "fisting"
        return token
    endif
    return token+" sex"
EndFunction

; "have vaginal sex with Bob" — drop style; partner is the other participant.
String Function FormatSexCommand(String methodOrTags, Actor partner) global
    if methodOrTags != "" && StringUtil.GetLength(methodOrTags) >= 5
        String prefix = StringUtil.Substring(methodOrTags, 0, 5)
        if prefix == "have "
            return methodOrTags
        endif
    endif
    String mapped = MapSexType(FirstSexToken(methodOrTags))
    String phrase = "have "+mapped
    if partner
        String partnerName = GetDisplayName(partner)
        if partnerName != ""
            phrase += " with "+partnerName
        endif
    endif
    return phrase
EndFunction

; Prefer superior when they are in the scene; else first other actor.
Actor Function SexCommandPartner(Actor ordered, Actor superior, Actor speaker, Actor target, Actor participate=None) global
    Actor partner = None
    Bool sawSuperior = false
    if target && target != ordered
        partner = target
        if target == superior
            sawSuperior = true
        endif
    endif
    if speaker && speaker != ordered
        if speaker == superior
            partner = speaker
            sawSuperior = true
        elseif !sawSuperior && !partner
            partner = speaker
        endif
    endif
    if participate && participate != ordered
        if participate == superior
            partner = participate
            sawSuperior = true
        elseif !sawSuperior && !partner
            partner = participate
        endif
    endif
    if !partner && superior && superior != ordered
        partner = superior
    endif
    return partner
EndFunction

; Scene Creator / cast gate: prefer non-player DOM slave among actors.
; Returns 0 refuse, else proceed (-1 ungated / no slave / missing DLL).
Int Function TryOrderSexCast(Actor superior, Actor[] actors, String actionDesc) global
    if !actors
        return -1
    endif
    if !superior
        superior = Game.GetPlayer()
    endif
    Actor ordered = None
    int i = 0
    while i < actors.length
        Actor ak = actors[i]
        if ak && ak != superior && SkyrimNet_DOM_API.IsDOMSlave(ak)
            ordered = ak
            i = actors.length
        endif
        i += 1
    endwhile
    if !ordered
        i = 0
        while i < actors.length
            Actor ak = actors[i]
            if ak && SkyrimNet_DOM_API.IsDOMSlave(ak)
                ordered = ak
                i = actors.length
            endif
            i += 1
        endwhile
    endif
    if !ordered
        Trace("TryOrderSexCast", "no DOM slave in cast")
        return -1
    endif
    Actor partner = None
    Bool sawSuperior = false
    i = 0
    while i < actors.length
        Actor ak = actors[i]
        if ak && ak != ordered
            if ak == superior
                partner = ak
                sawSuperior = true
            elseif !sawSuperior && !partner
                partner = ak
            endif
        endif
        i += 1
    endwhile
    if !partner && superior && superior != ordered
        partner = superior
    endif
    return TryOrder(superior, ordered, "sex", FormatSexCommand(actionDesc, partner))
EndFunction
