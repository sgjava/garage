{
SG Tools (C) 1992 Parsec, Inc.

The VDC Fast Write module supports fast display I/O using current DispMem
and AttrMem.
}

type

  fwMaxStr = string[255];

procedure FillDispVDC (X, Y, CLen, C : byte);

var

  DispOfs : integer;

begin
  DispOfs := vdcSettings.DispMem+Y*vdcSettings.ScrHorz+X;
  FillMemVDC (DispOfs,CLen,C)
end;

procedure FillAttrVDC (X, Y, ALen, A : byte);

var

  AttrOfs : integer;

begin
  AttrOfs := vdcSettings.AttrMem+Y*vdcSettings.ScrHorz+X;
  FillMemVDC (AttrOfs,ALen,A)
end;

procedure FWriteVDC (X, Y, Attr : byte;
                     FWStr : fwMaxStr);

var

  I, DispOfs, AttrOfs : integer;
  FWStrLen : byte;

begin
  DispOfs := vdcSettings.DispMem+Y*vdcSettings.ScrHorz+X;
  AttrOfs := vdcSettings.AttrMem+Y*vdcSettings.ScrHorz+X;
  FWStrLen := Length (FWStr);
  WriteVDC (vdcUpdateAddrHi,Hi (DispOfs));
  WriteVDC (vdcUpdateAddrLo,Lo (DispOfs));
  for I := 1 to FWStrLen do
    WriteVDC (vdcCPUData,Ord (FWStr[I]));
  FillMemVdc (AttrOfs,FWStrLen,Attr)
end;
