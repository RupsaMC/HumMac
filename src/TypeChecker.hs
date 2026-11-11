-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0
-- See the LICENSE file for details.

module TypeChecker where

import Syntax

validateExpression :: [Variable] -> Expression -> Either String ()

validateExpression _ (Number _) =
    Right ()

validateExpression _ (Decimal _) =
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

validateExpression defined (Power base powerExpression) = do
    validateExpression defined base
    validateExpression defined powerExpression

validateExpression defined (Negate operand) =
    validateExpression defined operand

validateProposition
    :: [Variable]
    -> Proposition
    -> Either String ()

validateProposition defined (Compare _ left right) = do
    validateExpression defined left
    validateExpression defined right

validateProgram :: Program -> Either String ()
validateProgram program = do
    _ <- go [] program
    Right ()
    where
        go :: [Variable] -> [Instruction] -> Either String [Variable]
        go defined [] =
            Right defined

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
                        _ <- go defined body
                        go defined rest

                If proposition thenBody elseBody -> do
                    validateProposition defined proposition
                    thenDefined <- go defined thenBody
                    elseDefined <- go defined elseBody
                    let guaranteed =
                            filter (`elem` elseDefined) thenDefined
                        merged =
                            unique (defined ++ guaranteed)
                    go merged rest

        unique = foldr
            (\name names ->
                if name `elem` names then names else name : names)
            []
