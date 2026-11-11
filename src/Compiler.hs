-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0
-- See the LICENSE file for details.

module Compiler
    ( CompilationResult(..)
    , CompilationError(..)
    , compileSource
    ) where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set

import qualified Parser
import qualified SMIR

import ExpressionInference (FunctionRegistry)
import InitializationAnalysis
    ( InitializationError(..)
    , analyzeInitialization
    )
import InstructionAnalysis
import SymbolTable
import SyntaxToSMIR (convertProgram)

data CompilationResult = CompilationResult
    { compiledProgram :: SMIR.Program
    , compiledSymbols :: SymbolTable
    , semanticResult :: InstructionResult
    }
    deriving (Show, Eq)

data CompilationError
    = ParsingFailed String
    | SemanticAnalysisFailed InstructionError
    | InitializationAnalysisFailed InitializationError
    deriving (Show, Eq)

compileSource :: String -> Either CompilationError CompilationResult
compileSource source = do
    legacyProgram <-
        either
            (Left . ParsingFailed)
            Right
            (Parser.parseProgram source)

    let (coreProgram, symbolTable) =
            convertProgram legacyProgram

        SMIR.Program instructions = coreProgram

        functions :: FunctionRegistry
        functions = Map.empty

        runtimeRequiredSymbols =
            Set.fromList
                [ symbolId info
                | info <- getSymbols symbolTable
                , symbolReadBeforeWrite info
                , symbolProgramWritten info
                ]

    result <-
        either
            (Left . SemanticAnalysisFailed)
            Right
            (analyzeInstructions
                1000000
                Map.empty
                functions
                instructions)

    _ <-
        either
            (Left . InitializationAnalysisFailed)
            Right
            (analyzeInitialization
                runtimeRequiredSymbols
                Set.empty
                instructions)

    Right CompilationResult
        { compiledProgram = coreProgram
        , compiledSymbols = symbolTable
        , semanticResult = result
        }
