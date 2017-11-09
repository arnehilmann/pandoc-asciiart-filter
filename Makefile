README.pdf:	README.md lib/
	pandoc \
		$< \
		--lua-filter render-asciiart-filter.lua \
		-o $@


lib: lib/ditaa.jar lib/plantuml.jar


lib/ditaa.jar:
	mkdir -p lib
	curl -L -o $@ https://github.com/stathissideris/ditaa/raw/master/service/web/lib/ditaa0_10.jar


lib/plantuml.jar:
	mkdir -p lib
	curl -L "https://sourceforge.net/projects/plantuml/files/plantuml.jar/download?use_mirror=10gbps-io" > $@


clean:
	rm -rf rendered


mrproper:	clean
	rm -rf lib
	git clean -fxd


.PHONY: clean mrproper
