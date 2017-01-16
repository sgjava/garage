{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Snip player with single step and PCX exporter.  Play dialog is used in 256
color mode and is not visible on desk top!
}

unit SnipDlg;

{$I APP.INC}
{$X+}

interface

uses

  Dos,
  Objects, Drivers, Views, Dialogs,
  App,
{$IFDEF UseDLL}
  CyberApi,
{$ELSE}
  VGA,
{$ENDIF}
  Snip, PCX, TVStr, CACmds;

type

  PSnipDialog = ^TSnipDialog;

  TSnipDialog = object (TDialog)
    PlayFlag,
    PalFlag : boolean;
    FrameCnt,
    PlayTime : longint;
    SnpName : PathStr;
    Snip : TDecodeSnpScr;
    EncodePCX : TEncodePCXFile256;
    InfoLine : PInputLine;
    constructor Init (FileName : PathStr);
    destructor Done; virtual;
    procedure DispFrame;
    procedure Step;
    procedure Play;
    procedure ExportPCX;
    procedure GetEvent(var Event: TEvent); virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure WriteStr256 (X, Y, C : byte; S : string);
    procedure PlayerInfo;
  end;

const

  {graphic colors using snip palette}

  snpBlack    =  0; snpBlue         =  1; snpGreen      =  2; snpCyan      =  3;
  snpRed      =  4; snpMagenta      =  5; snpBrown      =  6; snpLightGray =  7;
  snpDarkGray =  8; snpLightBlue    =  9; snpLightGreen = 10; snpLightCyan = 11;
  snpLightRed = 12; snpLightMagenta = 13; snpYellow     = 14; snpWhite     = 15;

implementation

{
TSnipDialog is not visible in 256 color mode and is used to handle keyboard
events.
}

constructor TSnipDialog.Init (FileName : PathStr);

var

  R : TRect;

begin
  R.Assign (0,0,76,7);
  inherited Init (R,'Snip Controller');
  Options := Options or ofCenterX or ofCenterY;

  GetExtent (R);
  R.A.X := R.A.X+2;
  R.B.X := R.A.X+4;
  R.A.Y := R.A.Y+1;
  R.B.Y := R.A.Y+1;
  Insert(New(PStaticText, Init(R,'Name')));

  GetExtent (R);
  R.A.X := R.A.X+2;
  R.B.X := R.B.X-2;
  R.A.Y := R.A.Y+2;
  R.B.Y := R.A.Y+1;
  InfoLine := New (PInputLine,Init (R,127));
  InfoLine^.Options := InfoLine^.Options and not ofSelectable;
  Insert (InfoLine);
  InfoLine^.SetData (FileName);

  GetExtent (R);
  R.A.X := R.A.X+1;
  R.B.X := R.A.X+10;
  R.A.Y := R.B.Y-3;
  R.B.Y := R.A.Y+2;
  Insert(New(PButton, Init(R, '~S~tep', cmStep, bfNormal)));
  R.A.X := R.B.X+2;
  R.B.X := R.A.X+10;
  Insert(New(PButton, Init(R, '~P~lay', cmPlay, bfNormal)));
  R.A.X := R.B.X+2;
  R.B.X := R.A.X+10;
  Insert(New(PButton, Init(R, 'PC~X~', cmPCX, bfNormal)));
  R.A.X := R.B.X+2;
  R.B.X := R.A.X+10;
  Insert(New(PButton, Init(R, 'O~K~', cmOk, bfDefault)));

  SnpName := FileName;
  PalFlag := true;
  FrameCnt := 0;
  Snip.Init (SnpName)
end;

{
Dispose Snip screen decoder.
}

destructor TSnipDialog.Done;

begin
  Snip.Done;
  inherited Done
end;

{
Display frame and increment frame counter.
}

procedure TSnipDialog.DispFrame;

begin
  if Snip.ReadError = snpNoError then
  begin
    Snip.DecodeFrame (FrameCnt);
    Inc (FrameCnt);
    if FrameCnt = Snip.Header.Frames then
      FrameCnt := 0 {last frame reached, so reset counter}
  end
end;

{
Single step frame display.
}

procedure TSnipDialog.Step;

begin
  WriteStr256 (33,13,snpLightGreen,IntToRightStr (FrameCnt+1,6));
  DispFrame;
  PlayFlag := false
end;

{
Set play flag and timer.
}

procedure TSnipDialog.Play;

begin
  if not PlayFlag then
  begin
    PlayFlag := true;
    PlayTime := longint (Ptr (Seg0040,$6c)^) {read time from bios area}
  end
end;

{
Convert frame on mode 13h screen to 256 color PCX.
}

procedure TSnipDialog.ExportPCX;

var

  FrameNum : longint;
  FileName : PathStr;
  NumStr : string[4];

begin
  FileName := GetFileNameStr (SnpName);
  if byte (FileName[0]) > 4 then    {only use first 4 chars of name}
    FileName[0] := #4;
  if FrameCnt = 0 then
    FrameNum := Snip.Header.Frames
  else
    FrameNum := FrameCnt;
  FormatStr (NumStr,'%0#%04d',FrameNum); {add frame number to filename}
  FileName := AddExtStr (FileName+NumStr,'PCX');
  EncodePCX.Init (FileName);
  if EncodePCX.WriteError = 0 then
  begin
    EncodePCX.SetHeader (Snip.Header.HorzRes,  {set pcx header}
    Snip.Header.VertRes,8,1);
    EncodePCX.WriteHeader;                     {write pcx header}
    EncodePCX.EncodeFile (Snip.DecodeBlockPtr, {encode screen to file}
    vgaScr256Line);
    if PalFlag then {if this is first export then convert palette to 8 bit}
    begin
      EncodePCX.Palette64to256 (Snip.PalPtr);
      PalFlag := false
    end;
    EncodePCX.WritePal256 (Snip.PalPtr); {write 256 color PCX palette}
    if EncodePCX.WriteError = 0 then     {invoke single step mode}
      Step
  end;
  EncodePCX.Done
end;

{
Use dialog's idle processing to play snip.
}

procedure TSnipDialog.GetEvent (var Event : TEvent);

begin
  inherited GetEvent (Event); {commands take priority over animation}
  if (PlayFlag) and (longint (Ptr (Seg0040,$6c)^) >= PlayTime) and
  (Event.What <> evCommand) then
  begin
    PlayTime := {set timer value to wait for next frame}
    longint (Ptr (Seg0040,$6c)^)+Snip.Header.Delay;                            {next frame time}
    WriteStr256 (33,13,snpLightGreen,IntToRightStr (FrameCnt+1,6));
    DispFrame
  end
end;

{
Handle Snip player events.
}

procedure TSnipDialog.HandleEvent(var Event: TEvent);

begin
  inherited HandleEvent(Event);
  case Event.What of
    evCommand:
      begin
        case Event.Command of
          cmStep : Step;
          cmPlay : Play;
          cmPCX  : ExportPCX
        else
          Exit
        end;
        ClearEvent(Event)
      end
  end
end;

{
Write 256 color string using BIOS.
}

procedure TSnipDialog.WriteStr256 (X, Y, C : byte; S : string);

var

  CurX, ChrEle : byte;
  WChr : char;

begin
  for ChrEle := 1 to Length (S) do
  begin
    WChr := S[ChrEle];
    CurX := Pred (X+ChrEle);
    asm
      mov     ah,02h
      mov     bh,00h
      mov     dl,CurX
      mov     dh,Y
      int     10h       {plot cursor}
      mov     ah,0ah
      mov     al,WChr   {char to write}
      mov     bh,0      {screen page}
      mov     bl,C      {color}
      mov     cx,1      {write char 1 time}
      int     10h       {write char}
    end
  end
end;

{
Display snip info in 256 color mode.
}

procedure TSnipDialog.PlayerInfo;

var

  I : word;

begin
  for I := 0 to 24 do
    WriteStr256 (32,I,snpBlue,'лллллллл');
  WriteStr256 (33,1,snpWhite,' P');
  WriteStr256 (35,1,snpCyan,'lay ');
  WriteStr256 (33,3,snpWhite,' S');
  WriteStr256 (35,3,snpCyan,'tep ');
  WriteStr256 (33,5,snpCyan,' PC');
  WriteStr256 (36,5,snpWhite,'X  ');
  WriteStr256 (33,7,snpCyan,' O');
  WriteStr256 (35,7,snpWhite,'K   ');

  WriteStr256 (33,11,snpGreen,'Frame ');
  WriteStr256 (33,14,snpLightGreen,IntToRightStr (Snip.Header.Frames,6));
  WriteStr256 (33,16,snpGreen,'Size  ');
  WriteStr256 (33,18,snpLightGreen,IntToRightStr (Snip.Header.HorzRes,6));
  WriteStr256 (33,19,snpLightGreen,IntToRightStr (Snip.Header.VertRes,6));
  WriteStr256 (33,21,snpGreen,'Delay ');
  WriteStr256 (33,23,snpLightGreen,'   /18');
  WriteStr256 (33,23,snpLightGreen,IntToRightStr (Snip.Header.Delay,3));
end;

end.
