module Main where

import Proto
import Idl.Parser2
import Data.Text
import qualified Data.Text.IO as TIO

main :: IO ()
main = do
  input <- TIO.readFile "app/basic_module_test.idl"
  let Right (ast : _) = runParser input
  renderProto ast
