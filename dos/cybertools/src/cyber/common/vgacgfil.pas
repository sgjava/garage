{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

VGA character generator file object.  All CGF header fields must be set
and a buffer containing character patterns allocated before writing
character generator files (CGF) to disk.  The read method will allocate
the buffer for you.  You are responsible for deallocating the buffer.
}

unit VGACGFil;

{$I APP.INC}

interface

uses

  Dos, Objects,
{$IFDEF UseDLL}
  CyberAPI;
{$ELSE}
  VGA;
{$ENDIF}

const

{cgf version 01.00}

  cgfVersion = $0100;

{cgf internal errors}

  cgfMemAlloc      = -100;
  cgfNotCGFformat  = -101;

type

{128 byte cgf header record}

  cgfHeader = record
    Version,
    Height,
    StartChr,
    TotalChrs : word;
    Filler : array[0..119] of byte; {save space for future expansion}
  end;

  PChrGenFile = ^TChrGenFile;
  TChrGenFile = object (TObject)
    IoError : integer;
    ChrTableSize : word;
    CGFFile : file;
    Header : cgfHeader;
    ChrTablePtr : vgaChrTablePtr;
    constructor Init;
    destructor Done; virtual;
    procedure FreeChrTable;
    procedure OpenRead (FileName : PathStr);
    procedure ReadChrTable;
    procedure OpenWrite (FileName : PathStr);
    procedure WriteChrTable;
    procedure GetFontTable (ChrTable,StartChr,TotalChrs,Height : word);
  end;

implementation

uses

  Memory;

{
TChrGenFile
}

constructor TChrGenFile.Init;

begin
  inherited Init;
  Header.Version := cgfVersion
end;

{
Close file.
}

destructor TChrGenFile.Done;

begin
  {$I-} Close (CGFFile); {$I+}
  IoError := IoResult;
  inherited Done
end;

{
Dispose char table buffer.
}

procedure TChrGenFile.FreeChrTable;

begin
  if ChrTablePtr <> nil then
    FreeMem (ChrTablePtr,ChrTableSize)
end;

{
Open file for reading.
}

procedure TChrGenFile.OpenRead (FileName : PathStr);

begin
  Assign (CGFFile,FileName);
  {$I-} Reset  (CGFFile,1); {$I+}
  IoError := IoResult;
  if IoError = 0 then
  begin
    {$I-} BlockRead (CGFFile,Header,SizeOf (Header)); {$I+}
    IoError := IoResult;
    if IoError = 0 then
    begin
      if Header.Version = cgfVersion then
      begin
        ChrTableSize := Header.Height*Header.TotalChrs;
        ChrTablePtr := MemAlloc (ChrTableSize);
        if ChrTablePtr = nil then
          IoError := cgfMemAlloc
      end
      else
        IoError := cgfNotCGFFormat
    end
  end
end;

{
Read char table into buffer.
}

procedure TChrGenFile.ReadChrTable;

var

  ReadSize : word;

begin
  {$I-} Seek (CGFFile,SizeOf (Header)); {$I+}
  IoError := IoResult;
  if IoError = 0 then
  begin
    {$I-} BlockRead (CGFFile,ChrTablePtr^,ChrTableSize,ReadSize); {$I+}
    IoError := IoResult
  end
end;

{
Open file for writing.
}

procedure TChrGenFile.OpenWrite (FileName : PathStr);

begin
  Assign (CGFFile,FileName);
  {$I-} Rewrite  (CGFFile,1); {$I+}
  IoError := IoResult;
  if IoError = 0 then
  begin
    {$I-} BlockWrite (CGFFile,Header,SizeOf (Header)); {$I+}
    IoError := IoResult
  end
end;

{
Write char table from buffer.
}

procedure TChrGenFile.WriteChrTable;

var

  WriteSize : word;

begin
  {$I-} Seek (CGFFile,SizeOf (Header)); {$I+}
  IoError := IoResult;
  if IoError = 0 then
  begin
    {$I-} BlockWrite (CGFFile,ChrTablePtr^,ChrTableSize,WriteSize); {$I+}
    IoError := IoResult
  end
end;

{
Set header and copy font mem to a buffer.
}

procedure TChrGenFile.GetFontTable (ChrTable,StartChr,TotalChrs,Height : word);

begin 
  Header.Height := Height;
  Header.StartChr := StartChr;
  Header.TotalChrs := TotalChrs;
  ChrTableSize := Height*TotalChrs;
  ChrTablePtr := GetRamTable (StartChr,TotalChrs,Height,vgaChrTableLoc[ChrTable])
end;

end.
