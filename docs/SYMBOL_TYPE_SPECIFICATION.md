\# HumMac: Symbol Resolution, Type Inference and Runtime Binding



\*\*Document:\*\* Symbol and Type System Specification  

\*\*Project:\*\* HumMac (Human-to-Machine Compiler)  

\*\*Version:\*\* 0.1 — Design Draft  

\*\*Status:\*\* Proposed architecture



\## 1. Purpose



HumMac uses implicit symbol introduction.



An identifier does not require an explicit declaration before it can be recognised as a mathematical symbol.



The compiler must be capable of representing and compiling expressions containing unknown variables without requiring their numerical values at compilation time.



The symbol system must distinguish:



1\. Symbol identity.

2\. Symbol type.

3\. Symbol usage and assignment.

4\. Runtime value binding.



These concepts must not be conflated.



\## 2. Implicit symbol introduction



Any syntactically valid identifier that appears in a supported mathematical or computational context may introduce a symbol.



For example:



```text

Set y to 2x + 5.

```



The compiler introduces symbols for `x` and `y` if they do not already exist in the applicable scope.



The compiler constructs a symbol table and assigns each symbol a unique internal identifier.



Conceptually:



```text

Symbol table:



SymbolId(1)

&#x20;   name: y

&#x20;   type: inferred



SymbolId(2)

&#x20;   name: x

&#x20;   type: inferred

```



The actual identifiers and ordering are implementation details. Symbol identity must not depend on the spelling or position of an occurrence alone.



Implicit introduction does not mean that arbitrary text is accepted as an identifier. Identifiers must conform to the lexical rules of the language.



Function names, reserved words and operators must be distinguished from ordinary identifiers.



\## 3. Symbol identity and resolution



\### 3.1 Symbol identifiers



Every resolved symbol receives a unique internal identifier.



Conceptually:



```haskell

newtype SymbolId = SymbolId Int

&#x20;   deriving (Show, Eq, Ord)

```



The compiler maintains a symbol table that associates each identifier with its metadata.



\### 3.2 Name resolution



When the compiler encounters an identifier:



1\. It checks the applicable lexical scope.

2\. If an existing symbol is found, the occurrence refers to that symbol.

3\. If no symbol exists, a new symbol is introduced in the applicable scope.

4\. The new symbol receives a unique identifier.

5\. Subsequent occurrences resolve to the same symbol unless a distinct scope introduces a separate symbol.



\### 3.3 Scope



The initial implementation will use a simple program-level scope.



Nested lexical scopes and shadowing will be introduced only after their semantics are specified.



An identifier must not silently change its identity because its type or value changes.



\## 4. Symbol metadata



A symbol must retain at least:



\- Internal identifier.

\- Source-level name.

\- Inferred or established type.

\- Scope information.

\- Source locations of relevant occurrences.

\- Read and write usage information.

\- Runtime binding classification.



A conceptual Haskell representation is:



```haskell

data SymbolInfo = SymbolInfo

&#x20;   { symbolId :: SymbolId

&#x20;   , symbolName :: String

&#x20;   , symbolType :: Type

&#x20;   , symbolScope :: ScopeId

&#x20;   , symbolOrigin :: SymbolOrigin

&#x20;   } deriving (Show, Eq)



data SymbolOrigin

&#x20;   = ExternalInput

&#x20;   | ProgramDefined

&#x20;   deriving (Show, Eq)

```



This is a design sketch, not final implementation code.



\## 5. Type system



\### 5.1 Initial types



HumMac will initially distinguish:



```haskell

data Type

&#x20;   = IntegerType

&#x20;   | RationalType

&#x20;   | RealType

&#x20;   | BooleanType

&#x20;   | FunctionType \[Type] Type

&#x20;   | TypeVariable Int

&#x20;   deriving (Show, Eq)

```



The exact representation may evolve.



The initial type system is intended to support numerical and logical computation.



Vectors, matrices, complex numbers, physical quantities with units and other mathematical structures are future extensions.



\### 5.2 Unknown types



A newly introduced symbol initially receives an unresolved type variable.



For example:



```text

Set y to 2x + 5.

```



At first, the type of `x` is unknown.



The arithmetic operations impose constraints on its type.



The compiler must infer a compatible type or report that it cannot establish one.



\### 5.3 Type inference



Type inference derives type constraints from operations and program context.



Examples:



| Expression | Type constraint |

|---|---|

| `x + 5` | `x` must support compatible numerical addition |

| `x \* y` | Both operands must support compatible multiplication |

| `x / y` | Both operands must be numerical |

| `x > y` | Operands must support an applicable ordering |

| `NOT p` | `p` must be Boolean |

| `p AND q` | Both operands must be Boolean |



The compiler must not infer types merely from variable names.



For example, `temperature` is not automatically a real number because of its name. Its type is inferred from its use or established by explicit type information.



\### 5.4 Numeric compatibility



The initial numeric type hierarchy is:



```text

Integer

&#x20;  |

Rational

&#x20;  |

Real

```



This is a conceptual widening hierarchy.



Permitted conversions must be defined explicitly.



Examples:



\- Integer values may be represented as rational values.

\- Rational values may be converted to real values where the selected semantics permit it.

\- A real value must not silently be narrowed to an integer.

\- A type conflict must be rejected unless an explicitly defined conversion resolves it.



\### 5.5 Exact arithmetic



Integer and rational arithmetic should preserve exactness where possible.



Decimal literals must have explicitly specified semantics. The initial proposal is to interpret finite decimal literals as exact rational values during parsing rather than immediately converting them to binary floating-point values.



For example:



```text

0.25

```



may be represented exactly as:



```text

1/4

```



This avoids introducing unnecessary floating-point approximation into the mathematical IR.



Real-number representations and target-specific floating-point behaviour must be specified separately.



\### 5.6 Symbolic expressions



An unknown numerical value is not a type.



For example, `x` can have type `Real` even when its numerical value is unavailable during compilation.



The compiler can represent:



```text

2x + 5

```



as an expression over a real-valued symbol without evaluating it.



The absence of a runtime value must not be treated as a type error.



\## 6. Assignment and symbol definition



An assignment introduces or updates a symbol.



For example:



```text

Set x to 10.

Set y to 2x + 5.

```



The first instruction introduces `x` and establishes its value through a program assignment.



The second introduces `y` and references the already established symbol `x`.



Assignment must preserve symbol identity.



If a symbol has an established type, subsequent assignments must be type-compatible with that type.



The compiler must not silently change an established symbol's type in a way that invalidates earlier operations.



\## 7. Read and write analysis



The compiler must distinguish between reading a symbol and writing to it.



Examples:



```text

Set x to 10.

```



This writes to `x`.



```text

Set y to 2x + 5.

```



This reads `x` and writes to `y`.



A symbol that is read before any program definition may represent an external input.



For example:



```text

Set y to 2x + 5.

```



If `x` has no preceding program assignment, the compiler may classify it as an external input.



The compiler must not invent a numerical value for that input.



Read-before-write analysis must account for control flow. A symbol assigned on only one possible path cannot automatically be treated as definitely assigned on every path.



\## 8. Runtime binding



Runtime binding is separate from compilation-time symbol resolution.



A symbol may be fully resolved as an identifier and have a known type without having a known numerical value.



For example:



```text

Set y to 2x + 5.

```



may produce a compiled program that expects `x` to be supplied by its execution environment.



The compiler must retain enough metadata to identify this requirement.



Conceptually:



```text

External input:

&#x20;   symbol: x

&#x20;   type: Real

&#x20;   required: true

```



The actual representation of runtime inputs depends on the selected backend and its application binary interface or virtual-machine calling convention.



A backend must define how external inputs are received, represented and validated.



If a required runtime input is unavailable, the generated program or its runtime environment must handle that situation according to the target's defined error semantics.



HumMac itself does not need to obtain the numerical value during compilation.



\## 9. Compilation-time and runtime responsibilities



| Operation | Compilation time | Runtime |

|---|---|---|

| Recognise an identifier | Yes | No |

| Assign a SymbolId | Yes | No |

| Infer compatible types | Yes | No |

| Construct IR | Yes | No |

| Generate code | Yes | No |

| Obtain external input value | No | Yes |

| Compute a numerical result | Not required | Yes |

| Detect runtime input absence | Define the requirement | Handle the condition |



Some values may be known at compilation time, but compile-time evaluation is an optional optimisation, not a requirement for representing or compiling symbolic expressions.



\## 10. Error handling



Implicit symbol introduction must not make HumMac permissive towards meaningless or unsupported constructs.



The compiler must distinguish:



\*\*Unknown numerical value:\*\* Acceptable when the expression can be represented symbolically and the runtime contract is defined.



\*\*Unknown identifier:\*\* Normally introduced as a new symbol in a supported context.



\*\*Invalid identifier syntax:\*\* Rejected by lexical analysis.



\*\*Unsupported function:\*\* Rejected unless the function is registered or otherwise defined by the language.



\*\*Type conflict:\*\* Rejected when no valid type assignment or conversion exists.



\*\*Invalid operation:\*\* Rejected when an operation violates the applicable type or mathematical domain.



\*\*Unresolved runtime input:\*\* Recorded as a runtime requirement; it is not automatically a compilation error.



The compiler should provide source locations and meaningful diagnostics for rejected constructs.



\## 11. Design invariants



1\. Identifiers may be introduced implicitly.

2\. Symbol identity must remain stable within its scope.

3\. A symbol need not have a known numerical value at compilation time.

4\. Type inference must be based on program constraints, not variable names.

5\. Symbolic representation must remain distinct from data types.

6\. Reads and writes must be tracked separately.

7\. External inputs must be represented explicitly in compilation metadata.

8\. Runtime binding must not be confused with compilation-time evaluation.

9\. Type and domain violations must not be silently accepted.

10\. Backends must respect the runtime-binding requirements of the IR.



\## 12. Implementation boundary



This document defines the intended symbol and type-system behaviour.



It does not imply that the current Haskell prototype implements implicit symbol resolution, type inference or external input binding.



Implementation will follow after the language grammar and IR data structures have been finalised.



\*\*End of specification.\*\*

