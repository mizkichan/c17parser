CXXFLAGS += -std=c++17 -Wall -Wextra
CPPFLAGS +=
LDFLAGS +=
LDLIBS +=

.PHONY: all
all: main

main: main.o lexer.o parser.o
	$(CXX) $(LDFLAGS) $(LDLIBS) -o $@ $^

main.o: main.cpp parser.hpp
parser.o: parser.cpp lexer.hpp

lexer.cpp lexer.hpp: lexer.l
	flex --header-file=lexer.hpp -o lexer.cpp $<

parser.cpp parser.hpp: parser.y
	bison -d -o parser.cpp $<

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	$(RM) main *.o lexer.cpp parser.cpp lexer.hpp parser.hpp
