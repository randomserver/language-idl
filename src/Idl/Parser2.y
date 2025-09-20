{
module Idl.Parser2 where

import qualified Idl.Lexer as L
import Idl.Lexer (Token, Token(..))
import Idl.Ast2
import Control.Monad
import Control.Monad.Trans.Except
import Control.Monad.Trans.Class (lift)

}

%name idlParse
%tokentype { Token }
%error { parseError }

%lexer { lift L.alexMonadScan >>= } { T _ L.Eof _ }
%monad { Parse } 

%token
  -- OMG IDL Keywords
  "module"             { T _ L.Module _ }
  "interface"          { T _ L.Interface _ }
  "struct"             { T _ L.Struct _ }
  "union"              { T _ L.Union _ }
  "enum"               { T _ L.Enum _ }
  "typedef"            { T _ L.Typedef _ }
  "sequence"           { T _ L.Sequence _ }

  -- Additional Keywords
  "abstract"           { T _ L.Abstract _ }
  "any"                { T _ L.Any _ }
  "alias"              { T _ L.Alias _ }
  "attribute"          { T _ L.Attribute _ }
  "bitfield"           { T _ L.Bitfield _ }
  "bitmask"            { T _ L.Bitmask _ }
  "bitset"             { T _ L.Bitset _ }
  "boolean"            { T _ L.Boolean _ }
  "case"               { T _ L.Case _ }
  "char"               { T _ L.CharType _ }
  "component"          { T _ L.Component _ }
  "connector"          { T _ L.Connector _ }
  "const"              { T _ L.Const _ }
  "consumes"           { T _ L.Consumes _ }
  "context"            { T _ L.Context _ }
  "custom"             { T _ L.Custom _ }
  "default"            { T _ L.Default _ }
  "double"             { T _ L.DoubleType _ }
  "exception"          { T _ L.Exception _ }
  "emits"              { T _ L.Emits _ }
  "eventtype"          { T _ L.Eventtype _ }
  "factory"            { T _ L.Factory _ }
  "FALSE"              { T _ L.FalseLit _ }
  "finder"             { T _ L.Finder _ }
  "fixed"              { T _ L.Fixed _ }
  "float"              { T _ L.FloatType _ }
  "getraises"          { T _ L.GetRaises _ }
  "home"               { T _ L.Home _ }
  "import"             { T _ L.Import _ }
  "in"                 { T _ L.In _ }
  "inout"              { T _ L.InOut _ }
  "local"              { T _ L.Local _ }
  "long"               { T _ L.Long _ }
  "manages"            { T _ L.Manages _ }
  "map"                { T _ L.Map _ }
  "mirrorport"         { T _ L.MirrorPort _ }
  "multiple"           { T _ L.Multiple _ }
  "native"             { T _ L.Native _ }
  "Object"             { T _ L.ObjectType _ }
  "octet"              { T _ L.Octet _ }
  "oneway"             { T _ L.OneWay _ }
  "out"                { T _ L.Out _ }
  "primarykey"         { T _ L.PrimaryKey _ }
  "private"            { T _ L.Private _ }
  "port"               { T _ L.Port _ }
  "porttype"           { T _ L.PortType _ }
  "provides"           { T _ L.Provides _ }
  "public"             { T _ L.Public _ }
  "publishes"          { T _ L.Publishes _ }
  "raises"             { T _ L.Raises _ }
  "readonly"           { T _ L.Readonly _ }
  "setraises"          { T _ L.SetRaises _ }
  "short"              { T _ L.Short _ }
  "string"             { T _ L.StringType _ }
  "supports"           { T _ L.Supports _ }
  "switch"             { T _ L.Switch _ }
  "TRUE"               { T _ L.TrueLit _ }
  "truncatable"        { T _ L.Truncatable _ }
  "typeid"             { T _ L.TypeId _ }
  "typename"           { T _ L.TypeName _ }
  "typeprefix"         { T _ L.TypePrefix _ }
  "unsigned"           { T _ L.Unsigned _ }
  "uses"               { T _ L.Uses _ }
  "ValueBase"          { T _ L.ValueBase _ }
  "valuetype"          { T _ L.ValueType _ }
  "void"               { T _ L.Void _ }
  "wchar"              { T _ L.WChar _ }
  "wstring"            { T _ L.WString _ }

  -- Extended Integer Types
  "int8"               { T _ L.Int8 _ }
  "uint8"              { T _ L.UInt8 _ }
  "int16"              { T _ L.Int16 _ }
  "int32"              { T _ L.Int32 _ }
  "int64"              { T _ L.Int64 _ }
  "uint16"             { T _ L.UInt16 _ }
  "uint32"             { T _ L.UInt32 _ }
  "uint64"             { T _ L.UInt64 _ }

  -- Identifiers and Literals
  identifier              { T _ L.Identifier $$     }
  integer_literal         { T _ L.IntegerLiteral $$ }
  floating_pt_literal     { T _ L.FloatLiteral $$   }
  string_literal          { T _ L.StringLiteral $$  }
  character_literal       { T _ L.CharLiteral $$    }
  wide_string_literal     { T _ L.WStringLiteral $$ }
  wide_character_literal  { T _ L.WCharLiteral $$ }
  fixed_pt_literal        { T _ L.FixedPointLiteral $$ }

  -- Symbols
  "{"                  { T _ L.LBrace _ }
  "}"                  { T _ L.RBrace _ }
  "("                  { T _ L.LParen _ }
  ")"                  { T _ L.RParen _ }
  ";"                  { T _ L.Semicolon _ }
  ":"                  { T _ L.Colon _ }
  ","                  { T _ L.Comma _ }
  "="                  { T _ L.Equals _ }
  "["                  { T _ L.LeftBracket _ }
  "]"                  { T _ L.RightBracket _ }
  "::"                 { T _ L.ColonColon _ }
  ">"                  { T _ L.Gt _ }
  "<"                  { T _ L.Lt _ }

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
const_expr : primary_expr { $1 }

-- 16
primary_expr :: { ConstExpr }
primary_expr : scoped_name { ExprScoped $1 }
             | literal     { ExprLiteral $1 }

-- 17
literal :: { Literal }
literal : integer_literal        { LitInt (read $1)   }
        | floating_pt_literal    { LitFloat (read $1) }
        | fixed_pt_literal       { LitFixed $1        }
        | character_literal      { LitChar (read $1)  }
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
sequence_type : "sequence" "<" type_spec "," positive_int_const ">" { TSSeq $3 (Just $5) }
              | "sequence" "<" type_spec ">"                        { TSSeq $3 Nothing   }

-- 40
string_type :: { TypeSpec }
string_type : "string" "<" positive_int_const ">" { TSString (Just $3) }
            | "string"                            { TSString Nothing   }

-- 41
wide_string_type :: { TypeSpec }
wide_string_type : "wstring" "<" positive_int_const ">" { TSWString (Just $3) }
                 | "wstring"                            { TSWString Nothing   }

-- 42
fixed_pt_type :: { TypeSpec }
fixed_pt_type : "fixed" "<" positive_int_const "," positive_int_const ">" { TSFixed (Just $3) (Just $5) }
              | "fixed"                                                   { TSFixed Nothing Nothing     }

-- 43
fixed_pt_const_type :: { TypeSpec }
fixed_pt_const_type : "fixed" { TSFixed Nothing Nothing }

-- 44
constr_type_dcl :: { TypeDcl }
constr_type_dcl : struct_dcl  { $1 }
                | union_dcl   { TypeUnion }
                | enum_dcl    { TypeEnum }
                | bitmask_dcl { TypeBitmask }

-- 45
struct_dcl :: { TypeDcl }
struct_dcl : struct_def         { $1 }
           | struct_forward_def { $1 }

-- 46
struct_def :: { TypeDcl }
struct_def : "struct" identifier ":" scoped_name "{" list1(member) "}"  { TypeStruct $2 (Just $4) $6 }
           | "struct" identifier "{" list1(member) "}"                  { TypeStruct $2 Nothing $4           }

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
enum_dcl : "enum" identifier "{" sep1(enumerator, ",") "}"  {}

-- 58
enumerator : identifier {}

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
map_type : "map" "<" type_spec "," type_spec "," positive_int_const ">" { TSMap $3 $5 (Just $7) }
         | "map" "<" type_spec "," type_spec ">"                        { TSMap $3 $5 Nothing   }

-- 200
bitset_dcl : "bitset" identifier ":" list1(scoped_name) "{" list(bitfield) "}"  {}
           | "bitset" identifier "{" list(bitfield) "}"                         {}

--201
bitfield : bitfield_spec list(identifier) ";" {}

-- 202
bitfield_spec : "bitfield" "<" positive_int_const ">"                       {}
              | "bitfield" "<" positive_int_const "," destination_type ">"  {}

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

type Parse = ExceptT String L.Alex

parseError :: Token -> Parse a
parseError tok = throwE $ "Parse Error: " ++ (show tok)

runParser :: String -> Either String Specification
runParser = join <$> flip L.runAlex (runExceptT idlParse)

}
