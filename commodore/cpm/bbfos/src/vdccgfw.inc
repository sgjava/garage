{
SG Tools Pro (C) 1992 Steve Goldsmith

The VDC Character Generator File Write module saves VDC fonts in CGF file
format.
}

procedure WriteFontFile (F: bdosPathStr; Hgt,SChr,TChr : integer;
                         AltFlag : boolean);

var

  ChrCode,
  ChrAddr,
  ChrLine,
  ChrSetOfs : integer;

begin
  InitCGF;
  with cgfHead^ do
  begin
    Height := Hgt;
    StartChr := SChr;
    TotalChrs := TChr;
  end;
  OpenWriteCGF (F);
  if cgfIOError = 0 then
  begin
    GetMem (cgfChrTablePtr,cgfChrTableSize);
    if AltFlag then
      ChrSetOfs := cgfAltChrOfs
    else
      ChrSetOfs := 0;
    for ChrCode := 0 to pred(TChr) do
    begin
      ChrAddr := vdcSettings.CharDefMem+ChrSetOfs+(ChrCode+SChr)*16;
      WriteVDC (vdcUpdateAddrHi,Hi (ChrAddr));
      WriteVDC (vdcUpdateAddrLo,Lo (ChrAddr));
      for ChrLine := 0 to pred (Hgt) do
        cgfChrTablePtr^[ChrCode*Hgt+ChrLine] := ReadVDC (vdcCPUData)
    end;
    WriteChrTable;
    FreeChrTable
  end;
  DoneCGF
end;
