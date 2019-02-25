%code {
/* Unqualified "%code" block which will be emitted into .cpp */
}

%code requires {
/* "%code requires" block for dependency codes of YYSTYPE and YYLTYPE */
#include <string>
}

%code provides {
/* "%code provides" block for declarations in other object files */
#include <string_view>

extern auto yylex(void) -> yy::parser::symbol_type;
extern auto add_enumeration_constant(std::string_view) -> void;
extern auto add_typedef_name(std::string_view) -> void;
}

%define api.token.constructor
%define api.value.type variant
%define parse.assert
%define parse.error verbose
%define parse.trace
%language "c++"
%locations
%require "3.2"

%token AUTO BREAK CASE CHAR CONST CONTINUE DEFAULT DO DOUBLE ELSE ENUM EXTERN FLOAT FOR GOTO IF INLINE INT LONG REGISTER RESTRICT RETURN SHORT SIGNED SIZEOF STATIC STRUCT SWITCH TYPEDEF UNION UNSIGNED VOID VOLATILE WHILE ALIGNAS ALIGNOF ATOMIC BOOL COMPLEX GENERIC IMAGINARY NORETURN STATIC_ASSERT THREAD_LOCAL
%token ELLIPSIS LEFT_ASSIGN RIGHT_ASSIGN NOT_EQUAL LESS_EQUAL EQUAL GREATER_EQUAL MOD_ASSIGN MUL_ASSIGN ADD_ASSIGN SUB_ASSIGN DIV_ASSIGN AND OR AND_ASSIGN XOR_ASSIGN OR_ASSIGN INCREMENT DECREMENT ARROW LEFT RIGHT EXCLAMATION PERCENT AMPASAND LEFT_PAREN RIGHT_PAREN ASTERISK PLUS COMMA MINUS DOT SLASH COLON SEMICOLON LESS_THAN ASSIGN GREATER_THAN QUESTION LEFT_BRACKET RIGHT_BRACKET CIRCUMFLEX LEFT_BRACE BAR RIGHT_BRACE TILDE
%token <std::string> INTEGER_CONSTANT FLOATING_CONSTANT CHARACTER_CONSTANT
%token <std::string> IDENTIFIER ENUMERATION_CONSTANT TYPEDEF_NAME STRING_LITERAL
%token END_OF_FILE 0

%start translation_unit

%%

constant: INTEGER_CONSTANT
        | FLOATING_CONSTANT
        | ENUMERATION_CONSTANT
        | CHARACTER_CONSTANT
        ;

enumeration_constant: IDENTIFIER  { add_enumeration_constant($1); }
                    ;

primary_expression: IDENTIFIER
                  | constant
                  | STRING_LITERAL
                  | LEFT_PAREN expression RIGHT_PAREN
                  | generic_selection
                  ;

generic_selection: GENERIC LEFT_PAREN assignment_expression COMMA generic_assoc_list RIGHT_PAREN
                 ;

generic_assoc_list: generic_association
                  | generic_assoc_list COMMA generic_association
                  ;

generic_association: type_name COLON assignment_expression
                   | DEFAULT COLON assignment_expression
                   ;

postfix_expression: primary_expression
                  | postfix_expression LEFT_BRACKET expression RIGHT_BRACKET
                  | postfix_expression LEFT_PAREN RIGHT_PAREN
                  | postfix_expression LEFT_PAREN argument_expression_list RIGHT_PAREN
                  | postfix_expression DOT IDENTIFIER
                  | postfix_expression ARROW IDENTIFIER
                  | postfix_expression INCREMENT
                  | postfix_expression DECREMENT
                  | LEFT_PAREN type_name RIGHT_PAREN LEFT_BRACE initializer_list RIGHT_BRACE
                  | LEFT_PAREN type_name RIGHT_PAREN LEFT_BRACE initializer_list COMMA RIGHT_BRACE
                  ;

argument_expression_list: assignment_expression
                        | argument_expression_list COMMA assignment_expression
                        ;

unary_expression: postfix_expression
                | INCREMENT unary_expression
                | DECREMENT unary_expression
                | unary_operator cast_expression
                | SIZEOF unary_expression
                | SIZEOF LEFT_PAREN type_name RIGHT_PAREN
                | ALIGNOF LEFT_PAREN type_name RIGHT_PAREN
                ;

unary_operator: AMPASAND | ASTERISK | PLUS | MINUS | TILDE | EXCLAMATION ;

cast_expression: unary_expression
               | LEFT_PAREN type_name RIGHT_PAREN cast_expression
               ;

multiplicative_expression: cast_expression
                         | multiplicative_expression ASTERISK cast_expression
                         | multiplicative_expression SLASH cast_expression
                         | multiplicative_expression PERCENT cast_expression
                         ;

additive_expression: multiplicative_expression
                   | additive_expression PLUS multiplicative_expression
                   | additive_expression MINUS multiplicative_expression
                   ;

shift_expression: additive_expression
                | shift_expression LEFT additive_expression
                | shift_expression RIGHT additive_expression
                ;

relational_expression: shift_expression
                     | relational_expression LESS_THAN shift_expression
                     | relational_expression GREATER_THAN shift_expression
                     | relational_expression LESS_EQUAL shift_expression
                     | relational_expression GREATER_EQUAL shift_expression
                     ;

equality_expression: relational_expression
                   | equality_expression EQUAL relational_expression
                   | equality_expression NOT_EQUAL relational_expression
                   ;

AND_expression: equality_expression
              | AND_expression AMPASAND equality_expression
              ;

exclusive_OR_expression: AND_expression
                       | exclusive_OR_expression CIRCUMFLEX AND_expression
                       ;

inclusive_OR_expression: exclusive_OR_expression
                       | inclusive_OR_expression BAR exclusive_OR_expression
                       ;

logical_AND_expression: inclusive_OR_expression
                      | logical_AND_expression AND inclusive_OR_expression
                      ;

logical_OR_expression: logical_AND_expression
                     | logical_OR_expression OR logical_AND_expression
                     ;

conditional_expression: logical_OR_expression
                      | logical_OR_expression QUESTION expression COLON conditional_expression
                      ;

assignment_expression: conditional_expression
                     | unary_expression assignment_operator assignment_expression
                     ;

assignment_operator: ASSIGN | MUL_ASSIGN | DIV_ASSIGN | MOD_ASSIGN | ADD_ASSIGN | SUB_ASSIGN | LEFT_ASSIGN | RIGHT_ASSIGN | AND_ASSIGN | XOR_ASSIGN | OR_ASSIGN ;

expression: assignment_expression
          | expression COMMA assignment_expression
          ;

constant_expression: conditional_expression
                   ;

declaration: declaration_specifiers SEMICOLON 
           | declaration_specifiers init_declarator_list SEMICOLON 
           | static_assert_declaration
           ;

declaration_specifiers: storage_class_specifier
                      | storage_class_specifier declaration_specifiers
                      | type_specifier
                      | type_specifier declaration_specifiers
                      | type_qualifier
                      | type_qualifier declaration_specifiers 
                      | function_specifier
                      | function_specifier declaration_specifiers
                      | alignment_specifier
                      | alignment_specifier declaration_specifiers
                      ;

init_declarator_list: init_declarator
                    | init_declarator_list COMMA init_declarator
                    ;

init_declarator: declarator
               | declarator ASSIGN initializer
               ;

storage_class_specifier: TYPEDEF | EXTERN | STATIC | THREAD_LOCAL | AUTO | REGISTER ;

type_specifier: VOID | CHAR | SHORT | INT | LONG | FLOAT | DOUBLE | SIGNED | UNSIGNED | BOOL | COMPLEX
              | atomic_type_specifier
              | struct_or_union_specifier
              | enum_specifier
              /*
              | typedef_name
              */
              | TYPEDEF_NAME
              ;

struct_or_union_specifier: struct_or_union LEFT_BRACE struct_declaration_list RIGHT_BRACE
                         | struct_or_union IDENTIFIER LEFT_BRACE struct_declaration_list RIGHT_BRACE
                         | struct_or_union IDENTIFIER
                         ;

struct_or_union: STRUCT | UNION ;

struct_declaration_list: struct_declaration
                       | struct_declaration_list struct_declaration
                       ;

struct_declaration: specifier_qualifier_list SEMICOLON
                  | specifier_qualifier_list struct_declarator_list SEMICOLON
                  | static_assert_declaration
                  ;

specifier_qualifier_list: type_specifier
                        | type_specifier specifier_qualifier_list
                        | type_qualifier
                        | type_qualifier specifier_qualifier_list
                        | alignment_specifier
                        | alignment_specifier specifier_qualifier_list
                        ;

struct_declarator_list: struct_declarator
                      | struct_declarator_list COMMA struct_declarator
                      ;

struct_declarator: declarator
                 | COLON constant_expression
                 | declarator COLON constant_expression
                 ;

enum_specifier: ENUM LEFT_BRACE enumerator_list RIGHT_BRACE
              | ENUM IDENTIFIER LEFT_BRACE enumerator_list RIGHT_BRACE
              | ENUM LEFT_BRACE enumerator_list COMMA RIGHT_BRACE
              | ENUM IDENTIFIER LEFT_BRACE enumerator_list COMMA RIGHT_BRACE
              | ENUM IDENTIFIER
              ;

enumerator_list: enumerator
               | enumerator_list COMMA enumerator
               ;

enumerator: enumeration_constant
          | enumeration_constant ASSIGN enumeration_constant
          ;

/* NOTE: following two rules make grammar ambiguous.
 * See https://stackoverflow.com/questions/10668941/c11-grammar-ambiguity-between-atomic-type-specifier-and-qualifier
 */

atomic_type_specifier: ATOMIC LEFT_PAREN type_name RIGHT_PAREN
                     ;

type_qualifier: CONST | RESTRICT | VOLATILE | ATOMIC ;

function_specifier: INLINE | NORETURN ;

alignment_specifier: ALIGNAS LEFT_PAREN type_name RIGHT_PAREN
                   | ALIGNAS LEFT_PAREN constant_expression RIGHT_PAREN
                   ;

declarator: direct_declarator
          | pointer direct_declarator
          ;

direct_declarator: IDENTIFIER
                 | LEFT_PAREN declarator RIGHT_PAREN
                 | direct_declarator LEFT_BRACKET RIGHT_BRACKET
                 | direct_declarator LEFT_BRACKET type_qualifier_list RIGHT_BRACKET
                 | direct_declarator LEFT_BRACKET assignment_expression RIGHT_BRACKET
                 | direct_declarator LEFT_BRACKET type_qualifier_list assignment_expression RIGHT_BRACKET
                 | direct_declarator LEFT_BRACKET STATIC assignment_expression RIGHT_BRACKET
                 | direct_declarator LEFT_BRACKET STATIC type_qualifier_list assignment_expression RIGHT_BRACKET
                 | direct_declarator LEFT_BRACKET type_qualifier_list STATIC assignment_expression RIGHT_BRACKET
                 | direct_declarator LEFT_BRACKET ASTERISK RIGHT_BRACKET
                 | direct_declarator LEFT_BRACKET type_qualifier_list ASTERISK RIGHT_BRACKET
                 | direct_declarator LEFT_PAREN parameter_type_list RIGHT_PAREN
                 | direct_declarator LEFT_PAREN RIGHT_PAREN
                 | direct_declarator LEFT_PAREN identifier_list RIGHT_PAREN
                 ;

/*
typedef_name: IDENTIFIER
            ;
*/

pointer: ASTERISK
       | ASTERISK type_qualifier_list
       | ASTERISK pointer
       | ASTERISK type_qualifier_list pointer
       ;

type_qualifier_list: type_qualifier
                   | type_qualifier_list type_qualifier
                   ;

parameter_type_list: parameter_list
                   | parameter_list COMMA ELLIPSIS
                   ;

parameter_list: parameter_declaration
              | parameter_list COMMA parameter_declaration
              ;

parameter_declaration: declaration_specifiers declarator
                     | declaration_specifiers
                     | declaration_specifiers abstract_declarator
                     ;

identifier_list: IDENTIFIER
               | identifier_list COMMA IDENTIFIER
               ;

type_name: specifier_qualifier_list
         | specifier_qualifier_list abstract_declarator
         ;

abstract_declarator: pointer
                   | direct_abstract_declarator
                   | pointer direct_abstract_declarator
                   ;

direct_abstract_declarator: LEFT_PAREN abstract_declarator RIGHT_PAREN
                          | LEFT_BRACKET RIGHT_BRACKET
                          | direct_abstract_declarator LEFT_BRACKET RIGHT_BRACKET
                          | LEFT_BRACKET type_qualifier_list RIGHT_BRACKET
                          | direct_abstract_declarator LEFT_BRACKET type_qualifier_list RIGHT_BRACKET
                          | LEFT_BRACKET assignment_expression RIGHT_BRACKET
                          | direct_abstract_declarator LEFT_BRACKET assignment_expression RIGHT_BRACKET
                          | LEFT_BRACKET type_qualifier_list assignment_expression RIGHT_BRACKET
                          | direct_abstract_declarator LEFT_BRACKET type_qualifier_list assignment_expression RIGHT_BRACKET
                          | LEFT_BRACKET STATIC assignment_expression RIGHT_BRACKET
                          | direct_abstract_declarator LEFT_BRACKET STATIC assignment_expression RIGHT_BRACKET
                          | LEFT_BRACKET STATIC type_qualifier_list assignment_expression RIGHT_BRACKET
                          | direct_abstract_declarator LEFT_BRACKET STATIC type_qualifier_list assignment_expression RIGHT_BRACKET
                          | LEFT_BRACKET type_qualifier_list STATIC assignment_expression RIGHT_BRACKET
                          | direct_abstract_declarator LEFT_BRACKET type_qualifier_list STATIC assignment_expression RIGHT_BRACKET
                          | LEFT_BRACKET ASTERISK RIGHT_BRACKET
                          | direct_abstract_declarator LEFT_BRACKET ASTERISK RIGHT_BRACKET
                          | LEFT_PAREN RIGHT_PAREN
                          | direct_abstract_declarator LEFT_PAREN RIGHT_PAREN
                          | LEFT_PAREN parameter_type_list RIGHT_PAREN
                          | direct_abstract_declarator LEFT_PAREN parameter_type_list RIGHT_PAREN
                          ;

initializer: assignment_expression
           | LEFT_BRACE initializer_list RIGHT_BRACE
           | LEFT_BRACE identifier_list COMMA RIGHT_BRACE
           ;

initializer_list: initializer
                | designation initializer
                | initializer_list COMMA initializer
                | initializer_list COMMA designation initializer
                ;

designation: designation_list ASSIGN
           ;

designation_list: designator
                | designation_list designator
                ;

designator: LEFT_BRACKET constant_expression RIGHT_BRACKET
          | DOT IDENTIFIER
          ;

static_assert_declaration: STATIC_ASSERT LEFT_PAREN constant_expression COMMA STRING_LITERAL RIGHT_PAREN SEMICOLON
                         ;

statement: labeled_statement
         | compound_statement
         | expression_statement
         | selection_statement
         | iteration_statement
         | jump_statement
         ;


labeled_statement: IDENTIFIER COLON statement
                 | CASE constant_expression COLON statement
                 | DEFAULT COLON statement
                 ;

compound_statement: LEFT_BRACE RIGHT_BRACE
                  | LEFT_BRACE block_item_list RIGHT_BRACE
                  ;

block_item_list: block_item
               | block_item_list block_item
               ;

block_item: declaration
          | statement
          ;

expression_statement: SEMICOLON
                    | expression SEMICOLON
                    ;

selection_statement: IF LEFT_PAREN expression RIGHT_PAREN statement
                   | IF LEFT_PAREN expression RIGHT_PAREN statement ELSE statement
                   | SWITCH LEFT_PAREN expression RIGHT_PAREN statement
                   ;

iteration_statement: WHILE LEFT_PAREN expression RIGHT_PAREN statement
                   | DO statement WHILE LEFT_PAREN expression RIGHT_PAREN SEMICOLON
                   | FOR LEFT_PAREN SEMICOLON SEMICOLON RIGHT_PAREN statement
                   | FOR LEFT_PAREN expression SEMICOLON SEMICOLON RIGHT_PAREN statement
                   | FOR LEFT_PAREN SEMICOLON expression SEMICOLON RIGHT_PAREN statement
                   | FOR LEFT_PAREN SEMICOLON SEMICOLON expression RIGHT_PAREN statement
                   | FOR LEFT_PAREN expression SEMICOLON expression SEMICOLON RIGHT_PAREN statement
                   | FOR LEFT_PAREN expression SEMICOLON SEMICOLON expression RIGHT_PAREN statement
                   | FOR LEFT_PAREN SEMICOLON expression SEMICOLON expression RIGHT_PAREN statement
                   | FOR LEFT_PAREN expression SEMICOLON expression SEMICOLON expression RIGHT_PAREN statement
                   | FOR LEFT_PAREN declaration SEMICOLON RIGHT_PAREN statement
                   | FOR LEFT_PAREN declaration expression SEMICOLON RIGHT_PAREN statement
                   | FOR LEFT_PAREN declaration SEMICOLON expression RIGHT_PAREN statement
                   | FOR LEFT_PAREN declaration expression SEMICOLON expression RIGHT_PAREN statement
                   ;

jump_statement: GOTO IDENTIFIER SEMICOLON
              | CONTINUE SEMICOLON
              | BREAK SEMICOLON
              | RETURN SEMICOLON
              | RETURN expression SEMICOLON
              ;

translation_unit: external_declaration
                | translation_unit external_declaration
                ;

external_declaration: function_definition
                    | declaration 
                    ;

function_definition: declaration_specifiers declarator compound_statement
                   | declaration_specifiers declarator declaration_list compound_statement
                   ;

declaration_list: declaration
                | declaration_list declaration 
                ;

%%

auto yy::parser::error(parser::location_type const &yylloc, std::string const &msg) -> void {
  std::cerr << yylloc << ": " << msg << std::endl;
}

/* vim: set ts=2 sw=2 et: */
