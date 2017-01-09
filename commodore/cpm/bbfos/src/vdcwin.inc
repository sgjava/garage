{
SG Tools (C) 1992 Parsec, Inc.

The VDC Window module allows fast pop up windowing.
}

const

  winTopLeft = 207;    winTop = 247;    winTopRight = 208;
  winLeft = 244;       winFill = 32;    winRight = 231;
  winBottomLeft = 204; winBottom = 239; winBottomRight = 250;

procedure DrawWinVDC (X1,Y1,X2,Y2,A : byte;
                      Title : fwMaxStr);

var

  InsideLen, Y, Shadow : byte;

begin
  Shadow := vdcDarkGray or (A and vdcAltChrSet);
  InsideLen := X2-X1-1;
  for Y := Y1 to Y2 do
  begin
    FillAttrVDC (X1,Y,InsideLen+2,A);
    FillAttrVDC (X2+1,Y+1,1,Shadow)
  end;
  FillAttrVDC (X1+1,Y2+1,InsideLen+1,Shadow);
  FillDispVDC (X1,Y1,1,winTopLeft);
  FillDispVDC (X1+1,Y1,InsideLen,winTop);
  FillDispVDC (X2,Y1,1,winTopRight);
  FillDispVDC (X1,Y2,1,winBottomLeft);
  FillDispVDC (X1+1,Y2,InsideLen,winBottom);
  FillDispVDC (X2,Y2,1,winBottomRight);
  if Title <> '' then
  begin
    Title := ' '+Title+' ';
    if Length (Title) > InsideLen then
      Title[0] := Chr (InsideLen);
    FWriteVDC (X1+1,Y1,A or (vdcRvsVid+vdcIntensity),Title)
  end;
  Y1 := Y1+1;
  Y2 := Y2-1;
  for Y := Y1 to Y2 do
  begin
    FillDispVDC (X1,Y,1,winLeft);
    FillDispVDC (X1+1,Y,InsideLen,winFill);
    FillDispVDC (X2,Y,1,winRight);
  end
end;
