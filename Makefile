# http://www.theweb.dk/KickAssembler
KICKASS=./bin/KickAss.jar
# https://sourceforge.net/projects/c64-debugger/
DEBUGGER=/Applications/C64\ Debugger.app/Contents/MacOS/C64\ Debugger
# DEBUGGER=start "" "C:\Program Files\C64Debugger.exe" # on Windows
# https://bitbucket.org/magli143/exomizer/wiki/Home
EXOMIZER=/usr/local/bin/exomizer

.PHONY: %.debug clean
.PRECIOUS: %.exe.prg

%.prg: %.asm $(KICKASS)
	java -jar $(KICKASS) -debugdump -symbolfile -vicesymbols "$<"

%.exe.prg: %.prg
	exomizer sfx basic "$<" -o "$@"
	x64sc "$@"

%.debug: %.prg
	$(DEBUGGER) -prg "$<" -wait 2500 -autojmp -layout 9
	# x64sc -moncommands "$*.vs" "$@"

clean:
	rm -f *.prg
	rm -f *.exe.prg
	rm -f *.sym
	rm -f *.vs
	rm -f *.dbg
	rm -f *.d64
