#include "lexer.hpp"
#include "parser.hpp"
#include <cstring>
#include <cstdlib>
#include <iostream>
#include <string_view>

#include <unistd.h>

extern int yy_flex_debug;

extern auto main(int argc, char **argv) -> int {
  int opt;
  FILE *fp;

  yy_flex_debug = yydebug = 0;

  while ((opt = getopt(argc, argv, "o:v")) != -1) switch (opt) {
    case 'o':
      fp = std::fopen(optarg, "w");
      if (!fp) {
        std::cerr << optarg << ": " << std::strerror(errno) << std::endl;
        return EXIT_FAILURE;
      }
      yyout = fp;
      break;

    case 'v':
      yy_flex_debug = yydebug = 1;
      break;

    default:
      std::cerr << "Usage: " << argv[0] << " [-v] [-o outfile] [infile]" << std::endl;
      return EXIT_SUCCESS;
  }

  if (optind < argc) {
    fp = std::fopen(argv[optind], "r");
    if (!fp) {
      std::cerr << argv[optind] << ": " << std::strerror(errno) << std::endl;
      return EXIT_FAILURE;
    }
    yyin = fp;
  }

  yyparse();
  return EXIT_SUCCESS;
}

extern auto yyerror(std::string_view msg) -> void {
  std::cerr << yylloc.first_line << ':' << yylloc.first_column << '-'
            << yylloc.last_line  << ':' << yylloc.last_column  << ": "
            << msg << std::endl;
}

/* vim: set ts=2 sw=2 et: */
