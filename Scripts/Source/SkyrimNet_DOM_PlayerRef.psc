Scriptname SkyrimNet_DOM_PlayerRef extends ReferenceAlias  

SkyrimNet_DOM_Main Property main  Auto  

Function Trace(String msg, String func, Bool Notification = false) global
    SkyrimNet_DOM_Utils.Trace("SkyrimNet_DOM_PlayerRef", func, msg, Notification)
EndFunction

Event OnPlayerLoadGame()
    main = Game.GetFormFromFile(0x800, "SkyrimNet_DOM.esp") as SkyrimNet_DOM_Main
    if main == None 
        Trace("OnPlayerLoadGame"," main is None")
    else
        Trace("OnPlayerLoadGame"," main is not None")
        main.Setup()
    endif 
EndEvent