{
SG Tools (C) 1992 Parsec, Inc.

File View allows you to view a text file in a VDC window.
}

var

  fvX1, fvY1, fvX2, fvY2, fvCol,
  fvXSize, fvYSize, fvAttr : byte;
  fvCurPtr, fvTopPtr, fvBtmPtr : rtfPLine;

{return line with current column offset}

function DispLine (Old : rtfStr) : rtfStr;

begin
  if Length (Old) >= fvCol then
    Old := Copy (Old,fvCol,fvXSize-2)
  else
    Old := '';
  DispLine := Old
end;

{fill window with lines starting at current line pointer}

procedure DispWin;

var

  X, Y : byte;
  S : rtfStr;

begin
  Y := fvY1+1;
  X := fvX1+1;
  repeat
    S := DispLine (GetLine);
    if S <> '' then
      FWriteVDC (X,Y,fvAttr,S);
    Y := Y+1
  until (rtfCurPtr = nil) or
        (Y = fvY2)
end;

procedure MoveUpLine;

begin
  if fvTopPtr^.Prev <> nil then
  begin
    fvTopPtr := fvTopPtr^.Prev;
    fvBtmPtr := fvBtmPtr^.Prev;
    fvCurPtr := fvTopPtr;
    ScrollDownVDC (fvX1+1,fvY1+1,
    fvX2-1,fvY2-2);
    FillDispVDC (fvX1+1,fvY1+1,
    fvXSize-2,32);
    FWriteVDC (fvX1+1,fvY1+1,
    fvAttr,DispLine (fvCurPtr^.Line^));
    FlipPageVDC
  end
end;

procedure MoveDownLine;

begin
  if fvBtmPtr^.Next <> nil then
  begin
    fvTopPtr := fvTopPtr^.Next;
    fvBtmPtr := fvBtmPtr^.Next;
    fvCurPtr := fvBtmPtr;
    ScrollUpVDC (fvX1+1,fvY1+2,
    fvX2-1,fvY2-1);
    FillDispVDC (fvX1+1,fvY2-1,
    fvXSize-2,32);
    FWriteVDC (fvX1+1,fvY2-1,
    fvAttr,DispLine (fvCurPtr^.Line^));
    FlipPageVDC
  end
end;

procedure MoveLeftLine;

begin
  if fvCol < rtfMaxStr then
  begin
    rtfCurPtr := fvTopPtr;
    fvCol := fvCol+1;
    ClearWinVDC (fvX1+1,fvY1+1,fvX2-1,fvY2-1,32);
    DispWin;
    FlipPageVDC
  end
end;

procedure MoveRightLine;

begin
  if fvCol > 1 then
  begin
    rtfCurPtr := fvTopPtr;
    fvCol := fvCol-1;
    ClearWinVDC (fvX1+1,fvY1+1,fvX2-1,fvY2-1,32);
    DispWin;
    FlipPageVDC
  end
end;

procedure ViewFile;

var

  C : byte;

begin
  repeat
    C := GetKey (bdosConIn);
    case C of
      kbCtrlE : MoveUpLine;
      kbCtrlX : MoveDownLine;
      kbCtrlD : MoveLeftLine;
      kbCtrlS : MoveRightLine
    end
  until (C = kbCtrlM) or (C = kbEsc)
end;

procedure InitViewFile (X1,Y1,X2,Y2,A : byte;
                        FileName : bdosPathStr);

begin
  fvX1 := X1;
  fvY1 := Y1;
  fvX2 := X2;
  fvY2 := Y2;
  fvXSize := X2-X1+1;
  fvYSize := Y2-Y1+1;
  fvCol := 1;
  fvAttr := A;
  InitReadFile (FileName);
  if rtfError = 0 then
  begin
    ReadFile;
    DrawWinVDC (fvX1,fvY1,fvX2,fvY2,fvAttr,FileName);
    rtfCurPtr := rtfFirstPtr;
    fvTopPtr := rtfFirstPtr;
    DispWin;
    fvCurPtr := rtfCurPtr;
    fvBtmPtr := rtfCurPtr^.Prev;
    FlipPageVDC
  end
end;

procedure DoneViewFile;

begin
  DoneReadFile
end;
