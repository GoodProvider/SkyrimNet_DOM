use says "checking plugin E:\Wabbajack\full furry game\GAME\Game Root\Data\SKSE\Plugins\SkyrimNet_DOM.dll
couldn't load plugin E:\Wabbajack\full furry game\GAME\Game Root\Data\SKSE\Plugins\SkyrimNet_DOM.dll (Error 126)"

I have attached log files in logs subdirectory

his claude says "Error 126 means a dependency is missing. Checking the DLL's imports, it links against the debug Visual C++ runtime:

MSVCP140D.dll
VCRUNTIME140D.dll
VCRUNTIME140_1D.dll
ucrtbased.dll

These only exist on machines with Visual Studio installed, so the plugin fails for anyone using the normal VC++ Redistributable. I think it was compiled in Debug instead of Release. Could you upload a Release build?"

If the above is true, do we need to add that as a requirement or can we work without it? 