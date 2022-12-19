# http://www.theweb.dk/KickAssembler
KICKASS=~/Commodore64/Dev/KickAssembler/KickAss.jar
# https://sourceforge.net/projects/c64-debugger/
DEBUGGER=/Applications/C64\ Debugger.app/Contents/MacOS/C64\ Debugger
# DEBUGGER=start "" "C:\Program Files\C64Debugger.exe" # on Windows
# https://bitbucket.org/magli143/exomizer/wiki/Home
EXOMIZER=/usr/local/bin/exomizer

.PRECIOUS: %.exe.prg

%.prg: %.asm $(KICKASS)
	java -jar $(KICKASS) -debugdump -symbolfile -vicesymbols "$<"

%.exe.prg: %.prg
	exomizer sfx basic "$<" -o "$@"

.PHONY: %.run
%.run: %.prg
	x64sc "$@"

.PHONY: %.debug
%.debug: %.prg
	$(DEBUGGER) -prg "$<" -wait 3000 -autojmp -layout 9

.PHONY: clean
clean:
	rm -f *.prg
	rm -f *.exe.prg
	rm -f *.sym
	rm -f *.vs
	rm -f *.dbg
	rm -f *.d64
