
module TypeInference
    ( TypeConstraint(..)
    , TypeSubstitution
    , InferenceError(..)
    , InferenceResult(..)
    , applyTypeSubstitution
    , solveConstraints
    ) where

import Control.Monad (foldM)
import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)

import TypeSystem (Type(..))


data TypeConstraint
    = TypesEqual Type Type
    | RequiresNumeric Type
    | RequiresBoolean Type
    | RequiresInteger Type
    deriving (Show, Eq)


type TypeSubstitution = Map Int Type


data InferenceError
    = CannotUnify Type Type
    | InfiniteType Int Type
    | TypeConstraintViolation String Type
    deriving (Show, Eq)


data InferenceResult = InferenceResult
    { substitution :: TypeSubstitution
    , unresolvedConstraints :: [TypeConstraint]
    }
    deriving (Show, Eq)


applyTypeSubstitution :: TypeSubstitution -> Type -> Type
applyTypeSubstitution subst typ =
    case typ of
        TypeVariable v ->
            case Map.lookup v subst of
                Just replacement ->
                    applyTypeSubstitution subst replacement
                Nothing -> typ

        FunctionType arguments result ->
            FunctionType
                (map (applyTypeSubstitution subst) arguments)
                (applyTypeSubstitution subst result)

        _ -> typ


occursIn :: Int -> Type -> Bool
occursIn variable typ =
    case typ of
        TypeVariable v ->
            variable == v

        FunctionType arguments result ->
            any (occursIn variable) arguments
                || occursIn variable result

        _ -> False


bindVariable
    :: TypeSubstitution
    -> Int
    -> Type
    -> Either InferenceError TypeSubstitution

bindVariable subst variable typ =
    let resolved = applyTypeSubstitution subst typ
    in case resolved of
        TypeVariable v | v == variable ->
            Right subst

        _ | occursIn variable resolved ->
              Left (InfiniteType variable resolved)

          | otherwise ->
              Right (Map.insert variable resolved subst)


unify
    :: TypeSubstitution
    -> Type
    -> Type
    -> Either InferenceError TypeSubstitution

unify subst first second =
    let a = applyTypeSubstitution subst first
        b = applyTypeSubstitution subst second
    in case (a, b) of

        (TypeVariable v, typ) ->
            bindVariable subst v typ

        (typ, TypeVariable v) ->
            bindVariable subst v typ

        (FunctionType args1 result1, FunctionType args2 result2)
            | length args1 == length args2 -> do
                updated <- foldM
                    (\current (x, y) -> unify current x y)
                    subst
                    (zip args1 args2)

                unify updated result1 result2

        _ | a == b ->
              Right subst

          | otherwise ->
              Left (CannotUnify a b)


checkNumeric
    :: TypeSubstitution
    -> Type
    -> Either InferenceError [TypeConstraint]

checkNumeric subst typ =
    let resolved = applyTypeSubstitution subst typ
    in case resolved of

        IntegerType ->
            Right []

        RationalType ->
            Right []

        RealType ->
            Right []

        TypeVariable _ ->
            Right [RequiresNumeric resolved]

        _ ->
            Left
                (TypeConstraintViolation
                    "Expected a numeric type"
                    resolved)


checkBoolean
    :: TypeSubstitution
    -> Type
    -> Either InferenceError [TypeConstraint]

checkBoolean subst typ =
    let resolved = applyTypeSubstitution subst typ
    in case resolved of

        BooleanType ->
            Right []

        TypeVariable _ ->
            Right [RequiresBoolean resolved]

        _ ->
            Left
                (TypeConstraintViolation
                    "Expected a Boolean type"
                    resolved)


checkInteger
    :: TypeSubstitution
    -> Type
    -> Either InferenceError [TypeConstraint]

checkInteger subst typ =
    let resolved = applyTypeSubstitution subst typ
    in case resolved of

        IntegerType ->
            Right []

        TypeVariable _ ->
            Right [RequiresInteger resolved]

        _ ->
            Left
                (TypeConstraintViolation
                    "Expected an Integer type"
                    resolved)


solveConstraints
    :: [TypeConstraint]
    -> Either InferenceError InferenceResult

solveConstraints constraints = do

    let equalities =
            [(a, b) | TypesEqual a b <- constraints]

        predicates =
            [ constraint
            | constraint <- constraints
            , case constraint of
                TypesEqual _ _ -> False
                _ -> True
            ]

    subst <- foldM
        (\current (a, b) -> unify current a b)
        Map.empty
        equalities

    unresolved <- fmap concat $
        mapM
            (\constraint ->
                case constraint of

                    RequiresNumeric typ ->
                        checkNumeric subst typ

                    RequiresBoolean typ ->
                        checkBoolean subst typ

                    RequiresInteger typ ->
                        checkInteger subst typ

                    TypesEqual _ _ ->
                        Right []
            )
            predicates

    Right InferenceResult
        { substitution = subst
        , unresolvedConstraints = unresolved
        }
