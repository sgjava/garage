{
Turbo Vision CyberTools 2.0
(C) 1994 Steve Goldsmith
All Rights Reserved

PX Browse is a generic paradox table browser and supporting tools to
interface Turbo Vision to the OOP Database Framework.
}

unit PXBrowse;

{$I APP.INC}
{$X+}

interface

uses

  Dos,                       {system units}
  OOPXENG, PXENGINE,         {paradox engine 3.0 and framework units}
  Drivers, Objects, Views,   {tv units}
  Validate, Dialogs, MsgBox,
  Editors, App, Memory,
  CommDlgs, TVStr;           {cybertools units}

const

  pxbBlobNames :    {names used in place of data for blob input lines}
  array [0..4] of string [17] =
  (
  '<BLOB Memo>',
  '<BLOB Binary>',
  '<BLOB Fmt Memo>',
  '<BLOB OLE Object>',
  '<BLOB Graphic>'
  );
  pxbMaxUMemoSize = 16384;           {max unformatted memo blob size}
  pxbFixedMax = 1e13;                {max double val formatted as -0.00}

{px browser commands}

  cmFieldAdd       = 65300;
  cmFieldDelete    = 65301;
  cmFieldEdit      = 65302;
  cmFieldEnter     = 65303;
  cmFieldExit      = 65304;
  cmFieldChanged   = 65305;

type

  PpxbFieldName = ^TpxbFieldName;
  TpxbFieldName = object (TStaticText)
    StartLoc,
    StartSize : TPoint;
    constructor Init (var Bounds : TRect; const AText : string);
    procedure CalcBounds (var Bounds : TRect; Delta : TPoint); virtual;
  end;

  PpxbInputLine = ^TpxbInputLine;
  TpxbInputLine = object (TInputLine)
    FieldTyp : PXFieldType;
    FieldSub : PXFieldSubType;
    FieldNum : FieldNumber;
    RecordNum : RecordNumber;
    StartLoc,
    StartSize,
    TabPos : TPoint;
    DownLine,
    UpLine,
    HomeLine,
    EndLine,
    TopLine : PpxbInputLine;
    constructor Init (var Bounds : TRect; AMaxLen : Integer);
    procedure CalcBounds (var Bounds : TRect; Delta : TPoint); virtual;
    procedure SetState (AState : word; Enable : boolean); virtual;
    function Valid (Command : word): boolean; virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  TpxbEngineCfgRec = record
    EngTyp,
    DosShr,
    WinShr,
    CrtFmt,
    LckMod,
    SrtOrd : integer;
    SwpSiz,
    TabHan,
    RecHan,
    LckHan,
    FilHan : string[6];
    NetPat : PathStr;
    UsrNam : string[MaxNameLen];
    CliNam : string[MaxNameLen];
  end;

  PpxbEngineCfg = ^TpxbEngineCfg;
  TpxbEngineCfg = object (TDialog)
    constructor Init;
  end;

  PpxbMemoRec = ^TpxbMemoRec;
  TpxbMemoRec = record
    Len : word;
    Data : array [0..pxbMaxUMemoSize-1] of char;
  end;

  PpxbMemoEdit = ^TpxbMemoEdit;
  TpxbMemoEdit = object (TDialog)
    Memo : PMemo;
    constructor Init;
  end;

  TpxbListBoxRec = record
    List : PCollection;
    Selection : Word;
  end;

  PpxbFieldListBox = ^TpxbFieldListBox;
  TpxbFieldListBox = object (TListBox)
    function GetText (Item : integer; MaxLen : integer) : string; virtual;
  end;

  TpxbCreateDlgRec = record
    Name : string[25];
    Len : string[3];
    Typ : integer;
    Fields : TpxbListBoxRec;
    PriKey : string[3];
  end;

  PpxbCreateDialog = ^TpxbCreateDialog;
  TpxbCreateDialog = object (TDialog)
    TableNam : PathStr;
    FieldPtr : PCollection;
    TypeButtons : PMsgButtons;
    NameLine,
    LengthLine,
    PriKeyLine : PInputLine;
    FieldBox : PpxbFieldListBox;
    constructor Init (TblName : PathStr);
    procedure SetData (var Rec); virtual;
    procedure AddField;
    procedure DeleteField;
    procedure DefTypeLen;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  PpxbDialog = ^TpxbDialog;
  TpxbDialog = object (TDialog)
    FieldCnt,
    PriFieldCnt,
    RecordLines : integer;
    IndexNumber : FieldNumber;
    EditLockHan : LockHandle;
    EditLockRecNum : RecordNumber;
    TableHan  : TableHandle;
    EnterStr,
    PasteStr : string;
    TableNam : PathStr;
    EnginePtr : PEngine;
    DataBasePtr : PDataBase;
    CursorPtr : PCursor;
    FieldPtr : PCollection;
    TopRec : PRecord;
    StatusLin : PInputLine;
    MaxScrSize : TPoint;
    InpGroup : PGroup;
    FirstField,
    LastField,
    PrevField : PpxbInputLine;
    FirstName : PpxbFieldName;
    constructor Init (RecLines : integer; TblName : PathStr;
    EngPtr : PEngine; DBPtr : PDatabase; CurPtr : PCursor; IdxNum : FieldNumber);
    destructor Done; virtual;
    procedure UpdateStatus (S : string); virtual;
    function ErrorBox (ErrCode : integer) : boolean; virtual;
    procedure InitBrowser; virtual;
    function InpLineLen (P : PFieldDesc) : integer; virtual;
    procedure MakeValidator (InpLine : PpxbInputLine); virtual;
    procedure MakeMoveLinks; virtual;
    procedure BuildFields; virtual;
    procedure ReadFields; virtual;
    function SearchKey (InpLine : PPxBInputLine) : Retcode; virtual;
    function LockRec (InpLine : PpxbInputLine) : Retcode; virtual;
    function UnlockRec : Retcode; virtual;
    procedure LockUpdate (InpLine : PpxbInputLine); virtual;
    function WriteField (InpLine : PpxbInputLine) : Retcode; virtual;
    procedure TabPosLine (InpLine : PpxbInputLine); virtual;
    procedure ToggleIns; virtual;
    procedure FieldChanged (InpLine : PpxbInputLine); virtual;
    procedure FieldEnter (InpLine : PpxbInputLine); virtual;
    function FieldExit (InpLine : PpxbInputLine) : boolean; virtual;
    procedure GotoHome; virtual;
    procedure GotoLast; virtual;
    procedure DownRead (InpLine : PpxbInputLine); virtual;
    procedure UpRead (InpLine : PpxbInputLine); virtual;
    procedure PageUpRead; virtual;
    procedure PageDownRead; virtual;
    procedure HomeRead; virtual;
    procedure EndRead; virtual;
    procedure CopyClip (InpLine : PpxbInputLine); virtual;
    procedure PasteClip (InpLine : PpxbInputLine); virtual;
    procedure BlobMemoEdit (InpLine : PpxbInputLine); virtual;
    procedure BlobEdit (InpLine : PpxbInputLine); virtual;
    procedure DeleteRec (InpLine : PpxbInputLine); virtual;
    procedure SizeLimits (var Min, Max : TPoint); virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
    function Valid (Command: word) : boolean; virtual;
  end;

procedure EngCfgToDlgCfg (EngCfg : TEnv; var DlgCfg : TpxbEngineCfgRec);
procedure DlgCfgToEngCfg (DlgCfg : TpxbEngineCfgRec; var EngCfg : TEnv);

implementation

{
Convert TEnv to TpxbEngineCfgRec, so it can be used with a TpxbEngineCfg
dialog.
}

procedure EngCfgToDlgCfg (EngCfg : TEnv; var DlgCfg : TpxbEngineCfgRec);

begin
  with EngCfg do
    with DlgCfg do
    begin
      EngTyp := integer (engineType);
      DosShr := integer (dosShare);
      WinShr := integer (winShare);
      CrtFmt := integer (tabCrtMode);
      LckMod := integer (tabLckMode);
      SrtOrd := integer (sortOrder);
      SwpSiz := IntToStr (bufSize);
      TabHan := IntToStr (maxTables);
      RecHan := IntToStr (maxRecBufs);
      LckHan := IntToStr (maxLocks);
      FilHan := IntToStr (maxFiles);
      NetPat := netNamePath;
      UsrNam := userName;
      CliNam := clientName
    end
end;

{
Convert TpxbEngineCfgRec to TEnv , so it can be used after a TpxbEngineCfg
dialog.
}

procedure DlgCfgToEngCfg (DlgCfg : TpxbEngineCfgRec; var EngCfg : TEnv);

begin
  with DlgCfg do
    with EngCfg do
    begin
      engineType  := TEngineType (EngTyp);
      dosShare    := PXDosShare (DosShr);
      winShare    := PXWinShare (WinShr);
      tabCrtMode  := PXTabCrtMode (CrtFmt);
      tabLckMode  := PXTblLckMode (LckMod);
      sortOrder   := PXSortOrder (SrtOrd);
      bufSize     := StrToInt (SwpSiz);
      maxTables   := StrToInt (TabHan);
      maxRecBufs  := StrToInt (RecHan);
      maxLocks    := StrToInt (LckHan);
      maxFiles    := StrToInt (FilHan);
      netNamePath := NetPat;
      userName    := UsrNam;
      clientName  := CliNam
    end
end;

{
TpxbEngineCfg allows you modify a TEnv record for custom engine start up.
A TpxbEngineCfgRec can be used to set/get the dialog's data.  Use
EngCfgToDlgCfg to convert TEnv rec to dialog rec before calling
TpxbEngineCfgRec.Init.  Use DlgCfgToEngCfg afterwards to convert dialog rec
back to TEnv rec.
}

constructor TpxbEngineCfg.Init;

var

  R : TRect;
  RB : PRadioButtons;
  Field : PInputLine;

begin
  R.Assign (0,0,53,20);
  inherited Init (R,'Engine Options');
  Options := Options or ofCentered;

  R.Assign (2,3,15,6);
  RB := New (PRadioButtons,Init(R,
    NewSItem ('Local',
    NewSItem ('Network',
    NewSItem ('Windows',
    nil)))));
  Insert (RB);
  R.Assign (1,2,13,3);
  Insert (New (PLabel,Init (R,'~E~ngine type',RB)));

  R.Assign (17,3,30,6);
  RB := New (PRadioButtons,Init(R,
    NewSItem ('Local',
    NewSItem ('Network',
    NewSItem ('None',
    nil)))));
  Insert (RB);
  R.Assign (16,2,30,3);
  Insert (New (PLabel,Init (R,'~D~OS share',RB)));

  R.Assign (32,3,51,6);
  RB := New (PRadioButtons,Init(R,
    NewSItem ('Shared',
    NewSItem ('Single client',
    NewSItem ('Exclusive',
    nil)))));
  Insert (RB);
  R.Assign (31,2,47,3);
  Insert (New (PLabel,Init (R,'~W~indows share',RB)));

  R.Assign (2,8,15,10);
  RB := New (PRadioButtons,Init(R,
    NewSItem ('4.0',
    NewSItem ('3.5',
    nil))));
  Insert (RB);
  R.Assign (1,7,15,8);
  Insert (New (PLabel,Init (R,'~C~reate format',RB)));

  R.Assign (17,8,30,10);
  RB := New (PRadioButtons,Init(R,
    NewSItem ('4.0',
    NewSItem ('3.5',
    nil))));
  Insert (RB);
  R.Assign (16,7,30,8);
  Insert (New (PLabel,Init (R,'~L~ock mode',RB)));

  R.Assign (32,8,51,13);
  RB := New (PRadioButtons,Init(R,
    NewSItem ('ASCII',
    NewSItem ('International',
    NewSItem ('Norwegian 3.5',
    NewSItem ('Norwegian 4.0',
    NewSItem ('Swedish',
    nil)))))));
  Insert (RB);
  R.Assign (31,7,51,8);
  Insert (New (PLabel,Init (R,'~S~ort order',RB)));

  R.Assign (13,11,21,12);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (8,256)));
  Insert (Field);
  R.Assign(1,11,12,12);
  Insert (New (PLabel,Init (R,'Swap si~z~e',Field)));

  R.Assign (13,12,21,13);
  Field := New (PInputLine,Init (R,6));
  Field^.SetValidator (New (PRangeValidator,Init (1,64)));
  Insert (Field);
  R.Assign (1,12,12,13);
  Insert (New (PLabel,Init (R,'~T~ables',Field)));

  R.Assign (13,13,21,14);
  Field := New (PInputLine,Init (R,6));
  Field^.SetValidator (New (PRangeValidator,Init (1,512)));
  Insert (Field);
  R.Assign (1,13,12,14);
  Insert (New (PLabel,Init (R,'~R~ecords',Field)));

  R.Assign (13,14,21,15);
  Field := New (PInputLine,Init (R,6));
  Field^.SetValidator (New (PRangeValidator,Init (1,128)));
  Insert (Field);
  R.Assign (1,14,12,15);
  Insert (New (PLabel,Init (R,'L~o~cks',Field)));

  R.Assign (13,15,21,16);
  Field := New (PInputLine,Init (R,6));
  Field^.SetValidator (New (PRangeValidator,Init (3,255)));
  Insert (Field);
  R.Assign (1,15,12,16);
  Insert(New (PLabel,Init (R,'~F~iles',Field)));

  R.Assign (32,14,51,15);
  Field := New (PInputLine,Init (R,SizeOf (PathStr)-1));
  Insert (Field);
  R.Assign (22,14,31,15);
  Insert (New(PLabel,Init (R,'Net ~p~ath',Field)));

  R.Assign (32,15,51,16);
  Field := New (PInputLine,Init (R,MaxNameLen));
  Insert (Field);
  R.Assign (22,15,31,16);
  Insert (New(PLabel,Init (R,'~N~ame',Field)));

  R.Assign (32,16,51,17);
  Field := New (PInputLine,Init(R,MaxNameLen));
  Insert (Field);
  R.Assign (22,16,31,17);
  Insert (New (PLabel,Init (R,'Cl~i~ent',Field)));

  R.Assign (1,17,11,19);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (12,17,22,19);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)))
end;

{
TpxbEngineCfg is a editor dialog for unformatted memo blobs.  Scroll bars,
OK and Cancel buttons included.
}

constructor TpxbMemoEdit.Init;

var

  R : TRect;
  HScrollBar,
  VScrollBar : PScrollBar;

begin
  Application^.GetExtent (R);
  R.B.Y := R.B.Y-2;
  R.A.Y := (R.B.Y shr 1)-1;
  inherited Init (R,'Memo Editor');

  GetExtent (R);
  R.A.X := R.A.X+1;
  R.B.X := R.B.X-1;
  R.A.Y := R.B.Y-5;
  R.B.Y := R.A.Y+1;
  HScrollBar := New (PScrollBar, Init (R));
  Insert (HScrollBar);

  GetExtent (R);
  R.A.X := R.B.X-1;
  R.B.X := R.A.X+1;
  R.A.Y := R.A.Y+1;
  R.B.Y := R.B.Y-5;
  VScrollBar := New (PScrollBar, Init (R));
  Insert (VScrollBar);

  GetExtent (R);
  R.A.X := R.A.X+1;
  R.B.X := R.B.X-1;
  R.A.Y := R.A.Y+1;
  R.B.Y := R.B.Y-5;
  Memo := New(PMemo, Init (R,HScrollBar,VScrollBar,nil,pxbMaxUMemoSize));
  Insert (Memo);

  GetExtent (R);
  R.A.X := R.A.X+1;
  R.B.X := R.A.X+10;
  R.A.Y := R.B.Y-3;
  R.B.Y := R.A.Y+2;
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));

  R.A.X := R.B.X+2;
  R.B.X := R.A.X+10;
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)));
  SelectNext (false)
end;

{
TpxbFieldName is a Paradox field name that can be moved and will not resize
when the owner is resized.  These are insetred into the InpGroup.
}

constructor TpxbFieldName.Init (var Bounds : TRect; const AText : string);

begin
  inherited Init (Bounds,AText);
  StartLoc := Bounds.A; {starting location}
  GetExtent (Bounds);
  StartSize := Bounds.B {starting size for CalcBounds}
end;

{
Always draw field name in its original size regardless of owner's size.
}

procedure TpxbFieldName.CalcBounds (var Bounds : TRect; Delta : TPoint);

begin
  Bounds.A.X := Origin.X;
  Bounds.A.Y := Origin.Y;
  Bounds.B.X := Origin.X+StartSize.X;
  Bounds.B.Y := Origin.Y+StartSize.Y
end;

{
TpxbInputLine allows you to edit all non-blob field types.  Blob fields
display blob type and do not allow editing.  The owner dialog Owner^.Owner
is sent messages when you modify, enter and exit the input line.  BuildFields
handles size, initial position and validators.  TpxbDialog handles table I/O
and final validation.  These are insetred into the InpGroup.
}

constructor TpxbInputLine.Init (var Bounds : TRect; AMaxLen : Integer);

begin
  inherited Init (Bounds,AMaxLen);
  Options := Options or ofValidate;
  StartLoc := Bounds.A; {starting location}
  GetExtent (Bounds);
  StartSize := Bounds.B {starting size for CalcBounds}
end;

{
Always draw input line in its original size regardless of owner's size.
}

procedure TpxbInputLine.CalcBounds (var Bounds : TRect; Delta : TPoint);

begin
  Bounds.A.X := Origin.X;
  Bounds.A.Y := Origin.Y;
  Bounds.B.X := Origin.X+StartSize.X;
  Bounds.B.Y := Origin.Y+StartSize.Y
end;

{
Notifies dialog that a new field has been selected.
}

procedure TpxbInputLine.SetState (AState : word; Enable : boolean);

begin
  inherited SetState (AState,Enable);
  if (AState = sfSelected) and
  (State and sfActive <> 0) and
  (State and sfSelected <> 0) then
    Message(Owner^.Owner,evCommand,cmFieldEnter,@Self)
end;

{
Check for vaild data and ask dialog if the input line is valid.  Called when
you try to move to another input line.
}

function TpxbInputLine.Valid (Command : word) : boolean;

var

  Temp : boolean;

begin
  Temp := inherited Valid(Command);
  if Command = cmReleasedFocus then
  begin                {tell dialog that input line is being exited}
    if Message(Owner^.Owner,evCommand,cmFieldExit,@Self) = nil then
    begin
      Select;          {validation failed}
      Temp := false
    end
  end;
  Valid := Temp
end;

{
If input line is used for blob fields then all evKeyDown events will be
cleared before the inherited method is called.  This prevents modifing the
generic blob name.
}

procedure TpxbInputLine.HandleEvent (var Event : TEvent);

begin
  if Event.What = evKeyDown then
  begin
    if FieldTyp = fldBlob then
    begin               {blob lines cannot be edited}
     ClearEvent (Event);
      inherited HandleEvent (Event)
    end
    else
    begin               {tell dialog that input line may have changed}
      inherited HandleEvent (Event);
      Message(Owner^.Owner,evCommand,cmFieldChanged,@Self)
    end
  end
  else
    inherited HandleEvent (Event)
end;

{
TpxbFieldListBox is pick list using TFieldDesc collection used in a
TpxbCreateDialog.
}

function TpxbFieldListBox.GetText(Item: Integer; MaxLen: Integer): String;

var

  C : char;
  P : PFieldDesc;

begin
  if List <> nil then
  begin
    P := PFieldDesc (List^.At (Item));
    case P^.fldType of
      fldChar  : C := 'A';
      fldShort : C := 'S';
      fldDouble: if P^.fldSubtype = fldstNone then
                   C := 'N'
                 else
                   C := '$';
      fldDate  : C := 'D';
      fldBlob  :
      case P^.fldSubtype of
        fldstMemo    : C := 'M';
        fldstBinary  : C := 'B';
        fldstFmtMemo : C := 'F';
        fldstOleObj  : C := 'O';
        fldstGraphic : C := 'G'
      end
    end;
    GetText := IntToRightStr (P^.fldNum,3)+' ³ '+C+' ³ '+IntToRightStr (P^.fldLen,3)+' ³ '+P^.fldName
  end
  else
    GetText := ''
end;

{
TpxbCreateDialog allows you to create paradox tables.  If the table exists
with the same name then it is deleted first.
}

constructor TpxbCreateDialog.Init (TblName : PathStr);

var

  R : TRect;
  VScrollBar : PScrollBar;

begin
  R.Assign (0,0,66,19);
  inherited Init (R,TblName);
  Options := Options or ofCentered;
  TableNam := TblName;

  R.Assign (2,3,29,4);
  NameLine := New(PInputLine,Init(R,25));
  Insert (NameLine);
  R.Assign(1,2,6,3);
  Insert (New (PLabel,Init (R,'~N~ame',NameLine)));

  R.Assign (33,3,38,4);
  LengthLine := New(PInputLine,Init(R,3));
  LengthLine^.SetValidator (New (PRangeValidator,Init (0,255)));
  Insert (LengthLine);
  R.Assign(32,2,42,3);
  Insert (New (PLabel,Init (R,'~L~ength',LengthLine)));

  R.Assign (47,3,64,13);
  TypeButtons := New (PMsgButtons,Init(R,
    NewSItem ('Alhpa',
    NewSItem ('Short',
    NewSItem ('Double',
    NewSItem ('Date',
    NewSItem ('Currency',
    NewSItem ('Memo',
    NewSItem ('Binary',
    NewSItem ('Fmt Memo',
    NewSItem ('Windows OLE',
    NewSItem ('Graphic',
    nil))))))))))));
  Insert (TypeButtons);
  R.Assign (46,2,51,3);
  Insert (New (PLabel,Init (R,'~T~ype',TypeButtons)));

  R.Assign(45,5,46,13);
  New (VScrollBar,Init (R));
  Insert (VScrollBar);

  R.Assign (2,5,45,13);
  FieldBox := New (PpxbFieldListBox,Init (R,1,VScrollBar));
  Insert (FieldBox);
  R.Assign (1,4,22,5);
  Insert (New (PLabel,Init (R,'~F~ield Typ Len   Name',FieldBox)));

  R.Assign (2,14,7,15);
  PriKeyLine := New(PInputLine,Init(R,3));
  PriKeyLine^.SetValidator (New (PRangeValidator,Init (0,255)));
  Insert (PriKeyLine);
  R.Assign(1,13,13,14);
  Insert (New (PLabel,Init (R,'~P~rimary key',PriKeyLine)));

  R.Assign (1,16,11,18);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (12,16,22,18);
  Insert (New (PButton,Init (R,'~A~dd',cmFieldAdd,bfNormal)));
  R.Assign (23,16,33,18);
  Insert (New (PButton,Init (R,'~D~elete',cmFieldDelete,bfNormal)));
  R.Assign (34,16,44,18);
  Insert (New (PButton,Init (R,'~E~dit',cmFieldEdit,bfNormal)));
  R.Assign (45,16,55,18);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)));
  SelectNext (false)
end;

{
Set the valid field range by type when dialog's set data is called.
}

procedure TpxbCreateDialog.SetData (var Rec);

begin
  inherited SetData(Rec);
  DefTypeLen
end;

{
Adds field to field pick list.  Accepts names that are not '' or
duplicated and also checks for correct field lengths.
}

procedure TpxbCreateDialog.AddField;

var

  ButtonVal,
  FieldCnt : integer;
  P : PFieldDesc;

function SameName (Item : pointer) : boolean; far;

begin {see if name matches on from list}
  SameName := (UpCaseStr (PFieldDesc (Item)^.fldName) =
  UpCaseStr (NameLine^.Data^))
end;

procedure SetFieldNum (Item : pointer); far;

begin {set field number in list}
  PFieldDesc (Item)^.fldNum := FieldCnt;
  Inc (FieldCnt)
end;

begin
  if FieldBox^.Range < 255 then {max fields reached?}
  begin
    if NameLine^.Data^ <> '' then {null name?}
    begin
      if FieldPtr^.FirstThat (@SameName) = nil then {does name exist in list?}
      begin
        if LengthLine^.Valid (cmOK) then {is field length valid?}
        begin
          ButtonVal := TypeButtons^.Value;
          P := New (PFieldDesc,Init);
          with P^ do
          begin
            fldName := NameLine^.Data^;
            case ButtonVal of             {convert radio button value to}
              0..1 :                      {field type/subtype}
              begin
                fldType := PXFieldType (ButtonVal);
                fldSubtype := fldstNone
              end;
              2..3 :
              begin
                fldType := PXFieldType (ButtonVal+1);
                fldSubtype := fldstNone
              end;
              4 :
              begin
                fldType := fldDouble;
                fldSubtype := fldstMoney
              end;
              5..9 :
              begin
                fldType := fldBlob;
                fldSubtype := PXFieldSubtype (ButtonVal-3)
              end;
            end;
            fldLen := StrToInt (LengthLine^.Data^)
          end;
          if FieldBox^.Focused = FieldBox^.Range-1 then
            FieldPtr^.Insert (P)                      {add to end of list}
          else
            FieldPtr^.AtInsert (FieldBox^.Focused,P); {insert before selected item}
          FieldCnt := 1;
          FieldPtr^.ForEach (@SetFieldNum);             {set field numbers}
          FieldBox^.SetRange (FieldBox^.List^.Count);   {set list's range}
          if FieldBox^.Focused < FieldBox^.Range-1 then {update list display}
            FieldBox^.FocusItem (FieldBox^.Focused+1)
          else
            FieldBox^.DrawView
        end
      end
      else
      begin
        MessageBox (#3'Duplicate field name',nil,mfError or mfOKButton);
        NameLine^.Focus
      end
    end
    else
    begin
      MessageBox (#3'Name field blank',nil,mfError or mfOKButton);
      NameLine^.Focus
    end
  end
  else
    MessageBox (#3'Only 255 fields allowed',nil,mfError or mfOKButton)
end;

{
Delete field from field pick list.
}

procedure TpxbCreateDialog.DeleteField;

var

  FieldCnt : integer;

procedure SetFieldNum (Item : pointer); far;

begin {set field number in list}
  PFieldDesc (Item)^.fldNum := FieldCnt;
  Inc (FieldCnt)
end;

begin
  if FieldBox^.Range > 0 then
  begin
    FieldPtr^.AtDelete (FieldBox^.Focused);
    FieldBox^.SetRange (FieldBox^.List^.Count);
    FieldCnt := 1;
    FieldPtr^.ForEach (@SetFieldNum);
    FieldBox^.DrawView
  end
end;

{
Set length line's range by field type.
}

procedure TpxbCreateDialog.DefTypeLen;

var

  LenMin,
  LenMax : longint;

begin
  case TypeButtons^.Value of
    0 :
    begin
      LenMin := 1;
      LenMax := 255
    end;
    1..4 :
    begin
      LenMin := 0;
      LenMax := 0
    end;
    5 :
    begin
      LenMin := 1;
      LenMax := 240
    end;
    6..9 :
    begin
      LenMin := 0;
      LenMax := 240
    end
  end;
  PRangeValidator (LengthLine^.Validator)^.Min := LenMin;
  PRangeValidator (LengthLine^.Validator)^.Max := LenMax
end;

{
Process events.
}

procedure TpxbCreateDialog.HandleEvent (var Event : TEvent);

{
Edit a current field in list.
}

procedure EditField;

var

  ButtonVal : integer;
  LenStr : string[3];
  FldDesc : PFieldDesc;

begin
  if FieldBox^.Range > 0 then
  begin
    FldDesc := FieldPtr^.At (FieldBox^.Focused);
    NameLine^.SetData (FldDesc^.fldName);
    LenStr := IntToStr (FldDesc^.fldLen);
    LengthLine^.SetData (LenStr);
    case FldDesc^.fldType of      {convert field type to button val}
      fldChar   : ButtonVal := 0;
      fldShort  : ButtonVal := 1;
      fldDouble :
      if FldDesc^.fldSubtype = fldstMoney then
        ButtonVal := 4
      else
        ButtonVal := 2;
      fldDate   : ButtonVal := 3;
      fldBlob   : ButtonVal := integer (FldDesc^.fldSubtype)+3
    end;
    TypeButtons^.SetData (ButtonVal);
    DefTypeLen
  end
end;

begin
  case Event.What of
    evCommand :
    begin {process commands}
      case Event.Command of
        cmFieldAdd    : AddField;
        cmFieldDelete : DeleteField;
        cmFieldEdit   : EditField
      else
      begin
        inherited HandleEvent (Event);
        Exit
      end
      end
    end;
    evBroadcast:
    begin {process broadcasts}
      case Event.Command of
        cmMsgButtonPress : DefTypeLen
      else
      begin
        inherited HandleEvent (Event);
        Exit
      end
      end;
      ClearEvent (Event)
    end
  end;
  inherited HandleEvent (Event)
end;

{
TpxbDialog is a generic browser dialog for Paradox tables.  The engine and
a cursor must be opened before calling.  In addition to TCursor's overhead
the TpxbDialog uses 1 record buffer and 1 lock handle.
}

constructor TpxbDialog.Init (RecLines : integer; TblName : PathStr;
EngPtr : PEngine; DBPtr : PDatabase; CurPtr : PCursor; IdxNum : FieldNumber);

var

  R : TRect;
  InteriorView : PView;

begin
  Application^.GetExtent (R);
  R.B.Y := R.A.Y+Reclines+6;
  inherited Init (R,TblName);
  Options := Options or ofValidate or ofTileable;
  Flags := wfMove+wfGrow+wfClose+wfZoom;
  GrowMode := gfGrowRel;
  Palette := dpBlueDialog;

  GetExtent (R);          {make non-selectable status line}
  R.A.X := R.A.X+2;
  R.B.X := R.A.X+12;
  R.A.Y := R.B.Y-1;
  StatusLin := New (PInputLine,Init (R,10));
  StatusLin^.Options := StatusLin^.Options and not ofSelectable;
  StatusLin^.GrowMode := gfGrowLoY; {move with bottom of dialog}
  Insert (StatusLin);

  GetExtent (R);          {make input line group}
  Inc (R.A.X,2);
  Inc (R.A.Y,2);
  Dec (R.B.X,2);
  Dec (R.B.Y,2);
  InpGroup := New (PGroup, Init (R));
  with InpGroup^ do
  begin
    GrowMode := gfGrowHiX+gfGrowHiY;            {resizable}
    GetExtent (R);
    RecordLines := R.B.Y-2;                {record lines in dialog}
    InteriorView := New (PView, Init (R)); {make group interior}
    InteriorView^.GrowMode := gfGrowHiX+gfGrowHiY;
    Insert (InteriorView)
  end;
  Insert (InpGroup);

  GetExtent (R);          {set max window size}
  MaxScrSize.X := R.B.X;
  MaxScrSize.Y := R.B.Y;

  TableNam := TblName;         {set px framework ralated stuff}
  EnginePtr := EngPtr;
  DataBasePtr := DBPtr;
  CursorPtr := CurPtr;
  IndexNumber := IdxNum;
  InitBrowser
end;

{
Disposes field desc collection, top rec and cursor before calling inherited
done.
}

destructor TpxbDialog.Done;

begin
  if FieldPtr <> nil then
    Dispose (FieldPtr,Done);
  if TopRec <> nil then
    Dispose (TopRec,Done);
  if CursorPtr <> nil then
    Dispose (CursorPtr,Done);
  inherited Done
end;

{
Update dialog status line.
}

procedure TpxbDialog.UpdateStatus (S : string);

begin
  StatusLin^.SetData (S)
end;

{
Displays error dialog for errors <> PXSUCCESS.  ErrorBox returns true if
error <> PXSUCCESS and false if error = PXSUCCESS.
}

function TpxbDialog.ErrorBox (ErrCode : integer) : boolean;

begin
  if ErrCode <> PXSUCCESS then
  begin
    MessageBox (EnginePtr^.getErrorMessage (ErrCode),
    nil, mfError or mfOKButton);
    ErrorBox := true
  end
  else
    ErrorBox := false
end;

{
Get table field count, number of primary key fields and field desc
collection.
}

procedure TpxbDialog.InitBrowser;

var

  I : FieldNumber;
  P : PFieldDesc;

begin
  EditLockHan := 0;
  EditLockRecNum := 0;
  TableHan := CursorPtr^.getTableHandle;
  TopRec := New (PRecord,Init (CursorPtr));
  FieldCnt := CursorPtr^.genericRec^.getFieldCount;     {number of fields}
  PriFieldCnt := DataBasePtr^.getNumPFields (TableNam); {number of primary key fields}
  FieldPtr := New (PCollection,Init (FieldCnt,10));
  for I := 1 to FieldCnt do     {make collection without using table handle}
  begin                         {like getDescVector}
    P := New (PFieldDesc,Init);
    CursorPtr^.genericRec^.getFieldDesc (I,P);
    FieldPtr^.Insert (P)
  end;
  BuildFields;                  {build browser structure}
  FirstField^.Select;           {select first field}
  PrevField := FirstField;      {previous field = first field too}
  GotoHome;                     {postion cursor at home pos}
  ReadFields                    {fill browser fields with data}
end;

{
Set input line length based on field type.
}

function TpxbDialog.InpLineLen (P : PFieldDesc) : integer;

begin
  case P^.fldType of
    fldChar   : InpLineLen := P^.fldLen;
    fldShort  : InpLineLen := 6;
    fldLong   : InpLineLen := 11;
    fldDouble : InpLineLen := 17;
    fldDate   : InpLineLen := 10;
    fldBlob   :
    case P^.fldSubType of      {blobs are set by their description length}
      fldstMemo    : InpLineLen := byte (pxbBlobNames[0,0]);
      fldstBinary  : InpLineLen := byte (pxbBlobNames[1,0]);
      fldstFmtMemo : InpLineLen := byte (pxbBlobNames[2,0]);
      fldstOleObj  : InpLineLen := byte (pxbBlobNames[3,0]);
      fldstGraphic : InpLineLen := byte (pxbBlobNames[4,0])
    end
  end
end;

{
Set basic input line validator based on field type.
}

procedure TpxbDialog.MakeValidator (InpLine : PpxbInputLine);

begin
  case InpLine^.FieldTyp of
    fldShort  : InpLine^.SetValidator (New (PFilterValidator,
    Init (['0'..'9','+','-',' '])));
    fldLong   : InpLine^.SetValidator (New (PFilterValidator,
    Init (['0'..'9','+','-',' '])));
    fldDouble : InpLine^.SetValidator (New (PFilterValidator,
    Init (['0'..'9','+','-','.','E','e',' '])));
    fldDate   : InpLine^.SetValidator (New (PPXPictureValidator,
    Init ('{##}/{##}/{####}',true)))
  end
end;

{
Set all input line movement links to handle up, down, home, end and top from
any input line.
}

procedure TpxbDialog.MakeMoveLinks;

var

  RecLines, Flds : integer;
  CView, LView : PpxbInputLine;

begin

{set down links}

  CView := FirstField;
  LView := CView;
  for Flds := 1 to FieldCnt do
    PView (LView) := LView^.PrevView;
  for RecLines := 1 to RecordLines do
    for Flds := 1 to FieldCnt do
    begin
      CView^.DownLine := LView;
      if CView^.PrevView <> nil then
        PView (CView) := CView^.PrevView;
      if LView <> nil then
        PView (LView) := LView^.PrevView
    end;

{set up links}

  CView := FirstField;
  for RecLines := 1 to RecordLines do
    for Flds := 1 to FieldCnt do
    begin
      LView := CView^.DownLine;
      if LView <> nil then
        LView^.UpLine := CView;
      if CView^.PrevView <> nil then
        PView (CView) := CView^.PrevView
    end;

{set home links}

  CView := FirstField;
  for RecLines := 1 to RecordLines do
  begin
    LView := CView;
    for Flds := 1 to FieldCnt do
    begin
      LView^.HomeLine := CView;
      if LView^.PrevView <> nil then
        PView (LView) := LView^.PrevView
    end;
    PView (CView) := CView^.DownLine
  end;

{set end links}

  CView := LastField;
  for RecLines := 1 to RecordLines do
  begin
    LView := CView;
    for Flds := 1 to FieldCnt do
    begin
      LView^.EndLine := CView;
      PView (LView) := LView^.NextView
    end;
    CView := CView^.UpLine
  end;

{set top links}

  CView := FirstField;
  for Flds := 1 to FieldCnt do
  begin
    LView := CView;
    for RecLines := 1 to RecordLines do
    begin
      LView^.TopLine := CView;
      LView := LView^.DownLine
    end;
    if CView^.PrevView <> nil then
      PView (CView) := CView^.PrevView
  end
end;

{
Builds field structure inside group.  Field names, width, validators,
movement links, first name, first field and last field are created.
}

procedure TpxbDialog.BuildFields;

var


  I : integer;
  FieldPnt : TPoint;
  R : TRect;

{
Insert input line with validator.  Blobs do not have validators and cannot
be edited by the input line.  BlobEdit handles editing all blob types.
}

procedure MakeField (P : PFieldDesc); far;

var

  S : integer;
  InpLine : PpxbInputLine;

begin
  S := InpLineLen (P);
  if S > InpGroup^.Size.X-2 then
    S := InpGroup^.Size.X-2;
  R.Assign (FieldPnt.X,FieldPnt.Y,FieldPnt.X+S+2,FieldPnt.Y+1);
  InpLine := New (PpxbInputLine,Init (R,InpLineLen (P)));
  InpLine^.TabPos := FieldPnt;
  InpLine^.FieldNum := P^.fldNum;
  InpLine^.FieldTyp := P^.fldType;
  InpLine^.FieldSub := P^.fldSubtype;
  MakeValidator (InpLine);
  InpGroup^.Insert (InpLine);
  FieldPnt.X := FieldPnt.X+S+3
end;

{
Insert paradox field names
}

procedure MakeFieldName (P : PFieldDesc); far;

var

  S : integer;

begin
  S := InpLineLen (P);
  if S > InpGroup^.Size.X-2 then
    S := InpGroup^.Size.X-2;
  R.Assign (FieldPnt.X,FieldPnt.Y,FieldPnt.X+S+2,FieldPnt.Y+2);
  InpGroup^.Insert (New (PpxbFieldName,Init (R,#3+P^.fldName)));
  FieldPnt.X := FieldPnt.X+S+3
end;

{
Find first view that's not a TpxbInputLine.
}

function FirstInpLine (P : PView) : boolean; far;

begin
  FirstInpLine :=
  (TypeOf (P^) = TypeOf (TpxbInputLine)) and
  (TypeOf (P^.NextView^) = TypeOf (TpxbFieldName))
end;

begin
  FieldPnt.X := 0;
  FieldPnt.Y := 0;
  FieldPtr^.ForEach (@MakeFieldName); {insert field names}
  FieldPnt.X := 0;
  Inc (FieldPnt.Y,2);
  for I := 1 to RecordLines do
  begin
    FieldPtr^.ForEach (@MakeField);   {insert input lines}
    FieldPnt.X := 0;
    Inc (FieldPnt.Y)
  end;
  PView (FirstName) := InpGroup^.Last^.Prev; {first name is interior^.prev}
  PView (LastField) := InpGroup^.Last^.Next; {last field is interior^.next}
  PView (FirstField) := InpGroup^.FirstThat (@FirstInpLine); {find first field}
  MakeMoveLinks
end;

{
Read and translate records to fill entire browser.
}

procedure TpxbDialog.ReadFields;

var

  S, I, Flds : integer;
  L : longint;
  D : double;
  isBlank : boolean;
  InpLineStr : string;
  CView : PpxbInputLine;

begin
  if CursorPtr^.hasChanged then  {update table image if it has changed}
    CursorPtr^.refresh;
  CView := FirstField;           {start with first field}
  CursorPtr^.getRecord (TopRec); {get top record}
  for I := 1 to RecordLines do
  begin
    if CursorPtr^.LastError = PXSUCCESS then
    begin
      CursorPtr^.getRecord (CursorPtr^.genericRec); {get record}
      for Flds := 1 to FieldCnt do                  {translate fields}
        if CView^.FieldTyp <> fldBlob then
        begin
          if not CursorPtr^.genericRec^.isNull (CView^.FieldNum) then
          begin
            case CView^.FieldTyp of
              fldChar   : {char fields translated by framework}
              CursorPtr^.genericRec^.getString
              (CView^.FieldNum,InpLineStr,isBlank);
              fldShort  : {convert short to right justified integer}
              begin
                CursorPtr^.genericRec^.getField (CView^.FieldNum,@S,SizeOf (S),isBlank);
                Str(S:6,InpLineStr)
              end;
              fldLong   : {convert longint to right justified longint}
              begin
                CursorPtr^.genericRec^.getField (CView^.FieldNum,@L,SizeOf (L),isBlank);
                Str(L:11,InpLineStr)
              end;
              fldDouble : {convert double to right justified 0.00 or 1e14}
              begin
                CursorPtr^.genericRec^.getDouble (CView^.FieldNum,D,isBlank);
                if (Abs (D) < pxbFixedMax) then
                  Str(D:17:2,InpLineStr)
                else
                  Str(D:17,InpLineStr)
              end;
              fldDate   : {convert date to mm/dd/yyyy}
              CursorPtr^.genericRec^.getString (CView^.FieldNum,InpLineStr,isBlank)
            end;
            if CView^.Exposed then {update input line}
              CView^.SetData (InpLineStr)
            else
              CView^.Data^ := InpLineStr;
            CView^.RecordNum := CursorPtr^.getCurRecNum; {set record number}
            CView := PpxbInputLine (CView^.PrevView);    {goto next field}
          end
          else                      {handle null fields}
          begin
            InpLineStr := '';       {input line data = '' (null)}
            if CView^.Exposed then  {update input line}
              CView^.SetData (InpLineStr)
            else
              CView^.Data^ := InpLineStr;
            CView^.RecordNum := CursorPtr^.getCurRecNum; {set record number}
            CView := PpxbInputLine (CView^.PrevView);    {goto next field}
          end
        end
        else {handle blobs by setting input line data to generic name}
        begin
          case CView^.FieldSub of
            fldstMemo    : InpLineStr := pxbBlobNames[0];
            fldstBinary  : InpLineStr := pxbBlobNames[1];
            fldstFmtMemo : InpLineStr := pxbBlobNames[2];
            fldstOleObj  : InpLineStr := pxbBlobNames[3];
            fldstGraphic : InpLineStr := pxbBlobNames[4]
          end;
          if CView^.Exposed then                       {update input line}
            CView^.SetData (InpLineStr)
          else
            CView^.Data^ := InpLineStr;
          CView^.RecordNum := CursorPtr^.getCurRecNum; {set record number}
          CView := PpxbInputLine (CView^.PrevView)     {goto next field}
        end;
      CursorPtr^.gotoNext       {goto next record}
    end
    else    {handle error by setting input line data to null}
    begin
      InpLineStr := '';            {input line data = '' (null)}
      for Flds := 1 to FieldCnt do {do all fields}
      begin
        if CView^.Exposed then     {update input line}
          CView^.SetData (InpLineStr)
        else
          CView^.Data^ := InpLineStr;
        CView^.RecordNum := 0;     {set record number to 0 like blank record}
        CView := PpxbInputLine (CView^.PrevView) {goto next field}
      end
    end
  end;
  EnterStr := PpxbInputLine (InpGroup^.Current)^.Data^; {update current field str}
  LockUpdate (PpxbInputLine (InpGroup^.Current))
end;

{
Make primary key out of input lines and search.  If cursor not opened on
primary or secondary index then gotoRec is used.
}

function TPxBDialog.SearchKey (InpLine : PPxBInputLine) : Retcode;

var

  CView : PPxbInputLine;
  I : integer;

begin
  CView := InpLine^.HomeLine;
  CursorPtr^.genericRec^.clear;
  if PriFieldCnt <> 0 then
  begin
    for I := 1 to PriFieldCnt do
    begin
      if (CView^.RecordNum = PPxbInputLine(InpGroup^.Current)^.RecordNum) and
      (CView^.FieldNum = PPxbInputLine(InpGroup^.Current)^.FieldNum) then
        CursorPtr^.genericRec^.putString (CView^.FieldNum,EnterStr)
      else
        CursorPtr^.genericRec^.putString (CView^.FieldNum,CView^.Data^);
      PView (CView) := CView^.PrevView
    end;
    SearchKey := PXSrchKey (TableHan,
    CursorPtr^.genericRec^.recH,PriFieldCnt,Ord (pxSearchFirst))
  end
  else
    SearchKey := CursorPtr^.GotoRec (CView^.RecordNum)
end;

{
Goto input line's record and lock with network retry.  If the record is
currently locked then LockRec will not change lock handle and record number.
If the record number = 0 then LockRec will zero the lock handle and record
number.  If lock handle <> 0 (record locked) then record number and lock
handle are not changed. LockRec returns error code or PXSUCCESS.
}

function TpxbDialog.LockRec (InpLine : PpxbInputLine) : Retcode;

var

  TempErr : Retcode;
  BoxCmd : word;
  LongInfo : longint;
  NetErrStr : string;

begin
  if InpLine^.RecordNum <> 0 then
  begin
    if EditLockHan = 0 then
    begin
      TempErr := SearchKey (InpLine);
      if TempErr = PXSUCCESS then
      begin
        if EnginePtr^.engineType <> pxLocal then
        begin
          repeat
            EditLockHan := CursorPtr^.lockRecord; {get lock handle}
            TempErr := CursorPtr^.lastError;
            if TempErr = PXERR_RECLOCKED then     {if locked the ask to retry}
            begin
              NetErrStr := DataBasePtr^.getNetErrUser; {see what user is locking}
              if NetErrStr = '' then
                NetErrStr := 'unknown or local user';
              LongInfo := longint (@NetErrStr);
              BoxCmd := MessageBox (
              'Record is locked by %s.  Try to lock record again?',
              @LongInfo,mfYesButton+mfNoButton)
            end
            else
              BoxCmd := cmNo
          until (TempErr = PXSUCCESS) or (BoxCmd = cmNo);
          if TempErr = PXSUCCESS then                    {record locked}
          begin
            EditLockRecNum := InpLine^.RecordNum;
            UpdateStatus ('Locked')
          end
          else                                           {record not locked}
            if TempErr <> PXERR_RECLOCKED then
              ErrorBox (TempErr)
        end
      end
    end
    else {if record already locked then just seek}
      TempErr := CursorPtr^.GotoRec (InpLine^.RecordNum)
  end
  else
  begin {can't lock new records, so return pxsuccess}
    EditLockHan := 0;
    EditLockRecNum := 0;
    TempErr := PXSUCCESS
  end;
  if TempErr <> PXERR_RECLOCKED then
    ErrorBox (TempErr);
  if (TempErr = PXERR_RECDELETED) or
  (TempErr = PXERR_RECNOTFOUND) then
  begin
    CursorPtr^.GotoRec (FirstField^.RecordNum); {refresh browser}
    ReadFields
  end;
  LockRec := TempErr
end;

{
Unlock record on a network, zero lock handle and record number.  If the
engine type is pxLocal then lock handle and record number are not changed.
}

function TpxbDialog.UnlockRec : Retcode;

begin
  if (EnginePtr^.engineType <> pxLocal) and
  (EditLockHan <> 0) then
  begin
    CursorPtr^.unlockRecord (EditLockHan);
    EditLockHan := 0;
    EditLockRecNum := 0
  end;
  UnlockRec := CursorPtr^.lastError
end;

{
Unlock current record if another record is selected.  Browser status line
is updated to reflect locked or browse state.
}

procedure TpxbDialog.LockUpdate (InpLine : PpxbInputLine);

begin
  if EditLockRecNum <> InpLine^.RecordNum then
    UnlockRec;
  if EditLockHan = 0 then
    UpdateStatus ('Browse')
  else
    UpdateStatus ('Locked')
end;

{
Translate field, read record, change field and write record.  Record is
locked when a field is modified in any way, so explicit locking is not
required.
}

function TpxbDialog.WriteField (InpLine : PpxbInputLine) : Retcode;

var

  E : extended;
  TempErr : Retcode;

begin
  if InpLine^.RecordNum <> 0 then
  begin
    TempErr := CursorPtr^.GotoRec (InpLine^.RecordNum);        {seek record}
    if TempErr = PXSUCCESS then
      TempErr := CursorPtr^.getRecord (CursorPtr^.genericRec)  {get record}
  end
  else
    TempErr := CursorPtr^.genericRec^.clear; {clear new record}
  if TempErr = PXSUCCESS then
  begin
    if TrimStr (InpLine^.Data^) <> '' then
    begin
      if InpLine^.FieldTyp = fldDouble then
      begin                                  {convert/validate doubles}
        Val(TrimStr (InpLine^.Data^),E,TempErr);
        if TempErr = 0 then
        begin
          if ((Abs (E) >= pxbDoubleMin) and  {double range test}
          (Abs (E) <= pxbDoubleMax)) or
          (E = 0.0) then
            TempErr := CursorPtr^.genericRec^.putDouble (InpLine^.FieldNum,E)
          else
            TempErr := PXERR_OUTOFRANGE
        end
        else {pos input line cursor to val conversion error pos}
        begin
          InpLine^.CurPos := TempErr-1;
          TempErr := PXERR_DATACONV
        end
      end
      else {all non-double fields use framework to convert/validate}
        TempErr := CursorPtr^.genericRec^.putString (InpLine^.FieldNum,TrimStr (InpLine^.Data^))
    end
    else   {set field to null}
      TempErr := CursorPtr^.genericRec^.setNull (InpLine^.FieldNum);
    if TempErr = PXSUCCESS then {update/append record if no errors}
    begin
      if InpLine^.RecordNum <> 0 then
        TempErr := CursorPtr^.updateRec (CursorPtr^.genericRec)
      else
        TempErr := CursorPtr^.appendRec (CursorPtr^.genericRec)
    end
  end;
  CursorPtr^.GotoRec (FirstField^.RecordNum); {refresh browser}
  ReadFields;
  WriteField := TempErr
end;

{
Position all field names and input lines starting with InpLine column.  Only
enough input lines to fill the browser are moved to increase performance.
}

procedure TpxbDialog.TabPosLine (InpLine : PpxbInputLine);

var

  Recs, I : integer;
  CView, FView : PpxbInputLine;
  NView : PpxbFieldName;

begin
  if InpLine^.FieldNum <> PrevField^.FieldNum then
  begin
    NView := FirstName;
    for I := 1 to FieldCnt do   {position all field names}
    begin
      NView^.Origin.X := NView^.StartLoc.X-InpLine^.TabPos.X;
      PView (NView) := NView^.Prev
    end;

    CView := PrevField^.TopLine;
    while CView^.Exposed do         {move all exposed lines}
    begin
      FView := CView^.TopLine;
      for Recs := 1 to RecordLines do
      begin
        FView^.Origin.X := MaxScrSize.X;
        FView := FView^.DownLine
      end;
      if CView^.PrevView <> nil then
        PView (CView) := CView^.PrevView
    end;

    CView := InpLine^.TopLine;
    I := 0;
    repeat             {position lines relative to current line}
      FView := CView^.TopLine;
      for Recs := 1 to RecordLines do
      begin
        FView^.Origin.X := I;
        FView := FView^.DownLine
      end;
      I := I+CView^.StartSize.X+1;
      if CView^.PrevView <> nil then
        PView (CView) := CView^.PrevView
      else
        I := MaxScrSize.X+1
    until (I > MaxScrSize.X) or
    (InpLine^.FieldNum >= CView^.FieldNum);
    InpGroup^.ReDraw
  end
end;

{
Toggle insert mode for all input lines.
}

procedure TpxbDialog.ToggleIns;

var

  Recs, I : integer;
  CView : PpxbInputLine;

begin
  CView := FirstField;
  for Recs := 1 to RecordLines do
    for I := 1 to FieldCnt do
    begin
      if (not CView^.GetState (sfFocused)) and
      (CView^.FieldTyp <> fldBlob) then
        if CView^.GetState (sfCursorIns) then
          CView^.SetState (sfCursorIns,false)
        else
          CView^.SetState (sfCursorIns,true);
      PView (CView) := CView^.Prev
    end
end;

{
If input line data has changed the lock record.  If lock fails then restore
original data.
}

procedure TpxbDialog.FieldChanged (InpLine : PpxbInputLine);

var

  TempErr : Retcode;

begin
  if EnterStr <> InpLine^.Data^ then
  begin
    TempErr := LockRec (InpLine);
    if (TempErr <> PXSUCCESS) and
    (TempErr <> PXERR_RECDELETED) and
    (TempErr <> PXERR_RECNOTFOUND) then
      InpLine^.SetData (EnterStr)
  end
end;

{
Called when a input line has been focused.  EnterStr is set to the input
lines current data, lines are positioned starting with current line and
the record lock is updated.
}

procedure TpxbDialog.FieldEnter (InpLine : PpxbInputLine);

begin
  EnterStr := InpLine^.Data^;
  TabPosLine (InpLine);
  LockUpdate (InpLine)
end;

{
Called when a input line is losing focus.  If field has been modified then
it is posted to the table.  If the write fails then false is returned.
}

function TpxbDialog.FieldExit (InpLine : PpxbInputLine) : boolean;

var

  TempErr : Retcode;

begin
  PrevField := InpLine;
  if EnterStr = InpLine^.Data^ then
    FieldExit := true
  else
  begin
    FieldExit := (not ErrorBox (WriteField (InpLine)));
    CursorPtr^.GotoRec (FirstField^.RecordNum);
    ReadFields
  end
end;

{
Move cursor to first record.
}

procedure TpxbDialog.GotoHome;

begin
  with CursorPtr^ do
  begin
    gotoBegin;
    if lastError = PXSUCCESS then
      gotoNext
  end
end;

{
Move cursor to last record.
}

procedure TpxbDialog.GotoLast;

begin
  with CursorPtr^ do
  begin
    gotoEnd;
    if lastError = PXSUCCESS then
      gotoPrev
  end
end;

{
Move down one record and update browser.
}

procedure TpxbDialog.DownRead (InpLine : PpxbInputLine);

begin
  if InpLine^.DownLine <> nil then
    InpLine^.DownLine^.Focus
  else
    if InpLine^.Valid (cmReleasedFocus) then
    begin
      CursorPtr^.GotoRec (FirstField^.RecordNum);
      CursorPtr^.gotoNext;
      ReadFields
    end
end;

{
Move up one record and update browser.
}

procedure TpxbDialog.UpRead (InpLine : PpxbInputLine);

begin
  if InpLine^.UpLine <> nil then
    InpLine^.UpLine^.Focus
  else
    if InpLine^.Valid (cmReleasedFocus) then
    begin
      CursorPtr^.GotoRec (FirstField^.RecordNum);
      CursorPtr^.gotoPrev;
      if CursorPtr^.LastError = PXERR_STARTOFTABLE then
        GotoHome;
      ReadFields
    end
end;

{
Move up one browser page and update browser.
}

procedure TpxbDialog.PageUpRead;

var

  I : integer;

begin
  if InpGroup^.Current^.Valid (cmReleasedFocus) then
  begin
    CursorPtr^.GotoRec (FirstField^.RecordNum);
      for I := 1 to RecordLines do
        CursorPtr^.gotoPrev;
    if CursorPtr^.LastError = PXERR_STARTOFTABLE then
      GotoHome;
    ReadFields
  end
end;

{
Move down one browser page and update browser.
}

procedure TpxbDialog.PageDownRead;

var

  I : integer;

begin
  if InpGroup^.Current^.Valid (cmReleasedFocus) then
  begin
    CursorPtr^.GotoRec (FirstField^.RecordNum);
      for I := 1 to RecordLines do
        CursorPtr^.gotoNext;
    if CursorPtr^.LastError = PXERR_ENDOFTABLE then
      GotoLast;
    ReadFields
  end
end;

{
Home cursor and update browser.
}

procedure TpxbDialog.HomeRead;

begin
  if InpGroup^.Current^.Valid (cmReleasedFocus) then
  begin
    CursorPtr^.gotoPrev;
    GotoHome;
    ReadFields
  end
end;

{
End cursor and update browser.
}

procedure TpxbDialog.EndRead;

begin
  if InpGroup^.Current^.Valid (cmReleasedFocus) then
  begin
    CursorPtr^.gotoNext;
    GotoLast;
    ReadFields
  end
end;

{
Get selected field text.
}

procedure TpxbDialog.CopyClip (InpLine : PpxbInputLine);

begin
  if InpLine^.SelEnd > 0 then
    PasteStr := Copy (InpLine^.Data^,InpLine^.SelStart+1,InpLine^.SelEnd-InpLine^.SelStart)
end;

{
Paste previously saved field text over current field data.
}

procedure TpxbDialog.PasteClip (InpLine : PpxbInputLine);

var

  Temp : string;

begin
  if InpLine^.FieldTyp <> fldBlob then
  begin
    if byte (PasteStr[0]) <= InpLine^.MaxLen then
      InpLine^.SetData (PasteStr)
    else
    begin
      Temp := Copy (PasteStr,1,InpLine^.MaxLen);
      InpLine^.SetData (Temp)
    end;
    FieldChanged (InpLine)
  end
end;

{
Edit unformatted memo blob with a TMemo editor.
}

procedure TpxbDialog.BlobMemoEdit (InpLine : PpxbInputLine);

var

  PrevChar : char;
  BufEle : word;
  BlobSize : longint;
  BlobBuf : PpxbMemoRec;
  MemoEditor : PpxbMemoEdit;

begin
  ErrorBox (CursorPtr^.genericRec^.openBlobRead
  (InpLine^.FieldNum,true));                      {open memo blob}
  BlobSize := CursorPtr^.genericRec^.getBlobSize
  (InpLine^.FieldNum);                           {get size}
  if BlobSize < pxbMaxUMemoSize then
  begin
    BlobBuf := MemAlloc (SizeOf (TpxbMemoRec));  {get blob buffer}
    BlobBuf^.Len := BlobSize;
    MemoEditor := New (PpxbMemoEdit, Init);
    if MemoEditor^.Valid (cmValid) then {see if memo editor is valid}
    begin
      if BlobSize <> 0 then
      begin                       {read blob into buffer}
        CursorPtr^.genericRec^.getBlob (InpLine^.FieldNum,BlobSize,0,@BlobBuf^.Data);
        PrevChar := #0;
        for BufEle := 0 to BlobSize-1 do {change #10 to #13 if not #13#10}
        begin
          if (BlobBuf^.Data[BufEle] = #10) and
          (PrevChar <> #13) then
          begin
            PrevChar := BlobBuf^.Data[BufEle];
            BlobBuf^.Data[BufEle] := #13;
          end
          else
            PrevChar := BlobBuf^.Data[BufEle]
        end
      end;
      CursorPtr^.genericRec^.closeBlob (InpLine^.FieldNum,false);
      if Application^.ExecuteDialog (MemoEditor,BlobBuf) <> cmCancel then
      begin                {write blob}
        CursorPtr^.genericRec^.openBlobWrite (InpLine^.FieldNum,BlobBuf^.Len,false);
        CursorPtr^.genericRec^.putBlob (InpLine^.FieldNum,BlobBuf^.Len,0,@BlobBuf^.Data);
        CursorPtr^.genericRec^.closeBlob (InpLine^.FieldNum,true);
        CursorPtr^.updateRec (CursorPtr^.genericRec);
      end;
      FreeMem (BlobBuf,SizeOf (TpxbMemoRec))
    end
    else
    begin {invalid memo editor}
      CursorPtr^.genericRec^.closeBlob (InpLine^.FieldNum,false);
      if BlobBuf <> nil then
        FreeMem (BlobBuf,SizeOf (TpxbMemoRec));
      Dispose (MemoEditor,Done);
      Application^.OutOfMemory
    end
  end
  else       {blob too big to fit into buffer}
    CursorPtr^.genericRec^.closeBlob (InpLine^.FieldNum,false)
end;

{
When return is pressed on a blob field this method is called.  Currently
only unformatted memos are handles, but you can add any of the other blob
types with a custom editor.
}

procedure TpxbDialog.BlobEdit (InpLine : PpxbInputLine);

begin
  if (InpLine^.RecordNum <> 0) and
  (InpLine^.FieldTyp = fldBlob) then
  begin
    if (LockRec (InpLine) = PXSUCCESS) and
    (CursorPtr^.getRecord (CursorPtr^.genericRec) = PXSUCCESS) then
      case InpLine^.FieldSub of
        fldstMemo : BlobMemoEdit (InpLine)
      else
        MessageBox (#3'This BLOB format not currently supported',
        nil,mfInformation+mfOKButton)
      end;
  end
end;

{
Lock, delete and unlock current input line's record.
}
procedure TpxbDialog.DeleteRec (InpLine : PpxbInputLine);

begin
  if InpLine^.RecordNum <> 0 then
    if LockRec (InpLine) = PXSUCCESS then
    begin
      CursorPtr^.deleteRec;
      UnlockRec;
      UpdateStatus ('Delete');
      CursorPtr^.GotoRec (FirstField^.RecordNum);
      ReadFields
    end
end;

{
Cannot resize dialog to be larger then the number of records it holds.
}

procedure TpxbDialog.SizeLimits (var Min, Max : TPoint);

begin
  inherited SizeLimits(Min, Max);
  Min.X := MinWinSize.X;
  Min.Y := MinWinSize.Y+1;
  Max.Y := MaxScrSize.Y
end;

{
Handle browser events.
}

procedure TpxbDialog.HandleEvent (var Event : TEvent);

var

  ClearFlag : boolean;

begin
  case Event.What of
    evKeyDown :
    begin
      ClearFlag := true;
      case Event.KeyCode of
        kbTab      : InpGroup^.FocusNext(false);
        kbShiftTab : InpGroup^.FocusNext(true);
        kbDown     : DownRead (PpxbInputLine (InpGroup^.Current));
        kbUp       : UpRead (PpxbInputLine (InpGroup^.Current));
        kbCtrlHome : PpxbInputLine (InpGroup^.Current)^.HomeLine^.Focus;
        kbCtrlEnd  : PpxbInputLine (InpGroup^.Current)^.EndLine^.Focus;
        kbPgDn     : PageDownRead;
        kbPgUp     : PageUpRead;
        kbCtrlPgUp : HomeRead;
        kbCtrlPgDn : EndRead;
        kbEnter    : BlobEdit (PpxbInputLine (InpGroup^.Current));
        kbCtrlDel  : DeleteRec (PpxbInputLine (InpGroup^.Current));
        kbCtrlIns  : CopyClip (PpxbInputLine (InpGroup^.Current));
        kbShiftIns : PasteClip (PpxbInputLine (InpGroup^.Current));
        kbIns      :
        begin
          ToggleIns;
          ClearFlag := false
        end
      else
        ClearFlag := false
      end;
      if ClearFlag then
        ClearEvent (Event)
    end;
    evCommand :
    begin
      ClearFlag := true;
      case Event.Command of
        cmFieldChanged : FieldChanged (PpxbInputLine (Event.InfoPtr));
        cmFieldEnter   : FieldEnter (PpxbInputLine (Event.InfoPtr));
        cmFieldExit    : ClearFlag := FieldExit (PpxbInputLine (Event.InfoPtr))
      else
        ClearFlag := false
      end;
      if ClearFlag then
        ClearEvent (Event)
    end
  end;
  inherited HandleEvent (Event)
end;

{
Make sure current input line is validated before closing dialog.  If input
line data has changed then write and unlock record.
}

function TpxbDialog.Valid (Command : word) : boolean;

var

  Temp : boolean;

begin
  Temp := inherited Valid(Command);
  if Command = cmClose then
  begin
    if FieldExit (PpxbInputLine (InpGroup^.Current)) then
      UnlockRec
    else
      Temp := false;
  end;
  Valid := Temp
end;

end.
