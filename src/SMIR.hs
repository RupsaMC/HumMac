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

module SMIR
    ( SymbolId(..)
    , FunctionId(..)
    , Program(..)
    , NumericLiteral(..)
    , Expr(..)
    , Relation(..)
    , Proposition(..)
    , ValueExpr(..)
    , Instruction(..)
    ) where

newtype SymbolId = SymbolId Int
    deriving (Show, Eq, Ord)

newtype FunctionId = FunctionId String
    deriving (Show, Eq, Ord)

newtype Program = Program [Instruction]
    deriving (Show, Eq)

-- Preserve the original category of numeric literals.
data NumericLiteral
    = IntegerLiteral Integer
    | RealLiteral Rational
    deriving (Show, Eq)

-- Mathematical expressions.
data Expr
    = Constant NumericLiteral
    | Symbol SymbolId
    | Add Expr Expr
    | Subtract Expr Expr
    | Multiply Expr Expr
    | Divide Expr Expr
    | Power Expr Expr
    | Negate Expr
    | FunctionCall FunctionId [Expr]
    deriving (Show, Eq)

data Relation
    = Equal Expr Expr
    | NotEqual Expr Expr
    | LessThan Expr Expr
    | GreaterThan Expr Expr
    | LessEqual Expr Expr
    | GreaterEqual Expr Expr
    deriving (Show, Eq)

data Proposition
    = BooleanConstant Bool
    | Compare Relation
    | And Proposition Proposition
    | Or Proposition Proposition
    | Not Proposition
    deriving (Show, Eq)

data ValueExpr
    = NumericValue Expr
    | BooleanValue Proposition
    deriving (Show, Eq)

data Instruction
    = Assign SymbolId ValueExpr
    | Evaluate Expr
    | Check Proposition
    | If Proposition [Instruction] [Instruction]
    | Repeat Expr [Instruction]
    deriving (Show, Eq)
