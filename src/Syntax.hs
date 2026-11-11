-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0
-- See the LICENSE file for details.

module Syntax where

type Variable = String

data Expression
    = Number Integer
    | Decimal Rational
    | VariableRef Variable
    | Add Expression Expression
    | Subtract Expression Expression
    | Multiply Expression Expression
    | Divide Expression Expression
    | Power Expression Expression
    | Negate Expression
    deriving (Show, Eq)

data ComparisonOperator
    = EqualTo
    | NotEqualTo
    | LessThan
    | GreaterThan
    | LessThanOrEqualTo
    | GreaterThanOrEqualTo
    deriving (Show, Eq)

data Proposition
    = Compare ComparisonOperator Expression Expression
    deriving (Show, Eq)

data Instruction
    = Assign Variable Expression
    | Print Expression
    | Repeat Integer [Instruction]
    | If Proposition [Instruction] [Instruction]
    deriving (Show, Eq)

type Program = [Instruction]
