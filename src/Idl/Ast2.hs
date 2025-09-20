module Idl.Ast2 where
import           Data.Text

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
  = LitInt Integer
  | LitFloat Double
  | LitFixed Text
  | LitChar Char
  | LitWChar Text
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

