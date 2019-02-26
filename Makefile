CXXFLAGS += -std=c++17 -Wall -Wextra -MMD -MP
CPPFLAGS +=
LDFLAGS +=
LDLIBS += -lboost_program_options

.SUFFIXES:

.DEFAULT: c2xml
c2xml: c2xml.o lexer.o parser.tab.o
c2xml.o: c2xml.cpp parser.tab.hpp
lexer.o: lexer.cpp parser.tab.hpp
parser.tab.o: parser.tab.cpp

%: %.o
	$(CXX) $^ $(LDFLAGS) $(LDLIBS) -o $@

%.o: %.cpp
	$(CXX) $< $(CXXFLAGS) $(CPPFLAGS) -c -o $@

%.tab.cpp %.tab.hpp: %.ypp
	bison -d -D api.location.file='"location.hpp"' $<

.PHONY: clean
clean:
	$(RM) `cat .gitignore`

.PHONY: format
format: c2xml.cpp lexer.cpp
	clang-format -i $^

%.output: %.ypp
	LANG=C bison -r all $<
	$(RM) $(<:.ypp=.tab.c)

-include c2xml.d lexer.d parser.d
