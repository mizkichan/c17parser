%{
#include "parser.hpp"
#include <string_view>

#define YY_DECL auto yylex(void)->yy::parser::symbol_type

#define YY_USER_ACTION                                                         \
  if (*yytext != '\n') {                                                       \
    yylloc.begin.column = yylloc.end.column;                                   \
    yylloc.end.column += yyleng;                                               \
  }

static yy::parser::location_type yylloc;

static auto check_type(char const *, yy::parser::location_type const &)
    -> yy::parser::symbol_type;
extern auto add_enumeration_constant(std::string_view) -> void;
extern auto add_typedef_name(std::string_view) -> void;
static auto is_enumeration_constant(std::string_view) -> bool;
static auto is_typedef_name(std::string_view) -> bool;
%}

%option debug
%option nodefault
%option noinput
%option nounput
%option noyywrap
%option warn

%%

"auto"            return yy::parser::make_AUTO(yylloc);
"break"           return yy::parser::make_BREAK(yylloc);
"case"            return yy::parser::make_CASE(yylloc);
"char"            return yy::parser::make_CHAR(yylloc);
"const"           return yy::parser::make_CONST(yylloc);
"continue"        return yy::parser::make_CONTINUE(yylloc);
"default"         return yy::parser::make_DEFAULT(yylloc);
"do"              return yy::parser::make_DO(yylloc);
"double"          return yy::parser::make_DOUBLE(yylloc);
"else"            return yy::parser::make_ELSE(yylloc);
"enum"            return yy::parser::make_ENUM(yylloc);
"extern"          return yy::parser::make_EXTERN(yylloc);
"float"           return yy::parser::make_FLOAT(yylloc);
"for"             return yy::parser::make_FOR(yylloc);
"goto"            return yy::parser::make_GOTO(yylloc);
"if"              return yy::parser::make_IF(yylloc);
"inline"          return yy::parser::make_INLINE(yylloc);
"int"             return yy::parser::make_INT(yylloc);
"long"            return yy::parser::make_LONG(yylloc);
"register"        return yy::parser::make_REGISTER(yylloc);
"restrict"        return yy::parser::make_RESTRICT(yylloc);
"return"          return yy::parser::make_RETURN(yylloc);
"short"           return yy::parser::make_SHORT(yylloc);
"signed"          return yy::parser::make_SIGNED(yylloc);
"sizeof"          return yy::parser::make_SIZEOF(yylloc);
"static"          return yy::parser::make_STATIC(yylloc);
"struct"          return yy::parser::make_STRUCT(yylloc);
"switch"          return yy::parser::make_SWITCH(yylloc);
"typedef"         return yy::parser::make_TYPEDEF(yylloc);
"union"           return yy::parser::make_UNION(yylloc);
"unsigned"        return yy::parser::make_UNSIGNED(yylloc);
"void"            return yy::parser::make_VOID(yylloc);
"volatile"        return yy::parser::make_VOLATILE(yylloc);
"while"           return yy::parser::make_WHILE(yylloc);
"_Alignas"        return yy::parser::make_ALIGNAS(yylloc);
"_Alignof"        return yy::parser::make_ALIGNOF(yylloc);
"_Atomic"         return yy::parser::make_ATOMIC(yylloc);
"_Bool"           return yy::parser::make_BOOL(yylloc);
"_Complex"        return yy::parser::make_COMPLEX(yylloc);
"_Generic"        return yy::parser::make_GENERIC(yylloc);
"_Imaginary"      return yy::parser::make_IMAGINARY(yylloc);
"_Noreturn"       return yy::parser::make_NORETURN(yylloc);
"_Static_assert"  return yy::parser::make_STATIC_ASSERT(yylloc);
"_Thread_local"   return yy::parser::make_THREAD_LOCAL(yylloc);

[_a-zA-Z][_0-9a-zA-Z]*  { return check_type(yytext, yylloc); }

[1-9][0-9]*             return yy::parser::make_INTEGER_CONSTANT(yytext, yylloc);
"0"[0-7]*               return yy::parser::make_INTEGER_CONSTANT(yytext, yylloc);
("0x"|"0X")[0-9a-fA-F]+ return yy::parser::make_INTEGER_CONSTANT(yytext, yylloc);
"\""[^"]*"\""           return yy::parser::make_STRING_LITERAL(yytext, yylloc);

"..." return yy::parser::make_ELLIPSIS(yylloc);
"<<=" return yy::parser::make_LEFT_ASSIGN(yylloc);
">>=" return yy::parser::make_RIGHT_ASSIGN(yylloc);
"!="  return yy::parser::make_NOT_EQUAL(yylloc);
"<="  return yy::parser::make_LESS_EQUAL(yylloc);
"=="  return yy::parser::make_EQUAL(yylloc);
">="  return yy::parser::make_GREATER_EQUAL(yylloc);
"%="  return yy::parser::make_MOD_ASSIGN(yylloc);
"*="  return yy::parser::make_MUL_ASSIGN(yylloc);
"+="  return yy::parser::make_ADD_ASSIGN(yylloc);
"-="  return yy::parser::make_SUB_ASSIGN(yylloc);
"/="  return yy::parser::make_DIV_ASSIGN(yylloc);
"&&"  return yy::parser::make_AND(yylloc);
"||"  return yy::parser::make_OR(yylloc);
"&="  return yy::parser::make_AND_ASSIGN(yylloc);
"^="  return yy::parser::make_XOR_ASSIGN(yylloc);
"|="  return yy::parser::make_OR_ASSIGN(yylloc);
"++"  return yy::parser::make_INCREMENT(yylloc);
"--"  return yy::parser::make_DECREMENT(yylloc);
"->"  return yy::parser::make_ARROW(yylloc);
"<<"  return yy::parser::make_LEFT(yylloc);
">>"  return yy::parser::make_RIGHT(yylloc);
"!"   return yy::parser::make_EXCLAMATION(yylloc);
"%"   return yy::parser::make_PERCENT(yylloc);
"&"   return yy::parser::make_AMPASAND(yylloc);
"("   return yy::parser::make_LEFT_PAREN(yylloc);
")"   return yy::parser::make_RIGHT_PAREN(yylloc);
"*"   return yy::parser::make_ASTERISK(yylloc);
"+"   return yy::parser::make_PLUS(yylloc);
","   return yy::parser::make_COMMA(yylloc);
"-"   return yy::parser::make_MINUS(yylloc);
"."   return yy::parser::make_DOT(yylloc);
"/"   return yy::parser::make_SLASH(yylloc);
":"   return yy::parser::make_COLON(yylloc);
";"   return yy::parser::make_SEMICOLON(yylloc);
"<"   return yy::parser::make_LESS_THAN(yylloc);
"="   return yy::parser::make_ASSIGN(yylloc);
">"   return yy::parser::make_GREATER_THAN(yylloc);
"?"   return yy::parser::make_QUESTION(yylloc);
"["   return yy::parser::make_LEFT_BRACKET(yylloc);
"]"   return yy::parser::make_RIGHT_BRACKET(yylloc);
"^"   return yy::parser::make_CIRCUMFLEX(yylloc);
"{"   return yy::parser::make_LEFT_BRACE(yylloc);
"|"   return yy::parser::make_BAR(yylloc);
"}"   return yy::parser::make_RIGHT_BRACE(yylloc);
"~"   return yy::parser::make_TILDE(yylloc);

[ \t\v\f]+
"\n"  { yylloc.begin.line = ++yylloc.end.line; yylloc.begin.column = yylloc.end.column = 1;  }

. { std::cerr << yylloc << ": " << yytext << std::endl; }

<<EOF>> return yy::parser::make_END_OF_FILE(yylloc);

%%

#include <algorithm>
#include <string>
#include <string_view>
#include <vector>

static std::vector<std::string> enum_consts;
static std::vector<std::string> typedef_names;

auto check_type(char const *const id, yy::parser::location_type const &yylloc)
    -> yy::parser::symbol_type {
  if (std::string_view(id).find("__") == 0)
    return yy::parser::make_TYPEDEF_NAME(id, yylloc);
  if (is_enumeration_constant(id))
    return yy::parser::make_ENUMERATION_CONSTANT(id, yylloc);
  if (is_typedef_name(id))
    return yy::parser::make_TYPEDEF_NAME(id, yylloc);
  return yy::parser::make_IDENTIFIER(id, yylloc);
}

auto add_enumeration_constant(std::string_view const id) -> void {
  if (!is_enumeration_constant(id)) {
    enum_consts.emplace_back(id);
  }
}

auto is_enumeration_constant(std::string_view const id) -> bool {
  return std::find(enum_consts.cbegin(), enum_consts.cend(), id) !=
         enum_consts.cend();
}

auto add_typedef_name(std::string_view const id) -> void {
  if (!is_typedef_name(id)) {
    typedef_names.emplace_back(id);
  }
}

auto is_typedef_name(std::string_view const id) -> bool {
  return std::find(typedef_names.cbegin(), typedef_names.cend(), id) !=
         typedef_names.cend();
}

/* vim: set ts=2 sw=2 et: */
