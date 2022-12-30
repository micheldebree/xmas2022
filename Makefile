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
	x64sc -moncommands "$*.vs" "$<"

.PHONY: %.debug
%.debug: %.prg
	$(DEBUGGER) -prg "$<" -wait 5000 -autojmp -layout 9

%.png.bin: %.png
	node convert_image.js "$<"

Xmas.prg: Xmas.asm Precalc.asm VIC.asm \
	tree.png.bin ball.png.bin candle.png.bin snowman.png.bin bell.png.bin star.png.bin soldier.png.bin

.PHONY: clean
clean:
	rm -f *.prg
	rm -f *.exe.prg
	rm -f *.sym
	rm -f *.vs
	rm -f *.dbg
	rm -f *.d64
	rm -f *.bin
