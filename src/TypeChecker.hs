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


module TypeChecker where

import Syntax

validateExpression :: [Variable] -> Expression -> Either String ()

validateExpression _ (Number _) =
    Right ()

validateExpression defined (VariableRef name)
    | name `elem` defined = Right ()
    | otherwise = Left ("Undefined variable: " ++ name)

validateExpression defined (Add left right) = do
    validateExpression defined left
    validateExpression defined right

validateExpression defined (Subtract left right) = do
    validateExpression defined left
    validateExpression defined right

validateExpression defined (Multiply left right) = do
    validateExpression defined left
    validateExpression defined right

validateExpression defined (Divide left right) = do
    validateExpression defined left
    validateExpression defined right

validateProgram :: Program -> Either String ()
validateProgram = go []
    where
        go _ [] = Right ()

        go defined (instruction:rest) =
            case instruction of
                Assign name expression -> do
                    validateExpression defined expression
                    go (name : defined) rest

                Print expression -> do
                    validateExpression defined expression
                    go defined rest

                Repeat count body
                    | count < 0 ->
                        Left "Repeat count must be a non-negative integer."

                    | otherwise -> do
                        validateProgramWith defined body
                        go defined rest

        validateProgramWith defined body =
            go defined body
