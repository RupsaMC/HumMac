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


module TypeSystem
    ( Type(..)
    , TypeError(..)
    , isNumericType
    , canPromote
    , promoteNumericTypes
    ) where

-- The initial HumMac type hierarchy.
data Type
    = IntegerType
    | RationalType
    | RealType
    | BooleanType
    | FunctionType [Type] Type
    | TypeVariable Int
    deriving (Show, Eq, Ord)

-- Errors arising from type compatibility checks.
data TypeError
    = NotNumeric Type
    | IncompatibleTypes Type Type
    deriving (Show, Eq)

-- Check whether a type belongs to the numeric hierarchy.
isNumericType :: Type -> Bool
isNumericType IntegerType = True
isNumericType RationalType = True
isNumericType RealType = True
isNumericType _ = False

-- Check whether a value of one type can be
-- implicitly promoted to another type.
canPromote :: Type -> Type -> Bool
canPromote IntegerType IntegerType = True
canPromote IntegerType RationalType = True
canPromote IntegerType RealType = True

canPromote RationalType RationalType = True
canPromote RationalType RealType = True

canPromote RealType RealType = True

canPromote BooleanType BooleanType = True

canPromote (FunctionType args1 result1)
           (FunctionType args2 result2) =
    args1 == args2 && result1 == result2

canPromote (TypeVariable a) (TypeVariable b) =
    a == b

canPromote _ _ = False

-- Find the least numeric type that can represent
-- operands of both supplied types.
promoteNumericTypes :: Type -> Type -> Either TypeError Type

promoteNumericTypes a b
    | not (isNumericType a) = Left (NotNumeric a)
    | not (isNumericType b) = Left (NotNumeric b)

    | canPromote a b = Right b
    | canPromote b a = Right a

    | otherwise = Left (IncompatibleTypes a b)
