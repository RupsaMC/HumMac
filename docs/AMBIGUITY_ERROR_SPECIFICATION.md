\# HumMac: Ambiguity Handling and Error Specification



\*\*Document:\*\* Ambiguity and Error Handling Specification  

\*\*Project:\*\* HumMac (Human-to-Machine Compiler)  

\*\*Version:\*\* 0.1 — Design Draft  

\*\*Status:\*\* Proposed architecture



\## 1. Purpose



HumMac accepts multiple forms of human-written mathematical and computational instructions.



Because the same words or symbols may have different meanings in different contexts, the compiler must establish the intended meaning before constructing executable representations.



HumMac must not silently guess the meaning of ambiguous input.



This specification defines:



\- Categories of ambiguity.

\- Interpretation and disambiguation rules.

\- Clarification requirements.

\- Rejection conditions.

\- Unsupported-language handling.

\- Compiler diagnostics.

\- Conditions under which compilation may proceed.



\## 2. Fundamental principle



HumMac must compile an input only when it can establish a supported and sufficiently unambiguous interpretation under its documented language rules.



The compiler must distinguish between:



1\. An input with a valid, established interpretation.

2\. An input with multiple plausible interpretations.

3\. An input that violates the language specification.

4\. An input that may be meaningful but is outside the implemented language subset.



The compiler must not treat uncertainty as permission to invent an interpretation.



\## 3. Categories of ambiguity



\### 3.1 Lexical ambiguity



Lexical ambiguity occurs when the character sequence may be divided into tokens in more than one plausible way.



Example:



```text

2x

```



Under the HumMac grammar, this is a numerical literal followed by an identifier and therefore represents implicit multiplication.



Identifiers must be recognised as complete names. The compiler must not automatically split an identifier into individual letters.



For example:



```text

xy

```



represents one identifier unless an explicit multiplication operator is present.



\### 3.2 Syntactic ambiguity



Syntactic ambiguity occurs when a sequence of valid tokens admits multiple grammatical structures.



Example:



```text

a / b c

```



This must be interpreted according to the documented implicit-multiplication and operator-associativity rules.



Where the grammar cannot establish a unique interpretation, HumMac must request clarification or reject the expression according to the applicable rule.



Parentheses should be recommended when grouping is unclear.



\### 3.3 Semantic ambiguity



Semantic ambiguity occurs when a syntactically valid structure admits different meanings.



Example:



```text

Set x to banana.

```



Under implicit symbol introduction, `banana` may be a valid symbolic identifier.



The compiler must not automatically interpret it as a fruit, a string literal or an external variable without considering the language context.



If the mathematical grammar establishes that it is an identifier, the compiler may introduce it as a symbol.



If another supported interpretation is also plausible and cannot be resolved through documented rules, clarification is required.



\### 3.4 Referential ambiguity



Referential ambiguity occurs when a word or expression refers to an unclear symbol or object.



Example:



```text

Set x to 5.

Increase it by 2.

```



The compiler must establish what `it` refers to.



If the reference cannot be resolved uniquely, HumMac must request clarification.



Pronouns and other context-dependent references must not be resolved through unsupported assumptions.



\### 3.5 Instructional ambiguity



Instructional ambiguity occurs when an instruction does not specify enough information to construct a complete operation.



Example:



```text

Make x larger.

```



This does not specify the amount or the operation sufficiently.



HumMac must not invent a numerical increment.



It should request a more precise instruction, such as:



```text

Increase x by 5.

```



\## 4. Interpretation hierarchy



HumMac will use a documented interpretation hierarchy.



The proposed order is:



1\. Explicit symbolic notation.

2\. Explicit controlled-language syntax.

3\. Recognised natural-language templates.

4\. Context-dependent interpretation only when explicitly supported by defined rules.



A higher-priority interpretation may be selected only when it is valid in the applicable context.



The compiler must not use arbitrary preference or statistical confidence as a substitute for a defined semantic rule.



If two supported interpretations remain possible, clarification is required.



\## 5. Equivalent expressions and normalisation



Equivalent supported expressions must converge to equivalent Structured Mathematical IR.



For example:



```text

Set y to 2\*x + 5.

```



```text

Set y to twice x plus five.

```



```text

Assign y the value of two multiplied by x, then add five.

```



If all three are recognised as the same supported assignment, they must produce equivalent canonical representations.



The frontend may use different parsing procedures for symbolic notation and natural-language input.



However, both must ultimately pass through the same semantic validation and normalisation requirements.



The compiler must preserve mathematical meaning during normalisation.



It must not force different meanings into the same IR merely because their surface forms look similar.



\## 6. Clarification protocol



When HumMac cannot establish one supported interpretation, it must produce a clarification request.



A clarification request should contain:



\- The relevant source fragment.

\- The ambiguity identified.

\- The possible interpretations, where they can be stated reliably.

\- The information needed to proceed.



Example input:



```text

Increase x by something proportional to y.

```



Possible response:



```text

Clarification required:



What proportionality relationship should be used?



1\. Increase x by k\*y, where k is a proportionality constant.

2\. Increase x by y.

3\. Specify another relationship.

```



The compiler must not select an option automatically.



After receiving clarification, the input must be reprocessed and validated.



Clarification is an interaction between the frontend and the user. It is not a successful compilation result.



\## 7. Rejection conditions



HumMac must reject input when it violates an established language rule.



Examples include:



\### 7.1 Invalid syntax



```text

Set x to +\* 5.

```



The expression does not conform to the grammar.



\### 7.2 Contradictory structure



An instruction may contain mutually incompatible requirements.



Such input must be rejected if the contradiction is established by the language semantics.



\### 7.3 Invalid mathematical operation



An expression may be syntactically valid but violate its mathematical domain.



For example, division by zero must not be accepted under a domain in which the denominator is required to be nonzero.



\### 7.4 Invalid type constraints



An operation that requires a Boolean value must not silently accept an incompatible numerical value unless the language explicitly defines a conversion.



\### 7.5 Invalid symbol use



Implicit symbol introduction does not override identifier syntax, scope rules or reserved-word restrictions.



An identifier that cannot be represented under the language's symbol rules must be rejected.



\## 8. Unsupported constructs



An unsupported construct is not necessarily invalid mathematics.



For example:



```text

Differentiate sin(x) with respect to x.

```



This may be a meaningful mathematical instruction.



However, if HumMac has not implemented symbolic differentiation or the function `sin`, it must report the relevant unsupported feature.



It must not:



\- Pretend to differentiate the expression.

\- Replace the operation with an approximation without permission.

\- Silently discard the instruction.

\- Generate code with invented semantics.



The diagnostic should identify the unsupported construct and, where possible, distinguish between an unsupported frontend feature and an unsupported backend operation.



\## 9. Deterministic interpretation



For a given language version, input and declared compilation configuration, the compiler should produce deterministic results.



This means:



\- The same supported input should produce equivalent canonical IR.

\- Operator precedence must not depend on parsing order or implementation accidents.

\- Identifier resolution must follow defined scope rules.

\- English templates must have specified meanings.

\- Ambiguity must not be resolved through arbitrary selection.



If a compiler update changes the interpretation of an existing language construct, the language version or compatibility implications must be documented.



\## 10. Compiler outcome model



The frontend should expose distinct outcomes.



Conceptually:



```haskell

data CompilationOutcome a

&#x20;   = Accepted a

&#x20;   | NeedsClarification Clarification

&#x20;   | Rejected Diagnostic

&#x20;   | Unsupported Diagnostic

```



The final implementation may use a different Haskell structure.



The important requirement is that these outcomes remain distinguishable.



A clarification request, rejection or unsupported construct must never be presented as successful compilation.



\## 11. Diagnostics



Diagnostics should contain:



\- A stable diagnostic category or code.

\- A human-readable explanation.

\- The relevant source location.

\- The affected expression or instruction.

\- A suggested correction or clarification when appropriate.



Example:



```text

HM-AMB-001: Ambiguous grouping



Source:

&#x20;   a / b c



HumMac cannot establish the intended grouping

under the current expression rules.



Please add parentheses to specify the intended expression.

```



Example:



```text

HM-UNS-001: Unsupported operation



Source:

&#x20;   Differentiate sin(x) with respect to x.



Symbolic differentiation is not supported

by this language version.

```



Diagnostics must not claim that a mathematically meaningful expression is nonsense merely because a feature has not yet been implemented.



\## 12. Compilation gate



Code generation must be permitted only after the relevant frontend and IR validation stages succeed.



The conceptual pipeline is:



```text

Input

&#x20; |

Lexical analysis

&#x20; |

Parsing

&#x20; |

Interpretation

&#x20; |

Ambiguity assessment

&#x20; |

Semantic analysis

&#x20; |

Normalisation

&#x20; |

IR validation

&#x20; |

Structured Mathematical IR

&#x20; |

Lowering

&#x20; |

Low-Level Instruction IR

&#x20; |

Code generation

```



If ambiguity remains unresolved, the compiler must stop before generating executable code.



If the construct is unsupported, the compiler must stop before generating code for that construct.



A valid input may still fail during lowering or backend code generation if the selected target does not support the required operation.



\## 13. Design invariants



1\. HumMac must not silently guess between plausible meanings.

2\. Unknown numerical values are not inherently ambiguous.

3\. Implicit symbol introduction must remain supported.

4\. Identifier recognition must follow lexical and contextual rules.

5\. Equivalent supported inputs must converge to equivalent canonical IR.

6\. Unsupported mathematics must be distinguished from invalid mathematics.

7\. Clarification must precede compilation when meaning cannot be established.

8\. Diagnostics must identify the actual category of failure.

9\. Successful compilation must require a validated representation.

10\. Interpretation must be deterministic under a fixed language version and configuration.



\## 14. Implementation boundary



This document defines the proposed ambiguity and error-handling architecture.



It does not imply that the current Haskell prototype implements natural-language ambiguity detection or clarification.



Initial implementation will focus on deterministic grammar-based parsing and structured diagnostics.



Natural-language recognition will be expanded through explicitly defined templates and semantic mappings.



\*\*End of specification.\*\*

