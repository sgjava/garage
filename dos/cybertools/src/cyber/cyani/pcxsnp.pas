{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Convert all PCX files in focused file list to a Snip file.  The first PCX
in the list determines Snip size and palette.
}

unit PCXSNP;

{$I APP.INC}
{$X+}

interface

uses

  Dos, Objects, Drivers, Views, Dialogs, App, MsgBox,
{$IFDEF UseDLL}
  CyberApi,
{$ELSE}
  VGA,
{$ENDIF}
  PCX, Snip, TVStr;

type

  PPCXSNP = ^TPCXSNP;

  TPCXSNP = object (TDialog)
    CompareFlag : boolean;
    ConvSeq,
    SnipXSize,
    SnipYSize,
    FrameSize,
    TotalFrames,
    FrameCnt,
    FrameDelay,
    FrameTableEle : word;
    FrameFilePos : longint;
    DelayStr : string[9];
    SnipName : PathStr;
    FileListColl : PStringCollection;
    PCXDecode1 : TDecodePCXFile256;
    PCXDecode2 : TDecodePCXFile256;
    SnipEncode : TWriteSnpFile;
    InfoLine : PInputLine;
    DelayLine : PInputLine;
    DelayBar : PScrollBar;
    constructor Init (FL : PStringCollection);
    procedure UpdateInfo (Msg : string);
    procedure UpdateDelay;
    procedure ScanFirst;
    procedure ScanNext;
    procedure CreateSnip;
    procedure CompareFrames (OldFrame, NewFrame : vgaDataBufPtr);
    procedure DoneConvert;
    procedure ConvertFrame;
    procedure GetEvent(var Event: TEvent); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

const

  {conversion sequences}

  snpWait       = 0;
  snpScanFirst  = 1;
  snpScanNext   = 2;
  snpCreateSnip = 3;
  snpConvert    = 4;
  snpDone       = 5;

implementation

{
TPCXSNP dialog converts PCX files to Snip animation file.
}

constructor TPCXSNP.Init (FL : PStringCollection);

var

  R : TRect;

begin
  R.Assign (0,0,65,8);
  inherited Init (R,'Make Snip');
  Options := Options or ofCenterX or ofCenterY;

  GetExtent (R);
  R.A.X := R.A.X+2;
  R.B.X := R.B.X-2;
  R.A.Y := R.A.Y+2;
  R.B.Y := R.A.Y+1;
  InfoLine := New (PInputLine,Init (R,127));
  InfoLine^.Options := InfoLine^.Options and not ofSelectable;
  Insert (InfoLine);

  GetExtent (R);
  R.A.X := R.A.X+2;
  R.B.X := R.A.X+20;
  R.A.Y := R.A.Y+5;
  R.B.Y := R.A.Y+1;
  DelayBar := New (PScrollBar, Init (R));
  FrameDelay := 1;
  DelayBar^.SetParams (1,1,1080,18,1);
  DelayBar^.Options := DelayBar^.Options or ofSelectable;
  Insert (DelayBar);

  GetExtent (R);
  R.A.X := R.A.X+1;
  R.B.X := R.A.X+6;
  R.A.Y := R.A.Y+4;
  R.B.Y := R.A.Y+1;
  Insert (New (PLabel,Init (R,'~D~elay',DelayBar)));

  GetExtent (R);
  R.A.X := R.A.X+24;
  R.B.X := R.A.X+11;
  R.A.Y := R.A.Y+5;
  R.B.Y := R.A.Y+1;
  DelayLine := New (PInputLine,Init (R,127));
  DelayLine^.Options := DelayLine^.Options and not ofSelectable;
  Insert (DelayLine);

  GetExtent (R);
  R.A.X := R.B.X-24;
  R.B.X := R.A.X+10;
  R.A.Y := R.B.Y-3;
  R.B.Y := R.A.Y+2;
  Insert (New (PButton,Init (R,'~C~ancel',cmCancel,bfNormal)));
  R.A.X := R.B.X+2;
  R.B.X := R.A.X+10;
  Insert (New (PButton,Init (R,'O~K~',cmOK,bfDefault)));

  UpdateInfo ('Set delay, press OK to process current directory.');
  FileListColl := FL;   {string collection of pcx file names}
  UpdateDelay;          {show delay value}
  ConvSeq := snpWait;   {conversion sequence set to wait}
  CompareFlag := true   {pcx compare toggle}
end;

{
Display string in status line.
}

procedure TPCXSNP.UpdateInfo (Msg : string);

begin
  InfoLine^.SetData (Msg)
end;

{
Display frame delay in x/18th seconds.
}

procedure TPCXSNP.UpdateDelay;

begin
  DelayStr := IntToRightStr (FrameDelay,5)+'/18';
  DelayLine^.SetData (DelayStr)
end;

{
Scan first PCX and determine if it meets Snip requirements.
}

procedure TPCXSNP.ScanFirst;

begin
  UpdateInfo ('Scanning '+GetFileNameStr (PString (FileListColl^.At (0))^));
  DelayBar^.Options :=   {disable delay slider during conversion}
  DelayBar^.Options and not ofSelectable;
  DelayBar^.SetState (sfDisabled,true);
  if DelayBar^.GetState (sfSelected) then {select next item if slider selected}
    SelectNext (true);
  TotalFrames := FileListColl^.Count; {total pcx files}
  FrameCnt := 1;                      {current frame in list}
  PCXDecode1.Init (PString (FileListColl^.At (0))^); {decode pcx and set snip header}
  if PCXDecode1.ReadError = 0 then
  begin
    with PCXDecode1 do
    begin
      SnipXSize := Header.XMax-Header.XMin+1;
      SnipYSize := Header.YMax-Header.YMin+1;
      DecodeFile
    end;
    FrameSize := SnipXSize*SnipYSize; {calc total frame bytes}
    ConvSeq := snpScanNext            {set conversion seq to scan next pcx}
  end
  else
  begin {pcx not 256 color or too big}
    ConvSeq := snpDone;
    MessageBox(PString (FileListColl^.At (0))^+' is not in expected format.',
    nil,mfError+mfOkButton);
    UpdateInfo ('Processing terminated.')
  end;
  PCXDecode1.Done
end;

{
Make sure all PCXs are the same size and type as first PCX.
}

procedure TPCXSNP.ScanNext;

begin
  if FrameCnt < FileListColl^.Count then
  begin
    UpdateInfo ('Scanning '+GetFileNameStr (PString (FileListColl^.At (FrameCnt))^));
    PCXDecode1.Init (PString (FileListColl^.At (FrameCnt))^);
    if PCXDecode1.ReadError = 0 then
    begin
      PCXDecode1.DecodeFile;
      if (PCXDecode1.Header.XMax-PCXDecode1.Header.XMin+1 <> SnipXSize) or
      (PCXDecode1.Header.YMax-PCXDecode1.Header.YMin+1 <> SnipYSize) then
      begin {this pcx is different size then first}
        ConvSeq := snpDone;
        MessageBox(PString (FileListColl^.At (FrameCnt))^+' not correct size.',
        nil,mfError+mfOkButton);
        UpdateInfo ('Processing terminated.')
      end
    end
    else
    begin {pcx not 256 color}
      ConvSeq := snpDone;
      MessageBox('PCX decode error scanning '+PString (FileListColl^.At (FrameCnt))^,
      nil,mfError+mfOkButton);
      UpdateInfo ('Processing terminated.')
    end;
    PCXDecode1.Done;
    Inc (FrameCnt) {set for next frame}
  end
  else
    ConvSeq := snpCreateSnip {last pcx scanned, so set up to create snip file}
end;

{
Create Snip file from first PCX.
}

procedure TPCXSNP.CreateSnip;

begin
  SnipName := AddExtStr (PString (FileListColl^.At (0))^,'SNP'); {snip has same name as first pcx}
  UpdateInfo ('Adding '+GetFileNameStr (PString (FileListColl^.At (0))^));
  PCXDecode1.Init (PString (FileListColl^.At (0))^);
  if PCXDecode1.ReadError = 0 then
  begin
    PCXDecode1.DecodeFile;     {decode pcx}
    PCXDecode1.Palette256to64; {convert 8 bit pcx pal to 6 bit snip pal}
    SnipEncode.Init (SnipName,TotalFrames,
    PCXDecode1.XSize,PCXDecode1.YSize,FrameDelay);
    SnipEncode.WritePal256 (@PCXDecode1.ReadPalette);     {write palette}
    SnipEncode.WriteFrameTable;                           {write frame table}
    SnipEncode.WriteFirstFrame (PCXDecode1.DecodeBufPtr); {write first frame}
    SnipEncode.WriteFrameByte (0);                        {end of frame marker}
    FrameFilePos := SizeOf (SnipEncode.Header)+           {frame seek pos}
    SizeOf (vgaPalette)+(TotalFrames+1)*SizeOf (longint);
    SnipEncode.FrameTablePtr^[0] := FrameFilePos;         {set frame seek pos}
    FrameTableEle := 1;                                   {frame table index}
    FrameFilePos := FrameFilePos+                         {set for next frame pos}
    PCXDecode1.XSize*PCXDecode1.YSize+1;
    FrameCnt := 1;                                        {convert count}
    ConvSeq := snpConvert                                 {start convert}
  end
  else
  begin {scanning process should prevent this}
    PCXDecode1.Done;
    ConvSeq := snpDone;
    UpdateInfo ('Processing terminated.')
  end
end;

{
Compare old frame to new frame and do differental encoding.
}

procedure TPCXSNP.CompareFrames (OldFrame, NewFrame : vgaDataBufPtr);

var

  SkipLen   : byte;
  FramePos, LastPos : word;

begin
  SkipLen := 0;
  FramePos := 0;
  SnipEncode.FrameTablePtr^[FrameTableEle] := FrameFilePos; {set frame seek pos}
  Inc (FrameTableEle);                                      {set for next}
  LastPos := FrameSize-1;                                   {last byte of image}
  for FramePos := 0 to LastPos do                           {process entire frame}
  begin
    if OldFrame^[FramePos] = NewFrame^[FramePos] then
    begin
      Inc (SkipLen);        {if pixels same then increment skip length}
      if SkipLen = 63 then
      begin                 {max skip length reached, so write encode byte}
        SnipEncode.WriteFrameByte (SkipLen);
        Inc (FrameFilePos); {track seek pos}
        SkipLen := 0        {reset skip length}
      end
    end
    else
    begin
      if SkipLen > 0 then
      begin                 {write encode byte}
        SnipEncode.WriteFrameByte (SkipLen);
        Inc (FrameFilePos); {track seek pos}
        SkipLen := 0        {reset skip length}
      end;
      SnipEncode.WriteFrameByte (NewFrame^[FramePos]); {write as is}
      Inc (FrameFilePos)    {track seek pos}
    end
  end;
  SnipEncode.WriteFrameByte (0); {write end of frame marker}
  Inc (FrameFilePos)             {track seek pos}
end;

{
Flush write buffer and close files.
}

procedure TPCXSNP.DoneConvert;

begin
  if ConvSeq = snpConvert then
  begin
   if CompareFlag then         {close open pcx file}
     PCXDecode1.Done
   else
     PCXDecode2.Done;
   SnipEncode.FlushBuf;        {flush write buffer}
   SnipEncode.FrameTablePtr^[FrameTableEle] := FrameFilePos;
   SnipEncode.WriteFrameTable; {write frame table}
   SnipEncode.Done;
   ConvSeq := snpDone
 end
end;

{
Encode PCX image to Snip frame.
}

procedure TPCXSNP.ConvertFrame;

begin
  if FrameCnt < FileListColl^.Count then
  begin
    UpdateInfo ('Adding '+ GetFileNameStr (PString (FileListColl^.At (FrameCnt))^));
    if CompareFlag then {decide which pcx is new/old and convert to snip frame}
    begin
      PCXDecode2.Init (PString (FileListColl^.At (FrameCnt))^);
      if PCXDecode2.ReadError = 0 then
      begin
        PCXDecode2.DecodeFile;
        CompareFrames (PCXDecode1.DecodeBufPtr,PCXDecode2.DecodeBufPtr)
      end;
      PCXDecode1.Done;
      CompareFlag := false
    end
    else
    begin
      PCXDecode1.Init (PString (FileListColl^.At (FrameCnt))^);
      if PCXDecode1.ReadError = 0 then
      begin
        PCXDecode1.DecodeFile;
        CompareFrames (PCXDecode2.DecodeBufPtr,PCXDecode1.DecodeBufPtr)
      end;
      PCXDecode2.Done;
      CompareFlag := true
    end;
    Inc (FrameCnt) {set up for next frame}
  end
  else
  begin
    DoneConvert; {last pcx reached, so complete processing}
    UpdateInfo ('Finished processing '+GetFileNameStr (SnipName))
  end
end;

{
Handle dialog's idle processing before commands.
}

procedure TPCXSNP.GetEvent (var Event: TEvent);

begin
  case ConvSeq of {process conversion sequences}
    snpScanFirst  : ScanFirst;
    snpScanNext   : ScanNext;
    snpCreateSnip : CreateSnip;
    snpConvert    : ConvertFrame
  end;
  inherited GetEvent (Event)
end;

{
Handle dialog's events.
}

procedure TPCXSNP.HandleEvent(var Event: TEvent);

begin
  if Event.What = evCommand then
  case Event.Command of
    cmCancel : DoneConvert; {stop convert}
    cmOK :                  {start convert if waiting}
    if ConvSeq = snpWait then
    begin
      ConvSeq := snpScanFirst;
      ClearEvent(Event)
    end
    else
      if ConvSeq <> snpDone then {ok does nothing if processing in progress}
        ClearEvent(Event)
  end;
  inherited HandleEvent(Event);
  if (Event.What = evBroadcast) and {handle delay slider command}
  (Event.Command = cmScrollBarChanged) then
  begin
    FrameDelay := DelayBar^.Value; {set frame delay by slider value}
    UpdateDelay                    {show change}
  end;
end;

end.
