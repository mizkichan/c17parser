#include "parser.h"
#include <stdio.h>
#include <stdlib.h>

extern int yy_flex_debug;

int main(void) {
  yy_flex_debug = 0;
  yydebug = 1;
  yyparse();
  return EXIT_SUCCESS;
}

void yyerror(char const *const msg) {
  fprintf(stderr, "%d:%d-%d:%d: %s\n", yylloc.first_line, yylloc.first_column,
          yylloc.last_line, yylloc.last_column, msg);
}

/* vim: set ts=2 sw=2 et: */
