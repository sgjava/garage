{
SG Tools (C) 1992 Parsec, Inc.

The Directory module reads a CP/M directory into a double linked list structure.
No memory allocation error trapping.  READTF.INC uses such error trapping.
}

type

  dirPRec = ^dirRec;
  dirRec = record
    FileName : string [12];
    Prev,
    Next : dirPRec;
  end;

var

  dirCurDrive,             {current drive}
  dirCurUser : byte;       {current user}
  dirError,                {error codes}
  dirRecs : integer;       {records read}
  dirDMAPtr : bdosPDMABuf; {dma buffer}
  dirFCB : bdosFCBRec      {default fcb}
  absolute bdosDefaultFCB;
  dirFirstPtr,             {first record pointer}
  dirCurPtr : dirPRec;     {current record pointer}

procedure InitDir (Drive, User : byte;
                   WildCard : bdosPathStr);

var

  I : byte;

begin
  dirRecs := 0;
  dirDMAPtr := nil;            {init pointers}
  dirFirstPtr := nil;
  dirCurPtr := nil;
  dirError :=                  {set bdos error mode to return error}
  BDos (bdosSetErrorMode,bdosRetErrMode);
  dirCurDrive :=
  BDos (bdosCurrentDisk);      {save current drive and user}
  dirCurUser :=
  BDos (bdosUserCode,$ff);
  dirError :=
  BDos (bdosSelectDisk,Drive); {select drive to read}
  if dirError = 0 then
  begin
    dirError :=
    BDos (bdosUserCode,User);  {select user to read}
    dirFCB.Drive := 0;         {use default drive}
    for I := 0 to 7 do         {set wild card}
      dirFCB.FileName[I] := WildCard[I+1];
    for I := 0 to 2 do
      dirFCB.FileType[I] := WildCard[I+10];
    New (dirDMAPtr)            {allocate dma buffer}
  end
end;

procedure DoneDir;

var

  TempPtr : dirPRec;

begin
  if dirDMAPtr <> nil then
    Dispose (dirDMAPtr);     {dispose dma buffer}
  if dirFirstPtr <> nil then {dispose linked list structure}
  begin
    dirCurPtr := dirFirstPtr;
    repeat
      TempPtr := dirCurPtr^.Next;
      Dispose (dirCurPtr);
      dirCurPtr := TempPtr
    until dirCurPtr = nil
  end;
  dirError :=                {select previous drive}
  BDos (bdosSelectDisk,dirCurDrive);
  dirError :=                {select previous user}
  BDos (bdosUserCode,dirCurUser);
  dirError :=                {set bdos error mode to default}
  BDos (bdosSetErrorMode,bdosDefErrMode)
end;

function PackName (U : bdosPathStr) : bdosPathStr;

var

  I : byte;

begin
  repeat               {delete spaces from file name}
    I := Pos (' ',U);
    if I <> 0 then
      Delete (U,I,1)
  until I = 0;
  PackName := U
end;

procedure ReadDir;

var

  FCBPtr : bdosPFCBRec;
  TempPtr : dirPRec;

begin
  dirError :=                 {set new dma address}
  BDos (bdosSetDMAAddr,Addr (dirDMAPtr^));
  dirError :=                 {read fisrt dir fcbs}
  BDos(bdosSearchFirst,Addr (dirFCB));
  if dirError <> $ff then
  begin
    New (dirCurPtr);          {allocate first dir record}
    dirCurPtr^.Prev := nil;   {first record's prev is nil}
    dirFirstPtr := dirCurPtr;
    while dirError <> $ff do  {read and allocate remaining records}
    begin
      dirRecs := dirRecs+1;
      FCBPtr :=               {pointer to fcb in dma buffer}
      Ptr (Addr (dirDMAPtr^)+dirError shl 5);
      dirCurPtr^.FileName :=  {make file name}
      FCBPtr^.FileName+'.'+FCBPtr^.FileType;
      dirError :=             {bdos search for next dir entry}
      BDos (bdosSearchNext);
      if dirError <> $ff then
      begin
        TempPtr := dirCurPtr;       {save cur record pointer}
        New (dirCurPtr);            {allocate new record}
        TempPtr^.Next := dirCurPtr; {set links}
        dirCurPtr^.Prev := TempPtr
      end
    end;
    dirCurPtr^.Next := nil  {last record's next pointer is nil}
  end;
  dirError :=               {set default dma address}
  BDos (bdosSetDMAAddr,bdosDefaultFCB)
end;

function GetFileName : bdosPathStr;

begin
  if dirCurPtr <> nil then
  begin
    GetFileName := dirCurPtr^.FileName; {get current file name}
    dirCurPtr := dirCurPtr^.Next        {set up for next record}
  end
end;
