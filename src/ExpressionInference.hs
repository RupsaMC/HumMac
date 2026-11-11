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


module ExpressionInference
    ( FunctionSignature(..)
    , PromotionConstraint(..)
    , ExpressionResult(..)
    , ExpressionError(..)
    , SymbolTypes
    , FunctionRegistry
    , inferExpression
    , inferExpressionFrom
    , inferExpressionWithCounter
    ) where

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)

import SMIR
import TypeSystem
import TypeInference

data FunctionSignature = FunctionSignature
    { argumentTypes :: [Type]
    , returnType :: Type
    }
    deriving (Show, Eq)

data PromotionConstraint
    = CommonNumericType Type Type Type
    | DivisionResultType Type Type Type
    deriving (Show, Eq)

data ExpressionResult = ExpressionResult
    { expressionType :: Type
    , typeConstraints :: [TypeConstraint]
    , pendingPromotions :: [PromotionConstraint]
    }
    deriving (Show, Eq)

data ExpressionError
    = UnknownFunction FunctionId
    | IncorrectFunctionArity FunctionId Int Int
    | InvalidNumericOperands Type Type
    deriving (Show, Eq)

type SymbolTypes = Map SymbolId Type

type FunctionRegistry = Map FunctionId FunctionSignature

type InferResult = (Int, ExpressionResult)

-- Standard entry point.
inferExpression
    :: SymbolTypes
    -> FunctionRegistry
    -> Expr
    -> Either ExpressionError ExpressionResult

inferExpression =
    inferExpressionFrom 1000000

-- Entry point with a caller-supplied starting counter.
inferExpressionFrom
    :: Int
    -> SymbolTypes
    -> FunctionRegistry
    -> Expr
    -> Either ExpressionError ExpressionResult

inferExpressionFrom firstFreshTypeVariable symbolTypes functions expression = do
    (_, result) <-
        inferExpressionWithCounter
            firstFreshTypeVariable
            symbolTypes
            functions
            expression
    Right result

-- Entry point that also returns the next available counter.
inferExpressionWithCounter
    :: Int
    -> SymbolTypes
    -> FunctionRegistry
    -> Expr
    -> Either ExpressionError (Int, ExpressionResult)

inferExpressionWithCounter firstFreshTypeVariable symbolTypes functions expression =
    infer firstFreshTypeVariable expression

  where

    infer :: Int -> Expr -> Either ExpressionError InferResult

    infer next (Constant (IntegerLiteral _)) =
        Right (next, ExpressionResult IntegerType [] [])

    infer next (Constant (RealLiteral _)) =
        Right (next, ExpressionResult RealType [] [])

    infer next (Symbol symbolId) =
        let typ =
                Map.findWithDefault
                    (TypeVariable (symbolIndex symbolId))
                    symbolId
                    symbolTypes
        in Right (next, ExpressionResult typ [] [])

    infer next (Negate operand) = do
        (next1, result) <- infer next operand

        let typ = expressionType result

        if not (isPotentiallyNumeric typ)
            then Left (InvalidNumericOperands typ typ)
            else
                Right
                    (next1, ExpressionResult
                        typ
                        (typeConstraints result ++ [RequiresNumeric typ])
                        (pendingPromotions result))

    infer next (Add left right) =
        inferArithmetic next left right False

    infer next (Subtract left right) =
        inferArithmetic next left right False

    infer next (Multiply left right) =
        inferArithmetic next left right False

    infer next (Divide left right) =
        inferArithmetic next left right True

    infer next (Power base powerExpression) = do
        (next1, baseResult) <- infer next base
        (next2, powerResult) <- infer next1 powerExpression

        let baseType = expressionType baseResult
            powerType = expressionType powerResult

        if not (isPotentiallyNumeric baseType)
            then Left (InvalidNumericOperands baseType baseType)
            else
                Right
                    (next2, ExpressionResult
                        baseType
                        (typeConstraints baseResult
                            ++ typeConstraints powerResult
                            ++ [ RequiresNumeric baseType
                               , TypesEqual powerType IntegerType
                               ])
                        (pendingPromotions baseResult
                            ++ pendingPromotions powerResult))

    infer next (FunctionCall functionId arguments) =
        case Map.lookup functionId functions of
            Nothing ->
                Left (UnknownFunction functionId)

            Just signature ->
                let expected = argumentTypes signature
                    actualCount = length arguments
                    expectedCount = length expected
                in
                    if actualCount /= expectedCount
                    then
                        Left (IncorrectFunctionArity
                            functionId expectedCount actualCount)
                    else do
                        (next1, results) <-
                            inferArguments next arguments

                        let constraints =
                                concatMap typeConstraints results
                                ++ zipWith
                                    TypesEqual
                                    (map expressionType results)
                                    expected

                        Right
                            (next1, ExpressionResult
                                (returnType signature)
                                constraints
                                (concatMap pendingPromotions results))

    inferArithmetic next left right isDivision = do
        (next1, leftResult) <- infer next left
        (next2, rightResult) <- infer next1 right

        let leftType = expressionType leftResult
            rightType = expressionType rightResult

            constraints =
                typeConstraints leftResult
                ++ typeConstraints rightResult
                ++ [ RequiresNumeric leftType
                   , RequiresNumeric rightType
                   ]

            existingPromotions =
                pendingPromotions leftResult
                ++ pendingPromotions rightResult

        if not (isPotentiallyNumeric leftType)
            || not (isPotentiallyNumeric rightType)
            then
                Left (InvalidNumericOperands leftType rightType)
            else
                case (numericRank leftType, numericRank rightType) of

                    (Just leftRank, Just rightRank) ->
                        let resultType =
                                if isDivision
                                    && leftRank == 0
                                    && rightRank == 0
                                then RationalType
                                else rankType (max leftRank rightRank)
                        in
                            Right
                                (next2, ExpressionResult
                                    resultType
                                    constraints
                                    existingPromotions)

                    _ ->
                        let resultType = TypeVariable next2

                            promotion =
                                if isDivision
                                then DivisionResultType
                                    leftType rightType resultType
                                else CommonNumericType
                                    leftType rightType resultType

                        in
                            Right
                                (next2 + 1, ExpressionResult
                                    resultType
                                    (constraints ++ [RequiresNumeric resultType])
                                    (existingPromotions ++ [promotion]))

    inferArguments
        :: Int
        -> [Expr]
        -> Either ExpressionError (Int, [ExpressionResult])

    inferArguments next [] =
        Right (next, [])

    inferArguments next (argument:rest) = do
        (next1, result) <- infer next argument
        (next2, remaining) <- inferArguments next1 rest
        Right (next2, result : remaining)

    symbolIndex :: SymbolId -> Int
    symbolIndex (SymbolId identifier) =
        negate (identifier + 1)

    isPotentiallyNumeric :: Type -> Bool
    isPotentiallyNumeric IntegerType = True
    isPotentiallyNumeric RationalType = True
    isPotentiallyNumeric RealType = True
    isPotentiallyNumeric (TypeVariable _) = True
    isPotentiallyNumeric _ = False

    numericRank :: Type -> Maybe Int
    numericRank IntegerType = Just 0
    numericRank RationalType = Just 1
    numericRank RealType = Just 2
    numericRank _ = Nothing

    rankType :: Int -> Type
    rankType 0 = IntegerType
    rankType 1 = RationalType
    rankType _ = RealType
