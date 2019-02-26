#ifndef LEXER_HPP
#define LEXER_HPP

#include "parser.tab.hpp"
#include <optional>

extern auto yylex(void) -> yy::parser::symbol_type;
extern auto add_enumeration_constant(std::string_view) -> void;
extern auto add_typedef_name(std::string_view) -> void;

extern std::istream *yyin;
extern std::optional<std::string> yyfile;

#endif
