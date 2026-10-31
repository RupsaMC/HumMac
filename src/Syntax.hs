module Syntax where

type Variable = String

data Expression
    = Number Integer
    | VariableRef Variable
    | Add Expression Expression
    | Subtract Expression Expression
    | Multiply Expression Expression
    | Divide Expression Expression
    deriving (Show, Eq)

data Instruction
    = Assign Variable Expression
    | Print Expression
    deriving (Show, Eq)

type Program = [Instruction]