module Main where

import Parser
import Evaluator
import Termination
import TypeChecker

main :: IO ()
main = do
    source <- readFile "examples/arithmetic.eng"

    case parseProgram source of
        Left err ->
            putStrLn ("Parsing error: " ++ err)

        Right program ->
            case validateProgram program of
                Left err ->
                    putStrLn ("Semantic validation failed: " ++ err)

                Right () ->
                    case verifyProgram program of
                        Left err ->
                            putStrLn ("Termination verification failed: " ++ err)

                        Right certificate -> do
                            putStrLn "Semantic validation successful."
                            putStrLn "Termination verification successful."
                            putStrLn ("Certificate: " ++ show certificate)

                            case evalProgram program of
                                Left err ->
                                    putStrLn ("Execution error: " ++ err)

                                Right (environment, output) -> do
                                    putStrLn "\nHumMac execution successful."
                                    putStrLn "\nOutput:"
                                    mapM_ print output
                                    putStrLn "\nFinal variable environment:"
                                    print environment