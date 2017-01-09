{
Z Blaster Recorder (C) 1992 Steve Goldsmith
Program to record ZBF's from a Covox Voice Master.

Call as: ZBREC FILENAME SIZE HZ
}
program ZBRec;

{$B-,C-,R-,U-,V-}

{SG Tools Pro include files}

{$I PORT.INC}
{$I SID.INC}
{$I BDOS.INC}
{$I KEYIN.INC}
{$I ZBPLAY.INC}
{$I ZBREC.INC}
{$I ZBFREAD.INC}
{$I ZBFWRITE.INC}

const

  vicContReg1 = $d011; {vic control reg 1}
  timRes = 10227; {cia timer a resolution div 100}
  appSizeMax = 32767; {max digitized data size}
  appHzMin = 4000;  {min record hz}
  appHzMax = 17000; {max record hz}

var

  appSize,
  appHz : integer;
  appFileName : bdosPathStr;

procedure SetZBFHeader (DataSize, Hertz : integer);

begin
  with zbfHeader^ do
  begin
    Version := zbfVersion;
    Compress := 0;
    SamBits := 1;
    Delay := timRes div (Hertz div 100);
    SizeLo := DataSize;
    SizeHi := 0;
    Hz := Hertz;
    FillChar (Filler,SizeOf (Filler),0)
  end
end;

procedure RecordZB;

var

  BlankSts : byte;
  I : byte;

begin
  for I := 10 downto 1 do
  begin
    Delay (500);
    Writeln (I)
  end;
  Writeln;
  Writeln ('Recording...');
  SetCIA2TimerA (timRes div (zbfHeader^.Hz div 100));
  BlankSts := PortIn (vicContReg1) and $10;
  PortOut (vicContReg1,PortIn (vicContReg1) and $ef);
  Inline ($F3); {di                      ;disable hardware interrupt}
  InitVoiceMaster;
  RecVoiceMaster (Addr (zbfSamplePtr^), zbfHeader^.SizeLo);
  DoneVoiceMaster;
  Inline ($FB); {ei                      ;enable hardware interrupt}
  PortOut (vicContReg1,PortIn (vicContReg1) or BlankSts)
end;

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

procedure WriteZB;

begin
  InitWriteZBF (appFileName);
  if zbfwError = 0 then
  begin
    Writeln;
    Writeln ('Saving ',appFileName,'...');
    WriteZBFHeader;
    WriteZBFData
  end
  else
    Writeln ('ZBF write error',zbfwError:7);
  DoneWriteZBF
end;

procedure DispHelp;

begin
  Writeln;
  Writeln ('Usage: ZBREC FILENAME SIZE HZ');
  Writeln;
  Writeln ('FILENAME =    1 to     8 character file name without .ZBF extension');
  Writeln ('SIZE     =  128 to 32640 bytes');
  Writeln ('HZ       = 4000 to 17000 Hz')
end;

procedure DispTitle;

begin
  Writeln;
  Writeln ('Z Blaster Recorder 1.1 (C) 1992 Steve Goldsmith');
  Writeln ('C128 CP/M version 10/09/92')
end;

function GetParams : boolean;

var

  ValCode : integer;

begin
  appFileName := '';
  appSize := 0;
  appHz := 0;
  GetParams := false;
  if ParamCount = 3 then
  begin
    appFileName := ParamStr (1);
    if (Length (appFileName) > 0) and
    (Length (appFileName) < 9) then
    begin
      appFileName := appFileName+zbfExt;
      Val (ParamStr (2),appSize,ValCode);
      appSize := (appSize div zbfBlockSize)*zbfBlockSize;
      if (appSize > 0) and (appSize <= appSizeMax) then
      begin
        Val (ParamStr (3),appHz,ValCode);
        if (appHz >= appHzMin) and
        (appHz <= appHzMax) then
        begin
          appHz := (timRes div (timRes div (appHz div 100)))*100;
          GetParams := true
        end
      end
    end
  end
end;

procedure Init;

begin
  ClearSID;
  zbfSamplePtr := nil;
  zbfHeader := nil;
  New (zbfHeader);
  SetZBFHeader (appSize,appHz);
  GetMem (zbfSamplePtr,zbfHeader^.SizeLo);
end;

procedure OptionLine;

var

  C : char;

begin
  repeat
    Writeln;
    Writeln ('Ready to record ',appFileName,',',appSize:7,' bytes,',appHz:6,' Hz.');
    Writeln;
    Write ('[SPACE BAR] to record, [p]lay, [y]es to save or [ESC] to exit: ');
    C := Chr (GetKey (bdosConIn));
    Writeln (C);
    case C of
      ' ' : RecordZB;
      'p' : PlayZB;
      'y' : WriteZB
    end
  until C = Chr (kbEsc)
end;

procedure Run;

begin
  Writeln;
  Writeln ('Plug Covox Voice Master in control port 2!');
  OptionLine;
  Writeln;
  Writeln ('Unplug Covox Voice Master!')
end;

procedure Done;

begin
  ClearSID;
  if zbfHeader <> nil then
    Dispose (zbfHeader);
  if zbfSamplePtr <> nil then
    FreeMem (zbfSamplePtr,zbfHeader^.SizeLo)
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
