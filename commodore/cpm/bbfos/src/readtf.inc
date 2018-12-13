{
SG Tools (C) 1992 Parsec, Inc.

The Read Text File module reads a CP/M text file into a double linked list
structure.  Each text line is saved in a line record with a poitner to the
string.  Only enough memory is allocated to hold each string, so there is
no waste!
}

const

  rtfMinFree = 1024; {min free memory}
  rtfMaxStr  = 255;  {max string size}

type

  rtfPStr = ^rtfStr;
  rtfStr = string[rtfMaxStr];
  rtfPLine = ^rtfLine;
  rtfLine = record
    Line : rtfPStr;
    Prev,
    Next : rtfPLine;
  end;

var

  rtfError,               {errors}
  rtfLines : integer;     {line count}
  rtfFirstPtr,            {first record pointer}
  rtfCurPtr : rtfPLine;   {current record pointer}
  rtfFile : text;         {text file to read}

procedure InitReadFile (FileName : bdosPathStr);

begin
  rtfError := 0;    {initilize vars}
  rtfLines := 0;
  rtfFirstPtr := nil;
  rtfCurPtr := nil;
  Assign (rtfFile, FileName);
  {$I-} Reset (rtfFile); {$I+}
  rtfError := IoResult
end;

procedure DoneReadFile;

var

  TempPtr : rtfPLine;

begin
  {$I-} Close (rtfFile); {$I+}
  rtfError := IoResult;
  if rtfFirstPtr <> nil then {dispose linked list structure}
  begin
    rtfCurPtr := rtfFirstPtr;
    repeat
      TempPtr := rtfCurPtr^.Next;
      FreeMem (rtfCurPtr^.Line,
      Length (rtfCurPtr^.Line^)+1);
      Dispose (rtfCurPtr);
      rtfCurPtr := TempPtr
    until rtfCurPtr = nil
  end;
end;

procedure ReadFile;

var

  TempStr : rtfStr;
  TempStrPtr : rtfPStr;
  TempPtr : rtfPLine;

begin
  {$I-} Readln (rtfFile,TempStr); {$I+}
  rtfError := IoResult;
  if (rtfError = 0) and
  (not eof (rtfFile)) then
  begin
    rtfLines := 1;
    New (rtfCurPtr);             {set up first record}
    rtfCurPtr^.Prev := nil;      {first records prev is nil}
    GetMem (TempStrPtr,          {allocate just string length + 1}
    Length (TempStr)+1);
    TempStrPtr^ := TempStr;
    rtfCurPtr^.Line := TempStrPtr;
    rtfFirstPtr := rtfCurPtr;
    while (rtfError = 0) and     {read in rest of file}
    (not eof (rtfFile)) and
    (Hi (MemAvail) > Hi (rtfMinFree)) do
    begin
      {$I-} Readln (rtfFile,TempStr); {$I+}
      rtfError := IoResult;
      if rtfError = 0 then
      begin
        rtfLines := rtfLines+1;  {add line record}
        New (TempPtr);
        rtfCurPtr^.Next := TempPtr;
        TempPtr^.Prev := rtfCurPtr;
        GetMem (TempPtr^.Line,   {allocate string length + 1}
        Length (TempStr)+1);
        TempPtr^.Line^ := TempStr;
        rtfCurPtr := TempPtr
      end
    end;
    rtfCurPtr^.Next := nil       {last record's next is nil}
  end
end;

function GetLine : rtfStr;

begin
  if rtfCurPtr <> nil then
  begin
    GetLine := rtfCurPtr^.Line^; {get current line}
    rtfCurPtr := rtfCurPtr^.Next {set up to read next line}
  end
end;
