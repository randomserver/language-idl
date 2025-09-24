{
{-# LANGUAGE LambdaCase #-}
module Idl.Parser2 where
import           Data.Text (Text)
import qualified Data.Text as Text
import qualified Idl.Lexer as L
import Idl.Lexer (Token, Token(..))
import Idl.Ast2
import Control.Monad
import Control.Monad.Trans.State
import Control.Monad.Trans.Except
import Control.Monad.Trans.Class (lift)

import Debug.Trace

}

%name idlParse
%tokentype { Token }
%error { parseError }

%lexer { monadScan >>= } { T _ L.Eof }
%monad { Parse } 

%token
  -- OMG IDL Keywords
  "module"             { T _ L.Module }
  "interface"          { T _ L.Interface }
  "struct"             { T _ L.Struct }
  "union"              { T _ L.Union  }
  "enum"               { T _ L.Enum  }
  "typedef"            { T _ L.Typedef  }
  "sequence"           { T _ L.Sequence  }

  -- Additional Keywords
  "abstract"           { T _ L.Abstract  }
  "any"                { T _ L.Any  }
  "alias"              { T _ L.Alias  }
  "attribute"          { T _ L.Attribute  }
  "bitfield"           { T _ L.Bitfield  }
  "bitmask"            { T _ L.Bitmask  }
  "bitset"             { T _ L.Bitset  }
  "boolean"            { T _ L.Boolean  }
  "case"               { T _ L.Case  }
  "char"               { T _ L.CharType  }
  "component"          { T _ L.Component  }
  "connector"          { T _ L.Connector  }
  "const"              { T _ L.Const  }
  "consumes"           { T _ L.Consumes  }
  "context"            { T _ L.Context  }
  "custom"             { T _ L.Custom  }
  "default"            { T _ L.Default  }
  "double"             { T _ L.DoubleType  }
  "exception"          { T _ L.Exception  }
  "emits"              { T _ L.Emits  }
  "eventtype"          { T _ L.Eventtype  }
  "factory"            { T _ L.Factory  }
  "FALSE"              { T _ L.FalseLit  }
  "finder"             { T _ L.Finder  }
  "fixed"              { T _ L.Fixed  }
  "float"              { T _ L.FloatType  }
  "getraises"          { T _ L.GetRaises  }
  "home"               { T _ L.Home  }
  "import"             { T _ L.Import  }
  "in"                 { T _ L.In  }
  "inout"              { T _ L.InOut  }
  "local"              { T _ L.Local  }
  "long"               { T _ L.Long  }
  "manages"            { T _ L.Manages  }
  "map"                { T _ L.Map  }
  "mirrorport"         { T _ L.MirrorPort  }
  "multiple"           { T _ L.Multiple  }
  "native"             { T _ L.Native  }
  "Object"             { T _ L.ObjectType  }
  "octet"              { T _ L.Octet  }
  "oneway"             { T _ L.OneWay  }
  "out"                { T _ L.Out  }
  "primarykey"         { T _ L.PrimaryKey  }
  "private"            { T _ L.Private  }
  "port"               { T _ L.Port }
  "porttype"           { T _ L.PortType }
  "provides"           { T _ L.Provides }
  "public"             { T _ L.Public }
  "publishes"          { T _ L.Publishes }
  "raises"             { T _ L.Raises }
  "readonly"           { T _ L.Readonly  }
  "setraises"          { T _ L.SetRaises  }
  "short"              { T _ L.Short  }
  "string"             { T _ L.StringType  }
  "supports"           { T _ L.Supports  }
  "switch"             { T _ L.Switch  }
  "TRUE"               { T _ L.TrueLit  }
  "truncatable"        { T _ L.Truncatable  }
  "typeid"             { T _ L.TypeId  }
  "typename"           { T _ L.TypeName  }
  "typeprefix"         { T _ L.TypePrefix  }
  "unsigned"           { T _ L.Unsigned  }
  "uses"               { T _ L.Uses  }
  "ValueBase"          { T _ L.ValueBase  }
  "valuetype"          { T _ L.ValueType  }
  "void"               { T _ L.Void  }
  "wchar"              { T _ L.WChar  }
  "wstring"            { T _ L.WString  }

  -- Extended Integer Types
  "int8"               { T _ L.Int8  }
  "uint8"              { T _ L.UInt8  }
  "int16"              { T _ L.Int16  }
  "int32"              { T _ L.Int32  }
  "int64"              { T _ L.Int64  }
  "uint16"             { T _ L.UInt16  }
  "uint32"             { T _ L.UInt32  }
  "uint64"             { T _ L.UInt64  }

  -- Identifiers and Literals
  identifier              { T _ (L.Identifier $$)     }
  integer_literal         { T _ (L.IntegerLiteral $$) }
  floating_pt_literal     { T _ (L.FloatLiteral $$)   }
  string_literal          { T _ (L.StringLiteral $$)  }
  character_literal       { T _ (L.CharLiteral $$)    }
  wide_string_literal     { T _ (L.WStringLiteral $$) }
  wide_character_literal  { T _ (L.WCharLiteral $$)   }
  fixed_pt_literal        { T _ (L.FixedPointLiteral $$) }

  -- Symbols
  "{"                  { T _ L.LBrace  }
  "}"                  { T _ L.RBrace  }
  "("                  { T _ L.LParen  }
  ")"                  { T _ L.RParen  }
  ";"                  { T _ L.Semicolon  }
  ":"                  { T _ L.Colon  }
  ","                  { T _ L.Comma  }
  "="                  { T _ L.Equals  }
  "["                  { T _ L.LeftBracket  }
  "]"                  { T _ L.RightBracket }
  "::"                 { T _ L.ColonColon  }
  ">"                  { T _ L.Gt  }
  "<"                  { T _ L.Lt  }
  ">>"                 { T _ L.ShiftRight  }
  "<<"                 { T _ L.ShiftLeft  }
  "+"                  { T _ L.Plus  }
  "-"                  { T _ L.Minus  }
  "^"                  { T _ L.Xor  }
  "&"                  { T _ L.And  }
  "|"                  { T _ L.Or  }
  "~"                  { T _ L.Not  }
  "*"                  { T _ L.Mul  }
  "/"                  { T _ L.Div  }
  "%"                  { T _ L.Mod  }

%%

-- 1
specification :: { Specification }
specification : list1(definition) { $1 }

-- 2
definition :: { Definition }
definition : module_dcl ";" { $1 }
           | const_dcl ";"  { $1 }
           | type_dcl ";"   { DefType $1 }
-- 3
module_dcl :: { Definition }
module_dcl : "module" identifier "{" list1(definition) "}" { DefModule $2 $4 }

-- 4
scoped_name :: { ScopedName }
scoped_name : sep1(identifier, "::")      { $1 }
            | "::" sep1(identifier, "::") { $2 }

-- 5
const_dcl :: { Definition }
const_dcl : "const" const_type identifier "=" const_expr { DefConst $3 $2 $5 }

-- 6
const_type :: { TypeSpec }
const_type : integer_type         { TSInt $1 }
           | floating_pt_type     { TSFloat $1 }
           | fixed_pt_const_type  { $1 }
           | char_type            { TSChar }
           | wide_char_type       { TSWChar }
           | boolean_type         { TSBool }
           | octet_type           { TSOctet }
           | string_type          { $1 }
           | wide_string_type     { $1 }
           | scoped_name          { TSUser $1 }

-- 7
const_expr :: { ConstExpr }
const_expr : or_expr { $1 }

-- 8
or_expr : xor_expr              { $1           }
        | or_expr "|" xor_expr  { OrExpr $1 $3 }

-- 9
xor_expr : and_expr               { $1            }
         | xor_expr "^" and_expr  { XorExpr $1 $3 }
-- 10
and_expr : shift_expr               { $1            }
         | and_expr "&" shift_expr  { AndExpr $1 $3 }

-- 11
shift_expr : add_expr                   { $1               }
           | shift_expr ">>" add_expr   { ShiftRExpr $1 $3 }
           | shift_expr "<<" shift_expr { ShiftLExpr $1 $3 }

--12
add_expr : mult_expr              { $1            }
         | add_expr "+" mult_expr { AddExpr $1 $3 }
         | add_expr "-" mult_expr { SubExpr $1 $3 }
-- 13
mult_expr : unary_expr               { $1            }
          | mult_expr "*" unary_expr { MultExpr $1 $3 }
          | mult_expr "/" unary_expr { DivExpr $1 $3 }
          | mult_expr "%" unary_expr { ModExpr $1 $3 }

-- 14
unary_expr : unary_operator primary_expr  { $1 $2 }
           | primary_expr                 { $1 }

-- 15
unary_operator : "-"  { UnaryNeg }
               | "+"  { UnaryAdd }
               | "~"  { UnaryNot }

-- 16
primary_expr :: { ConstExpr }
primary_expr : scoped_name        { ExprScoped $1 }
             | literal            { ExprLiteral $1 }
             | "(" const_expr ")" { $2 }

-- 17
literal :: { Literal }
literal : integer_literal        { LitInt $1   }
        | floating_pt_literal    { LitFloat $1 }
        | fixed_pt_literal       { LitFixed $1        }
        | character_literal      { LitChar $1  }
        | wide_character_literal { LitWChar $1        }
        | boolean_literal        { LitBool $1         }
        | string_literal         { LitString $1       }
        | wide_string_literal    { LitWString $1      }

-- 18
boolean_literal : "TRUE"  { True }
                | "FALSE" { False }

-- 19
positive_int_const :: { ConstExpr }
positive_int_const : const_expr { $1 }

-- 20
type_dcl :: { TypeDcl }
type_dcl : constr_type_dcl { $1 }
         | native_dcl      { $1 }
         | typedef_dcl     { $1 }

-- 21
type_spec :: { TypeSpec }
type_spec : simple_type_spec    { $1 }
          | template_type_spec  { $1 } -- 216

-- 22
simple_type_spec :: { TypeSpec }
simple_type_spec : base_type_spec { $1  }
                 | scoped_name    { TSUser $1 }

-- 23
base_type_spec :: { TypeSpec }
base_type_spec : integer_type     { TSInt $1   }
               | floating_pt_type { TSFloat $1 }
               | char_type        { TSChar     }
               | wide_char_type   { TSWChar    }
               | boolean_type     { TSBool     }
               | octet_type       { TSOctet    }

-- 24
floating_pt_type :: { FloatingKind }
floating_pt_type : "float"          { Float32    }
                 | "double"         { Float64   }
                 | "long" "double"  { LongDouble }

-- 25
integer_type :: { IntegerKind }
integer_type : signed_int   { $1 }
             | unsigned_int { $1 }

-- 26
signed_int :: { IntegerKind }
signed_int : signed_short_int     { TInt16 }
           | signed_long_int      { TInt32 }
           | signed_longlong_int  { TInt64 }
           | signed_tiny_int      { TInt8  } -- 206
-- 27
signed_short_int : "short"  {  }
                 | "int16"  {  } -- 210

-- 28
signed_long_int : "long"  {}
                | "int32" {} -- 211

-- 29
signed_longlong_int : "long" "long" {}
                    | "int64"       {} -- 212

-- 30
unsigned_int : unsigned_short_int     { TUInt16 }
             | unsigned_long_int      { TUInt32 }
             | unsigned_longlong_int  { TUInt64 }
             | unsigned_tiny_int      { TUInt8  } -- 207

-- 31
unsigned_short_int : "unsigned" "short" {}
                   | "uint16"           {} -- 213

-- 32
unsigned_long_int : "unsigned" "long" {}
                  | "uint32"          {} -- 214

-- 33
unsigned_longlong_int : "unsigned" "long" "long" {}
                      | "uint64"                 {} -- 215

-- 34
char_type : "char" {}

-- 35
wide_char_type : "wchar" {}

-- 36
boolean_type : "boolean" {}

-- 37
octet_type : "octet" {}

-- 38
template_type_spec :: { TypeSpec }
template_type_spec : sequence_type    { $1 }
                   | string_type      { $1 }
                   | wide_string_type { $1 }
                   | fixed_pt_type    { $1 }
                   | map_type         { $1 }

-- 39
sequence_type :: { TypeSpec }
sequence_type : "sequence" "<" type_spec "," positive_int_const gt ">"  { TSSeq $3 (Just $5) }
              | "sequence" "<" type_spec gt ">"                         { TSSeq $3 Nothing   }

-- 40
string_type :: { TypeSpec }
string_type : "string" "<" positive_int_const gt ">" { TSString (Just $3) }
            | "string"                            { TSString Nothing   }

-- 41
wide_string_type :: { TypeSpec }
wide_string_type : "wstring" "<" positive_int_const gt ">" { TSWString (Just $3) }
                 | "wstring"                            { TSWString Nothing   }

-- 42
fixed_pt_type :: { TypeSpec }
fixed_pt_type : "fixed" "<" positive_int_const "," positive_int_const gt ">" { TSFixed (Just $3) (Just $5) }
              | "fixed"                                                      { TSFixed Nothing Nothing     }

-- 43
fixed_pt_const_type :: { TypeSpec }
fixed_pt_const_type : "fixed" { TSFixed Nothing Nothing }

-- 44
constr_type_dcl :: { TypeDcl }
constr_type_dcl : struct_dcl  { $1 }
                | union_dcl   { TypeUnion }
                | enum_dcl    { $1 }
                | bitmask_dcl { TypeBitmask }

-- 45
struct_dcl :: { TypeDcl }
struct_dcl : struct_def         { $1 }
           | struct_forward_def { $1 }

-- 46
struct_def :: { TypeDcl }
struct_def : "struct" identifier ":" scoped_name "{" list1(member) "}"  { TypeStruct $2 (Just $4) $6 }
           | "struct" identifier "{" list1(member) "}"                  { TypeStruct $2 Nothing $4   }

-- 47
member :: { StructMember }
member : type_spec declarators ";"  { StructMember $1 $2 }

-- 48
struct_forward_def :: { TypeDcl }
struct_forward_def : "struct" identifier  { TypeStruct $2 Nothing [] }

-- 49
union_dcl : union_def         {  }
          | union_forward_dcl {  }

-- 50
union_def : "union" identifier "switch" "(" switch_type_spec ")" "{" switch_body "}"  {}

-- 51
switch_type_spec : integer_type   {}
                 | char_type      {}
                 | boolean_type   {}
                 | scoped_name    {}
                 | wide_char_type {}
                 | octet_type     {}
-- 52
switch_body : list1(case) {}

-- 53
case : list1(case_label) element_spec ";" {}

-- 54
case_label : "case" const_expr ":"  {}
           | "default" ":"          {}

-- 55
element_spec : type_spec declarator {}

-- 56
union_forward_dcl : "union" identifier  {}

-- 57
enum_dcl : "enum" identifier "{" sep1(enumerator, ",") "}"  { TypeEnum $2 $4 }

-- 58
enumerator : identifier { $1 }

-- 59
array_declarator : identifier list1(fixed_array_size) { DeclArray $1 $2 }

-- 60
fixed_array_size : "[" positive_int_const "]" { $2 }

-- 61
native_dcl : "native" simple_declarator { TypeNative $2 }

-- 62
simple_declarator : identifier { DeclSimple $1 }

-- 63
typedef_dcl : "typedef" type_declarator { TypeTypedef $2 }

-- 64
type_declarator : simple_type_spec any_declarators   { TypeDeclarator $1 $2 }
                | template_type_spec any_declarators { TypeDeclarator $1 $2 }
                | constr_type_dcl any_declarators    { TypeConstrDeclarator $1 $2 }

-- 65
any_declarators : sep1(any_declarator, ",") { $1 }

-- 66
any_declarator : simple_declarator  { $1 }
               | array_declarator   { $1 }

-- 67
declarators :: { [Declarator] }
declarators : sep1(declarator, ",") { $1 }

-- 68
declarator : simple_declarator { $1 }
           | array_declarator  { $1 } -- 217

-- from building block extended data-types
-- 199
map_type : "map" "<" type_spec "," type_spec "," positive_int_const gt ">" { TSMap $3 $5 (Just $7) }
         | "map" "<" type_spec "," type_spec gt ">"                        { TSMap $3 $5 Nothing   }

-- 200
bitset_dcl : "bitset" identifier ":" list1(scoped_name) "{" list(bitfield) "}"  {}
           | "bitset" identifier "{" list(bitfield) "}"                         {}

--201
bitfield : bitfield_spec list(identifier) ";" {}

-- 202
bitfield_spec : "bitfield" "<" positive_int_const gt ">"                       {}
              | "bitfield" "<" positive_int_const "," destination_type gt ">"  {}

-- 203
destination_type : boolean_type {}
                 | octet_type   {}
                 | integer_type {}

-- 204
bitmask_dcl : "bitmask" identifier "{" sep1(bit_value, ",") "}" {}

-- 205
bit_value : identifier  {}

-- 208
signed_tiny_int : "int8"  {}
                
-- 209
unsigned_tiny_int : "uint8" {}

-- Happy stuff
gt :: { () }
gt : {- empty -} {%% \(T pos tc) ->
                    case tc of
                      L.ShiftRight -> pushToken (T pos L.Gt) *> pushToken (T pos L.Gt)
                      _ -> pushToken (T pos tc)
                  }

list(p)         : list1(p)            { $1 }
                |                     { [] }

list1(p)        : rev_list1(p)        { reverse $1 }

rev_list1(p)    : p                   { [$1] }
                | rev_list1(p) p      { $2 : $1 }


sep1(EXPR,SEP)
  : EXPR list(snd(SEP,EXPR))                { $1 : $2 }


snd(SEP,EXPR)
  : SEP EXPR                                { $2 }

{

type TokenStack = [Token]
type Parse = StateT TokenStack (ExceptT String L.Alex)

pushToken :: Token -> Parse ()
pushToken tc = modify $ \toks -> tc:toks

monadScan :: Parse Token
monadScan = do
  mt <- state $ \toks -> case toks of
    (tok:rest) -> (Just tok, rest)
    []         -> (Nothing, [])

  case mt of
    Just tok -> pure tok
    Nothing -> lift . lift $ L.alexMonadScan


parseError :: Token -> Parse a
parseError tok = lift . throwE $ "Parse Error: " ++ (show tok)

runParser ::Text -> Either String Specification
runParser = join <$> flip L.runAlex (runExceptT (evalStateT idlParse []))
--runParser input = evalSateT (join <$> flip L.runAlex (runExceptT idlParse) input) []

}
