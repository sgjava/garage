{
SG Tools Pro (C) 1992 Steve Goldsmith

Z Blaster File Import module.
}

const

  timRes = 10227; {cia timer a resolution div 100}
  zbfiBufMax = 16383;
  zbfiBufBlocks = 128;

  appStatus = #$1b#$3d#$2d#$28#$1b#$54;

type

  zbfiBufArrPtr = ^zbfiBufArr;
  zbfiBufArr = array[0..zbfiBufMax] of byte;

var

  zbfiSOpen,
  zbfiDOpen : boolean;
  zbfiSBits,
  zbfiDBits : byte;
  zbfiSBlocks,
  zbfiSBuf,
  zbfiDBuf,
  zbfiDHz,
  zbfiError : integer; {errors}
  zbfiSFile : file;     {sample file to read}
  zbfiDFile : file;     {zbf file to write}
  zbfiSBufPtr : zbfiBufArrPtr;
  zbfiDBufPtr : zbfiBufArrPtr;
  zbfiHeader : zbfFileHeader;

procedure InitImport (SName : bdosPathStr; SBits :byte;
                      DName : bdosPathStr; DBits: byte; DHz : integer);

begin
  zbfiError := 0;    {initilize vars}
  zbfiSOpen := false;
  zbfiSBits := SBits;
  zbfiSBuf := zbfiBufMax+1; {force read of first buffer}
  zbfiSBufPtr := nil;
  zbfiDOpen := false;
  zbfiDBits := DBits;
  zbfiDBuf := 0;
  zbfiDHz := DHz;
  zbfiDBufPtr := nil;
  Assign (zbfiSFile, SName);
  {$I-} Reset (zbfiSFile); {$I+}
  zbfiError := IoResult;
  if zbfiError = 0 then
  begin
    zbfiSOpen := true;
    {$I-} zbfiSBlocks := FileSize (zbfiSFile); {$I+}
    zbfiError := IoResult;
    if zbfiError = 0 then
    begin
      Assign (zbfiDFile,DName);
      {$I-} Rewrite (zbfiDFile); {$I+}
      zbfiError := IoResult;
      if zbfiError = 0 then
      begin
        zbfiDOpen := true;
        New (zbfiSBufPtr);
        New (zbfiDBufPtr);
        FillChar (zbfiDBufPtr^,SizeOf (zbfiDBufPtr^),0)
      end
    end
  end
end;

procedure DoneImport;

begin
  if zbfiSOpen then
  begin
    {$I-} Close (zbfiSFile); {$I+}
    zbfiError := IoResult
  end;
  if zbfiDOpen then
  begin
    {$I-} Close (zbfiDFile); {$I+}
    zbfiError := IoResult
  end;
  if zbfiSBufPtr <> nil then
    Dispose (zbfiSBufPtr);
  if zbfiDBufPtr <> nil then
    Dispose (zbfiDBufPtr)
 end;

procedure WriteHeader (SL, SH : integer);

begin
  Writeln (appStatus,'Writing ZBF header');
  with zbfiHeader do
  begin
    Version := zbfVersion;
    Compress := 0;
    SamBits := zbfiDBits;
    Delay := timRes div (zbfiDHz div 100);
    Hz := zbfiDHz;
    SizeLo := SL;
    SizeHi := SH;
    FillChar (Filler,SizeOf (Filler),0)
  end;
  {$I-} BlockWrite (zbfiDFile,zbfiHeader,1); {$I+}
  zbfiError := IoResult
end;

procedure ReadBuffer;

begin
  if zbfiSBlocks >= zbfiBufBlocks then
  begin
    Writeln (appStatus,'Reading buffer');
    {$I-} BlockRead (zbfiSFile,zbfiSBufPtr^,zbfiBufBlocks); {$I+}
    zbfiSBlocks := zbfiSBlocks-zbfiBufBlocks
  end
  else
  begin
    Writeln (appStatus,'Reading last buffer');
    if zbfiSBlocks > 0 then
      {$I-} BlockRead (zbfiSFile,zbfiSBufPtr^,zbfiSBlocks); {$I+}
    zbfiSBlocks := 0
  end;
  zbfiError := IoResult;
  zbfiSBuf := 0;
  Writeln (appStatus,'Processing buffer')
end;

procedure WriteBuffer;

begin
  
  Writeln (appStatus,'Writing buffer');
  {$I-} BlockWrite (zbfiDFile,zbfiDBufPtr^,zbfiBufBlocks); {$I+}
  zbfiError := IoResult;
  FillChar (zbfiDBufPtr^,SizeOf (zbfiDBufPtr^),0);
  zbfiDBuf := 0;
  
  Writeln (appStatus,'Processing buffer')
end;

procedure FlushDest;

begin
  if zbfiDBuf > 0 then
  begin
    Writeln (appStatus,'Flushing write buffer');
    {$I-} BlockWrite (zbfiDFile,zbfiDBufPtr^,zbfiDBuf div zbfBlockSize+1); {$I+}
    zbfiError := IoResult;
    zbfiDBuf := 0
  end;
end;

procedure Import1to1;

var

  SBytes, SBlks : integer;

begin
  if zbfiSBlocks < 512 then
    WriteHeader ((Hi (zbfiSBlocks)*$8000) or
    (Lo (zbfiSBlocks)*128),0)
  else
    WriteHeader ((zbfiSBlocks mod 512)*128,
    zbfiSBlocks div 512);
  SBlks := zbfiSBlocks;
  SBytes := zbfBlockSize;
  while SBlks > 0 do
  begin
    if zbfiSBuf > zbfiBufMax then
      ReadBuffer;
    if zbfiDBuf > zbfiBufMax then
      WriteBuffer;
    zbfiDBufPtr^[zbfiDBuf] := zbfiSBufPtr^[zbfiSBuf];
    zbfiDBuf := zbfiDBuf+1;
    zbfiSBuf := zbfiSBuf+1;
    SBytes := SBytes-1;
    if SBytes = 0 then
    begin
      SBlks := SBlks-1;
      SBytes := zbfBlockSize
    end
  end;
  FlushDest
end;

procedure Import4to1;

var

  BitCnt, SByte, DByte : byte;
  SBytes, SBlks : integer;

begin
  WriteHeader ((Hi (zbfiSBlocks)*$8000) or
  (Lo (zbfiSBlocks)*32),0);
  SBlks := zbfiSBlocks;
  SBytes := zbfBlockSize;
  while SBlks > 0 do
  begin
    BitCnt := 8;
    DByte := 0;
    repeat
      DByte := DByte shl 1;
      if zbfiSBuf > zbfiBufMax then
        ReadBuffer;
      DByte := DByte or (zbfiSBufPtr^[zbfiSBuf] shr 7);
      DByte := DByte shl 1;
      DByte := DByte or ((zbfiSBufPtr^[zbfiSBuf] shr 3) and $01);
      zbfiSBuf := zbfiSBuf+1;
      BitCnt := BitCnt-2;
      SBytes := SBytes-1;
      if SBytes = 0 then
      begin
        SBlks := SBlks-1;
        SBytes := zbfBlockSize
      end
    until (BitCnt = 0) or (SBlks = 0);
    if zbfiDBuf > zbfiBufMax then
      WriteBuffer;
    zbfiDBufPtr^[zbfiDBuf] := DByte;
    zbfiDBuf := zbfiDBuf+1
  end;
  FlushDest
end;

procedure Import8to1;

var

  BitCnt, DByte : byte;
  SBytes, SBlks : integer;

begin
  WriteHeader ((Hi (zbfiSBlocks)*4096) or
  (Lo (zbfiSBlocks)*16),0);
  SBlks := zbfiSBlocks;
  SBytes := zbfBlockSize;
  while SBlks > 0 do
  begin
    BitCnt := 8;
    DByte := 0;
    repeat
      DByte := DByte shl 1;
      if zbfiSBuf > zbfiBufMax then
        ReadBuffer;
      DByte := DByte or (zbfiSBufPtr^[zbfiSBuf] shr 7);
      zbfiSBuf := zbfiSBuf+1;
      BitCnt := BitCnt-1;
      SBytes := SBytes-1;
      if SBytes = 0 then
      begin
        SBlks := SBlks-1;
        SBytes := zbfBlockSize
      end
    until (BitCnt = 0) or (SBlks = 0);
    if zbfiDBuf > zbfiBufMax then
      WriteBuffer;
    zbfiDBufPtr^[zbfiDBuf] := DByte;
    zbfiDBuf := zbfiDBuf+1
  end;
  FlushDest
end;

procedure Import8to4;

var

  DByte : byte;
  SBytes, SBlks : integer;

begin
  if zbfiSBlocks < 1024 then
    WriteHeader ((Hi (zbfiSBlocks)*$4000) or
    (Lo (zbfiSBlocks)*64),0)
  else
    WriteHeader ((zbfiSBlocks mod 1024)*64,
    zbfiSBlocks div 1024);
  SBlks := zbfiSBlocks;
  SBytes := zbfBlockSize;
  while SBlks > 0 do
  begin
    if zbfiSBuf > zbfiBufMax then
      ReadBuffer;
    DByte := zbfiSBufPtr^[zbfiSBuf] and $f0;
    zbfiSBuf := zbfiSBuf+1;
    if zbfiSBuf > zbfiBufMax then
      ReadBuffer;
    if zbfiDBuf > zbfiBufMax then
      WriteBuffer;
    zbfiDBufPtr^[zbfiDBuf] := DByte or (zbfiSBufPtr^[zbfiSBuf] shr 4);
    zbfiSBuf := zbfiSBuf+1;
    zbfiDBuf := zbfiDBuf+1;
    SBytes := SBytes-2;
    if SBytes = 0 then
    begin
      SBlks := SBlks-1;
      SBytes := zbfBlockSize
    end
  end;
  FlushDest
end;
