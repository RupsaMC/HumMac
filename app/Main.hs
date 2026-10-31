module Main where

import Parser
import Evaluator

main :: IO ()
main = do
    source <- readFile "examples/arithmetic.eng"

    case parseProgram source of
        Left err ->
            putStrLn ("Parsing error: " ++ err)

        Right program ->
            case evalProgram program of
                Left err ->
                    putStrLn ("Execution error: " ++ err)

                Right (environment, output) -> do
                    putStrLn "HumMac execution successful."
                    putStrLn "\nOutput:"
                    mapM_ print output
                    putStrLn "\nFinal variable environment:"
                    print environment