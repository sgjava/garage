{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Common dialogs and controls for CyberTools apps including VGA only
CyberFont apps.
}

unit CommDlgs;

{$I APP.INC}

interface

uses

  Dos, Drivers, Objects, Memory, Views, Dialogs, TextView, Validate, App,
  StdDlg, MsgBox, Tools, DirView,
{$IFDEF UseDLL}
  CyberApi,
{$ELSE}
  VGA,
{$ENDIF}
{$IFDEF UseNewEdit}
  NewEdit,
{$ELSE}
  Editors,
{$ENDIF}
  TVStr;

const

  cmMsgButtonPressCF = 65100; {adjust vga palette commands}
  cmDefaultPal       = 65101;
  cmRootDir          = 65102; {commands used by dir window}
  cmExpand           = 65103;
  cmWildcard         = 65104;
  cmNewDrive         = 65105;
  cmUpdateFiles      = 65106;
  cmAllFiles         = 65107;
  cmMsgButtonPress   = 65108; {commands used by message buttons}
  cmUpdateLog        = 65109; {update log with a string}
  cmUpdateLogRaw     = 65110;
  cmUpdateLogBack    = 65111;

  CCharColor = #$00;          {app tv palette additions for font 2 table}
  CCharPal   = #136;
  CDirViewer = #7#27#9#8;     {dir outline viewer palette}

  cfButton      = #32#224#225#226#32; {graphic radio button chars}
  cfButtonOffOn = #225#227;
  cfBox         = #32#228#229#230#32; {graphic check box chars}
  cfBoxOffOn    = #229#231;

  dtDosNameSet : TCharSet =   {filter set for valid dos names}
  ['0'..'9','A'..'Z','a'..'z','_','^','$','~','!',
  '#','%','&','-','{','}','@','`',#39,'(',')','.'];

  cdLogWidth    = 160;  {max width of log window}
  cdRightMargin = 75;   {set right margin for editor}

type

  ScrOptsData = record {controls data}
    SMode,
    FntTbl1,
    FntTbl2 : integer;
    FChr,
    LChr : string[3];
  end;

  PRadioButtonsCF = ^TRadioButtonsCF;
  TRadioButtonsCF = object (TRadioButtons)
    procedure Draw; virtual;
  end;

  PCheckBoxesCF = ^TCheckBoxesCF;
  TCheckBoxesCF = object (TCheckBoxes)
    procedure Draw; virtual;
  end;

  PScrOptsDlg = ^TScrOptsDlg;
  TScrOptsDlg = object (TDialog)
    ScrMode :PCheckBoxesCF;
    ChrTable1,
    ChrTable2 : PRadioButtonsCF;
    FirstField,
    LastField : PInputLine;
    constructor Init;
    function Valid (Command : word) : boolean; virtual;
  end;

  PColPalView = ^TColPalView;
  TColPalView = object (TView)
    StartColor : byte;
    constructor Init (var Bounds : TRect; StartCol : byte);
    procedure Draw; virtual;
  end;

  PMsgButtonsCF = ^TMsgButtonsCF;
  TMsgButtonsCF = object (TRadioButtonsCF)
    procedure Press (Item: Integer); virtual;
    procedure MovedTo (Item:Integer); virtual;
  end;

  PPalDlg = ^TPalDlg;
  TPalDlg = object (TDialog)
    CurPal : vgaPalette;
    RedBar,
    GreenBar,
    BlueBar : PScrollBar;
    DefColor : PMsgButtonsCF;
    constructor Init;
    procedure SetColorBars (Color : byte);
    procedure ChangeDAC;
    procedure HandleEvent (var Event: TEvent); virtual;
  end;

  PChrSetView = ^TChrSetView;
  TChrSetView = object (TView)
    procedure Draw; virtual;
  end;

  PChrSetDlg = ^TChrSetDlg;
  TChrSetDlg = object (TDialog)
    constructor Init (Name : PathStr; XLen,YLen : word);
    function GetPalette: PPalette; virtual;
  end;

  PWinSizeDlg = ^TWinSizeDlg;
  TWinSizeDlg = object (TDialog)
    constructor Init;
  end;

  PMsgButtons = ^TMsgButtons;
  TMsgButtons = object (TRadioButtons)
    procedure Press (Item: Integer); virtual;
    procedure MovedTo (Item:Integer); virtual;
  end;

  PDriveDlg = ^TDriveDlg;
  TDriveDlg = object (TDialog)
    DriveBox : PListBox;
    constructor Init;
    destructor Done; virtual;
    procedure GetData (var Rec); virtual;
    procedure SetData (var Rec); virtual;
    procedure SizeLimits (var Min , Max : TPoint); virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  PSearchRec = ^TSearchRec;

  PDirViewer = ^TDirViewer;
  TDirViewer = object (TDirectoryViewer)
    procedure Focused (I : integer); virtual;
    procedure Adjust(Node: Pointer; Expand: Boolean); virtual;
    function GetPalette : PPalette; virtual;
  end;

  PInfoPane = ^TInfoPane;
  TInfoPane = object(TFileInfoPane)
    procedure Draw; virtual;
  end;

  PDirWinLine = ^TDirWinLine;
  TDirWinLine = object(TInputLine)
    constructor Init (var Bounds: TRect; AMaxLen: Integer);
    procedure HandleEvent (var Event: TEvent); virtual;
  end;

  PDirWindow = ^TDirWindow;
  TDirWindow = object (TDialog)
    CloseCmd : boolean;
    AppCmd : word;
    WildCard : PathStr;
    NameLine : PDirWinLine;
    DirView : PDirViewer;
    FileList : PFileList;
    InfoPane : PInfoPane;
    constructor Init (T : string; Drive, FMask : PathStr; ACmd : word; CCmd : boolean);
    function FocFileName : PathStr;
    function FocDirName : PathStr;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  PStrListDlg = ^TStrListDlg;
  TStrListDlg = object (TDialog)
    StrBox : PListBox;
    constructor Init (TStr : string);
    destructor Done; virtual;
  end;

  PLogTerm = ^TLogTerm;
  TLogTerm = object(TTerminal)
    procedure StrWrite(var S : TextBuf; Count : byte); virtual;
  end;

  PLogWin = ^TLogWin;
  TLogWin = object (TWindow)
    LogFileOpen : boolean;
    LogFile : Text;
    LogFileBuf : array [0..4095] of char;
    LogTerm : PLogTerm;
    constructor Init (WinTitle : TTitleStr; ABufSize : word);
    destructor Done; virtual;
    procedure OpenLogFile (FileName : PathStr);
    procedure CloseLogFile;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  PCyFileEditor = ^TCyFileEditor;
  TCyFileEditor = object (TFileEditor)
    function Save : boolean;
    procedure HandleEvent (var Event: TEvent); virtual;
    function Valid (Command : word) : boolean; virtual;
  end;

  PCyEditWindow = ^TCyEditWindow;
  TCyEditWindow = object (TEditWindow)
    constructor Init (var Bounds : TRect;
    FileName : FNameStr; ANumber : integer);
  end;

  PCySortedListBox = ^TCySortedListBox;
  TCySortedListBox = object(TSortedListBox)
    procedure HandleEvent (var Event: TEvent); virtual;
  end;

  function AppSystemError (ErrorCode: integer; Drive : byte) : integer;
  function SelectFile (Title : string; WildCard : PathStr; ReadFlag : boolean) : PathStr;

implementation

const

  {critical error handler messages}

  sysErrorMessage : array [0..15] of string [42] = (
  'Disk is write-protected in drive %c',
  'Unknown unit error on drive %c',
  'Disk is not ready in drive %c',
  'Unknown command on drive %c',
  'Data integrity error on drive %c',
  'Bad requested structure length on drive %c',
  'Seek error on drive %c',
  'Unknown media type in drive %c',
  'Sector not found on drive %c',
  'Printer out of paper',
  'Write fault on drive %c',
  'Read fault on drive %c',
  'Hardware failure on drive %c',
  'Bad memory image of FAT detected',
  'Device access error',
  'Insert diskette in drive %c');

{
TV app critical error handler.
}

function AppSystemError (ErrorCode: integer; Drive : byte) : integer;

var

  P : longint;

begin
  P := longint (Drive+65); {param for formatstr}
  MessageBox (sysErrorMessage[ErrorCode],@P,mfOkButton+mfError);
  AppSystemError := 1      {do not retry}
end;

{
Use standard TV file box.
}

function SelectFile (Title : string; WildCard : PathStr; ReadFlag : boolean) : PathStr;

var

  F : file;

begin
  if Application^.ExecuteDialog (New (PFileDialog,Init (WildCard,Title,
    '~N~ame',fdOkButton,100)),@WildCard) <> cmCancel then
  begin
    if ReadFlag then
      SelectFile := WildCard
    else
    begin
      Assign (F,WildCard);
      {$I-} Reset (F); {$I+}
      if IoResult = 0 then {see if file exists before writes}
      begin
        {$I-} Close (F); {$I+}
        if MessageBox (WildCard+' already exists.  Erase and continue?',
        nil,mfConfirmation or mfYesNoCancel) = cmYes then
          SelectFile := WildCard
        else
          SelectFile := ''
      end
      else
        SelectFile := WildCard
    end
  end
  else
    SelectFile := ''
end;

{
TRadioButtonsCF graphic radio buttons.
}

procedure TRadioButtonsCF.Draw;

begin
  DrawMultiBox (cfButton,cfButtonOffOn)
end;

{
TCheckBoxesCF graphic check boxes.
}

procedure TCheckBoxesCF.Draw;

begin
  DrawMultiBox (cfBox,cfBoxOffOn)
end;

{
TScrOptsDlg dialog to select various screen options and font tables.
}

constructor TScrOptsDlg.Init;

var

  R : TRect;

begin
  R.Assign (0,0,52,12);
  inherited Init (R,'Screen');
  Options := Options or ofValidate;

  R.Assign (2,3,17,7);
  ScrMode := New (PCheckBoxesCF,Init(R,
    NewSItem ('640 X 400',
    NewSItem ('Paging',
    NewSItem ('8 colors',
    nil)))));
  Insert (ScrMode);
  R.Assign (1,2,13,3);
  Insert (New (PLabel,Init (R,'~S~creen mode',ScrMode)));

  R.Assign (18,3,33,7);
  ChrTable1 := New (PRadioButtonsCF,Init (R,
    NewSItem ('0',
    NewSItem ('1',
    NewSItem ('2',
    NewSItem ('3',
    NewSItem ('4',
    NewSItem ('5',
    NewSItem ('6',
    NewSItem ('7',
    nil))))))))));
  Insert (ChrTable1);
  R.Assign (17,2,30,3);
  Insert (New (PLabel,Init (R,'Font ~1~ table',ChrTable1)));

  R.Assign (34,3,50,7);
  ChrTable2 := New (PRadioButtonsCF,Init (R,
    NewSItem ('0',
    NewSItem ('1',
    NewSItem ('2',
    NewSItem ('3',
    NewSItem ('4',
    NewSItem ('5',
    NewSItem ('6',
    NewSItem ('7',
    nil))))))))));
  Insert (ChrTable2);
  R.Assign (33,2,46,3);
  Insert (New (PLabel,Init (R,'Font ~2~ table',ChrTable2)));

  R.Assign (13,8,18,9);
  FirstField := New(PInputLine,Init(R,3));
  FirstField^.SetValidator (New (PRangeValidator,Init (0,255)));
  Insert (FirstField);
  R.Assign(1,8,12,9);
  Insert (New (PLabel,Init (R,'~F~irst char',FirstField)));

  R.Assign (13,9,18,10);
  LastField := New(PInputLine,Init(R,3));
  LastField^.SetValidator (New (PRangeValidator,Init (0,255)));
  Insert (LastField);
  R.Assign(1,9,12,10);
  Insert (New (PLabel,Init (R,'~L~ast  char',LastField)));

  R.Assign (26,9,36,11);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (38,9,48,11);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)))
end;

{
Make sure last save char >= first save char before closing with OK.
}

function TScrOptsDlg.Valid (Command : word) : boolean;

var

  Temp : boolean;

begin
  Temp := inherited Valid(Command);
  if (Command <> cmCancel) and
  (StrToInt (LastField^.Data^) < StrToInt (FirstField^.Data^)) then
  begin
    MessageBox ('Last save char must be greater than or equal to First save char.',nil,mfOkButton+mfError);
    Temp := false
  end;
  Valid := Temp
end;

{
TColPalView vertical fills view with block chars starting with any color.
}

constructor TColPalView.Init (var Bounds : TRect; StartCol : byte);

begin
  inherited Init (Bounds);
  StartColor := StartCol
end;

{
Draw color blocks using character 219 'Û'.
}

procedure TColPalView.Draw;

var

  MiniBuf : word;
  Y, Color : byte;

begin
  Color := GetColor (6) and $f0;
  for Y := 0 to Size.Y-1 do
  begin
    MiniBuf := ((Color or (StartColor+Y)) shl 8) or 219;
    WriteLine (0,Y,1,1,MiniBuf)
  end
end;

{
TMsgButtonsCF sends a message any time button is moved or pressed.
}

{
Send message radio button pressed.
}

procedure TMsgButtonsCF.Press (Item : integer);

begin
  inherited Press (Item);
  Message (Owner,evBroadcast,cmMsgButtonPressCF,nil)
end;

{
Send message when button moved.
}

procedure TMsgButtonsCF.MovedTo (Item:Integer);

begin
  inherited MovedTo (Item);
  Message (Owner,evBroadcast,cmMsgButtonPressCF,nil)
end;

{
TPalDlg adjusts VGA DAC for any of the 16 text colors.
}

constructor TPalDlg.Init;

var

  R : TRect;

begin
  R.Assign (0,0,40,21);
  inherited Init (R,'Adjust Palette');

  R.Assign(2,3,38,11);
  DefColor := New(PMsgButtonsCF,Init(R, {use bios default color names}
    NewSItem('Black',
    NewSItem('Blue',
    NewSItem('Green',
    NewSItem('Cyan',
    NewSItem('Red',
    NewSItem('Magenta',
    NewSItem('Brown',
    NewSItem('Light Gray',
    NewSItem('Gray',
    NewSItem('Light Blue',
    NewSItem('Light Green',
    NewSItem('Light Cyan',
    NewSItem('Light Red',
    NewSItem('Light Magenta',
    NewSItem('Yellow',
    NewSItem('White',
    nil))))))))))))))))));
  Insert(DefColor);

  R.Assign(1,2,7,3);
  Insert(New(PLabel,Init(R,'~C~olors',DefColor)));

  R.Assign(6,3,7,11);
  Insert(New(PColPalView,Init(R,0)));

  R.Assign(22,3,23,11);
  Insert(New(PColPalView,Init(R,8)));

  R.Assign(2,12,36,13);
  RedBar := New (PScrollBar,Init (R));
  RedBar^.SetParams (0,0,63,8,1);
  RedBar^.Options := RedBar^.Options or ofSelectable;
  Insert (RedBar);

  R.Assign(1,11,5,12);
  Insert (New (PLabel,Init (R,'~R~ed',RedBar)));
  R.Assign(2,14,36,15);
  GreenBar := New (PScrollBar,Init (R));
  GreenBar^.SetParams (0,0,63,8,1);
  GreenBar^.Options := GreenBar^.Options or ofSelectable;
  Insert (GreenBar);

  R.Assign(1,13,7,14);
  Insert (New (PLabel,Init (R,'~G~reen',GreenBar)));
  R.Assign(2,16,36,17);
  BlueBar := New (PScrollBar,Init (R));
  BlueBar^.SetParams (0,0,63,8,1);
  BlueBar^.Options := BlueBar^.Options or ofSelectable;
  Insert (BlueBar);

  R.Assign(1,15,6,16);
  Insert (New (PLabel,Init (R,'~B~lue',BlueBar)));

  R.Assign(1,18,11,20);
  Insert(New(PButton,Init(R,'O~K~',cmOk,bfDefault)));

  R.Assign(12,18,22,20);
  Insert(New(PButton,Init(R,'Cancel',cmCancel,bfNormal)));

  R.Assign(23,18,36,20);
  Insert(New(PButton,Init(R,'~D~efault',cmDefaultPal,bfNormal)));

  GetDACBlock (@CurPal,0,256);
  SetColorBars (0);
  SelectNext (false)
end;

{
Set RGB sliders to color in DAC.
}

procedure TPalDlg.SetColorBars (Color : byte);

var

  R,G,B : byte;

begin
  GetDAC (GetAttrCont (Color),R,G,B);
  RedBar^.SetValue (R);
  GreenBar^.SetValue (G);
  BlueBar^.SetValue (B)
end;

{
Find which scroll bar is selected and set that DAC register.
}

procedure TPalDlg.ChangeDAC;

var

  R,G,B : byte;

begin
  GetDAC (GetAttrCont (DefColor^.Value),R,G,B);
  if RedBar^.State and sfSelected = sfSelected then
    R := RedBar^.Value
  else
    if GreenBar^.State and sfSelected = sfSelected then
      G := GreenBar^.Value
    else
      if BlueBar^.State and sfSelected = sfSelected then
        B := BlueBar^.Value;
  SetDAC (GetAttrCont (DefColor^.Value),R,G,B);
end;

{
Process RGB sliders and commands.
}

procedure TPalDlg.HandleEvent(var Event: TEvent);

begin
  if (Event.What = evCommand) and
  ((Event.Command = cmCancel) or
  (Event.Command = cmClose)) then
  SetDACBlock (@CurPal,0,256); {set default palette}
  inherited HandleEvent(Event);
  case Event.What of
    evCommand:
    begin
      case Event.Command of
        cmOk         : Close;
        cmDefaultPal :
        begin
          SetDACBlock (@CurPal,0,256);   {set default palette}
          SetColorBars (DefColor^.Value) {set scroll bars too}
        end
      else
        Exit
      end;
      ClearEvent (Event)
    end;
    evBroadcast:
    begin {process broadcasts from sliders}
      case Event.Command of
        cmScrollBarChanged : ChangeDAC;
        cmMsgButtonPressCF : SetColorBars (DefColor^.Value)
      end
    end
  end
end;

{
TChrSetView is used to display graphics, .CGF and .PCX files. Foreground color
must have bit 3 set (colors 8 - 15) to display the second VGA font.  You can
use any window size as long as the total characters are <= 256 (X*Y <= 256).
}

procedure TChrSetView.Draw;

var

  Buf: TDrawBuffer;
  X, Y: Integer;
  Color: word;

begin
  Color := GetColor(33);      {color added after last dialog entry}
  for Y := 0 to Size.Y - 1 do {draw character set to fit view}
  begin
    for X := 0 to Size.X - 1 do
      Buf[x] := (Y*Size.X+X) or (Color shl 8);
    WriteBuf (0,Y,Size.X,1,Buf);
  end
end;

{
TChrSetDlg displays a TChrSetView in a dialog with custom palette.
}

constructor TChrSetDlg.Init (Name : PathStr; XLen,YLen : word);

var

  R : TRect;

begin
  R.Assign (0,0,XLen+2,YLen+2); {leaves room for view of xlen,ylen}
  inherited Init (R,Name);
  GetExtent (R);
  R.Grow (-1,-1);
  Insert (New (PChrSetView,Init (R)))
end;

{
Get graphic color addition to dialog palette.
}

function TChrSetDlg.GetPalette: PPalette;

const

  CNewBlueDialog = CBlueDialog+CCharPal;
  CNewCyanDialog = CCyanDialog+CCharPal;
  CNewGrayDialog = CGrayDialog+CCharPal;
  P: array[dpBlueDialog..dpGrayDialog] of string[Length(CNewBlueDialog)] =
  (CNewBlueDialog,CNewCyanDialog,CNewGrayDialog);

begin
  GetPalette := @P[Palette]
end;

{
TWinSizeDlg allows you to select graphics window size matrix.  Notice that
each matrix size adds up to 256 chars.  Matrix sizes can be <= 256, but I
selected sizes that use all chars in set.
}

constructor TWinSizeDlg.Init;

var

  R : TRect;

begin
  R.Assign (0,0,26,9);
  inherited Init (R,'Window Size');

  R.Assign (2,2,24,5);
  Insert (New (PRadioButtonsCF,Init (R,
    NewSItem ('128 X 256',
    NewSItem ('256 X 128',
    NewSItem ('512 X 64',
    nil))))));

  R.Assign (2,6,12,8);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (14,6,24,8);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)))
end;

{
TMsgButtons broadcasts a message to the owner object when a button is
pressed or selected.
}

{
Send message when radio button is pressed.
}

procedure TMsgButtons.Press (Item : integer);

begin
  inherited Press (Item);
  Message (Owner,evBroadcast,cmMsgButtonPress,nil)
end;

{
Send message when radio button is moved.
}

procedure TMsgButtons.MovedTo (Item : integer);

begin
  inherited MovedTo (Item);
  Message (Owner,evBroadcast,cmMsgButtonPress,nil)
end;

constructor TDriveDlg.Init;

var

  Drive : char;
  S : string;
  R : TRect;
  VScrollBar : PScrollBar;

begin
  R.Assign (0, 0, 9, 8);
  inherited Init (R,'');
  Options := Options or ofCentered;
  R.Assign (6,2,7,6);
  New (VScrollBar,Init (R));
  Insert (VScrollBar);

  R.Assign (2,2,6,6);
  DriveBox := New (PListBox,Init (R,1,VScrollBar));
  DriveBox^.List := New (PStringCollection,Init (0,1));
  Insert (DriveBox);
  for Drive := 'A' to 'Z' do
  begin
    if DriveValid (Drive) then
    begin
      S := Drive + ':';
      DriveBox^.List^.Insert (NewStr (S))
    end
  end;
  DriveBox^.SetRange (DriveBox^.List^.Count); {set list's range}
  DriveBox^.DrawView                          {draw box}
end;

{
Dispose string collection.
}

destructor TDriveDlg.Done;

begin
  if DriveBox^.List <> nil then
    Dispose (DriveBox^.List,Done);
  inherited Done
end;

{
Return focused drive letter.
}

procedure TDriveDlg.GetData (var Rec);

begin
  char (Rec) := PString(DriveBox^.List^.At (DriveBox^.Focused))^[1]
end;

{
Ignore data sent to dialog.
}

procedure TDriveDlg.SetData (var Rec);

begin
end;

{
Dialog only needs to be big enough to hold drive (C:).
}

procedure TDriveDlg.SizeLimits (var Min, Max : TPoint);

begin
  inherited SizeLimits(Min, Max);
  Min.X := 9
end;

procedure TDriveDlg.HandleEvent (var Event : TEvent);

begin
  if ((Event.What = evMouseDown) and (Event.Double) and
  (DriveBox^.MouseInView (Event.Where))) or
  ((Event.What = evKeyDown) and (Event.KeyCode = kbEnter)) then
  begin
    Event.What := evCommand;
    Event.Command := cmOK;
    PutEvent (Event);
    ClearEvent (Event)
  end;
  inherited HandleEvent (Event)
end;

{
TDirViewer is a directory selector tree for use in dialogs.
}

{
Update file list when a new directory is focused.
}

procedure TDirViewer.Focused (I : integer);

begin
  inherited Focused (I);
  if not LowMemory then
    PDirWindow (Owner)^.FileList^.ReadDirectory (
    PDirWindow (Owner)^.FocDirName+PDirWindow (Owner)^.WildCard)
end;

{
Expand or contract branch if not all ready in that state.
}

procedure TDirViewer.Adjust (Node : pointer; Expand : boolean);

begin
  if Expand then
  begin
    if not IsExpanded (Node) then
      inherited Adjust (Node,Expand)
  end
  else
    if IsExpanded (Node) then
      inherited Adjust (Node,Expand)
end;

{
Use dialog palette instead of window palette provided by TDirectoryViewer.
}

function TDirViewer.GetPalette: PPalette;

const

  NewPal : string[Length(CDirViewer)] = CDirViewer;

begin
  GetPalette := @NewPal;
end;

{
TInfoPane displays info on selected file.
}

procedure TInfoPane.Draw;

var

  PMFlag : boolean;
  Color : word;
  Params : array[0..7] of LongInt;
  FSizeStr : string[9];
  MonthStr : string[3];
  Str : String[80];
  FmtId: string;
  Time : DateTime;
  Path : PathStr;
  DrawBuf : TDrawBuffer;

const

  sDirectoryLine = ' %-12s %-9s %3s %2d, %4d  %2d:%02d%cm';
  sFileLine      = ' %-12s %-9d %3s %2d, %4d  %2d:%02d%cm';
  Month : array[1..12] of String[3] =
  ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

begin
  Path := PDirWindow (Owner)^.FocDirName+PDirWindow (Owner)^.WildCard;
  Color := GetColor ($01);
  MoveChar(DrawBuf, ' ', Color, Size.X);
  MoveStr(DrawBuf[1], Path, Color);      {display path}
  WriteLine(0, 0, Size.X, 1, DrawBuf);
  if S.Name <> '' then
  begin
    Params[0] := LongInt(@S.Name);
    MoveChar(DrawBuf, ' ', Color, Size.X); {display file}
    Params[0] := LongInt(@S.Name);
    if S.Attr and Directory <> 0 then
    begin
      FmtId := sDirectoryLine;
      FSizeStr := 'Directory';
      Params[1] := LongInt(@FSizeStr);
    end
    else
    begin
      FmtId := sFileLine;
      Params[1] := S.Size;
    end;
    UnpackTime(S.Time, Time);
    MonthStr := Month[Time.Month];
    Params[2] := LongInt(@MonthStr);
    Params[3] := Time.Day;
    Params[4] := Time.Year;
    PMFlag := Time.Hour >= 12;
    Time.Hour := Time.Hour mod 12;
    if Time.Hour = 0 then
      Time.Hour := 12;
    Params[5] := Time.Hour;
    Params[6] := Time.Min;
    if PMFlag then             {handle am/pm}
      Params[7] := byte ('p')
    else
      Params[7] := byte ('a');
    FormatStr(Str, FmtId, Params)
  end
  else
    Str := FillStr (' ',Size.X); {handle null file name}
  MoveStr (DrawBuf,Str,Color);
  WriteLine (0,1,Size.X,1,DrawBuf)
end;

{
TDirWinLine allows editing file names.
}

constructor TDirWinLine.Init (var Bounds: TRect; AMaxLen: Integer);

begin
  inherited Init (Bounds, AMaxLen);
  EventMask := EventMask or evBroadcast
end;

{
Display file name if line is not selected.
}

procedure TDirWinLine.HandleEvent (var Event : TEvent);

var

  FName : PathStr;

begin
  inherited HandleEvent (Event);
  if (Event.What = evBroadcast) and (Event.Command = cmFileFocused) and
  (State and sfSelected = 0) then
  begin
    FName := PDirWindow (Owner)^.FocFileName;
    if FName[byte (FName[0])] = '\' then
      FName := '';
    SetData (FName)
  end
end;

{
DOS directory tree window.
}

constructor TDirWindow.Init (T : string; Drive, FMask : PathStr; ACmd : word; CCmd : boolean);

var

  R: TRect;
  vSB, hSB: PScrollBar;

begin
  R.Assign (0, 0, 67, 17);
  inherited Init (R,T);
  Options := Options or ofCentered;
  CloseCmd := CCmd;
  AppCmd := ACmd;
  WildCard := FMask;

  GetExtent (R);
  R.Assign(R.A.X+22,R.A.Y+4,R.A.X+23,R.B.Y-5);
  vSB := New(PScrollBar, Init(R));
  vSB^.Options := vSB^.Options or ofPostProcess;
  Insert(vSB);

  GetExtent (R);
  R.Assign(R.A.X+4,R.B.Y-5,R.A.X+21,R.B.Y-4);
  hSB := New(PScrollBar, Init(R));
  hSB^.Options := hSB^.Options or ofPostProcess;
  Insert(hSB);

  GetExtent (R);
  R.Assign (R.A.X+3,R.A.Y+4,R.A.X+22,R.B.Y-5);
  DirView := New (PDirViewer,Init (R,hSB,vSB,
  New (PDirectory,Init (Drive))));
  with DirView^ do
  begin
    Options := Options or ofFirstClick or ofFramed;
    Adjust (GetRoot,true);
    GrowMode := gfGrowHiY;
    Update;
  end;
  Insert (DirView);
  GetExtent (R);
  R.Assign (R.A.X+1,R.A.Y+2,R.A.X+6,R.A.Y+3);
  Insert (New (PLabel,Init (R,'~D~ir',DirView)));

  GetExtent (R);
  R.Assign (R.A.X+24,R.A.Y+3,R.B.X-12,R.A.Y+4);
  NameLine := New (PDirWinLine,Init (R,128));
  NameLine^.SetValidator (New (PFilterValidator, Init (dtDosNameSet)));
  Insert (NameLine);
  GetExtent (R);
  R.Assign (R.A.X+23,R.A.Y+2,R.A.X+30,R.A.Y+3);
  Insert (New (PLabel,Init (R,'~N~ame',NameLine)));

  GetExtent (R);
  R.Assign (R.A.X+24,R.B.Y-5,R.B.X-12,R.B.Y-4);
  hSB := New(PScrollBar, Init (R));
  hSB^.Options := hSB^.Options or ofPostProcess;
  Insert (hSB);

  GetExtent (R);
  R.Assign (R.A.X+24,R.A.Y+5,R.B.X-12,R.B.Y-5);
  FileList := New (PFileList, Init (R, PScrollBar (hSB)));
  Insert (FileList);
  GetExtent (R);
  R.Assign (R.A.X+23,R.A.Y+4,R.A.X+30,R.A.Y+5);
  Insert (New (PLabel,Init (R,'Files',FileLIst)));

  GetExtent (R);
  R.Assign(R.A.X+2,R.B.Y-3,R.B.X-12,R.B.Y-1);
  InfoPane := New (PInfoPane, Init(R));
  Insert (InfoPane);

  if Drive[byte (Drive[0])] <> '\' then
    FileList^.ReadDirectory (Drive+'\'+WildCard)
  else
    FileList^.ReadDirectory (Drive+WildCard);

  GetExtent (R);
  R.Assign(R.B.X-12,R.A.Y+2,R.B.X-2,R.A.Y+4);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign(R.A.X,R.A.Y+2,R.B.X,R.A.Y+4);
  Insert (New (PButton,Init (R,'~R~oot',cmRootDir,bfNormal)));
  R.Assign(R.A.X,R.A.Y+2,R.B.X,R.A.Y+4);
  Insert (New (PButton,Init (R,'~E~xpand',cmExpand,bfNormal)));
  R.Assign(R.A.X,R.A.Y+2,R.B.X,R.A.Y+4);
  Insert (New (PButton,Init (R,'~M~ask',cmWildcard,bfNormal)));
  R.Assign(R.A.X,R.A.Y+2,R.B.X,R.A.Y+4);
  Insert (New (PButton,Init (R,'Dri~v~e',cmNewDrive,bfNormal)));
  R.Assign(R.A.X,R.A.Y+2,R.B.X,R.A.Y+4);
  Insert (New (PButton,Init (R,'~U~pdate',cmUpdateFiles,bfNormal)));
  R.Assign(R.A.X,R.A.Y+2,R.B.X,R.A.Y+4);
  Insert (New (PButton,Init (R,'~A~ll',cmAllFiles,bfNormal)));
  FileList^.Focus
end;

{
Return focused file name.  If name is a directory then append '\'.
}

function TDirWindow.FocFileName : PathStr;

var

  S : PSearchRec;

begin
  S := PSearchRec (FileList^.List^.At (FileList^.Focused));
  if S^.Attr and Directory = 0 then
    FocFileName := S^.Name
  else
    FocFileName := S^.Name+'\'
end;

{
Return focused directory name and append '\' if needed.
}

function TDirWindow.FocDirName : PathStr;

var

  D : PathStr;

begin
  D := PDirectory(DirView^.GetNode (DirView^.Foc))^.Dir^;
  if D[byte (D[0])] <> '\' then
    FocDirName := D+'\'
  else
    FocDirName := D
end;

{
If OK is pressed the assigned command is sent to TApplication.HandleEvent as
a broadcast.
}

procedure TDirWindow.HandleEvent (var Event : TEvent);

{
Read root and first level child dirs into tree.
}

procedure ReadTree (Drive : char);

var

  S : TSearchRec;
  D : PathStr;

begin
  with DirView^ do
  begin
    Dispose (Root,Done);                       {dispose old dir tree}
    Root := New (PDirectory,Init (Drive+':')); {alloc new tree}
    if DosError <> 0 then                      {handle dos errors}
    begin
      if DosError <> 18 then
      begin
        Dispose (Root,Done);               {dispose dir tree}
        GetDir (0,D);                      {revert to default dir}
        Root := New (PDirectory,Init (D))  {alloc new tree}
      end
      else                                 {no files found}
      begin
        FillChar (S,SizeOf (S),0); {empty search rec for infopane}
        Message (InfoPane,evBroadcast,cmFileFocused,@S);
        NameLine^.SetData (S.Name) {clear name line}
      end
    end;
    Adjust (Root,true);                 {expand dirs off root}
    Foc := 0;                           {focus root}
    SearchPos := 0;
    OldFoc := 0;
    Focused (Foc);
    SetCursor (0,0);
    Update;
    DrawView
  end
end;

{
Read default dir into tree.
}

procedure DefRootDir;

var

  Drive : PathStr;

begin
  GetDir (0,Drive);     {default dir}
  ReadTree (Drive[1])   {read tree}
end;

{
Expand all child dirs if not expanded.
}

procedure ExpandDir;

begin
  with DirView^ do
  begin
    Adjust (GetNode (Foc),not IsExpanded (GetNode (Foc)));
    Update;
    DrawView
  end
end;

{
Allow user to change wild card.
}

procedure GetWildCard;

var

  W : PathStr;

begin
  W := WildCard;
  if InputBox ('','File mask',W,12) <> cmCancel then
  begin
    WildCard := UpCaseStr (W);
    DirView^.Focused (DirView^.Foc)
  end
end;

{
Select new drive and read tree.
}

procedure NewDrive;

var

  Drive : char;
  D : PDriveDlg;

begin
  D := New (PDriveDlg,Init);
  if Application^.ExecuteDialog (D,@Drive) <> cmCancel then
    ReadTree (Drive)
end;

{
Read file list.
}

procedure UpdateFiles;

begin
  DirView^.Focused (DirView^.Foc)
end;

{
Process all files in list.
}

procedure DoAllFiles;

procedure SendMsg (Item : pointer); far;

var

  FName : PathStr;
  S : PSearchRec;

begin
  S := PSearchRec (Item);
  if (S^.Attr and Directory = 0) and
  (not LowMemory) then
  begin
    NameLine^.Data^ := S^.Name;
    Message (Application,evBroadcast,AppCmd,@Self)
  end
end;

var

  CurFileName : PathStr;

begin
  if MessageBox (#13#3'Process all files?',
  nil,mfConfirmation or mfYesNoCancel) = cmYes then
  begin
    CurFileName := NameLine^.Data^;
    FileList^.List^.ForEach (@SendMsg);
    NameLine^.Data^ := CurFileName
  end
end;

begin
  if (Event.What = evKeyDown) and
  (Event.KeyCode = kbEsc) then
  begin
    Close;
    Exit
  end;
  inherited HandleEvent (Event);
  case Event.What of
    evCommand :
    begin
      case Event.Command of
        cmOk          : {do not send dirs or '' names}
        begin
{
          if (NameLine^.Data^[byte (NameLine^.Data^[0])] <> '\') and
          (NameLine^.Data^ <> '') then
}
          if NameLine^.Data^ <> '' then
          begin
            Message (Application,evBroadcast,AppCmd,@Self);
            if CloseCmd then
            begin
              Close;
              Exit
            end
          end
        end;
        cmRootDir     : DefRootDir;
        cmExpand      : ExpandDir;
        cmWildcard    : GetWildCard;
        cmNewDrive    : NewDrive;
        cmUpdateFiles : UpdateFiles;
        cmAllFiles    :
        begin
          DoAllFiles;
          if CloseCmd then
          begin
            Close;
            Exit
          end
        end
      else
        Exit
      end;
      ClearEvent (Event)
    end
  end
end;

{
TStrListDlg is a sorted string list.
}

constructor TStrListDlg.Init (TStr : string);

var

  R : TRect;
  VScrollBar : PScrollBar;

begin
  R.Assign (0,0,80,10);
  inherited Init (R,TStr);
  Options := Options or ofCentered;

  R.Assign (77,2,78,8);
  New (VScrollBar,Init (R));
  Insert (VScrollBar);

  R.Assign (2,2,77,8);
  StrBox := New (PListBox,Init (R,1,VScrollBar));
  Insert (StrBox);
  StrBox^.List := New (PStringCollection,Init (0,1));
end;

{
Dispose string collection.
}

destructor TStrListDlg.Done;

begin
  if StrBox^.List <> nil then
    Dispose (StrBox^.List,Done);
  inherited Done
end;

{
TLogTerm is a TTerminal used in the log window TLogWin.
}

{
Put string in text view without using slow CalcWidth method.  CalcWidth goes
through all lines to find the longest one.  The more lines the slower it
gets.  A constant is used in place of CalcWidth to improve performance.
}

procedure TLogTerm.StrWrite (var S : TextBuf; Count : byte);

var

  I, J: Word;
  ScreenLines: Word;

begin
  if Count = 0 then
    Exit else
    if Count >= BufSize then
      Count := BufSize-1;
  ScreenLines := Limit.Y;
  J := 0;
  for I := 0 to Count-1 do
    case S[I] of
      #13 : Dec (Count)
      else
      begin
        if S[I] = #10 then Inc (ScreenLines);
        S[J] := S[I];
        Inc(J)
      end
    end;
  while not CanInsert (Count) do
  begin
    QueBack := NextLine (QueBack);
    Dec (ScreenLines)
  end;
  if LongInt (QueFront) + Count >= BufSize then
  begin
    I := BufSize - QueFront;
    Move (S,Buffer^[QueFront], I);
    Move (S[I],Buffer^, Count - I);
    QueFront := Count - I
  end
  else
  begin
    Move (S,Buffer^[QueFront],Count);
    Inc (QueFront,Count)
  end;
  SetLimit (cdLogWidth,ScreenLines); {use ctlogwidth instead of calcwidth}
  ScrollTo (0, ScreenLines+1);
  I := PrevLines (QueFront,1);
  if I <= QueFront then I := QueFront - I
  else I := BufSize - (I - QueFront);
  SetCursor (I, ScreenLines-Delta.Y-1);
  DrawView
end;

{
TLogWin is a for logging events or as a dumb TTY.
}

constructor TLogWin.Init (WinTitle : TTitleStr; ABufSize : word);

var

  R : TRect;
  HScrollBar, VScrollBar : PScrollBar;

begin
  Desktop^.GetExtent (R);
  R.A.Y := R.B.Y-7;
  inherited Init (R,WinTitle,wnNoNumber);
  Options := Options or ofTileable;
  HScrollBar := StandardScrollBar (sbHorizontal or sbHandleKeyboard);
  Insert (HScrollBar);
  VScrollBar := StandardScrollBar (sbVertical or sbHandleKeyboard);
  Insert (VScrollBar);
  GetExtent (R);
  R.Grow (-1,-1);
  New (LogTerm, Init (R,HScrollBar,VScrollBar,ABufSize));
  if Application^.ValidView (LogTerm) <> nil then
    Insert (LogTerm);
  LogFileOpen := false
end;

{
Make sure log file is closed.
}

destructor TLogWin.Done;

begin
  CloseLogFile;
  inherited Done
end;

{
Open log file.
}

procedure TLogWin.OpenLogFile (FileName : PathStr);

begin
  if not LogFileOpen then
  begin
    Assign (LogFile,FileName);
    SetTextBuf (LogFile,LogFileBuf);
    {$I-} Append (LogFile); {$I+}
    if IoResult = 0 then
      LogFileOpen := true
    else
    begin
      {$I-} Rewrite (LogFile); {$I+}
      LogFileOpen := IoResult = 0
    end
  end
end;

procedure TLogWin.CloseLogFile;

begin
  if LogFileOpen then
  begin
    {$I-} SYSTEM.Close (LogFile); {$I+}
    LogFileOpen := false
  end
end;

{
Handle log window events.
}

procedure TLogWin.HandleEvent (var Event : TEvent);

procedure UpdateLog (S : string);

var

  TBuf : TextBuf;

begin
  if LogFileOpen then
  begin
    {$I-} WriteLn (LogFile); {$I+}
    {$I-} Write (LogFile,S) {$I+}
  end;
  S := #10+S;
  Move (S[1],TBuf[0],byte (S[0]));
  LogTerm^.StrWrite (TBuf,byte (S[0]))
end;

procedure UpdateLogRaw (S : string);

var

  TBuf : TextBuf;

begin
  if LogFileOpen then
    {$I-} Write (LogFile,S); {$I+}
  Move (S[1],TBuf[0],byte (S[0]));
  LogTerm^.StrWrite (TBuf,byte (S[0]))
end;

procedure UpdateLogBack (S : string);

var

  TBuf : TextBuf;

begin
  if LogFileOpen then
    {$I-} Write (LogFile,S); {$I+}
  Move (S[1],TBuf[0],byte (S[0]));
  LogTerm^.StrWrite (TBuf,byte (S[0]));
  Dec (LogTerm^.QueFront,byte (S[0]))
end;

begin
  inherited HandleEvent(Event);
  if Event.What = evBroadcast then
  case Event.Command of
    cmUpdateLog     : UpdateLog (PString (Event.InfoPtr)^);
    cmUpdateLogRaw  : UpdateLogRaw (PString (Event.InfoPtr)^);
    cmUpdateLogBack : UpdateLogBack (PString (Event.InfoPtr)^)
  end
end;

{
Use CyberTools save routines.
}

function TCyFileEditor.Save : boolean;

begin
  if FileName = '' then
    FileName := 'UNTITLED.TXT';
 Save := SaveFile
end;

procedure TCyFileEditor.HandleEvent (var Event: TEvent);

begin
  if (Event.What = evCommand) and (Event.Command = cmSave) then
  begin
    Save;
    ClearEvent (Event)
  end;
  inherited HandleEvent(Event)
end;

function TCyFileEditor.Valid (Command: Word): Boolean;

begin
  if Command = cmValid then Valid := IsValid else
  begin
    Valid := true;
    if Modified then
    begin
      if FileName = '' then
      begin
        case MessageBox ('Close untitled file?',
        nil, mfInformation + mfYesNoCancel) of
          cmYes : Modified := false; {close untitled file without saving}
          cmNo : Valid := false;
          cmCancel : Valid := false
        end
      end
      else
      begin
        case MessageBox (FileName+' has been modified. Save?',
        nil, mfInformation + mfYesNoCancel) of
          cmYes:
          begin
            Save;
            Modified := false {file saved}
          end;
          cmNo : Modified := false;
          cmCancel : Valid := false
        end
      end
    end
  end
end;

{TCyEditWindow }

constructor TCyEditWindow.Init (var Bounds : TRect;
                          FileName : FNameStr; ANumber : integer);
var

  HScrollBar, VScrollBar : PScrollBar;
  Indicator : PIndicator;
  R : TRect;

begin
  TWindow.Init (Bounds, '', ANumber); {bypass inherited constructor}
  Options := Options or ofTileable;   {we set the rest same as inherited}
  R.Assign (18,Size.Y-1,Size.X-2,Size.Y);
  HScrollBar := New (PScrollBar, Init (R));
  HScrollBar^.Hide;
  Insert (HScrollBar);
  R.Assign (Size.X - 1, 1, Size.X, Size.Y - 1);
  VScrollBar := New (PScrollBar, Init(R));
  VScrollBar^.Hide;
  Insert (VScrollBar);
  R.Assign (2, Size.Y - 1, 16, Size.Y);
  Indicator := New (PIndicator, Init(R));
  Indicator^.Hide;
  Insert (Indicator);
  GetExtent (R);
  R.Grow (-1, -1);
  Editor := New(PCyFileEditor, Init (R,HScrollBar,
  VScrollBar,Indicator, FileName)); {use new file editor}
{$IFDEF UseNewEdit}
  Editor^.AutoIndent := True;
  Editor^.Word_Wrap := True;
  Editor^.Right_Margin := cdRightMargin;
{$ENDIF}
  Insert (Editor);
end;

{
Convert all chars to upper case for TSortedListBox incremental search.
}

procedure TCySortedListBox.HandleEvent (var Event : TEvent);

begin
  if (Event.What = evKeyDown) and
  (Event.CharCode <> #0) then
    Event.CharCode := UpCase (Event.CharCode);
  inherited HandleEvent (Event)
end;

end.
