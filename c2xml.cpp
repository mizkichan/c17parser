#include "lexer.hpp"
#include "parser.tab.hpp"
#include <boost/program_options.hpp>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <fstream>

using ptree = boost::property_tree::ptree;

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

  if (options.count("input")) {
    filename = options["input"].as<std::string>();
    input = new std::ifstream(filename->c_str());
  }

  ptree result;
  auto yyparse = yy::parser(result);
  yyparse.set_debug_level(options.count("verbose"));
  if (yyparse() == 0) {
    auto output = &std::cout;
    if (options.count("output")) {
      output = new std::ofstream(options["output"].as<std::string>());
    }

    boost::property_tree::write_xml(
        *output, result,
        boost::property_tree::xml_writer_make_settings<ptree::key_type>(' ',
                                                                        1));
    *output << std::endl;
    return EXIT_SUCCESS;
  } else {
    return EXIT_FAILURE;
  }
}

// vim: set ts=2 sw=2 et:
