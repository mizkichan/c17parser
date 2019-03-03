# `c2xml`

A converter whcih processes C preprocessed source code to XML representation of C concrete syntax tree.

## How to build and use

Requires C++17 compiler, boost, re2c, bison. Clone this reop and `make`. Run `./c2xml [file]`.

## Examples

`hello.c`:

```c
int main(void) {
  printf("Hello, world!\n");
  return 0;
}
```

Run `c2xml`:

```sh
c2xml hello.c
```

Then you get:

```xml
<?xml version="1.0" encoding="utf-8"?>
<translation_unit>
 <external_declaration>
  <function_definition>
   <declaration_specifiers>
    <type_specifier>
     <INT>int</INT>
    </type_specifier>
   </declaration_specifiers>
   <declarator>
    <direct_declarator>
     <direct_declarator>
      <IDENTIFIER>main</IDENTIFIER>
     </direct_declarator>
     <LPAR>(</LPAR>
     <parameter_type_list>
      <parameter_list>
       <parameter_declaration>
        <declaration_specifiers>
         <type_specifier>
          <VOID>void</VOID>
         </type_specifier>
        </declaration_specifiers>
       </parameter_declaration>
      </parameter_list>
     </parameter_type_list>
     <RPAR>)</RPAR>
    </direct_declarator>
   </declarator>
   <compound_statement>
    <LCUB>{</LCUB>
    <block_item_list>
     <block_item_list>
      <block_item>
       <statement>
        <expression_statement>
         <expression>
          <assignment_expression>
           <conditional_expression>
            <logical_OR_expression>
             <logical_AND_expression>
              <inclusive_OR_expression>
               <exclusive_OR_expression>
                <AND_expression>
                 <equality_expression>
                  <relational_expression>
                   <shift_expression>
                    <additive_expression>
                     <multiplicative_expression>
                      <cast_expression>
                       <unary_expression>
                        <postfix_expression>
                         <postfix_expression>
                          <primary_expression>
                           <IDENTIFIER>printf</IDENTIFIER>
                          </primary_expression>
                         </postfix_expression>
                         <LPAR>(</LPAR>
                         <argument_expression_list>
                          <assignment_expression>
                           <conditional_expression>
                            <logical_OR_expression>
                             <logical_AND_expression>
                              <inclusive_OR_expression>
                               <exclusive_OR_expression>
                                <AND_expression>
                                 <equality_expression>
                                  <relational_expression>
                                   <shift_expression>
                                    <additive_expression>
                                     <multiplicative_expression>
                                      <cast_expression>
                                       <unary_expression>
                                        <postfix_expression>
                                         <primary_expression>
                                          <STRING_LITERAL>&quot;Hello, world!\n&quot;</STRING_LITERAL>
                                         </primary_expression>
                                        </postfix_expression>
                                       </unary_expression>
                                      </cast_expression>
                                     </multiplicative_expression>
                                    </additive_expression>
                                   </shift_expression>
                                  </relational_expression>
                                 </equality_expression>
                                </AND_expression>
                               </exclusive_OR_expression>
                              </inclusive_OR_expression>
                             </logical_AND_expression>
                            </logical_OR_expression>
                           </conditional_expression>
                          </assignment_expression>
                         </argument_expression_list>
                         <RPAR>)</RPAR>
                        </postfix_expression>
                       </unary_expression>
                      </cast_expression>
                     </multiplicative_expression>
                    </additive_expression>
                   </shift_expression>
                  </relational_expression>
                 </equality_expression>
                </AND_expression>
               </exclusive_OR_expression>
              </inclusive_OR_expression>
             </logical_AND_expression>
            </logical_OR_expression>
           </conditional_expression>
          </assignment_expression>
         </expression>
         <SEMI>;</SEMI>
        </expression_statement>
       </statement>
      </block_item>
     </block_item_list>
     <block_item>
      <statement>
       <jump_statement>
        <RETURN>return</RETURN>
        <expression>
         <assignment_expression>
          <conditional_expression>
           <logical_OR_expression>
            <logical_AND_expression>
             <inclusive_OR_expression>
              <exclusive_OR_expression>
               <AND_expression>
                <equality_expression>
                 <relational_expression>
                  <shift_expression>
                   <additive_expression>
                    <multiplicative_expression>
                     <cast_expression>
                      <unary_expression>
                       <postfix_expression>
                        <primary_expression>
                         <constant>
                          <INTEGER_CONSTANT>0</INTEGER_CONSTANT>
                         </constant>
                        </primary_expression>
                       </postfix_expression>
                      </unary_expression>
                     </cast_expression>
                    </multiplicative_expression>
                   </additive_expression>
                  </shift_expression>
                 </relational_expression>
                </equality_expression>
               </AND_expression>
              </exclusive_OR_expression>
             </inclusive_OR_expression>
            </logical_AND_expression>
           </logical_OR_expression>
          </conditional_expression>
         </assignment_expression>
        </expression>
        <SEMI>;</SEMI>
       </jump_statement>
      </statement>
     </block_item>
    </block_item_list>
    <RCUB>}</RCUB>
   </compound_statement>
  </function_definition>
 </external_declaration>
</translation_unit>
```

Note that `c2xml` input source code must be preprocessed; that is, input code should not include preprocessor directives, such as `#include` adn `#define`.
