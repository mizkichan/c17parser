%code {
#include "lexer.h"
extern void add_enumeration_constant(char const *);
extern void add_typedef_name(char const *);
}

%code requires {
#include <stdint.h>
}

%code provides {
void yyerror(char const *);
}

%define parse.error verbose
%define parse.lac full
%define parse.trace
%locations

%union {
  char *str;
  uintmax_t num;
}

%token AUTO BREAK CASE CHAR CONST CONTINUE DEFAULT DO DOUBLE ELSE ENUM EXTERN FLOAT FOR GOTO IF INLINE INT LONG REGISTER RESTRICT RETURN SHORT SIGNED SIZEOF STATIC STRUCT SWITCH TYPEDEF UNION UNSIGNED VOID VOLATILE WHILE ALIGNAS ALIGNOF ATOMIC BOOL COMPLEX GENERIC IMAGINARY NORETURN STATIC_ASSERT THREAD_LOCAL
%token ELLIPSIS LEFT_ASSIGN RIGHT_ASSIGN NOT_EQUAL LESS_EQUAL EQUAL GREATER_EQUAL MOD_ASSIGN MUL_ASSIGN ADD_ASSIGN SUB_ASSIGN DIV_ASSIGN AND OR AND_ASSIGN XOR_ASSIGN OR_ASSIGN INCREMENT DECREMENT ARROW LEFT RIGHT
%token <num> INTEGER_CONSTANT FLOATING_CONSTANT CHARACTER_CONSTANT
%token <str> IDENTIFIER ENUMERATION_CONSTANT TYPEDEF_NAME STRING_LITERAL

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
                  | '(' expression ')'
                  | generic_selection
                  ;

generic_selection: GENERIC '(' assignment_expression ',' generic_assoc_list ')'
                 ;

generic_assoc_list: generic_association
                  | generic_assoc_list ',' generic_association
                  ;

generic_association: type_name ':' assignment_expression
                   | DEFAULT ':' assignment_expression
                   ;

postfix_expression: primary_expression
                  | postfix_expression '[' expression ']'
                  | postfix_expression '(' ')'
                  | postfix_expression '(' argument_expression_list ')'
                  | postfix_expression '.' IDENTIFIER
                  | postfix_expression ARROW IDENTIFIER
                  | postfix_expression INCREMENT
                  | postfix_expression DECREMENT
                  | '(' type_name ')' '{' initializer_list '}'
                  | '(' type_name ')' '{' initializer_list ',' '}'
                  ;

argument_expression_list: assignment_expression
                        | argument_expression_list ',' assignment_expression
                        ;

unary_expression: postfix_expression
                | INCREMENT unary_expression
                | DECREMENT unary_expression
                | unary_operator constant_expression
                | SIZEOF unary_expression
                | SIZEOF '(' type_name ')'
                | ALIGNOF '(' type_name ')'
                ;

unary_operator: '&' | '*' | '+' | '-' | '~' | '!' ;

cast_expression: unary_expression
               | '(' type_name ')' cast_expression
               ;

multiplicative_expression: cast_expression
                         | multiplicative_expression '*' cast_expression
                         | multiplicative_expression '/' cast_expression
                         | multiplicative_expression '%' cast_expression
                         ;

additive_expression: multiplicative_expression
                   | additive_expression '+' multiplicative_expression
                   | additive_expression '-' multiplicative_expression ;

shift_expression: additive_expression
                | shift_expression LEFT additive_expression
                | shift_expression RIGHT additive_expression
                ;

relational_expression: shift_expression
                     | relational_expression '<' shift_expression
                     | relational_expression '>' shift_expression
                     | relational_expression LESS_EQUAL shift_expression
                     | relational_expression GREATER_EQUAL shift_expression
                     ;

equality_expression: relational_expression
                   | equality_expression EQUAL relational_expression
                   | equality_expression NOT_EQUAL relational_expression
                   ;

AND_expression: equality_expression
              | AND_expression '&' equality_expression
              ;

exclusive_OR_expression: AND_expression
                       | exclusive_OR_expression '^' AND_expression
                       ;

inclusive_OR_expression: exclusive_OR_expression
                       | inclusive_OR_expression '|' exclusive_OR_expression
                       ;

logical_AND_expression: inclusive_OR_expression
                      | logical_AND_expression AND inclusive_OR_expression
                      ;

logical_OR_expression: logical_AND_expression
                     | logical_OR_expression OR logical_AND_expression
                     ;

conditional_expression: logical_OR_expression
                      | logical_OR_expression '?' expression ':' conditional_expression
                      ;

assignment_expression: conditional_expression
                     | unary_expression assignment_operator assignment_expression
                     ;

assignment_operator: '=' | MUL_ASSIGN | DIV_ASSIGN | MOD_ASSIGN | ADD_ASSIGN | SUB_ASSIGN | LEFT_ASSIGN | RIGHT_ASSIGN | AND_ASSIGN | XOR_ASSIGN | OR_ASSIGN ;

expression: assignment_expression
          | expression ',' assignment_expression
          ;

constant_expression: conditional_expression
                   ;

declaration: declaration_specifiers ';' 
           | declaration_specifiers init_declarator_list ';' 
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
                    | init_declarator_list ',' init_declarator
                    ;

init_declarator: declarator
               | declarator '=' initializer
               ;

storage_class_specifier: TYPEDEF | EXTERN | STATIC | THREAD_LOCAL | AUTO | REGISTER ;

type_specifier: VOID | CHAR | SHORT | INT | LONG | FLOAT | DOUBLE | SIGNED | UNSIGNED | BOOL | COMPLEX
              | atomic_type_specifier
              | struct_or_union_specifier
              | enum_specifier
              | typedef_name
              ;

struct_or_union_specifier: struct_or_union '{' struct_declaration_list '}'
                         | struct_or_union IDENTIFIER '{' struct_declaration_list '}'
                         | struct_or_union IDENTIFIER
                         ;

struct_or_union: STRUCT | UNION ;

struct_declaration_list: struct_declaration
                       | struct_declaration_list struct_declaration
                       ;

struct_declaration: specifier_qualifier_list ';'
                  | specifier_qualifier_list struct_declarator_list ';'
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
                      | struct_declarator_list ',' struct_declarator
                      ;

struct_declarator: declarator
                 | ':' constant_expression
                 | declarator ':' constant_expression
                 ;

enum_specifier: ENUM '{' enumerator_list '}'
              | ENUM IDENTIFIER '{' enumerator_list '}'
              | ENUM '{' enumerator_list ',' '}'
              | ENUM IDENTIFIER '{' enumerator_list ',' '}'
              | ENUM IDENTIFIER
              ;

enumerator_list: enumerator
               | enumerator_list ',' enumerator
               ;

enumerator: enumeration_constant
          | enumeration_constant '=' enumeration_constant
          ;

atomic_type_specifier: ATOMIC '(' type_name ')'
                     ;

type_qualifier: CONST | RESTRICT | VOLATILE | ATOMIC ;

function_specifier: INLINE | NORETURN ;

alignment_specifier: ALIGNAS '(' type_name ')'
                   | ALIGNAS '(' constant_expression ')'
                   ;

declarator: direct_declarator
          | pointer direct_declarator
          ;

direct_declarator: IDENTIFIER
                 | '(' declarator ')'
                 | direct_declarator '[' ']'
                 | direct_declarator '[' type_qualifier_list ']'
                 | direct_declarator '[' assignment_expression ']'
                 | direct_declarator '[' type_qualifier_list assignment_expression ']'
                 | direct_declarator '[' STATIC assignment_expression ']'
                 | direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'
                 | direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'
                 | direct_declarator '[' '*' ']'
                 | direct_declarator '[' type_qualifier_list '*' ']'
                 | direct_declarator '(' parameter_type_list ')'
                 | direct_declarator '(' ')'
                 | direct_declarator '(' identifier_list ')'
                 ;

typedef_name: TYPEDEF_NAME
            | IDENTIFIER  { add_typedef_name($1); }
            ;

pointer: '*'
       | '*' type_qualifier_list
       | '*' pointer
       | '*' type_qualifier_list pointer
       ;

type_qualifier_list: type_qualifier
                   | type_qualifier_list type_qualifier
                   ;

parameter_type_list: parameter_list
                   | parameter_list ',' ELLIPSIS
                   ;

parameter_list: parameter_declaration
              | parameter_list ',' parameter_declaration
              ;

parameter_declaration: declaration_specifiers declarator
                     | declaration_specifiers
                     | declaration_specifiers abstract_declarator
                     ;

identifier_list: IDENTIFIER
               | identifier_list ',' IDENTIFIER
               ;

type_name: specifier_qualifier_list
         | specifier_qualifier_list abstract_declarator
         ;

abstract_declarator: pointer
                   | direct_abstract_declarator
                   | pointer direct_abstract_declarator
                   ;

direct_abstract_declarator: '(' abstract_declarator ')'
                          | '[' ']'
                          | direct_abstract_declarator '[' ']'
                          | '[' type_qualifier_list ']'
                          | direct_abstract_declarator '[' type_qualifier_list ']'
                          | '[' assignment_expression ']'
                          | direct_abstract_declarator '[' assignment_expression ']'
                          | '[' type_qualifier_list assignment_expression ']'
                          | direct_abstract_declarator '[' type_qualifier_list assignment_expression ']'
                          | '[' STATIC assignment_expression ']'
                          | direct_abstract_declarator '[' STATIC assignment_expression ']'
                          | '[' STATIC type_qualifier_list assignment_expression ']'
                          | direct_abstract_declarator '[' STATIC type_qualifier_list assignment_expression ']'
                          | '[' type_qualifier_list STATIC assignment_expression ']'
                          | direct_abstract_declarator '[' type_qualifier_list STATIC assignment_expression ']'
                          | '[' '*' ']'
                          | direct_abstract_declarator '[' '*' ']'
                          | '(' ')'
                          | direct_abstract_declarator '(' ')'
                          | '(' parameter_type_list ')'
                          | direct_abstract_declarator '(' parameter_type_list ')'
                          ;

initializer: assignment_expression
           | '{' initializer_list '}'
           | '{' identifier_list ',' '}'
           ;

initializer_list: initializer
                | designation initializer
                | initializer_list ',' initializer
                | initializer_list ',' designation initializer
                ;

designation: designation_list '='
           ;

designation_list: designator
                | designation_list designator
                ;

designator: '[' constant_expression ']'
          | '.' IDENTIFIER
          ;

static_assert_declaration: STATIC_ASSERT '(' constant_expression ',' STRING_LITERAL ')' ';'
                         ;

statement: labeled_statement
         | compound_statement
         | expression_statement
         | selection_statement
         | iteration_statement
         | jump_statement
         ;


labeled_statement: IDENTIFIER ':' statement
                 | CASE constant_expression ':' statement
                 | DEFAULT ':' statement
                 ;

compound_statement: '{' '}'
                  | '{' block_item_list '}'
                  ;

block_item_list: block_item
               | block_item_list block_item
               ;

block_item: declaration
          | statement
          ;

expression_statement: ';'
                    | expression ';'
                    ;

selection_statement: IF '(' expression ')' statement
                   | IF '(' expression ')' statement ELSE statement
                   | SWITCH '(' expression ')' statement
                   ;

iteration_statement: WHILE '(' expression ')' statement
                   | DO statement WHILE '(' expression ')' ';'
                   | FOR '(' ';' ';' ')' statement
                   | FOR '(' expression ';' ';' ')' statement
                   | FOR '(' ';' expression ';' ')' statement
                   | FOR '(' ';' ';' expression ')' statement
                   | FOR '(' expression ';' expression ';' ')' statement
                   | FOR '(' expression ';' ';' expression ')' statement
                   | FOR '(' ';' expression ';' expression ')' statement
                   | FOR '(' expression ';' expression ';' expression ')' statement
                   | FOR '(' declaration ';' ')' statement
                   | FOR '(' declaration expression ';' ')' statement
                   | FOR '(' declaration ';' expression ')' statement
                   | FOR '(' declaration expression ';' expression ')' statement
                   ;

jump_statement: GOTO IDENTIFIER ';'
              | CONTINUE ';'
              | BREAK ';'
              | RETURN ';'
              | RETURN expression ';'
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

/* vim: set ts=2 sw=2 et: */
