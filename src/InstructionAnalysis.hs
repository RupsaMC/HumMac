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


module InstructionAnalysis
    ( TypeEnvironment
    , InstructionResult(..)
    , InstructionError(..)
    , analyzeInstructions
    ) where

import Control.Monad (foldM)
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)

import SMIR
import TypeSystem
import TypeInference
import ExpressionInference
import PropositionInference
import PromotionResolution


type TypeEnvironment = Map SymbolId Type


applyConstraintSubstitution
    :: TypeSubstitution
    -> TypeConstraint
    -> TypeConstraint

applyConstraintSubstitution subst constraint =
    case constraint of
        TypesEqual first second ->
            TypesEqual
                (applyTypeSubstitution subst first)
                (applyTypeSubstitution subst second)

        RequiresNumeric typ ->
            RequiresNumeric (applyTypeSubstitution subst typ)

        RequiresBoolean typ ->
            RequiresBoolean (applyTypeSubstitution subst typ)

        RequiresInteger typ ->
            RequiresInteger (applyTypeSubstitution subst typ)


data InstructionResult = InstructionResult
    { finalTypeEnvironment :: TypeEnvironment
    , instructionSubstitution :: TypeSubstitution
    , instructionConstraints :: [TypeConstraint]
    , instructionPromotions :: [PromotionConstraint]
    , nextFreshTypeVariable :: Int
    }
    deriving (Show, Eq)


data InstructionError
    = InstructionExpressionError ExpressionError
    | InstructionPropositionError PropositionError
    | InstructionInferenceError InferenceError
    | InstructionPromotionError PromotionError
    | AssignmentTypeConflict SymbolId Type Type
    | ExpectedBooleanCondition Type
    | InvalidRepeatCount Type
    deriving (Show, Eq)


analyzeInstructions
    :: Int
    -> TypeEnvironment
    -> FunctionRegistry
    -> [Instruction]
    -> Either InstructionError InstructionResult

analyzeInstructions firstFreshTypeVariable initialEnvironment functions instructions = do

    (finalEnvironment, finalCounter, constraints, promotions) <-
        analyzeSequence firstFreshTypeVariable initialEnvironment instructions

    let implicitBindingConstraints =
            [ TypesEqual (implicitSymbolType symbol) typ
            | (symbol, typ) <- Map.toList finalEnvironment
            , Map.notMember symbol initialEnvironment
            ]

        allConstraints =
            constraints ++ implicitBindingConstraints

    initialSolution <-
        either (Left . InstructionInferenceError) Right
            (solveConstraints allConstraints)

    promotionSolution <-
        either (Left . InstructionPromotionError) Right
            (resolvePromotions (substitution initialSolution) promotions)

    let afterPromotion =
            Map.union
                (resolvedSubstitution promotionSolution)
                (substitution initialSolution)

        constraintsAfterPromotion =
            map (applyConstraintSubstitution afterPromotion) allConstraints

    finalCheck <-
        either (Left . InstructionInferenceError) Right
            (solveConstraints constraintsAfterPromotion)

    let finalSubstitution =
            Map.union
                (substitution finalCheck)
                afterPromotion

        resolvedEnvironment =
            Map.map
                (applyTypeSubstitution finalSubstitution)
                finalEnvironment

    Right InstructionResult
        { finalTypeEnvironment = resolvedEnvironment
        , instructionSubstitution = finalSubstitution
        , instructionConstraints = unresolvedConstraints finalCheck
        , instructionPromotions = unresolvedPromotions promotionSolution
        , nextFreshTypeVariable = finalCounter
        }

  where

    analyzeSequence counter environment [] =
        Right (environment, counter, [], [])

    analyzeSequence counter environment (instruction:rest) = do

        (updatedEnvironment, nextCounter, constraints1, promotions1) <-
            analyzeInstruction counter environment instruction

        (finalEnvironment, finalCounter, constraints2, promotions2) <-
            analyzeSequence nextCounter updatedEnvironment rest

        Right
            ( finalEnvironment
            , finalCounter
            , constraints1 ++ constraints2
            , promotions1 ++ promotions2
            )


    analyzeInstruction counter environment instruction =
        case instruction of

            Assign symbol value ->
                analyzeAssignment counter environment symbol value

            Evaluate expression ->
                analyzeEvaluation counter environment expression

            Check proposition ->
                analyzeCheck counter environment proposition

            If condition thenBranch elseBranch ->
                analyzeConditional
                    counter environment condition thenBranch elseBranch

            Repeat count body ->
                analyzeRepeat counter environment count body


    analyzeAssignment counter environment symbol value =
        case value of

            NumericValue expression -> do

                (nextCounter, result) <-
                    either (Left . InstructionExpressionError) Right
                        (inferExpressionWithCounter
                            counter environment functions expression)

                let assignedType = expressionType result

                (updatedType, assignmentConstraints) <-
                    reconcileAssignmentType symbol environment assignedType

                Right
                    ( Map.insert symbol updatedType environment
                    , nextCounter
                    , typeConstraints result ++ assignmentConstraints
                    , pendingPromotions result
                    )

            BooleanValue proposition -> do

                (nextCounter, result) <-
                    either (Left . InstructionPropositionError) Right
                        (inferPropositionWithCounter
                            counter environment functions proposition)

                let assignedType = propositionType result

                (updatedType, assignmentConstraints) <-
                    reconcileAssignmentType symbol environment assignedType

                Right
                    ( Map.insert symbol updatedType environment
                    , nextCounter
                    , propositionConstraints result ++ assignmentConstraints
                    , propositionPromotions result
                    )


    analyzeEvaluation counter environment expression = do

        (nextCounter, result) <-
            either (Left . InstructionExpressionError) Right
                (inferExpressionWithCounter
                    counter environment functions expression)

        Right
            ( environment
            , nextCounter
            , typeConstraints result
            , pendingPromotions result
            )


    analyzeCheck counter environment proposition = do

        (nextCounter, result) <-
            either (Left . InstructionPropositionError) Right
                (inferPropositionWithCounter
                    counter environment functions proposition)

        Right
            ( environment
            , nextCounter
            , propositionConstraints result
            , propositionPromotions result
            )


    analyzeConditional counter environment condition thenBranch elseBranch = do

        (counter1, conditionResult) <-
            either (Left . InstructionPropositionError) Right
                (inferPropositionWithCounter
                    counter environment functions condition)

        (thenEnvironment, counter2, thenConstraints, thenPromotions) <-
            analyzeSequence counter1 environment thenBranch

        (elseEnvironment, counter3, elseConstraints, elsePromotions) <-
            analyzeSequence counter2 environment elseBranch

        (mergedEnvironment, mergeConstraints) <-
            mergeBranchEnvironments thenEnvironment elseEnvironment

        Right
            ( mergedEnvironment
            , counter3
            , propositionConstraints conditionResult
                ++ thenConstraints
                ++ elseConstraints
                ++ mergeConstraints
            , propositionPromotions conditionResult
                ++ thenPromotions
                ++ elsePromotions
            )


    analyzeRepeat counter environment count body = do

        (counter1, countResult) <-
            either (Left . InstructionExpressionError) Right
                (inferExpressionWithCounter
                    counter environment functions count)

        let countType = expressionType countResult

        case countType of
            IntegerType -> Right ()
            TypeVariable _ -> Right ()
            _ -> Left (InvalidRepeatCount countType)

        (bodyEnvironment, counter2, bodyConstraints, bodyPromotions) <-
            analyzeSequence counter1 environment body

        Right
            ( bodyEnvironment
            , counter2
            , typeConstraints countResult
                ++ [RequiresInteger countType]
                ++ bodyConstraints
            , pendingPromotions countResult ++ bodyPromotions
            )


    -- Reconcile a new assignment with the symbol's existing type.
    --
    -- For a previously unseen symbol, its implicit type binding is
    -- deliberately deferred until the complete instruction sequence
    -- has been analysed.
    --
    -- This allows conditional branches to infer their types separately.
    -- The merged environment determines the final type, which is then
    -- connected to the symbol's implicit type variable.
    --
    -- Numeric assignments widen the stored type.
    -- Incompatible concrete types are rejected.

    reconcileAssignmentType symbol environment newType =
        case Map.lookup symbol environment of

            Nothing ->
                Right (newType, [])

            Just oldType ->
                reconcileTypes symbol oldType newType


    implicitSymbolType (SymbolId identifier) =
        TypeVariable (negate (identifier + 1))


    reconcileTypes symbol oldType newType =
        case (oldType, newType) of

            (TypeVariable _, _) ->
                Right
                    ( oldType
                    , [TypesEqual oldType newType]
                    )

            (_, TypeVariable _) ->
                Right
                    ( oldType
                    , [TypesEqual oldType newType]
                    )

            (a, b)
                | a == b ->
                    Right (a, [])

            (a, b)
                | isNumericType a && isNumericType b ->
                    Right (widerNumericType a b, [])

            _ ->
                Left (AssignmentTypeConflict symbol oldType newType)


    widerNumericType first second =
        case (first, second) of

            (RealType, _) -> RealType
            (_, RealType) -> RealType

            (RationalType, _) -> RationalType
            (_, RationalType) -> RationalType

            _ -> IntegerType


    -- Merge the types visible after the two conditional branches.
    -- Numeric types are widened to their common wider type.
    -- Definite initialization is handled separately.

    mergeBranchEnvironments first second =
        foldM mergeOne (Map.empty, []) allSymbols

      where

        allSymbols =
            Map.keys (Map.union first second)

        mergeOne (merged, constraints) symbol =
            case (Map.lookup symbol first, Map.lookup symbol second) of

                (Just firstType, Just secondType) -> do

                    (mergedType, newConstraints) <-
                        reconcileTypes symbol firstType secondType

                    Right
                        ( Map.insert symbol mergedType merged
                        , constraints ++ newConstraints
                        )

                (Just typ, Nothing) ->
                    Right (Map.insert symbol typ merged, constraints)

                (Nothing, Just typ) ->
                    Right (Map.insert symbol typ merged, constraints)

                (Nothing, Nothing) ->
                    Right (merged, constraints)
