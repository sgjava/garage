{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

VGA 256 color Snip (.SNP) file decoder objects.  Decode Snip file to buffer
or to bios mode 13h 256 color screen.  ComputerEyes/RT hardware and CineMaker
software can be used to create Snip files.  You can also build your own Snips
from PCX files or other 256 color data.  The decode method can be modified for
use in unchained mode 13h a.k.a. mode x.
}

unit Snip;

{$I APP.INC}

interface

uses

  Dos, Objects,
{$IFDEF UseDLL}
  CyberApi;
{$ELSE}
  VGA;
{$ENDIF}

type

  snpFrameTable = array[0..16379] of longint;

{16 byte snip header record}

  snpHeader = record
    Version,
    Frames,
    HorzRes,
    VertRes,
    Reserved1,
    Delay,
    Reserved2,
    Reserved3 : word;
  end;

  PReadSnpFile = ^TReadSnpFile;
  TReadSnpFile = object (TObject)
    ReadError : integer;
    BufSize : word;
    SnipFile : file;
    ReadBlockPtr : vgaDataBufPtr;
    FrameTablePtr : ^snpFrameTable;
    Header : snpHeader;
    constructor Init (FileName : PathStr);
    destructor Done; virtual;
    function ReadFrame (BlockLoc : longint; BlockSize : word) : word;
    procedure ReadPal256 (PalPtr : vgaPalettePtr);
    procedure ReadFrameTable;
  end;

  PDecodeSnpFile = ^TDecodeSnpFile;
  TDecodeSnpFile = object (TReadSnpFile)
    XSize,
    YSize : word;
    PalPtr : vgaPalettePtr;
    DecodeBlockPtr : vgaDataBufPtr;
    constructor Init (FileName : PathStr);
    destructor Done; virtual;
    procedure DecodeData (Encode, Decode : pointer);
    procedure DecodeFrame (FrameNum : word);
  end;

  PDecodeSnpScr = ^TDecodeSnpScr;
  TDecodeSnpScr = object (TReadSnpFile)
    XSize,
    YSize : word;
    PalPtr : vgaPalettePtr;
    DecodeBlockPtr : vgaDataBufPtr;
    constructor Init (FileName : PathStr);
    destructor Done; virtual;
    procedure DecodeData (Encode, Decode : pointer;
              SnipWidth, ScrWidth : word);
    procedure DecodeFrame (FrameNum : word);
  end;

  PWriteSnpFile = ^TWriteSnpFile;
  TWriteSnpFile = object (TObject)
    WriteError : integer;
    WriteBufPos : word;
    SnipFile : file;
    WriteBlockPtr : vgaDataBufPtr;
    FrameTablePtr : ^snpFrameTable;
    Header : snpHeader;
    constructor Init (FileName : PathStr; TotFrames, Horz, Vert, FDelay : word);
    destructor Done; virtual;
    procedure WriteFrameByte (FByte : byte);
    procedure FlushBuf;
    procedure WriteFirstFrame (I : vgaDataBufPtr);
    procedure WritePal256 (PalPtr : vgaPalettePtr);
    procedure WriteFrameTable;
  end;
const

{snp max 256 color viewable sizes}

  snpMaxXSize = 320; snpMaxYSize = 200;

{snp max buffer sizes}

  snpMaxDecodeSize = vgaDataBufMax+1;
  snpMaxEncodeSize = 16384;

{snp errors}

  snpNoError     = 0;
  snpMemAlloc    = -100;
  snpBadVersion  = -101;
  snpNot256Color = -103;
  snpXSize       = -104;
  snpYSize       = -105;
  snpBufOverflow = -106;

{tp system errors}

  snpIOResultStart  = 100;
  snpIOResultEnd    = 162;

{snp software version}

  snpVersion = $0001;

implementation

uses

  Memory;

{
TReadSnpFile allows you to read DAC palette, frame table and encoded frames
of screen data.  Init opens file, reads header, checks version and allocates read
buffer and frame table.
}

constructor TReadSnpFile.Init (FileName : PathStr);

begin
  inherited Init;
  Assign (SnipFile,FileName);
  {$I-} Reset  (SnipFile,1); {$I+}
  ReadError := IoResult;
  if ReadError = snpNoError then
  begin
    {$I-} BlockRead (SnipFile,Header,SizeOf (Header)); {$I+}
    ReadError := IoResult;
    if ReadError = snpNoError then
    begin
      if Header.Version = snpVersion then {make sure version is correct}
      begin
        BufSize := Header.HorzRes*Header.VertRes+1; {buf size = x*y bytes}
        if BufSize <= snpMaxDecodeSize then       {check for buf overflow}
        begin
          ReadBlockPtr := MemAlloc (BufSize); {allocate read buffer}
          if ReadBlockPtr = nil then
            ReadError := snpMemAlloc;
          FrameTablePtr :=                    {allocate frame table}
          MemAlloc ((Header.Frames+1)*SizeOf (longint));
          if FrameTablePtr = nil then
            ReadError := snpMemAlloc
        end
        else
          ReadError := snpBufOverflow
      end
      else
        ReadError := snpBadVersion
    end
  end
end;

{
Dispose buffers if allocated and close file.
}

destructor TReadSnpFile.Done;

begin
  if ReadBlockPtr <> nil then
    FreeMem (ReadBlockPtr,BufSize);
  if FrameTablePtr <> nil then
    FreeMem (FrameTablePtr,
    (Header.Frames+1)*SizeOf (longint));
  {$I-} Close (SnipFile); {$I+}
  ReadError := IoResult;
  inherited Done
end;

{
Read up to 64K of encoded frame data starting at BlockLoc for BlockSize
bytes.
}

function TReadSnpFile.ReadFrame (BlockLoc : longint; BlockSize : word) : word;

var

  ReadSize : word;

begin
  {$I-} Seek (SnipFile,BlockLoc); {$I+}
  ReadError := IoResult;
  if ReadError = snpNoError then
  begin
    {$I-} BlockRead (SnipFile,ReadBlockPtr^,BlockSize,ReadSize); {$I+}
    ReadError := IoResult;
    ReadFrame := ReadSize
  end
  else
    ReadFrame := 0
end;

{
Read 256 color DAC palette into buffer.
}

procedure TReadSnpFile.ReadPal256 (PalPtr : vgaPalettePtr);

begin
  {$I-} Seek (SnipFile,SizeOf (Header)); {$I+}
  ReadError := IoResult;
  if ReadError = snpNoError then
  begin
    {$I-} BlockRead (SnipFile,PalPtr^,SizeOf (PalPtr^)); {$I+}
    ReadError := IoResult
  end
end;

{
Read frame table into buffer.
}

procedure TReadSnpFile.ReadFrameTable;

begin
  {$I-} Seek (SnipFile,SizeOf (Header)+
  SizeOf (vgaPalette)); {$I+}
  ReadError := IoResult;
  if ReadError = snpNoError then
  begin
    {$I-} BlockRead (SnipFile,FrameTablePtr^,
    (Header.Frames+1)*SizeOf (longint)); {$I+}
    ReadError := IoResult
  end
end;

{
TDecodeSnpFile is a high speed frame decoder to buffer memory.  You can
use this buffer for screen display or other processing.
}

constructor TDecodeSnpFile.Init (FileName : PathStr);

begin
  inherited Init (FileName);
  if ReadError = snpNoError then
  begin
    if Header.HorzRes <= snpMaxXSize then
    begin
      if Header.VertRes <= snpMaxYSize then
      begin
        DecodeBlockPtr :=
        MemAlloc (Header.HorzRes*Header.VertRes); {allocate frame buffer}
        if DecodeBlockPtr <> nil then
        begin
          XSize := Header.HorzRes;
          YSize := Header.VertRes;
          PalPtr := MemAlloc (SizeOf (PalPtr^))   {allocate dac palette}
        end
        else
          ReadError := snpMemAlloc
      end
      else
        ReadError := snpYSize
    end
    else
      ReadError := snpXSize
  end
end;

{
Dispose frame decode buffer and palette if allocated.
}

destructor TDecodeSnpFile.Done;

begin
  if DecodeBlockPtr <> nil then
    FreeMem (DecodeBlockPtr,XSize*YSize);
  if PalPtr <> nil then
    FreeMem (PalPtr,SizeOf (PalPtr^));
  inherited Done
end;

{
High speed linear differential decoder using Snip format.
}

procedure TDecodeSnpFile.DecodeData (Encode, Decode : pointer); assembler;

asm
  push    ds
  les     si,Encode  {es:si = address of snip data}
  lds     di,Decode  {ds:di = address of decode data}
  mov     ax,0       {ax = 0}
@while1:             {while al >= 64 do }
  mov     al,es:[si] { al = snp key byte}
  cmp     al,64
  jb      @while2    { if al >= 64 then}
  mov     ds:[di],al {  store al in unpack buffer}
  inc     si         {  si = si+1 encode data idx}
  inc     di         {  di = di+1 decode data idx}
  jmp     @while1    {end do}
@while2:             {while al <> 0 do}
  cmp     al,0
  je      @enddo2    { if al <> 0 then}
  inc     si         {  si = si+1 encode data idx}
  add     di,ax      {  di = di+al decode data idx}
  jmp     @while1    {enddo}
@enddo2:
  pop     ds         {restore ds}
end;

{
Decode any frame in Snip file.
}

procedure TDecodeSnpFile.DecodeFrame (FrameNum : word);

begin
  if ReadError = snpNoError then
  begin
    ReadFrame (FrameTablePtr^[FrameNum],
    FrameTablePtr^[FrameNum+1]-FrameTablePtr^[FrameNum]);
    if ReadError = snpNoError then
      DecodeData (ReadBlockPtr,DecodeBlockPtr)
  end
end;

{
TDecodeSnpScr is a high speed frame decoder to bios mode 13h screen memory.
This is much faster than decoding to a memory buffer and coping it to the
screen.
}

constructor TDecodeSnpScr.Init (FileName : PathStr);

begin
  inherited Init (FileName);
  if ReadError = snpNoError then
  begin
    if Header.HorzRes <= snpMaxXSize then
    begin
      if Header.VertRes <= snpMaxYSize then
      begin
        DecodeBlockPtr := Ptr (SegA000,$0000); {mode 13h screen memory}
        XSize := Header.HorzRes;
        YSize := Header.VertRes;
        PalPtr := MemAlloc (SizeOf (PalPtr^))  {allocate dac palette}
      end
      else
        ReadError := snpYSize
    end
    else
      ReadError := snpXSize
  end
end;

{
Dispose palette buffer if allocated.
}

destructor TDecodeSnpScr.Done;

begin
  if PalPtr <> nil then
    FreeMem (PalPtr,SizeOf (PalPtr^));
  inherited Done
end;

{
High speed linear differential decoder using Snip format.  Decode Snip
frame to standard mode 13h bios screen given snip and screen X size.  Could
be modified to handle mode x type displays too!
}

procedure TDecodeSnpScr.DecodeData (Encode, Decode : pointer;
          SnipWidth, ScrWidth : word); assembler;

asm
  push    ds
  les     si,Encode    {es:si = address of snp data}
  lds     di,Decode    {ds:di = address of screen}
  mov     ax,0         {ax = 0}
  mov     bx,SnipWidth {snip x size}
  mov     cx,ScrWidth  {screen x size}
  sub     cx,bx        {difference between screen and snip x size}
@while1:               {while al >= 64 do }
  mov     al,es:[si]   { al = snp key byte}
  cmp     al,64
  jb      @while2      { if al >= 64 then}
  mov     ds:[di],al   {  store al in unpack buffer}
  inc     si           {  si = si+1 encode data idx}
  inc     di           {  di = di+1 decode data idx}
  dec     bx           {  bx = bx-1}
  jnz     @while1      {end do if bx = 0}
  mov     bx,SnipWidth {bx = snip x size}
  add     di,cx        {di = di+cx set to start of next line}
  jmp     @while1      {end do}
@while2:               {while al <> 0 do}
  cmp     al,0
  je      @enddo2      { if al <> 0 then}
  inc     si           {  si = si+1 encode data idx}
  cmp     ax,bx        { if skip bytes >= bytes left then}
  jb      @then1
  add     di,ax        {  di = di+ax add skip bytes}
  add     di,cx        {  di = di+cx set to start of next line}
  add     bx,SnipWidth {  bx = snip x size}
  sub     bx,ax        {  bx = bx-ax subtract overflow from bytes left}
  jmp     @while1      {enddo}
@then1:
  add     di,ax        {  di = di+al decode data idx}
  sub     bx,ax        {  bx = bx-ax subtract skip bytes from bytes left}
  jmp     @while1      {enddo}
@enddo2:
  pop     ds           {restore ds}
end;

{
Decode any frame in Snip file.
}

procedure TDecodeSnpScr.DecodeFrame (FrameNum : word);

begin
  if ReadError = snpNoError then
  begin
    ReadFrame (FrameTablePtr^[FrameNum],
    FrameTablePtr^[FrameNum+1]-FrameTablePtr^[FrameNum]);
    if ReadError = snpNoError then
      DecodeData (ReadBlockPtr,DecodeBlockPtr,XSize,vgaScr256Line)
  end
end;

{
TWriteSnpFile creates file and handles writing first frame, DAC palette,
frame table and encoded bytes.
}

constructor TWriteSnpFile.Init (FileName : PathStr; TotFrames, Horz, Vert, FDelay : word);

begin
  inherited Init;
  Assign (SnipFile,FileName);
  {$I-} Rewrite (SnipFile,1); {$I+}
  WriteError := IoResult;
  if WriteError = snpNoError then
  begin
    with Header do
    begin
      Version := snpVersion;
      Frames := TotFrames;
      HorzRes := Horz;
      VertRes := Vert;
      Reserved1 := HorzRes*VertRes;
      Delay := FDelay;
      Reserved2 := 64;
      Reserved3 := 255
    end;
    {$I-} BlockWrite (SnipFile,Header,SizeOf (Header)); {$I+}
    WriteError := IoResult;
    WriteBlockPtr := MemAlloc (snpMaxEncodeSize);
    if WriteBlockPtr = nil then
      WriteError := snpMemAlloc;
    FrameTablePtr :=
    MemAlloc ((Header.Frames+1)*SizeOf (longint));
    if FrameTablePtr <> nil then
      FillChar (FrameTablePtr^,(Header.Frames+1)*SizeOf (longint),0)
    else
      WriteError := snpMemAlloc
  end
end;

destructor TWriteSnpFile.Done;

begin
  if WriteBlockPtr <> nil then
    FreeMem (WriteBlockPtr,snpMaxEncodeSize);
  if FrameTablePtr <> nil then
    FreeMem (FrameTablePtr,
    (Header.Frames+1)*SizeOf (longint));
  {$I-} Close (SnipFile); {$I+}
  WriteError := IoResult;
  inherited Done
end;

procedure TWriteSnpFile.WriteFrameByte (FByte : byte);

begin
  if WriteBufPos = snpMaxEncodeSize then
  begin
    {$I-} BlockWrite (SnipFile,WriteBlockPtr^,snpMaxEncodeSize); {$I+}
    WriteError := IoResult;
    WriteBufPos := 0
  end;
  WriteBlockPtr^[WriteBufPos] := FByte;
  Inc (WriteBufPos)
end;

procedure TWriteSnpFile.FlushBuf;

begin
  if WriteBufPos > 0 then
  begin
    {$I-} BlockWrite (SnipFile,WriteBlockPtr^,WriteBufPos); {$I+}
    WriteError := IoResult;
    WriteBufPos := 0
  end
end;

procedure TWriteSnpFile.WriteFirstFrame (I : vgaDataBufPtr);

begin
  {$I-} BlockWrite (SnipFile,I^,Header.HorzRes*Header.VertRes); {$I+}
  WriteError := IoResult;
end;

procedure TWriteSnpFile.WritePal256 (PalPtr : vgaPalettePtr);

begin
  {$I-} Seek (SnipFile,SizeOf (Header)); {$I+}
  WriteError := IoResult;
  if WriteError = snpNoError then
  begin
    {$I-} BlockWrite (SnipFile,PalPtr^,SizeOf (PalPtr^)); {$I+}
    WriteError := IoResult
  end
end;

procedure TWriteSnpFile.WriteFrameTable;

begin
  {$I-} Seek (SnipFile,SizeOf (Header)+
  SizeOf (vgaPalette)); {$I+}
  WriteError := IoResult;
  if WriteError = snpNoError then
  begin
    {$I-} BlockWrite (SnipFile,FrameTablePtr^,
    (Header.Frames+1)*SizeOf (longint)); {$I+}
    WriteError := IoResult
  end
end;

end.
