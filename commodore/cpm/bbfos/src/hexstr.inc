{
SG Tools (C) 1992 Parsec, Inc.

The hex string module converts bytes and integers to hex strings
}

type

  HexByte = string[2];
  HexWord = string[4];

function HexByteStr (B : byte) : HexByte;

  function HexNibble (N : byte) : char;

  begin
    if N < $0a then
      HexNibble := Chr (48+N)
    else
      HexNibble := Chr (55+N)
  end;

begin
  HexByteStr :=
  HexNibble (B shr 4)+
  HexNibble (B and $0f)
end;

function HexWordStr (W : integer) : HexWord;

begin
  HexWordStr :=
  HexByteStr (Hi (W))+
  HexByteStr (Lo (W))
end;
