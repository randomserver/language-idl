module Main where

import Idl.Ast2
import Idl.Parser2
import qualified Data.Text.IO as TIO

main :: IO ()
main = do
  input <- TIO.readFile "app/test_simple.idl"
  case runParser input >>= runSimplify of
    Left err -> putStrLn err
    Right ast -> print $ show ast 
