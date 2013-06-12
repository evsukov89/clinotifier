CC=clang
CFLAGS=-lobjc -framework Foundation
SOURCES=clinotifier.m

debug: $(SOURCES)
		$(CC) -o clinotifier $(SOURCES) $(CFLAGS) -g
		lldb clinotifier

clinotifier: $(SOURCES)
	    $(CC) -o clinotifier $(SOURCES) $(CFLAGS)

clean:
		rm clinotifier

run: clinotifier
		./clinotifier

all: clinotifier

