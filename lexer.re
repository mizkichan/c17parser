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
  using YYCTYPE = std::string::value_type;
  using iterator = std::string::const_iterator;

  static std::string line;
  static size_t lineno = 0;
  yy::parser::token::yytokentype token;

#define YYLIMIT line.cend()
#define YYFILL                                                                 \
  if (YYCURSOR == line.cend()) {                                               \
    do {                                                                       \
      if (!std::getline(*input, line)) {                                       \
        return yy::parser::token::END_OF_FILE;                                 \
      }                                                                        \
      ++lineno;                                                                \
    } while (line.empty());                                                    \
    YYCURSOR = line.cbegin();                                                  \
  }

  // clang-format off
  /*!re2c
    re2c:flags:posix-captures = 1;
    re2c:flags:input = custom;
    re2c:define:YYFILL:naked = 1;
  */
  /*!stags:re2c format = 'iterator @@;'; */
  /*!maxnmatch:re2c*/
  // clang-format on

  static auto YYCURSOR = line.cbegin();
  std::array<iterator, YYMAXNMATCH * 2> yypmatch;

  iterator YYMARKER;
  size_t yynmatch;

  auto const YYPEEK = []() { return *YYCURSOR; };
  auto const YYSKIP = []() { ++YYCURSOR; };
  auto const YYBACKUP = [&]() { YYMARKER = YYCURSOR; };
  auto const YYRESTORE = [&]() { YYCURSOR = YYMARKER; };
  auto const YYLESSTHAN = [](auto const &n) {
    return std::distance(YYCURSOR, YYLIMIT) < n;
  };
  auto const YYSTAGP = [](auto &t) { t = YYCURSOR; };
  auto const YYSTAGN = [](auto &t) { t = line.cend(); };

  while (true) {
    // clang-format off
    /*!re2c
      hexadecimal_digit     = [0-9a-fA-F];
      octal_digit           = [0-7];
      digit                 = [0-9];
      nonzero_digit         = [1-9];
      nondigit              = [_a-zA-Z];

      hex_quad              = hexadecimal_digit{4};
      universal_character_name  = ( "\\u" hex_quad | "\\U" hex_quad{2} );

      identifier_nondigit   = ( nondigit | universal_character_name );
      identifier            = identifier_nondigit ( identifier_nondigit | digit )*;

      long_long_suffix      = ( "ll" | "LL" );
      long_suffix           = 'l';
      unsigned_suffix       = 'u';
      integer_suffix        = ( unsigned_suffix long_suffix?  | unsigned_suffix long_long_suffix | long_suffix unsigned_suffix?  | long_long_suffix unsigned_suffix? );
      hexadecimal_prefix    = '0x';
      hexadecimal_constant  = ( hexadecimal_prefix hexadecimal_digit+ );
      octal_constant        = ( "0" octal_digit* );
      decimal_constant      = ( nonzero_digit digit* );
      integer_constant      = decimal_constant integer_suffix?  | octal_constant integer_suffix?  | hexadecimal_constant integer_suffix?;

      sign                  = [+-];
      digit_sequence        = digit+;
      floating_suffix       = ( "f" | "l" );
      hexadecimal_digit_sequence  = hexadecimal_digit+;
      binary_exponent_part  = ( 'p' sign? digit_sequence );
      hexadecimal_fractional_constant = ( hexadecimal_digit_sequence? "." hexadecimal_digit_sequence | hexadecimal_digit_sequence "." );
      exponent_part         = ( 'e' sign? digit_sequence );
      fractional_constant   = ( digit_sequence? "." digit_sequence | digit_sequence "." );
      hexadecimal_floating_constant = ( hexadecimal_prefix hexadecimal_fractional_constant binary_exponent_part floating_suffix? | hexadecimal_prefix hexadecimal_digit_sequence binary_exponent_part floating_suffix? );
      decimal_floating_constant = ( fractional_constant exponent_part? floating_suffix? | digit_sequence exponent_part floating_suffix? );
      floating_constant     = decimal_floating_constant | hexadecimal_floating_constant;

      hexadecimal_escape_sequence = ( "\\x" hexadecimal_digit+ );
      octal_escape_sequence   = ( "\\" octal_digit{1,3} );
      simple_escape_sequence  = ( "\\'" | "\\\"" | "\\?" | "\\\\" | "\\a" | "\\b" | "\\f" | "\\n" | "\\r" | "\\t" | "\\v" );
      escape_sequence       = ( simple_escape_sequence | octal_escape_sequence | hexadecimal_escape_sequence | universal_character_name );
      c_char                = ( [^'\\] | escape_sequence );
      c_char_sequence       = c_char+;
      character_constant    = ( "'" | "L'" | 'u\'' ) c_char_sequence "'";

      s_char                = ( [^"\\] | escape_sequence );
      s_char_sequence       = s_char+;
      encoding_prefix       = ( "u8" | 'u' | "L" );
      string_literal        = encoding_prefix? "\"" s_char_sequence? "\"";

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
      integer_constant      { lval->emplace<std::string>(std::string(yypmatch[0], yypmatch[1])); token = yy::parser::token::INTEGER_CONSTANT; break; }
      floating_constant     { lval->emplace<std::string>(std::string(yypmatch[0], yypmatch[1])); token = yy::parser::token::FLOATING_CONSTANT; break; }
      character_constant    { lval->emplace<std::string>(std::string(yypmatch[0], yypmatch[1])); token = yy::parser::token::CHARACTER_CONSTANT; break; }
      string_literal        { lval->emplace<std::string>(std::string(yypmatch[0], yypmatch[1])); token = yy::parser::token::STRING_LITERAL; break; }

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
