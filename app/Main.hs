-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0
-- See the LICENSE file for details.

module Main where

import Control.Exception (IOException, evaluate, try)
import qualified Data.Map.Strict as Map
import System.Environment (getArgs)
import System.Exit (exitFailure)

import Compiler
import InstructionAnalysis
import SymbolTable (SymbolInfo(..), getSymbols)

main :: IO ()
main = do
    arguments <- getArgs

    filePath <-
        case arguments of
            [] -> pure "examples/arithmetic.eng"
            [path] -> pure path
            _ -> do
                putStrLn "Usage: hummac [source-file.eng]"
                exitFailure

    sourceResult <- readSource filePath

    case sourceResult of
        Left err -> do
            putStrLn "Could not read source file."
            putStrLn (show err)
            exitFailure

        Right source ->
            case compileSource source of
                Left (ParsingFailed err) -> do
                    putStrLn "Compilation failed during parsing."
                    putStrLn err
                    exitFailure

                Left (SemanticAnalysisFailed err) -> do
                    putStrLn "Compilation failed during semantic analysis."
                    print err
                    exitFailure

                Right result -> do
                    putStrLn "HumMac compilation successful."

                    putStrLn "\nStructured Mathematical IR:"
                    print (compiledProgram result)

                    putStrLn "\nSymbol table:"
                    mapM_ print (getSymbols (compiledSymbols result))

                    putStrLn "\nInferred types:"
                    let environment =
                            finalTypeEnvironment (semanticResult result)

                        printSymbolType :: SymbolInfo -> IO ()
                        printSymbolType info =
                            case Map.lookup (symbolId info) environment of
                                Just typ ->
                                    putStrLn
                                        (symbolName info ++ " :: " ++ show typ)

                                Nothing ->
                                    putStrLn
                                        (symbolName info ++ " :: unresolved")

                    mapM_ printSymbolType (getSymbols (compiledSymbols result))

                    putStrLn "\nSemantic analysis successful."

readSource :: FilePath -> IO (Either IOException String)
readSource path =
    try $ do
        source <- readFile path
        _ <- evaluate (length source)
        pure source
