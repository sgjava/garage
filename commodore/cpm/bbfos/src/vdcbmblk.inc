{
SG Tools (C) 1992 Steve Goldsmith

The VDC Bit Map Block module supports bit mapped graphics.
}

procedure MoveBufToBitMap (XLen, YLen : integer);

var

  UnpackBufCnt, BitMapPtr, X, Y : integer;

begin
  UnpackBufCnt := 0;
  BitMapPtr := vdcSettings.BitMap;
  for Y := 1 to YLen do
  begin
    WriteVDC (vdcUpdateAddrHi,HI (BitMapPtr));
    WriteVDC (vdcUpdateAddrLo,LO (BitMapPtr));
    for X := 1 to XLen do
    begin
      WriteVDC (vdcCPUData,vdcBitMapBufPtr^[UnpackBufCnt]);
      UnpackBufCnt := UnpackBufCnt+1
    end;
    BitMapPtr := BitMapPtr+vdcScrHorz
  end
end;
