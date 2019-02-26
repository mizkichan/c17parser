#include "parser.hpp"
#include <algorithm>
#include <regex>
#include <string>
#include <string_view>
#include <vector>

extern auto yylex(void) -> yy::parser::symbol_type;
static auto check_type(std::string const &, yy::parser::location_type const &)
    -> yy::parser::symbol_type;
extern auto add_enumeration_constant(std::string_view) -> void;
extern auto add_typedef_name(std::string_view) -> void;
static auto is_enumeration_constant(std::string_view) -> bool;
static auto is_typedef_name(std::string_view) -> bool;

extern std::istream *yyin;
extern std::optional<std::string> yyfile;
static std::vector<std::string> enum_consts;
static std::vector<std::string> typedef_names;

std::istream *yyin = &std::cin;
std::optional<std::string> yyfile;

auto advance(std::string_view &line, std::string::size_type yyleng,
             yy::parser::location_type &yylloc) -> void {
  line.remove_prefix(yyleng);
  yylloc.begin.column = yylloc.end.column;
  yylloc.end.column += yyleng;
}

#define STRING(S, T)                                                           \
  if (line.find((S)) == 0) {                                                   \
    advance(line, std::size((S)) - 1, yylloc);                                 \
    auto copied = yylloc; /* sucks */                                          \
    return yy::parser::symbol_type(yy::parser::token::T, std::move(copied));   \
  }

#define REGEX(S, ACTION)                                                       \
  {                                                                            \
    auto e = std::regex((S), std::regex_constants::optimize);                  \
    std::smatch m;                                                             \
    auto ownedline = std::string(line); /* sucks */                            \
    if (std::regex_search(ownedline, m, e,                                     \
                          std::regex_constants::match_continuous)) {           \
      advance(line, m.length(), yylloc);                                       \
      auto yytext = m.str();                                                   \
      ACTION                                                                   \
    }                                                                          \
  }

auto yylex(void) -> yy::parser::symbol_type {
  static std::string buffer;
  static std::string_view line;
  static yy::parser::location_type yylloc(
      []() {
        if (yyfile.has_value())
          return &*yyfile;
        else
          return static_cast<std::string *>(nullptr);
      }(),
      0, 0);

  while (*yyin) {
    if (line.empty()) {
      std::getline(*yyin, buffer);
      line = buffer;
      yylloc.begin.line = ++yylloc.end.line;
      yylloc.begin.column = yylloc.end.column = 1;
    }

    STRING("_Static_assert", STATIC_ASSERT);
    STRING("_Thread_local", THREAD_LOCAL);
    STRING("_Imaginary", IMAGINARY);
    STRING("_Noreturn", NORETURN);
    STRING("_Alignas", ALIGNAS);
    STRING("_Alignof", ALIGNOF);
    STRING("_Complex", COMPLEX);
    STRING("_Generic", GENERIC);
    STRING("continue", CONTINUE);
    STRING("register", REGISTER);
    STRING("restrict", RESTRICT);
    STRING("unsigned", UNSIGNED);
    STRING("volatile", VOLATILE);
    STRING("default", DEFAULT);
    STRING("typedef", TYPEDEF);
    STRING("_Atomic", ATOMIC);
    STRING("double", DOUBLE);
    STRING("extern", EXTERN);
    STRING("inline", INLINE);
    STRING("return", RETURN);
    STRING("signed", SIGNED);
    STRING("sizeof", SIZEOF);
    STRING("static", STATIC);
    STRING("struct", STRUCT);
    STRING("switch", SWITCH);
    STRING("_Bool", BOOL);
    STRING("break", BREAK);
    STRING("const", CONST);
    STRING("float", FLOAT);
    STRING("short", SHORT);
    STRING("union", UNION);
    STRING("while", WHILE);
    STRING("auto", AUTO);
    STRING("case", CASE);
    STRING("char", CHAR);
    STRING("else", ELSE);
    STRING("enum", ENUM);
    STRING("goto", GOTO);
    STRING("long", LONG);
    STRING("void", VOID);
    STRING("for", FOR);
    STRING("int", INT);
    STRING("do", DO);
    STRING("if", IF);

    STRING("...", ELLIPSIS);
    STRING("<<=", LEFT_ASSIGN);
    STRING(">>=", RIGHT_ASSIGN);
    STRING("!=", NOT_EQUAL);
    STRING("<=", LESS_EQUAL);
    STRING("==", EQUAL);
    STRING(">=", GREATER_EQUAL);
    STRING("%=", MOD_ASSIGN);
    STRING("*=", MUL_ASSIGN);
    STRING("+=", ADD_ASSIGN);
    STRING("-=", SUB_ASSIGN);
    STRING("/=", DIV_ASSIGN);
    STRING("&&", AND);
    STRING("||", OR);
    STRING("&=", AND_ASSIGN);
    STRING("^=", XOR_ASSIGN);
    STRING("|=", OR_ASSIGN);
    STRING("++", INCREMENT);
    STRING("--", DECREMENT);
    STRING("->", ARROW);
    STRING("<<", LEFT);
    STRING(">>", RIGHT);
    STRING("!", EXCLAMATION);
    STRING("%", PERCENT);
    STRING("&", AMPASAND);
    STRING("(", LEFT_PAREN);
    STRING(")", RIGHT_PAREN);
    STRING("*", ASTERISK);
    STRING("+", PLUS);
    STRING(",", COMMA);
    STRING("-", MINUS);
    STRING(".", DOT);
    STRING("/", SLASH);
    STRING(":", COLON);
    STRING(";", SEMICOLON);
    STRING("<", LESS_THAN);
    STRING("=", ASSIGN);
    STRING(">", GREATER_THAN);
    STRING("?", QUESTION);
    STRING("[", LEFT_BRACKET);
    STRING("]", RIGHT_BRACKET);
    STRING("^", CIRCUMFLEX);
    STRING("{", LEFT_BRACE);
    STRING("|", BAR);
    STRING("}", RIGHT_BRACE);
    STRING("~", TILDE);

    REGEX("[_[:alpha:]][_[:alnum:]]*", { return check_type(yytext, yylloc); });
    REGEX(R"([ \t\v\f]+)", { continue; });

    REGEX(".", {
      std::cerr << yylloc << ": '" << yytext << "'" << std::endl;
      break;
    });
  }

  return yy::parser::make_END_OF_FILE(yylloc);
}

auto check_type(std::string const &id, yy::parser::location_type const &yylloc)
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

// vim: set ts=2 sw=2 et:
