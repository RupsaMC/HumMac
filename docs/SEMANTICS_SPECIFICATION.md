\# HumMac: Language Semantics Specification



\*\*Document:\*\* Language Semantics Specification  

\*\*Project:\*\* HumMac (Human-to-Machine Compiler)  

\*\*Version:\*\* 0.1 — Design Draft  

\*\*Status:\*\* Proposed architecture



\## 1. Purpose



This document defines the computational meaning of HumMac instructions.



HumMac is a compiler. Its responsibility is to translate supported human-written instructions into formal representations and eventually target-specific executable code.



The semantics specification defines the behaviour that generated programs must preserve.



It is independent of any particular processor, machine instruction set or execution environment.



A compiler implementation is correct only insofar as its transformations preserve the specified meaning of the input program.



\## 2. Semantic model



The language is defined using an abstract computational environment.



Conceptually, the environment contains:



\- Symbol identities.

\- Current runtime values.

\- Variable types.

\- External inputs.

\- Program execution state.

\- Observable outputs.

\- Runtime errors and exceptional conditions.



A program transforms an initial environment into a resulting environment and a sequence of observable events, provided its execution completes.



The compiler does not need to know every runtime value when constructing the program.



It must preserve the relationships between symbols and operations so that the generated program behaves according to the language semantics.



\## 3. Expression semantics



An expression describes a computation that produces a value when evaluated in an appropriate runtime environment.



The initial expression categories are:



\- Constants.

\- Symbol references.

\- Addition.

\- Subtraction.

\- Multiplication.

\- Division.

\- Exponentiation.

\- Unary negation.

\- Registered function applications.



\### 3.1 Constants



Constants represent literal values.



The initial implementation will support integer and finite decimal literals, with exact rational representation where applicable.



For example:



```text

5

0.25

\-12

```



A decimal literal such as `0.25` should initially be represented exactly as the rational number 1/4.



\### 3.2 Symbol references



A symbol reference obtains the current value associated with its symbol identity.



The symbol may be:



\- Defined by an earlier program assignment.

\- Supplied as an external runtime input.

\- Provided by another explicitly defined runtime mechanism.



An unresolved runtime value must not be replaced with an invented value.



\### 3.3 Arithmetic operations



The arithmetic operations have their conventional mathematical meanings.



For example:



```text

x + y

x - y

x \* y

x / y

x ^ y

```



The initial language uses the precedence and associativity rules established in the language specification.



Binary arithmetic expressions are evaluated according to their specified grouping and evaluation order.



The initial evaluation order is left-to-right for operands.



\### 3.4 Division



Division requires a nonzero denominator.



If the denominator is zero at runtime, the generated program must produce the defined division-by-zero error behaviour.



The compiler may reject a division operation during compilation if it can establish that the denominator is identically zero.



It must not assume that an unknown symbolic denominator is nonzero merely because its value is unavailable.



\### 3.5 Exponentiation



Exponentiation represents raising a base to a specified power.



The initial exact arithmetic subset should support integer exponents.



Negative integer exponents require a nonzero base.



The cases involving zero to the zeroth power, non-integer exponents and values outside the supported mathematical domain must be explicitly rejected or handled by a separately specified extension.



The compiler must not silently substitute approximate semantics for unsupported exponentiation.



\### 3.6 Function applications



A function application represents a call to a registered function.



Each supported function must define:



\- Its name and identity.

\- Its arity.

\- Accepted argument types.

\- Return type.

\- Mathematical domain.

\- Runtime behaviour.

\- Error conditions.



An unregistered function must be reported as unsupported or unresolved according to the context.



Function names must not be treated as arbitrary user-defined operations without an applicable declaration or registration mechanism.



\## 4. Assignment semantics



Assignment associates a symbol with the result of an expression.



Example:



```text

Set x to 10.

Set y to 2x + 5.

```



The first assignment establishes the runtime value of `x`.



The second computes its expression using the current value of `x` and assigns the result to `y`.



Conceptually:



```text

x := 10

y := (2 \* x) + 5

```



Assignment has the following requirements:



1\. The right-hand expression is evaluated before the assignment takes effect.

2\. The assignment target must resolve to a valid symbol.

3\. The assigned value must be compatible with the target's type.

4\. Assignment updates the current binding of the target symbol.

5\. The assignment must not alter the identity of other symbols.

6\. Subsequent reads must observe the updated binding.



The compiler must preserve assignment order.



\## 5. External input semantics



A symbol may be introduced without a preceding assignment.



For example:



```text

Set y to 2x + 5.

```



If `x` is not defined by an earlier program instruction, it may be classified as an external runtime input.



The generated program must define how that input is obtained through its runtime interface.



The input's type and validity must be checked according to the applicable runtime contract.



If a required input is unavailable or invalid, the program must follow its defined runtime error behaviour.



Compilation does not require the actual numerical value of the external input.



\## 6. Evaluation and observable output



An evaluation instruction requests that an expression be evaluated.



For example:



```text

Evaluate 2x + 5.

```



The expression is evaluated using the current runtime environment.



If the expression produces a valid value, the result is made available through the language's defined output mechanism.



The initial implementation should distinguish:



\- An expression used internally by another instruction.

\- An explicit evaluation request whose result is observable.



The exact output mechanism, formatting rules and target-specific input/output interface will be specified separately.



\## 7. Relational and logical semantics



\### 7.1 Relations



Relations express mathematical comparisons between expressions.



The initial relation categories are:



\- Equality.

\- Inequality.

\- Less than.

\- Greater than.

\- Less than or equal to.

\- Greater than or equal to.



The meaning of each relation depends on the operand types and applicable mathematical domain.



\### 7.2 Propositions



Propositions represent logical statements.



The initial logical operations are:



\- AND.

\- OR.

\- NOT.



The result of evaluating a proposition is Boolean.



\### 7.3 Short-circuit evaluation



The initial semantics will use left-to-right short-circuit evaluation for logical conjunction and disjunction.



For `A AND B`, if `A` evaluates to false, `B` need not be evaluated.



For `A OR B`, if `A` evaluates to true, `B` need not be evaluated.



This behaviour must be preserved by every backend.



A proposition containing unresolved symbolic variables may be represented in the IR without being evaluated as true or false.



\## 8. Conditional execution



A conditional instruction selects a branch according to a Boolean condition.



Conceptually:



```text

If x > 5:

&#x20;   Set y to 10.

Otherwise:

&#x20;   Set y to 0.

```



Its semantics are:



1\. Evaluate the condition.

2\. Select the corresponding branch.

3\. Execute only the selected branch.

4\. Continue after the conditional instruction.



The unselected branch must not be executed.



A branch condition must produce a valid Boolean result at runtime.



The compiler must preserve the control-flow structure when lowering the program.



\## 9. Repetition semantics



Repetition represents repeated execution of a program block.



The initial language supports bounded repetition.



Example:



```text

Repeat 5 times.

&#x20;   Increase x by 1.

End repeat.

```



The block executes five times.



\### 9.1 Repetition count



The repetition count must be a nonnegative integer.



A count of zero means the body is not executed.



A count of one means the body is executed once.



\### 9.2 Evaluation



The repetition count is evaluated according to the defined loop semantics.



For the initial implementation, the count must be established before the first iteration and must not change the number of scheduled iterations during the loop.



\### 9.3 State updates



Assignments performed inside a loop update the runtime environment according to normal assignment semantics.



Changes to variables that are visible outside the loop must remain visible after the loop.



The compiler must not discard observable state changes merely because they occur inside a repeated block.



\### 9.4 Termination



A loop with a finite, nonnegative repetition count executes a finite number of iterations, assuming each body execution itself completes.



Nested bounded loops are also finite under the same assumption.



Data-dependent loops and unbounded repetition require separate termination analysis and language rules.



The compiler must not claim a general termination proof for arbitrary loops.



\## 10. Scope and variable lifetime



The initial semantic model uses program-level symbol identity and explicitly defined block visibility.



Variables assigned inside a block must follow the visibility rules established by the symbol and scope specifications.



For the initial implementation:



\- Existing symbols retain their identity inside nested blocks.

\- Assignments to existing visible symbols update those symbols.

\- New symbols introduced inside a block have block-local visibility unless the language explicitly defines otherwise.

\- A variable must not become visible outside a block merely because it was mentioned inside it.



The exact rules for declarations, shadowing and lifetime will be refined before implementation.



\## 11. Runtime errors



The language must define observable error behaviour for invalid runtime conditions.



Initial error categories include:



\- Division by zero.

\- Invalid external input.

\- Missing required runtime input.

\- Invalid function arguments.

\- Unsupported runtime operation.

\- Arithmetic overflow in a target representation where overflow is possible.

\- Invalid control-flow state.



The semantic model must define whether an error terminates the current program, propagates to a caller or can be handled by a future error-handling construct.



The initial implementation should use explicit runtime failure rather than silently producing an arbitrary value.



\## 12. Evaluation order and side effects



HumMac must define evaluation order independently of the target backend.



The initial rules are:



1\. Binary arithmetic operands are evaluated left-to-right.

2\. Function arguments are evaluated left-to-right.

3\. Assignment expressions are evaluated before the target is updated.

4\. Logical AND and OR use the specified short-circuit rules.

5\. Instructions execute in their written program order unless control flow specifies otherwise.

6\. A conditional executes only its selected branch.

7\. Repetition executes its body according to its established iteration count.



The compiler must not perform transformations that change observable behaviour.



Future optimisations may reorder operations only when they can establish that the transformation preserves the language semantics.



\## 13. Compiler correctness



A compiler transformation is semantics-preserving when the resulting program has the same specified observable behaviour as the original program, subject to the declared target representation and runtime assumptions.



This applies to:



\- Frontend normalisation.

\- Structured IR construction.

\- IR validation.

\- Lowering.

\- Optimisation.

\- Target-specific code generation.



The compiler must preserve:



\- Values produced by expressions.

\- Symbol identity and binding.

\- Assignment order.

\- Control-flow decisions.

\- Observable outputs.

\- Defined error behaviour.



The implementation should eventually include tests that compare the behaviour of programs represented at different compiler stages.



\## 14. Termination guarantees



Termination is a property of program behaviour, not a synonym for syntactic or semantic validity.



The initial language supports a restricted subset for which structural termination arguments can be established:



\- Finite expression trees.

\- Finite instruction sequences.

\- Literal bounded repetition.

\- Nested bounded repetition.

\- Finite control-flow structures without unbounded cycles.



These guarantees assume that primitive operations and called functions themselves complete.



The compiler must distinguish:



\- Programs proven to terminate under the specified assumptions.

\- Programs whose termination cannot be established.

\- Programs that violate a termination requirement imposed by a compilation policy.



HumMac must not claim that it can decide whether every arbitrary program terminates.



\## 15. Target independence



The semantics must remain independent of the selected machine architecture.



For example, an addition operation has the same specified meaning regardless of whether the backend targets x86-64, ARM64 or a virtual machine.



Backends must implement the defined value representation, arithmetic behaviour, control flow and error semantics.



If a target cannot faithfully implement a required operation, the backend must report the limitation rather than silently changing its meaning.



\## 16. Design invariants



1\. Instructions must have precisely specified meanings.

2\. Compilation must preserve those meanings.

3\. Symbolic variables do not require known numerical values at compilation time.

4\. Assignment is distinct from mathematical equality.

5\. Evaluation order must be defined and preserved.

6\. Control-flow semantics must be independent of the backend.

7\. Runtime errors must not be silently converted into arbitrary results.

8\. Bounded repetition must have a defined finite execution meaning.

9\. Termination analysis must remain separate from semantic validity.

10\. Target-specific implementations must respect the language's specified behaviour.



\## 17. Implementation boundary



This document defines the intended semantics of HumMac version 0.1.



It does not imply that the current Haskell prototype implements every listed construct.



Implementation will begin with a deliberately restricted subset and expand only when the corresponding semantics, IR structures and backend requirements have been defined.



\*\*End of specification.\*\*

