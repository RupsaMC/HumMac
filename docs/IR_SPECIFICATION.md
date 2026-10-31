\# HumMac: Intermediate Representation Specification



\*\*Document:\*\* IR Specification  

\*\*Project:\*\* HumMac (Human-to-Machine Compiler)  

\*\*Version:\*\* 0.1 — Design Draft  

\*\*Status:\*\* Proposed architecture



\## 1. Purpose



HumMac uses a two-stage Intermediate Representation (IR) architecture.



The purpose of the IR is to provide a canonical, platform-independent representation of the meaning of supported human-written mathematical instructions.



The compiler must separate:



1\. Understanding and representing mathematical intent.

2\. Transforming that representation into instructions suitable for a target machine.



The first stage must not depend on a particular processor, instruction set, or execution environment.



The second stage must not depend on the original language used to express the instruction.



\## 2. Overall architecture



The compilation pipeline is:



Human Input  

→ Frontend Recognition  

→ Lexical and Syntactic Analysis  

→ Semantic Analysis  

→ Normalisation  

→ Structured Mathematical IR  

→ IR Validation  

→ Lowering  

→ Low-Level Instruction IR  

→ Target-Specific Code Generation



The two IR stages have different responsibilities.



\### 2.1 Structured Mathematical IR



The Structured Mathematical IR (SMIR) preserves meaningful mathematical and computational structures.



It represents:



\- Numerical constants

\- Symbolic variables

\- Arithmetic expressions

\- Function applications

\- Equations and inequalities

\- Logical propositions

\- Variable declarations and bindings

\- Assignments

\- Conditional operations

\- Repetition and control flow

\- Ordered program structure



It should remain readable and sufficiently close to the mathematical meaning of the original instruction.



\### 2.2 Low-Level Instruction IR



The Low-Level Instruction IR (LIR) represents operations in a form suitable for code generation.



It may contain:



\- Explicit temporary values

\- Primitive arithmetic operations

\- Explicit variable loads and stores

\- Labels and control-flow transfers

\- Conditional branches

\- Explicit function calls

\- Target-independent primitive operations



The LIR must not depend on the original human-facing syntax.



\## 3. Symbol representation



Symbols must be represented independently of their textual spelling.



A symbol has a unique internal identifier.



Conceptually:



```haskell

newtype SymbolId = SymbolId Int

&#x20;   deriving (Show, Eq, Ord)

```



The symbol table associates identifiers with their declared names, types, scope and other relevant metadata.



For example, the textual identifier `x` is resolved to a particular `SymbolId`.



Two occurrences of `x` refer to the same symbol only when they resolve to the same declaration or binding.



An unresolved symbolic variable may be represented in a mathematical expression. Its absence of a numerical value does not automatically make the expression invalid.



However, a compiler must distinguish an intentional symbolic reference from an invalid or unresolvable reference under the language's symbol-resolution rules.



\## 4. Structured Mathematical IR



The following is a conceptual initial design.



\### 4.1 Expressions



```haskell

data Expr

&#x20;   = Constant Rational

&#x20;   | Symbol SymbolId

&#x20;   | Add Expr Expr

&#x20;   | Subtract Expr Expr

&#x20;   | Multiply Expr Expr

&#x20;   | Divide Expr Expr

&#x20;   | Power Expr Expr

&#x20;   | Negate Expr

&#x20;   | FunctionCall FunctionId \[Expr]

&#x20;   deriving (Show, Eq)

```



Expressions represent values or symbolic computations.



They do not necessarily contain enough information to produce a numerical result immediately.



\### 4.2 Relations



```haskell

data Relation

&#x20;   = Equal Expr Expr

&#x20;   | NotEqual Expr Expr

&#x20;   | LessThan Expr Expr

&#x20;   | GreaterThan Expr Expr

&#x20;   | LessEqual Expr Expr

&#x20;   | GreaterEqual Expr Expr

&#x20;   deriving (Show, Eq)

```



Relations represent mathematical relationships between expressions.



An equation must not be confused with a variable assignment.



For example:



\- `x = 5` represents a mathematical equality when used as a relation.

\- `Set x to 5` represents an assignment instruction.



\### 4.3 Propositions



```haskell

data Proposition

&#x20;   = RelationProposition Relation

&#x20;   | And Proposition Proposition

&#x20;   | Or Proposition Proposition

&#x20;   | Not Proposition

&#x20;   deriving (Show, Eq)

```



Propositions represent logical statements.



They may contain symbolic variables and therefore need not be immediately evaluable as true or false.



\### 4.4 Instructions



```haskell

data Instruction

&#x20;   = Assign SymbolId Expr

&#x20;   | Evaluate Expr

&#x20;   | Check Proposition

&#x20;   | Branch Proposition \[Instruction] \[Instruction]

&#x20;   | Repeat Expr \[Instruction]

&#x20;   deriving (Show, Eq)

```



Instructions represent operations requested by the program.



The meaning and constraints of each instruction must be specified by the language semantics.



In particular, repetition counts, branch conditions and assignment targets must be validated before lowering.



\### 4.5 Program structure



```haskell

newtype Program = Program \[Instruction]

&#x20;   deriving (Show, Eq)

```



A program is an ordered sequence of instructions.



Declarations, scopes, source locations and compilation metadata will be incorporated into the eventual complete representation.



\## 5. Type and domain information



The IR must distinguish the structure of an expression from the mathematical domain in which it is interpreted.



Potential initial domains include:



\- Integers

\- Rational numbers

\- Real numbers

\- Boolean values

\- Symbolic values



The compiler must not silently assume that every operation is valid over every domain.



For example, division by zero must be treated according to the specified domain semantics.



A symbolic expression may remain valid without a numerical value, but its operations must still satisfy the applicable type and domain rules.



Function applications must refer to supported functions with defined arity and domain requirements.



\## 6. Normalisation requirements



Equivalent supported human inputs must converge to equivalent Structured Mathematical IR.



For example:



```text

Set y to 2x + 5.

```



```text

Assign y the value of twice x plus five.

```



```text

y := 2\*x + 5

```



All three should produce the same canonical assignment structure, assuming they have the same symbol resolution and mathematical interpretation.



Normalisation must include:



\- Resolving equivalent supported input forms.

\- Applying operator precedence and associativity.

\- Converting implicit multiplication into explicit multiplication nodes.

\- Resolving identifiers into symbol references.

\- Converting supported English constructions into mathematical operations.

\- Applying canonical representation rules.



Normalisation must not silently change mathematical meaning.



Source text, source positions and diagnostic information should be retained separately from the canonical semantic representation.



\## 7. Lowering to Low-Level Instruction IR



Lowering transforms the Structured Mathematical IR into explicit operations.



For example:



Structured Mathematical IR:



```text

Assign y

&#x20;   Add

&#x20;       Multiply

&#x20;           Constant 2

&#x20;           Symbol x

&#x20;       Constant 5

```



Possible Low-Level Instruction IR:



```text

t1 = LOAD x

t2 = MULTIPLY 2, t1

t3 = ADD t2, 5

STORE y, t3

```



The example illustrates the intended transformation, not a final LIR syntax.



\### 7.1 Lowering requirements



Lowering must:



1\. Preserve the semantics of the Structured Mathematical IR.

2\. Preserve symbol identity and binding.

3\. Respect the declared evaluation order.

4\. Make required intermediate values explicit.

5\. Represent control flow without changing its meaning.

6\. Reject constructs for which no valid lowering is currently defined.



Lowering must not introduce unsupported assumptions about numerical values.



\## 8. Low-Level Instruction IR design



The eventual LIR may use a structure similar to:



```haskell

newtype TempId = TempId Int

&#x20;   deriving (Show, Eq, Ord)



data Operand

&#x20;   = Immediate Rational

&#x20;   | SymbolOperand SymbolId

&#x20;   | Temporary TempId

&#x20;   deriving (Show, Eq)



data Operation

&#x20;   = Load Operand

&#x20;   | Store SymbolId Operand

&#x20;   | AddOp Operand Operand

&#x20;   | SubtractOp Operand Operand

&#x20;   | MultiplyOp Operand Operand

&#x20;   | DivideOp Operand Operand

&#x20;   | PowerOp Operand Operand

&#x20;   | CallOp FunctionId \[Operand]

&#x20;   deriving (Show, Eq)



data LowInstruction

&#x20;   = Compute TempId Operation

&#x20;   | Jump Label

&#x20;   | ConditionalJump Operand Label Label

&#x20;   | LabelDefinition Label

&#x20;   deriving (Show, Eq)

```



This is a preliminary design, not a complete instruction set.



The final LIR must define operand constraints, control-flow semantics, value representation, error handling and target-independent operation semantics.



\## 9. Validation and compilation boundaries



The compiler must distinguish the following:



\*\*Syntactic validity:\*\* The input conforms to a supported grammar.



\*\*Semantic validity:\*\* The input has a supported and coherent interpretation.



\*\*Symbol validity:\*\* Identifiers resolve according to the language's declaration and scope rules.



\*\*Type and domain validity:\*\* Operations are compatible with their operands and declared mathematical domains.



\*\*IR validity:\*\* The constructed representation satisfies its invariants.



\*\*Lowering validity:\*\* The IR can be transformed into the selected LIR.



\*\*Code-generation validity:\*\* The LIR can be translated to the selected target.



\*\*Termination analysis:\*\* The compiler can establish termination properties where the language subset and analysis permit it.



These are separate properties. Passing one stage does not automatically establish all the others.



\## 10. Termination and execution



HumMac is a compiler, not fundamentally a mathematical evaluator.



It does not need to know the numerical value of every symbolic variable in order to compile an expression.



For example:



```text

Set y to 2x + 5.

```



can be represented and compiled without knowing the value of `x`, provided the symbol is valid under the language's rules.



The generated program may obtain that value from its execution environment.



Termination analysis is an independent compiler analysis. It may prove termination for a restricted subset, but it must not claim to decide termination for arbitrary generated programs.



\## 11. Backend independence



The LIR must be sufficiently independent of the original input language and, where possible, the target architecture.



Potential future backends include:



\- x86-64

\- ARM64

\- Virtual-machine bytecode

\- Other supported instruction targets



A backend must consume validated LIR rather than reinterpret the original human-written input.



Adding a new backend should not require changing the mathematical frontend or the meaning of the Structured Mathematical IR.



\## 12. Design invariants



The following principles govern the IR architecture:



1\. Mathematical meaning must be preserved throughout compilation.

2\. Equivalent supported inputs must converge to equivalent canonical IR.

3\. Symbolic variables must not require known numerical values merely to be represented.

4\. Mathematical relations must remain distinct from computational assignments.

5\. The Structured Mathematical IR must remain independent of target architecture.

6\. Lowering must preserve the semantics of the structured representation.

7\. Unsupported constructs must be rejected rather than silently approximated.

8\. Validation, termination analysis and code generation must remain distinct stages.

9\. The compiler must not claim correctness beyond the operations and semantics it has formally specified.

10\. Every backend must implement the same defined LIR semantics.



\## 13. Implementation status



This specification establishes the proposed architecture.



It does not imply that the current Haskell prototype already implements these structures.



Implementation will proceed only after the language grammar, symbol rules, type system, IR invariants and lowering semantics have been sufficiently specified.



The first implementation milestone will be a structured mathematical IR and a frontend capable of producing it from a limited, explicitly defined subset of the input language.



\*\*End of specification.\*\*

