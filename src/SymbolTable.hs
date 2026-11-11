-- Copyright 2026 Rupsa Mandal Chakraborty
-- SPDX-License-Identifier: Apache-2.0
--
-- Licensed under the Apache License, Version 2.0
-- See the LICENSE file for details.

module SymbolTable
    ( SymbolInfo(..)
    , SymbolTable
    , emptySymbolTable
    , introduceSymbol
    , lookupSymbol
    , getSymbols
    , recordRead
    , recordWrite
    , restoreUsageMetadata
    , mergeUsageMetadata
    ) where

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)

import SMIR (SymbolId(..))

data SymbolInfo = SymbolInfo
    { symbolName :: String
    , symbolId :: SymbolId
    , symbolReadBeforeWrite :: Bool
    , symbolProgramWritten :: Bool
    }
    deriving (Show, Eq)

data SymbolTable = SymbolTable
    { symbols :: Map String SymbolInfo
    , nextSymbolId :: Int
    }
    deriving (Show, Eq)

emptySymbolTable :: SymbolTable
emptySymbolTable =
    SymbolTable Map.empty 0

introduceSymbol :: String -> SymbolTable -> (SymbolInfo, SymbolTable)
introduceSymbol name table =
    case Map.lookup name (symbols table) of
        Just info -> (info, table)
        Nothing ->
            let newId = SymbolId (nextSymbolId table)
                info = SymbolInfo
                    { symbolName = name
                    , symbolId = newId
                    , symbolReadBeforeWrite = False
                    , symbolProgramWritten = False
                    }
                updatedSymbols = Map.insert name info (symbols table)
                updatedTable = SymbolTable
                    { symbols = updatedSymbols
                    , nextSymbolId = nextSymbolId table + 1
                    }
            in (info, updatedTable)

lookupSymbol :: String -> SymbolTable -> Maybe SymbolInfo
lookupSymbol name table =
    Map.lookup name (symbols table)

getSymbols :: SymbolTable -> [SymbolInfo]
getSymbols table =
    Map.elems (symbols table)

recordRead :: SymbolId -> SymbolTable -> SymbolTable
recordRead target table =
    table
        { symbols = Map.map update (symbols table) }
    where
        update info
            | symbolId info == target
                && not (symbolProgramWritten info) =
                    info { symbolReadBeforeWrite = True }
            | otherwise = info

recordWrite :: SymbolId -> SymbolTable -> SymbolTable
recordWrite target table =
    table
        { symbols = Map.map update (symbols table) }
    where
        update info
            | symbolId info == target =
                    info { symbolProgramWritten = True }
            | otherwise = info

-- Keep symbols and their IDs introduced by the converted body,
-- but discard read/write effects when a repeat executes zero times.
restoreUsageMetadata :: SymbolTable -> SymbolTable -> SymbolTable
restoreUsageMetadata original updated =
    updated
        { symbols = Map.mapWithKey restore (symbols updated) }
    where
        restore name info =
            case Map.lookup name (symbols original) of
                Just previous ->
                    info
                        { symbolReadBeforeWrite =
                            symbolReadBeforeWrite previous
                        , symbolProgramWritten =
                            symbolProgramWritten previous
                        }

                Nothing ->
                    info
                        { symbolReadBeforeWrite = False
                        , symbolProgramWritten = False
                        }

-- Merge the effects of two alternative branches.
-- Both flags use disjunction: an effect in either branch must be retained.
-- The second table contains the complete shared symbol-ID allocation.
mergeUsageMetadata :: SymbolTable -> SymbolTable -> SymbolTable
mergeUsageMetadata thenTable elseTable =
    elseTable
        { symbols = Map.mapWithKey merge (symbols elseTable) }
    where
        merge name elseInfo =
            case Map.lookup name (symbols thenTable) of
                Just thenInfo ->
                    elseInfo
                        { symbolReadBeforeWrite =
                            symbolReadBeforeWrite thenInfo
                            || symbolReadBeforeWrite elseInfo
                        , symbolProgramWritten =
                            symbolProgramWritten thenInfo
                            || symbolProgramWritten elseInfo
                        }

                Nothing ->
                    elseInfo
