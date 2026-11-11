-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- https://www.apache.org/licenses/LICENSE-2.0

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

data Instruction
    = Assign Variable Expression
    | Print Expression
    | Repeat Integer [Instruction]
    deriving (Show, Eq)

type Program = [Instruction]
