{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE BlockArguments #-}
module Idl.Proto where

import Data.Maybe
import Data.List (maximumBy)
import Data.Ord (comparing)
import Data.Text (Text)
import qualified Data.Map as Map
import Data.Map (Map)
import Control.Monad (forM)
import Control.Monad.Trans.State
import Prettyprinter
import Prettyprinter.Render.Text
import Idl.Ast2
import System.IO

type FieldIds = Map Text Int

data ProtoState = ProtoState {
  stack_ :: [Text],
  fields_ :: Map [Text] FieldIds
}

emptyProtoState :: ProtoState
emptyProtoState = ProtoState {
  stack_ = [],
  fields_ = Map.empty
}

type ProtoPrint a = State ProtoState a

pushStack :: Text -> ProtoPrint ()
pushStack name = modify $ \s@(ProtoState st _) -> s { stack_ = name : st }

popStack :: ProtoPrint ()
popStack = modify $ \case
  s@(ProtoState (_ : rest) _) -> s { stack_ = rest }
  s@(ProtoState [] _) -> s

stackDepth :: ProtoPrint Int
stackDepth = length . stack_ <$> get

getFieldId :: Text -> Int -> ProtoPrint Int
getFieldId name starting = do
  ProtoState stack fields <- get
  let ids = Map.findWithDefault Map.empty stack fields
  case Map.lookup name ids of
    Just val -> pure val
    Nothing  -> do
      let val = nextValue ids
          ids' = Map.insert name val ids
          fields' = Map.insert stack ids' fields
      put $ ProtoState stack fields'
      pure val
  where
    nextValue :: FieldIds -> Int
    nextValue m
      | Map.null m = starting
      | otherwise  = snd (maximumBy (comparing snd) (Map.toList m)) + 1

ppTypeSpec :: TypeSpec -> ProtoPrint (Maybe (Doc a))
ppTypeSpec (TSInt TInt8) = pure $ Just "int8"
ppTypeSpec (TSInt TInt16) = pure $ Just "int16"
ppTypeSpec (TSInt TInt32) = pure $ Just "int32"
ppTypeSpec (TSInt TInt64) = pure $ Just "int64"
ppTypeSpec (TSInt TUInt8) = pure $ Just "uint8"
ppTypeSpec (TSInt TUInt16) = pure $ Just "uint16"
ppTypeSpec (TSInt TUInt32) = pure $ Just "uint32"
ppTypeSpec (TSInt TUInt64) = pure $ Just "uint64"
ppTypeSpec (TSFloat Float32) = pure $ Just "float"
ppTypeSpec (TSFloat _) = pure $ Just "double"
ppTypeSpec TSChar = pure $ Just "uint8"
ppTypeSpec TSWChar = pure $ Just "uint16"
ppTypeSpec TSBool = pure $ Just "bool"
ppTypeSpec TSOctet = pure Nothing
ppTypeSpec (TSString _) = pure $ Just "string"
ppTypeSpec (TSUser names) = pure . Just $ concatWith (\l r -> l <> "." <> r) (pretty <$> names)

ppTypeSpec (TSSeq ts _) = do
  t <- ppTypeSpec ts
  pure $ ("repeated" <+>) <$> t

ppTypeSpec (TSMap ks vs _) = do
  mk <- ppTypeSpec ks
  mv <- ppTypeSpec vs
  pure $ do
    k <- mk
    v <- mv
    pure $ "map" <> "<" <> k <> "," <+> v <> ">"

ppTypeSpec _ = pure Nothing

ppDeclarator :: Declarator -> ProtoPrint (Doc a)
ppDeclarator (DeclSimple name) = pure $ pretty name
ppDeclarator (DeclArray name _) = pure $ pretty name

ppTypeDcl :: TypeDcl -> ProtoPrint (Maybe (Doc a))
ppTypeDcl (TypeStruct identifier _ members) = do
  pushStack identifier
  indentation <- stackDepth
  ms <- concat <$> mapM ppMember members
  popStack
  pure . Just $ "message" <+> pretty identifier <+> vcat [ 
    nest indentation (vcat ("{" : ms)), "}"]

  where ppMember :: StructMember -> ProtoPrint [Doc a]
        ppMember (StructMember ts declarators) = ppTypeSpec ts >>= \case
          Just t -> do
            forM declarators $ \case
              DeclSimple name  -> getFieldId name 1 >>= \v -> pure $ t <+> pretty name <+> "=" <+> pretty v <> ";"
              DeclArray name _ -> getFieldId name 1 >>= \v -> pure $ "repeated" <+> t <+> pretty name <+> "=" <+> pretty v <> ";"
          Nothing -> pure []
            
ppTypeDcl (TypeEnum name identifiers) = do
  pushStack name
  ind <- stackDepth
  members <- mapM ppMember identifiers
  popStack
  pure . Just $ "enum" <+> pretty name <+> vcat [
    nest ind (vcat ("{" : members)), "}"]

  where ppMember :: Text -> ProtoPrint (Doc a)
        ppMember m = do
          i <- getFieldId m 0
          pure $ pretty m <+> "=" <+> pretty i <> ";"

ppTypeDcl _ = pure Nothing

ppDefinition :: Definition -> ProtoPrint (Maybe (Doc a))
ppDefinition (DefModule identifier definitions) = do
  pushStack identifier
  indentation <- stackDepth
  maybeDocs <- mapM ppDefinition definitions
  let proto_defs = catMaybes maybeDocs

  popStack
  pure $ Just $ "message" <+> pretty identifier <+> vcat
    [nest indentation $
      vcat ("{" : proto_defs)
    , "}" ]

ppDefinition (DefType typeDcl) = ppTypeDcl typeDcl

ppDefinition _ = pure Nothing

ppDefinitions :: Specification -> ProtoPrint (Doc a)
ppDefinitions spec = do
  docs <- mapM ppDefinition spec
  pure $ vcat $ "syntax = \"proto3\";" : catMaybes docs 

render :: Doc a -> IO ()
render doc = renderIO System.IO.stdout (layoutPretty defaultLayoutOptions doc)

renderProto :: [Definition] -> IO ()
renderProto def = render (evalState (ppDefinitions def) emptyProtoState)


