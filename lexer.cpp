#include "lexer.hpp"
#include <regex>

static auto check_type(std::string const &, yy::parser::location_type const &)
    -> yy::parser::symbol_type;
static auto is_enumeration_constant(std::string_view) -> bool;
static auto is_typedef_name(std::string_view) -> bool;

static std::vector<std::string> enum_consts;
static std::vector<std::string> typedef_names = {
    "__builtin_va_list",
};

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

    STRING("...", HELLIP);
    STRING("<<=", LAQUO_EQ);
    STRING(">>=", RAQUO_EQ);
    STRING("!=", EXCL_EQ);
    STRING("<=", LT_EQ);
    STRING("==", EQ_EQ);
    STRING(">=", GT_EQ);
    STRING("%=", PERCNT_EQ);
    STRING("*=", AST_EQ);
    STRING("+=", PLUS_EQ);
    STRING("-=", MINUS_EQ);
    STRING("/=", SOL_EQ);
    STRING("&&", AMP_AMP);
    STRING("||", VERT_VERT);
    STRING("&=", AMP_EQ);
    STRING("^=", HAT_EQ);
    STRING("|=", VERT_EQ);
    STRING("++", PLUS_PLUS);
    STRING("--", MINUS_MINUS);
    STRING("->", RARR);
    STRING("<<", LAQUO);
    STRING(">>", RAQUO);
    STRING("!", EXCL);
    STRING("%", PERCNT);
    STRING("&", AMP);
    STRING("(", LPAR);
    STRING(")", RPAR);
    STRING("*", AST);
    STRING("+", PLUS);
    STRING(",", COMMA);
    STRING("-", MINUS);
    STRING(".", PERIOD);
    STRING("/", SOL);
    STRING(":", COLON);
    STRING(";", SEMI);
    STRING("<", LT);
    STRING("=", EQ);
    STRING(">", GT);
    STRING("?", QUEST);
    STRING("[", LSQB);
    STRING("]", RSQB);
    STRING("^", HAT);
    STRING("{", LCUB);
    STRING("|", VERT);
    STRING("}", RCUB);
    STRING("~", TILDE);

    REGEX("[_[:alpha:]][_[:alnum:]]*", { return check_type(yytext, yylloc); });
    REGEX("[1-9][0-9]*",
          { return yy::parser::make_INTEGER_CONSTANT(yytext, yylloc); });
    REGEX("0[0-7]*",
          { return yy::parser::make_INTEGER_CONSTANT(yytext, yylloc); });
    REGEX("(?:0x|0X)[:alnum:]+",
          { return yy::parser::make_INTEGER_CONSTANT(yytext, yylloc); });

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
