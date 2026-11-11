-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this license except in compliance with the License.
-- You may obtain a copy of the License at
--
-- https://www.apache.org/licenses/LICENSE-2.0

module Evaluator where

import Syntax

type Environment = [(Variable, Integer)]

lookupVariable :: Variable -> Environment -> Either String Integer
lookupVariable name environment =
    case lookup name environment of
        Just value -> Right value
        Nothing -> Left ("Undefined variable: " ++ name)

evalExpression :: Environment -> Expression -> Either String Integer

evalExpression _ (Number n) =
    Right n

evalExpression _ (Decimal _) =
    Left "The legacy evaluator does not support decimal expressions."

evalExpression environment (VariableRef name) =
    lookupVariable name environment

evalExpression environment (Add left right) = do
    x <- evalExpression environment left
    y <- evalExpression environment right
    Right (x + y)

evalExpression environment (Subtract left right) = do
    x <- evalExpression environment left
    y <- evalExpression environment right
    Right (x - y)

evalExpression environment (Multiply left right) = do
    x <- evalExpression environment left
    y <- evalExpression environment right
    Right (x * y)

evalExpression environment (Divide left right) = do
    x <- evalExpression environment left
    y <- evalExpression environment right
    if y == 0
        then Left "Division by zero."
        else Right (x `div` y)

evalExpression environment (Power base powerExpression) = do
    x <- evalExpression environment base
    n <- evalExpression environment powerExpression
    if n < 0
        then Left "The legacy evaluator does not support negative integer exponents."
        else Right (x ^ n)

evalExpression environment (Negate operand) = do
    value <- evalExpression environment operand
    Right (negate value)

updateEnvironment :: Variable -> Integer -> Environment -> Environment
updateEnvironment name value environment =
    (name, value) : filter (\(key, _) -> key /= name) environment

evalInstruction
    :: Environment
    -> Instruction
    -> Either String (Environment, [Integer])

evalInstruction environment (Assign name expression) = do
    value <- evalExpression environment expression
    let newEnvironment = updateEnvironment name value environment
    Right (newEnvironment, [])

evalInstruction environment (Print expression) = do
    value <- evalExpression environment expression
    Right (environment, [value])

evalInstruction environment (Repeat count body)
    | count < 0 =
        Left "Repeat count must be a non-negative integer."

    | otherwise =
        evalRepeated count environment []
    where
        evalRepeated remaining currentEnvironment output
            | remaining <= 0 =
                Right (currentEnvironment, output)

            | otherwise = do
                (nextEnvironment, iterationOutput) <-
                    evalInstructions currentEnvironment body

                evalRepeated
                    (remaining - 1)
                    nextEnvironment
                    (output ++ iterationOutput)

evalInstructions
    :: Environment
    -> [Instruction]
    -> Either String (Environment, [Integer])

evalInstructions environment instructions =
    go instructions environment []
    where
        go [] currentEnvironment output =
            Right (currentEnvironment, output)

        go (instruction:rest) currentEnvironment output = do
            (newEnvironment, instructionOutput) <-
                evalInstruction currentEnvironment instruction

            go
                rest
                newEnvironment
                (output ++ instructionOutput)

evalProgram
    :: Program
    -> Either String (Environment, [Integer])

evalProgram instructions =
    evalInstructions [] instructions
