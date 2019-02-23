%{
#include "parser.hpp"
#include <string_view>

#define YY_USER_ACTION if (*yytext != '\n') { \
  yylloc.first_column = yylloc.last_column; \
  yylloc.last_column += yyleng; \
}

#define fprintf flex_fprintf

static auto check_type(std::string_view id) -> int;
extern auto add_enumeration_constant(std::string_view id) -> void;
extern auto add_typedef_name(std::string_view id) -> void;
static auto is_enumeration_constant(std::string_view id) -> bool;
static auto is_typedef_name(std::string_view id) -> bool;

extern auto yyerror(std::string_view) -> void;
extern auto flex_fprintf(FILE *, char const *const, ...) -> int;
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

#undef fprintf

#include <algorithm>
#include <string>
#include <vector>

static std::vector<std::string> enum_consts;
static std::vector<std::string> typedef_names;

auto check_type(std::string_view const id) -> int {
  if (is_enumeration_constant(id)) return ENUMERATION_CONSTANT;
  if (is_typedef_name(id)) return TYPEDEF_NAME;
  return IDENTIFIER;
}

auto add_enumeration_constant(std::string_view const id) -> void {
  if (!is_enumeration_constant(id)) {
    enum_consts.emplace_back(id);
  }
}

auto is_enumeration_constant(std::string_view const id) -> bool {
  return std::find(enum_consts.cbegin(), enum_consts.cend(), id) != enum_consts.cend();
}

auto add_typedef_name(std::string_view const id) -> void {
  if (!is_typedef_name(id)) {
    typedef_names.emplace_back(id);
  }
}

auto is_typedef_name(std::string_view const id) -> bool {
  return std::find(typedef_names.cbegin(), typedef_names.cend(), id) != typedef_names.cend();
}

/* vim: set ts=2 sw=2 et: */
