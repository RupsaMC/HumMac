\# HumMac — Language Specification



\*\*Version:\*\* 0.1  

\*\*Status:\*\* Design specification  

\*\*Project:\*\* Human-to-Machine Compiler  

\*\*Implementation language:\*\* Haskell



\## 1. Purpose and scope



HumMac is an experimental programming language and compiler project designed to translate mathematical expressions and human-readable mathematical instructions into a common formal representation.



Its central design principle is:



> Different expressions of the same mathematical intent should converge to an equivalent formal representation. Only inputs whose meaning and execution properties satisfy the language's requirements may be executed.



HumMac has two complementary input interfaces:



1\. \*\*Controlled mathematical language:\*\* A defined vocabulary and grammar for expressing mathematical operations.

2\. \*\*Flexible mathematical language:\*\* Alternative natural-language expressions that can be normalised into the same formal representation.



Both interfaces feed into a common mathematical intermediate representation (IR).



HumMac does not attempt to interpret arbitrary English or solve every possible mathematical problem. Its supported mathematical vocabulary and operations are explicitly defined and may expand through subsequent language versions.



\## 2. Language architecture



The language is organised into the following stages:



1\. Lexical analysis.

2\. Parsing and input interpretation.

3\. Normalisation into the mathematical IR.

4\. Semantic and mathematical-domain validation.

5\. Formal verification.

6\. Termination analysis.

7\. Execution or compilation.



The two input interfaces must converge before semantic validation and execution.



The execution engine must not depend on the particular wording or notation used by the original input.



\## 3. Lexical conventions



\### 3.1 Identifiers



An identifier represents a variable or a named mathematical object.



Initial identifier grammar:



```ebnf

Identifier ::= Letter { Letter | Digit | "\_" }

Letter     ::= "A"…"Z" | "a"…"z"

Digit      ::= "0"…"9"

```



Examples:



\- `x`

\- `velocity`

\- `node\_count`

\- `signal2`



Identifiers are case-sensitive in the initial specification.



Reserved keywords cannot be used as identifiers unless explicitly escaped in a future version.



\### 3.2 Numerical literals



HumMac distinguishes:



\- Integers: `10`, `-4`

\- Rational literals: `3/5`

\- Decimal literals: `2.75`



The intended internal numerical representation is exact rational arithmetic wherever possible.



A decimal literal such as `0.25` is interpreted as the exact rational number \\(1/4\\), not as an approximate binary floating-point value.



A rational literal must have a nonzero denominator.



\### 3.3 Operators



Initial symbolic operators:



| Operation | Symbols |

|---|---|

| Addition | `+` |

| Subtraction | `-` |

| Multiplication | `\*` |

| Division | `/` |

| Exponentiation | `^` |

| Equality | `=` |

| Inequality | `!=` |

| Less than | `<` |

| Greater than | `>` |

| Less than or equal | `<=` |

| Greater than or equal | `>=` |

| Logical conjunction | `AND` |

| Logical disjunction | `OR` |

| Logical negation | `NOT` |



\## 4. Symbolic mathematical grammar



The following EBNF defines the initial symbolic language.



\### 4.1 Arithmetic expressions



```ebnf

Expression          ::= LogicalExpression

&#x20;                     | ArithmeticExpression



ArithmeticExpression ::= Sum



Sum                 ::= Product

&#x20;                       { ("+" | "-") Product }



Product             ::= Unary

&#x20;                       { ("\*" | "/") Unary }



Unary               ::= ("+" | "-") Unary

&#x20;                     | Power



Power               ::= Primary

&#x20;                       \[ "^" Unary ]



Primary             ::= Number

&#x20;                     | Identifier

&#x20;                     | FunctionCall

&#x20;                     | "(" ArithmeticExpression ")"



FunctionCall        ::= Identifier

&#x20;                       "(" ArgumentList ")"



ArgumentList        ::= ArithmeticExpression

&#x20;                       { "," ArithmeticExpression }

```



Exponentiation is right-associative.



For example:



```text

2^3^2

```



is interpreted as:



```text

2^(3^2)

```



Multiplication and division have higher precedence than addition and subtraction.



Parentheses override normal precedence.



Implicit multiplication, such as `2x` or `3(x+1)`, is reserved for a later grammar extension. Initially, multiplication must be explicit.



\### 4.2 Equations



```ebnf

Equation ::= ArithmeticExpression

&#x20;            "="

&#x20;            ArithmeticExpression

```



Example:



```text

2\*x + 3 = 11

```



An equation represents an equality proposition. It is not an assignment.



\### 4.3 Comparisons



```ebnf

Comparison ::= ArithmeticExpression

&#x20;              ComparisonOperator

&#x20;              ArithmeticExpression



ComparisonOperator ::= "<"

&#x20;                    | ">"

&#x20;                    | "<="

&#x20;                    | ">="

&#x20;                    | "!="

&#x20;                    | "="

```



\### 4.4 Logical propositions



```ebnf

LogicalExpression ::= LogicalTerm

&#x20;                     { "OR" LogicalTerm }



LogicalTerm        ::= LogicalFactor

&#x20;                     { "AND" LogicalFactor }



LogicalFactor      ::= "NOT" LogicalFactor

&#x20;                    | Comparison

&#x20;                    | "(" LogicalExpression ")"

```



Logical conjunction has higher precedence than logical disjunction.



\## 5. Instruction grammar



A HumMac program is a finite sequence of statements.



```ebnf

Program ::= { Statement }



Statement ::= Assignment

&#x20;           | Evaluation

&#x20;           | SolveInstruction

&#x20;           | CheckInstruction

&#x20;           | RepeatBlock

```



Statements are separated by newlines or explicit statement delimiters. The exact lexical handling of separators must be consistent across both input interfaces.



\### 5.1 Assignment



```ebnf

Assignment ::= Identifier "=" ArithmeticExpression

```



Example:



```text

x = 10

```



Controlled-English equivalent:



```text

Set x to 10.

```



Assignment evaluates the right-hand expression and associates its value with the target variable.



\### 5.2 Evaluation



```ebnf

Evaluation ::= "Evaluate" ArithmeticExpression

```



Example:



```text

Evaluate 5 + 3 \* 2

```



Evaluation calculates an expression and returns its result.



\### 5.3 Equation solving



```ebnf

SolveInstruction ::= "Solve"

&#x20;                    Equation

&#x20;                    "for"

&#x20;                    Identifier

```



Example:



```text

Solve 2\*x + 3 = 11 for x

```



Solving is an operation distinct from evaluating an expression.



A solver must operate within an explicitly defined mathematical domain and supported equation class.



The initial implementation should support a restricted class of algebraic equations rather than claim general symbolic-solving capability.



\### 5.4 Proposition checking



```ebnf

CheckInstruction ::= "Check" LogicalExpression

```



Example:



```text

Check x > 5 AND y < 10

```



The result is a truth value, provided all required variables have valid values.



\### 5.5 Bounded repetition



```ebnf

RepeatBlock ::= "Repeat"

&#x20;               Integer

&#x20;               "times"

&#x20;               StatementList

&#x20;               "End"

&#x20;               "repeat"



StatementList ::= { Statement }

```



Example:



```text

Repeat 5 times

&#x20;   x = x + 1

End repeat

```



The repetition count must be a non-negative integer known at verification time.



Unbounded repetition is excluded from the initial language.



Nested bounded repetition is permitted.



\## 6. Controlled mathematical English



The controlled-English interface provides alternative grammatical forms for the same formal operations.



Examples:



| Intended operation | Accepted controlled form |

|---|---|

| Assignment | `Set x to 10.` |

| Addition | `Add 5 to x.` |

| Subtraction | `Subtract 3 from x.` |

| Multiplication | `Multiply x by 4.` |

| Division | `Divide x by 2.` |

| Evaluation | `Evaluate 5 plus 3.` |

| Equation solving | `Solve 2 times x plus 3 equals 11 for x.` |

| Comparison | `Check whether x is greater than 5.` |



These forms are grammatical input patterns, not independent execution semantics.



Each form must map to an equivalent symbolic IR representation.



For example:



```text

Set x to 10.

```



and:



```text

x = 10

```



must produce equivalent assignment nodes.



\## 7. Flexible mathematical English



The flexible-English interface recognises alternative expressions of an already defined mathematical intent.



Examples:



| Alternative expression | Normalised operation |

|---|---|

| Increase x by five. | `x = x + 5` |

| Make x five units larger. | `x = x + 5` |

| Add five onto x. | `x = x + 5` |

| Reduce x by three. | `x = x - 3` |

| Halve x. | `x = x / 2` |

| Double x. | `x = x \* 2` |



\### 7.1 Normalisation requirements



The flexible-English interface must:



1\. Identify the mathematical operation.

2\. Identify the operands.

3\. Identify the target variable, where applicable.

4\. Establish the intended order of operations.

5\. Generate a formal IR representation.

6\. Report ambiguity rather than silently guessing.



\### 7.2 Semantic convergence



Inputs with equivalent mathematical intent must produce equivalent IR representations.



Example:



```text

Increase x by five.

```



and:



```text

Set x to x + 5.

```



Both should normalise to:



```text

Assign(

&#x20;   "x",

&#x20;   Add(VariableRef("x"), Number(5))

)

```



This property will be tested through equivalence tests across the two input interfaces.



The flexible interface is not permitted to invent missing mathematical values or resolve materially ambiguous expressions without clarification.



\## 8. Intermediate representation



The IR is the common mathematical representation consumed by validation, termination analysis and execution.



The following is a conceptual type design.



\### 8.1 Expressions



```haskell

data Expression

&#x20;   = Number Rational

&#x20;   | VariableRef Variable

&#x20;   | Add Expression Expression

&#x20;   | Subtract Expression Expression

&#x20;   | Multiply Expression Expression

&#x20;   | Divide Expression Expression

&#x20;   | Power Expression Expression

&#x20;   | Negate Expression

&#x20;   | Function String \[Expression]

```



\### 8.2 Propositions



```haskell

data Proposition

&#x20;   = Equal Expression Expression

&#x20;   | LessThan Expression Expression

&#x20;   | GreaterThan Expression Expression

&#x20;   | LessEqual Expression Expression

&#x20;   | GreaterEqual Expression Expression

&#x20;   | NotEqual Expression Expression

&#x20;   | And Proposition Proposition

&#x20;   | Or Proposition Proposition

&#x20;   | Not Proposition

```



\### 8.3 Instructions



```haskell

data Instruction

&#x20;   = Assign Variable Expression

&#x20;   | Evaluate Expression

&#x20;   | Solve Proposition Variable

&#x20;   | Check Proposition

&#x20;   | Repeat Integer \[Instruction]

```



These types are a proposed design. They are not yet the implementation contract, and the exact representation of solving operations may be refined when their semantics are specified.



\## 9. Mathematical semantics



Every accepted IR construct must have a defined meaning.



\### 9.1 Arithmetic



For valid numerical operands:



\\\[

\\operatorname{eval}(a+b)=\\operatorname{eval}(a)+\\operatorname{eval}(b)

\\]



\\\[

\\operatorname{eval}(a-b)=\\operatorname{eval}(a)-\\operatorname{eval}(b)

\\]



\\\[

\\operatorname{eval}(a\\times b)=\\operatorname{eval}(a)\\operatorname{eval}(b)

\\]



\\\[

\\operatorname{eval}(a/b)=\\frac{\\operatorname{eval}(a)}{\\operatorname{eval}(b)}

\\]



Division by zero is rejected.



Exponentiation must have a defined supported domain. The initial implementation should support integer exponents, with zero and negative exponents subject to their mathematical domain restrictions.



\### 9.2 Variables



A variable reference must resolve to a previously established value or a valid declared mathematical symbol.



Undefined variable references are rejected during semantic validation.



\### 9.3 Assignment



An assignment evaluates its right-hand expression and updates the environment.



For:



```text

x = 5 + 3

```



the resulting environment associates `x` with `8`.



\### 9.4 Equations and solving



An equation represents equality between two expressions.



A solving operation identifies values satisfying that equality within a specified domain.



The result may be:



\- One solution.

\- Multiple solutions.

\- No solution.

\- An unsupported equation.

\- An unresolved result where the implemented solver cannot establish the answer.



The solver must not report an unsupported or incomplete result as a proven solution.



\### 9.5 Propositions



A proposition evaluates to a Boolean value when its constituent expressions are defined and its operations are supported.



\### 9.6 Repetition



For:



```text

Repeat n times

&#x20;   S

End repeat

```



the semantics are equivalent to sequential execution of the statement sequence `S`, repeated exactly `n` times.



For `n = 0`, the body executes zero times.



The repetition body must satisfy the same semantic and termination requirements as any other executable statement sequence.



\## 10. Mathematical domains



HumMac must distinguish the domain in which an operation is interpreted.



The planned domains are:



\- Integers.

\- Rational numbers.

\- Real numbers.

\- Complex numbers.



The first implementation will prioritise integers and rational numbers.



Domain-specific rules include:



\- Division by zero is invalid.

\- A rational number has a nonzero denominator.

\- Negative square roots are outside the real domain but may be valid in the complex domain.

\- An equation may have different solution sets in different domains.



HumMac must not confuse an operation unsupported by the current implementation with a mathematically invalid operation.



\## 11. Validation and rejection model



Input must pass distinct validation stages.



\### Stage 1: Lexical validation



Checks whether tokens belong to the recognised vocabulary and lexical rules.



\### Stage 2: Syntactic validation



Checks whether the input follows a supported grammar.



\### Stage 3: Semantic validation



Checks variable references, operand roles, function availability and instruction consistency.



\### Stage 4: Mathematical-domain validation



Checks whether operations are defined in the selected mathematical domain.



\### Stage 5: Formal validation



Checks whether the IR satisfies the restrictions of the executable language.



\### Stage 6: Termination verification



Establishes a finite execution bound for accepted programs under the current language semantics.



\### Possible outcomes



HumMac distinguishes:



\- \*\*Accepted:\*\* The input has been understood and satisfies the relevant validation requirements.

\- \*\*Rejected:\*\* The input is invalid, unsupported or fails a required verification.

\- \*\*Clarification required:\*\* The input has multiple plausible interpretations.



Rejection messages should identify the stage and the reason for failure.



\## 12. Termination model



HumMac adopts a restricted-execution approach.



It does not attempt to decide termination for arbitrary programs.



The initial executable language permits:



1\. Finite arithmetic expression trees.

2\. Finite sequences of instructions.

3\. Statically bounded repetition.

4\. Nested repetition with finite non-negative bounds.

5\. Supported operations with defined execution semantics.



The initial language excludes unbounded loops and unrestricted recursion.



\### 12.1 Structural execution bound



For a program \\(P\\), define its expanded instruction count recursively:



\\\[

I(P)=\\sum\_{s\\in P}I(s)

\\]



For ordinary instructions:



\\\[

I(s)=1

\\]



For a repetition instruction:



\\\[

I(\\operatorname{Repeat}(n,B))

=1+nI(B)

\\]



where \\(n\\) is a finite non-negative integer and \\(B\\) is the body.



The expression evaluation count is calculated separately, accounting for repeated execution of expression-bearing instructions.



This establishes a structural upper bound on instruction and expression evaluations for the initial language.



It does not, by itself, establish a bound on physical running time or guarantee termination of an incorrectly implemented host-language operation. Those properties require separate implementation assumptions and tests.



\## 13. Error and ambiguity handling



HumMac must distinguish at least the following cases:



| Category | Example | Expected response |

|---|---|---|

| Invalid syntax | `5 + \* 8` | Syntax rejection |

| Undefined reference | `x + 5` with no definition of x | Semantic rejection |

| Undefined operation | `5 / 0` | Domain rejection |

| Unsupported operation | Unsupported mathematical function | Explicit unsupported-operation response |

| Ambiguous input | `2 / 3x` | Clarification request |

| Unverified execution | Unbounded repetition | Formal rejection |



A recognised mathematical identifier must not automatically be assumed to be a valid function or instruction.



The system must preserve the distinction between an unknown identifier and an unsupported operation.



\## 14. Compiler and execution model



The intended long-term pipeline is:



```text

Input

&#x20; |

&#x20; v

Lexical Analysis

&#x20; |

&#x20; v

Input Interpretation

&#x20; |

&#x20; v

Mathematical IR

&#x20; |

&#x20; v

Semantic Validation

&#x20; |

&#x20; v

Domain Validation

&#x20; |

&#x20; v

Formal Verification

&#x20; |

&#x20; v

Termination Verification

&#x20; |

&#x20; v

Intermediate Instructions

&#x20; |

&#x20; v

HumMac Virtual Machine

```



The initial implementation may execute the validated IR directly.



A custom virtual machine and bytecode generation are future development goals, not requirements of the initial prototype.



\## 15. Implementation status



The specification distinguishes planned language features from implemented ones.



| Feature | Current status |

|---|---|

| Basic English arithmetic instructions | Implemented |

| Basic expression AST | Implemented |

| Undefined-variable validation | Implemented |

| Structural termination certificate | Implemented for current finite instruction language |

| Bounded repetition parsing | Implemented |

| Bounded repetition validation | Implemented |

| Bounded repetition termination accounting | Implemented |

| Bounded repetition execution | Pending |

| Symbolic mathematical parser | Planned |

| Exact rational arithmetic | Planned |

| Equations and inequalities | Planned |

| Logical propositions | Planned |

| Flexible-English normalisation | Planned |

| Mathematical-domain validation | Planned |

| Generalised IR | Planned |

| Custom virtual machine | Future development |



\## 16. Design principles



HumMac development must follow these principles:



1\. \*\*Semantic convergence:\*\* Equivalent input forms should produce equivalent formal representations.

2\. \*\*Explicit semantics:\*\* Every supported construct must have a defined mathematical meaning.

3\. \*\*Separation of concerns:\*\* Parsing, interpretation, validation, termination verification and execution must remain distinct.

4\. \*\*No silent guessing:\*\* Ambiguous input must be clarified or rejected.

5\. \*\*Domain awareness:\*\* Mathematical validity must be assessed within an explicitly defined domain.

6\. \*\*Restricted execution:\*\* Only programs satisfying the language's formal execution requirements may run.

7\. \*\*Honest guarantees:\*\* HumMac must never claim general termination detection or universal mathematical understanding.

8\. \*\*Incremental extensibility:\*\* New language constructs must be added through explicit grammar and semantic extensions.



\## 17. Future research directions



Potential future extensions include:



\- More expressive mathematical English.

\- Implicit multiplication and advanced mathematical notation.

\- Symbolic differentiation and integration.

\- More extensive equation-solving capabilities.

\- Recursive functions with provable termination conditions.

\- Stronger formal verification and proof-carrying execution.

\- A typed intermediate representation.

\- Bytecode compilation and a custom virtual machine.

\- Formal equivalence testing between different input interfaces.



These are research directions, not guaranteed features.



\---



\*\*End of HumMac Language Specification v0.1\*\*



\*\*Status:\*\* Proposed design baseline. Implementation must follow the specification as it is refined and versioned.

