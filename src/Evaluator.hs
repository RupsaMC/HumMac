-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- https://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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

updateEnvironment :: Variable -> Integer -> Environment -> Environment
updateEnvironment name value environment =
    (name, value) : filter (\(key, _) -> key /= name) environment

evalInstruction
    :: Environment
    -> Instruction
    -> Either String (Environment, Maybe Integer)

evalInstruction environment (Assign name expression) = do
    value <- evalExpression environment expression
    let newEnvironment = updateEnvironment name value environment
    Right (newEnvironment, Nothing)

evalInstruction environment (Print expression) = do
    value <- evalExpression environment expression
    Right (environment, Just value)

evalProgram
    :: Program
    -> Either String (Environment, [Integer])

evalProgram instructions =
    go instructions [] []
    where
        go [] environment output =
            Right (environment, output)

        go (instruction:rest) environment output = do
            (newEnvironment, result) <-
                evalInstruction environment instruction

            let newOutput =
                    case result of
                        Nothing -> output
                        Just value -> output ++ [value]

            go rest newEnvironment newOutput