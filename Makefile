CXXFLAGS += -std=c++17 -Wall -Wextra
CPPFLAGS +=
LDFLAGS +=
LDLIBS += -lboost_program_options

.SUFFIXES:

.PHONY: all
all: c2xml
c2xml: c2xml.o lexer.o parser.o
c2xml.o: c2xml.cpp lexer.hpp parser.hpp
lexer.o: lexer.cpp parser.hpp
parser.o: parser.cpp

lexer.cpp lexer.hpp: lexer.l
	flex --header-file=lexer.hpp -o lexer.cpp $<

parser.cpp parser.hpp location.hpp: parser.y
	bison -d -D api.location.file='"location.hpp"' -o parser.cpp $<

.PHONY: clean
clean:
	$(RM) c2xml *.o lexer.cpp parser.cpp lexer.hpp parser.hpp location.hpp *.output

%: %.o
	$(CXX) $^ $(LDFLAGS) $(LDLIBS) -o $@

%.o: %.cpp
	$(CXX) $< $(CXXFLAGS) $(CPPFLAGS) -c -o $@

%.output: %.y
	LANG=C bison -r all $<
	$(RM) $(<:.y=.tab.c)
