{-# LANGUAGE BlockArguments, LambdaCase #-}
module Main where

import Idl.Parser
import Idl.Proto
import Idl.Proto.Simplify
import qualified Data.Text.IO as TIO
import Control.Monad.IO.Class
import Control.Monad.Except

main :: IO ()
main = do
  (runExceptT . runParser) "app/test_simple.idl" >>= \case
    Left err -> putStrLn err
    Right (IdlFile _ includes specs) -> print includes >> print specs
  pure ()
