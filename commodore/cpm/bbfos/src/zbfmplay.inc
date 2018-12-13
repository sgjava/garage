{
Z Blaster Multi Player module

(C) 1992 Steve Goldsmith
}

const

  vicContReg1 = $d011; {vic control reg 1}
  timRes = 10227; {cia timer a resolution div 100}
  zbfmMinFree = 1024; {min free memory}

type

  zbfmFilePtr = ^zbfmFile;
  zbfmFile = record
    FileName : bdosPathStr;
    SamplePtr : zbfSampleArrPtr;
    AllocSize,
    SizeLo,
    Hz : integer;
    Prev,
    Next : zbfmFilePtr;
  end;

var

  zbfmFiles : integer;      {file count}
  zbfmFirstPtr,             {first record pointer}
  zbfmCurPtr : zbfmFilePtr; {current record pointer}

procedure MultiPlay (F : bdosPathStr; VolPlay, VolEnd : byte);

var

  BlankSts : byte;
  TempPtr : zbfmFilePtr;

begin
  TempPtr := zbfmFirstPtr;
  while (TempPtr^.FileName <> F) and (TempPtr^.Next <> nil) do
    TempPtr := TempPtr^.Next; {linear file name search}
  SetCIA2TimerA (timRes div (TempPtr^.Hz div 100));
  BlankSts := PortIn (vicContReg1) and $10;
  PortOut (vicContReg1,PortIn (vicContReg1) and $ef);
  Inline ($F3); {di                      ;disable hardware interrupt}
  PlaySample (Addr (TempPtr^.SamplePtr^),TempPtr^.SizeLo,VolPlay);
  Inline ($FB); {ei                      ;enable hardware interrupt}
  PortOut (vicContReg1,PortIn (vicContReg1) or BlankSts);
  SetVolume (VolEnd)
end;

procedure AddMultiPlay (F : bdosPathStr);

var

  TempPtr : zbfmFilePtr;

begin
  InitReadZBF (F+'.ZBF');
  if zbfError = 0 then
    ReadZBFData;
  if (zbfError = 0) and
  (Hi (MemAvail) > Hi (zbfmMinFree)) then
  begin
    zbfmFiles := zbfmFiles+1;  {add line record}
    New (TempPtr);
    TempPtr^.FileName := F;
    TempPtr^.SamplePtr := zbfSamplePtr;
    TempPtr^.AllocSize := zbfBlocks*zbfBlockSize;
    TempPtr^.SizeLo := zbfHeader^.SizeLo;
    TempPtr^.Hz := zbfHeader^.Hz;
    if zbfmFiles > 1 then
      zbfmCurPtr^.Next := TempPtr
    else
      zbfmFirstPtr := TempPtr;
    TempPtr^.Prev := zbfmCurPtr;
    zbfmCurPtr := TempPtr;
    zbfmCurPtr^.Next := nil       {last record's next is nil}
  end;
  DoneReadZBF (false)
end;

procedure InitMultiPlay;

begin
  zbfmFiles := 0;
  zbfmFirstPtr := nil;
  zbfmCurPtr := nil
end;

procedure DoneMultiPlay;

var

  TempPtr : zbfmFilePtr;

begin
  if zbfmFirstPtr <> nil then {dispose linked list structure}
  begin
    zbfmCurPtr := zbfmFirstPtr;
    repeat
      TempPtr := zbfmCurPtr^.Next;
      FreeMem (zbfmCurPtr^.SamplePtr,zbfmCurPtr^.AllocSize);
      Dispose (zbfmCurPtr);
      zbfmCurPtr := TempPtr
    until zbfmCurPtr = nil
  end
end;
