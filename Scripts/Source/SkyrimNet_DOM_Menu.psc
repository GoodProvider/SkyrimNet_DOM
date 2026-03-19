Scriptname SkyrimNet_DOM_Menu

Function Trace(String func, String msg, Bool Notification = false) global
    SkyrimNet_DOM_Utils.Trace("SkyrimNet_DOM_Event", func, msg, Notification)
EndFunction

Function Target_Menu_Selection(Actor slaveActor, Actor player) global
    SkyrimNet_DOM_Main main = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main
    SkyrimNet_DOM_Events events = (main as Quest) as SkyrimNet_DOM_Events
    Trace("slaveActor_Menu_Selection",slaveActor.GetDisplayName())

    bool manual_obedience = True 

    String clothing_string = "undress"
    DOM_Actor slave = SkyrimNet_DOM_Utils.GetSlave("SkyrimNet_DOM_Menu", "slaveActor_Menu_Selector", slaveActor, true) 
    if slave.mind.should_be_naked == true ; mind.should_be_naked
        clothing_string = "dress"
    endif 
    Trace("SelectAction","slave.is_naked:"+slave.is_naked+" should_be_naked:"+slave.mind.should_be_naked+" clothing:"+clothing_string)

    int masturbate = 0
    int sex = 1
    int raped_by_player = 2
    int rapes_the_player = 3
    int clothing = 4
    int cancel = 5

    String[] buttons = new String[6]
    int bondage = -2
    if main.devices_group != None 
        bondage = 5
        cancel = 6

        buttons = new String[7]
        buttons[bondage] = "bondage"
    else 
        bondage = -2
    endif 

    buttons[masturbate] = "masturbate"
    if slave.behaviour == "masturbate"
        buttons[masturbate] = "masturbate harder"
    endif 
    buttons[sex] = "have sex with player"
    buttons[raped_by_player] = "raped by player"
    buttons[rapes_the_player] = "rapes the player"
    buttons[clothing] = clothing_string
    buttons[cancel] = "cancel"
    String msg = "Should "+slaveActor.getDisplayName()+":"
    int button = SkyMessage.ShowArray(msg, buttons, getIndex = true) as int  

    Trace("slaveActor_Menu_Selection","button "+button+" == "+sex+" "+buttons[button])
    if button == masturbate
        Masturbate_Start(player, slaveActor, slave, manual_obedience)
    elseif button == sex || button == raped_by_player || button == rapes_the_player

        String rape_victim = "None" 
        String obedience_question = "Will "+slaveActor.getDisplayName()+" "+buttons[button]+"?"
        if button == raped_by_player
            rape_victim = "Speaker"
        elseif button == rapes_the_player
            rape_victim = "Target"
        endif 

        String choice = "obey" 
        if button != raped_by_player
            if ObedienceSelector(slave, obedience_question, manual_obedience)
                choice = "obey"
            endif 
        endif 

        SkyrimNet_DOM_Actions.Sex_Start_Helper(slaveActor, "", "{\"target\":\""+player.GetDisplayName()+"\",\"choice\":\""+choice+"\", \"dynamic\":\"dominate\"}", rape_victim)
    elseif button == clothing

        ;--------------------------------------------------
        ; How would they like it appear? 
        int Forcefully = 0
        int Normally = 1
        int Gently = 2 
        int Silently = 3

        int By_Slave = -1
        if button == clothing 
            buttons = new String[5]
            By_Slave = 3 
            Silently = 4
            buttons[By_Slave] = "By Slave" 
        else 
            buttons = new String[4]
        endif 
        buttons[Forcefully] = "forceful"
        buttons[Normally] = "normal" 
        buttons[Gently] = "gentle" 
        buttons[Silently] = "( Silently )" 

        msg = "How is "+slaveActor.getDisplayName()+" to be "+clothing_string+"ed?"

        int button_style = SkyMessage.ShowArray(msg, buttons, getIndex = true) as int  
        String style = buttons[button_style]

        Clothing_Start(clothing_string, style, player, slaveActor, slave, manual_obedience)
    elseif button == bondage 
        Trace("slaveActor_Menu_Selection","bondge")
        main.devices_group.UpdateDevices(slaveActor) 
    endif 
EndFunction 

Function Masturbate_Start(Actor superior, Actor slaveActor , DOM_Actor slave, bool manual_obedience) global
    String choice = "" 
    if ObedienceSelector(slave, "masturbate", manual_obedience)
        choice = "start masturbating"
    else
        choice = "refuse to masturbate"
    endif 
    SkyrimNet_DOM_Actions.masturbate_Start(slaveActor, "", "{\"choice\":\""+choice+"\"}")
EndFunction
        
Function Clothing_Start(String clothing_string, String style, Actor player, Actor slaveActor, DOM_Actor slave, bool manual_obedience) global
    String slave_name = slaveActor.GetDisplayName() 
    String player_name = player.GetDisplayName()

    if slave.is_naked && slave.mind.should_be_naked && !HasClothingInInventory(slaveActor) 
        Trace("Target_Menu_Selection",slave_name+" slave.is_naked: "+slave.is_naked+" slave.mind.should_be_naked: "+slave.mind.should_be_naked)
        String msg = slave_name+" tells "+player_name+", they can not obey an order to dress until they are given clothing."
        SkyrimNetApi.DirectNarration(msg, slaveActor, player) 
    endif 

    if style == "by slave" 
        String choice = "disobey" 
        if ObedienceSelector(slave, clothing_string, manual_obedience)
            choice = "obey"
        endif 
        Trace("Clothing_Start",slave_name+" by slave choice:"+choice)
        SkyrimNet_DOM_Actions.UndressDress_Execute(slaveActor,"", "{\"type\":\""+clothing_string+"\",\"choice\":\""+choice+"\"}")
        return 
    endif 


    if style != "( Silently )" ; silent 
        String msg = player.GetDisplayName()+" "+style+" "+clothing_string+"es "+slave_name+"."
        SkyrimNetApi.DirectNarration(msg, player, slaveActor) 
    endif 

    ; Now do the action 
    if clothing_string == "dress"
        slave.UnsetShouldBeNaked(player)
    else
        if !slave.mind.should_be_naked
            slave.mind.SetObedientTimer(1)
        endif 
        slave.SetShouldBeNaked(player)
    endif 
    Trace("clothing_Start","DOM slave "+slave_name+" "+clothing_string\
        +" is_naked:"+slave.is_naked+" should_be_naked:"+slave.mind.should_be_naked)
EndFunction 

bool Function HasClothingInInventory(Actor akActor) global
    int numItems = akActor.GetNumItems()
    int i = 0

    while i < numItems 
        Form kForm = akActor.GetNthForm(i)
        ; Type 26 = Armor (includes Clothing)
        if (kForm && kForm.GetType() == 26) 
            return true 
        endif
        i += 1
    endWhile
    return False 
EndFunction 


Bool Function ObedienceSelector(DOM_Actor slave, String msg, Bool manual_obedience ) global
    if manual_obedience
        int obey = 0
        int disobey = 1
        String[] buttons = new String[2]
        buttons[obey] = "Obey"
        buttons[disobey] = "Disobey" 

        int button = SkyMessage.ShowArray(msg, buttons, getIndex = true) as int  
        if button == obey 
            return True
        else
            return False 
        endif 
    else
        if slave.mind.WillObeyDisgraced(21) ; "no_sex"
            return True
        else 
            return False
        endif 
    endif
EndFunction

Function DebugMenuOpen(Actor slaveActor) 
    int final = 0 
    int cancel = 1 
    String[] buttons = new String[2]
    buttons[final] = "final"
    buttons[final] = "final"
    buttons[cancel] = "cancel"
    
    int button = SkyMessage.ShowArray("What to check/do on slaveActor?", buttons, getIndex = true) as int  
    
    ;if button == final 
    ;    String dec = SkyrimNet_DOM_Decorators.get_final_instructions(slaveActor) 
    ;    Debug.MessageBox(dec)
    ;endif 
EndFunction 