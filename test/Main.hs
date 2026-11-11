module Main where

import Compiler
import InitializationAnalysis
    ( InitializationError(..)
    , analyzeInitialization
    )
import qualified Data.Set as Set
import InstructionAnalysis
    ( finalTypeEnvironment
    , analyzeInstructions
    , InstructionError(..)
    )
import ExpressionInference (ExpressionError(..))
import qualified SMIR as Core
import Parser
import SMIR (SymbolId(..))
import Syntax
import TypeSystem
import qualified Data.Map.Strict as Map
import Data.Ratio ((%))

assert :: String -> Bool -> IO ()
assert name condition =
    if condition
        then putStrLn ("PASS: " ++ name)
        else do
            putStrLn ("FAIL: " ++ name)
            fail name

assertEqual :: (Eq a, Show a) => String -> a -> a -> IO ()
assertEqual name expected actual =
    assert
        (name ++ "\n  expected: " ++ show expected
            ++ "\n  actual:   " ++ show actual)
        (expected == actual)

testExpressions :: IO ()
testExpressions = do
    assertEqual "Unary minus precedence"
        (Just (Negate (Power (Number 2) (Number 2))))
        (parseComplete expression "-2^2")

    assertEqual "Right-associative exponentiation"
        (Just (Power (Number 2) (Power (Number 3) (Number 2))))
        (parseComplete expression "2^3^2")

    assertEqual "Implicit multiplication with parentheses"
        (Just (Multiply (Number 3)
            (Add (VariableRef "x") (Number 1))))
        (parseComplete expression "3(x+1)")

    assertEqual "Adjacent parenthesized multiplication"
        (Just (Multiply
            (Add (VariableRef "x") (Number 1))
            (Subtract (VariableRef "x") (Number 1))))
        (parseComplete expression "(x+1)(x-1)")

    assertEqual "Exact decimal representation"
        (Just (Add (Decimal (5 % 4)) (Decimal (5 % 2))))
        (parseComplete expression "1.25+2.5")

    assertEqual "Complete identifier"
        (Just (VariableRef "xy"))
        (parseComplete expression "xy")

    assertEqual "Explicit multiplication"
        (Just (Multiply (VariableRef "x") (VariableRef "y")))
        (parseComplete expression "x*y")

    assertEqual "Left-associative division"
        (Just (Divide
            (Divide (VariableRef "a") (VariableRef "b"))
            (VariableRef "c")))
        (parseComplete expression "a/b/c")

    assertEqual "Implicit multiplication preserves identifier"
        (Just (Multiply (Number 2) (VariableRef "xy")))
        (parseComplete expression "2xy")

testInstructions :: IO ()
testInstructions = do
    assertEqual "Set instruction"
        (Right (Assign "x" (Number 10)))
        (parseInstruction "Set x to 10.")

    assertEqual "Add instruction"
        (Right (Print (Add (VariableRef "x") (VariableRef "y"))))
        (parseInstruction "Add x and y.")

    assertEqual "Multiply instruction"
        (Right (Print (Multiply (VariableRef "x") (Number 5))))
        (parseInstruction "Multiply x by 5.")

    assertEqual "Subtract instruction order"
        (Right (Print (Subtract (VariableRef "y") (Number 3))))
        (parseInstruction "Subtract 3 from y.")

testRepetition :: IO ()
testRepetition = do
    assertEqual "Zero repetition count"
        (Just 0)
        (parseRepeatHeader "Repeat 0 times.")

    assertEqual "Positive repetition count"
        (Just 12)
        (parseRepeatHeader "Repeat 12 times.")

    assert "Negative repetition rejected"
        (isNegativeRepeatHeader "Repeat -3 times.")

    assert "Decimal repetition rejected"
        (isDecimalRepeatHeader "Repeat 2.5 times.")

    assert "Missing repeat terminator rejected"
        (case parseProgram "Repeat 3 times.\nSet x to 1.\n" of
            Left message -> "missing" `contains` message
            Right _ -> False)

    assert "Unmatched repeat terminator rejected"
        (case parseProgram "Set x to 1.\nEnd repeat.\n" of
            Left message -> "Unexpected" `contains` message
            Right _ -> False)

    assertEqual "Nested repetition structure"
        (Right
            [ Repeat 2
                [ Assign "x" (Number 10)
                , Repeat 3
                    [ Print (Add (VariableRef "x") (Number 1)) ]
                ]
            ])
        (parseProgram
            "Repeat 2 times.\n\
            \Set x to 10.\n\
            \Repeat 3 times.\n\
            \Add x and 1.\n\
            \End repeat.\n\
            \End repeat.\n")

contains :: String -> String -> Bool
contains needle haystack =
    any (startsWith needle) (tails haystack)
    where
        startsWith prefix value =
            take (length prefix) value == prefix

        tails [] = [[]]
        tails value@(_:rest) = value : tails rest

testCompilation :: IO ()
testCompilation = do
    case compileSource
        "Set x to 4.\nSet y to 2x+3.\n" of

        Left err ->
            fail ("Compiler rejected valid program: " ++ show err)

        Right result -> do
            let environment =
                    finalTypeEnvironment (semanticResult result)

            assertEqual "Assignment type inference"
                (Just IntegerType)
                (Map.lookup (SymbolId 0) environment)

            assertEqual "Type propagation through implicit multiplication"
                (Just IntegerType)
                (Map.lookup (SymbolId 1) environment)

    assert "Negative repetition rejected by compiler"
        (case compileSource "Repeat -3 times.\n" of
            Left (ParsingFailed _) -> True
            _ -> False)

    assert "Decimal repetition rejected by compiler"
        (case compileSource "Repeat 2.5 times.\n" of
            Left (ParsingFailed _) -> True
            _ -> False)


testCompilerInitialization :: IO ()
testCompilerInitialization = do

    assert "Compiler rejects runtime self-reference before initialization"
        (case compileSource "Set x to x + 1.\n" of
            Left (InitializationAnalysisFailed
                (ReadBeforeInitialization (SymbolId 0))) -> True
            _ -> False)

    assert "Compiler accepts a free mathematical variable"
        (case compileSource "Add x and 1.\n" of
            Right _ -> True
            _ -> False)

    assert "Compiler accepts assignment before subsequent read"
        (case compileSource
            "Set x to 1.\nAdd x and 1.\n" of
            Right _ -> True
            _ -> False)

    assert "Compiler accepts self-reference inside zero repetition"
        (case compileSource
            "Repeat 0 times.\nSet x to x + 1.\nEnd repeat.\n" of
            Right _ -> True
            _ -> False)

    assert "Compiler rejects self-reference inside positive repetition"
        (case compileSource
            "Repeat 3 times.\nSet x to x + 1.\nEnd repeat.\n" of
            Left (InitializationAnalysisFailed
                (ReadBeforeInitialization (SymbolId 0))) -> True
            _ -> False)


testSemanticRules :: IO ()
testSemanticRules = do
    case compileSource "Set result to 1 + 2.5.\n" of
        Left err ->
            fail ("Integer plus Real was rejected: " ++ show err)

        Right result ->
            assertEqual "Integer plus Real produces Real"
                (Just RealType)
                (Map.lookup (SymbolId 0)
                    (finalTypeEnvironment (semanticResult result)))

    case compileSource "Set result to 4 / 2.\n" of
        Left err ->
            fail ("Integer division was rejected: " ++ show err)

        Right result ->
            assertEqual "Integer division produces Rational"
                (Just RationalType)
                (Map.lookup (SymbolId 0)
                    (finalTypeEnvironment (semanticResult result)))

    case compileSource
        "Set x to 2.\nSet x to 2.5.\n" of

        Left err ->
            fail ("Numeric widening was rejected: " ++ show err)

        Right result ->
            assertEqual "Integer assignment widens to Real"
                (Just RealType)
                (Map.lookup (SymbolId 0)
                    (finalTypeEnvironment (semanticResult result)))

    assert "Boolean symbol rejected in arithmetic"
        (case analyzeInstructions 1000000 Map.empty Map.empty
            [ Core.Assign (SymbolId 0)
                (Core.BooleanValue (Core.BooleanConstant True))
            , Core.Assign (SymbolId 1)
                (Core.NumericValue
                    (Core.Add
                        (Core.Symbol (SymbolId 0))
                        (Core.Constant (Core.IntegerLiteral 1))))
            ] of

            Left (InstructionExpressionError
                (InvalidNumericOperands BooleanType IntegerType)) -> True

            _ -> False)

    assert "Incompatible Integer-to-Boolean reassignment rejected"
        (case analyzeInstructions 1000000 Map.empty Map.empty
            [ Core.Assign (SymbolId 0)
                (Core.NumericValue
                    (Core.Constant (Core.IntegerLiteral 5)))
            , Core.Assign (SymbolId 0)
                (Core.BooleanValue (Core.BooleanConstant True))
            ] of

            Left (AssignmentTypeConflict
                (SymbolId 0) IntegerType BooleanType) -> True

            _ -> False)


testControlFlowTypes :: IO ()
testControlFlowTypes = do
    assert "If branches merge Integer and Real as Real"
        (case analyzeInstructions 1000000 Map.empty Map.empty
            [ Core.If (Core.BooleanConstant True)
                [ Core.Assign (SymbolId 0)
                    (Core.NumericValue
                        (Core.Constant (Core.IntegerLiteral 5)))
                ]
                [ Core.Assign (SymbolId 0)
                    (Core.NumericValue
                        (Core.Constant (Core.RealLiteral (5 % 2))))
                ]
            ] of
            Right result ->
                Map.lookup (SymbolId 0)
                    (finalTypeEnvironment result) == Just RealType
            _ -> False)

    assert "Repeat body propagates assignment type"
        (case analyzeInstructions 1000000 Map.empty Map.empty
            [ Core.Repeat
                (Core.Constant (Core.IntegerLiteral 3))
                [ Core.Assign (SymbolId 0)
                    (Core.NumericValue
                        (Core.Constant (Core.RealLiteral (5 % 2))))
                ]
            ] of
            Right result ->
                Map.lookup (SymbolId 0)
                    (finalTypeEnvironment result) == Just RealType
            _ -> False)

    assert "Real repetition count is rejected"
        (case analyzeInstructions 1000000 Map.empty Map.empty
            [ Core.Repeat
                (Core.Constant (Core.RealLiteral (5 % 2)))
                []
            ] of
            Left (InvalidRepeatCount RealType) -> True
            _ -> False)


testInitializationAnalysis :: IO ()
testInitializationAnalysis = do
    let symbol = SymbolId 0
        required = Set.singleton symbol
        freeSymbols = Set.empty
        uninitialized = Set.empty
        initialized = Set.singleton symbol

    assert "Uninitialized runtime symbol read is rejected"
        (analyzeInitialization required uninitialized
            [Core.Evaluate (Core.Symbol symbol)]
            == Left (ReadBeforeInitialization symbol))

    assert "Free mathematical symbol can be read"
        (analyzeInitialization freeSymbols uninitialized
            [Core.Evaluate (Core.Symbol symbol)]
            == Right uninitialized)

    assert "Assignment initializes its target"
        (analyzeInitialization required uninitialized
            [ Core.Assign symbol
                (Core.NumericValue
                    (Core.Constant (Core.IntegerLiteral 5)))
            , Core.Evaluate (Core.Symbol symbol)
            ]
            == Right initialized)

    assert "Runtime self-reference before assignment is rejected"
        (analyzeInitialization required uninitialized
            [ Core.Assign symbol
                (Core.NumericValue
                    (Core.Add
                        (Core.Symbol symbol)
                        (Core.Constant (Core.IntegerLiteral 1))))
            ]
            == Left (ReadBeforeInitialization symbol))

    assert "Free symbol can appear in self-referential assignment"
        (analyzeInitialization freeSymbols uninitialized
            [ Core.Assign symbol
                (Core.NumericValue
                    (Core.Add
                        (Core.Symbol symbol)
                        (Core.Constant (Core.IntegerLiteral 1))))
            ]
            == Right initialized)

    assert "Assignment in both branches initializes symbol"
        (analyzeInitialization required uninitialized
            [ Core.If (Core.BooleanConstant True)
                [ Core.Assign symbol
                    (Core.NumericValue
                        (Core.Constant (Core.IntegerLiteral 1)))
                ]
                [ Core.Assign symbol
                    (Core.NumericValue
                        (Core.Constant (Core.IntegerLiteral 2)))
                ]
            , Core.Evaluate (Core.Symbol symbol)
            ]
            == Right initialized)

    assert "Assignment in only one branch does not initialize runtime symbol"
        (analyzeInitialization required uninitialized
            [ Core.If (Core.BooleanConstant True)
                [ Core.Assign symbol
                    (Core.NumericValue
                        (Core.Constant (Core.IntegerLiteral 1)))
                ]
                []
            , Core.Evaluate (Core.Symbol symbol)
            ]
            == Left (ReadBeforeInitialization symbol))

    assert "Positive repeat guarantees runtime initialization"
        (analyzeInitialization required uninitialized
            [ Core.Repeat
                (Core.Constant (Core.IntegerLiteral 3))
                [ Core.Assign symbol
                    (Core.NumericValue
                        (Core.Constant (Core.IntegerLiteral 1)))
                ]
            , Core.Evaluate (Core.Symbol symbol)
            ]
            == Right initialized)

    assert "Zero repeat does not initialize runtime symbol"
        (analyzeInitialization required uninitialized
            [ Core.Repeat
                (Core.Constant (Core.IntegerLiteral 0))
                [ Core.Assign symbol
                    (Core.NumericValue
                        (Core.Constant (Core.IntegerLiteral 1)))
                ]
            , Core.Evaluate (Core.Symbol symbol)
            ]
            == Left (ReadBeforeInitialization symbol))

    assert "Zero repeat does not evaluate its body"
        (analyzeInitialization required uninitialized
            [ Core.Repeat
                (Core.Constant (Core.IntegerLiteral 0))
                [ Core.Evaluate (Core.Symbol symbol) ]
            ]
            == Right uninitialized)

    assert "Positive repeat propagates initialization through both If branches"
        (analyzeInitialization required uninitialized
            [ Core.Repeat
                (Core.Constant (Core.IntegerLiteral 2))
                [ Core.If
                    (Core.BooleanConstant True)
                    [ Core.Assign symbol
                        (Core.NumericValue
                            (Core.Constant (Core.IntegerLiteral 1)))
                    ]
                    [ Core.Assign symbol
                        (Core.NumericValue
                            (Core.Constant (Core.IntegerLiteral 2)))
                    ]
                ]
            , Core.Evaluate (Core.Symbol symbol)
            ]
            == Right initialized)

    assert "Nested positive repeats propagate initialization"
        (analyzeInitialization required uninitialized
            [ Core.Repeat
                (Core.Constant (Core.IntegerLiteral 2))
                [ Core.Repeat
                    (Core.Constant (Core.IntegerLiteral 3))
                    [ Core.Assign symbol
                        (Core.NumericValue
                            (Core.Constant (Core.IntegerLiteral 1)))
                    ]
                ]
            , Core.Evaluate (Core.Symbol symbol)
            ]
            == Right initialized)

    assert "Initially initialized runtime symbol can be read"
        (analyzeInitialization required initialized
            [Core.Evaluate (Core.Symbol symbol)]
            == Right initialized)

main :: IO ()
main = do
    putStrLn "HumMac regression tests"
    testExpressions
    testInstructions
    testRepetition
    testCompilation
    testSemanticRules
    testControlFlowTypes
    testInitializationAnalysis
    testCompilerInitialization
    putStrLn "\nAll regression tests passed."
