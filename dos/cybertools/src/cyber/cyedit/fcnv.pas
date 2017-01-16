program FontConvert;

{$I APP.INC}
{$X+}

uses

  Dos, Memory,
  VGA, VGACGFil, TVStr;

{
Save CGF file from table.
}

procedure SaveChrFile (F : PathStr);

var

  BufSize : longint;
  TempBuf : pointer;
  RawFile : file;
  ChrFile : TChrGenFile;

begin
  Assign (RawFile,F);
  {$I-} Reset  (RawFile,1); {$I+}
  if IoResult = 0 then
  begin
    BufSize := {$I-} FileSize  (RawFile); {$I+}
    Writeln ('Converting '+F+' ',BufSize);
    TempBuf := MemAlloc (BufSize);
    {$I-} BlockRead (RawFile,TempBuf^,BufSize); {$I+}
    {$I-} Close  (RawFile); {$I+}
    ChrFile.Init;
    with ChrFile.Header do
    begin
      Height := BufSize div 256;
      StartChr := 0;
      TotalChrs := 256;
    end;
    ChrFile.ChrTableSize := BufSize;
    ChrFile.ChrTablePtr := TempBuf;
    ChrFile.OpenWrite (AddExtStr (F,'CGF'));
    if ChrFile.IoError = 0 then
      ChrFile.WriteChrTable
    else
      Writeln ('Problem writing font file.');
    ChrFile.FreeChrTable;
    ChrFile.Done
  end
end;

begin
  if ParamCount > 0 then
    SaveChrFile (ParamStr (1))
end.