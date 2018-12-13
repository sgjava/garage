{
SG Tools Pro (C) 1992 Steve Goldsmith

Z Blaster File Read module.
}

const

  zbfExt       = '.ZBF';
  zbfVersion   = $0200; {file version 02.00}
  zbfBlockSize = 128;   {block size}
  zbfMaxBlocks = 256;   {max file block}
  zbfVerError  = -1;    {file wrong version}

type

  zbfBlock = array[0..127] of byte;
  zbfSampleArrPtr = ^zbfSampleArr;
  zbfSampleArr = array[0..255] of zbfBlock;
  zbfFileHeaderPtr = ^zbfFileHeader;
  zbfFileHeader = record
    Version : integer;
    Compress : byte;
    SamBits : byte;
    Delay,
    SizeLo,
    SizeHi,
    Hz : integer;
    Filler : array[0..115] of byte;
  end;

var

  zbfError,                       {errors}
  zbfBlocks : integer;            {number of file blocks}
  zbfSamplePtr : zbfSampleArrPtr; {sample pointer}
  zbfHeader : zbfFileHeaderPtr;   {zbf file header pointer}
  zbfFile : file;                 {sample file to read}

procedure InitReadZBF (FileName : bdosPathStr);

begin
  zbfError := 0;    {initilize vars}
  zbfHeader := nil;
  zbfSamplePtr := nil;
  Assign (zbfFile, FileName);
  {$I-} Reset (zbfFile); {$I+}
  zbfError := IoResult;
  if zbfError = 0 then
  begin
    {$I-} zbfBlocks := FileSize (zbfFile); {$I+}
    zbfError := IoResult;
    if zbfError = 0 then
    begin
      zbfBlocks := zbfBlocks-1;
      New (zbfHeader);
      {$I-} BlockRead (zbfFile,zbfHeader^,1); {$I+}
      zbfError := IoResult;
      if zbfError = 0 then
      begin
        if zbfHeader^.Version <= zbfVersion then
        begin
          if zbfBlocks >= zbfMaxBlocks then
          begin
            zbfBlocks := zbfMaxBlocks-1;
            zbfHeader^.SizeLo := zbfBlocks*zbfBlockSize
          end;
          if zbfBlocks >= (Hi (MemAvail)*2) then
          begin
            zbfBlocks := Hi (MemAvail)*2-1;
            zbfHeader^.SizeLo := zbfBlocks*zbfBlockSize
          end;
          zbfHeader^.SizeHi := 0;
          GetMem (zbfSamplePtr,zbfBlocks*zbfBlockSize)
        end
        else
          zbfError := zbfVerError
      end
    end
  end
end;

procedure DoneReadZBF (BufFlag : boolean);

begin
  {$I-} Close (zbfFile); {$I+}
  zbfError := IoResult;
  if zbfHeader <> nil then
    Dispose (zbfHeader);
  if (BufFlag) and (zbfSamplePtr <> nil) then
    FreeMem (zbfSamplePtr,
    zbfBlocks*zbfBlockSize)
end;

procedure ReadZBFData;

begin
  {$I-} BlockRead (zbfFile,zbfSamplePtr^,zbfBlocks); {$I+}
  zbfError := IoResult;
end;
