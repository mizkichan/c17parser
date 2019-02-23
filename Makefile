CXXFLAGS += -std=c++17 -Wall -Wextra
CPPFLAGS +=
LDFLAGS +=
LDLIBS += -lboost_program_options

.SUFFIXES:

.PHONY: all
all: main
main: main.o lexer.o parser.o
main.o: main.cpp lexer.hpp parser.hpp

.PHONY: clean
clean:
	$(RM) main *.o lexer.cpp parser.cpp lexer.hpp parser.hpp

%: %.o
	$(CXX) $^ $(LDFLAGS) $(LDLIBS) -o $@

%.o: %.cpp
	$(CXX) $< $(CXXFLAGS) $(CPPFLAGS) -c -o $@

%.cpp %.hpp: %.l
	flex --header-file=$(@:.cpp=.hpp) -o $(@:.hpp=.cpp) $<

%.cpp %.hpp: %.y
	bison -d -o $(@:.hpp=.cpp) $<
