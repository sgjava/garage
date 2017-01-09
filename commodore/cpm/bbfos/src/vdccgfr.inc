{
SG Tools Pro (C) 1992 Steve Goldsmith

The VDC Character Generator File Read module reads CGF format fonts into
the VDC.
}

const

  cgfAltChrOfs = 4096;

procedure ReadFontFile (F : bdosPathStr; AltFlag : boolean);

var

  ChrCode,
  ChrAddr,
  ChrLine,
  ChrSetOfs : integer;

begin
  InitCGF;
  OpenReadCGF (F);
  if cgfIOError = 0 then
  begin
    ReadChrTable;
    if AltFlag then
      ChrSetOfs := cgfAltChrOfs
    else
      ChrSetOfs := 0;
    for ChrCode := 0 to pred(cgfHead^.TotalChrs) do
    begin
      ChrAddr := vdcSettings.CharDefMem+ChrSetOfs+
      (ChrCode+cgfHead^.StartChr)*16;
      WriteVDC (vdcUpdateAddrHi,Hi (ChrAddr));
      WriteVDC (vdcUpdateAddrLo,Lo (ChrAddr));
      for ChrLine := 0 to pred (cgfHead^.Height) do
        WriteVDC (vdcCPUData,cgfChrTablePtr^[ChrCode*cgfHead^.Height+ChrLine])
    end;
    FreeChrTable
  end;
  DoneCGF
end;
