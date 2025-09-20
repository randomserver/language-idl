{-# LANGUAGE OverloadedStrings #-}
module Proto where

import Data.Text
import Data.Stack
import Control.Monad.State
import Prettyprinter
import Prettyprinter.Render.Text
import Idl.Ast2
import System.IO
import GHC.Natural (naturalToInteger)


newtype ProtoState = ProtoState {
  stack :: Stack Text
}

type ProtoPrint a = State ProtoState a

pushStack :: Text -> ProtoPrint ()
pushStack name = modify (\s -> s { stack = stackPush (stack s) name } )

stackDepth :: ProtoPrint Int
stackDepth = do
  st <- get
  let depth = stackSize $ stack st
  pure $ fromIntegral (naturalToInteger depth)

ppDefinition :: Definition -> ProtoPrint (Doc a)
ppDefinition (DefModule identifier definitions) = do
  indentation <- stackDepth
  pushStack identifier
  proto_defs <- mapM ppDefinition definitions

  pure $ "message" <+> pretty identifier <+> vcat
    [nest (indentation + 4) $
      vcat ("{" : proto_defs)
    , "}" ]

ppDefinition (DefConst identifier typeSpec constExpr) = do
  pure (pretty identifier)
ppDefinition (DefType typeDcl) = do
  pure (pretty $ show typeDcl)

render :: Doc a -> IO ()
render doc = renderIO System.IO.stdout (layoutPretty defaultLayoutOptions doc)

renderProto :: Definition -> IO ()
renderProto def = render (evalState (ppDefinition def) (ProtoState stackNew))


