{
SG Tools Pro (C) 1992 Steve Goldsmith

PCX file decoder
}

const

  pcxMaxBuf = 1023;

type

  pcxFileName = string[15];

  pcxPHeader = ^pcxHeader;
  pcxHeader = record
    Manufacturer,
    Version,
    Encoding,
    BitsPerPixel : byte;
    XMin,
    YMin,
    XMax,
    YMax,
    HRes,
    VRes : integer;
    Palette : array[0..47] of byte;
    Reserved,
    ColorPlanes : byte;
    BytesPerLine,
    PaletteType : integer;
    Filler: array[0..57] of byte
  end;

  pcxPEncodeBuf = ^pcxEncodeBuf;
  pcxEncodeBuf = array[0..pcxMaxBuf] of byte;

var

  pcxError : integer;
  pcxHead : pcxPHeader;
  pcxEncode : pcxPEncodeBuf;
  pcxFile : file;

procedure InitPCX (FileName : pcxFileName);

begin
  pcxError := 0;
  pcxHead := nil;
  pcxEncode := nil;
  Assign (pcxFile,FileName);
  {$I-} Reset (pcxFile); {$I+}
  pcxError := IoResult;
  if pcxError = 0 then
  begin
    New (pcxHead);
    New (pcxEncode);
    {$I-} BlockRead (pcxFile,
    pcxHead^,1) {$I+}
  end
end;

procedure DecodePCX;

var

  Index, Data, RunLen : byte;
  YSize, Line, Unpack, UnpackBufCnt,
  ReadBlks, TotalUnpack, BufCnt : integer;

  function GetByte : byte;

  begin
    if BufCnt > pcxMaxBuf then
    begin
      BufCnt := 0;
      {$I-} BlockRead (pcxFile,
      pcxEncode^,ReadBlks); {$I+}
      pcxError := IoResult
    end;
    GetByte := pcxEncode^[BufCnt];
    BufCnt := BufCnt+1
  end;

begin
  ReadBlks := pcxMaxBuf div 128+1; {calc # of blocks to read}
  YSize := pcxHead^.YMax-pcxHead^.YMin+1;
  TotalUnpack := pcxHead^.ColorPlanes*pcxHead^.BytesPerLine;
  BufCnt := pcxMaxBuf+1; {force read first buffer}
  UnpackBufCnt := 0;
  for Line := 1 to YSize do
  begin
    Unpack := 0;
    while Unpack < TotalUnpack do
    begin
      Index := GetByte;
      if (Index and $c0) <> $c0 then
      begin
        vdcBitMapBufPtr^[UnpackBufCnt] := Index;
        UnpackBufCnt := UnpackBufCnt+1;
        Unpack := Unpack+1
      end
      else
      begin
        Index := Index and $3f;
        Unpack := Unpack+Index;
        Data := GetByte;
        for RunLen := 1 to Index do
        begin
          vdcBitMapBufPtr^[UnpackBufCnt] := Data;
          UnpackBufCnt := UnpackBufCnt+1
        end
      end
    end
  end
end;

procedure DonePCX;

begin
  if pcxHead <> nil then
    Dispose (pcxHead);
  if pcxEncode <> nil then
    Dispose (pcxEncode);
  {$I-} Close (pcxFile); {$I+}
  pcxError := IoResult
end;
