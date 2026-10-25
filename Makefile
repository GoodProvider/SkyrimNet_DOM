VERSION=0.2.0
NAME=SkyrimNet_DOM
RELEASE_FILE=versions/SkyrimNet_DOM ${VERSION}.zip

swap_headers:
	powershell.exe -NoProfile -Command " \
		if (Test-Path 'swapped_source') { \
			Move-Item -Path 'swapped_source' -Destination 'Scripts' -Force ; \
			& 'c:\Users\bhuff\.vscode\extensions\joelday.papyrus-lang-vscode-2024.578.1412\pyro\pyro.exe' --input-path skyrimse.ppj --game-path C:\Skyrim\dev\skyrim ; \
		} else { \
			Move-Item -Path 'Scripts\Source' -Destination 'swapped_source' -Force ; \
			New-Item -ItemType Directory -Force -Path 'Scripts\Source' | Out-Null ; \
			uv run python_scripts/headers_strip_psc.py --source swapped_source --destination Scripts\Source ; \
			Copy-Item -Path 'Headers\DOM\*.psc' -Destination 'Scripts\Source\' -Force ; \
			& 'c:\Users\bhuff\.vscode\extensions\joelday.papyrus-lang-vscode-2024.578.1412\pyro\pyro.exe' --input-path skyrimse.ppj --game-path C:\Skyrim\dev\skyrim ; \
		}"

release: 
	powershell.exe -NoProfile -Command " \
		python3 ./python_scripts/fomod-info.py -v ${VERSION} -n '${NAME}' -o fomod/info.xml fomod-source/info.xml ; \
		if (Test-Path '${RELEASE_FILE}') { Remove-Item -Path '${RELEASE_FILE}' -Recurse -Force } ; \
		7z a '${RELEASE_FILE}' fomod Scripts SkyrimNet_DOM.esp SKSE \
	"
