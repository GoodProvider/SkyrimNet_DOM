Scriptname SkyrimNet_DOM_InfoPanel hidden

; DOM Info MainPanel (SkyrimNet_SexLab ControlPanel view, type actor_profile).
; Same information and role rules as PrismaUI-for-DOM's profile panel
; (DOMPrismController BuildStats / BuildAdditionalInfo / BuildDiaryNotif):
;   any role with a mind: status (or School), mood, recs, personality, events
;   slave + trainer:      + Training, Love (+ Enjoyment when dom.info.show_enjoyment)
;   trainer + slaver:     + Slaver Skills
;   free person (no mind): personality from DOM_Generator.GetNPCTraits
; Payload contract: SkyrimNet_SexLab docs/developers/webui.md (actor_profile).

Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_API.Trace_Helper("SkyrimNet_DOM_InfoPanel", func, msg, Notification)
EndFunction

String Function BuildPanelJson(DOM_Core core, SkyrimNet_DOM_Events events, Actor akActor, Bool showEnjoyment = false) global
    int root = JMap.object()
    JMap.setStr(root, "panel", "actor_profile")
    JMap.setStr(root, "id", "dom_info")
    JMap.setStr(root, "label", "DOM Info")

    if core == None
        JMap.setStr(root, "empty", "Diary of Mine is not loaded.")
        return Finish(root)
    endif
    if akActor == None
        JMap.setStr(root, "empty", "Pick a single actor to see their DOM profile.")
        return Finish(root)
    endif

    String name = akActor.GetDisplayName()
    JMap.setStr(root, "name", name)

    String mode = ResolveMode(core, akActor)
    JMap.setStr(root, "subtitle", ModeSubtitle(mode))

    int pills = JArray.object()
    JMap.setObj(root, "pills", pills)
    int sections = JArray.object()
    JMap.setObj(root, "sections", sections)

    DOM_Mind mind = core.GetActorMind(akActor)
    Bool skills = (mode == "trainer" || mode == "slaver")

    if mind
        if skills
            int dom = DominantSkill(mind, core, akActor)
            AddPill(pills, "School", SkillSchool(dom), SkillMethod(dom), "status")
        elseif mode == "slaver"
            AddPill(pills, "Status", mind.GetSlaverStatusName(), "", "status")
        else
            AddPill(pills, "Status", mind.GetTrainingStatusName(), "", "status")
        endif
        String mood = mind.GetMoodName()
        AddPill(pills, "Mood", mood, "", "mood")
        AddRecs(sections, mood, name)
        AddPersonalityFromMind(sections, mind)
        if mode == "slave" || mode == "trainer"
            AddTrainingLove(sections, mind)
            if showEnjoyment && events && events.handler
                AddEnjoyment(sections, mind, events.handler, akActor)
            endif
        endif
    elseif mode == "npc"
        AddPersonalityFromTraits(sections, core, akActor)
    endif

    if skills
        AddSlaverSkills(sections, mind, core, akActor)
    endif

    AddEvents(sections, mind, events, akActor)
    AddAdditionalInfo(sections, core, mind, akActor, name)
    return Finish(root)
EndFunction

String Function Finish(int root) global
    String json = SkyrimNet_SexLab_Utilities.ObjectToLowerCaseKeyJson(root)
    JValue.release(root)
    return json
EndFunction

; Slaver faction before slave faction; slave rank 2 = trainer (DOMDoCallMenu parity).
String Function ResolveMode(DOM_Core core, Actor akActor) global
    if core.DOMPlayerSlaverFaction && akActor.IsInFaction(core.DOMPlayerSlaverFaction)
        return "slaver"
    endif
    if core.DOMPlayerSlaveFaction && akActor.IsInFaction(core.DOMPlayerSlaveFaction)
        if akActor.GetFactionRank(core.DOMPlayerSlaveFaction) == 2
            return "trainer"
        endif
        return "slave"
    endif
    return "npc"
EndFunction

String Function ModeSubtitle(String mode) global
    if mode == "slaver"
        return "Slaver"
    elseif mode == "trainer"
        return "Trainer"
    elseif mode == "slave"
        return "Slave"
    endif
    return "Free person"
EndFunction

; ---- JSON helpers ----

Function AddPill(int pills, String label, String value, String tip, String kind) global
    if value == ""
        return
    endif
    int p = JMap.object()
    JMap.setStr(p, "label", label)
    JMap.setStr(p, "value", value)
    if tip != ""
        JMap.setStr(p, "tip", tip)
    endif
    JMap.setStr(p, "kind", kind)
    JArray.addObj(pills, p)
EndFunction

; Returns the section's items (or axes) array.
int Function AddSection(int sections, String type, String title, String tone, String listKey = "items") global
    int s = JMap.object()
    JMap.setStr(s, "type", type)
    if title != ""
        JMap.setStr(s, "title", title)
    endif
    if tone != ""
        JMap.setStr(s, "tone", tone)
    endif
    int items = JArray.object()
    JMap.setObj(s, listKey, items)
    JArray.addObj(sections, s)
    return items
EndFunction

; text (optional) is shown instead of the number; the fill still uses value.
Function AddBar(int items, String label, Float value, String text = "") global
    int b = JMap.object()
    JMap.setStr(b, "label", label)
    JMap.setInt(b, "value", Math.Floor(value))
    if text != ""
        JMap.setStr(b, "text", text)
    endif
    JArray.addObj(items, b)
EndFunction

; Two decimals ("1.25"); Papyrus float-to-string prints six.
String Function Fmt2(Float x) global
    String sign = ""
    if x < 0.0
        sign = "-"
        x = -x
    endif
    int cents = Math.Floor(x * 100.0 + 0.5)
    int whole = cents / 100
    int frac = cents % 100
    if frac < 10
        return sign + whole + ".0" + frac
    endif
    return sign + whole + "." + frac
EndFunction

Function AddTrait(int axes, String lo, String hi, String pol, Float value) global
    int a = JMap.object()
    JMap.setStr(a, "lo", lo)
    JMap.setStr(a, "hi", hi)
    JMap.setStr(a, "pol", pol)
    JMap.setInt(a, "value", Math.Floor(value))
    JArray.addObj(axes, a)
EndFunction

int Function AddRadar(int sections, String title, String tone, String radarMode) global
    int axes = AddSection(sections, "radar", title, tone, "axes")
    int s = JArray.getObj(sections, JArray.count(sections) - 1)
    JMap.setStr(s, "mode", radarMode)
    return axes
EndFunction

; ---- Personality (HEXACO + PRISM, one 12-axis bipolar web) ----

Function AddPersonalityFromMind(int sections, DOM_Mind m) global
    float[] t = new float[12]
    t[0] = m.HEXACO_Honesty
    t[1] = m.HEXACO_Emotionality
    t[2] = m.HEXACO_eXtraversion
    t[3] = m.HEXACO_Agreeableness
    t[4] = m.HEXACO_Conscientiousness
    t[5] = m.HEXACO_Openness
    t[6] = m.PRISM_Wilfulness
    t[7] = m.PRISM_Toughness
    t[8] = m.PRISM_Sensuality
    t[9] = m.PRISM_Submissivity
    t[10] = m.PRISM_Boldness
    t[11] = m.PRISM_Smartness
    AddPersonality(sections, t)
EndFunction

; GetNPCTraits order: 6 HEXACO, then wilfulness, toughness, sensuality, submissivity, boldness, smartness.
Function AddPersonalityFromTraits(int sections, DOM_Core core, Actor akActor) global
    if !core.DOMGenerator
        return
    endif
    float[] t = core.DOMGenerator.GetNPCTraits(akActor)
    if !t || t.Length < 12
        return
    endif
    AddPersonality(sections, t)
EndFunction

; Axis order and pole labels match Prisma ALL_TRAITS.
Function AddPersonality(int sections, float[] t) global
    int axes = AddRadar(sections, "Personality", "gold", "bipolar")
    AddTrait(axes, "Unlawful", "Honest", "pos", t[0])
    AddTrait(axes, "Calm", "Anxious", "neg", t[1])
    AddTrait(axes, "Shy", "Lively", "pos", t[2])
    AddTrait(axes, "Grumpy", "Kind", "pos", t[3])
    AddTrait(axes, "Lazy", "Thorough", "pos", t[4])
    AddTrait(axes, "Shallow", "Open", "pos", t[5])
    AddTrait(axes, "Needy", "Bold", "pos", t[10])
    AddTrait(axes, "Weak", "Wilful", "pos", t[6])
    AddTrait(axes, "Stupid", "Smart", "pos", t[11])
    AddTrait(axes, "Delicate", "Tough", "pos", t[7])
    AddTrait(axes, "Frigid", "Sensual", "pos", t[8])
    AddTrait(axes, "Dominant", "Submissive", "pos", t[9])
EndFunction

; ---- Training + Love bars (slave + trainer) ----

Function AddTrainingLove(int sections, DOM_Mind m) global
    int tr = AddSection(sections, "bars", "Training", "steel")
    AddBar(tr, "Submission", m.submission)
    AddBar(tr, "Fear", m.fear_training)
    AddBar(tr, "Humiliation", m.humiliation)
    AddBar(tr, "Anger", m.anger_training)
    AddBar(tr, "Resignation", m.resignation)
    AddBar(tr, "Respect", m.respect_training)
    AddBar(tr, "Sex", m.sex_training)
    AddBar(tr, "Vaginal", m.vaginal_training)
    AddBar(tr, "Anal", m.anal_training)
    AddBar(tr, "Oral", m.oral_training)
    AddBar(tr, "Pose", m.pose_training)
    AddBar(tr, "House", m.house_training)
    AddBar(tr, "Work", m.work_training)
    AddBar(tr, "Combat", m.combat_training * 100.0 / 127.0)

    int lv = AddSection(sections, "bars", "Love", "rose")
    AddBar(lv, "Desire", m.love_desire)
    AddBar(lv, "Worship", m.loyal_worship)
    AddBar(lv, "Fascination", m.love_fascination)
    AddBar(lv, "Absolution", m.loyal_absolution)
    AddBar(lv, "Devotion", m.loyal_devotion)
    AddBar(lv, "Admiration", m.love_admiration)
EndFunction

; ---- Enjoyment (slave + trainer, opt-in): the terms of Handler_DOM.EstimateChance, the
; per-roll chance and the HUD's DOM meter (Handler_DOM.OrgasmMeter), so the numbers match the HUD.

Function AddEnjoyment(int sections, DOM_Mind m, SkyrimNet_SexLab_Handler_DOM handler, Actor akActor) global
    int en = AddSection(sections, "bars", "Enjoyment", "rose")
    AddBar(en, "Arousal", m.arousal_factor)

    String aroused = "No"
    Float arousedFill = 0.0
    if handler.IsRefractory(m, akActor)
        aroused = "Refractory"
    elseif m.is_aroused_for > 0
        aroused = "Yes"
        arousedFill = 100.0
    endif
    AddBar(en, "Aroused", arousedFill, aroused)

    Float act = m.MOD_Vaginal
    if m.MOD_Anal > act
        act = m.MOD_Anal
    endif
    if m.MOD_Oral > act
        act = m.MOD_Oral
    endif
    if m.DOM01 && m.DOM01.DOMSexlab && m.DOM01.DOMSexlab.separateOrgasmToggle
        act = 1000.0
    endif
    AddBar(en, "Best act modifier", act * 50.0, "x" + Fmt2(act))
    AddBar(en, "Orgasm modifier", m.MOD_Orgasm * 50.0, "x" + Fmt2(m.MOD_Orgasm))
    Float bonus = m.getArousalBonus()
    AddBar(en, "Mood bonus", bonus * 200.0, "+" + Fmt2(bonus))
    AddBar(en, "Past orgasms", m.number_of_orgasm, "" + m.number_of_orgasm)
    AddBar(en, "Submission", m.submission)
    AddBar(en, "Desire", m.love_desire)

    Float chance = handler.EstimateChance(m, akActor)
    if chance < 0.0
        chance = 0.0
    elseif chance > 1.0
        chance = 1.0
    endif
    AddBar(en, "Orgasm chance", chance * 100.0, Math.Floor(chance * 100.0 + 0.5) + "%")
    AddBar(en, "Enjoyment", handler.OrgasmMeter(akActor))
EndFunction

; ---- Slaver skills (trainer + slaver): mind values, faction ranks without a mind ----

Float[] Function SlaverSkillValues(DOM_Mind m, DOM_Core core, Actor akActor) global
    Float[] v = new Float[6]
    if m
        v[0] = m.skill_enforcer
        v[1] = m.skill_persuader
        v[2] = m.skill_depraver
        v[3] = m.skill_predator
        v[4] = m.skill_slaver
        v[5] = m.skill_deceiver
        return v
    endif
    v[0] = SkillRank(akActor, core.DOMSkillEnforcer)
    v[1] = SkillRank(akActor, core.DOMSkillPersuader)
    v[2] = SkillRank(akActor, core.DOMSkillDepraver)
    v[3] = SkillRank(akActor, core.DOMSkillPredator)
    v[4] = SkillRank(akActor, core.DOMSkillSlaver)
    v[5] = SkillRank(akActor, core.DOMSkillDeceiver)
    return v
EndFunction

Float Function SkillRank(Actor akActor, Faction f) global
    if !f
        return 0.0
    endif
    int r = akActor.GetFactionRank(f)
    if r < 0
        return 0.0
    endif
    return r as Float
EndFunction

Function AddSlaverSkills(int sections, DOM_Mind m, DOM_Core core, Actor akActor) global
    Float[] v = SlaverSkillValues(m, core, akActor)
    int axes = AddRadar(sections, "Slaver Skills", "blue", "unipolar")
    int i = 0
    while i < 6
        AddBar(axes, SkillLabel(i), v[i])
        i += 1
    endwhile
EndFunction

String Function SkillLabel(int i) global
    if i == 0
        return "Enforcer"
    elseif i == 1
        return "Persuader"
    elseif i == 2
        return "Depraver"
    elseif i == 3
        return "Predator"
    elseif i == 4
        return "Slaver"
    endif
    return "Deceiver"
EndFunction

; Highest skill index; ties keep the first (enforcer), like Prisma dominantSkill.
int Function DominantSkill(DOM_Mind m, DOM_Core core, Actor akActor) global
    Float[] v = SlaverSkillValues(m, core, akActor)
    int best = 0
    int i = 1
    while i < 6
        if v[i] > v[best]
            best = i
        endif
        i += 1
    endwhile
    return best
EndFunction

String Function SkillSchool(int i) global
    if i == 0
        return "Pain"
    elseif i == 1
        return "Fear"
    elseif i == 2
        return "Depravity"
    elseif i == 3
        return "Predation"
    elseif i == 4
        return "Commerce"
    endif
    return "Deception"
EndFunction

String Function SkillMethod(int i) global
    if i == 0
        return "Breaks slaves through pain and forced submission."
    elseif i == 1
        return "Breaks slaves through intimidation and terror."
    elseif i == 2
        return "Trains via sex, humiliation and depravity."
    elseif i == 3
        return "Specializes in capturing and hunting slaves."
    elseif i == 4
        return "Trains slaves for trade and sale."
    endif
    return "Breaks slaves through brainwashing and deceit."
EndFunction

; ---- Recommendations (Prisma spike-data MOOD_TIPS + ACTION_GRAMMAR) ----

; Mood display name -> tip code: letters only, then the display-name aliases.
String Function MoodKey(String mood) global
    String k = ""
    int n = StringUtil.GetLength(mood)
    int i = 0
    while i < n
        String c = StringUtil.GetNthChar(mood, i)
        if StringUtil.IsLetter(c)
            k += c
        endif
        i += 1
    endwhile
    if k == "inshock"
        return "shocked"
    elseif k == "nothappy"
        return "depressed"
    elseif k == "annoyed"
        return "jealous"
    elseif k == "outraged"
        return "defiant"
    elseif k == "offended"
        return "proud"
    endif
    return k
EndFunction

; Comma list of action[:type], highest priority first.
String Function MoodTips(String moodCode) global
    if moodCode == "afraid"
        return "sex:vaginal,pain"
    elseif moodCode == "terrified"
        return "sex:vaginal,rape:vaginal"
    elseif moodCode == "scared"
        return "sex:vaginal"
    elseif moodCode == "proud"
        return "sex,rape,pain"
    elseif moodCode == "ashamed"
        return "sex,rape,scold,praise"
    elseif moodCode == "angry"
        return "sex:anal,pain"
    elseif moodCode == "defiant"
        return "rape,scold"
    elseif moodCode == "crushed"
        return "sex:oral,rape:oral,pain,scold"
    elseif moodCode == "sad"
        return "sex:oral,pain,praise"
    elseif moodCode == "shocked"
        return "sex"
    elseif moodCode == "loyal"
        return "pain,scold,praise"
    elseif moodCode == "inlove"
        return "sex,rape,scold,praise"
    elseif moodCode == "depressed"
        return "sex:oral,pain,scold"
    elseif moodCode == "insecure"
        return "sex:vaginal,rape:vaginal,praise"
    elseif moodCode == "jealous"
        return "sex:anal,rape:anal"
    endif
    return ""
EndFunction

String Function TipSentence(String tip, String name) global
    String act = tip
    String typ = ""
    int colon = StringUtil.Find(tip, ":")
    if colon >= 0
        act = StringUtil.Substring(tip, 0, colon)
        typ = StringUtil.Substring(tip, colon + 1)
    endif
    String adverb = ""
    if typ != ""
        adverb = " " + typ + "ly"
    endif
    if act == "praise"
        return "You should praise " + name
    elseif act == "sex"
        return "You should have sex with " + name + adverb
    elseif act == "rape"
        return "You should rape " + name + adverb
    elseif act == "pain"
        return "You should inflict pain on " + name
    elseif act == "scold"
        return "You should scold " + name
    endif
    return ""
EndFunction

Function AddRecs(int sections, String mood, String name) global
    String tips = MoodTips(MoodKey(mood))
    if tips == ""
        return
    endif
    String[] parts = StringUtil.Split(tips, ",")
    int items = AddSection(sections, "recs", "Recommended", "")
    int i = 0
    while i < parts.Length && i < 3
        String line = TipSentence(parts[i], name)
        if line != ""
            JArray.addStr(items, line)
        endif
        i += 1
    endwhile
EndFunction

; ---- Events: last 3 diary memories + last 3 live notifications, oldest -> newest ----

Function AddEvents(int sections, DOM_Mind m, SkyrimNet_DOM_Events events, Actor akActor) global
    Float[] ts = new Float[6]
    String[] txt = new String[6]
    Bool[] diary = new Bool[6]
    int n = 0

    if m
        int entries = m.memory_entries
        int i = entries - 3
        if i < 0
            i = 0
        endif
        while i < entries
            String evtText = m.memory_abuse_txt[i]
            if evtText == ""
                evtText = m.memory_abuse_type[i]
                if m.memory_abuse_reason[i] != ""
                    evtText = evtText + " for " + m.memory_abuse_reason[i]
                endif
            endif
            if m.memory_abuse_ntimes[i] > 1
                evtText = evtText + " (x" + m.memory_abuse_ntimes[i] + ")"
            endif
            if evtText != ""
                ts[n] = m.memory_abuse_time[i]
                txt[n] = evtText
                diary[n] = true
                n += 1
            endif
            i += 1
        endwhile
    endif

    if events
        int notes = events.GetNotifications(akActor)
        if notes
            int count = JArray.count(notes)
            int j = count - 3
            if j < 0
                j = 0
            endif
            while j < count
                int note = JArray.getObj(notes, j)
                String msg = JMap.getStr(note, "message", "")
                if msg != ""
                    ts[n] = JMap.getFlt(note, "timestamp", 0.0)
                    txt[n] = msg
                    diary[n] = false
                    n += 1
                endif
                j += 1
            endwhile
        endif
    endif

    if n == 0
        return
    endif

    ; Insertion sort by game time, oldest first.
    int a = 1
    while a < n
        Float kt = ts[a]
        String kx = txt[a]
        Bool kd = diary[a]
        int b = a - 1
        while b >= 0 && ts[b] > kt
            ts[b + 1] = ts[b]
            txt[b + 1] = txt[b]
            diary[b + 1] = diary[b]
            b -= 1
        endwhile
        ts[b + 1] = kt
        txt[b + 1] = kx
        diary[b + 1] = kd
        a += 1
    endwhile

    int items = AddSection(sections, "events", "Events", "")
    Float now = Utility.GetCurrentGameTime()
    int k = 0
    while k < n
        int e = JMap.object()
        JMap.setStr(e, "text", CapFirst(txt[k]))
        JMap.setStr(e, "ago", AgoText(now - ts[k], ts[k]))
        JMap.setStr(e, "tip", Utility.GameTimeToString(ts[k]))
        if diary[k]
            JMap.setStr(e, "tone", "diary")
        else
            JMap.setStr(e, "tone", "live")
        endif
        JArray.addObj(items, e)
        k += 1
    endwhile
EndFunction

; Prisma eventRelative: now / Xm / Xh Ym / Xd Yh ago; older than a week -> the game date.
String Function AgoText(Float d, Float at) global
    if d < 0.0
        d = 0.0
    endif
    if d < 1.0 / 1440.0
        return "now"
    endif
    if d < 1.0 / 24.0
        return Math.Floor(d * 1440.0) + "m ago"
    endif
    if d < 1.0
        int h = Math.Floor(d * 24.0)
        int mins = Math.Floor((d * 24.0 - h) * 60.0)
        if mins > 0
            return h + "h " + mins + "m ago"
        endif
        return h + "h ago"
    endif
    if d < 7.0
        int dd = Math.Floor(d)
        int hh = Math.Floor((d - dd) * 24.0)
        if hh > 0
            return dd + "d " + hh + "h ago"
        endif
        return dd + "d ago"
    endif
    return Utility.GameTimeToString(at)
EndFunction

String Function CapFirst(String s) global
    if s == ""
        return s
    endif
    int c = StringUtil.AsOrd(StringUtil.GetNthChar(s, 0))
    if c < 97 || c > 122
        return s
    endif
    return StringUtil.AsChar(c - 32) + StringUtil.Substring(s, 1)
EndFunction

; ---- Additional info (Prisma BuildAdditionalInfo + renderAdditionalInfo) ----

Function AddAdditionalInfo(int sections, DOM_Core core, DOM_Mind m, Actor akActor, String name) global
    int lines = AddSection(sections, "lines", "", "")

    ; Virginity: faction rank 0 = still a virgin. Display order vaginal, anal, oral, same, gangbang.
    AddVirginLine(lines, akActor, core.DOMVirginVaginal, "Vaginal virgin")
    AddVirginLine(lines, akActor, core.DOMVirginAnal, "Anal virgin")
    AddVirginLine(lines, akActor, core.DOMVirginOral, "Oral virgin")
    AddVirginLine(lines, akActor, core.DOMVirginSame, "Same-sex virgin")
    AddVirginLine(lines, akActor, core.DOMVirginGangbang, "Gangbang virgin")

    ; Difficulty: mind aggregates, else DOM's DifficultyMessage fallback from traits.
    Float modSum = 0.0
    Float modSkill = 0.0
    Bool haveMods = false
    if m
        modSum = m.MOD_SumAll
        modSkill = m.MOD_SkillAll
        haveMods = true
    elseif core.DOMGenerator
        float[] traits = core.DOMGenerator.GetNPCTraits(akActor)
        if traits && traits.Length >= 12
            float[] mods = core.DOMGenerator.GetModifiers(akActor, traits)
            float[] inv = core.DOMGenerator.GetInverseModifiers(akActor, traits)
            if mods && mods.Length > 41 && inv && inv.Length > 35
                modSum = mods[0] + mods[7] + inv[14] + mods[21] + mods[28] + inv[35]
                modSkill = inv[1] + mods[37] + mods[13] + inv[23] + mods[40] + mods[41]
                haveMods = true
            endif
        endif
    endif
    if haveMods
        int rank = core.GetDifficultyLevel(modSum)
        if rank >= 6
            JArray.addStr(lines, name + " will be easy to train.")
        elseif rank <= 3
            JArray.addStr(lines, name + " will be difficult to train.")
        endif
        if core.GetDifficultyLevel(modSkill) >= 6
            JArray.addStr(lines, name + " will make a good trainer.")
        endif
    endif

    ; Market worth: slaves (and trainers) only.
    if m && m.is_slave && core.DOMGenerator
        int worth = core.DOMGenerator.getActorPrice(akActor)
        if worth > 0
            JArray.addStr(lines, "Current Market Worth: " + worth)
        endif
    endif

    ; Trainees roster for a slaver/trainer; trainer sentence for a plain slave.
    DOM_Actor a = core.GetActor(akActor)
    if !a
        return
    endif
    int nTrainees = a.GetTraineeCount()
    if nTrainees > 0
        int roster = 0
        int i = 0
        while i < nTrainees
            DOM_Actor t = a.GetTrainee(i)
            if t
                String tn = t.getName()
                if tn != ""
                    if roster == 0
                        roster = AddSection(sections, "list", "Slaves under management", "")
                    endif
                    JArray.addStr(roster, tn)
                endif
            endif
            i += 1
        endwhile
    elseif m && m.is_slave
        DOM_Actor tr = a.GetTrainer()
        if tr && tr.getName() != ""
            JArray.addStr(lines, name + " is trained by " + tr.getName())
        else
            JArray.addStr(lines, name + " has no trainer assigned.")
        endif
    endif
EndFunction

Function AddVirginLine(int lines, Actor akActor, Faction f, String label) global
    if f && akActor.GetFactionRank(f) == 0
        JArray.addStr(lines, label)
    endif
EndFunction
