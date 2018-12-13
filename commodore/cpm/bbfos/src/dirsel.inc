{
SG Tools (C) 1992 Parsec, Inc.

Directory Selector uses a VDC window to select a CP/M file from the currently
logged disk.
}

const

  dselXSize   = 16; {window size}
  dselYSize   = 15;
  dselCurSize = 14;

var

  dselX1, dselY1, dselX2, dselY2,
  dselCY, dselAttr : byte;
  dselCurPtr : dirPRec;

procedure DispDir;

var

  X, Y : byte;

begin              {fill window with file names}
  X := dselX1+2;
  Y := dselY1+2;
  repeat
    FWriteVDC (X,Y,dselAttr,GetFileName);
    Y := Y+1
  until (dirCurPtr = nil) or
  (Y = dselY2-2)
end;

procedure DispCur (A : byte);

begin               {draw cursor}
  FillAttrVDC (dselX1+1,dselCY,dselCurSize,A);
end;

procedure ScrollUpDir;

begin              {scroll window up}
  ScrollUpVDC (dselX1+1,dselY1+3,
  dselX2-1,dselY2-3);
  FWriteVDC (dselX1+2,dselY2-3,
  dselAttr,dselCurPtr^.FileName)
end;

procedure ScrollDownDir;

begin              {scroll window down}
  ScrollDownVDC (dselX1+1,dselY1+2,
  dselX2-1,dselY2-4);
  FWriteVDC (dselX1+2,dselY1+2,
  dselAttr,dselCurPtr^.FileName)
end;

procedure MoveCurUp;

begin            {move cursor up}
  DispCur (dselAttr);
  if (dselCurPtr^.Prev <> nil) and
  (dselCY > dselY1+1) then
  begin
    dselCurPtr := dselCurPtr^.Prev;
    if dselCY = dselY1+2 then
      ScrollDownDir
    else
      dselCY := dselCY-1
  end;
  DispCur (vdcRvsVid+dselAttr);
  FlipPageVDC
end;

procedure MoveCurDown;

begin            {move cursor down}
  DispCur (dselAttr);
  if (dselCurPtr^.Next <> nil) and
  (dselCY < dselY2-2) then
  begin
    dselCurPtr := dselCurPtr^.Next;
    if dselCY = dselY2-3 then
      ScrollUpDir
    else
      dselCY := dselCY+1
  end;
  DispCur (vdcRvsVid+dselAttr);
  FlipPageVDC
end;

function SelFileName : bdosPathStr;

var

  C, J : byte;

begin
  repeat
    C := GetKey (bdosConInStat);
    case C of
      kbCtrlE : MoveCurUp;
      kbCtrlX : MoveCurDown
    end;
    J := ReadJoy2;
    case J of
      joyUp   : MoveCurUp;
      joyDown : MoveCurDown
    end
  until (C = kbCtrlM) or
  (C = kbEsc) or (J = joyFire);
  if (C = kbCtrlM) or (J = joyFire) then
    SelFileName := PackName (dselCurPtr^.FileName)
  else
    SelFileName := ''
end;

procedure InitDirSel (X1,Y1,A : byte;
                      WildCard : bdosPathStr);

begin
  InitDir (                {read dir of default drive/user}
  BDos (bdosCurrentDisk),
  BDos (bdosUserCode,$ff),
  WildCard);
  if dirError = 0 then
  begin
    ReadDir;
    if dirRecs > 0 then
    begin
      dirCurPtr := dirFirstPtr;
      dselCurPtr := dirFirstPtr;
      dselX1 := X1;
      dselY1 := Y1;
      dselX2 := X1+dselXSize-1;
      dselY2 := Y1+dselYSize-1;
      dselCY := Y1+2;
      dselAttr := A;
      DrawWinVDC (dselX1,dselY1,dselX2,dselY2,dselAttr,
      Chr (dirCurDrive+65)+Chr (dirCurUser+48)+':');
      FWriteVDC (dselX1+1,dselY2-1,
      vdcAltChrSet+vdcWhite,IntStr (dirRecs)+' Files');
      DispDir;
      DispCur (dselAttr+vdcRvsVid)
    end
  end
end;

procedure DoneDirSel;

begin
  DoneDir
end;
