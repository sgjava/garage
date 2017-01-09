{
SG Tools (C) 1992 Steve Goldsmith

The VDC Bit Map module supports custom fonts and bit mapped graphics.
}

const

  vdcChrSetMax = 8191;
  vdcBitMapMax = 15999;

type

  vdcPChrSetBuf = ^vdcChrSetBuf;
  vdcChrSetBuf = array[0..vdcChrSetMax] of byte;
  vdcPBitMapBuf = ^vdcBitMapBuf;
  vdcBitMapBuf = array[0..vdcBitMapMax] of byte;

var

  vdcChrSetBufPtr : vdcPChrSetBuf;
  vdcBitMapBufPtr : vdcPBitMapBuf;

procedure InitBitMapBuf;

begin
  vdcBitMapBufPtr := nil;
  New (vdcBitMapBufPtr)
end;

procedure DoneBitMapBuf;

begin
  if vdcBitMapBufPtr <> nil then
    Dispose (vdcBitMapBufPtr)
end;

procedure InitChrSetBuf;

begin
  vdcChrSetBufPtr := nil;
  New (vdcChrSetBufPtr)
end;

procedure DoneChrSetBuf;

begin
  if vdcChrSetBufPtr <> nil then
    Dispose (vdcChrSetBufPtr)
end;

procedure MoveChrSetToBuf;

var

  I : integer;

begin
  WriteVDC (vdcUpdateAddrHi,
  Hi (vdcSettings.CharDefMem));  {Set start of VDC mem hi}
  WriteVDC (vdcUpdateAddrLo,
  Lo (vdcSettings.CharDefMem));  {Set start of VDC mem lo}
  for I := 0 to vdcChrSetMax do
    vdcChrSetBufPtr^[I] := ReadVDC (vdcCPUData)
end;

procedure MoveBufToChrSet;

var

  I : integer;

begin
  WriteVDC (vdcUpdateAddrHi,
  Hi (vdcSettings.CharDefMem));  {Set start of VDC mem hi}
  WriteVDC (vdcUpdateAddrLo,
  Lo (vdcSettings.CharDefMem));  {Set start of VDC mem lo}
  for I := 0 to vdcChrSetMax do
    WriteVDC (vdcCPUData,vdcChrSetBufPtr^[I])
end;

procedure ClearBitMap (Filler : byte);

begin
  FillMemVDC (vdcSettings.BitMap,vdcBitMapMax+1,Filler)
end;

procedure InitBitMap (B,F : byte);

begin
  WriteVDC (vdcHorzSmoothScroll,
  (ReadVDC (vdcHorzSmoothScroll) or $80) and $bf);
  WriteVDC (vdcDispStartAddrHi,Hi (vdcSettings.BitMap));
  WriteVDC (vdcDispStartAddrLo,Lo (vdcSettings.BitMap));
  SetScrColVDC (B,F)
end;

procedure DoneBitMap;

begin
  WriteVDC (vdcHorzSmoothScroll,vdcSettings.Mode)
end;
