module Main where

import Proto
import Idl.Parser2

main :: IO ()
main = do
  input <- readFile "app/basic_module_test.idl"
  let Right (ast : _) = runParser input
  renderProto ast
