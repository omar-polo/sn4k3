FENNEL =	fennel-5.1
LOVE =		love

.PHONY: all run clean

all: run

.SUFFIXES: .lua .fnl
.fnl.lua:
	${FENNEL} --compile $< > $@ || (rm -f $@ && false)

main.lua: main.fnl

run: main.lua
	${LOVE} .

clean:
	rm -f main.lua
