module Termination where

import Syntax

data TerminationCertificate = TerminationCertificate
    { instructionCount :: Int
    , expressionNodeCount :: Int
    , terminationMeasure :: Int
    } deriving (Show, Eq)

-- Count the nodes in an expression tree.
expressionSize :: Expression -> Int
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

-- Count the size of each instruction.
instructionSize :: Instruction -> Int
instructionSize (Assign _ expression) =
    expressionSize expression

instructionSize (Print expression) =
    expressionSize expression

-- Verify that a program belongs to our current
-- structurally terminating language.
verifyProgram :: Program -> Either String TerminationCertificate
verifyProgram program =
    let
        count = length program
        nodes = sum (map instructionSize program)
        measure = count + nodes
    in
        Right TerminationCertificate
            { instructionCount = count
            , expressionNodeCount = nodes
            , terminationMeasure = measure
            }