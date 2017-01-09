{
SG Tools Pro (C) 1992 Steve Goldsmith

Z Blaster File Write module.
}

var

  zbfwError : integer; {errors}
  zbfwFile : file;     {sample file to read}

procedure InitWriteZBF (FileName : bdosPathStr);

begin
  zbfwError := 0;    {initilize vars}
  Assign (zbfwFile,FileName);
  {$I-} Rewrite (zbfwFile); {$I+}
  zbfwError := IoResult;
end;

procedure WriteZBFHeader;

begin
  {$I-} Seek (zbfwFile,0); {$I+}
  zbfwError := IoResult;
  if zbfwError = 0 then
  begin
    {$I-} BlockWrite (zbfwFile,zbfHeader^,1); {$I+}
    zbfwError := IoResult
  end
end;

procedure WriteZBFData;

begin
  {$I-} Seek (zbfwFile,1); {$I+}
  zbfwError := IoResult;
  if zbfwError = 0 then
  begin
    {$I-} BlockWrite (zbfwFile,zbfSamplePtr^,
    zbfHeader^.SizeLo div zbfBlockSize); {$I+}
    zbfwError := IoResult
  end
end;

procedure DoneWriteZBF;

begin
  {$I-} Close (zbfwFile); {$I+}
  zbfwError := IoResult
end;
