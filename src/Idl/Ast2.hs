{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE LambdaCase #-}
module Idl.Ast2 where
import Data.Bits
import           Data.Text (Text)
import qualified Data.Text as Text
import Control.Monad.State
import Control.Monad.Except
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Stack (Stack)
import qualified Data.Stack as Stack

-- Top-level specification
type Specification = [Definition]

data Definition
  = DefModule Identifier [Definition]
  | DefConst Identifier TypeSpec ConstExpr
  | DefType TypeDcl
  deriving (Show)

-- Expressions and Literals
data ConstExpr
  = ExprScoped ScopedName
  | ExprLiteral Literal
  | OrExpr ConstExpr ConstExpr
  | XorExpr ConstExpr ConstExpr
  | AndExpr ConstExpr ConstExpr
  | ShiftRExpr ConstExpr ConstExpr | ShiftLExpr ConstExpr ConstExpr
  | AddExpr ConstExpr ConstExpr | SubExpr ConstExpr ConstExpr
  | MultExpr ConstExpr ConstExpr | DivExpr ConstExpr ConstExpr | ModExpr ConstExpr ConstExpr
  | UnaryNeg ConstExpr | UnaryNot ConstExpr | UnaryAdd ConstExpr
  deriving (Show)

data Literal
  = LitInt Int
  | LitFloat Double
  | LitFixed Double
  | LitChar Char
  | LitWChar Char
  | LitString Text
  | LitWString Text
  | LitBool Bool
  deriving (Show)

-- Type Declarations
data TypeDcl
  = TypeStruct Identifier (Maybe ScopedName) [StructMember]
  | TypeUnion   -- [TODO]
  | TypeEnum    -- [TODO]
  | TypeBitmask -- [TODO]
  | TypeNative Declarator
  | TypeTypedef TypeDeclarator 
  deriving (Show)

-- Struct members
data StructMember = StructMember TypeSpec [Declarator]
                    deriving (Show)

data TypeDeclarator = TypeDeclarator TypeSpec [Declarator]
                    | TypeConstrDeclarator TypeDcl [Declarator]
                    deriving (Show)

-- Declarators
data Declarator = DeclSimple Identifier
                | DeclArray Identifier [ConstExpr]
                deriving (Show)

-- Unified type representation (flattened)
data TypeSpec
  -- Primitive/base types
  = TSInt IntegerKind
  | TSFloat FloatingKind
  | TSChar
  | TSWChar
  | TSBool
  | TSOctet

  -- Template types
  | TSSeq TypeSpec (Maybe ConstExpr)
  | TSString (Maybe ConstExpr)
  | TSWString (Maybe ConstExpr)
  | TSFixed (Maybe ConstExpr) (Maybe ConstExpr)
  | TSMap TypeSpec TypeSpec (Maybe ConstExpr)

  -- User-defined types
  | TSUser ScopedName
  deriving (Show)
data IntegerKind
  = TInt8 | TInt16 | TInt32 | TInt64
  | TUInt8 | TUInt16 | TUInt32 | TUInt64
  deriving (Show)

data FloatingKind
  = Float32 | Float64 | LongDouble
  deriving (Show)

-- Scoped names like ::A::B::C => ["A", "B", "C"]
type ScopedName = [Identifier]
type Identifier = Text

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
simplify = mapM simplifyDef

runSimplify :: Specification -> Either String Specification
runSimplify spec = evalState (runExceptT (simplify spec)) (ExprState [] Map.empty)
