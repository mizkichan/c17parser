%{
#include "parser.hpp"
#include <string_view>

#define YY_DECL auto yylex(yy::parser::semantic_type *yylval, yy::parser::location_type *yylloc) -> int

/*
#define YY_USER_ACTION if (*yytext != '\n') { \
  yylloc.first_column = yylloc.last_column; \
  yylloc.last_column += yyleng; \
}

#define fprintf flex_fprintf
*/

static auto check_type(std::string_view id) -> int;
extern auto add_enumeration_constant(std::string_view id) -> void;
extern auto add_typedef_name(std::string_view id) -> void;
static auto is_enumeration_constant(std::string_view id) -> bool;
static auto is_typedef_name(std::string_view id) -> bool;

//extern auto yyerror(std::string_view) -> void;
//extern auto flex_fprintf(FILE *, char const *const, ...) -> int;
%}

%option debug
%option nodefault
%option noinput
%option nounput
%option noyywrap
%option warn
%option yylineno

%%

"auto"            return yy::parser::token::AUTO;
"break"           return yy::parser::token::BREAK;
"case"            return yy::parser::token::CASE;
"char"            return yy::parser::token::CHAR;
"const"           return yy::parser::token::CONST;
"continue"        return yy::parser::token::CONTINUE;
"default"         return yy::parser::token::DEFAULT;
"do"              return yy::parser::token::DO;
"double"          return yy::parser::token::DOUBLE;
"else"            return yy::parser::token::ELSE;
"enum"            return yy::parser::token::ENUM;
"extern"          return yy::parser::token::EXTERN;
"float"           return yy::parser::token::FLOAT;
"for"             return yy::parser::token::FOR;
"goto"            return yy::parser::token::GOTO;
"if"              return yy::parser::token::IF;
"inline"          return yy::parser::token::INLINE;
"int"             return yy::parser::token::INT;
"long"            return yy::parser::token::LONG;
"register"        return yy::parser::token::REGISTER;
"restrict"        return yy::parser::token::RESTRICT;
"return"          return yy::parser::token::RETURN;
"short"           return yy::parser::token::SHORT;
"signed"          return yy::parser::token::SIGNED;
"sizeof"          return yy::parser::token::SIZEOF;
"static"          return yy::parser::token::STATIC;
"struct"          return yy::parser::token::STRUCT;
"switch"          return yy::parser::token::SWITCH;
"typedef"         return yy::parser::token::TYPEDEF;
"union"           return yy::parser::token::UNION;
"unsigned"        return yy::parser::token::UNSIGNED;
"void"            return yy::parser::token::VOID;
"volatile"        return yy::parser::token::VOLATILE;
"while"           return yy::parser::token::WHILE;
"_Alignas"        return yy::parser::token::ALIGNAS;
"_Alignof"        return yy::parser::token::ALIGNOF;
"_Atomic"         return yy::parser::token::ATOMIC;
"_Bool"           return yy::parser::token::BOOL;
"_Complex"        return yy::parser::token::COMPLEX;
"_Generic"        return yy::parser::token::GENERIC;
"_Imaginary"      return yy::parser::token::IMAGINARY;
"_Noreturn"       return yy::parser::token::NORETURN;
"_Static_assert"  return yy::parser::token::STATIC_ASSERT;
"_Thread_local"   return yy::parser::token::THREAD_LOCAL;

[_a-zA-Z][_0-9a-zA-Z]*  { /*yylval.str = strdup(yytext);*/ return check_type(yytext); }

[1-9][0-9]*             return yy::parser::token::INTEGER_CONSTANT;
"0"[0-7]*               return yy::parser::token::INTEGER_CONSTANT;
("0x"|"0X")[0-9a-fA-F]+ return yy::parser::token::INTEGER_CONSTANT;
"\""[^"]*"\""           return yy::parser::token::STRING_LITERAL;

"..." return yy::parser::token::ELLIPSIS;
"<<=" return yy::parser::token::LEFT_ASSIGN;
">>=" return yy::parser::token::RIGHT_ASSIGN;
"!="  return yy::parser::token::NOT_EQUAL;
"<="  return yy::parser::token::LESS_EQUAL;
"=="  return yy::parser::token::EQUAL;
">="  return yy::parser::token::GREATER_EQUAL;
"%="  return yy::parser::token::MOD_ASSIGN;
"*="  return yy::parser::token::MUL_ASSIGN;
"+="  return yy::parser::token::ADD_ASSIGN;
"-="  return yy::parser::token::SUB_ASSIGN;
"/="  return yy::parser::token::DIV_ASSIGN;
"&&"  return yy::parser::token::AND;
"||"  return yy::parser::token::OR;
"&="  return yy::parser::token::AND_ASSIGN;
"^="  return yy::parser::token::XOR_ASSIGN;
"|="  return yy::parser::token::OR_ASSIGN;
"++"  return yy::parser::token::INCREMENT;
"--"  return yy::parser::token::DECREMENT;
"->"  return yy::parser::token::ARROW;
"<<"  return yy::parser::token::LEFT;
">>"  return yy::parser::token::RIGHT;
[\[\](){}.&*+-~!/%<>^|?:;=,]  return *yytext;

[ \t\v\f]+
"\n" {
/*
  yylloc.first_line = yylloc.last_line = yylineno;
  yylloc.first_column = yylloc.last_column = 1;
*/
}

. { std::cerr << yylloc << ": " << yytext << std::endl; }

%%

#undef fprintf

#include <algorithm>
#include <string>
#include <vector>

static std::vector<std::string> enum_consts;
static std::vector<std::string> typedef_names;

auto check_type(std::string_view const id) -> int {
  if (id.find("__") == 0) return yy::parser::token::TYPEDEF_NAME;
  if (is_enumeration_constant(id)) return yy::parser::token::ENUMERATION_CONSTANT;
  if (is_typedef_name(id)) return yy::parser::token::TYPEDEF_NAME;
  return yy::parser::token::IDENTIFIER;
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
