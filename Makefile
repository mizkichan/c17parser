CXXFLAGS += -std=c++17 -Wall -Wextra
CPPFLAGS +=
LDFLAGS +=
LDLIBS += -lboost_program_options

.SUFFIXES:

.PHONY: all
all: c2xml
c2xml: c2xml.o lexer.o parser.o
c2xml.o: c2xml.cpp lexer.hpp parser.hpp

.PHONY: clean
clean:
	$(RM) c2xml *.o lexer.cpp parser.cpp lexer.hpp parser.hpp

%: %.o
	$(CXX) $^ $(LDFLAGS) $(LDLIBS) -o $@

%.o: %.cpp
	$(CXX) $< $(CXXFLAGS) $(CPPFLAGS) -c -o $@

%.cpp %.hpp: %.l
	flex --header-file=$(@:.cpp=.hpp) -o $(@:.hpp=.cpp) $<

%.cpp %.hpp: %.y
	bison -d -o $(@:.hpp=.cpp) $<
