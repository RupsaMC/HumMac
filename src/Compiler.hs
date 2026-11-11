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

import qualified Parser
import qualified SMIR

import ExpressionInference (FunctionRegistry)
import InstructionAnalysis
import SymbolTable
import SyntaxToSMIR (convertProgram)


-- Result of compiling and semantically analysing a source program.

data CompilationResult = CompilationResult
    { compiledProgram :: SMIR.Program
    , compiledSymbols :: SymbolTable
    , semanticResult :: InstructionResult
    }
    deriving (Show, Eq)


-- Errors that may occur during compilation.

data CompilationError
    = ParsingFailed String
    | SemanticAnalysisFailed InstructionError
    deriving (Show, Eq)


-- Parse source, translate it into SMIR, and perform semantic analysis.
-- This function does not execute the resulting program.

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

    result <-
        either
            (Left . SemanticAnalysisFailed)
            Right
            (analyzeInstructions
                1000000
                Map.empty
                functions
                instructions)

    Right CompilationResult
        { compiledProgram = coreProgram
        , compiledSymbols = symbolTable
        , semanticResult = result
        }
