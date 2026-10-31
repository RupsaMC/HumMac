
module TypeChecker where

import Syntax

validateExpression :: [Variable] -> Expression -> Either String ()

validateExpression _ (Number _) =
    Right ()

validateExpression defined (VariableRef name)
    | name `elem` defined = Right ()
    | otherwise = Left ("Undefined variable: " ++ name)

validateExpression defined (Add left right) = do
    validateExpression defined left
    validateExpression defined right

validateExpression defined (Subtract left right) = do
    validateExpression defined left
    validateExpression defined right

validateExpression defined (Multiply left right) = do
    validateExpression defined left
    validateExpression defined right

validateExpression defined (Divide left right) = do
    validateExpression defined left
    validateExpression defined right

validateProgram :: Program -> Either String ()
validateProgram = go []
    where
        go _ [] = Right ()

        go defined (instruction:rest) =
            case instruction of
                Assign name expression -> do
                    validateExpression defined expression
                    go (name : defined) rest

                Print expression -> do
                    validateExpression defined expression
                    go defined rest

                Repeat _ body -> do
                    validateProgramWith defined body
                    go defined rest

        validateProgramWith defined body =
            go defined body
