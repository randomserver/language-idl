{-# LANGUAGE FlexibleContexts #-}
module Idl.Parser (
  runParser
  , module Idl.Parser.Ast) where

import qualified Idl.Parser.Lexer as L
import Idl.Parser.Parser
import Idl.Parser.Ast
import Idl.Simplify
import qualified Data.Text.IO as TIO
import Control.Monad
import Control.Monad.State
import Control.Monad.Except

runParser :: (MonadIO m, MonadError String m) => FilePath -> m IdlFile
runParser fp = do
  content <- liftIO $ TIO.readFile fp
  spec <- liftEither . join $ L.runAlex content $ evalStateT (runExceptT idlParse) []
  (Spec includes defs) <- (liftEither . runSimplify) spec
  pure $ IdlFile fp includes defs
  
