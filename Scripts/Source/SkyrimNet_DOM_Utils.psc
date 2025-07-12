Scriptname SkyrimNet_DOM_Utils

Function Trace(String File, String msg, Bool Notification) global
    msg = File+" "+msg
    if Notification
        Debug.Notification(msg)
    endif 
    Debug.Trace(msg)
Endfunction 