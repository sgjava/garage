{
Z Blaster Player (C) 1992 Steve Goldsmith

Call as: ZBPLAY FILENAME
}
program ZBPlay;

{$B-,C-,R-,U-,V-}

{SG Tools Pro include files}

{$I HEXSTR.INC}
{$I PORT.INC}
{$I SID.INC}
{$I BDOS.INC}
{$I KEYIN.INC}
{$I ZBPLAY.INC}
{$I ZBFREAD.INC}

const

  vicContReg1 = $d011; {vic control reg 1}
  timRes = 10227; {cia timer a resolution div 100}
  appSizeMax = 32767; {max digitized data size}
  appHzMin = 4000;  {min record hz}
  appHzMax = 17000; {max record hz}

var

  appFileName : bdosPathStr;

procedure PlayZB;

var

  BlankSts : byte;

begin
  Writeln;
  Writeln ('Playing...');
  SetCIA2TimerA (timRes div (zbfHeader^.Hz div 100));
  BlankSts := PortIn (vicContReg1) and $10;
  PortOut (vicContReg1,PortIn (vicContReg1) and $ef);
  Inline ($F3); {di                      ;disable hardware interrupt}
  PlaySample (Addr (zbfSamplePtr^), zbfHeader^.SizeLo,15);
  Inline ($FB); {ei                      ;enable hardware interrupt}
  PortOut (vicContReg1,PortIn (vicContReg1) or BlankSts);
  SetVolume (0)
end;

procedure DispHelp;

begin
  Writeln;
  Writeln ('Usage: ZBPLAY FILENAME');
  Writeln;
  Writeln ('FILENAME = 1 to 8 character file name without .ZBF extension')
end;

procedure DispTitle;

begin
  Writeln;
  Writeln ('Z Blaster Player 1.1 (C) 1992 Steve Goldsmith');
  Writeln ('C128 CP/M version 10/09/92')
end;

function GetParams : boolean;

var

  ValCode : integer;

begin
  appFileName := '';
  GetParams := false;
  if ParamCount = 1 then
  begin
    appFileName := ParamStr (1);
    if (Length (appFileName) > 0) and
    (Length (appFileName) < 9) then
    begin
      appFileName := appFileName+zbfExt;
      GetParams := true
    end
  end
end;

procedure Init;

begin
  ClearSID;
  InitReadZBF (appFileName);
  if zbfError = 0 then
    ReadZBFData
  else
    Writeln ('ZBF read error',zbfError:7)
end;

procedure OptionLine;

var

  C : char;

begin
  repeat
    Writeln;
    Writeln (appFileName,', version ',
    HexByteStr (Hi (zbfHeader^.Version)),'.',
    HexByteStr (Lo (zbfHeader^.Version)),',',
    zbfHeader^.SamBits:2,' bit,',
    zbfHeader^.SizeLo:7,' bytes,',
    zbfHeader^.Hz:7,' Hz');
    Writeln;
    Write ('[p]lay or [ESC] to exit: ');
    C := Chr (GetKey (bdosConIn));
    Writeln (C);
    case C of
      'p' : PlayZB
    end
  until C = Chr (kbEsc)
end;

procedure Run;

begin
  if zbfError = 0 then
    OptionLine
end;

procedure Done;

begin
  ClearSID;
  DoneReadZBF (true)
end;

begin
  DispTitle;
  if GetParams then
  begin
    Init;
    Run;
    Done
  end
  else
    DispHelp
end.
