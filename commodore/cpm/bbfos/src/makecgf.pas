{
Make CGF (C) 1992 Steve Goldsmith
Create CGFs from VDC memory

Call as: MAKECGF FILENAME STD START TOTAL
}

program MakeCGF;

{$B-,C-,R-,U-,V-}

{SG Tools include files}

{$I PORT.INC}
{$I VDC.INC}
{$I VDCCONST.INC}
{$I VDCSCMGR.INC}
{$I BDOS.INC}
{$I CGFFILE.INC}
{$I VDCCGFR.INC}
{$I VDCCGFW.INC}

const

  appClrChar = 32; {character used to clear screen}
  appScrColor = vdcBlack; {screen color}
  appStdStr = 'STD';
  appAltStr = 'ALT';
  appStartMin = 0;
  appStartMax = 255;
  appTotalMin = 1;
  appTotalMax = 256;
  appFileNameMin = 1;
  appFileNameMax = 8;
  appChrHeight = 8;

type

  appSetStr = string[3];

var

  appStart,
  appTotal : integer;
  appChrSet : appSetStr;
  appFileName : bdosPathStr;

procedure Init;

begin
  InitVDC {fire up screen manager}
end;

procedure DispHelp;

begin
  Writeln;
  Writeln ('Usage: MAKECGF FILENAME SET START TOTAL');
  Writeln;
  Writeln ('FILENAME =    1 to   8 character file name without .CGF extension');
  Writeln ('SET      =  STD or ALT for STanDard or ALTernate character set');
  Writeln ('START    =    0 to 255 for starting character code');
  Writeln ('TOTAL    =    1 to 256 characters')
end;

procedure DispTitle;

begin
  Writeln;
  Writeln ('Make CGF 1.0 (C) 1992 Steve Goldsmith');
  Writeln ('C128 CP/M version 11/29/92')
end;

function GetParams : boolean;

var

  ValCode : integer;

begin
  appFileName := '';
  appChrSet := '';
  appStart := 0;
  appTotal := 0;
  GetParams := false;
  if ParamCount = 4 then
  begin
    appFileName := ParamStr (1);
    if (Length (appFileName) >= appFileNameMin) and
    (Length (appFileName) <= appFileNameMax) then
    begin
      appFileName := appFileName+'.CGF';
      appChrSet := ParamStr (2);
      if (appChrSet = appStdStr) or (appChrSet = appAltStr) then
      begin
        Val (ParamStr (3),appStart,ValCode);
        if (appStart >= appStartMin) and
        (appStart <= appStartMax) then
        begin
          Val (ParamStr (4),appTotal,ValCode);
          if (appTotal >= appTotalMin) and
          (appTotal <= appTotalMax) then
            GetParams := true
        end
      end
    end
  end
end;

procedure Run;

begin
  Writeln;
  Writeln ('Writing ',appFileName,', Starting chr code:',
  appStart:4,', Total chrs:',appTotal:4);
  if appChrSet = appStdStr then
    WriteFontFile (appFileName,appChrHeight,appStart,appTotal,false)
  else
    WriteFontFile (appFileName,appChrHeight,appStart,appTotal,true);
  if cgfIoError <> 0 then
    Writeln ('CGF Error:',cgfIoError:6)
end;

procedure Done;

begin
  DoneVDC {we're finished with the screen manager}
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
