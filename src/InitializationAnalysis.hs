-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0
-- See the LICENSE file for details.

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

-- The first set contains symbols that require runtime initialization.
-- The second set contains symbols already initialized.
analyzeInitialization
    :: Set SymbolId
    -> Set SymbolId
    -> [Instruction]
    -> Either InitializationError (Set SymbolId)

analyzeInitialization required initiallyInitialized instructions =
    analyzeSequence required initiallyInitialized instructions

analyzeSequence
    :: Set SymbolId
    -> Set SymbolId
    -> [Instruction]
    -> Either InitializationError (Set SymbolId)

analyzeSequence _ initialized [] =
    Right initialized

analyzeSequence required initialized (instruction:rest) = do
    updated <- analyzeInstruction required initialized instruction
    analyzeSequence required updated rest

analyzeInstruction
    :: Set SymbolId
    -> Set SymbolId
    -> Instruction
    -> Either InitializationError (Set SymbolId)

analyzeInstruction required initialized instruction =
    case instruction of
        Assign symbol value -> do
            checkValue required initialized value
            Right (Set.insert symbol initialized)

        Evaluate expression -> do
            checkExpression required initialized expression
            Right initialized

        Check proposition -> do
            checkProposition required initialized proposition
            Right initialized

        If condition thenBranch elseBranch -> do
            checkProposition required initialized condition
            thenInitialized <- analyzeSequence required initialized thenBranch
            elseInitialized <- analyzeSequence required initialized elseBranch
            Right (Set.intersection thenInitialized elseInitialized)

        Repeat (Constant (IntegerLiteral 0)) _ ->
            Right initialized

        Repeat (Constant (IntegerLiteral count)) body
            | count > 0 ->
                analyzeSequence required initialized body

        Repeat count body -> do
            checkExpression required initialized count
            _ <- analyzeSequence required initialized body
            Right initialized

checkValue
    :: Set SymbolId
    -> Set SymbolId
    -> ValueExpr
    -> Either InitializationError ()

checkValue required initialized value =
    case value of
        NumericValue expression ->
            checkExpression required initialized expression
        BooleanValue proposition ->
            checkProposition required initialized proposition

checkExpression
    :: Set SymbolId
    -> Set SymbolId
    -> Expr
    -> Either InitializationError ()

checkExpression required initialized expression =
    case expression of
        Constant _ -> Right ()
        Symbol symbol -> requireInitialized required initialized symbol
        Add left right -> checkBoth required initialized left right
        Subtract left right -> checkBoth required initialized left right
        Multiply left right -> checkBoth required initialized left right
        Divide left right -> checkBoth required initialized left right
        Power base powerExponent -> checkBoth required initialized base powerExponent
        Negate operand -> checkExpression required initialized operand
        FunctionCall _ arguments ->
            mapM_ (checkExpression required initialized) arguments

checkBoth
    :: Set SymbolId
    -> Set SymbolId
    -> Expr
    -> Expr
    -> Either InitializationError ()

checkBoth required initialized left right = do
    checkExpression required initialized left
    checkExpression required initialized right

checkProposition
    :: Set SymbolId
    -> Set SymbolId
    -> Proposition
    -> Either InitializationError ()

checkProposition required initialized proposition =
    case proposition of
        BooleanConstant _ -> Right ()
        Compare relation ->
            let (left, right) = relationOperands relation
            in checkBoth required initialized left right
        And left right ->
            checkBothPropositions required initialized left right
        Or left right ->
            checkBothPropositions required initialized left right
        Not operand ->
            checkProposition required initialized operand

checkBothPropositions
    :: Set SymbolId
    -> Set SymbolId
    -> Proposition
    -> Proposition
    -> Either InitializationError ()

checkBothPropositions required initialized left right = do
    checkProposition required initialized left
    checkProposition required initialized right

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
    -> Set SymbolId
    -> SymbolId
    -> Either InitializationError ()

requireInitialized required initialized symbol
    | not (Set.member symbol required) = Right ()
    | Set.member symbol initialized = Right ()
    | otherwise = Left (ReadBeforeInitialization symbol)
