{
module Idl.Lexer where
}

%wrapper "monad"
%encoding "utf-8"

-- Character class macros
@white         = [ \t\r\n]
@digit         = [0-9]
@alpha         = [a-zA-Z_]
@alphanum      = [a-zA-Z0-9_]
@identifier    = @alpha @alphanum*
@linecomment   = "//".*
@blockcomment  = "/*" ( ~[\*] | \*+ (~[\/\*] | \n) | \n )* \*+ "/"
@stringliteral = \"([^\"]|.)*\"
@integerliteral = (\-)*@digit+
@floatliteral = (\-)*@digit+\.@digit+
@charliteral  = \'@alphanum\'
tokens :-
  $white+              ;
  @linecomment         ;
  @blockcomment        ;

  -- Original keywords
  "module"             { mkT Module }
  "interface"          { mkT Interface }
  "struct"             { mkT Struct }
  "union"              { mkT Union }
  "enum"               { mkT Enum }
  "typedef"            { mkT Typedef }
  "sequence"           { mkT Sequence }

  -- Additional keywords
  "abstract"           { mkT Abstract }
  "any"                { mkT Any }
  "alias"              { mkT Alias }
  "attribute"          { mkT Attribute }
  "bitfield"           { mkT Bitfield }
  "bitmask"            { mkT Bitmask }
  "bitset"             { mkT Bitset }
  "boolean"            { mkT Boolean }
  "case"               { mkT Case }
  "char"               { mkT CharType }
  "component"          { mkT Component }
  "connector"          { mkT Connector }
  "const"              { mkT Const }
  "consumes"           { mkT Consumes }
  "context"            { mkT Context }
  "custom"             { mkT Custom }
  "default"            { mkT Default }
  "double"             { mkT DoubleType }
  "exception"          { mkT Exception }
  "emits"              { mkT Emits }
  "eventtype"          { mkT Eventtype }
  "factory"            { mkT Factory }
  "FALSE"              { mkT FalseLit }
  "finder"             { mkT Finder }
  "fixed"              { mkT Fixed }
  "float"              { mkT FloatType }
  "getraises"          { mkT GetRaises }
  "home"               { mkT Home }
  "import"             { mkT Import }
  "in"                 { mkT In }
  "inout"              { mkT InOut }
  "local"              { mkT Local }
  "long"               { mkT Long }
  "manages"            { mkT Manages }
  "map"                { mkT Map }
  "mirrorport"         { mkT MirrorPort }
  "multiple"           { mkT Multiple }
  "native"             { mkT Native }
  "Object"             { mkT ObjectType }
  "octet"              { mkT Octet }
  "oneway"             { mkT OneWay }
  "out"                { mkT Out }
  "primarykey"         { mkT PrimaryKey }
  "private"            { mkT Private }
  "port"               { mkT Port }
  "porttype"           { mkT PortType }
  "provides"           { mkT Provides }
  "public"             { mkT Public }
  "publishes"          { mkT Publishes }
  "raises"             { mkT Raises }
  "readonly"           { mkT Readonly }
  "setraises"          { mkT SetRaises }
  "short"              { mkT Short }
  "string"             { mkT StringType }
  "supports"           { mkT Supports }
  "switch"             { mkT Switch }
  "TRUE"               { mkT TrueLit }
  "truncatable"        { mkT Truncatable }
  "typeid"             { mkT TypeId }
  "typename"           { mkT TypeName }
  "typeprefix"         { mkT TypePrefix }
  "unsigned"           { mkT Unsigned }
  "uses"               { mkT Uses }
  "ValueBase"          { mkT ValueBase }
  "valuetype"          { mkT ValueType }
  "void"               { mkT Void }
  "wchar"              { mkT WChar }
  "wstring"            { mkT WString }

  "int8"               { mkT Int8 }
  "uint8"              { mkT UInt8 }
  "int16"              { mkT Int16 }
  "int32"              { mkT Int32 }
  "int64"              { mkT Int64 }
  "uint16"             { mkT UInt16 }
  "uint32"             { mkT UInt32 }
  "uint64"             { mkT UInt64 }

  -- Identifiers and literals
  @identifier          { mkT Identifier }
  @floatliteral        { mkT FloatLiteral }
  @stringliteral       { mkT StringLiteral }
  @integerliteral      { mkT IntegerLiteral }
  @charliteral         { mkT CharLiteral }
  "L" @stringliteral   { mkT WStringLiteral }
  "L" @charliteral     { mkT WCharLiteral }
  @floatliteral"D"     { mkT FixedPointLiteral }

  -- Symbols
  "::"                 { mkT ColonColon }
  "{"                  { mkT LBrace }
  "}"                  { mkT RBrace }
  "("                  { mkT LParen }
  ")"                  { mkT RParen }
  ";"                  { mkT Semicolon }
  ":"                  { mkT Colon }
  ","                  { mkT Comma }
  "="                  { mkT Equals }
  "["                  { mkT LeftBracket }
  "]"                  { mkT RightBracket }
  ">"                  { mkT Gt }
  "<"                  { mkT Lt }

  -- Catch-all
  .                    { unknown }

{


-- | Token type for OMG IDL
data TokenClass
  = Module | Interface | Struct | Union | Enum | Typedef | Sequence

  -- Additional Keywords
  | Abstract | Any | Alias | Attribute | Bitfield | Bitmask | Bitset | Boolean
  | Case | CharType | Component | Connector | Const | Consumes | Context | Custom
  | Default | DoubleType | Exception | Emits | Eventtype | Factory | FalseLit | Finder
  | Fixed | FloatType | GetRaises | Home | Import | In | InOut | Local | Long
  | Manages | Map | MirrorPort | Multiple | Native | ObjectType | Octet | OneWay
  | Out | PrimaryKey | Private | Port | PortType | Provides | Public | Publishes
  | Raises | Readonly | SetRaises | Short | StringType | Supports | Switch | TrueLit
  | Truncatable | TypeId | TypeName | TypePrefix | Unsigned | Uses | ValueBase | ValueType
  | Void | WChar | WString

  -- Extended Integer Types
  | Int8 | UInt8 | Int16 | Int32 | Int64 | UInt16 | UInt32 | UInt64

  -- Identifiers and literals
  | Identifier
  | IntegerLiteral
  | StringLiteral
  | WStringLiteral
  | FloatLiteral
  | CharLiteral
  | WCharLiteral
  | FixedPointLiteral

  -- Symbols
  | ColonColon   -- ::
  | LBrace       -- {
  | RBrace       -- }
  | LParen       -- (
  | RParen       -- )
  | Semicolon    -- ;
  | Colon        -- :
  | Comma        -- ,
  | Equals       -- =
  | LeftBracket  -- [
  | RightBracket -- ]
  | Gt           -- >
  | Lt           -- <

  | Unknown
  | Eof
  deriving (Show, Eq)

data Token = T AlexPosn TokenClass String deriving (Show)

alexEOF :: Alex Token
alexEOF = return (T undefined Eof "")

mkT :: TokenClass -> AlexInput -> Int -> Alex Token
mkT c (p,_,_,str) len = return $ T p c (take len str)

showPosn (AlexPn _ line col) = show line ++ ':': show col

unknown :: AlexInput -> Int -> Alex Token
unknown input _ = do
  alexSetInput input
  lexError "Unknown token"

lexError s = do
  (p,c,_,input) <- alexGetInput
  alexError (showPosn p ++ ": " ++ s ++
             (if (not (null input))
              then " before " ++ show (head input)
              else " at end of file"))


alexScanTokens str = runAlex str $ do
  let loop toks = do tok@(T _ cl _) <- alexMonadScan; 
		                 if cl == Eof
			            then return (toks ++ [tok])
			            else loop $ (toks ++ [tok])
  loop [] 

}

