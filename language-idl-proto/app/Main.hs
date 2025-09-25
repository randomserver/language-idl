module Main where

import Idl.Ast2
import Idl.Parser2
import Idl.Proto
import qualified Data.Text.IO as TIO

main :: IO ()
main = do
  input <- TIO.readFile "app/test_simple.idl"
  case runParser input of
    Left err -> putStrLn err
    Right ast -> renderProto ast 
