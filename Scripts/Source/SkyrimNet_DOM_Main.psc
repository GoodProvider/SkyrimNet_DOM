Scriptname SkyrimNet_DOM_Main extends Quest  

Event OnInit()
    ; Register for all SexLab events using the framework's RegisterForAllEvents function
    Setup() 
EndEvent

Function Setup()
   ((self as Quest) as SkyrimNet_DOM_Events).Register_Events(self) 
   SkyrimNet_DOM_Decorators.Register_Decorators() 
   SkyrimNet_DOM_Actions.Register_Actions() 
EndFunction
