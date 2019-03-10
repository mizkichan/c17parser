# `c2xml`

A converter that transformes C (preprocessed) source code into XML representation of C concrete syntax tree.

## How to build and use

Requires C++17 compiler, Boost, re2c, bison. Clone this repo and `make`. Run `./c2xml [file]`.

## Examples

Prepare `hello.c`:

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

Then you will get this XML:

```xml
<?xml version="1.0" encoding="utf-8"?>
<translation-unit>
 <external-declaration>
  <function-definition>
   <declaration-specifiers>
    <type-specifier>
     <keyword>int</keyword>
    </type-specifier>
   </declaration-specifiers>
   <declarator>
    <direct-declarator>
     <direct-declarator>
      <identifier>main</identifier>
     </direct-declarator>
     <punctuator>(</punctuator>
     <parameter-type-list>
      <parameter-list>
       <parameter-declaration>
        <declaration-specifiers>
         <type-specifier>
          <keyword>void</keyword>
         </type-specifier>
        </declaration-specifiers>
       </parameter-declaration>
      </parameter-list>
     </parameter-type-list>
     <punctuator>)</punctuator>
    </direct-declarator>
   </declarator>
   <compound-statement>
    <punctuator>{</punctuator>
    <block-item-list>
     <block-item-list>
      <block-item>
       <statement>
        <expression-statement>
         <expression>
          <assignment-expression>
           <conditional-expression>
            <logical-OR-expression>
             <logical-AND-expression>
              <inclusive-OR-expression>
               <exclusive-OR-expression>
                <AND-expression>
                 <equality-expression>
                  <relational-expression>
                   <shift-expression>
                    <additive-expression>
                     <multiplicative-expression>
                      <cast-expression>
                       <unary-expression>
                        <postfix-expression>
                         <postfix-expression>
                          <primary-expression>
                           <identifier>printf</identifier>
                          </primary-expression>
                         </postfix-expression>
                         <punctuator>(</punctuator>
                         <argument-expression-list>
                          <assignment-expression>
                           <conditional-expression>
                            <logical-OR-expression>
                             <logical-AND-expression>
                              <inclusive-OR-expression>
                               <exclusive-OR-expression>
                                <AND-expression>
                                 <equality-expression>
                                  <relational-expression>
                                   <shift-expression>
                                    <additive-expression>
                                     <multiplicative-expression>
                                      <cast-expression>
                                       <unary-expression>
                                        <postfix-expression>
                                         <primary-expression>
                                          <string-literal>&quot;Hello, world!\n&quot;</string-literal>
                                         </primary-expression>
                                        </postfix-expression>
                                       </unary-expression>
                                      </cast-expression>
                                     </multiplicative-expression>
                                    </additive-expression>
                                   </shift-expression>
                                  </relational-expression>
                                 </equality-expression>
                                </AND-expression>
                               </exclusive-OR-expression>
                              </inclusive-OR-expression>
                             </logical-AND-expression>
                            </logical-OR-expression>
                           </conditional-expression>
                          </assignment-expression>
                         </argument-expression-list>
                         <punctuator>)</punctuator>
                        </postfix-expression>
                       </unary-expression>
                      </cast-expression>
                     </multiplicative-expression>
                    </additive-expression>
                   </shift-expression>
                  </relational-expression>
                 </equality-expression>
                </AND-expression>
               </exclusive-OR-expression>
              </inclusive-OR-expression>
             </logical-AND-expression>
            </logical-OR-expression>
           </conditional-expression>
          </assignment-expression>
         </expression>
         <punctuator>;</punctuator>
        </expression-statement>
       </statement>
      </block-item>
     </block-item-list>
     <block-item>
      <statement>
       <jump-statement>
        <keyword>return</keyword>
        <expression>
         <assignment-expression>
          <conditional-expression>
           <logical-OR-expression>
            <logical-AND-expression>
             <inclusive-OR-expression>
              <exclusive-OR-expression>
               <AND-expression>
                <equality-expression>
                 <relational-expression>
                  <shift-expression>
                   <additive-expression>
                    <multiplicative-expression>
                     <cast-expression>
                      <unary-expression>
                       <postfix-expression>
                        <primary-expression>
                         <constant>
                          <integer-constant>0</integer-constant>
                         </constant>
                        </primary-expression>
                       </postfix-expression>
                      </unary-expression>
                     </cast-expression>
                    </multiplicative-expression>
                   </additive-expression>
                  </shift-expression>
                 </relational-expression>
                </equality-expression>
               </AND-expression>
              </exclusive-OR-expression>
             </inclusive-OR-expression>
            </logical-AND-expression>
           </logical-OR-expression>
          </conditional-expression>
         </assignment-expression>
        </expression>
        <punctuator>;</punctuator>
       </jump-statement>
      </statement>
     </block-item>
    </block-item-list>
    <punctuator>}</punctuator>
   </compound-statement>
  </function-definition>
 </external-declaration>
</translation-unit>
```

Note that `c2xml` input source code must be preprocessed; that is, input code should not include preprocessor directives, such as `#include` or `#define`.

## Things to be done

- Make `c2xml` at least ignore preprocessor directives so that users can achieve their goals faster.
- Implement string literal concatenation, for C preprocessors seem not to do it.
- `__attribute__`, `__asm__`, `__restrict`, `__inline`, etc.

I will appreciate any form of your contribution or cooperation.
