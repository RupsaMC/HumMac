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


module SemanticAnalysis
    ( SemanticResult(..)
    , PropositionSemanticResult(..)
    , SemanticError(..)
    , analyzeExpression
    , analyzeProposition
    ) where

import qualified Data.Map.Strict as Map

import SMIR
import TypeSystem
import TypeInference
import ExpressionInference
import PropositionInference
import PromotionResolution

-- The complete result of analysing a numeric expression.
data SemanticResult = SemanticResult
    { finalExpressionType :: Type
    , finalTypeSubstitution :: TypeSubstitution
    , remainingTypeConstraints :: [TypeConstraint]
    , remainingPromotions :: [PromotionConstraint]
    }
    deriving (Show, Eq)

-- The complete result of analysing a Boolean proposition.
data PropositionSemanticResult = PropositionSemanticResult
    { finalPropositionType :: Type
    , propositionTypeSubstitution :: TypeSubstitution
    , remainingPropositionConstraints :: [TypeConstraint]
    , remainingPropositionPromotions :: [PromotionConstraint]
    }
    deriving (Show, Eq)

-- Errors produced by semantic analysis.
data SemanticError
    = ExpressionInferenceFailure ExpressionError
    | PropositionInferenceFailure PropositionError
    | ConstraintSolvingFailure InferenceError
    | PromotionResolutionFailure PromotionError
    deriving (Show, Eq)

-- Analyse a numeric expression.
analyzeExpression
    :: SymbolTypes
    -> FunctionRegistry
    -> Expr
    -> Either SemanticError SemanticResult

analyzeExpression symbolTypes functions expression = do

    inferred <-
        either
            (Left . ExpressionInferenceFailure)
            Right
            (inferExpression symbolTypes functions expression)

    (finalType, finalSubst, constraints, promotions) <-
        analyzeComponents
            (expressionType inferred)
            (typeConstraints inferred)
            (pendingPromotions inferred)

    Right SemanticResult
        { finalExpressionType = finalType
        , finalTypeSubstitution = finalSubst
        , remainingTypeConstraints = constraints
        , remainingPromotions = promotions
        }

-- Analyse a Boolean proposition.
analyzeProposition
    :: SymbolTypes
    -> FunctionRegistry
    -> Proposition
    -> Either SemanticError PropositionSemanticResult

analyzeProposition symbolTypes functions proposition = do

    inferred <-
        either
            (Left . PropositionInferenceFailure)
            Right
            (inferProposition symbolTypes functions proposition)

    (finalType, finalSubst, constraints, promotions) <-
        analyzeComponents
            (propositionType inferred)
            (propositionConstraints inferred)
            (propositionPromotions inferred)

    Right PropositionSemanticResult
        { finalPropositionType = finalType
        , propositionTypeSubstitution = finalSubst
        , remainingPropositionConstraints = constraints
        , remainingPropositionPromotions = promotions
        }

-- Shared semantic-analysis pipeline.
analyzeComponents
    :: Type
    -> [TypeConstraint]
    -> [PromotionConstraint]
    -> Either SemanticError
        (Type, TypeSubstitution, [TypeConstraint], [PromotionConstraint])

analyzeComponents originalType constraints promotions = do

    -- Stage 1: Solve type equalities and validate known constraints.
    initialSolution <-
        either
            (Left . ConstraintSolvingFailure)
            Right
            (solveConstraints constraints)

    let initialSubstitution = substitution initialSolution

    -- Stage 2: Resolve numeric promotion relationships.
    promotionSolution <-
        either
            (Left . PromotionResolutionFailure)
            Right
            (resolvePromotions
                initialSubstitution
                promotions)

    let promotionSubstitution =
            resolvedSubstitution promotionSolution

    -- Stage 3: Apply resolved types to the original constraints.
    let updatedConstraints =
            map
                (applyConstraintSubstitution promotionSubstitution)
                constraints

    -- Stage 4: Validate constraints again after promotion resolution.
    finalCheck <-
        either
            (Left . ConstraintSolvingFailure)
            Right
            (solveConstraints updatedConstraints)

    let finalSubstitution =
            composeSubstitutions
                (substitution finalCheck)
                promotionSubstitution

    Right
        ( applyTypeSubstitution finalSubstitution originalType
        , finalSubstitution
        , unresolvedConstraints finalCheck
        , unresolvedPromotions promotionSolution
        )

-- Compose two type substitutions.
composeSubstitutions
    :: TypeSubstitution
    -> TypeSubstitution
    -> TypeSubstitution

composeSubstitutions later earlier =
    Map.union
        later
        (Map.map (applyTypeSubstitution later) earlier)

-- Apply a type substitution to an individual constraint.
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
            RequiresNumeric
                (applyTypeSubstitution subst typ)

        RequiresBoolean typ ->
            RequiresBoolean
                (applyTypeSubstitution subst typ)
