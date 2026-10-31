
module PropositionInference
    ( PropositionResult(..)
    , PropositionError(..)
    , inferProposition
    , inferPropositionFrom
    , inferPropositionWithCounter
    ) where

import SMIR
import TypeSystem
import TypeInference
import ExpressionInference

data PropositionResult = PropositionResult
    { propositionType :: Type
    , propositionConstraints :: [TypeConstraint]
    , propositionPromotions :: [PromotionConstraint]
    }
    deriving (Show, Eq)

data PropositionError
    = PropositionExpressionError ExpressionError
    | InvalidComparisonOperands Type Type
    deriving (Show, Eq)

type PropositionInferResult = (Int, PropositionResult)

inferProposition
    :: SymbolTypes
    -> FunctionRegistry
    -> Proposition
    -> Either PropositionError PropositionResult

inferProposition = inferPropositionFrom 1000000

inferPropositionFrom
    :: Int
    -> SymbolTypes
    -> FunctionRegistry
    -> Proposition
    -> Either PropositionError PropositionResult

inferPropositionFrom firstFreshTypeVariable symbolTypes functions proposition = do
    (_, result) <-
        inferPropositionWithCounter
            firstFreshTypeVariable
            symbolTypes
            functions
            proposition

    Right result

-- Infer a proposition while preserving the fresh-variable counter.
inferPropositionWithCounter
    :: Int
    -> SymbolTypes
    -> FunctionRegistry
    -> Proposition
    -> Either PropositionError (Int, PropositionResult)

inferPropositionWithCounter firstFreshTypeVariable symbolTypes functions proposition =
    infer firstFreshTypeVariable proposition

  where

    infer :: Int -> Proposition -> Either PropositionError PropositionInferResult

    infer next (BooleanConstant _) =
        Right (next, PropositionResult BooleanType [] [])

    infer next (Compare relation) =
        inferComparison next relation

    infer next (And left right) =
        inferLogical next left right

    infer next (Or left right) =
        inferLogical next left right

    infer next (Not proposition) = do
        (next1, result) <- infer next proposition

        Right (next1, PropositionResult
            { propositionType = BooleanType
            , propositionConstraints = propositionConstraints result
            , propositionPromotions = propositionPromotions result
            })

    inferLogical
        :: Int
        -> Proposition
        -> Proposition
        -> Either PropositionError PropositionInferResult

    inferLogical next left right = do
        (next1, leftResult) <- infer next left
        (next2, rightResult) <- infer next1 right

        Right (next2, PropositionResult
            { propositionType = BooleanType
            , propositionConstraints =
                propositionConstraints leftResult
                ++ propositionConstraints rightResult
            , propositionPromotions =
                propositionPromotions leftResult
                ++ propositionPromotions rightResult
            })

    inferComparison
        :: Int
        -> Relation
        -> Either PropositionError PropositionInferResult

    inferComparison next relation = do
        let (left, right) = relationOperands relation

        (next1, leftResult) <-
            either
                (Left . PropositionExpressionError)
                Right
                (inferExpressionWithCounter
                    next symbolTypes functions left)

        (next2, rightResult) <-
            either
                (Left . PropositionExpressionError)
                Right
                (inferExpressionWithCounter
                    next1 symbolTypes functions right)

        let leftType = expressionType leftResult
            rightType = expressionType rightResult

        if not (isPotentiallyNumeric leftType)
            || not (isPotentiallyNumeric rightType)
            then Left (InvalidComparisonOperands leftType rightType)
            else Right (next2, PropositionResult
                { propositionType = BooleanType
                , propositionConstraints =
                    typeConstraints leftResult
                    ++ typeConstraints rightResult
                    ++ [RequiresNumeric leftType, RequiresNumeric rightType]
                , propositionPromotions =
                    pendingPromotions leftResult
                    ++ pendingPromotions rightResult
                })

    relationOperands :: Relation -> (Expr, Expr)

    relationOperands (Equal a b) = (a, b)
    relationOperands (NotEqual a b) = (a, b)
    relationOperands (LessThan a b) = (a, b)
    relationOperands (GreaterThan a b) = (a, b)
    relationOperands (LessEqual a b) = (a, b)
    relationOperands (GreaterEqual a b) = (a, b)

    isPotentiallyNumeric :: Type -> Bool

    isPotentiallyNumeric IntegerType = True
    isPotentiallyNumeric RationalType = True
    isPotentiallyNumeric RealType = True
    isPotentiallyNumeric (TypeVariable _) = True
    isPotentiallyNumeric _ = False
