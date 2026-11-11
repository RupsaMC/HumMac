-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- https://www.apache.org/licenses/LICENSE-2.0

module Parser where

import Syntax
import Text.ParserCombinators.ReadP
import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace)
import Data.Ratio ((%))

spaces :: ReadP ()
spaces = skipMany (satisfy isSpace)

keyword :: String -> ReadP ()
keyword word = do
    _ <- string word
    spaces

symbol :: String -> ReadP String
symbol value = do
    result <- string value
    spaces
    return result

identifier :: ReadP String
identifier = do
    first <- satisfy isAlpha
    rest <- munch (\c -> isAlphaNum c || c == '_')
    spaces
    return (first : rest)

reservedWords :: [String]
reservedWords =
    [ "Set", "Add", "Multiply", "Subtract"
    , "Repeat", "End", "repeat"
    , "If", "Otherwise", "if"
    , "is", "equal", "not", "less", "greater", "than", "or"
    , "to", "and", "by", "from", "times"
    ]

expressionIdentifier :: ReadP String
expressionIdentifier = do
    name <- identifier
    if name `elem` reservedWords
        then pfail
        else return name

number :: ReadP Integer
number = do
    digits <- munch1 isDigit
    spaces
    return (read digits)

decimalNumber :: ReadP Expression
decimalNumber = do
    whole <- munch1 isDigit
    _ <- char '.'
    fractional <- munch1 isDigit
    spaces

    let numerator =
            read whole * (10 ^ length fractional)
            + read fractional

        denominator = 10 ^ length fractional

    return (Decimal (numerator % denominator))

primary :: ReadP Expression
primary =
        decimalNumber
    <++ (Number <$> number)
    <++ between
            (symbol "(")
            (symbol ")")
            expression
    <++ (VariableRef <$> expressionIdentifier)

unary :: ReadP Expression
unary =
        (do
            _ <- symbol "-"
            Negate <$> unary
        )
    <++ power

power :: ReadP Expression
power = do
    base <- primary

    (do
        _ <- symbol "^"
        powerExpression <- unary
        return (Power base powerExpression)
        )
        <++ return base

startsImplicitFactor :: String -> Bool
startsImplicitFactor remaining =
    case remaining of
        '(' : _ ->
            True

        first : _
            | isAlpha first ->
                let name = takeWhile
                        (\c -> isAlphaNum c || c == '_')
                        remaining
                in name `notElem` reservedWords

        _ ->
            False

implicitMultiply :: ReadP (Expression -> Expression -> Expression)
implicitMultiply = do
    remaining <- look

    if startsImplicitFactor remaining
        then return Multiply
        else pfail

multiplicativeOperator
    :: ReadP (Expression -> Expression -> Expression)
multiplicativeOperator =
        (symbol "*" >> return Multiply)
    <++ (symbol "/" >> return Divide)
    <++ implicitMultiply

additiveOperator
    :: ReadP (Expression -> Expression -> Expression)
additiveOperator =
        (symbol "+" >> return Add)
    <++ (symbol "-" >> return Subtract)

expression :: ReadP Expression
expression =
    chainl1
        (chainl1 unary multiplicativeOperator)
        additiveOperator

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

repeatHeader :: ReadP Integer
repeatHeader = do
    keyword "Repeat"
    repeatCount <- number
    keyword "times"
    optional (char '.')
    spaces
    return repeatCount

endRepeat :: ReadP ()
endRepeat = do
    keyword "End"
    keyword "repeat"
    optional (char '.')
    spaces

endIf :: ReadP ()
endIf = do
    keyword "End"
    keyword "if"
    optional (char '.')
    spaces

otherwiseHeader :: ReadP ()
otherwiseHeader = do
    keyword "Otherwise"
    optional (char '.')
    spaces

comparisonOperator :: ReadP ComparisonOperator
comparisonOperator =
        (do
            keyword "less"
            keyword "than"
            keyword "or"
            keyword "equal"
            keyword "to"
            return LessThanOrEqualTo
        )
    <++ (do
            keyword "greater"
            keyword "than"
            keyword "or"
            keyword "equal"
            keyword "to"
            return GreaterThanOrEqualTo
        )
    <++ (do
            keyword "not"
            keyword "equal"
            keyword "to"
            return NotEqualTo
        )
    <++ (keyword "equal" >> keyword "to" >> return EqualTo)
    <++ (keyword "less" >> keyword "than" >> return LessThan)
    <++ (keyword "greater" >> keyword "than" >> return GreaterThan)

ifHeader :: ReadP Proposition
ifHeader = do
    keyword "If"
    left <- expression
    keyword "is"
    operator <- comparisonOperator
    right <- expression
    optional (char '.')
    spaces
    return (Compare operator left right)

parseComplete :: ReadP a -> String -> Maybe a
parseComplete parser input =
    case
        [ result
        | (result, _) <-
            readP_to_S (spaces *> parser <* spaces <* eof) input
        ] of
            [] ->
                Nothing

            results ->
                Just (last results)

parseInstruction :: String -> Either String Instruction
parseInstruction input =
    case parseComplete
        ( setInstruction
        <++ addInstruction
        <++ multiplyInstruction
        <++ subtractInstruction
        )
        input of

            Nothing ->
                Left "Could not parse instruction."

            Just instruction ->
                Right instruction

parseRepeatHeader :: String -> Maybe Integer
parseRepeatHeader = parseComplete repeatHeader

isNegativeRepeatHeader :: String -> Bool
isNegativeRepeatHeader line =
    case words line of
        ["Repeat", negativeCount, "times"] ->
            isNegativeInteger negativeCount

        ["Repeat", negativeCount, "times."] ->
            isNegativeInteger negativeCount

        _ ->
            False

isNegativeInteger :: String -> Bool
isNegativeInteger token =
    case token of
        '-':digits ->
            not (null digits) && all isDigit digits

        _ ->
            False

isDecimalRepeatHeader :: String -> Bool
isDecimalRepeatHeader line =
    case words line of
        ["Repeat", repeatCount, "times"] ->
            isDecimalNumber repeatCount

        ["Repeat", repeatCount, "times."] ->
            isDecimalNumber repeatCount

        _ ->
            False

isDecimalNumber :: String -> Bool
isDecimalNumber token =
    let unsigned =
            case token of
                '-':rest -> rest
                '+':rest -> rest
                _ -> token
    in case break (== '.') unsigned of
        (whole, '.':fraction) ->
            not (null whole)
                && not (null fraction)
                && all isDigit whole
                && all isDigit fraction

        _ ->
            False

isEndRepeat :: String -> Bool
isEndRepeat line =
    case parseComplete endRepeat line of
        Just () -> True
        Nothing -> False

isEndIf :: String -> Bool
isEndIf line =
    case parseComplete endIf line of
        Just () -> True
        Nothing -> False

isOtherwise :: String -> Bool
isOtherwise line =
    case parseComplete otherwiseHeader line of
        Just () -> True
        Nothing -> False

isBlockTerminator :: String -> Bool
isBlockTerminator line =
    isEndRepeat line || isEndIf line || isOtherwise line

parseIfHeader :: String -> Maybe Proposition
parseIfHeader = parseComplete ifHeader

parseSequence
    :: [(Int, String)]
    -> Either String ([Instruction], [(Int, String)])
parseSequence = go []
    where
        go accumulated [] =
            Right (reverse accumulated, [])

        go accumulated remaining@((lineNumber, line):rest)
            | isBlockTerminator line =
                Right (reverse accumulated, remaining)

            | Just repeatCount <- parseRepeatHeader line = do
                (body, afterBody) <- parseSequence rest

                case afterBody of
                    (_, endLine):afterEnd
                        | isEndRepeat endLine ->
                            go
                                (Repeat repeatCount body : accumulated)
                                afterEnd

                        | otherwise ->
                            Left
                                ("Line " ++ show lineNumber
                                    ++ ": Repeat block must end with 'End repeat.'")

                    [] ->
                        Left
                            ("Line " ++ show lineNumber
                                ++ ": Repeat block is missing 'End repeat.'")

            | Just proposition <- parseIfHeader line = do
                (thenBody, afterThen) <- parseSequence rest

                case afterThen of
                    (_, markerLine):afterMarker
                        | isOtherwise markerLine -> do
                            (elseBody, afterElse) <-
                                parseSequence afterMarker

                            case afterElse of
                                (_, endLine):afterEnd
                                    | isEndIf endLine ->
                                        go
                                            (If proposition thenBody elseBody
                                                : accumulated)
                                            afterEnd

                                [] ->
                                    Left
                                        ("Line " ++ show lineNumber
                                            ++ ": If block is missing 'End if.'")

                                (endLineNumber, _):_ ->
                                    Left
                                        ("Line " ++ show endLineNumber
                                            ++ ": Expected 'End if.' after Otherwise branch.")

                        | isEndIf markerLine ->
                            go
                                (If proposition thenBody [] : accumulated)
                                afterMarker

                        | otherwise ->
                            Left
                                ("Line " ++ show lineNumber
                                    ++ ": Invalid If block terminator.")

                    [] ->
                        Left
                            ("Line " ++ show lineNumber
                                ++ ": If block is missing 'End if.'")

            | isNegativeRepeatHeader line
                || isDecimalRepeatHeader line =
                Left
                    ("Line " ++ show lineNumber
                        ++ ": Repeat count must be a non-negative integer.")

            | isEndRepeat line || isEndIf line || isOtherwise line =
                Right (reverse accumulated, remaining)

            | otherwise =
                case parseInstruction line of
                    Left err ->
                        Left ("Line " ++ show lineNumber ++ ": " ++ err)

                    Right instruction ->
                        go (instruction : accumulated) rest

parseProgram :: String -> Either String Program
parseProgram input = do
    let numberedLines = zip [1..] (lines input)

        nonEmptyLines =
            filter (not . all isSpace . snd) numberedLines

    (program, remaining) <- parseSequence nonEmptyLines

    case remaining of
        [] ->
            Right program

        (lineNumber, line):_ ->
            let description
                    | isEndRepeat line = "End repeat."
                    | isEndIf line = "End if."
                    | otherwise = "Otherwise."
            in Left
                ("Line " ++ show lineNumber
                    ++ ": Unexpected '" ++ description ++ "'")
