\# HumMac: Version 0.1 Implementation Scope



\*\*Document:\*\* Initial Implementation Scope  

\*\*Project:\*\* HumMac (Human-to-Machine Compiler)  

\*\*Version:\*\* 0.1  

\*\*Status:\*\* Proposed implementation baseline



\## 1. Objective



HumMac v0.1 will implement the first reliable subset of the proposed human-to-machine compilation language.



Its primary objective is to:



1\. Recognise supported mathematical and computational instructions.

2\. Parse symbolic notation and supported English constructions.

3\. Resolve identifiers and infer compatible types.

4\. Detect ambiguous, invalid and unsupported input.

5\. Construct a canonical Structured Mathematical IR.

6\. Validate the resulting IR.

7\. Lower validated IR into a Low-Level Instruction IR.



Native machine-code generation is outside the initial implementation milestone.



\## 2. Supported mathematical expressions



\### 2.1 Numeric literals



\- Integers.

\- Finite decimal literals.

\- Rational values represented through division.



Exact rational arithmetic will be used where applicable.



\### 2.2 Identifiers



\- Implicit symbol introduction.

\- Stable symbol identities.

\- Symbolic variables without known numerical values.

\- External runtime input classification.

\- Basic program-level scope.



Identifiers must follow the language's lexical rules.



\### 2.3 Arithmetic



The initial arithmetic operations are:



\- Addition.

\- Subtraction.

\- Multiplication.

\- Division.

\- Integer exponentiation.

\- Unary positive and negative signs.



\### 2.4 Implicit multiplication



Supported forms include:



```text

2x

3(x + 1)

(x + 1)(x - 1)

2xy

```



Identifiers are treated as complete names.



Therefore, `xy` is one identifier, while `2xy` means two multiplied by the identifier `xy`.



The expression `2\*x\*y` explicitly refers to two separate variable symbols.



Parentheses are required where grouping cannot otherwise be established unambiguously.



\### 2.5 Operator rules



The initial grammar uses:



\- Conventional operator precedence.

\- Right-associative exponentiation.

\- Left-associative multiplication and division.

\- Left-associative addition and subtraction.

\- Conventional unary-minus precedence.



The expression `-2^2` means `-(2^2)`.



\## 3. Relations and logical expressions



The initial IR supports:



\- Equality.

\- Inequality.

\- Less than.

\- Greater than.

\- Less than or equal to.

\- Greater than or equal to.

\- Logical AND.

\- Logical OR.

\- Logical NOT.



These constructs may be represented symbolically.



HumMac does not need to solve an equation or know the values of all its variables merely to construct its representation.



\## 4. Supported computational instructions



The initial instruction set includes:



\### Assignment



```text

Set x to 10.

Set y to 2x + 5.

```



\### Expression evaluation



```text

Evaluate 2x + 5.

```



\### Proposition checking



```text

Check x > 5.

```



This produces a runtime Boolean operation when its operands are available.



\### Conditional execution



```text

If x > 5:

&#x20;   Set y to 10.

Otherwise:

&#x20;   Set y to 0.

End if.

```



\### Bounded repetition



```text

Repeat 5 times.

&#x20;   Increase x by 1.

End repeat.

```



Repetition counts must be nonnegative integers established before the first iteration.



The initial implementation will not support arbitrary unbounded repetition.



\## 5. English input support



HumMac will have two English-facing input modes.



\### 5.1 Controlled mathematical English



The initial supported templates include:



```text

Set x to 10.

Assign y the value of 2x plus 5.

Increase x by 5.

Decrease x by 3.

Multiply x by 4.

Divide x by 2.

Evaluate 2x + 5.

Check whether x is greater than 5.

Repeat 5 times.

```



Each template must have a documented grammatical and semantic interpretation.



\### 5.2 Flexible mathematical English



The initial frontend may recognise selected equivalent constructions.



Examples:



```text

Make y equal to twice x plus five.

Add five to twice x.

Increase x by five.

Take five away from x.

```



These constructions must map to explicitly defined mathematical operations.



The implementation must use documented language patterns rather than assuming arbitrary conversational English can be interpreted mathematically.



Unrecognised or ambiguous constructions must produce appropriate diagnostics.



\## 6. Initial function registry



The initial implementation may support a small set of functions with fully specified semantics.



Proposed initial functions:



\- `abs(x)`

\- `min(x, y)`

\- `max(x, y)`



Each function must have defined argument types, arity, return type and domain rules.



Functions requiring approximate or unsupported numerical representations will be deferred.



\## 7. Symbol and type support



The initial implementation must support:



\- Implicit symbol introduction.

\- Unique internal symbol identifiers.

\- Symbol tables.

\- Type variables and basic type inference.

\- Integer, rational, real and Boolean types.

\- Read/write tracking.

\- External runtime input metadata.

\- Basic assignment compatibility checks.



A symbol does not need a known numerical value to be represented.



\## 8. Ambiguity and diagnostics



The frontend must distinguish:



\- Accepted.

\- Needs clarification.

\- Rejected.

\- Unsupported.



It must provide source-aware diagnostics for malformed syntax, unresolved interpretation, incompatible types and unsupported operations.



It must not silently guess between different plausible meanings.



\## 9. Structured Mathematical IR



The initial SMIR must represent:



\- Constants.

\- Symbol references.

\- Arithmetic operations.

\- Function applications.

\- Relations.

\- Propositions.

\- Assignments.

\- Expression evaluation.

\- Proposition checking.

\- Conditional execution.

\- Bounded repetition.

\- Ordered program structure.



The SMIR must remain independent of target architecture.



\## 10. Low-Level Instruction IR



The initial LIR must support:



\- Temporary values.

\- Immediate constants.

\- Symbol operands.

\- Arithmetic operations.

\- Loads and stores.

\- Function calls supported by the initial registry.

\- Labels.

\- Conditional jumps.

\- Unconditional jumps.

\- Basic control-flow representation.



Lowering must preserve the semantics of the SMIR.



\## 11. Deferred features



The following are explicitly outside v0.1:



\- General equation solving.

\- Symbolic differentiation.

\- Symbolic integration.

\- General theorem proving.

\- Arbitrary mathematical text interpretation.

\- Arbitrary user-defined functions.

\- Recursive function definitions.

\- Unbounded and data-dependent loops.

\- Concurrent execution.

\- Distributed computation.

\- Vectors and matrices.

\- Complex numbers.

\- Physical units and dimensional analysis.

\- Native machine-code backends.



These are possible future extensions, not permanent exclusions.



\## 12. Initial testing requirements



The first implementation must include tests for:



1\. Arithmetic precedence and associativity.

2\. Explicit multiplication.

3\. Implicit multiplication.

4\. Identifier recognition.

5\. Symbol identity.

6\. Unknown symbolic variables.

7\. Type inference.

8\. Assignment semantics.

9\. Equation and proposition representation.

10\. English-to-IR normalisation.

11\. Ambiguous input detection.

12\. Unsupported feature detection.

13\. Conditional lowering.

14\. Bounded loop lowering.

15\. IR semantic preservation.



Equivalent supported input forms must be tested for equivalent canonical IR.



\## 13. Completion criteria



HumMac v0.1 will be considered implemented when:



1\. Its supported grammar is documented.

2\. Supported inputs can be parsed reliably.

3\. Symbol resolution and basic type inference work.

4\. Ambiguous and unsupported inputs are distinguished.

5\. Valid inputs produce canonical SMIR.

6\. SMIR validation is implemented.

7\. Valid SMIR can be lowered into LIR.

8\. Tests establish preservation of the defined semantics across the two IR stages.

9\. The compiler produces useful diagnostics when compilation cannot proceed.



A working native machine-code backend is not required for this milestone.



\## 14. Development principle



HumMac will expand through explicitly specified language extensions.



A feature must have documented syntax, semantics, IR representation, validation rules and lowering behaviour before it is considered supported.



The implementation must never claim broader mathematical understanding than its actual supported language subset.



\*\*End of specification.\*\*

