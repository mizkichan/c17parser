#include "lexer.hpp"
#include <unordered_set>

static auto check_type(std::string const &, yy::parser::semantic_type *)
    -> yy::parser::token::yytokentype;
template <typename T>
static auto check_type(T, T, yy::parser::semantic_type *)
    -> yy::parser::token::yytokentype;
static auto is_enumeration_constant(std::string const &) -> bool;
static auto is_typedef_name(std::string const &) -> bool;

static std::unordered_set<std::string> enum_consts;
static std::unordered_set<std::string> typedef_names = {
    "__builtin_va_list",
};

std::istream *input = &std::cin;
std::optional<std::string> filename;

auto yylex(yy::parser::semantic_type *lval, yy::parser::location_type *location)
    -> int {
  static std::string line;
  static size_t lineno = 0;
  yy::parser::token::yytokentype token;

#define YYFILL                                                                 \
  {                                                                            \
    if (YYCURSOR == line.cend()) {                                             \
      if (!std::getline(*input, line)) {                                       \
        return yy::parser::token::END_OF_FILE;                                 \
      }                                                                        \
      ++lineno;                                                                \
    } else {                                                                   \
      line = std::string(YYCURSOR, line.cend());                               \
    }                                                                          \
    YYCURSOR = line.cbegin();                                                  \
  }

  // clang-format off
  /*!re2c
    re2c:flags:posix-captures = 1;
    re2c:define:YYCTYPE = char;
    re2c:define:YYLIMIT = line.cend();
    re2c:define:YYFILL:naked = 1;
  */
  /*!stags:re2c format = 'std::string::const_iterator @@;'; */
  /*!maxnmatch:re2c*/
  // clang-format on

  static auto YYCURSOR = line.cbegin();
  std::array<decltype(YYCURSOR), YYMAXNMATCH * 2> yypmatch;

  std::string::const_iterator YYMARKER;
  size_t yynmatch;

  while (true) {
    // clang-format off
    /*!re2c
      identifier            = [_a-zA-Z][_0-9a-zA-Z]*;
      decimal_constant      = [1-9][0-9]*;
      octal_constant        = "0" [0-7]*;
      hexadecimal_constant  = '0x' [0-9a-zA-Z]+;
      string_literal        = "\"" ( [^"]* ) "\"";

      "_Alignas"        { token = yy::parser::token::ALIGNAS; break; }
      "_Alignof"        { token = yy::parser::token::ALIGNOF; break; }
      "_Atomic"         { token = yy::parser::token::ATOMIC; break; }
      "_Bool"           { token = yy::parser::token::BOOL; break; }
      "_Complex"        { token = yy::parser::token::COMPLEX; break; }
      "_Generic"        { token = yy::parser::token::GENERIC; break; }
      "_Imaginary"      { token = yy::parser::token::IMAGINARY; break; }
      "_Noreturn"       { token = yy::parser::token::NORETURN; break; }
      "_Static_assert"  { token = yy::parser::token::STATIC_ASSERT; break; }
      "_Thread_local"   { token = yy::parser::token::THREAD_LOCAL; break; }
      "auto"            { token = yy::parser::token::AUTO; break; }
      "break"           { token = yy::parser::token::BREAK; break; }
      "case"            { token = yy::parser::token::CASE; break; }
      "char"            { token = yy::parser::token::CHAR; break; }
      "const"           { token = yy::parser::token::CONST; break; }
      "continue"        { token = yy::parser::token::CONTINUE; break; }
      "default"         { token = yy::parser::token::DEFAULT; break; }
      "do"              { token = yy::parser::token::DO; break; }
      "double"          { token = yy::parser::token::DOUBLE; break; }
      "else"            { token = yy::parser::token::ELSE; break; }
      "enum"            { token = yy::parser::token::ENUM; break; }
      "extern"          { token = yy::parser::token::EXTERN; break; }
      "float"           { token = yy::parser::token::FLOAT; break; }
      "for"             { token = yy::parser::token::FOR; break; }
      "goto"            { token = yy::parser::token::GOTO; break; }
      "if"              { token = yy::parser::token::IF; break; }
      "inline"          { token = yy::parser::token::INLINE; break; }
      "int"             { token = yy::parser::token::INT; break; }
      "long"            { token = yy::parser::token::LONG; break; }
      "register"        { token = yy::parser::token::REGISTER; break; }
      "restrict"        { token = yy::parser::token::RESTRICT; break; }
      "return"          { token = yy::parser::token::RETURN; break; }
      "short"           { token = yy::parser::token::SHORT; break; }
      "signed"          { token = yy::parser::token::SIGNED; break; }
      "sizeof"          { token = yy::parser::token::SIZEOF; break; }
      "static"          { token = yy::parser::token::STATIC; break; }
      "struct"          { token = yy::parser::token::STRUCT; break; }
      "switch"          { token = yy::parser::token::SWITCH; break; }
      "typedef"         { token = yy::parser::token::TYPEDEF; break; }
      "union"           { token = yy::parser::token::UNION; break; }
      "unsigned"        { token = yy::parser::token::UNSIGNED; break; }
      "void"            { token = yy::parser::token::VOID; break; }
      "volatile"        { token = yy::parser::token::VOLATILE; break; }
      "while"           { token = yy::parser::token::WHILE; break; }

      "!"   { token = yy::parser::token::EXCL; break; }
      "!="  { token = yy::parser::token::EXCL_EQ; break; }
      "%"   { token = yy::parser::token::PERCNT; break; }
      "%="  { token = yy::parser::token::PERCNT_EQ; break; }
      "&&"  { token = yy::parser::token::AMP_AMP; break; }
      "&"   { token = yy::parser::token::AMP; break; }
      "&="  { token = yy::parser::token::AMP_EQ; break; }
      "("   { token = yy::parser::token::LPAR; break; }
      ")"   { token = yy::parser::token::RPAR; break; }
      "*"   { token = yy::parser::token::AST; break; }
      "*="  { token = yy::parser::token::AST_EQ; break; }
      "+"   { token = yy::parser::token::PLUS; break; }
      "++"  { token = yy::parser::token::PLUS_PLUS; break; }
      "+="  { token = yy::parser::token::PLUS_EQ; break; }
      ","   { token = yy::parser::token::COMMA; break; }
      "-"   { token = yy::parser::token::MINUS; break; }
      "--"  { token = yy::parser::token::MINUS_MINUS; break; }
      "-="  { token = yy::parser::token::MINUS_EQ; break; }
      "->"  { token = yy::parser::token::RARR; break; }
      "."   { token = yy::parser::token::PERIOD; break; }
      "..." { token = yy::parser::token::HELLIP; break; }
      "/"   { token = yy::parser::token::SOL; break; }
      "/="  { token = yy::parser::token::SOL_EQ; break; }
      ":"   { token = yy::parser::token::COLON; break; }
      ";"   { token = yy::parser::token::SEMI; break; }
      "<"   { token = yy::parser::token::LT; break; }
      "<<"  { token = yy::parser::token::LAQUO; break; }
      "<<=" { token = yy::parser::token::LAQUO_EQ; break; }
      "<="  { token = yy::parser::token::LT_EQ; break; }
      "="   { token = yy::parser::token::EQ; break; }
      "=="  { token = yy::parser::token::EQ_EQ; break; }
      ">"   { token = yy::parser::token::GT; break; }
      ">="  { token = yy::parser::token::GT_EQ; break; }
      ">>"  { token = yy::parser::token::RAQUO; break; }
      ">>=" { token = yy::parser::token::RAQUO_EQ; break; }
      "?"   { token = yy::parser::token::QUEST; break; }
      "["   { token = yy::parser::token::LSQB; break; }
      "]"   { token = yy::parser::token::RSQB; break; }
      "^"   { token = yy::parser::token::HAT; break; }
      "^="  { token = yy::parser::token::HAT_EQ; break; }
      "{"   { token = yy::parser::token::LCUB; break; }
      "|"   { token = yy::parser::token::VERT; break; }
      "|="  { token = yy::parser::token::VERT_EQ; break; }
      "||"  { token = yy::parser::token::VERT_VERT; break; }
      "}"   { token = yy::parser::token::RCUB; break; }
      "~"   { token = yy::parser::token::TILDE; break; }

      identifier            { token = check_type(yypmatch[0], yypmatch[1], lval); break; }
      decimal_constant      { token = yy::parser::token::INTEGER_CONSTANT; break; }
      octal_constant        { token = yy::parser::token::INTEGER_CONSTANT; break; }
      hexadecimal_constant  { token = yy::parser::token::INTEGER_CONSTANT; break; }
      string_literal        { token = yy::parser::token::STRING_LITERAL; break; }

      [ \t\v\f]+  { continue; }

      * { throw yy::parser::syntax_error(*location, std::string(YYCURSOR, YYCURSOR + 1)); }
    */
    // clang-format off
  }

  location->begin.line = location->end.line = lineno;
  location->begin.column = std::distance(line.cbegin(), yypmatch[0]) + 1;
  location->end.column = std::distance(line.cbegin(), yypmatch[1]) + 1;
  return token;
}

auto check_type(std::string const &id, yy::parser::semantic_type *const lval)
    -> yy::parser::token::yytokentype {
  lval->emplace<std::string>(id);
  if (is_enumeration_constant(id)) {
    return yy::parser::token::ENUMERATION_CONSTANT;
  } else if (is_typedef_name(id)) {
    return yy::parser::token::TYPEDEF_NAME;
  } else {
    return yy::parser::token::IDENTIFIER;
  }
}

template <typename T>
auto check_type(T begin, T end, yy::parser::semantic_type *lval)
    -> yy::parser::token::yytokentype {
  return check_type(std::string(begin, end), lval);
}

auto add_enumeration_constant(std::string &&id) -> void {
  if (!is_enumeration_constant(id)) {
    enum_consts.emplace(std::move(id));
  }
}

auto is_enumeration_constant(std::string const &id) -> bool {
  return enum_consts.find(id) != enum_consts.cend();
}

auto add_typedef_name(std::string &&id) -> void {
  if (!is_typedef_name(id)) {
    typedef_names.emplace(std::move(id));
  }
}

auto is_typedef_name(std::string const &id) -> bool {
  return typedef_names.find(id) != typedef_names.cend();
}

// vim: set ft=cpp ts=2 sw=2 et:
