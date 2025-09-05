Scriptname SkyrimNet_DOM_Utils

Function Setup() global
    if True
        String events_log = "Data/SkyrimNet_DOM/events-log.json"
        int events = JArray.object() 
        Jvalue.WriteToFile(events, events_log) 
    endif 
EndFunction 

Function Trace(String File, String msg, Bool Notification) global
    msg = File+" "+msg
    Debug.Trace(msg)
    if Notification
        Debug.Notification(msg)
    endif 
Endfunction 