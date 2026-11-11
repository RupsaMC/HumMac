-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- https://www.apache.org/licenses/LICENSE-2.0

module InitializationAnalysis
    ( InitializationError(..)
    , analyzeInitialization
    ) where

import qualified Data.Set as Set
import Data.Set (Set)

import SMIR


data InitializationError
    = ReadBeforeInitialization SymbolId
    deriving (Show, Eq)


analyzeInitialization
    :: Set SymbolId
    -> [Instruction]
    -> Either InitializationError (Set SymbolId)

analyzeInitialization initiallyInitialized instructions =
    analyzeSequence initiallyInitialized instructions


analyzeSequence
    :: Set SymbolId
    -> [Instruction]
    -> Either InitializationError (Set SymbolId)

analyzeSequence initialized [] =
    Right initialized

analyzeSequence initialized (instruction:rest) = do
    updated <- analyzeInstruction initialized instruction
    analyzeSequence updated rest


analyzeInstruction
    :: Set SymbolId
    -> Instruction
    -> Either InitializationError (Set SymbolId)

analyzeInstruction initialized instruction =
    case instruction of

        Assign symbol value -> do
            checkValue initialized value
            Right (Set.insert symbol initialized)

        Evaluate expression -> do
            checkExpression initialized expression
            Right initialized

        Check proposition -> do
            checkProposition initialized proposition
            Right initialized

        If condition thenBranch elseBranch -> do
            checkProposition initialized condition

            thenInitialized <-
                analyzeSequence initialized thenBranch

            elseInitialized <-
                analyzeSequence initialized elseBranch

            Right (Set.intersection thenInitialized elseInitialized)

        Repeat count body -> do
            checkExpression initialized count

            _ <- analyzeSequence initialized body

            -- A repetition may execute zero times.
            Right initialized


checkValue
    :: Set SymbolId
    -> ValueExpr
    -> Either InitializationError ()

checkValue initialized value =
    case value of
        NumericValue expression ->
            checkExpression initialized expression

        BooleanValue proposition ->
            checkProposition initialized proposition


checkExpression
    :: Set SymbolId
    -> Expr
    -> Either InitializationError ()

checkExpression initialized expression =
    case expression of

        Constant _ ->
            Right ()

        Symbol symbol ->
            requireInitialized initialized symbol

        Add left right ->
            checkBoth initialized left right

        Subtract left right ->
            checkBoth initialized left right

        Multiply left right ->
            checkBoth initialized left right

        Divide left right ->
            checkBoth initialized left right

        Power base powerExponent ->
            checkBoth initialized base powerExponent

        Negate operand ->
            checkExpression initialized operand

        FunctionCall _ arguments ->
            mapM_ (checkExpression initialized) arguments


checkBoth
    :: Set SymbolId
    -> Expr
    -> Expr
    -> Either InitializationError ()

checkBoth initialized left right = do
    checkExpression initialized left
    checkExpression initialized right


checkProposition
    :: Set SymbolId
    -> Proposition
    -> Either InitializationError ()

checkProposition initialized proposition =
    case proposition of

        BooleanConstant _ ->
            Right ()

        Compare relation ->
            let (left, right) = relationOperands relation
            in checkBoth initialized left right

        And left right ->
            checkBothPropositions initialized left right

        Or left right ->
            checkBothPropositions initialized left right

        Not operand ->
            checkProposition initialized operand


checkBothPropositions
    :: Set SymbolId
    -> Proposition
    -> Proposition
    -> Either InitializationError ()

checkBothPropositions initialized left right = do
    checkProposition initialized left
    checkProposition initialized right


relationOperands :: Relation -> (Expr, Expr)

relationOperands relation =
    case relation of
        Equal left right -> (left, right)
        NotEqual left right -> (left, right)
        LessThan left right -> (left, right)
        GreaterThan left right -> (left, right)
        LessEqual left right -> (left, right)
        GreaterEqual left right -> (left, right)


requireInitialized
    :: Set SymbolId
    -> SymbolId
    -> Either InitializationError ()

requireInitialized initialized symbol
    | Set.member symbol initialized =
        Right ()

    | otherwise =
        Left (ReadBeforeInitialization symbol)
