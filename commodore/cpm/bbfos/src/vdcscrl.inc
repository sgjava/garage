{
SG Tools (C) 1992 Parsec, Inc.

VDC window scroller using block copies and fills
}

procedure ScrollUpVDC (X1, Y1, X2, Y2 : byte);

var

  Y : byte;
  DispOfs : integer;

begin
  for Y := Y1 to Y2 do
  begin
    DispOfs := vdcSettings.DispMem+Y*vdcSettings.ScrHorz+X1;
    CopyMemVDC (DispOfs,DispOfs-vdcSettings.ScrHorz,X2-X1+1)
  end
end;

procedure ScrollDownVDC (X1, Y1, X2, Y2 : byte);

var

  Y : byte;
  DispOfs : integer;

begin
  for Y := Y2 downto Y1 do
  begin
    DispOfs := vdcSettings.DispMem+Y*vdcSettings.ScrHorz+X1;
    CopyMemVDC (DispOfs,DispOfs+vdcSettings.ScrHorz,X2-X1+1)
  end
end;

procedure ClearWinVDC (X1, Y1, X2, Y2, C : byte);

var

  Y : byte;
  DispOfs : integer;

begin
  for Y := Y1 to Y2 do
  begin
    DispOfs := vdcSettings.DispMem+Y*vdcSettings.ScrHorz+X1;
    FillMemVDC (DispOfs,X2-X1+1,C)
  end
end;
