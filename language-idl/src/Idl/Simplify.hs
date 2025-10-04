{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE TupleSections #-}

module Idl.Simplify where

import Data.Bits ( (.<<.), (.>>.), Bits((.&.), (.|.), xor) )
import Control.Monad.State
    ( modify, evalState, MonadState(get, put), State )
import Control.Monad.Except
    ( runExceptT, MonadError(throwError), ExceptT )
import Data.Map (Map)
import qualified Data.Map as Map
import System.FilePath (FilePath)


import Idl.Parser.Ast


data ExprState = ExprState {
  scope :: [Identifier],
  constants :: Map ScopedName ConstExpr
} deriving Show

type Constrain m = (MonadState ExprState m, MonadError String m)
type ExprSimplify = ExceptT String (State ExprState)

getScope :: Constrain m => m ScopedName
getScope = do
  ExprState sc _ <- get
  pure $ reverse sc

scopePush :: Constrain m => Identifier -> m ()
scopePush ident =
  modify (\s@(ExprState sc _) -> s { scope = ident : sc })

scopePop :: Constrain m => m ()
scopePop = do
  (ExprState sc con) <- get
  case sc of
    [] -> throwError "Could not pop empty stack"
    (_ : scc) -> put (ExprState scc con)

lookUp :: Constrain m => ScopedName -> m ConstExpr
lookUp name = do
  ExprState _ cons <- get
  scopedName <- getScope >>= (\sc -> pure (sc ++ name))
  case Map.lookup scopedName cons of
    Just ex -> pure ex
    Nothing -> throwError ("Unkonwn referense to " ++ show scopedName)

litToInt :: Constrain m => ConstExpr -> m Int
litToInt e = case e of
  ExprLiteral (LitInt i) -> pure i
  err -> throwError $ show err ++ " is not Integer"

simplifyExpr :: Constrain m => ConstExpr -> m ConstExpr
simplifyExpr (ExprScoped name) = lookUp name

simplifyExpr (OrExpr lhs rhs) = do
  lhss <- simplifyExpr lhs >>= litToInt
  rhss <- simplifyExpr rhs >>= litToInt
  pure $ ExprLiteral (LitInt (lhss .|. rhss))

simplifyExpr (XorExpr lhs rhs) = do
  lhss <- simplifyExpr lhs >>= litToInt 
  rhss <- simplifyExpr rhs >>= litToInt
  pure $ ExprLiteral (LitInt (lhss `xor` rhss))

simplifyExpr (AndExpr rhs lhs) = do
  lhss <- simplifyExpr lhs >>= litToInt
  rhss <- simplifyExpr rhs >>= litToInt
  pure $ ExprLiteral (LitInt (lhss .&. rhss))

simplifyExpr (ShiftRExpr lhs rhs) = do
  lhss <- simplifyExpr lhs >>= litToInt
  rhss <- simplifyExpr rhs >>= litToInt
  pure $ ExprLiteral (LitInt (lhss .>>. rhss))

simplifyExpr (ShiftLExpr lhs rhs) = do
  lhss <- simplifyExpr lhs >>= litToInt
  rhss <- simplifyExpr rhs >>= litToInt
  pure $ ExprLiteral (LitInt (lhss .<<. rhss))

simplifyExpr a = pure a

simplifyDef :: Constrain m => Definition -> m Definition
simplifyDef (DefModule name definitions) = do
  scopePush name
  defs <- mapM simplifyDef definitions
  scopePop
  pure $ DefModule name defs

simplifyDef (DefConst name typeSpec constExpr) = do
  expr <- simplifyExpr constExpr
  sc <- getScope
  modify (\s@(ExprState _ cs) -> s { constants = Map.insert (sc ++ [name]) expr cs })
  pure $ DefConst name typeSpec expr

simplifyDef t = pure t

simplify :: Constrain m => Specification -> m Specification
simplify (Spec includes defs) =  Spec includes <$> mapM simplifyDef defs

runSimplify :: Specification -> Either String Specification
runSimplify spec = evalState (runExceptT (simplify spec)) (ExprState [] Map.empty)
