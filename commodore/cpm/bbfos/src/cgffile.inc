{
VDC Character Generator File module.

(C) 1992 Steve Goldsmith
All Rights Reserved

All CGF header fields must be set and a buffer containing character
patterns allocated before writing character generator files (CGF) to disk.
The read method will allocate the buffer for you.  You are responsible
for deallocating the buffer.
}

const

{cgf version 01.00}

  cgfVersion = $0100;

{cgf internal errors}

  cgfMemAlloc      = -100;
  cgfNotCGFformat  = -101;

{cgf file block size}

  cgfBlockSize = 128;

type

{128 byte cgf header record}

  cgfHeaderPtr = ^cgfHeader;
  cgfHeader = record
    Version,
    Height,
    StartChr,
    TotalChrs : integer;
    Filler : array[0..119] of byte;
  end;

  cgfBufferPtr = ^cgfBuffer;
  cgfBuffer = array[0..8191] of byte;

var

  cgfIoError : integer;
  cgfChrTableSize : integer;
  cgfFile : file;
  cgfHead : cgfHeaderPtr;
  cgfChrTablePtr : cgfBufferPtr;

procedure InitCGF;

begin
  cgfIoError := 0;
  cgfChrTableSize := 0;
  cgfHead := nil;
  cgfChrTablePtr := nil;
  New (cgfHead);
  with cgfHead^ do
  begin
    Version := cgfVersion;
    Height := 0;
    StartChr := 0;
    TotalChrs := 0;
    FillChar (Filler,SizeOf (Filler),0)
  end
end;

procedure DoneCGF;

begin
  if cgfHead <> nil then
    Dispose (cgfHead);
  {$I-} Close (cgfFile); {$I+}
  cgfIoError := IoResult
end;

procedure FreeChrTable;

begin
  if cgfChrTablePtr <> nil then
    FreeMem (cgfChrTablePtr,cgfChrTableSize)
end;

procedure OpenReadCGF (FileName : bdosPathStr);

begin
  Assign (cgfFile,FileName);
  {$I-} Reset  (cgfFile); {$I+}
  cgfIoError := IoResult;
  if cgfIoError = 0 then
  begin
    {$I-} BlockRead (cgfFile,cgfHead^,1); {$I+}
    cgfIoError := IoResult;
    if cgfIoError = 0 then
    begin
      if cgfHead^.Version = cgfVersion then
      begin
        cgfChrTableSize := cgfHead^.Height*cgfHead^.TotalChrs;
        GetMem (cgfChrTablePtr,cgfChrTableSize);
        if cgfChrTablePtr = nil then
          cgfIoError := cgfMemAlloc
      end
      else
        cgfIoError := cgfNotCGFFormat
    end
  end
end;

procedure ReadChrTable;

var

  ReadBlks : integer;

begin
  {$I-} Seek (cgfFile,1); {$I+}
  cgfIoError := IoResult;
  if cgfIoError = 0 then
  begin
    if cgfChrTableSize mod cgfBlockSize = 0 then
      ReadBlks := cgfChrTableSize div cgfBlockSize
    else
      ReadBlks := cgfChrTableSize div cgfBlockSize+1;
    {$I-} BlockRead (cgfFile,cgfChrTablePtr^,ReadBlks); {$I+}
    cgfIoError := IoResult
  end
end;

procedure OpenWriteCGF (FileName : bdosPathStr);

begin
  Assign (cgfFile,FileName);
  {$I-} Rewrite  (cgfFile); {$I+}
  cgfIoError := IoResult;
  if cgfIoError = 0 then
  begin
    cgfChrTableSize := cgfHead^.Height*cgfHead^.TotalChrs;
    {$I-} BlockWrite (cgfFile,cgfHead^,1); {$I+}
    cgfIoError := IoResult
  end
end;

procedure WriteChrTable;

var

  WriteBlks : integer;

begin
  {$I-} Seek (cgfFile,1); {$I+}
  cgfIoError := IoResult;
  if cgfIoError = 0 then
  begin
    if cgfChrTableSize mod cgfBlockSize = 0 then
      WriteBlks := cgfChrTableSize div cgfBlockSize
    else
      WriteBlks := cgfChrTableSize div cgfBlockSize+1;
    {$I-} BlockWrite (cgfFile,cgfChrTablePtr^,WriteBlks); {$I+}
    cgfIoError := IoResult
  end
end;
