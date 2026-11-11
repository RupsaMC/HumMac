-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0
-- See the LICENSE file for details.

module SyntaxToSMIR
    ( convertProgram
    , convertExpression
    ) where

import qualified Syntax as Legacy
import qualified SMIR as Core

import SymbolTable

-- Convert a complete legacy program into SMIR.
-- The returned symbol table preserves source-level names and identities.

convertProgram
    :: Legacy.Program
    -> (Core.Program, SymbolTable)

convertProgram instructions =
    let (converted, finalTable) =
            convertInstructions instructions emptySymbolTable
    in (Core.Program converted, finalTable)


-- Convert an instruction sequence while threading the symbol table.

convertInstructions
    :: [Legacy.Instruction]
    -> SymbolTable
    -> ([Core.Instruction], SymbolTable)

convertInstructions [] table =
    ([], table)

convertInstructions (instruction:rest) table =
    let (converted, table1) =
            convertInstruction instruction table

        (remaining, table2) =
            convertInstructions rest table1

    in (converted : remaining, table2)


-- Convert one instruction.

convertInstruction
    :: Legacy.Instruction
    -> SymbolTable
    -> (Core.Instruction, SymbolTable)

convertInstruction (Legacy.Assign name expression) table =
    let (info, table1) =
            introduceSymbol name table

        (convertedExpression, table2) =
            convertExpression expression table1

    in
        ( Core.Assign
            (symbolId info)
            (Core.NumericValue convertedExpression)
        , table2
        )

convertInstruction (Legacy.Print expression) table =
    let (convertedExpression, table1) =
            convertExpression expression table

    in
        (Core.Evaluate convertedExpression, table1)

convertInstruction (Legacy.Repeat count body) table =
    let (convertedBody, table1) =
            convertInstructions body table

        countExpression =
            Core.Constant (Core.IntegerLiteral count)

    in
        (Core.Repeat countExpression convertedBody, table1)


-- Convert an expression while introducing previously unseen symbols.

convertExpression
    :: Legacy.Expression
    -> SymbolTable
    -> (Core.Expr, SymbolTable)

convertExpression (Legacy.Number value) table =
    (Core.Constant (Core.IntegerLiteral value), table)

convertExpression (Legacy.VariableRef name) table =
    let (info, table1) =
            introduceSymbol name table

    in (Core.Symbol (symbolId info), table1)

convertExpression (Legacy.Add left right) table =
    convertBinary Core.Add left right table

convertExpression (Legacy.Subtract left right) table =
    convertBinary Core.Subtract left right table

convertExpression (Legacy.Multiply left right) table =
    convertBinary Core.Multiply left right table

convertExpression (Legacy.Divide left right) table =
    convertBinary Core.Divide left right table


-- Convert a binary expression from left to right.

convertBinary
    :: (Core.Expr -> Core.Expr -> Core.Expr)
    -> Legacy.Expression
    -> Legacy.Expression
    -> SymbolTable
    -> (Core.Expr, SymbolTable)

convertBinary constructor left right table =
    let (convertedLeft, table1) =
            convertExpression left table

        (convertedRight, table2) =
            convertExpression right table1

    in (constructor convertedLeft convertedRight, table2)
