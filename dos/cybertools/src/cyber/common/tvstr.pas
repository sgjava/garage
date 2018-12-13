{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Non-OOP string library for Turbo Vision apps.
}

unit TVStr;

{$I APP.INC}

interface

uses

  Dos, Drivers;

const

  strDoubleMax : extended = 1.7e308; {max double for range check}
  strDoubleMin : extended = 5e-324;  {min double for range check}

function IntToStr (L : longint) : string;
function IntToRightStr (L : longint; Places : integer) : string;
function StrToInt (S : string) : longint;
function DblToStr (D : double; L,R : integer) : string;
function StrToDbl (S : string) : double;
function TrimStr (S : string) : string;
function UpCaseStr (S : string) : string;
function ExtStrPos (S : string; var ExtPos : word) : boolean;
function AddExtStr (S,E : string) : string;
function GetExtStr (S : string) : string;
function GetFileNameStr (S : string) : string;
function FillStr (C : char; L : integer) : string;
function PadRightStr (S : string; C : char; L : integer) : string;
function PadLeftStr (S : string; C : char; L : integer) : string;
function TimeStr : string;
function DateStr : string;

implementation

{
Convert longint into a left justified string.
}

function IntToStr (L : longint) : string;

var

  S : string;

begin
  Str (L,S);
  IntToStr := S
end;

{
Convert longint into a right justified string.
}

function IntToRightStr (L : longint; Places : integer) : string;

var

  S : string;

begin
  Str (L:Places,S);
  IntToRightStr := S
end;

{
Convert string to longint.
}

function StrToInt (S : string) : longint;

var

  NumErr : integer;
  L : longint;

begin
  Val (S,L,NumErr);
  StrToInt := L
end;

{
Convert double into a left justified string.
}

function DblToStr (D : double; L,R : integer) : string;

var

  S : string;

begin
  Str (D:L:R,S);
  DblToStr := S
end;

{
Convert string to double.  Convert error returns 0.0.
}

function StrToDbl (S : string) : double;

var

  NumErr : integer;
  E : extended;

begin
  Val (S,E,NumErr);
  if ((Abs (E) >= strDoubleMin) and  {double range test}
  (Abs (E) <= strDoubleMax)) then
    StrToDbl := E
  else
    StrToDbl := 0.0
end;

{
Trim leading and trailing chars <= ' ' in string.
}

function TrimStr (S : string) : string;

var

  I : word;

begin
  while (byte (S[0]) > 0) and (S[byte (S[0])] <= ' ') do
    Dec (byte (S[0]));   {trim from end by dec length code}
  I := 1;
  while (I <= byte (S[0])) and (S[I] <= ' ') do
    Inc (I);             {scan from start until char > ' '}
  Dec (I);
  if I > 0 then
    Delete (S, 1, I);    {delete from start to last char <= ' '}
  TrimStr := S
end;

{
Convert alpha chars to upper case.
}

function UpCaseStr (S : string) : string;

var

  I : integer;

begin
  for I := 1 to byte (S[0]) do
    S[I] := UpCase (S[I]);
  UpCaseStr := S
end;

{
Return position of extension from DOS path string.
}

function ExtStrPos (S : string; var ExtPos : word) : boolean;

var

  I : word;

begin
  ExtPos := 0;
  for I := byte(S[0]) downto 1 do          {search backwards for '.'}
    if (S[I] = '.') and (ExtPos = 0) then
      ExtPos := I;                         {'.' found, so assign pos}
  ExtStrPos := (ExtPos > 0) and
  (Pos ('\', Copy (S,Succ (ExtPos),
  SizeOf (PathStr)-1)) = 0)                {'.\' is not a valid ext}
end;

{
Return DOS path string with a user defined extension
}

function AddExtStr (S,E : string) : string;

var

  ExtPos : word;

begin
  if ExtStrPos (S,ExtPos) then
    AddExtStr := Copy (S,1,ExtPos)+E
  else
    AddExtStr := S+'.'+E
end;

{
Return only extension name from path.
}

function GetExtStr (S : string) : string;

var

  N : PathStr;
  D : DirStr;
  E : ExtStr;

begin
  FSplit (S,D,N,E);
  GetExtStr := E
end;

{
Return only file name from path.
}

function GetFileNameStr (S : string) : string;

var

  N : PathStr;
  D : DirStr;
  E : ExtStr;

begin
  FSplit (S,D,N,E);
  GetFileNameStr := N
end;

{
Make string of repeating chars.
}

function FillStr (C : char; L : integer) : string;

var

  S : string;

begin
  FillChar (S[1],L,byte (C));
  byte (S[0]) := L;
  FillStr := S
end;

{
Pad string.
}

function PadRightStr (S : string; C : char; L : integer) : string;

var

  I, SChar : integer;

begin
  SChar := byte(S[0])+1;
  for I := SChar to L do
    S[I] := C;
  byte (S[0]) := L;
  PadRightStr := S
end;

{
Pad string.
}

function PadLeftStr (S : string; C : char; L : integer) : string;

var

  SChar : integer;
  TempStr : string;

begin
  SChar := L-byte(S[0]);
  FillChar (TempStr[1],SChar,byte (C));
  byte (TempStr[0]) := SChar;
  PadLeftStr := TempStr+S
end;

{
Return system time in HH:MM:SS string.
}

function TimeStr : string;

var


  TimeArr : array [0..2] of longint;
  H, M, S, Hund : word;
  TStr : string[8];

begin
  GetTime (H,M,S,Hund);
  TimeArr[0] := H;
  TimeArr[1] := M;
  TimeArr[2] := S;
  FormatStr (TStr,'%02d:%02d:%02d',TimeArr); {0 fill single digits}
  TimeStr := TStr
end;

{
Return system date in MM/DD/YYYY string.
}

function DateStr : string;

var

  DateArr : array[0..2] of longint;
  Y, M, D, Dow : word;
  DStr : string[10];

begin
  GetDate (Y,M,D,Dow);
  DateArr[0] := M;
  DateArr[1] := D;
  DateArr[2] := Y;
  FormatStr (DStr,'%02d/%02d/%04d',DateArr); {0 fill single digits}
  DateStr := DStr
end;

end.
