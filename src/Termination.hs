-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0
-- See the LICENSE file for details.

module Termination where

import Syntax

data TerminationCertificate = TerminationCertificate
    { instructionCount :: Integer
    , expressionNodeCount :: Integer
    , terminationMeasure :: Integer
    } deriving (Show, Eq)

expressionSize :: Expression -> Integer
expressionSize (Number _) = 1
expressionSize (Decimal _) = 1
expressionSize (VariableRef _) = 1

expressionSize (Add left right) =
    1 + expressionSize left + expressionSize right

expressionSize (Subtract left right) =
    1 + expressionSize left + expressionSize right

expressionSize (Multiply left right) =
    1 + expressionSize left + expressionSize right

expressionSize (Divide left right) =
    1 + expressionSize left + expressionSize right

expressionSize (Power base powerExpression) =
    1 + expressionSize base + expressionSize powerExpression

expressionSize (Negate operand) =
    1 + expressionSize operand

propositionSize :: Proposition -> Integer
propositionSize (Compare _ left right) =
    1 + expressionSize left + expressionSize right

instructionExecutionCount :: Program -> Integer
instructionExecutionCount =
    sum . map instructionExecutions
    where
        instructionExecutions (Assign _ _) = 1

        instructionExecutions (Print _) = 1

        instructionExecutions (Repeat count body) =
            1 + count * instructionExecutionCount body

        instructionExecutions (If _ thenBody elseBody) =
            1 + max
                (instructionExecutionCount thenBody)
                (instructionExecutionCount elseBody)

programExpressionCount :: Program -> Integer
programExpressionCount =
    sum . map expressionExecutions
    where
        expressionExecutions (Assign _ expression) =
            expressionSize expression

        expressionExecutions (Print expression) =
            expressionSize expression

        expressionExecutions (Repeat count body) =
            count * programExpressionCount body

        expressionExecutions (If proposition thenBody elseBody) =
            propositionSize proposition
                + max
                    (programExpressionCount thenBody)
                    (programExpressionCount elseBody)

verifyProgram :: Program -> Either String TerminationCertificate
verifyProgram program
    | not (allBoundsValid program) =
        Left "Negative repetition bounds are not permitted."

    | otherwise =
        let
            count = instructionExecutionCount program
            nodes = programExpressionCount program
            measure = count + nodes
        in
            Right TerminationCertificate
                { instructionCount = count
                , expressionNodeCount = nodes
                , terminationMeasure = measure
                }

allBoundsValid :: Program -> Bool
allBoundsValid =
    all validInstruction
    where
        validInstruction (Assign _ _) = True

        validInstruction (Print _) = True

        validInstruction (Repeat count body) =
            count >= 0 && allBoundsValid body

        validInstruction (If _ thenBody elseBody) =
            allBoundsValid thenBody && allBoundsValid elseBody
