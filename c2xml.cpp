#include "lexer.hpp"
#include "parser.hpp"
#include <boost/program_options.hpp>
#include <cassert>
#include <cstdarg>
#include <iostream>

#define DEBUG_BUFFER_SIZE 1024

extern int yy_flex_debug;

extern auto main(int argc, char **argv) -> int {
  using boost::program_options::command_line_parser;
  using boost::program_options::options_description;
  using boost::program_options::positional_options_description;
  using boost::program_options::value;
  using boost::program_options::variables_map;

  auto visible = options_description();
  // clang-format off
  visible.add_options()
    ("help,h", "Show help")
    ("verbose,v", "Get verbose")
    ("output,o", value<std::string>(), "Output file path");
  // clang-format on

  // clang-format off
  auto hidden = options_description();
  hidden.add_options()
    ("input", value<std::string>(), "Intput file path");
  // clang-format on

  auto options = variables_map();
  try {
    boost::program_options::store(
        command_line_parser(argc, argv)
            .options(options_description().add(visible).add(hidden))
            .positional(positional_options_description().add("input", 1))
            .run(),
        options);
    boost::program_options::notify(options);
  } catch (boost::program_options::error &e) {
    std::cerr << e.what() << std::endl;
    return EXIT_FAILURE;
  }

  if (options.count("help")) {
    std::cout << "Usage: " << argv[0] << " [options] [file]" << std::endl
              << "Options: " << std::endl
              << visible;
    return EXIT_SUCCESS;
  }

  yy_flex_debug = yydebug = options.count("verbose");

  if (options.count("input")) {
    yyin = std::fopen(options["input"].as<std::string>().c_str(), "r");
  }

  if (options.count("output")) {
    yyout = std::fopen(options["output"].as<std::string>().c_str(), "w");
  }

  yyparse();
  return EXIT_SUCCESS;
}

extern auto yyerror(std::string_view msg) -> void {
  std::cerr << yylloc.first_line << ':' << yylloc.first_column << '-'
            << yylloc.last_line << ':' << yylloc.last_column << ": " << msg
            << std::endl;
}

static auto debug(std::string header, char const *const format, va_list ap)
    -> void {
  static auto streams = std::map<std::string, std::stringstream>();

  auto &stream = streams.try_emplace(header).first->second;

  // create formatted C-string and put it to the stream
  char buffer[DEBUG_BUFFER_SIZE];
  assert(std::vsnprintf(buffer, DEBUG_BUFFER_SIZE, format, ap) <
         DEBUG_BUFFER_SIZE);
  stream << buffer;

  // print lines
  auto line = std::string();
  while (std::getline(stream, line)) {
    if (stream.eof()) {
      // when the last line has no '\n'
      stream.clear();
      stream << line;
      break;
    }

    std::cerr << "[" << header << "]\t" << line << std::endl;
  }

  stream.clear();
}

extern auto bison_fprintf(__attribute__((unused)) FILE *stream,
                          char const *const format, ...) -> int {
  va_list ap;
  va_start(ap, format);
  debug("bison", format, ap);
  va_end(ap);
  return 0;
}

extern auto flex_fprintf(__attribute__((unused)) FILE *stream,
                         char const *const format, ...) -> int {
  va_list ap;
  va_start(ap, format);
  debug("flex ", format, ap);
  va_end(ap);
  return 0;
}

// vim: set ts=2 sw=2 et:
