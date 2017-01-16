{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Fast PCX objects for encoding and decoding various PCX formats.

Currently supports:

Decode/encode 2 color to/from buffer.
X size <= 640
Y size <= 480

Decode/encode 2 color to/from character table.
X size <= 640
Y size <= 480

Decode/encode 256 color/gray to/from buffer.
X size <= 320
Y size <= 200.

Decode/encode 256 color/gray to/from mode 13h screen.
X size <= 320
Y size <= 200.
}

unit PCX;

{$I APP.INC}
{$X+}

interface

uses

  Dos, Objects,
{$IFDEF UseDLL}
  CyberApi;
{$ELSE}
  VGA;
{$ENDIF}

const

  pcxManufacturer = $0a; {used to identify .pcx}
  pcxStart256Pal = $0c;  {byte before 256 color palette}

{pcx versions}

  pcxVer25 = 0; pcxVer28Pal = 2; pcxVer28NoPal = 3; pcxVer30 = 5;

{pcx palette types}

  pcxColorPal = 1; pcxGrayPal = 2;

{pcx max encode/decode sizes}

  pcxMaxXSize1 = 640;
  pcxMaxYSize1 = 480;
  pcxMaxXSize256 = 320;
  pcxMaxYSize256 = 200;
  pcxMaxEncodeSize = 16384; {encode buffer size}
  pcxMaxDecodeSize = 16384; {decode buffer size}

{pcx error codes}

  pcxMemAlloc      = -100;
  pcxNotPCXformat  = -101;
  pcxNot2Color     = -102;
  pcxNot256Color   = -103;
  pcxXSize         = -104;
  pcxYSize         = -105;

type

{128 byte pcx header record}

  pcx16Pal = array[0..47] of byte;
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
    Palette : pcx16Pal;
    Reserved,
    ColorPlanes : byte;
    BytesPerLine,
    PaletteType : integer;
    Filler : array[0..57] of byte;
  end;

  PReadPCXFile = ^TReadPCXFile;
  TReadPCXFile = object (TObject)
    ReadError : integer;
    XSize,
    YSize,
    EncodeBufPos : word;
    ReadFileSize,
    EncodeSize : longint;
    ReadFile : file;
    EncodeBufPtr : vgaDataBufPtr;
    DecodeBufPtr : vgaDataBufPtr;
    Header : pcxHeader;
    ReadPalette : vgaPalette;
    constructor Init (FileName : PathStr);
    destructor Done; virtual;
    function GetEncodeByte : byte;
    procedure DecodeFile; virtual;
  end;

  PDecodePCXFile2 = ^TDecodePCXFile2;
  TDecodePCXFile2 = object (TReadPCXFile)
    constructor Init (FileName : PathStr);
  end;

  PPCXToChrTable = ^PPCXToChrTable;
  TPCXToChrTable = object (TDecodePCXFile2)
    constructor Init (FileName : PathStr;
                      XLen, YLen, CHeight : word;
                      ChrTablePtr : vgaChrTablePtr);
  end;

  PDecodePCXFile256 = ^TDecodePCXFile256;
  TDecodePCXFile256 = object (TReadPCXFile)
    constructor Init (FileName : PathStr);
    procedure ReadPal256;
    procedure DecodeFile; virtual;
    procedure Palette256to64;
  end;

  PWritePCXFile = ^TWritePCXFile;
  TWritePCXFile = object (TObject)
    WriteError : integer;
    EncodeBufPos : word;
    WriteFile : file;
    EncodeBufPtr : vgaDataBufPtr;
    Header : pcxHeader;
    constructor Init (FileName : PathStr);
    destructor Done; virtual;
    procedure WriteHeader;
    procedure SetHeader (XS, YS : integer; BP, CP : byte);
    procedure WriteEncodeByte (E : byte);
    procedure FlushEncodeBuf;
    procedure EncodeFile (PCXImage : vgaDataBufPtr; LineLen : word); virtual;
  end;

  PEncodePCXFile2 = ^TEncodePCXFile2;
  TEncodePCXFile2 = object (TWritePCXFile)
    procedure EncodeFile (PCXImage : vgaDataBufPtr; LineLen : word); virtual;
  end;

  PChrTableToPCX = ^TChrTableToPCX;
  TChrTableToPCX = object (TEncodePCXFile2)
    constructor Init (FileName : PathStr;
                      XChrs, YChrs, CHeight : word;
                      ChrTablePtr : vgaChrTablePtr);
  end;

  PEncodePCXFile256 = ^TEncodePCXFile256;
  TEncodePCXFile256 = object (TWritePCXFile)
    procedure EncodeFile (PCXImage : vgaDataBufPtr; LineLen : word); virtual;
    procedure WritePal256 (Pal : vgaPalettePtr);
    procedure Palette64to256 (Pal : vgaPalettePtr);
  end;

const

{default rgb triples for 1 bit images}

  pcxDef1BitPal : pcx16Pal = (
  $00,$00,$00,
  $ff,$ff,$ff,
  $00,$aa,$00,
  $00,$aa,$aa,
  $aa,$00,$00,
  $aa,$00,$aa,
  $aa,$aa,$00,
  $aa,$aa,$aa,
  $55,$55,$55,
  $55,$55,$ff,
  $55,$ff,$55,
  $55,$ff,$ff,
  $ff,$55,$55,
  $ff,$55,$ff,
  $ff,$ff,$55,
  $ff,$ff,$ff
  );

implementation

uses

  Memory;

{
TReadPCXFile
}

constructor TReadPCXFile.Init (FileName : PathStr);

begin
  inherited Init;
  EncodeBufPos := pcxMaxEncodeSize; {force read first buffer}
  Assign (ReadFile,FileName);
  {$I-} Reset  (ReadFile,1); {$I+}
  ReadError := IoResult;
  if ReadError = 0 then
  begin
    {$I-} ReadFileSize := FileSize (ReadFile); {$I+}
    ReadError := IoResult;
    if ReadError = 0 then
    begin
      {$I-} BlockRead (ReadFile,Header,SizeOf (Header)); {$I+}
      ReadError := IoResult;
      if ReadError = 0 then
      begin
        if Header.Manufacturer = pcxManufacturer then
        begin {see if it is a .pcx file}
          if Header.BitsPerPixel = 8 then
            EncodeSize := ReadFileSize-SizeOf (ReadPalette)-SizeOf (Header)
          else
            EncodeSize := ReadFileSize-SizeOf (Header);
          EncodeBufPtr := MemAlloc (pcxMaxEncodeSize);
          if EncodeBufPtr = nil then
            ReadError := pcxMemAlloc
        end
        else
          ReadError := pcxNotPCXFormat
      end
    end
  end
end;

{
Dispose buffers and close file.
}

destructor TReadPCXFile.done;

begin
  if EncodeBufPtr <> nil then
    FreeMem (EncodeBufPtr,pcxMaxEncodeSize);
  if DecodeBufPtr <> nil then
    FreeMem (DecodeBufPtr,Header.BytesPerLine*YSize);
  {$I-} Close (ReadFile); {$I+}
  ReadError := IoResult;
  inherited Done
end;

{
Buffered file i/o used for performance.
}

function TReadPCXFile.GetEncodeByte : byte;

var

  ReadSize : word;

begin
  if EncodeBufPos = pcxMaxEncodeSize then
  begin
    EncodeBufPos := 0;
    {$I-} BlockRead (ReadFile,EncodeBufPtr^,pcxMaxEncodeSize,ReadSize); {$I+}
    ReadError := IoResult
  end;
  GetEncodeByte := EncodeBufPtr^[EncodeBufPos];
  Inc (EncodeBufPos)
end;

{
Decode file to buffer.
}

procedure TReadPCXFile.DecodeFile;

var

  EncodeByte,
  RunLen,
  RunByte : byte;
  DecodeBufPos : word;
  EncodeBufCnt : longint;

begin
  EncodeBufCnt := 1;
  DecodeBufPos := 0;
  while EncodeBufCnt < EncodeSize do
  begin
    EncodeByte := GetEncodeByte;
    Inc (EncodeBufCnt);
    if (EncodeByte and $c0) = $c0 then
    begin {do run length decode if bits 6 and 7 are set}
      EncodeByte := (EncodeByte and $3f)-1; {run length}
      RunByte := GetEncodeByte;             {byte to repeat}
      Inc (EncodeBufCnt);
      for RunLen := 0 to EncodeByte do
        DecodeBufPtr^[DecodeBufPos+RunLen] := RunByte;
      DecodeBufPos := DecodeBufPos+RunLen+1
    end
    else
    begin {store byte as is}
      DecodeBufPtr^[DecodeBufPos] := EncodeByte;
      Inc (DecodeBufPos)
    end
  end
end;

{
TDecodePCXFile2
}

constructor TDecodePCXFile2.Init (FileName : PathStr);

begin
  inherited Init (FileName);
  if ReadError = 0 then
  begin
    if (Header.BitsPerPixel = 1) and
    (Header.ColorPlanes = 1) then {see if 2 color format}
    begin
      XSize := Header.XMax-Header.XMin+1;
      YSize := Header.YMax-Header.YMin+1;
      if XSize <= pcxMaxXSize1 then
      begin
        if YSize <= pcxMaxYSize1 then
        begin
          DecodeBufPtr :=
          MemAlloc (Header.BytesPerLine*YSize);
          if DecodeBufPtr = nil then
            ReadError := pcxMemAlloc
        end
        else
          ReadError := pcxYSize
      end
      else
        ReadError := pcxXSize
    end
    else
      ReadError := pcxNot2Color
  end
end;

{
TPCXToChrTable
}

constructor TPCXToChrTable.Init (FileName : PathStr;
                                 XLen, YLen, CHeight : word;
                                 ChrTablePtr : vgaChrTablePtr);

var

  X, Y, Line, ChrLine, ChrLineInc, EndXChr, EndYLine : word;

begin
  inherited Init (FileName);
  if ReadError = 0 then
  begin
    DecodeFile; {decode data}
    if ReadError = 0 then
    begin
      AccessFontMem; {make sure there are no srceen writes during font mem access}
      for X := 0 to vgaChrTableSize-1 do {clear font table mem}
        ChrTablePtr^[X] := 0;
      Line := 0;
      ChrLine := 0;
      ChrLineInc := XLen*vgaMaxChrHeight; {offset to next chr line byte}
      if Header.BytesPerLine > XLen then {adjust end x chr to fit table}
        EndXChr := XLen-1
      else
        EndXChr := Header.BytesPerLine-1;
      if YSize > YLen*CHeight then {adjust end y chr to fit table}
        EndYLine := YLen*CHeight-1
      else
        EndYLine := YSize-1;
      for Y := 0 to EndYLine do {copy decoded .pcx buffer to font mem}
      begin
        for X := 0 to EndXChr do
          ChrTablePtr^[X*vgaMaxChrHeight+ChrLine+Line] :=
          DecodeBufPtr^[Y*Header.BytesPerLine+X] xor $ff;
        Inc (Line);
        if Line = CHeight then {set for next line of chrs}
        begin
          Line := 0;
          ChrLine := ChrLine+ChrLineInc
        end
      end;
      AccessScreenMem {screen writes ok now}
    end
  end
end;

{
TDecodePCXFile256
}

constructor TDecodePCXFile256.Init (FileName : PathStr);

begin
  inherited Init (FileName);
  if ReadError = 0 then
  begin
    if (Header.Version = pcxVer30) and
    (Header.BitsPerPixel = 8) then {see if 256 color}
    begin
      XSize := Header.XMax-Header.XMin+1;
      YSize := Header.YMax-Header.YMin+1;
      if XSize <= pcxMaxXSize256 then
      begin
        if YSize <= pcxMaxYSize256 then
        begin
          DecodeBufPtr := nil;
          DecodeBufPtr :=
          MemAlloc (XSize*YSize);
          if DecodeBufPtr = nil then
            ReadError := pcxMemAlloc
        end
        else
          ReadError := pcxYSize
      end
      else
        ReadError := pcxXSize
    end
    else
      ReadError := pcxNot256Color
  end
end;

{
Read palette from any file position.
}

procedure TDecodePCXFile256.ReadPal256;

begin
  {$I-} Seek (ReadFile,SizeOf (Header)+EncodeSize); {$I+}
  ReadError := IoResult;
  if ReadError = 0 then
  begin
    {$I-} BlockRead (ReadFile,ReadPalette,SizeOf (ReadPalette)); {$I+}
    ReadError := IoResult
  end
end;

{
Get 256 color palette.
}

procedure TDecodePCXFile256.DecodeFile;

begin
  inherited DecodeFile;
  ReadPal256
end;

{
Convert 8 bit RGB to 6 bit RGB.
}

procedure TDecodePCXFile256.Palette256to64;

var

  Rgb, Dac : byte;

begin
  for Dac := 0 to vgaDACRegMax do
    for Rgb := 0 to vgaRGBMax do
      ReadPalette[Dac,Rgb] :=
      ReadPalette[Dac,Rgb] shr 2
end;


{
TWritePCXFile
}

constructor TWritePCXFile.Init (FileName : PathStr);

begin
  inherited Init;
  Assign (WriteFile,FileName);
  {$I-} Rewrite  (WriteFile,1); {$I+}
  WriteError := IoResult;
  if WriteError = 0 then
  begin
    EncodeBufPtr := MemAlloc (pcxMaxEncodeSize);
    if EncodeBufPtr = nil then
      WriteError := pcxMemAlloc
  end
end;

{
Write PCX header from current file position.
}

procedure TWritePCXFile.WriteHeader;

begin
  {$I-} BlockWrite (WriteFile,Header,SizeOf (Header)); {$I+}
  WriteError := IoResult
end;

{
Set .pcx header with only size, bit planes and color planes needed.
}

procedure TWritePCXFile.SetHeader (XS, YS : integer; BP, CP : byte);

begin
  with Header do
  begin
    Manufacturer := pcxManufacturer;
    Version := pcxVer30;
    Encoding := 1;
    BitsPerPixel := BP;
    XMin := 0;
    YMin := 0;
    XMax := XS-1;
    YMax := YS-1;
    HRes := 640;
    VRes := 480;
    case BitsPerPixel of
      1 : Palette := pcxDef1BitPal;
      8 : Palette := pcxDef1BitPal
    end;
    Reserved := 0;
    ColorPlanes := CP;
    BytesPerLine := XS div (8 div BP);
    if XS and $07 <> 0 then
      Inc (BytesPerLine);
    case BitsPerPixel of
      1 : PaletteType := 0;
      8 : PaletteType := pcxColorPal
    end;
    FillChar (Filler,SizeOf (Filler),0)
  end
end;

{
Dispose buffer and close file.
}

destructor TWritePCXFile.Done;

begin
  if EncodeBufPtr <> nil then
    FreeMem (EncodeBufPtr,pcxMaxEncodeSize);
  {$I-} Close (WriteFile); {$I+}
  WriteError := IoResult;
  inherited Done
end;

{
Write data using buffered i/o for speed
}

procedure TWritePCXFile.WriteEncodeByte (E : byte);

begin
  if EncodeBufPos = pcxMaxEncodeSize then
  begin
    {$I-} BlockWrite (WriteFile,EncodeBufPtr^,pcxMaxEncodeSize); {$I+}
    WriteError := IoResult;
    EncodeBufPos := 0
  end;
  EncodeBufPtr^[EncodeBufPos] := E;
  Inc (EncodeBufPos)
end;

{
Always flush the write buffer before block writes or closing file!
}

procedure TWritePCXFile.FlushEncodeBuf;

var

  WriteSize : word;

begin
  if EncodeBufPos > 0 then
  begin
    {$I-} BlockWrite (WriteFile,EncodeBufPtr^,EncodeBufPos,WriteSize); {$I+}
    WriteError := IoResult;
    EncodeBufPos := 0
  end
end;

{
Encode file from buffer.
}

procedure TWritePCXFile.EncodeFile (PCXImage : vgaDataBufPtr; LineLen : word);

var

  RunLen : byte;
  ImageBufPos,
  RunPos,
  EndPos,
  Y : word;

begin
  for Y := 0 to Header.YMax do
  begin
    ImageBufPos := LineLen*Y;
    EndPos := ImageBufPos+Header.BytesPerLine-1;
    RunLen := 0;
    while ImageBufPos <= EndPos do
    begin
      RunPos := ImageBufPos+1;
      while (RunPos <= EndPos) and
      (RunLen < 62) and
      (PCXImage^[ImageBufPos] =
      PCXImage^[RunPos]) do {do run length encoding}
      begin
        Inc (RunPos);
        Inc (RunLen)
      end;
      if RunLen > 0 then
      begin {if run length was used then write key byte and data}
        Inc (RunLen);
        WriteEncodeByte (RunLen or $c0);
        WriteEncodeByte (PCXImage^[ImageBufPos]);
        ImageBufPos := RunPos;
        RunLen := 0
      end
      else
      begin {if bits 6 and 7 (0c0h) are set then store byte with run length of 1}
        if (PCXImage^[ImageBufPos] and $c0) = $c0 then
          WriteEncodeByte ($c1);
        WriteEncodeByte (PCXImage^[ImageBufPos]);
        Inc (ImageBufPos)
      end
    end
  end
end;

{
TEncodePCXFile2
}

procedure TEncodePCXFile2.EncodeFile (PCXImage : vgaDataBufPtr; LineLen : word);

begin
  inherited EncodeFile (PCXImage,LineLen);
  FlushEncodeBuf {flush write buffer after encoding}
end;

{
TChrTableToPCX
}

constructor TChrTableToPCX.Init (FileName : PathStr;
                                 XChrs, YChrs, CHeight : word;
                                 ChrTablePtr : vgaChrTablePtr);

var

  X, Y, Line, ChrLine, ChrLineInc, YLines : word;
  DecodeBuf : vgaDataBufPtr;

begin
  inherited Init (FileName);
  if WriteError = 0 then
  begin
    DecodeBuf := MemAlloc (XChrs*YChrs*CHeight); {decode buffer}
    if DecodeBuf <> nil then
    begin
      AccessFontMem; {no screen writes during font mem access}
      Line := 0;
      ChrLine := 0;
      ChrLineInc := XChrs*vgaMaxChrHeight; {offset to next chr line byte}
      YLines := YChrs*CHeight;
      for Y := 0 to YLines-1 do {copy font mem to decode buffer}
      begin
        for X := 0 to XChrs-1 do
          DecodeBuf^[Y*XChrs+X] := ChrTablePtr^[X*vgaMaxChrHeight+ChrLine+Line] xor $ff;
          Inc (Line);
          if Line = CHeight then {set for next chr line}
          begin
            Line := 0;
            ChrLine := ChrLine+ChrLineInc
          end
      end;
      AccessScreenMem; {screen writes ok now}
      SetHeader (XChrs*8,YLines,1,1);             {set .pcx header}
      WriteHeader;                                {write header}
      EncodeFile (DecodeBuf,Header.BytesPerLine); {encode data}
      FreeMem (DecodeBuf,XChrs*YChrs*CHeight)     {dispose buffer}
    end
  end
end;

{
TEncodePCXFile256
}

procedure TEncodePCXFile256.EncodeFile (PCXImage : vgaDataBufPtr; LineLen : word);

begin
  inherited EncodeFile (PCXImage,LineLen);
  WriteEncodeByte (pcxStart256Pal); {byte before 256 color palette}
  FlushEncodeBuf {flush write buffer before writing 256 color palette}
end;

{
Write 256 color palette from current file position.
}

procedure TEncodePCXFile256.WritePal256 (Pal : vgaPalettePtr);

begin
  {$I-} BlockWrite (WriteFile,Pal^,SizeOf (Pal^)); {$I+}
  WriteError := IoResult
end;

{
Convert 6 bit RGB to 8 bit RGB.
}

procedure TEncodePCXFile256.Palette64to256 (Pal : vgaPalettePtr);

var

  Rgb, Dac : byte;

begin
  for Dac := 0 to vgaDACRegMax do
    for Rgb := 0 to vgaRGBMax do
      Pal^[Dac,Rgb] :=
      Pal^[Dac,Rgb] shl 2
end;

end.
