{
Blue Bastards From Outer Space (C) 1992 Steve Goldsmith
C128 CP/M support from SG Tools (C) 1992 Parsec, Inc. and
SG Tools Pro (C) 1992 Steve Goldsmith

Main program
}

program BlueBastards;

{$A+,B+,C-,R-,U-,V-,X+}

{SG Tools include files}

{$I NUMSTR.INC}
{$I BDOS.INC}
{$I KEYIN.INC}
{$I PORT.INC}
{$I JOYSTICK.INC}
{$I SID.INC}
{$I ZBPLAY.INC}
{$I ZBFREAD.INC}
{$I ZBFMPLAY.INC}
{$I VDC.INC}
{$I VDCCONST.INC}
{$I VDCSCMGR.INC}
{$I CGFFILE.INC}
{$I VDCCGFR.INC}
{$I VDCFW.INC}
{$I VDCWIN.INC}
{$I BLUE1.INC}
{$I BLUE2.INC}
{$I BLUE3.INC}
{$I BLUE4.INC}

const

  appGameFontName = 'STDBLUE.CGF';

procedure EmptyKeyBuf;

begin
  while GetKey (bdosConInStat) <> kbNoKey do
end;

procedure Run;

var

  K : byte;

begin
  appHiScore := 0;
  repeat
    DrawDeskTop;
    PhaseIn;
    DrawDeskTop;
    FlipPageVDC;
    TitleSound;
    EmptyKeyBuf;
    K := TitleSong;
    if K = kbCtrlM then
    begin
      PhaseOut;
      InitGame;
      SetVolume (appVol);
      EmptyKeyBuf;
      repeat
        JoyControl;
        MoveBastards;
        MoveRepairShip;
        FlipPageVDC
      until (GetKey (bdosConInStat) = kbEsc) or
      (appLasersLeft = 0);
      if appLasersLeft = 0 then
        KillBaseSound;
      ClearSID;
      PhaseOut
    end
  until K = kbEsc;
  PhaseOut
end;

procedure Init;

var

  I : byte;

begin
  ClearSID;
  InitVDC; {fire up screen manager}
  Writeln;
  Writeln ('Blue Bastards From Outer Space (C) 1992 Steve Goldsmith');
  Writeln;
  Writeln ('Loading new font...');
  ReadFontFile (appGameFontName,false);
  InitMultiPlay;
  Writeln;
  Writeln ('Loading guitar chords...');
  Writeln;
  for I := 0 to appMaxChordName do
  begin
    Writeln (appChordNameArr[I]);
    AddMultiPlay (appChordNameArr[I])
  end;
  Writeln;
  Writeln ('Loading voice files...');
  Writeln;
  for I := 0 to appMaxName do
  begin
    Writeln (appNameArr[I]);
    AddMultiPlay (appNameArr[I])
  end;
  SetScrColVDC (appScrColor,appScrColor); {set app screen color}
  SetCursorVDC (0,0,vdcCurNone); {turn cursor off}
  FlipPageVDC {now fast writes go to non-viewable page}
end;

procedure Done;

begin
  ClearSID;
  DoneMultiPlay;
  ClrScrVDC (32);        {prepare screen for return to cp/m}
  ClrAttrVDC (vdcAltChrSet+vdcWhite);
  FlipPageVDC;
  DoneVDC;               {were finished with the screen manager}
  SetVolume (appMaxVol);
  EmptyKeyBuf
end;

begin
  Init;
  Run;
  Done
end.
