#include "parser.hpp"
#include <cstdlib>
#include <iostream>
#include <string_view>

extern int yy_flex_debug;

extern auto main(void) -> int {
  yy_flex_debug = 0;
  yydebug = 0;

  yyparse();
  return EXIT_SUCCESS;
}

extern auto yyerror(std::string_view msg) -> void {
  std::cerr << yylloc.first_line << ':' << yylloc.first_column << '-'
            << yylloc.last_line  << ':' << yylloc.last_column  << ": "
            << msg << std::endl;
}

/* vim: set ts=2 sw=2 et: */
