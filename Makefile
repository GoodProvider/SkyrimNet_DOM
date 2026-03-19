VERSION=0.0.2
NAME=SkyrimNet_DOM
RELEASE_FILE=versions/SkyrimNet_DOM ${VERSION}.zip

release: 
	python3 ./python_scripts/fomod-info.py -v ${VERSION} -n '${NAME}' -o fomod/info.xml fomod-source/info.xml
	if exist '${RELEASE_file}' rm /Q /S '${RELEASE_FILE}'
	7z -r a '${RELEASE_FILE}' fomod \
	    Scripts \
		SkyrimNet_DOM.esp \
		fomod/info.json \
		SKSE