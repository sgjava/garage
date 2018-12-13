{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

PX Edit is a generic paradox table editor and supporting tools to interface
Turbo Vision to the OOP Database Framework.  The table editor automatically
refreshes when it is focused or the table image has changed.  Automatic
network locking is provided by locking record before allowing any editing.
Validation is provided at field change, window releasing focus and window
closing.

IMPORTANT:

Remember to add TCursor.getTableHandle method to the Data Base Framework in
\BP\PXENGINE\PASCAL\SOURCE\OOPXENG.PAS.  This allows PX Edit access to
TCursor's private table handle tabH.  PX Edit can then search on the primary
index regardless of what index the table is opened on.

Search OOPXENG.PAS for 'searchIndex'. Right after:

  function searchIndex(keyRec: PRecord; mode: PXSearchMode;
    fldCnt: Integer): Retcode; virtual;

ADD:

  function getTableHandle : TableHandle;


Search OOPXENG.PAS for 'TRecord methods'.  Right before:

*************************************************************************
                          TRecord methods
**************************************************************************

ADD:

function TCursor.getTableHandle : TableHandle;

begin
  getTableHandle := tabH
end;
}

unit PXEdit;

{$I APP.INC}
{$X+}

interface

uses

{$IFDEF DPMI}
  WinProcs,                  {windows units}
{$ENDIF}
  Dos,                       {system units}
  PxEngine, OoPxEng,         {paradox engine 3.0 and framework units}
  Drivers, Objects, Views,   {tv units}
  Validate, Dialogs, MsgBox,
{$IFDEF UseNewEdit}
  NewEdit,
{$ELSE}
  Editors,
{$ENDIF}
  App, Memory,
  CommDlgs, TVStr;           {cybertools units}

const

  pxePrimary = 100;            {gettext primary field type}
  pxeComposite = 101;          {gettext composite field type}
  pxeMaxRecBufs = 43;          {max record buffers to handle 43/50 line mode}
  pxeRecBufDiff = 5;           {difference between recs displayed and desktop y size}
  pxeLineOfs = 3;              {input line offset in dialog}
  pxeMaxUMemoSize = 65520;     {max unformatted memo blob size}
  pxeFixedMax = 1e13;          {max double val formatted as -0.00}
  pxeShareName = 'SHARE.TST';  {file name used by share test}
  pxeDataDictDB  = 'DATADICT'; {data dictionary table name}

type

  PpxeFieldDesc = ^TpxeFieldDesc;
  TpxeFieldDesc = object (TObject)
    FDispLen : integer;
    FDesc : PFieldDesc;
  end;

  PpxeField = ^TpxeField;
  TpxeField = object (TObject)
    DispStr : PString;
  end;

  PpxeRecord = ^TpxeRecord;
  TpxeRecord = object (TObject)
    RecNum : RecordNumber;
    FldColl : PCollection;
  end;

  TpxeEngineCfgRec = record
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

  PpxeEngineCfg = ^TpxeEngineCfg;
  TpxeEngineCfg = object (TDialog)
    constructor Init;
  end;

  PpxeMemoRec = ^TpxeMemoRec;
  TpxeMemoRec = record
    Len : word;
    Data : array [0..pxeMaxUMemoSize-1] of char;
  end;

  PpxeMemo = ^TpxeMemo;
  TpxeMemo = object (TMemo)
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  PpxeMemoEdit = ^TpxeMemoEdit;
  TpxeMemoEdit = object (TDialog)
    Memo : PpxeMemo;
    constructor Init;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  TpxeListBoxRec = record
    List : PCollection;
    Selection : Word;
  end;

  PpxeFieldListBox = ^TpxeFieldListBox;
  TpxeFieldListBox = object (TListBox)
    function GetText (Item : integer; MaxLen : integer) : string; virtual;
    procedure HandleEvent ( var Event : TEvent); virtual;
  end;

  TpxeCreateDlgRec = record
    Name : string[25];
    Len : string[3];
    Typ : integer;
    Fields : TpxeListBoxRec;
  end;

  PpxeCreateDialog = ^TpxeCreateDialog;
  TpxeCreateDialog = object (TDialog)
    TableNam : PathStr;
    FieldPtr : PCollection;
    TypeButtons : PMsgButtons;
    NameLine,
    LengthLine : PInputLine;
    FieldBox : PpxeFieldListBox;
    constructor Init (TblName : PathStr; FldColl : PCollection);
    procedure SetData (var Rec); virtual;
    procedure AddField;
    procedure DeleteField;
    procedure DefTypeLen;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  TpxeIndexDlgRec = record
    Fields : TpxeListBoxRec;
    Key : TpxeListBoxRec;
    Index,
    CaseSens : integer;
    FldName : string[25];
  end;

  PpxeIndexDialog = ^TpxeIndexDialog;
  TpxeIndexDialog = object (TDialog)
    FieldPtr,
    KeyPtr : PCollection;
    NameLine : PInputLine;
    FieldBox,
    KeyBox : PpxeFieldListBox;
    constructor Init (TblName : PathStr);
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  TpxeKeyDlgRec = record
    Fields : TpxeListBoxRec;
  end;

  PpxeKeyDialog = ^TpxeKeyDialog;
  TpxeKeyDialog = object (TDialog)
    FieldPtr : PCollection;
    FieldBox : PpxeFieldListBox;
    constructor Init (TblName : PathStr);
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  PpxeTableLine = ^TpxeTableLine;
  TpxeTableLine = object (TInputLine)
    FieldStr : string;
    procedure SetState (AState : word; Enable : boolean); virtual;
  end;

  PpxeTableView = ^TpxeTableView;
  TpxeTableView = object (TView)
    FocusRefresh : boolean;
    FieldCnt,
    PriFieldCnt,
    RecBufs : integer;
    TableNam : PathStr;
    IndexNumber : FieldNumber;
    EditLockHan : LockHandle;
    EditLockRecNum : RecordNumber;
    TableHan  : TableHandle;
    EnginePtr : PEngine;
    DataBasePtr : PDataBase;
    CursorPtr : PCursor;
    FieldDescColl,
    RecordColl : PCollection;
    HScrollBar : PScrollBar;
    TableLine : PpxeTableLine;
    constructor Init (var Bounds: TRect;
                      AHScrollBar : PScrollBar;
                      TblName : PathStr; EngPtr : PEngine;
                      DBPtr : PDatabase; CurPtr : PCursor;
                      IdxNum : FieldNumber);
    destructor Done; virtual;
    procedure SetLineVaildator (FTyp : PXFieldType); virtual;
    procedure DrawLine; virtual;
    procedure Draw; virtual;
    function ErrorBox (ErrCode : integer) : boolean; virtual;
    procedure NewFieldColl; virtual;
    procedure NewRecColl; virtual;
    procedure XlateField (RecData : PpxeRecord; PFld : PpxeFieldDesc); virtual;
    procedure ReadFields; virtual;
    function SearchKey (RecData : PpxeRecord; SMode : integer) : Retcode; virtual;
    function SearchSecKey (RecData : PpxeRecord; SMode : integer) : Retcode; virtual;
    procedure Refresh; virtual;
    function GotoHome : Retcode; virtual;
    function GotoLast : Retcode; virtual;
    function DownRead : Retcode; virtual;
    function UpRead : Retcode; virtual;
    function PageDownRead : Retcode; virtual;
    function PageUpRead : Retcode; virtual;
    function HomeRead : Retcode; virtual;
    function EndRead : Retcode; virtual;
    function LockRec (RecData : PpxeRecord) : Retcode; virtual;
    function UnlockRec : Retcode; virtual;
    function LockUpdate : Retcode; virtual;
    function WriteField : Retcode; virtual;
    function BlobMemoEdit : Retcode; virtual;
    function BlobEdit : Retcode; virtual;
    function DeleteRec : Retcode; virtual;
    procedure HandleEvent ( var Event : TEvent); virtual;
    function Valid (Command : word) : boolean; virtual;
  end;

  PpxeTableWin = ^TpxeTableWin;
  TpxeTableWin = object (TDialog)
    TableView : PpxeTableView;
    constructor Init (TblName : PathStr; EngPtr : PEngine;
                      DBPtr : PDatabase; CurPtr : PCursor;
                      IdxNum : FieldNumber);
    procedure SizeLimits (var Min, Max : TPoint); virtual;
    procedure SetState (AState : word; Enable : boolean); virtual;
    procedure HandleEvent ( var Event : TEvent); virtual;
    function Valid (Command : word) : boolean; virtual;
  end;

const

  pxeBlobNames : {names used in place of data for blob input lines}
  array [0..4] of string [17] =
  (
  '<BLOB Memo>',
  '<BLOB Binary>',
  '<BLOB Fmt Memo>',
  '<BLOB OLE Object>',
  '<BLOB Graphic>'
  );

{px edit commands}

  cmFieldAdd       = 65300;
  cmFieldDelete    = 65301;
  cmFieldEdit      = 65302;
  cmFieldEnter     = 65303;
  cmFieldExit      = 65304;
  cmVideoChange    = 65305;

{commands to toggle when entering/exiting table editor window}

  pxeEditCmds = [cmCopy, cmPaste];

{data dictionary table field numbers}

  pxeddFile    = 1;
  pxeddNum     = 2;
  pxeddName    = 3;
  pxeddType    = 4;
  pxeddLen     = 5;
  pxeddPri     = 6;
  pxeddSec     = 7;

{procedural functions}

function ShareInstalled : boolean;
function GetFieldDesc (FileName : PathStr; DataB : PDataBase; var FldColl : PCollection) : Retcode;
function GetKeyFiles (TblName : PathStr) : PStringCollection;
function GetKeyFieldDesc (FileName : PathStr; DataB : PDataBase; var FldColl : PCollection) : Retcode;
procedure EngCfgToDlgCfg (EngCfg : TEnv; var DlgCfg : TpxeEngineCfgRec);
procedure DlgCfgToEngCfg (DlgCfg : TpxeEngineCfgRec; var EngCfg : TEnv);
function CreateTableDataDict (DB : PDatabase; TName : PathStr) : Retcode;

implementation

{
Determine if share is installed by creating a file of word, writing one word
and locking one byte using DOS.
}

function ShareInstalled : boolean;

var

  F : file of word;
  TestData : word;
  ShareFailed : byte;

begin
  ShareFailed := 1; {assume failure}
  Assign (F,pxeShareName);
  {$I-} Rewrite (F); {$I+}
  if IoResult = 0 then
  begin
    {$I-} Write (F,TestData); {$I+}
    if IoResult = 0 then
    begin
      asm
        mov  bx, FileRec (F).handle {file handle}
        mov  cx, 0000h              {high word section offset}
        mov  dx, 0000h              {low word section offset}
        mov  si, 0000h              {high word of section length}
        mov  di, 0001h              {low word of section length}
        mov  al, 00h                {lock file function}
        mov  ah, 5ch                {func 5ch control record access}
{$IFDEF DPMI}
        call DOS3Call               {dpmi dos int}
{$ELSE}
        int  21h                    {real dos int}
{$ENDIF}
        jc   @lockerror             {if not lock error then}
        dec  ShareFailed            { sharefailed = 0 (ok)}
      @lockerror:
      end;
      ShareInstalled := (ShareFailed <> 1);
      {$I-} Close (F); {$I+}
      if IoResult = 0 then
        {$I-} Erase (F) {$I+}
    end
  end
end;

{
Get collection of field descriptions.  Requires one table handle.
}

function GetFieldDesc (FileName : PathStr; DataB : PDataBase; var FldColl : PCollection) : Retcode;

var

  I, FldCnt : integer;
  PDesc : PFieldDesc;
  FieldCur : PCursor;

begin
  FieldCur := New (PCursor,
  InitAndOpen (DataB,FileName,0,true));             {new cursor}
  if FieldCur^.lastError = PXSUCCESS then
  begin
    FldCnt := FieldCur^.genericRec^.getFieldCount;  {field count}
    FldColl := New (PCollection,Init (FldCnt,0));   {field desc collection}
    for I := 1 to FldCnt do                         {read in field descs}
    begin
      PDesc := New (PFieldDesc,Init);               {allocate field desc}
      FieldCur^.genericRec^.getFieldDesc (I,PDesc); {get field desc}
      FldColl^.Insert (PDesc)                       {add to collection}
    end
  end;
  GetFieldDesc := FieldCur^.lastError;              {return last error}
  Dispose (FieldCur,Done)                           {dealloc table cursor}
end;

{
Get string collection of key files with .PX and .X?? mask for given table
name.
}

function GetKeyFiles (TblName : PathStr) : PStringCollection;

var

  FileInfo : SearchRec;
  FileColl : PStringCollection;

begin
  FileColl := New (PStringCollection,Init (10,10)); {file name collection}
  FindFirst (AddExtStr (TblName,'PX'),
  AnyFile,FileInfo);                                {get primary index}
  if DosError = 0 then                              {primary index found?}
  begin
    FileColl^.Insert (NewStr (FileInfo.Name));      {add to collection}
    FindFirst (AddExtStr (TblName,'X??'),
    AnyFile,FileInfo);                              {get secondary index}
    while DosError = 0 do
    begin
      FileColl^.Insert (NewStr (FileInfo.Name));    {add to collection}
      FindNext (FileInfo)
    end
  end;
  if FileColl^.Count = 0 then                       {handle empty list}
  begin
    Dispose (FileColl,Done);
    FileColl := nil
  end;
  GetKeyFiles := FileColl
end;

{
Get collection of key field descriptions for given table name.  Requires one
table handle.
}

function GetKeyFieldDesc (FileName : PathStr; DataB : PDataBase; var FldColl : PCollection) : Retcode;

var

  CaseSens : integer;
  D : DirStr;
  N : NameStr;
  E : ExtStr;
  CurDir : PathStr;
  FieldFiles : PStringCollection;
  FldHanArr : FieldHandleArray;
  PDesc : PFieldDesc;
  FieldCur : PCursor;

procedure AddField (Item : pointer); far;

begin                                         {add field desc to list}
  PDesc := New (PFieldDesc,Init);             {allocate field desc}
  PXKeyQuery (PString (Item)^,PDesc^.fldName, {get index info}
  PDesc^.fldLen,CaseSens,FldHanArr,PDesc^.fldNum);
  if PDesc^.fldNum = 0 then
  begin                                       {primary index}
    PDesc^.fldName := 'Primary';
    byte (PDesc^.fldType) := pxePrimary;      {primary field type for gettext}
    PDesc^.fldLen := DataB^.getNumPFields (N) {primary field count}
  end
  else {get real desc if single field case-sensitive index}
    if PDesc^.fldNum < 256 then
      FieldCur^.genericRec^.getFieldDesc (
      PDesc^.fldNum,PDesc) {get field desc}
    else                   {compisite field type for gettext}
      byte (PDesc^.fldType) := pxeComposite;
  FldColl^.Insert (PDesc)  {add to collection}
end;

begin
  FldColl := nil;                         {assume failure}
  FSplit (FileName,D,N,E);
  if D[byte (D[0])] = '\' then            {delete '\' at end of path name}
    Dec (byte (D[0]));
  GetDir (0,CurDir);                       {save current dir}
  {$I-} ChDir (D); {$I+}
  if IoResult = 0 then
  begin
    FieldCur := New (PCursor,
    InitAndOpen (DataB,N,0,true));          {new cursor}
    if FieldCur^.lastError = PXSUCCESS then
    begin
      FieldFiles := GetKeyFiles (N);        {get string collection of key files}
      if FieldFiles <> nil then             {any key files?}
      begin
        FldColl := New (PCollection,
        Init (FieldFiles^.Count,0));        {field desc collection}
        FieldFiles^.ForEach (@AddField);
        Dispose (FieldFiles,Done);          {dealloc field file names}
        if FldColl^.Count = 0 then          {handle empty list}
        begin
          Dispose (FldColl,Done);
          FldColl := nil
        end
      end
    end;
    GetKeyFieldDesc := FieldCur^.lastError; {return last cursor error}
    Dispose (FieldCur,Done);                {dealloc table cursor}
    {$I-} ChDir (CurDir); {$I+}
    if IoResult <> 0 then
      GetKeyFieldDesc := PXERR_DIRNOACCESS
  end
  else
    GetKeyFieldDesc := PXERR_DIRNOACCESS
end;

{
Convert TEnv to TpxeEngineCfgRec, so it can be used with a TpxeEngineCfg
dialog.
}

procedure EngCfgToDlgCfg (EngCfg : TEnv; var DlgCfg : TpxeEngineCfgRec);

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
Convert TpxeEngineCfgRec to TEnv , so it can be used after a TpxeEngineCfg
dialog.
}

procedure DlgCfgToEngCfg (DlgCfg : TpxeEngineCfgRec; var EngCfg : TEnv);

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
Create table from data dictionary if it doesn't exist.
}

function CreateTableDataDict (DB : PDatabase; TName : PathStr) : Retcode;

var

  Blank : boolean;
  I, fLen : integer;
  TNameKey, TNewNameKey : string[8];
  PriFlag, SecFlag, fType : string[1];
  fName : string[MaxNameLen];
  FL, PK, SK : FieldNumber;
  FieldPtr : PCollection;
  DescPtr : PFieldDesc;
  DataDictCur : PCursor;

begin
  if not DB^.tableExists (TName) then
  begin {create table if it doesn't exist}
    DataDictCur := New (PCursor,InitAndOpen (DB,pxeDataDictDB,0,true));
    if DataDictCur^.lastError = PXSUCCESS then
    begin
      FL := 0;
      PK := 0;
      SK := 0;
      TNameKey := GetFileNameStr (TName);
      TNewNameKey := TNameKey;
      FieldPtr := New (PCollection,Init (10,10));

      with DataDictCur^ do
      begin
        gotoBegin;
        if lastError = PXSUCCESS then
          gotoNext;
        genericRec^.clear;
        genericRec^.putString (pxeddFile,TNameKey);
        lastError := PXSrchKey (getTableHandle,
        genericRec^.recH,pxeddFile,SearchFirst);
      end;
      while (DataDictCur^.lastError = PXSUCCESS) and
      (TNameKey = TNewNameKey) do
      begin
        DataDictCur^.getRecord (DataDictCur^.genericRec);
        with DataDictCur^.genericRec^ do
        begin
          getString (pxeddFile,TNewNameKey,Blank);
          if TNameKey = TNewNameKey then
          begin
            Inc (FL);
            getString (pxeddName,fName,Blank);
            getString (pxeddType,fType,Blank);
            getInteger (pxeddLen,fLen,Blank);
            getString (pxeddPri,PriFlag,Blank);
            if PriFlag = 'Y' then
              PK := FL;
            getString (pxeddSec,SecFlag,Blank);
            if SecFlag = 'Y' then
              SK := FL;
            DescPtr := New (PFieldDesc,Init);
            with DescPtr^ do
            begin
              fldNum := FL;
              fldName := fName;
              fldLen := fLen;
              case fType[1] of
                'N' :
                begin
                  fldType := fldDouble;
                  fldSubtype := fldstNone
                end;
                'S' :
                begin
                  fldType := fldShort;
                  fldSubtype := fldstNone
                end;
                '$' :
                begin
                  fldType := fldDouble;
                  fldSubtype := fldstMoney
                end;
                'D' :
                begin
                  fldType := fldDate;
                  fldSubtype := fldstNone
                end;
                'A' :
                begin
                  fldType := fldChar;
                  fldSubtype := fldstNone
                end;
                'M' :
                begin
                  fldType := fldBlob;
                  fldSubtype := fldstMemo
                end;
                'B' :
                begin
                  fldType := fldBlob;
                  fldSubtype := fldstBinary
                end;
                'F' :
                begin
                  fldType := fldBlob;
                  fldSubtype := fldstFmtMemo
                end;
                'O' :
                begin
                  fldType := fldBlob;
                  fldSubtype := fldstOleObj
                end;
                'G' :
                begin
                  fldType := fldBlob;
                  fldSubtype := fldstGraphic
                end
              end
            end;
            FieldPtr^.Insert (DescPtr)
          end
        end;
        DataDictCur^.gotoNext
      end
    end;
    if DB^.createTable (TName,FieldPtr) = PXSUCCESS then
    begin
      if PK > 0 then
      begin
        if DB^.createPIndex (TName,PK) = PXSUCCESS then
        begin
          if SK > 0 then
            DB^.createSIndex (TName,SK,pxIncSecondary)
        end
      end
    end;
    Dispose (FieldPtr,Done);
    Dispose (DataDictCur,Done);
    CreateTableDataDict := DB^.lastError
  end
  else
    CreateTableDataDict := PXSUCCESS
end;

{
TpxeEngineCfg allows you modify a TEnv record for custom engine start up.
A TpxeEngineCfgRec can be used to set/get the dialog's data.  Use
EngCfgToDlgCfg to convert TEnv rec to dialog rec before calling
TpxeEngineCfgRec.Init.  Use DlgCfgToEngCfg afterwards to convert dialog rec
back to TEnv rec.
}

constructor TpxeEngineCfg.Init;

var

  R : TRect;
  RB : PRadioButtons;
  Field : PInputLine;

begin
  R.Assign (0,0,53,20);
  inherited Init (R,'Paradox Engine Options');
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
Send tab to TEditor instead to TMemo.
}

procedure TpxeMemo.HandleEvent (var Event : TEvent);


begin
  TEditor.HandleEvent (Event)
end;

{
TpxeMemoEdit is a editor dialog for unformatted memo blobs.
}

constructor TpxeMemoEdit.Init;

var

  R : TRect;
  HScrollBar,
  VScrollBar : PScrollBar;

begin
  DeskTop^.GetExtent (R);
  inherited Init (R,'Memo Editor');
  Options := Options or ofValidate or ofTileable;
  Flags := wfMove+wfGrow+wfClose+wfZoom;
  GrowMode := gfGrowRel;
  Palette := dpBlueDialog;

  HScrollBar := StandardScrollBar (sbHorizontal or sbHandleKeyboard);
  Insert (HScrollBar);
  VScrollBar := StandardScrollBar (sbVertical or sbHandleKeyboard);
  Insert (VScrollBar);

  GetExtent (R);
  R.Grow (-1,-1);
  Memo := New(PpxeMemo, Init (R,HScrollBar,VScrollBar,nil,pxeMaxUMemoSize));
  {$IFDEF UseNewEdit}
  Memo^.AutoIndent := True;
  Memo^.Word_Wrap := True;
  Memo^.Right_Margin := cdRightMargin;
  {$ENDIF}
  Insert (Memo)
end;

{
Convert cmCancel to cmOK, since no buttons are provided.
}

procedure TpxeMemoEdit.HandleEvent (var Event : TEvent);

begin
  if (Event.What = evCommand) and
  (Event.Command = cmCancel) then
    Event.Command := cmOK;
  inherited HandleEvent (Event)
end;

{
TpxeFieldListBox is pick list using TFieldDesc collection.  GetText formats
the field description as Field³Typ³Len  ³Name.  Display types for primary
and composite are also accounted for.
}

function TpxeFieldListBox.GetText(Item: Integer; MaxLen: Integer): String;

var

  C : char;
  P : PFieldDesc;

begin
  if List <> nil then
  begin
    P := PFieldDesc (List^.At (Item));
    case byte (P^.fldType) of {field type letter}
      byte (fldChar)  : C := 'A';
      byte (fldShort) : C := 'S';
      byte (fldDouble):
        if P^.fldSubtype = fldstNone then
          C := 'N'
        else
          C := '$';
      byte (fldDate)  : C := 'D';
      byte (fldBlob)  :
      case P^.fldSubtype of   {blob type letter}
        fldstMemo    : C := 'M';
        fldstBinary  : C := 'B';
        fldstFmtMemo : C := 'F';
        fldstOleObj  : C := 'O';
        fldstGraphic : C := 'G'
      end;
      pxePrimary : C := 'P';  {handle special types}
      pxeComposite : C := 'C'
    end;                      {make display string}
    GetText := IntToRightStr (P^.fldNum,3)+' ³ '+C+' ³ '+IntToRightStr (P^.fldLen,3)+' ³ '+P^.fldName
  end
  else                        {empty list}
    GetText := ''
end;

{
Use enter to select item.
}

procedure TpxeFieldListBox.HandleEvent ( var Event : TEvent);

begin
  inherited HandleEvent (Event);
  if (Event.What = evKeyDown) and
  (Event.KeyCode = kbEnter) and
  (List^.Count > 0) then
  begin {broadcast that list item selected}
    Event.What := evBroadcast;
    Event.Command := cmListItemSelected;
    PutEvent (Event);
    ClearEvent (Event)
  end
end;

{
TpxeCreateDialog allows you to edit a list of field descriptions for creating
paradox tables.  If the table exists with the same name then it is deleted
first.
}

constructor TpxeCreateDialog.Init (TblName : PathStr; FldColl : PCollection);

var

  R : TRect;
  VScrollBar : PScrollBar;

begin
  R.Assign (0,0,66,17);
  inherited Init (R,TblName);
  Options := Options or ofCentered;
  TableNam := TblName;
  FieldPtr := FldColl;
  R.Assign (2,3,29,4);
  NameLine := New(PInputLine,Init(R,25));
  Insert (NameLine);
  R.Assign(1,2,6,3);
  Insert (New (PLabel,Init (R,'~N~ame',NameLine)));

  R.Assign (41,3,46,4);
  LengthLine := New(PInputLine,Init(R,3));
  LengthLine^.SetValidator (New (PRangeValidator,Init (0,255)));
  Insert (LengthLine);
  R.Assign(40,2,46,3);
  Insert (New (PLabel,Init (R,'~L~en',LengthLine)));

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
  FieldBox := New (PpxeFieldListBox,Init (R,1,VScrollBar));
  Insert (FieldBox);
  R.Assign (1,4,22,5);
  Insert (New (PLabel,Init (R,'~F~ield Typ Len   Name',FieldBox)));

  R.Assign (2,14,12,16);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (15,14,25,16);
  Insert (New (PButton,Init (R,'~A~dd',cmFieldAdd,bfNormal)));
  R.Assign (28,14,38,16);
  Insert (New (PButton,Init (R,'~D~elete',cmFieldDelete,bfNormal)));
  R.Assign (41,14,51,16);
  Insert (New (PButton,Init (R,'~C~opy',cmFieldEdit,bfNormal)));
  R.Assign (54,14,64,16);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)));
  SelectNext (false)
end;

{
Set the valid field range by type when dialog's set data is called.
}

procedure TpxeCreateDialog.SetData (var Rec);

begin
  inherited SetData (Rec);
  DefTypeLen
end;

{
Adds field to field pick list.  Accepts names that are not '' or duplicated
and checks for correct field length.
}

procedure TpxeCreateDialog.AddField;

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
            FieldPtr^.Insert (P) {add to end of list}
          else                   {insert before selected item}
            FieldPtr^.AtInsert (FieldBox^.Focused,P);
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

procedure TpxeCreateDialog.DeleteField;

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
Set 'length' line's range by field type.
}

procedure TpxeCreateDialog.DefTypeLen;

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

procedure TpxeCreateDialog.HandleEvent (var Event : TEvent);

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
    NameLine^.SetData (FldDesc^.fldName); {set name}
    LenStr := IntToStr (FldDesc^.fldLen);
    LengthLine^.SetData (LenStr);         {set length}
    case FldDesc^.fldType of              {convert field type to button val}
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
  inherited HandleEvent (Event);
  case Event.What of
    evCommand :
    begin {process commands}
      case Event.Command of
        cmFieldAdd    : AddField;
        cmFieldDelete : DeleteField;
        cmFieldEdit   : EditField
      else
        Exit
      end;
      ClearEvent (Event)
    end;
    evBroadcast:
    begin {process broadcasts}
      case Event.Command of
        cmMsgButtonPress : DefTypeLen
      end
    end
  end
end;

{
TpxeIndexDialog allows you to create primary and secondary indexes.
}

constructor TpxeIndexDialog.Init (TblName : PathStr);

var

  R : TRect;
  VScrollBar : PScrollBar;
  IndexBut,
  CaseBut : PRadioButtons;

begin
  R.Assign (0,0,48,19);
  inherited Init (R,TblName);
  Options := Options or ofCentered;

  R.Assign(45,3,46,7);
  New (VScrollBar,Init (R));
  Insert (VScrollBar);

  R.Assign (2,3,45,7);
  FieldBox := New (PpxeFieldListBox,Init (R,1,VScrollBar));
  Insert (FieldBox);
  R.Assign (1,2,22,3);
  Insert (New (PLabel,Init (R,'~F~ield Typ Len   Name',FieldBox)));

  R.Assign(45,8,46,12);
  New (VScrollBar,Init (R));
  Insert (VScrollBar);

  R.Assign (2,8,45,12);
  KeyBox := New (PpxeFieldListBox,Init (R,1,VScrollBar));
  Insert (KeyBox);
  R.Assign (1,7,22,8);
  Insert (New (PLabel,Init (R,'~S~econdary key fields',KeyBox)));

  R.Assign (2,13,19,17);
  IndexBut := New (PRadioButtons,Init (R,
    NewSItem ('Primary',
    NewSItem ('Secondary',
    NewSItem ('Incremental',
    nil)))));
  Insert (IndexBut);
  R.Assign (1,12,6,13);
  Insert (New (PLabel,Init (R,'~T~ype',IndexBut)));

  R.Assign (20,13,35,15);
  CaseBut := New (PRadioButtons,Init (R,
  NewSItem ('On',
  NewSItem ('Off',
  nil))));
  Insert (CaseBut);
  R.Assign (19,12,34,13);
  Insert (New (PLabel,Init (R,'~C~ase sensitive',CaseBut)));

  R.Assign (20,16,35,17);
  NameLine := New(PInputLine,Init(R,25));
  Insert (NameLine);
  R.Assign (19,15,34,16);
  Insert (New (PLabel,Init (R,'~N~ame',NameLine)));

  R.Assign (36,13,46,15);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (36,16,46,18);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)));
  SelectNext (false)
end;

{
Handle events from list boxes.
}

procedure TpxeIndexDialog.HandleEvent (var Event : TEvent);

var

  PDesc : PFieldDesc;

begin
  inherited HandleEvent (Event);
  if Event.What = evBroadcast then
    if Event.Command = cmListItemSelected then
    begin
      if FieldBox^.State and sfSelected <> 0 then
      begin {move item from field box to key box}
        PDesc := New (PFieldDesc,Init); {allocate new description}
        PDesc^ := PFieldDesc (FieldBox^.List^.At (FieldBox^.Focused))^;
        FieldBox^.List^.Free (FieldBox^.List^.At (FieldBox^.Focused));
        KeyBox^.List^.Insert (PDesc); {move to key box}
        FieldBox^.SetRange (FieldBox^.List^.Count);
        FieldBox^.DrawView;
        KeyBox^.SetRange (KeyBox^.List^.Count);
        KeyBox^.DrawView
      end
      else
      begin {move item from key box to field box}
        PDesc := New (PFieldDesc,Init);
        PDesc^ := PFieldDesc (KeyBox^.List^.At (KeyBox^.Focused))^;
        KeyBox^.List^.Free (KeyBox^.List^.At (KeyBox^.Focused));
        FieldBox^.List^.Insert (PDesc); {move to field box}
        KeyBox^.SetRange (KeyBox^.List^.Count);
        KeyBox^.DrawView;
        FieldBox^.SetRange (FieldBox^.List^.Count);
        FieldBox^.DrawView
      end
    end
end;

{
TpxeKeyDialog allows you to select any key for a particular table.
}

constructor TpxeKeyDialog.Init (TblName : PathStr);

var

  R : TRect;
  VScrollBar : PScrollBar;

begin
  R.Assign (0,0,48,12);
  inherited Init (R,TblName);
  Options := Options or ofCentered;

  R.Assign(45,3,46,7);
  New (VScrollBar,Init (R));
  Insert (VScrollBar);

  R.Assign (2,3,45,7);
  FieldBox := New (PpxeFieldListBox,Init (R,1,VScrollBar));
  Insert (FieldBox);
  R.Assign (1,2,22,3);
  Insert (New (PLabel,Init (R,'~F~ield Typ Len   Name',FieldBox)));

  R.Assign (25,8,35,10);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (36,8,46,10);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)));
  SelectNext (false)
end;

{
Handle list box selection.
}

procedure TpxeKeyDialog.HandleEvent (var Event : TEvent);

var

  PDesc : PFieldDesc;

begin
  inherited HandleEvent (Event);
  if (Event.What = evBroadcast) and
  (Event.Command = cmListItemSelected) then
  begin
    Event.What := evCommand;
    Event.Command := cmOk;
    PutEvent (Event);
    ClearEvent (Event)
  end
end;

{
TpxeTableLine
}

{
Notifies owner that you are entering/exiting input line.  Same as TView's
cmReceivedFocus and cmReleasedFocus, but no need to TypeOf @Self to find
out what sent it.
}

procedure TpxeTableLine.SetState (AState : word; Enable : boolean);

begin
  inherited SetState (AState,Enable);
  if (AState = sfSelected) and
  (State and sfActive <> 0) then
  begin
   if State and sfSelected = 0 then
     Message(Owner,evBroadcast,cmFieldExit,@Self)
   else
     Message(Owner,evBroadcast,cmFieldEnter,@Self)
  end
end;

{
TpxeTableView handles all the low level table and cursor functions.  It is
designed to be inserted into a TDialog decendant instead of a TWindow.
FocusRefresh flag added to handle situations when you do not want focus
release to refresh view.
}

constructor TpxeTableView.Init (var Bounds: TRect;
                             AHScrollBar : PScrollBar;
                             TblName : PathStr; EngPtr : PEngine;
                             DBPtr : PDatabase; CurPtr : PCursor;
                             IdxNum : FieldNumber);

begin
  inherited Init (Bounds);
  Options := Options or ofSelectable or ofValidate;
  EventMask := EventMask or evBroadcast;
  GrowMode := gfGrowHiX + gfGrowHiY;
  HScrollBar := AHScrollBar;
  TableNam := TblName;         {set params needed by px framework}
  EnginePtr := EngPtr;
  DataBasePtr := DBPtr;
  CursorPtr := CurPtr;
  IndexNumber := IdxNum;
  EditLockHan := 0;
  EditLockRecNum := 0;
  FocusRefresh := true;                  {ok to refresh on focus release}
  TableHan := CursorPtr^.getTableHandle; {get private table handle}
  FieldCnt := CursorPtr^.genericRec^.getFieldCount;     {number of fields}
  PriFieldCnt := DataBasePtr^.getNumPFields (TableNam); {number of primary key fields}
  RecBufs := DeskTop^.Size.Y-pxeRecBufDiff; {max rec buffers needed to draw entire window}
  NewFieldColl; {create collection of field descriptions}
  NewRecColl;   {create collection of records}
  GotoHome;     {move table cursor to home}
  HScrollBar^.SetParams (0,0,FieldCnt-1,1,1)
end;

{
Dispose dynamic structures before calling inherited done.
}

destructor TpxeTableView.Done;

{dispose record collection}

procedure DisposeRecord (Item : pointer); far;

{dispose field collection}

procedure DisposeField (Item : pointer); far;

begin
  DisposeStr (PpxeField (Item)^.DispStr)
end;

begin
  PpxeRecord (Item)^.FldColl^.ForEach (@DisposeField);
  Dispose (PpxeRecord (Item)^.FldColl,Done)
end;

{dispose field descriptions}

procedure DisposeFieldDesc (Item : pointer); far;

begin
  Dispose (PpxeFieldDesc (Item)^.FDesc,Done)
end;

begin
  TableLine^.MaxLen := 255;    {make sure whole string disposed}
  if FieldDescColl <> nil then {dispose field desc collection}
  begin
    FieldDescColl^.ForEach (@DisposeFieldDesc);
    Dispose (FieldDescColl,Done)
  end;
  if RecordColl <> nil then    {dispose record collection}
  begin
    RecordColl^.ForEach (@DisposeRecord);
    Dispose (RecordColl,Done)
  end;
  if CursorPtr <> nil then     {dispose cursor}
    Dispose (CursorPtr,Done);
  inherited Done
end;

{
Set input line validator by field type.  Override this function to add
custom validation.
}

procedure TpxeTableView.SetLineVaildator (FTyp : PXFieldType);

begin
  case FTyp of
    fldChar, fldBlob :
      if TableLine^.Validator <> nil then
      begin
        TableLine^.Validator^.Free;
        TableLine^.Validator := nil
      end;
    fldDouble :
      TableLine^.SetValidator (New (PFilterValidator,
      Init (['0'..'9','+','-','.','E','e',' '])));
    fldDate :
      TableLine^.SetValidator (New (PPXPictureValidator,
      Init ('{##}/{##}/{####}',true)));
    fldShort :
      TableLine^.SetValidator (New (PFilterValidator,
      Init (['0'..'9','+','-',' '])));
    fldLong :
    TableLine^.SetValidator (New (PFilterValidator,
    Init (['0'..'9','+','-',' '])))
  end;
  if FTyp <> fldBlob then  {disable line when on a blob field}
    TableLine^.SetState (sfDisabled,false)
  else
    TableLine^.SetState (sfDisabled,true)
end;

{
Draw input line with current field data.  The input line is used as a
cursor and field editor.
}

procedure TpxeTableView.DrawLine;

var

  X, Y : integer;
  R : TRect;
  PDesc : PpxeFieldDesc;

begin
  PDesc := FieldDescColl^.At (HScrollBar^.Value); {get field description}
  TableLine^.FieldStr := TrimStr (PString (PpxeField (
  PpxeRecord (RecordColl^.At (TableLine^.Origin.Y-pxeLineOfs))^.FldColl^.At (
  HScrollBar^.Value))^.DispStr)^);          {set field string}
  TableLine^.MaxLen := PDesc^.FDispLen;     {set input line's length}
  TableLine^.Data^ := TableLine^.FieldStr;  {set input line's data}
  if Size.X > PDesc^.FDispLen+3 then        {calc x length}
    X := PDesc^.FDispLen+4
  else
    X := Size.X+1;
  if TableLine^.Origin.Y < Size.Y then      {calc y location}
    Y := TableLine^.Origin.Y
  else
    Y := Size.Y-1;
  R.Assign (2,Y,X,Y+1);                     {define input line's rect}
  TableLine^.Locate (R);                    {move line}
  SetLineVaildator (PDesc^.FDesc^.fldType); {set validator}
  TableLine^.DrawView;                      {draw line}
  LockUpdate                                {make sure lock updated}
end;

{
Draw table from record display buffer.  Primary key fields are highlighted
using colorized text (~Field_Name~) in the field name line.
}

procedure TpxeTableView.Draw;

var

  C1 : word;
  Y, CFld, DLen, MLen : integer;
  BufStr, TopStr, BotStr : string;
  B : array[0..511] of word;
  PDesc : PpxeFieldDesc;

begin
  C1 := GetColor (6);                  {normal drawing color}
  MoveChar (B,' ',C1,Size.X);          {fill buffer line with spaces}
  CFld := HScrollBar^.Value;           {current field number}
  BufStr := '';                        {prepare display and heading lines}
  TopStr := 'Ú';
  BotStr := 'À';
  MLen := Size.X;                      {max string length}
  repeat                               {build field name line and top/bottom frame}
    PDesc := FieldDescColl^.At (CFld); {get field desc}
    if PDesc^.FDispLen < MLen then     {adjust length to handle overflow}
      DLen := PDesc^.FDispLen+2
    else
      DLen := MLen;
    if CFld < PriFieldCnt then         {highlight primary key fields}
    begin
      BufStr := BufStr+' ~'+
      PadRightStr (PDesc^.FDesc^.fldName,' ',DLen)+'~';
      Inc (MLen,2)                     {account for '~~'}
    end
    else                               {normal color text}
      BufStr := BufStr+' '+
      PadRightStr (PDesc^.FDesc^.fldName,' ',DLen);
    TopStr := TopStr+FillStr ('Ä',DLen)+'Â'; {top frame}
    BotStr := BotStr+FillStr ('Ä',DLen)+'Á'; {bottom frame}
    Inc (CFld)                               {next field}
  until (byte (BufStr[0]) > MLen) or    {exit if string long enough or}
  (CFld = FieldCnt);                    {max fields reached}
  MoveCStr (B,BufStr,GetColor ($0706)); {move string to buffer}
  WriteBuf (0,0,Size.X,1,B);            {write it}
  TopStr[byte (TopStr[0])] := '¿';      {finish off top frame}
  MoveStr (B,TopStr,C1);                {move to buffer}
  WriteBuf (0,1,Size.X,1,B);            {write it}
  for Y := 2 to Size.Y-2 do             {lay out fields to fill rest of view}
  begin
    CFld := HScrollBar^.Value;          {current field}
    BufStr := '³ ';                     {start with vert bar on left}
    repeat                              {build string with fields}
      BufStr := BufStr+PString (PpxeField (PpxeRecord (
      RecordColl^.At (Y-2))^.FldColl^.At (CFld))^.DispStr)^;
      if byte (BufStr[0]) > Size.X then  {handle overflow}
        byte (BufStr[0]) := Size.X+1;
      BufStr := BufStr+' ³ ';            {end each field with vert bar on right}
      Inc (CFld)                         {next field}
    until (byte (BufStr[0]) > Size.X) or {until overflow or max field count}
    (CFld = FieldCnt);
    MoveStr (B,BufStr,C1);               {move to buffer}
    WriteBuf (0,Y,Size.X,1,B)            {write it}
  end;
  BotStr[byte (BotStr[0])] := 'Ù';  {finish off bottom frame}
  MoveStr (B,BotStr,C1);            {move to buffer}
  WriteBuf (0,Size.Y-1,Size.X,1,B); {write it}
  DrawLine                          {update input line}
end;

{
Displays error dialog for errors <> PXSUCCESS.  ErrorBox returns true if
error <> PXSUCCESS and false if error = PXSUCCESS.
}

function TpxeTableView.ErrorBox (ErrCode : integer) : boolean;

begin
  if ErrCode <> PXSUCCESS then
  begin
    FocusRefresh := false;
    MessageBox (EnginePtr^.getErrorMessage (ErrCode)+'.',
    nil, mfError or mfOKButton);
    FocusRefresh := true;
    ErrorBox := true
  end
  else
    ErrorBox := false
end;

{
Create new collection of custom field descriptions.
}

procedure TpxeTableView.NewFieldColl;

var

  I : FieldNumber;
  PDesc : PpxeFieldDesc;

begin
  FieldDescColl := New (PCollection,Init (FieldCnt,0));
  for I := 1 to FieldCnt do {make collection without using table handle}
  begin                     {like getDescVector}
    PDesc := New (PpxeFieldDesc,Init);
    PDesc^.FDesc := New (PFieldDesc,Init);
    CursorPtr^.genericRec^.getFieldDesc (I,PDesc^.FDesc);
    case PDesc^.FDesc^.fldType of {set field diaplay length}
      fldChar   : PDesc^.FDispLen := PDesc^.FDesc^.fldLen;
      fldShort  : PDesc^.FDispLen := 6;
      fldLong   : PDesc^.FDispLen := 11;
      fldDouble : PDesc^.FDispLen := 17;
      fldDate   : PDesc^.FDispLen := 10;
      fldBlob   : {blobs are set by their description length}
        case PDesc^.FDesc^.fldSubType of
          fldstMemo    : PDesc^.FDispLen := byte (pxeBlobNames[0,0]);
          fldstBinary  : PDesc^.FDispLen := byte (pxeBlobNames[1,0]);
          fldstFmtMemo : PDesc^.FDispLen := byte (pxeBlobNames[2,0]);
          fldstOleObj  : PDesc^.FDispLen := byte (pxeBlobNames[3,0]);
          fldstGraphic : PDesc^.FDispLen := byte (pxeBlobNames[4,0])
        end
    end;
    FieldDescColl^.Insert (PDesc) {add to collection}
  end
end;

{
Create new record collection of field collections.
}

procedure TpxeTableView.NewRecColl;

var

  I : integer;
  PColl : PCollection;
  PRec : PpxeRecord;

{make field and fill with ' '}

procedure MakeField (Item : pointer); far;

var

  PField : PpxeField;

begin
  PField := New (PpxeField,Init);
  PField^.DispStr := NewStr (
  FillStr (' ',PpxeFieldDesc (Item)^.FDispLen));
  PColl^.Insert (PField) {add to field collection}
end;

begin
  RecordColl := New (PCollection,Init (pxeMaxRecBufs,0));
  for I := 1 to pxeMaxRecBufs do {make records}
  begin
    PColl := New (PCollection,Init (FieldCnt,0));
    FieldDescColl^.ForEach (@MakeField); {build fields}
    PRec := New (PpxeRecord,Init);       {allocte record}
    PRec^.FldColl := PColl;              {assign field collection}
    RecordColl^.Insert (PRec)            {add to record collection}
  end
end;

{
Translate field into displable string.
}

procedure TpxeTableView.XlateField (RecData : PpxeRecord; PFld : PpxeFieldDesc);

var

  isBlank : boolean;
  S : integer;
  L : longint;
  D : double;
  TempStr : string;
  FldStr : PString;

begin
  FldStr := PString (PpxeField (
  RecData^.FldColl^.At (PFld^.FDesc^.fldNum-1))^.DispStr); {get field string}
  if not CursorPtr^.genericRec^.isNull (PFld^.FDesc^.fldNum) then
  begin
    case PFld^.FDesc^.fldType of
      fldChar   : {char fields translated by framework}
      begin
        CursorPtr^.genericRec^.getString
        (PFld^.FDesc^.fldNum,TempStr,isBlank);
        TempStr := PadRightStr (TempStr,' ',PFld^.FDispLen)
      end;
      fldDouble : {convert double to right justified 0.00 or 1e14}
      begin
        CursorPtr^.genericRec^.getDouble (PFld^.FDesc^.fldNum,D,isBlank);
        if (Abs (D) < pxeFixedMax) then
          Str (D:17:2,TempStr)
        else
          Str (D:17,TempStr)
      end;
      fldDate   : {convert date to mm/dd/yyyy}
        CursorPtr^.genericRec^.getString (PFld^.FDesc^.fldNum,TempStr,isBlank);
      fldShort  : {convert short to right justified integer}
      begin
        CursorPtr^.genericRec^.getField (PFld^.FDesc^.fldNum,@S,SizeOf (S),isBlank);
        Str (S:6,TempStr)
      end;
      fldBlob   : {use blob name}
        case PFld^.FDesc^.fldSubtype of
          fldstMemo    : TempStr := pxeBlobNames[0];
          fldstBinary  : TempStr := pxeBlobNames[1];
          fldstFmtMemo : TempStr := pxeBlobNames[2];
          fldstOleObj  : TempStr := pxeBlobNames[3];
          fldstGraphic : TempStr := pxeBlobNames[4]
        end;
      fldLong   : {convert longint to right justified longint}
      begin
        CursorPtr^.genericRec^.getField (PFld^.FDesc^.fldNum,@L,SizeOf (L),isBlank);
        Str (L:11,TempStr)
      end
    end;
    FldStr^ := TempStr
  end
  else {null fields are filled with spaces}
    FldStr^ := FillStr (' ',PFld^.FDispLen)
end;

{
Read and translate records to fill entire editor buffer.
}

procedure TpxeTableView.ReadFields;

var

  I : integer;
  CRec : PpxeRecord;

{xlate field into displable string}

procedure XlateFld (Item : pointer); far;

begin
  XLateField (CRec,Item)
end;

{fill field with blanks}

procedure EmptyField (Item : pointer); far;

var

  FldStr : PString;
  PFld : PpxeFieldDesc;

begin
  PFld := Item;
  FldStr := PString (PpxeField (
  CRec^.FldColl^.At (PFld^.FDesc^.fldNum-1))^.DispStr);
  FldStr^ := FillStr (' ',PFld^.FDispLen)
end;

begin
  if (EnginePtr^.engineType <> pxLocal) and
  (CursorPtr^.hasChanged) then  {update table image if it has changed}
    CursorPtr^.refresh;
  for I := 0 to RecBufs-1 do    {fill buffer}
  begin
    CRec := RecordColl^.At (I); {record buffer}
    if CursorPtr^.LastError = PXSUCCESS then
    begin
      CursorPtr^.getRecord (CursorPtr^.genericRec); {get record}
      if CursorPtr^.LastError = PXSUCCESS then
      begin
        CRec^.RecNum := CursorPtr^.getCurRecNum; {set record number}
        FieldDescColl^.ForEach (@XlateFld); {xlate fields to display strings}
        CursorPtr^.gotoNext                 {goto next record}
      end
      else
      begin
        CRec^.RecNum := 0;                   {error record number}
        FieldDescColl^.ForEach (@EmptyField) {handle error with blanks}
      end
    end
    else
    begin
      CRec^.RecNum := 0;                   {error record number}
      FieldDescColl^.ForEach (@EmptyField) {handle error with blanks}
    end
  end;
  if CursorPtr^.LastError = PXERR_ENDOFTABLE then
    GotoLast;                              {handle end of table error}
  LockUpdate                               {make sure lock updated}
end;

{
Make primary search key from display strings and search for match.  If cursor
is not opened on primary or secondary index then gotoRec is used.
}

function TpxeTableView.SearchKey (RecData : PpxeRecord; SMode : integer) : Retcode;

var

  I : integer;

begin
  CursorPtr^.genericRec^.clear;    {clear record buffer}
  if PriFieldCnt <> 0 then         {table has primary index}
  begin
    for I := 0 to PriFieldCnt-1 do {xlate primary fields}
      CursorPtr^.genericRec^.putString (I+1,
      PString (PpxeField (RecData^.FldColl^.At (I))^.DispStr)^);
    SearchKey := PXSrchKey (TableHan,CursorPtr^.genericRec^.recH,
    PriFieldCnt,SMode)
  end
  else                             {table doesn't have primary index}
    if RecData^.RecNum <> 0 then
      SearchKey := CursorPtr^.GotoRec (RecData^.RecNum)
    else                           {non-keyed table with empty search record}
      SearchKey := GotoHome
end;

{
Make secondary search key from display strings and search for match.  If
cursor is not opened on primary or secondary index then gotoRec is used.
}

function TpxeTableView.SearchSecKey (RecData : PpxeRecord; SMode : integer) : Retcode;

var

  I : integer;

begin
  CursorPtr^.genericRec^.clear; {clear record buffer}
  if PriFieldCnt <> 0 then      {table has primary index}
  begin
    for I := 0 to FieldCnt-1 do {xlate all fields}
      CursorPtr^.genericRec^.putString (I+1,
      PString (PpxeField (RecData^.FldColl^.At (I))^.DispStr)^);
    SearchSecKey := PXSrchFld (TableHan,CursorPtr^.genericRec^.recH,
    IndexNumber,SMode)
  end
  else                          {table doesn't have any indexs}
    if RecData^.RecNum <> 0 then
      SearchSecKey := CursorPtr^.GotoRec (RecData^.RecNum)
    else                        {non-keyed table with empty search record}
      SearchSecKey := GotoHome
end;

{
Refresh and redraw editor.
}

procedure TpxeTableView.Refresh;

begin
  if IndexNumber = 0 then
  begin
    if SearchKey (RecordColl^.At (0),SearchFirst) <> PXSUCCESS then
      SearchKey (RecordColl^.At (0),ClosestRecord)
  end
  else
  begin
    if SearchKey (RecordColl^.At (0),SearchFirst) <> PXSUCCESS then
      SearchSecKey (RecordColl^.At (0),ClosestRecord)
  end;
  ReadFields;
  DrawView
end;

{
Move cursor to first record.
}

function TpxeTableView.GotoHome : Retcode;

begin
  if (EnginePtr^.engineType <> pxLocal) and
  (CursorPtr^.hasChanged) then  {update table image if it has changed}
    CursorPtr^.refresh;
  with CursorPtr^ do
  begin
    gotoBegin;
    if lastError = PXSUCCESS then
      gotoNext
  end;
  GotoHome := CursorPtr^.lastError
end;

{
Move cursor to last record.
}

function TpxeTableView.GotoLast : Retcode;

begin
  if (EnginePtr^.engineType <> pxLocal) and
  (CursorPtr^.hasChanged) then  {update table image if it has changed}
    CursorPtr^.refresh;
  with CursorPtr^ do
  begin
    gotoEnd;
    if lastError = PXSUCCESS then
      gotoPrev
  end;
  GotoLast := CursorPtr^.lastError
end;

{
Move down one record and update editor.
}

function TpxeTableView.DownRead : Retcode;

var

  I : integer;
  CRec : PpxeRecord;

{xlate field into displable string}

procedure XlateFld (Item : pointer); far;

begin
  XLateField (CRec,Item)
end;

{fill field with blanks}

procedure EmptyField (Item : pointer); far;

var

  FldStr : PString;
  PFld : PpxeFieldDesc;

begin
  PFld := Item;
  FldStr := PString (PpxeField (
  CRec^.FldColl^.At (PFld^.FDesc^.fldNum-1))^.DispStr);
  FldStr^ := FillStr (' ',PFld^.FDispLen)
end;

begin
  if TableLine^.Origin.Y < Size.Y-1 then
  begin {move cursor down if not on bottom line}
    Inc (TableLine^.Origin.Y);
    DrawView;
    DownRead := PXSUCCESS
  end
  else {cursor on bottom, so scroll 1 record up}
  begin
    if PpxeRecord (RecordColl^.At (Size.Y-4))^.RecNum <> 0 then
    begin
      if (EnginePtr^.engineType <> pxLocal) and
      (CursorPtr^.hasChanged) then  {update table image if it has changed}
        CursorPtr^.refresh;
      CRec := New (PpxeRecord,Init);
      CRec^ := PpxeRecord (RecordColl^.At (0))^; {save top record}
      SearchKey (RecordColl^.At (RecBufs-1),SearchFirst); {find last record}
      RecordColl^.Free (RecordColl^.At (0));   {dispose top record}
      RecordColl^.AtInsert (RecBufs-1,CRec);   {insert at bottom}
      CursorPtr^.gotoNext;                     {goto record after last record}
      if CursorPtr^.lastError <> PXERR_ENDOFTABLE then
      begin
        CursorPtr^.getRecord (CursorPtr^.genericRec); {get record}
        CRec^.RecNum := CursorPtr^.getCurRecNum;      {set record number}
        FieldDescColl^.ForEach (@XlateFld)            {xlate fields to strings}
      end
      else
      begin
        CRec^.RecNum := 0;                   {error record number}
        FieldDescColl^.ForEach (@EmptyField) {handle error with blanks}
      end;
      DrawView
    end;
    if CursorPtr^.lastError = PXERR_ENDOFTABLE then
      GotoLast;
    DownRead := CursorPtr^.lastError
  end
end;

{
Move up one record and update editor.
}

function TpxeTableView.UpRead : Retcode;

var

  I : integer;
  CRec : PpxeRecord;

{xlate field into displable string}

procedure XlateFld (Item : pointer); far;

begin
  XLateField (CRec,Item)
end;

begin
  if TableLine^.Origin.Y > 3 then
  begin {move cursor up if not on top line}
    Dec (TableLine^.Origin.Y);
    DrawView;
    UpRead := PXSUCCESS
  end
  else {cursor on top, so scroll 1 record down}
  begin
    if (EnginePtr^.engineType <> pxLocal) and
    (CursorPtr^.hasChanged) then  {update table image if it has changed}
      CursorPtr^.refresh;
    SearchKey (RecordColl^.At (0),SearchFirst);      {find top record}
    CursorPtr^.gotoPrev;                             {goto record before it}
    if CursorPtr^.lastError <> PXERR_STARTOFTABLE then
    begin
      CRec := New (PpxeRecord,Init);
      CRec^ := PpxeRecord (RecordColl^.At (RecBufs-1))^;
      RecordColl^.Free (RecordColl^.At (RecBufs-1)); {dispose last record}
      RecordColl^.AtInsert (0,CRec);                 {add new record at top of list}
      CursorPtr^.getRecord (CursorPtr^.genericRec);  {get record}
      CRec^.RecNum := CursorPtr^.getCurRecNum;       {set record number}
      FieldDescColl^.ForEach (@XlateFld)             {xlate fields to display strings}
    end
    else
      GotoHome;
    DrawView;
    UpRead := CursorPtr^.lastError
  end
end;

{
Move down one window page and update editor.
}

function TpxeTableView.PageDownRead : Retcode;

var

  I : integer;
  PRec : PpxeRecord;

begin
  PRec := RecordColl^.At (Size.Y-4);
  if PRec^.RecNum <> 0 then
  begin
    SearchKey (PRec,SearchFirst);
    CursorPtr^.gotoNext;
    if CursorPtr^.LastError = PXERR_ENDOFTABLE then
      GotoLast;
    ReadFields;
    if PRec^.RecNum = 0 then  {view not full, so back up}
    begin
      for I := 6 to Size.Y do {back up y size records}
        CursorPtr^.gotoPrev;
      if CursorPtr^.lastError = PXERR_STARTOFTABLE then
        GotoHome;
      ReadFields
    end;
    DrawView
  end;
  PageDownRead := CursorPtr^.lastError
end;

{
Move up one window page and update editor.
}

function TpxeTableView.PageUpRead : Retcode;

var

  I : integer;

begin
  SearchKey (RecordColl^.At (0),SearchFirst);
  for I := 4 to Size.Y do          {back up y size records}
    CursorPtr^.gotoPrev;
  if CursorPtr^.lastError = PXERR_STARTOFTABLE then
    GotoHome;
  if CursorPtr^.lastError = PXSUCCESS then
  begin
    ReadFields;
    DrawView
  end;
  PageUpRead := CursorPtr^.lastError
end;

{
Home cursor and update editor.
}

function TpxeTableView.HomeRead : Retcode;

begin
  GotoHome;
  ReadFields;
  DrawView;
  HomeRead := CursorPtr^.lastError
end;

{
End cursor and update editor.
}

function TpxeTableView.EndRead : Retcode;

var

  I : integer;

begin
  GotoLast;
  for I := 6 to Size.Y do {back up enough records to fill view}
    CursorPtr^.gotoPrev;
  if CursorPtr^.lastError = PXERR_STARTOFTABLE then
    GotoHome;            {tried to back up beyond start of table}
  ReadFields;
  DrawView;
  EndRead := CursorPtr^.lastError
end;

{
Goto record and lock with network retry.  If the record is currently locked
then LockRec will not change lock handle or locked record number.  If the
record number = 0 then LockRec will zero the lock handle and locked record
number.  If lock handle <> 0 (record locked) then locked record number and
lock handle are not changed.  Local engine fakes locks by assigning record
number to lock handle and locked record number.  This is so tabbing will
leave editor in edit mode if the locked record number = current record
number.  LockRec returns error code or PXSUCCESS if valid.
}

function TpxeTableView.LockRec (RecData : PpxeRecord) : Retcode;

var

  TempErr : Retcode;
  BoxCmd : word;
  LongInfo : longint;
  NetErrStr : string;

begin
  if RecData^.RecNum <> 0 then
  begin
    if EditLockHan = 0 then
    begin
      TempErr := SearchKey (RecData,SearchFirst); {seek to record pos}
      if TempErr = PXSUCCESS then
      begin
        if EnginePtr^.engineType <> pxLocal then
        begin {only try locking if engine set for network use}
          repeat
            EditLockHan := CursorPtr^.lockRecord; {get lock handle}
            TempErr := CursorPtr^.lastError;
            if TempErr = PXERR_RECLOCKED then     {if locked the ask to retry}
            begin
              NetErrStr := DataBasePtr^.getNetErrUser; {see what user is locking}
              if NetErrStr = '' then
                NetErrStr := 'unknown or local user';
              LongInfo := longint (@NetErrStr);
              FocusRefresh := false;
              BoxCmd := MessageBox (
              'Record is locked by %s.  Try to lock record again?',
              @LongInfo,mfYesButton+mfNoButton);
              FocusRefresh := true
            end
            else
              BoxCmd := cmNo
          until (TempErr = PXSUCCESS) or (BoxCmd = cmNo);
          if TempErr = PXSUCCESS then                {record locked}
            EditLockRecNum := RecData^.RecNum
          else
          begin
            TableLine^.Data^ := TableLine^.FieldStr; {restore old field}
            TableLine^.DrawView
          end
        end
        else {if local engine then just fake lock}
        begin
          EditLockHan := RecData^.RecNum;
          EditLockRecNum := EditLockHan
        end
      end
    end
    else {if record already locked then just seek}
      TempErr := SearchKey (RecData,SearchFirst)
  end
  else
  begin {can't lock new records, so return pxsuccess}
    EditLockHan := 0;
    EditLockRecNum := 0;
    TempErr := PXSUCCESS
  end;
  if (TempErr = PXERR_RECDELETED) or {handle deleted or not found records}
  (TempErr = PXERR_RECNOTFOUND) then
    Refresh;
  LockRec := TempErr
end;

{
Unlock record, zero lock handle and record number.
}

function TpxeTableView.UnlockRec : Retcode;

begin
  if (EnginePtr^.engineType <> pxLocal) and
  (EditLockHan <> 0) then
    UnlockRec := CursorPtr^.unlockRecord (EditLockHan)
  else
    UnlockRec := PXSUCCESS;
  EditLockHan := 0;
  EditLockRecNum := 0;
end;

{
Unlock locked record if another record selected or if editor in browse mode.
}

function TpxeTableView.LockUpdate : RetCode;

begin
  if (PpxeRecord (RecordColl^.At (
  TableLine^.Origin.Y-pxeLineOfs))^.RecNum <> EditLockRecNum) or
  (State and sfSelected <> 0) then
    LockUpdate := UnlockRec
  else
    LockUpdate := PXSUCCESS
end;

{
Translate field, read record, change field and write record.  Record is
locked before write attempts, so explicit locking is not required.
}

function TpxeTableView.WriteField : Retcode;

var

  TempErr : Retcode;
  E : extended;
  PDesc : PpxeFieldDesc;
  PRec : PpxeRecord;
  PField : PpxeField;

begin
  PDesc := FieldDescColl^.At (HScrollBar^.Value); {get desc, rec and field}
  PRec := RecordColl^.At (TableLine^.Origin.Y-pxeLineOfs);
  PField := PRec^.FldColl^.At (HScrollBar^.Value);
  if PRec^.RecNum <> 0 then
  begin
    TempErr := LockRec (PRec);
    if TempErr = PXSUCCESS then              {get existing record}
      TempErr := CursorPtr^.getRecord (CursorPtr^.genericRec)
  end
  else
    TempErr := CursorPtr^.genericRec^.clear; {clear for new record}
  if TempErr = PXSUCCESS then
  begin
    if TrimStr (TableLine^.Data^) <> '' then
    begin
      if PDesc^.FDesc^.fldType = fldDouble then
      begin                                  {convert/validate doubles}
        Val(TrimStr (TableLine^.Data^),E,TempErr);
        if TempErr = 0 then
        begin
          if ((Abs (E) >= strDoubleMin) and  {double range test}
          (Abs (E) <= strDoubleMax)) or
          (E = 0.0) then
            TempErr := CursorPtr^.genericRec^.putDouble (PDesc^.FDesc^.fldNum,E)
          else
            TempErr := PXERR_OUTOFRANGE
        end
        else {val conversion error}
        begin
          TableLine^.CurPos := TempErr-1; {place cursor on error char}
          TempErr := PXERR_DATACONV
        end
      end
      else {all non-double fields use framework to convert/validate}
        TempErr := CursorPtr^.genericRec^.putString (PDesc^.FDesc^.fldNum,TrimStr (TableLine^.Data^))
    end
    else   {set field to null}
      TempErr := CursorPtr^.genericRec^.setNull (PDesc^.FDesc^.fldNum);
    if TempErr = PXSUCCESS then {update/append record if no errors}
    begin
      if PRec^.RecNum <> 0 then
        TempErr := CursorPtr^.updateRec (CursorPtr^.genericRec)  {update rec}
      else
        TempErr := CursorPtr^.appendRec (CursorPtr^.genericRec); {new rec}
      if CursorPtr^.getCurRecNum <> EditLockRecNum then
        UnlockRec; {if rec number changed then unlock rec}
      Refresh
    end
  end;
  WriteField := TempErr
end;

{
Edit unformatted memo blob with a TMemo editor window.  Expects record
to be locked before calling.  Translates buffer to handle differences
between Paradox and TMemo format.  Closing the memo editor will cause
editor to refresh.
}

function TpxeTableView.BlobMemoEdit : Retcode;

var

  BlobSize : longint;
  TempErr : Retcode;
  PDesc : PpxeFieldDesc;
  BlobBuf : PpxeMemoRec;
  MemoEditor : PpxeMemoEdit;

{xlate from paradox to editor format}

procedure XlateBufFrom;

var

  PrevChar : char;
  BufEle : word;

begin
  if BlobBuf^.Len > 0 then
  begin
    PrevChar := #0;
    for BufEle := 0 to BlobBuf^.Len-1 do {change #10 to #13 if not #13#10}
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
  end
end;

{xlate to paradox from editor format}

procedure XlateBufTo;

var

  PrevChar : char;
  BufEle,
  CopyEle,
  BLen : word;

begin
  if BlobBuf^.Len > 0 then
  begin
    BLen := BlobBuf^.Len-1;
    PrevChar := #0;
    for BufEle := 0 to BLen do {change #13#10 and #13 to #10}
    begin
      if PrevChar = #13 then
      begin
        if BlobBuf^.Data[BufEle] = #10 then     {#13#10 to #10}
        begin
          Move (BlobBuf^.Data[BufEle],          {use move to delete #13}
          BlobBuf^.Data[BufEle-1],BlobBuf^.Len-BufEle);
          PrevChar := BlobBuf^.Data[BufEle];
          Dec (BlobBuf^.Len)                    {adjust for #13 delete}
        end
        else                                    {#13 to #10}
        begin
          BlobBuf^.Data[BufEle-1] := #10;
          PrevChar := BlobBuf^.Data[BufEle]
        end
      end
      else
        PrevChar := BlobBuf^.Data[BufEle]
    end;
    if BlobBuf^.Data[BlobBuf^.Len-1] = #13 then {change last char in buffer}
      BlobBuf^.Data[BlobBuf^.Len-1] := #10
  end
end;

begin
  PDesc := FieldDescColl^.At (HScrollBar^.Value); {open memo blob}
  TempErr := CursorPtr^.genericRec^.openBlobRead (PDesc^.FDesc^.fldNum,false);
  if not ErrorBox (TempErr) then
  begin
    BlobSize := CursorPtr^.genericRec^.getBlobSize
    (PDesc^.FDesc^.fldNum);                        {get size}
    if BlobSize < pxeMaxUMemoSize then             {check for overflow}
    begin
      BlobBuf := MemAlloc (SizeOf (TpxeMemoRec));  {get blob buffer}
      BlobBuf^.Len := BlobSize;
      MemoEditor := New (PpxeMemoEdit, Init);
      if MemoEditor^.Valid (cmValid) then {see if memo editor is valid}
      begin
        if BlobSize <> 0 then
        begin                             {read blob into buffer}
          TempErr := CursorPtr^.genericRec^.getBlob (
          PDesc^.FDesc^.fldNum,BlobSize,0,@BlobBuf^.Data);
          XlateBufFrom                    {xlate from paradox format}
        end;
        CursorPtr^.genericRec^.closeBlob (PDesc^.FDesc^.fldNum,false);
        Application^.ExecuteDialog (MemoEditor,BlobBuf);
        XlateBufTo;                     {xlate to paradox format}
        CursorPtr^.genericRec^.openBlobWrite (PDesc^.FDesc^.fldNum,BlobBuf^.Len,false);
        CursorPtr^.genericRec^.putBlob (PDesc^.FDesc^.fldNum,BlobBuf^.Len,0,@BlobBuf^.Data);
        CursorPtr^.genericRec^.closeBlob (PDesc^.FDesc^.fldNum,true);
        CursorPtr^.updateRec (CursorPtr^.genericRec);
        Refresh;
        FreeMem (BlobBuf,SizeOf (TpxeMemoRec))
      end
      else
      begin   {invalid memo editor}
        CursorPtr^.genericRec^.closeBlob (PDesc^.FDesc^.fldNum,false);
        if BlobBuf <> nil then
          FreeMem (BlobBuf,SizeOf (TpxeMemoRec));
        Dispose (MemoEditor,Done);
        Application^.OutOfMemory
      end
    end
    else       {blob too big to fit into buffer}
    begin
      CursorPtr^.genericRec^.closeBlob (PDesc^.FDesc^.fldNum,false);
      MessageBox (#3'Memo blob too large to fit editor buffer.',
      nil,mfError or mfOKButton)
    end
  end;
  BlobMemoEdit := TempErr
end;

{
When Enter is pressed on a blob field this method is called.  Currently
only unformatted memos are handles, but you can add any of the other blob
types with a custom editor.
}

function TpxeTableView.BlobEdit : Retcode;

var

  PDesc : PpxeFieldDesc;
  PRec : PpxeRecord;

begin
  FocusRefresh := false;
  PDesc := FieldDescColl^.At (HScrollBar^.Value);
  PRec := RecordColl^.At (TableLine^.Origin.Y-pxeLineOfs);
  if (PRec^.RecNum <> 0) and
  (PDesc^.FDesc^.fldType = fldBlob) then {only existing blob records}
  begin
    if (LockRec (PRec) = PXSUCCESS) and {lock blob's record}
    (CursorPtr^.getRecord (CursorPtr^.genericRec) = PXSUCCESS) then
      case PDesc^.FDesc^.fldSubType of {handle each blob type}
        fldstMemo : BlobMemoEdit
      else
        MessageBox (#3'This BLOB format not currently supported',
        nil,mfInformation+mfOKButton)
      end
  end;
  FocusRefresh := true;
  BlobEdit := CursorPtr^.lastError
end;

{
Lock and delete current record.  PXRecDelete unlocks record, so the handle is
zeroed.  The GotoHome call is required because deleteRec leaves the
curStatus = atCrack instead of atRecord.  PXRecDelete moves to the next
record automatically.
}

function TpxeTableView.DeleteRec : Retcode;

var

  I : integer;
  PRec : PpxeRecord;

begin
  I := TableLine^.Origin.Y-pxeLineOfs;
  PRec := RecordColl^.At (I); {current rec}
  if PRec^.RecNum <> 0 then            {only delete existing records}
    if LockRec (PRec) = PXSUCCESS then {lock it}
    begin
      if CursorPtr^.deleteRec = PXSUCCESS then
      begin                    {record deleted}
        EditLockHan := 0;
        EditLockRecNum := 0;
        if I <> 0 then
        begin
          GotoHome;            {move from crack}
          Refresh              {refresh editor}
        end
        else                   {deleted top editor record}
        begin
          CursorPtr^.gotoNext; {move to record after top editor record}
          ReadFields;          {refresh editor}
          DrawView
        end
      end
    end;
  DeleteRec := CursorPtr^.lastError
end;

{
Handle events.  Some editing events are handled by the Owner.
}

procedure TpxeTableView.HandleEvent ( var Event : TEvent);

begin
  inherited HandleEvent (Event);
  case Event.What of
    evKeyDown :
    begin
      case Event.KeyCode of
        kbDown     : DownRead;
        kbUp       : UpRead;
        kbPgDn     : PageDownRead;
        kbPgUp     : PageUpRead;
        kbCtrlPgUp : HomeRead;
        kbCtrlPgDn : EndRead
      else
        case Event.CharCode of
        ^Y : DeleteRec
        else
          Exit
        end
      end;
      ClearEvent (Event)
    end;
    evBroadcast :
    begin
      case Event.Command of
        cmScrollBarChanged :
        begin {scroll editor left and right with scroll bar}
          if Event.InfoPtr = HScrollBar then
            DrawView
        end;
        cmFieldExit :
        begin {if input line modified then write it on exit}
          if TableLine^.FieldStr <> TableLine^.Data^ then
          begin
            if ErrorBox (WriteField) then
            begin {lock rec does a selectall if error, so we change here}
              TableLine^.SelEnd := 0;
              DrawLine
            end
          end
          else    {unlock rec if input line data not modified}
            UnlockRec
        end
      end
    end
  end
end;

{
Make sure we can lock record before releasing focus to input line.
}

function TpxeTableView.Valid (Command : word) : boolean;

var

  Temp : boolean;

begin
  Temp := inherited Valid (Command);
  if Command = cmReleasedFocus then
    Temp := LockRec (RecordColl^.At (
    TableLine^.Origin.Y-pxeLineOfs)) = PXSUCCESS;
  Valid := Temp
end;

{
TpxeTableWin
}

constructor TpxeTableWin.Init (TblName : PathStr; EngPtr : PEngine;
                            DBPtr : PDatabase; CurPtr : PCursor;
                            IdxNum : FieldNumber);

var

  R : TRect;
  HScrollBar : PScrollBar;

begin
  Desktop^.GetExtent (R);
  inherited Init (R,TblName);
  Options := Options or ofValidate or ofTileable;
  Flags := wfMove+wfGrow+wfClose+wfZoom;
  GrowMode := gfGrowRel;
  Palette := dpBlueDialog;
  HScrollBar := StandardScrollBar (sbHorizontal or sbHandleKeyboard);
  Insert (HScrollBar);

  GetExtent (R);
  R.Grow (-1,-1);
  TableView := New (PpxeTableView, Init (R,HScrollBar,TblName,EngPtr,DBPtr,CurPtr,IdxNum));
  Insert (TableView);

  R.Assign (2,3,10,4);
  TableView^.TableLine := New (PpxeTableLine,Init (R,255));
  Insert (TableView^.TableLine);
  TableView^.TableLine^.MoveTo (2,3);
  SelectNext (False)
end;

{
Cannot resize window while modifing a field.
}

procedure TpxeTableWin.SizeLimits (var Min, Max : TPoint);

begin
  inherited SizeLimits(Min, Max);
  if TableView^.TableLine^.State and sfSelected <> 0 then
  begin
    Min := Size;
    Max := Size
  end
end;

{
Enable/disable edit commands when entering/leaving window.  Refresh editor
when entering window.
}

procedure TpxeTableWin.SetState (AState : word; Enable : boolean);

begin
  inherited SetState (AState, Enable);
  if AState = sfFocused then
  begin
    if Enable then
    begin {window selected}
      if TableView^.FocusRefresh then
        TableView^.Refresh;
      EnableCommands (pxeEditCmds)
    end
    else  {leaving window focus}
      DisableCommands (pxeEditCmds)
  end
end;

{
Handle dialog events.
}

procedure TpxeTableWin.HandleEvent ( var Event : TEvent);

{handle tab positioning}

procedure TabPos;

var

  TabDir : integer;

begin
  with TableView^ do
  begin
    if Event.KeyCode = kbTab then {move right}
    begin
      if HScrollBar^.Value < FieldCnt-1 then
        TabDir := 1
      else
        TabDir := 0
    end
    else
    begin
      if HScrollBar^.Value > 0 then {move left}
        TabDir := -1
      else
        TabDir := 0
    end;
    if TabDir <> 0 then
    begin
      if TableLine^.State and sfSelected <> 0 then
      begin
        if TableLine^.FieldStr <> TableLine^.Data^ then
        begin
          if not ErrorBox (WriteField) then
          begin
            if EditLockRecNum = 0 then {record unlocked, exit edit mode}
              Focus
            else
            begin
              HScrollBar^.SetValue (HScrollBar^.Value+TabDir);
              TableLine^.SelectAll (true)
            end
          end
        end
        else
        begin
          HScrollBar^.SetValue (HScrollBar^.Value+TabDir);
          TableLine^.SelectAll (true)
        end
      end
      else
        HScrollBar^.SetValue (HScrollBar^.Value+TabDir)
    end;
    ClearEvent (Event)
  end
end;

{enter to toggle in/out of edit/browse mode.  blobs can be edited in either
mode}

procedure EnterToggle;

begin
  with TableView^ do
  begin
    if PpxeFieldDesc (FieldDescColl^.At (
    HScrollBar^.Value))^.FDesc^.fldType <> fldBlob then
    begin {toggle between table view/line}
      if TableLine^.State and sfSelected = 0 then
        TableLine^.Focus
      else
        TableView^.Focus
    end
    else {blob editor}
      ErrorBox (TableView^.BlobEdit);
    LockUpdate
  end
end;

{copy selected text to clip board}

procedure CopyClip;

var

  PasteStr : string;

begin
  with TableView^ do
  begin
    if (ClipBoard <> nil) and
    (TableLine^.State and sfSelected <> 0) and
    (TableLine^.SelEnd > 0) then
    begin
      PasteStr := Copy (TableLine^.Data^,
      TableLine^.SelStart+1,TableLine^.SelEnd-TableLine^.SelStart);
      ClipBoard^.InsertText (@PasteStr[1],byte (PasteStr[0]),true)
    end
  end
end;

{paste selected text to editor}

procedure PasteClip;

var

  CurChar : word;
  TempStr : string;
  PDesc : PpxeFieldDesc;

begin
  with TableView^ do
    if (ClipBoard <> nil) and
    (TableLine^.State and sfSelected <> 0) then
    begin
      PDesc := FieldDescColl^.At (HScrollBar^.Value);
      TempStr := '';
      CurChar := ClipBoard^.SelStart;
      while (CurChar < ClipBoard^.SelEnd) and
      (byte (TempStr[0]) < PDesc^.FDispLen) do
      begin
        TempStr := TempStr+ClipBoard^.BufChar (CurChar);
        Inc (CurChar)
      end;
      if TempStr <> '' then
        TableLine^.SetData (TempStr)
    end
end;

begin
  case Event.What of {need to see these before inherited method}
    evKeyDown :
    begin
      case Event.KeyCode of
        kbTab,
        kbShiftTab : TabPos;
        kbEnter    : EnterToggle
      end
    end
  end;
  inherited HandleEvent (Event);
  case Event.What of
    evCommand :
    begin {window commands}
      case Event.Command of
        cmCopy  : CopyClip;
        cmPaste : PasteClip
      end
    end;
    evBroadcast :
    begin {window cannot resize or scroll when editing field}
      case Event.Command of
        cmFieldEnter  :
        begin
          TableView^.HScrollBar^.SetState (sfDisabled,true);
          Flags := Flags and not wfZoom;
          Frame^.DrawView {hide zoom icon}
        end;
        cmFieldExit   :
        begin
          TableView^.HScrollBar^.SetState (sfDisabled,false);
          Flags := Flags or wfZoom;
          Frame^.DrawView {show zoom icon}
        end;
        cmVideoChange : {change number of record buffers}
        begin
          TableView^.RecBufs := DeskTop^.Size.Y-pxeRecBufDiff;
          if State and sfSelected <> 0 then {refresh if selected}
            TableView^.Refresh              {if editing field it will be set}
        end                                 {to current field value}
      end
    end
  end
end;

{
Make sure current field is written and unlocked If input line data has
changed.
}

function TpxeTableWin.Valid (Command : word) : boolean;

var

  Temp : boolean;

begin
  Temp := inherited Valid (Command);
  if (Command = cmReleasedFocus) or
  (Command = cmClose) then
  begin
    with TableView^ do
    begin
      if TableLine^.FieldStr <> TableLine^.Data^ then
        Temp := not ErrorBox (WriteField)  {field changed, so write it}
      else
        Temp := true;
      if (Temp) and (TableLine^.State and sfSelected <> 0) then
        TableView^.Focus;                  {select table view if line selected}
      if Command = cmReleasedFocus then
        LockUpdate                         {update lock}
      else
        UnlockRec                          {unlock rec if closing}
    end
  end;
  Valid := Temp
end;

end.
