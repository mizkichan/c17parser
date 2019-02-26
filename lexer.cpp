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

#define STRING(S, ACTION)                                                      \
  if (line.find((S)) == 0) {                                                   \
    advance(line, std::size((S)) - 1, yylloc);                                 \
    ACTION                                                                     \
  }

#define TOKEN(S, T)                                                            \
  STRING(S, {                                                                  \
    auto copied = yylloc; /* sucks */                                          \
    return yy::parser::symbol_type(yy::parser::token::T, std::move(copied));   \
  })

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

    TOKEN("_Static_assert", STATIC_ASSERT);
    TOKEN("_Thread_local", THREAD_LOCAL);
    TOKEN("_Imaginary", IMAGINARY);
    TOKEN("_Noreturn", NORETURN);
    TOKEN("_Alignas", ALIGNAS);
    TOKEN("_Alignof", ALIGNOF);
    TOKEN("_Complex", COMPLEX);
    TOKEN("_Generic", GENERIC);
    TOKEN("continue", CONTINUE);
    TOKEN("register", REGISTER);
    TOKEN("restrict", RESTRICT);
    TOKEN("unsigned", UNSIGNED);
    TOKEN("volatile", VOLATILE);
    TOKEN("default", DEFAULT);
    TOKEN("typedef", TYPEDEF);
    TOKEN("_Atomic", ATOMIC);
    TOKEN("double", DOUBLE);
    TOKEN("extern", EXTERN);
    TOKEN("inline", INLINE);
    TOKEN("return", RETURN);
    TOKEN("signed", SIGNED);
    TOKEN("sizeof", SIZEOF);
    TOKEN("static", STATIC);
    TOKEN("struct", STRUCT);
    TOKEN("switch", SWITCH);
    TOKEN("_Bool", BOOL);
    TOKEN("break", BREAK);
    TOKEN("const", CONST);
    TOKEN("float", FLOAT);
    TOKEN("short", SHORT);
    TOKEN("union", UNION);
    TOKEN("while", WHILE);
    TOKEN("auto", AUTO);
    TOKEN("case", CASE);
    TOKEN("char", CHAR);
    TOKEN("else", ELSE);
    TOKEN("enum", ENUM);
    TOKEN("goto", GOTO);
    TOKEN("long", LONG);
    TOKEN("void", VOID);
    TOKEN("for", FOR);
    TOKEN("int", INT);
    TOKEN("do", DO);
    TOKEN("if", IF);

    TOKEN("...", ELLIPSIS);
    TOKEN("<<=", LEFT_ASSIGN);
    TOKEN(">>=", RIGHT_ASSIGN);
    TOKEN("!=", NOT_EQUAL);
    TOKEN("<=", LESS_EQUAL);
    TOKEN("==", EQUAL);
    TOKEN(">=", GREATER_EQUAL);
    TOKEN("%=", MOD_ASSIGN);
    TOKEN("*=", MUL_ASSIGN);
    TOKEN("+=", ADD_ASSIGN);
    TOKEN("-=", SUB_ASSIGN);
    TOKEN("/=", DIV_ASSIGN);
    TOKEN("&&", AND);
    TOKEN("||", OR);
    TOKEN("&=", AND_ASSIGN);
    TOKEN("^=", XOR_ASSIGN);
    TOKEN("|=", OR_ASSIGN);
    TOKEN("++", INCREMENT);
    TOKEN("--", DECREMENT);
    TOKEN("->", ARROW);
    TOKEN("<<", LEFT);
    TOKEN(">>", RIGHT);
    TOKEN("!", EXCLAMATION);
    TOKEN("%", PERCENT);
    TOKEN("&", AMPASAND);
    TOKEN("(", LEFT_PAREN);
    TOKEN(")", RIGHT_PAREN);
    TOKEN("*", ASTERISK);
    TOKEN("+", PLUS);
    TOKEN(",", COMMA);
    TOKEN("-", MINUS);
    TOKEN(".", DOT);
    TOKEN("/", SLASH);
    TOKEN(":", COLON);
    TOKEN(";", SEMICOLON);
    TOKEN("<", LESS_THAN);
    TOKEN("=", ASSIGN);
    TOKEN(">", GREATER_THAN);
    TOKEN("?", QUESTION);
    TOKEN("[", LEFT_BRACKET);
    TOKEN("]", RIGHT_BRACKET);
    TOKEN("^", CIRCUMFLEX);
    TOKEN("{", LEFT_BRACE);
    TOKEN("|", BAR);
    TOKEN("}", RIGHT_BRACE);
    TOKEN("~", TILDE);

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
