
module Termination where

import Syntax

data TerminationCertificate = TerminationCertificate
    { instructionCount :: Integer
    , expressionNodeCount :: Integer
    , terminationMeasure :: Integer
    } deriving (Show, Eq)

-- Count the nodes in an expression tree.
expressionSize :: Expression -> Integer
expressionSize (Number _) = 1
expressionSize (VariableRef _) = 1

expressionSize (Add left right) =
    1 + expressionSize left + expressionSize right

expressionSize (Subtract left right) =
    1 + expressionSize left + expressionSize right

expressionSize (Multiply left right) =
    1 + expressionSize left + expressionSize right

expressionSize (Divide left right) =
    1 + expressionSize left + expressionSize right

-- Count instruction executions, including repetitions.
instructionExecutionCount :: Program -> Integer
instructionExecutionCount =
    sum . map instructionExecutions
    where
        instructionExecutions (Assign _ _) = 1

        instructionExecutions (Print _) = 1

        instructionExecutions (Repeat count body) =
            1 + count * instructionExecutionCount body

-- Count expression-node evaluations across all repetitions.
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

-- Verify that the program belongs to our
-- structurally terminating language.
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

-- Check repetition bounds recursively.
allBoundsValid :: Program -> Bool
allBoundsValid =
    all validInstruction
    where
        validInstruction (Assign _ _) = True

        validInstruction (Print _) = True

        validInstruction (Repeat count body) =
            count >= 0 && allBoundsValid body
