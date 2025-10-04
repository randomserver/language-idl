{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE LambdaCase #-}
module Idl.Proto.Simplify where

import Control.Monad (forM_)
import Control.Monad.State
    ( state, modify, evalState, MonadState(get, put), StateT, runStateT, runState)
import Control.Monad.Except
    ( runExceptT, MonadError(throwError), ExceptT )

import Control.Monad.IO.Class
import Data.Text (Text, unpack)
import qualified Data.Text as Text
import qualified Data.Text.IO as TIO
import Idl.Parser
import System.FilePath
import Data.Map (Map)
import qualified Data.Map as Map

type Package = [Text]
data ProtoFile = PF {
  package_     :: Package,
  file_        :: FilePath,
  definitions_ :: [Definition]
} deriving (Show)

data FlattnerState = FS {
  stack_ :: [Text],
  files_ :: Map Package ProtoFile
} deriving (Show)

type FlattnerClass m = (MonadError String m, MonadState FlattnerState m)
type Flattner m = ExceptT String (StateT FlattnerState m)

notModule :: Definition -> Bool
notModule (DefModule _ _) = False
notModule _ = True

isModule :: Definition -> Bool
isModule d = not (notModule d)

stackPush :: (FlattnerClass m) => Text -> m [Text]
stackPush t = state \s@(FS stack _) ->
  let stack' = t : stack
   in (stack', s { stack_ = stack' } )

stackPop :: (FlattnerClass m) => m ()
stackPop = do
  FS stack files <- get
  case stack of 
    [] -> throwError "Stack empty"
    (_ : stack') -> put $ FS stack' files

putFile :: (FlattnerClass m) => ProtoFile -> m ()
putFile pf = do
  let package = package_ pf
  FS stack files <- get
  put $ FS stack (Map.insert package pf files)
  

flattenDef :: (FlattnerClass m) => Definition -> m ()
flattenDef (DefModule name defs) = do
  s <- stackPush name
  let filtered = filter notModule defs 
      submodules = filter isModule defs
      package = reverse s
      path = joinPath (unpack <$> package) </> (unpack name ++ "Types") <.> "proto"
  putFile $ PF package path filtered
  forM_ submodules flattenDef
  stackPop

flattenDef a = throwError $ "Cannot flatten a " ++ show a

flattenSpec :: (FlattnerClass m) => Specification -> m ()
flattenSpec (Spec includes defs) = mapM_ flattenDef defs

runFlattner :: (MonadIO m) => Specification -> m (Either String [ProtoFile])
runFlattner specs = do
  flattend <- runStateT (runExceptT (flattenSpec specs)) (FS [] Map.empty)
  --liftIO $ print (show s)
  pure $ Right []

