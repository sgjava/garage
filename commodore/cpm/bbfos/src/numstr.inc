{
SG Tools (C) 1992 Parsec, Inc.

The number string module converts bytes and integers to strings
}

type

  strByte = string[3];
  strInteger = string[6];

function ByteStr (B : byte) : strByte;

var

  TempStr : StrByte;

begin
  Str (B:3,TempStr);
  ByteStr := TempStr
end;

function IntStr (I : integer) : strInteger;

var

  TempStr : StrInteger;

begin
  Str (I:6,TempStr);
  IntStr := TempStr
end;
