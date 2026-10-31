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


module PromotionResolution
    ( PromotionResolution(..)
    , PromotionError(..)
    , resolvePromotions
    ) where

import Control.Monad (foldM)
import qualified Data.Map.Strict as Map

import TypeSystem
import TypeInference
import ExpressionInference

-- The result of resolving numeric promotion relationships.
data PromotionResolution = PromotionResolution
    { resolvedSubstitution :: TypeSubstitution
    , unresolvedPromotions :: [PromotionConstraint]
    }
    deriving (Show, Eq)

data PromotionError
    = NonNumericPromotionOperand Type
    | ConflictingPromotionResult Type Type
    | PromotionOccursCheck Int Type
    deriving (Show, Eq)

resolvePromotions
    :: TypeSubstitution
    -> [PromotionConstraint]
    -> Either PromotionError PromotionResolution

resolvePromotions initialSubstitution promotions = do
    (finalSubstitution, remaining) <-
        foldM resolveOne (initialSubstitution, []) promotions

    Right PromotionResolution
        { resolvedSubstitution = finalSubstitution
        , unresolvedPromotions = reverse remaining
        }

  where

    resolveOne
        :: (TypeSubstitution, [PromotionConstraint])
        -> PromotionConstraint
        -> Either PromotionError (TypeSubstitution, [PromotionConstraint])

    resolveOne (subst, remaining) promotion =
        case promotion of

            CommonNumericType first second result ->
                resolveCommon subst remaining first second result

            DivisionResultType first second result ->
                resolveDivision subst remaining first second result

    resolveCommon subst remaining first second result = do
        let a = applyTypeSubstitution subst first
            b = applyTypeSubstitution subst second
            r = applyTypeSubstitution subst result

        checkNumericOperand a
        checkNumericOperand b

        case commonResult a b of
            Just target -> do
                updated <- bindResult subst r target
                Right (updated, remaining)

            Nothing ->
                Right
                    (subst,
                    CommonNumericType a b r : remaining)

    resolveDivision subst remaining first second result = do
        let a = applyTypeSubstitution subst first
            b = applyTypeSubstitution subst second
            r = applyTypeSubstitution subst result

        checkNumericOperand a
        checkNumericOperand b

        case divisionResult a b of
            Just target -> do
                updated <- bindResult subst r target
                Right (updated, remaining)

            Nothing ->
                Right
                    (subst,
                    DivisionResultType a b r : remaining)

    -- Reject known nonnumeric types, but allow unresolved variables.
    checkNumericOperand :: Type -> Either PromotionError ()
    checkNumericOperand typ
        | isNumericType typ = Right ()
        | isTypeVariable typ = Right ()
        | otherwise = Left (NonNumericPromotionOperand typ)

    isTypeVariable :: Type -> Bool
    isTypeVariable (TypeVariable _) = True
    isTypeVariable _ = False

    -- Determine the common numeric type when enough information exists.
    commonResult :: Type -> Type -> Maybe Type
    commonResult a b
        | a == b && isTypeVariable a = Just a
        | otherwise =
            case (numericRank a, numericRank b) of
                (Just rankA, Just rankB) ->
                    Just (rankType (max rankA rankB))

                (Just 2, _) -> Just RealType
                (_, Just 2) -> Just RealType

                _ -> Nothing

    -- Integer / Integer produces Rational.
    divisionResult :: Type -> Type -> Maybe Type
    divisionResult IntegerType IntegerType =
        Just RationalType

    divisionResult a b
        | a == b && isTypeVariable a = Nothing
        | otherwise =
            case (numericRank a, numericRank b) of
                (Just rankA, Just rankB) ->
                    Just (rankType (max rankA rankB))

                (Just 2, _) -> Just RealType
                (_, Just 2) -> Just RealType

                _ -> Nothing

    numericRank :: Type -> Maybe Int
    numericRank IntegerType = Just 0
    numericRank RationalType = Just 1
    numericRank RealType = Just 2
    numericRank _ = Nothing

    rankType :: Int -> Type
    rankType 0 = IntegerType
    rankType 1 = RationalType
    rankType _ = RealType

    -- Bind an expression's result type to its resolved promotion type.
    bindResult
        :: TypeSubstitution
        -> Type
        -> Type
        -> Either PromotionError TypeSubstitution

    bindResult subst result target =
        let resolvedResult = applyTypeSubstitution subst result
            resolvedTarget = applyTypeSubstitution subst target
        in
            case resolvedResult of
                TypeVariable variable
                    | resolvedResult == resolvedTarget ->
                        Right subst

                    | occursIn variable resolvedTarget ->
                        Left (PromotionOccursCheck variable resolvedTarget)

                    | otherwise ->
                        Right (Map.insert variable resolvedTarget subst)

                _ ->
                    if resolvedResult == resolvedTarget
                    then Right subst
                    else Left
                        (ConflictingPromotionResult
                            resolvedResult resolvedTarget)

    occursIn :: Int -> Type -> Bool
    occursIn variable typ =
        case typ of
            TypeVariable other -> variable == other
            FunctionType arguments result ->
                any (occursIn variable) arguments
                    || occursIn variable result
            _ -> False
