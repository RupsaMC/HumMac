
module SymbolTable
    ( SymbolInfo(..)
    , SymbolTable
    , emptySymbolTable
    , introduceSymbol
    , lookupSymbol
    , getSymbols
    ) where

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map)

import SMIR (SymbolId(..))

-- Information associated with one symbol.
data SymbolInfo = SymbolInfo
    { symbolName :: String
    , symbolId :: SymbolId
    }
    deriving (Show, Eq)

-- Maps source-level names to their symbol information.
data SymbolTable = SymbolTable
    { symbols :: Map String SymbolInfo
    , nextSymbolId :: Int
    }
    deriving (Show, Eq)

-- An initially empty symbol table.
emptySymbolTable :: SymbolTable
emptySymbolTable =
    SymbolTable Map.empty 0

-- Introduce a symbol if it does not already exist.
-- Existing symbols retain their original identity.
introduceSymbol
    :: String
    -> SymbolTable
    -> (SymbolInfo, SymbolTable)

introduceSymbol name table =
    case Map.lookup name (symbols table) of

        Just info ->
            (info, table)

        Nothing ->
            let newId = SymbolId (nextSymbolId table)

                info = SymbolInfo
                    { symbolName = name
                    , symbolId = newId
                    }

                updatedSymbols =
                    Map.insert name info (symbols table)

                updatedTable = SymbolTable
                    { symbols = updatedSymbols
                    , nextSymbolId = nextSymbolId table + 1
                    }

            in (info, updatedTable)

-- Look up a symbol without introducing it.
lookupSymbol
    :: String
    -> SymbolTable
    -> Maybe SymbolInfo

lookupSymbol name table =
    Map.lookup name (symbols table)

-- Retrieve all known symbols.
getSymbols :: SymbolTable -> [SymbolInfo]
getSymbols table =
    Map.elems (symbols table)
