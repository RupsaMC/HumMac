
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
