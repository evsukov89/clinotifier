CC=clang
CFLAGS=-lobjc -framework Foundation
SOURCES=clinotifier.m

clinotifier: $(SOURCES)
	    $(CC) -o clinotifier $(SOURCES) $(CFLAGS)

clean:
		rm clinotifier

run: clinotifier
		./clinotifier

all: clinotifier

