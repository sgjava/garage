{
Load CGF (C) 1992 Steve Goldsmith
Load CGFs into VDC memory

Call as: LOADCGF FILENAME SET
}

program LoadCGF;

{$B-,C-,R-,U-,V-}

{SG Tools include files}

{$I PORT.INC}
{$I VDC.INC}
{$I VDCCONST.INC}
{$I VDCSCMGR.INC}
{$I BDOS.INC}
{$I CGFFILE.INC}
{$I VDCCGFR.INC}

const

  appClrChar = 32; {character used to clear screen}
  appScrColor = vdcBlack; {screen color}
  appStdStr = 'STD';
  appAltStr = 'ALT';
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
  Writeln ('Usage: LOADCGF FILENAME SET');
  Writeln;
  Writeln ('FILENAME =    1 to   8 character file name without .CGF extension');
  Writeln ('SET      =  STD or ALT for STanDard or ALTernate character set')
end;

procedure DispTitle;

begin
  Writeln;
  Writeln ('Load CGF 1.0 (C) 1992 Steve Goldsmith');
  Writeln ('C128 CP/M version 11/29/92')
end;

function GetParams : boolean;

var

  ValCode : integer;

begin
  appFileName := '';
  appChrSet := '';
  GetParams := false;
  if ParamCount = 2 then
  begin
    appFileName := ParamStr (1);
    if (Length (appFileName) >= appFileNameMin) and
    (Length (appFileName) <= appFileNameMax) then
    begin
      appFileName := appFileName+'.CGF';
      appChrSet := ParamStr (2);
      if (appChrSet = appStdStr) or (appChrSet = appAltStr) then
        GetParams := true
    end
  end
end;

procedure Run;

begin
  Writeln;
  Writeln ('Reading ',appFileName,'...');
  if appChrSet = appStdStr then
    ReadFontFile (appFileName,false)
  else
    ReadFontFile (appFileName,true);
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
