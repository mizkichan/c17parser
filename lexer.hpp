#ifndef LEXER_HPP
#define LEXER_HPP

#include "parser.tab.hpp"
#include <optional>
#include <string>

extern auto yylex(yy::parser::semantic_type *, yy::parser::location_type *)
    -> int;
extern auto add_enumeration_constant(std::string &&) -> void;
extern auto add_typedef_name(std::string &&) -> void;

extern std::istream *input;
extern std::optional<std::string> filename;

#endif
