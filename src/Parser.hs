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

repeatHeader :: ReadP Integer
repeatHeader = do
    keyword "Repeat"
    count <- number
    keyword "times"
    optional (char '.')
    spaces
    return count

endRepeat :: ReadP ()
endRepeat = do
    keyword "End"
    keyword "repeat"
    optional (char '.')
    spaces

parseComplete :: ReadP a -> String -> Maybe a
parseComplete parser input =
    case [result | (result, rest) <- readP_to_S (spaces *> parser <* spaces <* eof) input] of
        [] -> Nothing
        results -> Just (last results)

parseInstruction :: String -> Either String Instruction
parseInstruction input =
    case parseComplete
        (setInstruction <++ addInstruction <++ multiplyInstruction <++ subtractInstruction)
        input of
            Nothing -> Left "Could not parse instruction."
            Just instruction -> Right instruction

parseRepeatHeader :: String -> Maybe Integer
parseRepeatHeader = parseComplete repeatHeader

isNegativeRepeatHeader :: String -> Bool
isNegativeRepeatHeader line =
    case words line of
        ["Repeat", negativeCount, "times"] ->
            isNegativeInteger negativeCount

        ["Repeat", negativeCount, "times."] ->
            isNegativeInteger negativeCount

        _ -> False

isNegativeInteger :: String -> Bool
isNegativeInteger token =
    case token of
        '-':digits ->
            not (null digits) && all isDigit digits

        _ -> False

isEndRepeat :: String -> Bool
isEndRepeat line =
    case parseComplete endRepeat line of
        Just () -> True
        Nothing -> False

parseSequence :: [(Int, String)] -> Either String ([Instruction], [(Int, String)])
parseSequence = go []
    where
        go accumulated [] =
            Right (reverse accumulated, [])

        go accumulated remaining@((lineNumber, line):rest)
            | isEndRepeat line =
                Right (reverse accumulated, remaining)

            | Just count <- parseRepeatHeader line = do
                (body, afterBody) <- parseSequence rest

                case afterBody of
                    (_, endLine):afterEnd
                        | isEndRepeat endLine ->
                            go (Repeat count body : accumulated) afterEnd

                    [] ->
                        Left ("Line " ++ show lineNumber
                            ++ ": Repeat block is missing 'End repeat.'")

                    _ ->
                        Left ("Line " ++ show lineNumber
                            ++ ": Invalid repeat block.")

            | isNegativeRepeatHeader line =
                Left ("Line " ++ show lineNumber
                    ++ ": Repeat count must be a non-negative integer.")

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

        (lineNumber, _):_ ->
            Left ("Line " ++ show lineNumber
                ++ ": Unexpected 'End repeat.'")
