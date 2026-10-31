module Parser where

import Syntax
import Text.ParserCombinators.ReadP
import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace)

spaces :: ReadP ()
spaces = skipMany (satisfy isSpace)

keyword :: String -> ReadP ()
keyword word = do
    _ <- string word
    spaces

identifier :: ReadP String
identifier = do
    first <- satisfy isAlpha
    rest <- munch (\c -> isAlphaNum c || c == '_')
    spaces
    return (first : rest)

number :: ReadP Integer
number = do
    digits <- munch1 isDigit
    spaces
    return (read digits)

expression :: ReadP Expression
expression =
        (Number <$> number)
    <++ (VariableRef <$> identifier)

setInstruction :: ReadP Instruction
setInstruction = do
    keyword "Set"
    variable <- identifier
    keyword "to"
    value <- expression
    optional (char '.')
    return (Assign variable value)

addInstruction :: ReadP Instruction
addInstruction = do
    keyword "Add"
    left <- expression
    keyword "and"
    right <- expression
    optional (char '.')
    return (Print (Add left right))

multiplyInstruction :: ReadP Instruction
multiplyInstruction = do
    keyword "Multiply"
    left <- expression
    keyword "by"
    right <- expression
    optional (char '.')
    return (Print (Multiply left right))

subtractInstruction :: ReadP Instruction
subtractInstruction = do
    keyword "Subtract"
    left <- expression
    keyword "from"
    right <- expression
    optional (char '.')
    return (Print (Subtract right left))

parseInstruction :: String -> Either String Instruction
parseInstruction input =
    case [result | (result, rest) <- readP_to_S (spaces *> (setInstruction <++ addInstruction <++ multiplyInstruction <++ subtractInstruction) <* spaces <* eof) input] of
        [] -> Left "Could not parse instruction."
        results -> Right (last results)

parseProgram :: String -> Either String Program
parseProgram input =
    mapM parseLine nonEmptyLines
    where
        numberedLines =
            zip [1..] (lines input)

        nonEmptyLines =
            filter (not . all isSpace . snd) numberedLines

        parseLine (lineNumber, line) =
            case parseInstruction line of
                Left err ->
                    Left ("Line " ++ show lineNumber ++ ": " ++ err)

                Right instruction ->
                    Right instruction