# HumMac
### Human-to-Machine Compiler

**HumMac is an experimental programming language and compiler project, independently developed in Haskell by Rupsa Mandal Chakraborty.**

It explores how mathematical instructions expressed in a controlled, human-readable language can be translated into a structured intermediate representation through parsing, semantic analysis, type inference, and compiler transformations.

HumMac is not an arbitrary natural-language-to-code system. It uses a defined language and grammar so that program meaning can be analysed systematically.

## Project status

**Current stage: Working compiler prototype (v0.1.0.0)**

The current implementation supports source parsing, expression construction, semantic analysis, initialization analysis, and generation of a Structured Mathematical Intermediate Representation (SMIR).

The compiler is under active development. SMIR generation is implemented; a complete SMIR execution engine is not yet available.

## Current capabilities

### Language features

- Variable assignment and mathematical expressions
- Integer and decimal literals
- Exact rational representation of decimal values
- Addition, subtraction, multiplication, division, and exponentiation
- Unary negation and conventional expression precedence
- Right-associative exponentiation
- Implicit multiplication, including forms such as `2x` and `3(x + 1)`
- Bounded repetition using `Repeat`
- Conditional statements using `If`, `Otherwise`, and `End if`
- Six comparison operators: equality, inequality, less than, greater than, less than or equal to, and greater than or equal to
- Nested conditionals and repetition blocks

### Compiler and semantic analysis

- Parsing into a structured abstract syntax tree
- Conversion into SMIR with explicit symbol identifiers
- Symbol-table construction and tracking
- Type inference and type propagation
- Numeric type promotion
- Semantic validation of expressions and instructions
- Definite-initialization analysis for runtime variables
- Branch-aware analysis of assignments across conditional paths
- Distinction between free mathematical symbols and runtime variables
- Regression tests covering parsing, semantic rules, initialization, and conditional behaviour

## Compiler architecture

The current compilation pipeline is:

```text
HumMac source (.eng)
        |
        v
     Parser
        |
        v
 Abstract Syntax Tree
        |
        v
 Symbol-table and SMIR conversion
        |
        v
 Structured Mathematical IR
        |
        v
 Semantic and instruction-level type analysis
        |
        v
 Definite-initialization analysis
        |
        v
 Compilation result
```

The compiler produces a structured representation of the program, together with symbol information and inferred types.

The intermediate representation uses explicit symbol identifiers and represents arithmetic expressions, comparisons, conditionals, and bounded repetition independently of their original source wording.

## Example

A simple HumMac program:

```text
Set x to 10.

If x is greater than 5.
    Set y to 1.
Otherwise.
    Set y to 0.
End if.

Set z to y + 2.
```

This program demonstrates assignment, comparison, conditional branching, and the use of a variable after a conditional.

HumMac parses the source, constructs its internal representation, performs semantic and initialization analysis, and reports the resulting SMIR, symbol table, and inferred types.

More examples are available in the [`examples/`](examples/) directory.

## Getting started

### Requirements

- GHC (Glasgow Haskell Compiler)
- Cabal

The project uses Haskell and the `base` and `containers` packages.

### Build

Clone the repository:

```bash
git clone https://github.com/RupsaMC/HumMac.git
cd HumMac
```

Build the project:

```bash
cabal build all
```

### Compile an example

```bash
cabal run hummac -- examples/conditional-basic.eng
```

You can provide another `.eng` source file in place of the example path.

On successful compilation, HumMac displays:

- The generated Structured Mathematical IR
- The symbol table
- Inferred types
- Semantic-analysis status

The current command-line application compiles and analyses source programs. It does not yet execute the generated SMIR.

### Run the tests

```bash
cabal test
```

The regression suite covers expression parsing, instruction parsing, repetition, conditionals, comparisons, evaluation tests, type inference, semantic validation, and initialization analysis.

## Design direction

HumMac is being developed around the idea that human-readable mathematical instructions should have precise, analysable semantics.

The longer-term direction includes:

- Expanding the controlled mathematical language
- Developing the intermediate representation further
- Strengthening formal and termination analysis
- Developing an execution model for the intermediate representation
- Extending the language while preserving semantic consistency

These are development goals, not claims about features already completed.

## Project structure

```text
HumMac/
├── app/          # Command-line application
├── docs/         # Language and design documentation
├── examples/     # HumMac source programs
├── src/          # Compiler implementation
└── test/         # Regression tests
```

## Author

**Rupsa Mandal Chakraborty**

Creator and independent developer of HumMac.

## License

HumMac is released under the [Apache License 2.0](LICENSE).
