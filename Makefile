SETTINGS_FILE := settings.json

BROWSERIFY := node_modules/.bin/browserify
EXORCIST := node_modules/.bin/exorcist
MUSTACHE := node_modules/.bin/mustache

.PHONY: default
default: chrome

.PHONY: chrome
chrome: build/chrome

.PHONY: dist
dist: dist/chrome.zip

.PHONY: clean
clean:
	rm -rf build/*.deps
	rm -rf build/chrome/*
	rm -rf dist/*

################################################################################

CHROME_SRC := content help images lib
build/chrome: build/chrome/extension.bundle.js
build/chrome: build/chrome/manifest.json
build/chrome: build/chrome/public
build/chrome: build/chrome/public/app.html
build/chrome: build/chrome/public/embed.js
build/chrome: build/chrome/settings-data.js
build/chrome: $(addprefix build/chrome/,$(CHROME_SRC))
build/chrome/extension.bundle.js: src/common/extension.js
	$(BROWSERIFY) -d $< | $(EXORCIST) $(addsuffix .map,$@) >$@
	@# When building the extension bundle, we also write out a list of
	@# depended-upon files to extension.bundle.deps, which we then include to
	@# ensure that the bundle is rebuilt if any of these change. We ignore
	@# vendor dependencies.
	@$(BROWSERIFY) --list $< | \
		grep -v node_modules | \
		sed 's#^#$@: #' \
		>build/extension.bundle.deps
build/chrome/manifest.json: src/chrome/manifest.json.mustache $(SETTINGS_FILE)
	$(MUSTACHE) $(SETTINGS_FILE) $< > $@
build/chrome/public:
	cp -R node_modules/hypothesis/build/ $@
build/chrome/public/app.html: src/client/app.html.mustache build/chrome/public $(SETTINGS_FILE)
	tools/template-context-app | $(MUSTACHE) - $< >$@
build/chrome/public/embed.js: src/client/embed.js.mustache build/chrome/public $(SETTINGS_FILE)
	tools/template-context-embed | $(MUSTACHE) - $< >$@
build/chrome/settings-data.js: src/chrome/settings-data.js.mustache build/chrome/public $(SETTINGS_FILE)
	tools/template-context-settings | $(MUSTACHE) - $< >$@
build/chrome/%: src/chrome/%
	cp -R $</ $@

dist/chrome.zip: build/chrome
	zip -qr $@ $<

-include build/*.deps
