CXXFLAGS += -std=c++17 -Wall -Wextra
CPPFLAGS +=
LDFLAGS +=
LDLIBS += -lboost_program_options

.SUFFIXES:

.PHONY: all
all: c2xml
c2xml: c2xml.o lexer.o parser.o
c2xml.o: c2xml.cpp parser.hpp
lexer.o: lexer.cpp parser.hpp
parser.o: parser.cpp

parser.cpp parser.hpp location.hpp: parser.y
	bison -d -D api.location.file='"location.hpp"' -o parser.cpp $<

.PHONY: clean
clean:
	$(RM) c2xml *.o parser.cpp parser.hpp location.hpp *.output

.PHONY: format
format: c2xml.cpp lexer.cpp
	clang-format -i $^

%: %.o
	$(CXX) $^ $(LDFLAGS) $(LDLIBS) -o $@

%.o: %.cpp
	$(CXX) $< $(CXXFLAGS) $(CPPFLAGS) -c -o $@

%.output: %.y
	LANG=C bison -r all $<
	$(RM) $(<:.y=.tab.c)
