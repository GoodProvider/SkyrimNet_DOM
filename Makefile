VERSION=0.0.2
NAME=SkyrimNet_DOM
RELEASE_FILE=versions/SkyrimNet_DOM ${VERSION}.zip

swap_headers:
	if exist swapped_scripts ( \
		rmdir /S /Q Scripts && \
		move swapped_scripts Scripts && \
		c:\Users\bhuff\.vscode\extensions\joelday.papyrus-lang-vscode-2024.578.1412\pyro\pyro.exe --input-path skyrimse.ppj --game-path C:\Skyrim\dev\skyrim \
	) else ( \
		move Scripts swapped_scripts && \
		mkdir Scripts && \
		mkdir Scripts\Source && \
		uv run python_scripts/headers_strip_psc.py --source swapped_source --destination Scripts\Source && \
		copy Headers\DOM\*.psc Scripts\Source\ /Y && \
		c:\Users\bhuff\.vscode\extensions\joelday.papyrus-lang-vscode-2024.578.1412\pyro\pyro.exe --input-path skyrimse.ppj --game-path C:\Skyrim\dev\skyrim \
	)

release: 
	python3 ./python_scripts/fomod-info.py -v ${VERSION} -n '${NAME}' -o fomod/info.xml fomod-source/info.xml
	if exist '${RELEASE_file}' rm /Q /S '${RELEASE_FILE}'
	7z -r a '${RELEASE_FILE}' fomod \
	    Scripts \
		SkyrimNet_DOM.esp \
		fomod/info.json \
		SKSE