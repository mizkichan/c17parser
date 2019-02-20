CFLAGS += -std=c17 -Wall -Wextra
CPPFLAGS += -D_POSIX_C_SOURCE=200809L
LDFLAGS +=
LDLIBS +=

.PHONY: all
all: main

main: main.o lexer.o parser.o
main.o: main.c parser.h
parser.o: parser.c lexer.h

lexer.c lexer.h: lexer.l
	flex --header-file=lexer.h -o lexer.c $<

parser.c parser.h: parser.y
	bison -d -o parser.c $<

.PHONY: clean
clean:
	$(RM) main *.o lexer.c parser.c lexer.h parser.h
