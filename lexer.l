%{
#include "parser.h"
#include <stdbool.h>
#include <assert.h>

#define YY_USER_ACTION { \
  if (*yytext != '\n') { \
    yylloc.first_column = yylloc.last_column; \
    yylloc.last_column += yyleng; \
  } \
}

static char **enum_consts = NULL;
static size_t enum_consts_count = 0;
static size_t enum_consts_capacity = 0;
static char **typedef_names = NULL;
static size_t typedef_names_count = 0;
static size_t typedef_names_capacity = 0;

static int check_type(char const *);
void add_enumeration_constant(char const *);
void add_typedef_name(char const *);
static bool is_enumeration_constant(char const *);
static bool is_typedef_name(char const *);
%}

%option debug
%option nodefault
%option noinput
%option nounput
%option noyywrap
%option warn
%option yylineno

%%

"auto"            return AUTO;
"break"           return BREAK;
"case"            return CASE;
"char"            return CHAR;
"const"           return CONST;
"continue"        return CONTINUE;
"default"         return DEFAULT;
"do"              return DO;
"double"          return DOUBLE;
"else"            return ELSE;
"enum"            return ENUM;
"extern"          return EXTERN;
"float"           return FLOAT;
"for"             return FOR;
"goto"            return GOTO;
"if"              return IF;
"inline"          return INLINE;
"int"             return INT;
"long"            return LONG;
"register"        return REGISTER;
"restrict"        return RESTRICT;
"return"          return RETURN;
"short"           return SHORT;
"signed"          return SIGNED;
"sizeof"          return SIZEOF;
"static"          return STATIC;
"struct"          return STRUCT;
"switch"          return SWITCH;
"typedef"         return TYPEDEF;
"union"           return UNION;
"unsigned"        return UNSIGNED;
"void"            return VOID;
"volatile"        return VOLATILE;
"while"           return WHILE;
"_Alignas"        return ALIGNAS;
"_Alignof"        return ALIGNOF;
"_Atomic"         return ATOMIC;
"_Bool"           return BOOL;
"_Complex"        return COMPLEX;
"_Generic"        return GENERIC;
"_Imaginary"      return IMAGINARY;
"_Noreturn"       return NORETURN;
"_Static_assert"  return STATIC_ASSERT;
"_Thread_local"   return THREAD_LOCAL;

[_a-zA-Z][_0-9a-zA-Z]*  { yylval.str = strdup(yytext); return check_type(yytext); }

[1-9][0-9]*             return INTEGER_CONSTANT;
"0"[0-7]*               return INTEGER_CONSTANT;
("0x"|"0X")[0-9a-fA-F]+ return INTEGER_CONSTANT;
"\""[^"]*"\""           return STRING_LITERAL;

"..." return ELLIPSIS;
"<<=" return LEFT_ASSIGN;
">>=" return RIGHT_ASSIGN;
"!="  return NOT_EQUAL;
"<="  return LESS_EQUAL;
"=="  return EQUAL;
">="  return GREATER_EQUAL;
"%="  return MOD_ASSIGN;
"*="  return MUL_ASSIGN;
"+="  return ADD_ASSIGN;
"-="  return SUB_ASSIGN;
"/="  return DIV_ASSIGN;
"&&"  return AND;
"||"  return OR;
"&="  return AND_ASSIGN;
"^="  return XOR_ASSIGN;
"|="  return OR_ASSIGN;
"++"  return INCREMENT;
"--"  return DECREMENT;
"->"  return ARROW;
"<<"  return LEFT;
">>"  return RIGHT;
[\[\](){}.&*+-~!/%<>^|?:;=,]  return *yytext;

[ \t\v\f]+
"\n" {
  yylloc.first_line = yylloc.last_line = yylineno;
  yylloc.first_column = yylloc.last_column = 1;
}

. {
  yyerror(yytext);
}

%%

int check_type(char const *const id) {
  if (is_enumeration_constant(id)) return ENUMERATION_CONSTANT;
  if (is_typedef_name(id)) return TYPEDEF_NAME;
  return IDENTIFIER;
}

void add_enumeration_constant(char const *const id) {
  if (is_enumeration_constant(id)) return;

  if (enum_consts_capacity == 0) {
    enum_consts_capacity = 1;
    enum_consts_count = 0;
    enum_consts = malloc(sizeof(char *));
  }

  if (enum_consts_count == enum_consts_capacity) {
    enum_consts_capacity *= 2;
    enum_consts = realloc(enum_consts, enum_consts_capacity * sizeof(char *));
    assert(enum_consts != NULL);
  }

  enum_consts[enum_consts_count] = strdup(id);
  ++enum_consts_count;
}

bool is_enumeration_constant(char const *const id) {
  for (size_t i = 0; i < enum_consts_count; ++i) {
    if (strcmp(enum_consts[i], id) == 0) {
      return true;
    }
  }
  return false;
}

void add_typedef_name(char const *const id) {
  if (is_typedef_name(id)) return;

  if (typedef_names_capacity == 0) {
    typedef_names_capacity = 1;
    typedef_names_count = 0;
    typedef_names = malloc(sizeof(char *));
  }

  if (typedef_names_count == typedef_names_capacity) {
    typedef_names_capacity *= 2;
    typedef_names = realloc(typedef_names, typedef_names_capacity * sizeof(char *));
    assert(typedef_names != NULL);
  }

  typedef_names[typedef_names_count] = strdup(id);
  ++typedef_names_count;
}

bool is_typedef_name(char const *const id) {
  for (size_t i = 0; i < typedef_names_count; ++i) {
    if (strcmp(typedef_names[i], id) == 0) {
      return true;
    }
  }
  return false;
}

/* vim: set ts=2 sw=2 et: */
