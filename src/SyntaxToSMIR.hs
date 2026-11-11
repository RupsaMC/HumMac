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

convertProgram
    :: Legacy.Program
    -> (Core.Program, SymbolTable)
convertProgram instructions =
    let (converted, finalTable) =
            convertInstructions instructions emptySymbolTable
    in (Core.Program converted, finalTable)

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

convertInstruction
    :: Legacy.Instruction
    -> SymbolTable
    -> (Core.Instruction, SymbolTable)
convertInstruction (Legacy.Assign name expression) table =
    let (info, table1) =
            introduceSymbol name table
        (convertedExpression, table2) =
            convertExpression expression table1
        table3 =
            recordWrite (symbolId info) table2
    in
        ( Core.Assign
            (symbolId info)
            (Core.NumericValue convertedExpression)
        , table3
        )

convertInstruction (Legacy.Print expression) table =
    let (convertedExpression, table1) =
            convertExpression expression table
    in (Core.Evaluate convertedExpression, table1)

convertInstruction (Legacy.Repeat count body) table =
    let (convertedBody, bodyTable) =
            convertInstructions body table
        finalTable =
            if count == 0
                then restoreUsageMetadata table bodyTable
                else bodyTable
        countExpression =
            Core.Constant (Core.IntegerLiteral count)
    in (Core.Repeat countExpression convertedBody, finalTable)

convertExpression
    :: Legacy.Expression
    -> SymbolTable
    -> (Core.Expr, SymbolTable)
convertExpression (Legacy.Number value) table =
    (Core.Constant (Core.IntegerLiteral value), table)

convertExpression (Legacy.Decimal value) table =
    (Core.Constant (Core.RealLiteral value), table)

convertExpression (Legacy.VariableRef name) table =
    let (info, table1) =
            introduceSymbol name table
        table2 =
            recordRead (symbolId info) table1
    in (Core.Symbol (symbolId info), table2)

convertExpression (Legacy.Add left right) table =
    convertBinary Core.Add left right table

convertExpression (Legacy.Subtract left right) table =
    convertBinary Core.Subtract left right table

convertExpression (Legacy.Multiply left right) table =
    convertBinary Core.Multiply left right table

convertExpression (Legacy.Divide left right) table =
    convertBinary Core.Divide left right table

convertExpression (Legacy.Power base powerExpression) table =
    convertBinary Core.Power base powerExpression table

convertExpression (Legacy.Negate operand) table =
    let (convertedOperand, table1) =
            convertExpression operand table
    in (Core.Negate convertedOperand, table1)

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
