all: yt-dlp doc pypi-files
clean: clean-test clean-dist
clean-all: clean clean-cache
completions: completion-bash completion-fish completion-zsh
tar: yt-dlp.tar.gz

# Keep this list in sync with MANIFEST.in
# intended use: when building a source distribution,
# make pypi-files && python setup.py sdist
pypi-files: AUTHORS Changelog.md LICENSE README.md README.txt \
	        completions yt-dlp.1 requirements.txt setup.cfg devscripts/*

.PHONY: all clean install tar pypi-files completions

clean-test:
	rm -rf test/testdata/sigs/player-*.js tmp/ *.annotations.xml *.aria2 *.description *.dump *.frag \
	*.frag.aria2 *.frag.urls *.info.json *.live_chat.json *.meta *.part* *.tmp *.temp *.unknown_video *.ytdl \
	*.3gp *.ape *.ass *.avi *.desktop *.f4v *.flac *.flv *.gif *.jpeg *.jpg *.m4a *.m4v *.mhtml *.mkv *.mov *.mp3 \
	*.mp4 *.mpga *.oga *.ogg *.opus *.png *.sbv *.srt *.swf *.swp *.tt *.ttml *.url *.vtt *.wav *.webloc *.webm *.webp
clean-dist:
	rm -rf yt-dlp.1.temp.md yt-dlp.1 README.txt MANIFEST build/ dist/ .coverage cover/ yt-dlp.tar.gz completions/ \
	*.spec CONTRIBUTING.md.tmp yt-dlp yt-dlp.exe yt_dlp.egg-info/ AUTHORS .mailmap
clean-cache:
	find . \( \
		-type d -name .pytest_cache -o -type d -name __pycache__ -o -name "*.pyc" -o -name "*.class" \
	\) -prune -exec rm -rf {} \;

completion-bash: completions/bash/yt-dlp
completion-fish: completions/fish/yt-dlp.fish
completion-zsh: completions/zsh/_yt-dlp

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/man
SHAREDIR ?= $(PREFIX)/share
PYTHON ?= /usr/bin/env python3

# set SYSCONFDIR to /etc if PREFIX=/usr or PREFIX=/usr/local
SYSCONFDIR = $(shell if [ $(PREFIX) = /usr -o $(PREFIX) = /usr/local ]; then echo /etc; else echo $(PREFIX)/etc; fi)

# set markdown input format to "markdown-smart" for pandoc version 2 and to "markdown" for pandoc prior to version 2
MARKDOWN = $(shell if [ `pandoc -v | head -n1 | cut -d" " -f2 | head -c1` = "2" ]; then echo markdown-smart; else echo markdown; fi)

install: yt-dlp yt-dlp.1 completions
	mkdir -p $(DESTDIR)$(BINDIR)
	install -m755 yt-dlp $(DESTDIR)$(BINDIR)/yt-dlp
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	install -m644 yt-dlp.1 $(DESTDIR)$(MANDIR)/man1/yt-dlp.1
	mkdir -p $(DESTDIR)$(SHAREDIR)/bash-completion/completions
	install -m644 completions/bash/yt-dlp $(DESTDIR)$(SHAREDIR)/bash-completion/completions/yt-dlp
	mkdir -p $(DESTDIR)$(SHAREDIR)/zsh/site-functions
	install -m644 completions/zsh/_yt-dlp $(DESTDIR)$(SHAREDIR)/zsh/site-functions/_yt-dlp
	mkdir -p $(DESTDIR)$(SHAREDIR)/fish/vendor_completions.d
	install -m644 completions/fish/yt-dlp.fish $(DESTDIR)$(SHAREDIR)/fish/vendor_completions.d/yt-dlp.fish

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/yt-dlp
	rm -f $(DESTDIR)$(MANDIR)/man1/yt-dlp.1
	rm -f $(DESTDIR)$(SHAREDIR)/bash-completion/completions/yt-dlp
	rm -f $(DESTDIR)$(SHAREDIR)/zsh/site-functions/_yt-dlp
	rm -f $(DESTDIR)$(SHAREDIR)/fish/vendor_completions.d/yt-dlp.fish

# XXX: This is hard to maintain
CODE_FOLDERS = yt_dlp yt_dlp/downloader yt_dlp/extractor yt_dlp/postprocessor yt_dlp/compat yt_dlp/dependencies
yt-dlp: yt_dlp/*.py yt_dlp/*/*.py
	mkdir -p zip
	for d in $(CODE_FOLDERS) ; do \
	  mkdir -p zip/$$d ;\
	  cp -pPR $$d/*.py zip/$$d/ ;\
	done
	touch -t 200001010101 zip/yt_dlp/*.py zip/yt_dlp/*/*.py
	mv zip/yt_dlp/__main__.py zip/
	cd zip ; zip -q ../yt-dlp yt_dlp/*.py yt_dlp/*/*.py __main__.py
	rm -rf zip
	echo '#!$(PYTHON)' > yt-dlp
	cat yt-dlp.zip >> yt-dlp
	rm yt-dlp.zip
	chmod a+x yt-dlp

yt-dlp.1: README.md devscripts/prepare_manpage.py
	$(PYTHON) devscripts/prepare_manpage.py yt-dlp.1.temp.md
	pandoc -s -f $(MARKDOWN) -t man yt-dlp.1.temp.md -o yt-dlp.1
	rm -f yt-dlp.1.temp.md

completions/bash/yt-dlp: yt_dlp/*.py yt_dlp/*/*.py devscripts/bash-completion.in
	mkdir -p completions/bash
	$(PYTHON) devscripts/bash-completion.py

completions/zsh/_yt-dlp: yt_dlp/*.py yt_dlp/*/*.py devscripts/zsh-completion.in
	mkdir -p completions/zsh
	$(PYTHON) devscripts/zsh-completion.py

completions/fish/yt-dlp.fish: yt_dlp/*.py yt_dlp/*/*.py devscripts/fish-completion.in
	mkdir -p completions/fish
	$(PYTHON) devscripts/fish-completion.py

yt-dlp.tar.gz: all
	@tar -czf yt-dlp.tar.gz --transform "s|^|yt-dlp/|" --owner 0 --group 0 \
		--exclude '*.DS_Store' \
		--exclude '*.kate-swp' \
		--exclude '*.pyc' \
		--exclude '*.pyo' \
		--exclude '*~' \
		--exclude '__pycache__' \
		--exclude '.pytest_cache' \
		--exclude '.git' \
		-- \
		README.md supportedsites.md Changelog.md LICENSE \
		CONTRIBUTING.md Collaborators.md CONTRIBUTORS AUTHORS \
		Makefile MANIFEST.in yt-dlp.1 README.txt completions \
		setup.py setup.cfg yt-dlp yt_dlp requirements.txt \
		devscripts

AUTHORS: .mailmap
	git shortlog -s -n | cut -f2 | sort > AUTHORS

.mailmap:
	git shortlog -s -e -n | awk '!(out[$$NF]++) { $$1="";sub(/^[ \t]+/,""); print}' > .mailmap
