{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

CyberBase application using Paradox Engine 3.x and PX Edit to edit multiple
Paradox tables on single user or network systems.  Table passwords,
encryption, decryption, create, append, copy, rename, empty, delete and
upgrade are supported.  Primary, secondary, composite and case insensitive
indexes can be created and deleted.  The table editor can copy and paste
fields using the standard clip board.  This allows easy import and export of
blob memo fields up to 64K or standard field types.

Floating status bar reports what the app is doing during some operations.

Borland Pascal 7.x or Turbo Pascal 7.x, Turbo Vision 2.x and Paradox
Engine 3.x Database Framework are required to compile.

Set IDE directories to

\BP\UNITS;
\BP\EXAMPLES\DOS\TVDEMO;
\BP\EXAMPLES\DOS\TVFM;
\BP\PXENGINE\PASCAL\SOURCE;
\BP\PXENGINE\PASCAL;

I used \BP\PXENGINE when I installed Paradox Engine 3.x.  The rest of the
path names use BP 7.x defaults.  If you changed any of these then use the
correct paths in Options|Directories...  See APP.INC for global compiler
switches.

* * *  I M P O R T A N T  * * *

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

USING WITH NETWORKS

All groups of users that will be sharing tables must have read/write access
to the network control file PDOXUSRS.NET created by the engine or another
Paradox app.  If you enable DOS share option then SHARE.EXE must be loaded.
If SHARE.EXE is not detected then all table functions are disabled.  See
Options|Engine... dialog to set Engine settings.  CyberBase has been tested
under MS-DOS, Windows 3.1, Novell via Tokenring and Lantastic with a mix of
Engine and Paradox DOS/Windows apps running.
}

{$I APP.INC}
{$X+}

program CyberBase;

uses

  Dos,                               {system units}
  OOPXEng, PXEngine,                 {paradox engine 3 and framework units}
  Memory, Drivers, Objects,          {tv units}
  Views, Menus, Dialogs, Editors,
  App, MsgBox, StdDlg, ColorSel,
  Gadgets, Calendar, Calc, HelpFile, {tv demo units}
  ViewText,                          {tvfm units}
  CBHelp, CBCmds, TVStr,             {cybertools units}
  CommDlgs, PXEdit;

const

  appViewDocBuf = 8192;       {buffer size for viewing doc file}
  appHelpInUse  = $8000;      {used by help system}
  appHelpName = 'CBHELP.HLP'; {help file name}
  appExeName  = 'CYBASE.EXE'; {name used to locate .exe for older dos}
  appDocName  = 'CYBER.DOC';  {doc file name}
  appCfgName = 'CYBASE.CFG';  {config file name}
  appCfgHeaderLen = 10;       {header used by config stream}
  appCfgHeader : string[appCfgHeaderLen] = 'CYBERBASE'#26;
  appTableCmds = [cmOpenTable,cmCreateTable,cmCreateIndex,cmDeleteIndex,
  cmAppendTable,cmCopyTable,cmRenameTable,cmDeleteTable,cmEmptyTable,
  cmUpgradeTable,cmEncryptTable,cmDecryptTable,cmAddPassword]; {engine commands}

  CAppStatusLine = #10#10#10#10; {new input line palette to map into app palette}
  CSysColor      = #$00#$00#$00; {app palette additions for tv system stuff}
  CSysPal        = #136#137#138;

type

  PAppStatusLine = ^TAppStatusLine;
  TAppStatusLine = object (TInputLine)
    function GetPalette: PPalette; virtual;
  end;

  TCyberBase = object(TApplication)
    AppOptions : word;
    appEnv : TEnv;
    appEngine : TEngine;
    appDatabase : TDatabase;
    appStatus : PAppStatusLine;
    Clock : PClockView;
    Heap : PHeapView;
    ClipWindow : PCyEditWindow;
    constructor Init;
    destructor Done; virtual;
    procedure UpdateStatus (S : string);
    function ErrorBox (ErrCode : integer) : boolean;
    procedure AboutBox;
    procedure Idle; virtual;
    procedure ClearDeskTop;
    function OpenEditor (FileName : FNameStr; Visible : Boolean) : PCyEditWindow;
    procedure AddPassword;
    procedure RestoreDesktop (F : PathStr);
    procedure SaveDeskTop (F : PathStr);
    procedure GetEvent (var Event : TEvent); virtual;
    function GetPalette : PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitDeskTop; virtual;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    procedure OutOfMemory; virtual;
    procedure LoadDesktop (var S : TStream);
    procedure StoreDesktop (var S : TStream);
  end;

{
Make input line look right when inserted into app.
}

function TAppStatusLine.GetPalette: PPalette;

const
  P: String[Length(CAppStatusLine)] = CAppStatusLine;

begin
  GetPalette := @P;
end;

{
Init app, engine and database.  If SHARE detection, engine or database
initilization fails then table related commands will be disabled.
}

constructor TCyberBase.Init;

var

  R : TRect;

begin
  MaxHeapSize := 12288; {192K app heap}
  LowMemSize := 4095;   {safety pool size}
  inherited Init;
  RegisterObjects;      {register stuff for stream access}
  RegisterViews;
  RegisterMenus;
  RegisterDialogs;
  RegisterApp;
  RegisterHelpFile;
  RegisterEditors;

  GetExtent (R);   {gadgets included with tvdemo}
  R.A.Y := R.B.Y-1;
  R.B.X := R.B.X-1;
  R.A.X := R.B.X-8;
  Heap := New (PHeapView,Init(R));
  Heap^.GrowMode := gfGrowAll;
  Insert (Heap);

  GetExtent (R);
  R.B.Y := R.A.Y+1;
  R.B.X := R.B.X-1;
  R.A.X := R.B.X-8;
  Clock := New (PClockView,Init (R));
  Insert (Clock);

  GetExtent (R); {floating status line}
  R.A.Y := R.B.Y-3;
  R.B.Y := R.A.Y+1;
  R.B.X := R.B.X-2;
  R.A.X := R.B.X-20;
  appStatus := New (PAppStatusLine,Init (R,30));
  appStatus^.Options := appStatus^.Options and not ofSelectable;
  appStatus^.GrowMode := gfGrowAll;
  appStatus^.SetState (sfShadow,true);
  Insert (appStatus);

  UpdateStatus ('Starting engine');
  RestoreDesktop (appCfgName);        {load config stream}
  if (appEnv.dosShare <> pxNoShare) and (not ShareInstalled) then
  begin {share not installed, but was requested by engine config}
    MessageBox ('SHARE.EXE not detected.  Exit and run SHARE.EXE or set DOS share to None in Options|Engine.',
    nil, mfError or mfOKButton);
    DisableCommands (appTableCmds)
  end;
  appEngine.Init (@appEnv);           {init engine}
  if ErrorBox (appEngine.lastError) then
    DisableCommands (appTableCmds)
  else                           {set 3.5 compatible or 4.0 create mode}
    ErrorBox (appEngine.setTblCreateMode (appEnv.tabCrtMode));
  appDatabase.Init (@appEngine);      {init database}
  if ErrorBox (appDataBase.lastError) then
    DisableCommands (appTableCmds);
  UpdateStatus ('');
  AboutBox;
  EditorDialog := StdEditorDialog;
  ClipWindow := OpenEditor ('', false); {create clip board}
  if ClipWindow <> nil then
  begin
    Clipboard := ClipWindow^.Editor;
    Clipboard^.CanUndo := false
  end
  else {unable to allocate clip board}
    DisableCommands ([cmShowClip]);
  DisableCommands ([cmSave, cmSaveAs, cmCut, cmCopy, cmPaste, cmClear,
  cmUndo, cmFind, cmReplace, cmSearchAgain, cmCloseAll])
end;

{
Close database and engine if open before calling inherited done.
}

destructor TCyberBase.Done;

begin
  UpdateStatus ('Ending engine');
  if appDataBase.isOpen then
    appDatabase.Done;
  if appEngine.isOpen then
    appEngine.Done;
  inherited Done
end;

{
Update status line.
}

procedure TCyberBase.UpdateStatus (S : string);

begin
  if S = '' then
  begin
    if appStatus^.State and sfVisible <> 0 then
      appStatus^.Hide
  end
  else
  begin
    if appStatus^.State and sfVisible = 0 then
      appStatus^.Show
  end;
  appStatus^.SetData (S)
end;

{
Display error and return true if error <> PXSUCCESS.  If error = PXSUCCESS
then no error is diaplayed and false is returned.
}

function TCyberBase.ErrorBox (ErrCode : integer) : boolean;

begin
  if ErrCode <> PxSuccess then
  begin
    MessageBox (appEngine.getErrorMessage (ErrCode)+'.',
    nil, mfError or mfOKButton);
    ErrorBox := true
  end
  else
    ErrorBox := false
end;

{
Tells what the app is about, run, network and share mode info.
}

procedure TCyberBase.AboutBox;

var

  S : string;


begin
  S := '';
  if appEnv.engineType <> pxLocal then
    S := S+', NETWORK';
  if appEnv.dosShare <> pxNoShare then
    S := S+', SHARE';
  HelpCtx := hcAbout;
  MessageBox(
    #3'Turbo Vision CyberTools 2.6'#13+
    #3'(C) 1994 Steve Goldsmith'#13+
{$IFDEF DPMI}
    #3'CyberBase DPMI'+S,
{$ELSE}
    #3'CyberBase REAL'+S,
{$ENDIF}
    nil, mfInformation or mfOKButton);
  HelpCtx := hcNoContext
end;

{
Update menu, status line and gadgets during idle processing.
}

procedure TCyberBase.Idle;

{return true if any view on desk top is tileable}

function IsTileable (P : PView) : boolean; far;

begin
  IsTileable := (P^.Options and ofTileable <> 0) and
  (P^.State and sfVisible <> 0)
end;

begin
  inherited Idle;
  Clock^.Update;                                       {update tvdemo gadgets}
  Heap^.Update;
  if Desktop^.Current <> nil then                      {see if anything is}
  begin                                                {on the desk top}
    EnableCommands ([cmCloseAll]);
    if Desktop^.FirstThat (@IsTileable) <> nil then    {see if any tileable}
      EnableCommands ([cmTile,cmCascade])              {windows are on the}
    else                                               {desk top}
      DisableCommands ([cmTile,cmCascade])
  end
  else
    DisableCommands ([cmCloseAll,cmTile,cmCascade]);
  if ((Desktop^.Current <> nil) and
  (Desktop^.Current^.State and sfModal = sfModal)) or
  (AppOptions and appHelpInUse = appHelpInUse) then    {see if modal dialog}
    DisableCommands ([cmQuit,cmOpenTable])             {is on the desk top}
  else
  begin                                                {no modal views}
    if appStatus^.Data^ <> '' then
      UpdateStatus ('');
    if appDataBase.isOpen then                         {enable open table}
      EnableCommands ([cmQuit,cmOpenTable])            {if database is valid}
    else
      EnableCommands ([cmQuit])
  end
end;

{
Close all windows on desk top.
}

procedure TCyberBase.ClearDeskTop;

procedure CloseDlg (P : PView); far;

begin
  Message (P,evCommand,cmClose,nil)
end;

begin
  UpdateStatus ('Clearing desk top');
  Desktop^.ForEach (@CloseDlg)
end;

{
Open text editor.
}

function TCyberBase.OpenEditor (FileName : FNameStr; Visible : Boolean) : PCyEditWindow;

var

  R : TRect;
  P : PWindow;

begin
  DeskTop^.GetExtent (R);
  P := New (PCyEditWindow, Init (R, FileName, wnNoNumber));
  P^.HelpCtx := hcTextEditor;
  if not Visible then
    P^.Hide;
  OpenEditor := PCyEditWindow (Application^.InsertWindow (P))
end;

{
Add master password to engine.
}

procedure TCyberBase.AddPassword;

var

  Password : string;

begin
  HelpCtx := hcPasswordDialog;
  Password := '';
  if InputBox ('','Password',Password,15) <> cmCancel then
    ErrorBox (appEngine.addPassword (Password));
  HelpCtx := hcNoContext
end;

{
Restore desk top stream.
}

procedure TCyberBase.RestoreDesktop (F : PathStr);

var

  S : PStream;
  Signature : string[appCfgHeaderLen];

begin
  S := New (PBufStream,Init (F,stOpenRead,1024));
  if LowMemory then OutOfMemory
  else
    if S^.Status <> stOk then
    begin
      MessageBox (#3'Unable to open file.',nil,mfOkButton+mfError)
    end
    else
    begin
      Signature[0] := Char (appCfgHeaderLen);
      S^.Read (Signature[1],appCfgHeaderLen);
      if Signature = appCfgHeader then {see if signature is right}
      begin
        S^.Read (appEnv,SizeOf (appEnv)); {read data from stream}
        LoadDesktop (S^);
        LoadIndexes (S^);
        ShadowAttr := GetColor (136);   {tv shadow color}
        SysColorAttr := (GetColor (137) shl 8) or GetColor (137); {tv system error color}
        ErrorAttr := GetColor (138);    {tv palette index error color}
        Application^.ReDraw; {draw app with new config}
        if S^.Status <> stOk then
          MessageBox (#3'Stream error.',nil,mfOkButton+mfError);
      end
      else
        MessageBox (#3'Invalid configuration format.',nil,mfOkButton+mfError)
    end;
  Dispose (S,Done)
end;

{
Save desk top stream.
}

procedure TCyberBase.SaveDesktop (F : PathStr);

var

  CfgFile : File;
  S : PStream;

begin
  S := New(PBufStream,Init (F,stCreate,1024));
  if not LowMemory and (S^.Status = stOk) then
  begin
    S^.Write (appCfgHeader[1],appCfgHeaderLen);
    S^.Write (appEnv,SizeOf (appEnv));
    StoreDesktop (S^);
    StoreIndexes (S^);
    if S^.Status <> stOk then
    begin {if stream error then delete file}
      MessageBox (#3'Could not create stream.',nil,mfOkButton+mfError);
      Dispose (S,Done);
      Assign (CfgFile,F);
      {$I-} Erase (CfgFile) {$I+};
      Exit
    end
  end;
  Dispose (S,Done)
end;

{
Intercept cmHelp to display help even when views are in modal state.
}

procedure TCyberBase.GetEvent (var Event : TEvent);

function CalcHelpName : PathStr;

var

  EXEName : PathStr;
  Dir : DirStr;
  Name : NameStr;
  Ext : ExtStr;

begin
  if Lo (DosVersion) >= 3 then
    EXEName := ParamStr (0)
  else
    EXEName := FSearch (appExeName, GetEnv ('PATH'));
  FSplit (EXEName, Dir, Name, Ext);
  if Dir[Length (Dir)] = '\' then
    Dec (Dir[0]);
  CalcHelpName := FSearch (appHelpName, Dir);
end;

var

  W : PWindow;
  HFile : PHelpFile;
  HelpStrm : PDosStream;

begin
  inherited GetEvent (Event);
  case Event.What of
    evCommand:
      if (Event.Command = cmHelp) and (AppOptions and appHelpInUse = 0) then
      begin {process help command if not in use}
        AppOptions := AppOptions or appHelpInUse; {help's in use}
        HelpStrm := New (PDosStream, Init (CalcHelpName, stOpenRead));
        HFile := New (PHelpFile, Init (HelpStrm));
        if HelpStrm^.Status <> stOk then
        begin
          MessageBox (#3'Could not open help file.', nil, mfError + mfOkButton);
          Dispose (HFile, Done);
        end
        else
        begin
          W := New (PHelpWindow,Init (HFile, GetHelpCtx));
          if ValidView (W) <> nil then
          begin
            DisableCommands ([cmHelp]);
            ExecView (W);
            Dispose (W, Done);
            EnableCommands ([cmHelp])
          end;
          ClearEvent (Event)
        end;
        AppOptions := AppOptions and not appHelpInUse
      end;
    evMouseDown:
      if Event.Buttons <> 1 then
        Event.What := evNothing
  end
end;

{
Get custom app palette.
}

function TCyberBase.GetPalette: PPalette;

const

  CNewColor = CAppColor+CHelpColor+CSysColor;
  CNewBlackWhite = CAppBlackWhite+CHelpBlackWhite+CSysColor;
  CNewMonochrome = CAppMonochrome+CHelpMonochrome+CSysColor;
  P: array[apColor..apMonochrome] of string[Length (CNewColor)] =
  (CNewColor, CNewBlackWhite, CNewMonochrome);

begin {add additional entries to the normal application palettes}
  GetPalette := @P[AppPalette];
end;

{
Handle app events.
}

procedure TCyberBase.HandleEvent(var Event: TEvent);

{
Configure and save engine setup.  Be careful when modifing engine values,
since incorrect values can crash the engine with a internal error!
}

procedure EngineConfig;

var

  D : PpxeEngineCfg;
  CfgRec : TpxeEngineCfgRec;

begin
  EngCfgToDlgCfg (appEnv,CfgRec);
  D := New (PpxeEngineCfg,Init);
  D^.HelpCtx := hcEngineDialog;
  if ExecuteDialog (D,@CfgRec) <> cmCancel then
  begin
    DlgCfgToEngCfg (CfgRec,appEnv);
    MessageBox(
    'Engine changes will not take effect until you save configuration as '+
    appCfgName+' and reload program.',
    nil, mfInformation or mfOKButton)
  end
end;

{
Tree window.
}
procedure TreeWindow (T : string; FMask : PathStr; ACmd : word; CCmd : boolean);

var

  W : PDirWindow;
  Drive : PathStr;

begin
  GetDir (0,Drive);
  W := New (PDirWindow,Init (T,Drive,FMask,ACmd,CCmd));
  W^.HelpCtx := hcTreeWindow;
  InsertWindow (W)
end;

{
Return focused file name from dir tree window.  If the extension param is not
null then that extension is used.
}

function TreeFileName (TW : PDirWindow; EStr : PathStr; ReadFlag : boolean) : PathStr;

var

  F : file;
  FName : PathStr;

begin
  FName := UpCaseStr (TW^.FocDirName+TW^.NameLine^.Data^);
  if (EStr <> '') and (FName[byte (FName[0])] <> '\') then {force extension}
    FName := AddExtStr (FName,EStr);
  if ReadFlag then
    TreeFileName := FName
  else
  begin
    Assign (F,FName);
    {$I-} Reset (F); {$I+}
    if IoResult = 0 then {see if file exists before writes}
    begin
      {$I-} Close (F); {$I+}
      if MessageBox (FName+' already exists.  Erase and continue?',
      nil,mfConfirmation or mfYesNoCancel) = cmYes then
        TreeFileName := FName
      else
        TreeFileName := ''
    end
    else
      TreeFileName := FName {doesn't exist, so return name}
  end
end;

{
New file list.
}

procedure NewFileList;

var

  D : PStrListDlg;

begin
  D := New (PStrListDlg,Init ('File List'));
  D^.HelpCtx := hcFileList;
  InsertWindow (D)
end;

{
Add file to file list.
}

procedure AddFileToList (TW : PDirWindow);

var

  I : integer;
  F : PathStr;
  D : PStrListDlg;

function IsStrList (V : PView) : boolean; far;

begin
  IsStrList :=  TypeOf (V^) = TypeOf (TStrListDlg)
end;

begin
  F := TreeFileName (TW,'',true);
  if F <> '' then
  begin
    D := PStrListDlg (Desktop^.FirstThat (@IsStrList));
    if D <> nil then
      with D^.StrBox^ do
      begin
        if (not LowMemory) and
        (not PStringCollection (List)^.Search (@F,I)) then
        begin
          List^.Insert (NewStr(F));       {add file name to list}
          SetRange (List^.Count);         {set list's range}
          FocusItem (List^.IndexOf (@F)); {focus inserted item}
          DrawView                        {draw box}
        end
      end
  end
end;

{
Return first file list in Z order.
}

function GetStrListDlg : PStrListDlg;

function IsStrList (V : PView) : boolean; far;

begin
  IsStrList :=  TypeOf (V^) = TypeOf (TStrListDlg)
end;

begin
  GetStrListDlg := PStrListDlg (Desktop^.FirstThat (@IsStrList))
end;

{
Find first file list in Z order and handle missing and empty lists by
returning nil.
}

function GetFileList : PStrListDlg;

var

  D : PStrListDlg;

begin
  D := GetStrListDlg;
  if D <> nil then
  begin
    if D^.StrBox^.List^.Count = 0 then
    begin
      MessageBox (#3'File list empty',nil,mfOkButton+mfError);
      D^.Focus;
      D := nil
    end
  end
  else
  begin
    MessageBox (#3'No file list found on desk top',nil,mfOkButton+mfError);
    NewFileList;
    D := nil
  end;
  GetFileList := D
end;

{
Load .CFG file.
}

procedure LoadConfigFile (TW : PDirWindow);

var

  F : PathStr;

begin
  F := TreeFileName (TW,'CFG',true);
  if F <> '' then
    RestoreDeskTop (F)
end;

{
Save .CFG file.
}

procedure SaveConfigFile (TW : PDirWindow);

var

  F : PathStr;

begin
  F := TreeFileName (TW,'CFG',false);
  if F <> '' then
    SaveDeskTop (F)
end;

{
Open new table editor window on selected index.  If no index or only a primary
exists then table is opened without prompting for key.  Handles encrypted
tables too.
}

procedure OpenTable (TW : PDirWindow);

var

  KeyCmd : word;
  FileName : PathStr;
  OpenFldNum : FieldNumber;
  GetError : Retcode;
  BrowseCur : PCursor;
  W : PpxeTableWin;
  K : PpxeKeyDialog;
  KData : TpxeKeyDlgRec;

begin
  FileName := TreeFileName (TW,'DB',true);
  if FileName <> '' then
  begin
    UpdateStatus ('Reading indexes');
    GetError := GetKeyFieldDesc (FileName,
    @appDataBase,KData.Fields.List);     {get field descs}
    KData.Fields.Selection := 0;
    if GetError = PXERR_INSUFRIGHTS then {handle password}
    begin
      AddPassword;
      GetError := GetKeyFieldDesc (FileName,
      @appDataBase,KData.Fields.List)    {get field descs}
    end;
    UpdateStatus ('');
    if not ErrorBox (GetError) then  {no errors, so proceed}
    begin
      if (KData.Fields.List <> nil) and
      (KData.Fields.List^.Count > 1) then
      begin {select key to open on}
        K := New (PpxeKeyDialog,Init (FileName));
        K^.HelpCtx := hcOpenIndexDialog;
        KeyCmd := ExecuteDialog (K,@KData);
        if KeyCmd <> cmCancel then
          OpenFldNum := PFieldDesc (KData.Fields.List^.At (
          KData.Fields.Selection))^.fldNum
      end
      else {no keys or only primary key}
      begin
        OpenFldNum := 0;
        KeyCmd := cmOk
      end;
      if KeyCmd <> cmCancel then
      begin
        UpdateStatus ('Opening table');
        BrowseCur := New (PCursor,
        InitAndOpen (@appDataBase,FileName,OpenFldNum,true));
        if not ErrorBox (BrowseCur^.lastError) then
        begin {create table editor}
          W := New (PpxeTableWin,Init (FileName,
          @appEngine,@appDataBase,BrowseCur,OpenFldNum));
          W^.HelpCtx := hcTableEditor;
          InsertWindow (W)
        end
        else {dispose cursor if error}
          Dispose (BrowseCur,Done)
      end
    end;
    if KData.Fields.List <> nil then
      Dispose (KData.Fields.List,Done)
  end
end;

{
Create table with password and error retry.  If appDataBase.createTable
returns an error you can retry with another table name, edit fields again or
abort.
}

procedure CreateTable (TW : PDirWindow);

var

  ExitCreate : boolean;
  FileName : PathStr;
  CreateData : TpxeCreateDlgRec;
  D : PpxeCreateDialog;

begin
  FillChar (CreateData,SizeOf (CreateData),0); {zero dialog rec}
  repeat
    UpdateStatus ('');
    ExitCreate := true;
    FileName := TreeFileName (TW,'DB',false);
    if FileName <> '' then
    begin
      if CreateData.Fields.List = nil then {create new list}
        CreateData.Fields.List := New (PCollection,Init (255,0));
      D := New (PpxeCreateDialog,Init (FileName,CreateData.Fields.List));
      D^.HelpCtx := hcCreateDialog;
      if ExecuteDialog (D,@CreateData) <> cmCancel then
      begin
        UpdateStatus ('Creating table');
        if appDataBase.createTable (FileName,
        CreateData.Fields.List) = PXERR_INSUFRIGHTS then
        begin {handle password}
          AddPassword;
          ErrorBox (appDataBase.createTable (FileName,
          CreateData.Fields.List))
        end
        else
          ErrorBox (appDataBase.lastError);
        if appDataBase.lastError <> PXSUCCESS then {error, try again?}
          if MessageBox ('Try again?',
          nil,mfConfirmation or mfYesNoCancel) = cmYes then
            ExitCreate := false
      end;
      if ExitCreate then {dispose list if exiting}
        Dispose (CreateData.Fields.List,Done)
    end
  until ExitCreate
end;

{
Create primary, single/multi field secondary and/or case-insensitive index.
}

procedure CreateIndex (TW : PDirWindow);

var

  I, FldCnt : integer;
  FileName : PathStr;
  GetError : Retcode;
  FldHan : FieldHandle;
  FldHanArr : FieldNumberArray;
  IData : TpxeIndexDlgRec;
  D : PpxeIndexDialog;

begin
  FillChar (IData,SizeOf (IData),0); {zero dialog rec}
  FileName := TreeFileName (TW,'DB',true);
  if FileName <> '' then
  begin
    IData.Fields.List := nil;        {start with nil lists}
    IData.Key.List := nil;
    GetError := GetFieldDesc (FileName,  {get field descs}
    @appDataBase,IData.Fields.List);
    if GetError = PXERR_INSUFRIGHTS then {handle password}
    begin
      AddPassword;
      GetError := GetFieldDesc (FileName,
      @appDataBase,IData.Fields.List)
    end;
    if not ErrorBox (GetError) then  {no errors, so proceed}
    begin
      FldCnt := IData.Fields.List^.Count;  {field count}
      D := New (PpxeIndexDialog,Init (FileName));
      IData.Key.List := New (PCollection,Init (FldCnt,0));
      D^.FieldPtr := IData.Fields.List; {let dialog know where list is}
      D^.HelpCtx := hcCreateIndexDialog;
      if ExecuteDialog (D,@IData) <> cmCancel then
      begin
        UpdateStatus ('Indexing table');
        if IData.Key.List^.Count > 0 then {any fields selected?}
        begin
          if PXKeyCrtMode (IData.Index) = pxPrimary then
          begin {use field number as field count of primary key}
            ErrorBox (appDataBase.createPIndex (FileName,
            PFieldDesc (IData.Key.List^.At (0))^.fldNum))
          end
          else {single field case-sensitive secondary index}
            if (IData.Key.List^.Count = 1) and (IData.CaseSens = 0) then
            begin
              ErrorBox (appDataBase.createSIndex (FileName,
              PFieldDesc (IData.Key.List^.At (0))^.fldNum,PXKeyCrtMode (IData.Index)))
            end
            else {multi-field and/or case-sensitive/insensitive secondary index}
            begin
              FldCnt := IData.Key.List^.Count; {total fields}
              for I := 1 to FldCnt do {load field numbers into handle array}
                FldHanArr[I] := PFieldDesc (IData.Key.List^.At (I-1))^.fldNum;
              if not ErrorBox (appDataBase.defineCompoundKey (
              FileName,FldCnt,FldHanArr,IData.FldName,
              IData.CaseSens = 0,FldHan)) then {make index}
                ErrorBox (appDataBase.createSIndex (FileName,
                FldHan,PXKeyCrtMode (IData.Index)))
            end
        end
        else {no fields selected to make index}
          MessageBox (#3'No fields selected.',nil,mfOkButton+mfError)
      end
    end;
    if IData.Fields.List <> nil then {dispose lists}
      Dispose (IData.Fields.List,Done);
    if IData.Key.List <> nil then
      Dispose (IData.Key.List,Done)
  end
end;

{
Delete primary, single/multi field secondary or case-insensitive index.
}

procedure DeleteIndex (TW : PDirWindow);

var

  FileName : PathStr;
  GetError : Retcode;
  K : PpxeKeyDialog;
  KData : TpxeKeyDlgRec;

begin
  FileName := TreeFileName (TW,'DB',true);
  if FileName <> '' then
  begin
    UpdateStatus ('Reading indexes');
    GetError := GetKeyFieldDesc (FileName,
    @appDataBase,KData.Fields.List);     {get key fields}
    KData.Fields.Selection := 0;
    if GetError = PXERR_INSUFRIGHTS then {handle password}
    begin
      AddPassword;
      GetError := GetKeyFieldDesc (FileName,
      @appDataBase,KData.Fields.List) {get field descs}
    end;
    UpdateStatus ('');
    if not ErrorBox (GetError) then  {no errors, so proceed}
    begin
      if KData.Fields.List <> nil then
      begin {select key to delete}
        K := New (PpxeKeyDialog,Init (FileName));
        K^.HelpCtx := hcDeleteIndexDialog;
        if ExecuteDialog (K,@KData) <> cmCancel then
        begin
          UpdateStatus ('Deleting index');
          ErrorBox (appDataBase.dropIndex (FileName,
          PFieldDesc (KData.Fields.List^.At (
          KData.Fields.Selection))^.fldNum))
        end
      end
      else
        MessageBox (FileName+' has no keys to delete.',nil,mfOkButton+mfError)
    end;
    if KData.Fields.List <> nil then
      Dispose (KData.Fields.List,Done)
  end
end;

{
Append table with password retry.
}

procedure AppendTable (TW : PDirWindow);

var

  SFileName,
  DFileName : PathStr;
  D : PStrListDlg;

begin
  D := GetFileList;
  if D <> nil then
  begin
    SFileName := PString (D^.StrBox^.List^.At (0))^;
    DFileName := TreeFileName (TW,'DB',true);
    UpdateStatus ('Appending table');
    if appDataBase.appendTable (SFileName,DFileName) = PXERR_INSUFRIGHTS then
    begin
      AddPassword;
      ErrorBox (appDataBase.appendTable (SFileName,DFileName))
    end
    else
      ErrorBox (appDataBase.lastError)
  end
end;

{
Copy table with password retry.
}

procedure CopyTable (TW : PDirWindow);

var

  SFileName,
  DFileName : PathStr;
  D : PStrListDlg;

begin
  D := GetFileList;
  if D <> nil then
  begin
    SFileName := PString (D^.StrBox^.List^.At (0))^; {source comes from file list}
    DFileName := TreeFileName (TW,'DB',false);       {dest comes from file browser}
    UpdateStatus ('Coping table');
    if appDataBase.copyTable (SFileName,DFileName) = PXERR_INSUFRIGHTS then
    begin
      AddPassword;
      ErrorBox (appDataBase.copyTable (SFileName,DFileName))
    end
    else
      ErrorBox (appDataBase.lastError)
  end
end;

{
Rename table with password retry.
}

procedure RenameTable (TW : PDirWindow);

var

  SFileName,
  DFileName : PathStr;
  D : PStrListDlg;

begin
  D := GetFileList;
  if D <> nil then
  begin
    SFileName := PString (D^.StrBox^.List^.At (0))^;
    DFileName := TreeFileName (TW,'DB',true);
    UpdateStatus ('Renaming table');
    if appDataBase.renameTable (SFileName,DFileName) = PXERR_INSUFRIGHTS then
    begin
      AddPassword;
      ErrorBox (appDataBase.renameTable (SFileName,DFileName))
    end
    else
      ErrorBox (appDataBase.lastError)
  end
end;

{
Delete table with password retry.
}

procedure DeleteTable (TW : PDirWindow);

var

  FileName : PathStr;

begin
  FileName := TreeFileName (TW,'DB',true);
  if FileName <> '' then
  begin
    UpdateStatus ('Deleting table');
    if appDataBase.deleteTable (FileName) = PXERR_INSUFRIGHTS then
    begin
      AddPassword;
      ErrorBox (appDataBase.deleteTable (FileName))
    end
    else
      ErrorBox (appDataBase.lastError)
  end
end;

{
Upgrade table with password retry.
}

procedure UpgradeTable (TW : PDirWindow);

var

  FileName : PathStr;

begin
  FileName := TreeFileName (TW,'DB',true);
  if FileName <> '' then
  begin
    UpdateStatus ('Upgrading table');
    if appDataBase.upgradeTable (FileName) = PXERR_INSUFRIGHTS then
    begin
      AddPassword;
      ErrorBox (appDataBase.upgradeTable (FileName))
    end
    else
      ErrorBox (appDataBase.lastError)
  end
end;

{
Empty table with password retry.
}

procedure EmptyTable (TW : PDirWindow);

var

  FileName : PathStr;

begin
  FileName := TreeFileName (TW,'DB',true);
  if FileName <> '' then
  begin
    UpdateStatus ('Empty table');
    if appDataBase.emptyTable (FileName) = PXERR_INSUFRIGHTS then
    begin
      AddPassword;
      ErrorBox (appDataBase.emptyTable (FileName))
    end
    else
      ErrorBox (appDataBase.lastError)
  end
end;

{
Encrypt table with password retry.
}

procedure EncryptTable (TW : PDirWindow);

var

  FileName : PathStr;
  Password : string;

begin
  FileName := TreeFileName (TW,'DB',true);
  if FileName <> '' then
  begin
    Password := '';
    if InputBox ('Encrypt','Password',Password,15) <> cmCancel then
    begin
      UpdateStatus ('Encrypting table');
      if appDataBase.encryptTable (FileName,Password) = PXERR_INSUFRIGHTS then
      begin
        AddPassword;
        ErrorBox (appDataBase.encryptTable (FileName,Password))
      end
      else
        ErrorBox (appDataBase.lastError)
    end
  end
end;

{
Decrypt table with password retry.  Password must be in effect for decrypt to
work.
}

procedure DecryptTable (TW : PDirWindow);

var

  FileName : PathStr;

begin
  FileName := TreeFileName (TW,'DB',true);
  if FileName <> '' then
  begin
    UpdateStatus ('Decrypting table');
    if appDataBase.decryptTable (FileName) = PXERR_INSUFRIGHTS then
    begin
      AddPassword;
      ErrorBox (appDataBase.decryptTable (FileName))
    end
    else
      ErrorBox (appDataBase.lastError)
  end
end;

{
Switch between 25 and 43/50 line mode and refresh editors.  The table editor
buffers have been optimized to use only what is needed to view a maximumized
window.
}

procedure ToggleVideo;

var

  NewMode : word;
  R : TRect;

begin
  NewMode := ScreenMode xor smFont8x8;
  if NewMode and smFont8x8 <> 0 then
    ShadowSize.X := 1
  else
    ShadowSize.X := 2;
  SetScreenMode (NewMode);
  Desktop^.GetExtent (R);
  UpdateStatus ('Refresh editor');
  Message (DeskTop,evBroadcast,cmVideoChange,@Self) {refreash all editors}
end;

{
TV Demo calendar.
}

procedure Calendar;

var

  P : PCalendarWindow;

begin
  P := New (PCalendarWindow, Init);
  P^.Palette := dpGrayDialog;
  P^.HelpCtx := hcCalendar;
  InsertWindow (P)
end;

{
TV Demo calculator.
}

procedure Calculator;

var

  P : PCalculator;
begin
  P := New (PCalculator, Init);
  P^.HelpCtx := hcCalculator;
  InsertWindow (P)
end;

{
View doc file.
}

procedure ViewTextFile (FileName : PathStr);

var

  T : PTextWindow;
  R : TRect;

begin
  GetExtent (R);
  R.Grow (-5,-4);
  T := New(PTextWindow, Init(R, FileName));
  T^.Options := T^.Options or ofCentered;
  T^.HelpCtx := hcViewDoc;
  InsertWindow (T)
end;

{
Return focused editor window or nil if none focused.
}

function GetEditor (FocFlag : boolean) : PCyEditWindow;

var

  FE : PCyEditWindow;

function IsFocused (V : PView) : boolean; far;

begin
  if FocFlag then
    IsFocused := (TypeOf (V^) = TypeOf (TCyEditWindow)) and
    (PCyEditWindow (V)^.State and sfFocused <> 0)
  else
    IsFocused := (TypeOf (V^) = TypeOf (TCyEditWindow))
end;

begin
  FE := PCyEditWindow (Desktop^.FirstThat (@IsFocused));
  if FE = nil then
    MessageBox ('No editor windows focused on desk top.',nil,mfOkButton+mfError);
  GetEditor := FE
end;

{
Open new text editor.
}

procedure FileNew;


begin
  OpenEditor ('', True)
end;

{
Open text file.
}

procedure FileOpen (TW : PDirWindow);

var

  F : PathStr;

begin
  F := TreeFileName (TW,'',true);
  if F <> '' then
    OpenEditor(F,true)
end;

{
Save as text file.
}

procedure SaveFileAs (TW : PDirWindow);

var

  F : PathStr;
  E : PCyEditWindow;

begin
  F := TreeFileName (TW,'',false);
  if F <> '' then
  begin
    E := GetEditor (false); {get first editor in z order}
    if E <> nil then
    begin
      E^.Editor^.FileName := F;
      Message (E^.Owner, evBroadcast, cmUpdateTitle, nil);
      E^.Editor^.SaveFile;
      if E^.Editor = @Clipboard then
        E^.Editor^.FileName := ''
    end
  end
end;

{
Make clip window visible.
}

procedure ShowClip;

begin
  if ClipWindow <> nil then
  begin
    ClipWindow^.Select;
    ClipWindow^.Show
  end
end;

{
Set custom TV color palette.
}

procedure Colors;

{custom color items}
function DlgColorItems (Palette: Word; const Next: PColorItem) : PColorItem;

const

  COffset : array[dpBlueDialog..dpGrayDialog] of Byte = (64, 96, 32);

var

  Offset : Byte;

begin
  Offset := COffset[Palette];
  DlgColorItems :=
    ColorItem ('Frame passive',     Offset,
    ColorItem ('Frame active',      Offset + 1,
    ColorItem ('Frame icons',       Offset + 2,
    ColorItem ('Scroll bar page',   Offset + 3,
    ColorItem ('Scroll bar icons',  Offset + 4,
    ColorItem ('Static text',       Offset + 5,

    ColorItem ('Label normal',      Offset + 6,
    ColorItem ('Label selected',    Offset + 7,
    ColorItem ('Label shortcut',    Offset + 8,

    ColorItem ('Button normal',     Offset + 9,
    ColorItem ('Button default',    Offset + 10,
    ColorItem ('Button selected',   Offset + 11,
    ColorItem ('Button disabled',   Offset + 12,
    ColorItem ('Button shortcut',   Offset + 13,
    ColorItem ('Button shadow',     Offset + 14,

    ColorItem ('Cluster normal',    Offset + 15,
    ColorItem ('Cluster selected',  Offset + 16,
    ColorItem ('Cluster shortcut',  Offset + 17,

    ColorItem ('Input normal',      Offset + 18,
    ColorItem ('Input selected',    Offset + 19,
    ColorItem ('Input arrow',       Offset + 20,

    ColorItem ('History button',    Offset + 21,
    ColorItem ('History sides',     Offset + 22,
    ColorItem ('History bar page',  Offset + 23,
    ColorItem ('History bar icons', Offset + 24,

    ColorItem ('List normal',       Offset + 25,
    ColorItem ('List focused',      Offset + 26,
    ColorItem ('List selected',     Offset + 27,
    ColorItem ('List divider',      Offset + 28,

    ColorItem('Information pane',  Offset + 29,
    Next))))))))))))))))))))))))))))));
end;

function HelpColorItems(const Next: PColorItem): PColorItem;

begin
  HelpColorItems :=
    ColorItem ('Frame passive',     128,
    ColorItem ('Frame active',      129,
    ColorItem ('Frame icons',       130,
    ColorItem ('Scroll bar page',   131,
    ColorItem ('Scroll bar icons',  132,
    ColorItem ('Normal text',       133,
    ColorItem ('Key word',          134,
    ColorItem ('Select key word',   135,
    Next))))))))
end;

function SysColorItems (const Next: PColorItem) : PColorItem;

begin
  SysColorItems :=
    ColorItem ('Shadow',       136,
    ColorItem ('System error', 137,
    ColorItem ('Index error',  138,
    Next)))
end;

var

  D : PColorDialog;

begin
  D := New (PColorDialog,Init ('',
  ColorGroup ('Desktop',     DesktopColorItems(nil),
  ColorGroup ('Menus',       MenuColorItems(nil),
  ColorGroup ('Gray Windows',WindowColorItems(wpGrayWindow,nil),
  ColorGroup ('Blue Windows',WindowColorItems(wpBlueWindow,nil),
  ColorGroup ('Cyan Windows',WindowColorItems(wpCyanWindow,nil),
  ColorGroup ('Gray Dialogs',DlgColorItems(dpGrayDialog,nil),
  ColorGroup ('Blue Dialogs',DlgColorItems(dpBlueDialog,nil),
  ColorGroup ('Cyan Dialogs',DlgColorItems(dpCyanDialog,nil),
  ColorGroup ('Help',        HelpColorItems(nil),
  ColorGroup ('System',      SysColorItems(nil),
  nil))))))))))));
  D^.HelpCtx := hcColorDialog;
  if ExecuteDialog (D,Application^.GetPalette) <> cmCancel then
  begin
    DoneMemory; {dispose all group buffers}
    ReDraw;     {redraw application with new palette}
    ShadowAttr := GetColor (136);   {tv shadow color}
    SysColorAttr := (GetColor (137) shl 8) or GetColor (137); {tv system error color}
    ErrorAttr := GetColor (138);    {tv palette index error color}
  end
end;

{
Force all oftileable windows to top and use Focus to cause call to
PView^.Valid and validate.
}

procedure TileableOnTop (P : PView); far;

begin
  if (P^.Options and ofTileable = ofTileable) then
    P^.Focus
end;

begin
  if Event.What = evCommand then {we need to see these before inherited call}
    case Event.Command of
      cmSaveAs  :
      begin
        TreeWindow ('Save As','*.TXT',cmSaveAs,true);
        ClearEvent (Event)
      end;
      cmCascade :
      begin
        UpdateStatus ('Cascading windows');
        Desktop^.ForEach (@TileableOnTop)
      end;
      cmTile :
      begin
        UpdateStatus ('Tiling windows');
        Desktop^.ForEach (@TileableOnTop)
      end;
      cmQuit :
      begin
        ClearDeskTop;                   {empty entire desk top}
        if DeskTop^.Current <> nil then {make sure nothing failed to close}
          ClearEvent (Event)
      end
    end;
  inherited HandleEvent (Event);
  case Event.What of
    evCommand:
    begin
      case Event.Command of             {process commands}
        cmOpenTable    : TreeWindow ('Open Table','*.DB',cmOpenTable,true);
        cmCreateTable  : TreeWindow ('Create Table','*.DB',cmCreateTable,true);
        cmCreateIndex  : TreeWindow ('Create Index','*.DB',cmCreateIndex,true);
        cmDeleteIndex  : TreeWindow ('Delete Index','*.DB',cmDeleteIndex,true);
        cmAppendTable  : TreeWindow ('Append Table To','*.DB',cmAppendTable,true);
        cmCopyTable    : TreeWindow ('Copy Table To','*.DB',cmCopyTable,true);
        cmRenameTable  : TreeWindow ('Rename Table To','*.DB',cmRenameTable,true);
        cmEmptyTable   : TreeWindow ('Empty Table','*.DB',cmEmptyTable,true);
        cmDeleteTable  : TreeWindow ('Delete Table','*.DB',cmDeleteTable,true);
        cmEncryptTable : TreeWindow ('Encrypt Table','*.DB',cmEncryptTable,true);
        cmDecryptTable : TreeWindow ('Decrypt Table','*.DB',cmDecryptTable,true);
        cmUpgradeTable : TreeWindow ('Upgrade Table','*.DB',cmUpgradeTable,true);
        cmSaveConfig   : TreeWindow ('Save Config Stream','*.CFG',cmSaveConfig,true);
        cmLoadConfig   : TreeWindow ('Load Config Stream','*.CFG',cmLoadConfig,true);
        cmFileBrowse   : TreeWindow ('File List Builder','*.DB',cmAddFile,true);
        cmOpen         : TreeWindow ('Open Text File','*.*',cmOpen,true);
        cmNew          : FileNew;
        cmShowClip     : ShowClip;
        cmNewFileList  : NewFileList;
        cmAddPassword  : AddPassword;
        cmEngineConfig : EngineConfig;
        cmVideoToggle  : ToggleVideo;
        cmViewDoc      : ViewTextFile (appDocName);
        cmCalendar     : Calendar;
        cmCalculator   : Calculator;
        cmAbout        : AboutBox;
        cmCloseAll     : ClearDeskTop;
        cmColors       : Colors
      else
        Exit
      end;
      ClearEvent (Event)
    end;
    evBroadcast :
    begin
      case Event.Command of {process broadcasts}
        cmOpenTable    : OpenTable (PDirWindow (Event.InfoPtr));
        cmCreateTable  : CreateTable (PDirWindow (Event.InfoPtr));
        cmCreateIndex  : CreateIndex (PDirWindow (Event.InfoPtr));
        cmDeleteIndex  : DeleteIndex (PDirWindow (Event.InfoPtr));
        cmAppendTable  : AppendTable (PDirWindow (Event.InfoPtr));
        cmCopyTable    : CopyTable (PDirWindow (Event.InfoPtr));
        cmRenameTable  : RenameTable (PDirWindow (Event.InfoPtr));
        cmEmptyTable   : EmptyTable (PDirWindow (Event.InfoPtr));
        cmDeleteTable  : DeleteTable (PDirWindow (Event.InfoPtr));
        cmEncryptTable : EncryptTable (PDirWindow (Event.InfoPtr));
        cmDecryptTable : DecryptTable (PDirWindow (Event.InfoPtr));
        cmUpgradeTable : UpgradeTable (PDirWindow (Event.InfoPtr));
        cmSaveConfig   : SaveConfigFile (PDirWindow (Event.InfoPtr));
        cmLoadConfig   : LoadConfigFile (PDirWindow (Event.InfoPtr));
        cmAddFile      : AddFileToList (PDirWindow (Event.InfoPtr));
        cmOpen         : FileOpen (PDirWindow (Event.InfoPtr));
        cmSaveAs       : SaveFileAs (PDirWindow (Event.InfoPtr))
      end
    end
  end
end;

{
Assign desk top pattern char.
}

procedure TCyberBase.InitDeskTop;

begin
  inherited InitDeskTop;
  DeskTop^.Background^.Pattern := '±' {new wall paper}
end;

procedure TCyberBase.InitMenuBar;

var

  R : TRect;

begin
  GetExtent (R);
  R.B.Y := R.A.Y+1;
  MenuBar := New (PMenuBar,Init (R,NewMenu (
    NewSubMenu ('~F~ile',hcFile,NewMenu (
      NewSubMenu ('~T~able',hcTable,NewMenu (
        NewItem ('~N~ew...','F4',kbF4,cmCreateTable,hcNew,
        NewItem ('~O~pen...','F3',kbF3,cmOpenTable,hcOpen,
        NewItem ('~A~ppend...','',kbNoKey,cmAppendTable,hcAppend,
        NewItem ('~C~opy...','',kbNoKey,cmCopyTable,hcCopyTable,
        NewItem ('~R~ename...','',kbNoKey,cmRenameTable,hcRename,
        NewItem ('~E~mpty...','',kbNoKey,cmEmptyTable,hcEmpty,
        NewItem ('~D~elete...','',kbNoKey,cmDeleteTable,hcDelete,
        NewItem ('~U~pgrade...','',kbNoKey,cmUpgradeTable,hcUpgrade,
        nil))))))))),
      NewSubMenu ('~I~ndex',hcIndex,NewMenu (
        NewItem ('~N~ew...','',kbNoKey,cmCreateIndex,hcNewIndex,
        NewItem ('~D~elete...','',kbNoKey,cmDeleteIndex,hcDeleteIndex,
        nil))),
      NewSubMenu ('~A~SCII',hcASCII,NewMenu (
        NewItem ('~N~ew', '', kbNoKey, cmNew, hcNewText,
        NewItem ('~O~pen...', '', kbNoKey, cmOpen, hcOpenText,
        NewItem ('~S~ave', '', kbNoKey, cmSave, hcSaveText,
        NewItem ('Sa~v~e as...', '', kbNoKey, cmSaveAs, hcSaveAsText,
        NewItem ('Save a~l~l', '', kbNoKey, cmSaveAll, hcSaveAllText,
        nil)))))),
      NewSubMenu ('~S~ecurity',hcSecurity,NewMenu (
        NewItem ('~A~dd password...','',kbNoKey,cmAddPassword,hcAddPassword,
        NewItem ('~E~ncrypt...','',kbNoKey,cmEncryptTable,hcEncrypt,
        NewItem ('~D~ecrypt...','',kbNoKey,cmDecryptTable,hcDecrypt,
        nil)))),
      NewSubMenu ('~L~ist',hcList,NewMenu (
        NewItem ('~N~ew','',kbNoKey,cmNewFileList,hcNewFileList,
        NewItem ('~B~uilder...','',kbNoKey,cmFileBrowse,hcFileListBuild,
        nil))),
      NewSubMenu ('~C~onfig',hcConfig,NewMenu (
        NewItem ('~L~oad...','Ctrl+F3',kbCtrlF3,cmLoadConfig,hcLoadFile,
        NewItem ('~S~ave...','Ctrl+F2',kbCtrlF2,cmSaveConfig,hcSaveFile,
        nil))),
      NewLine (
      NewItem ('A~b~out','',kbNoKey,cmAbout,hcAbout,
      NewLine (
      NewItem ('E~x~it','Alt+X',kbAltX,cmQuit,hcExit,
      nil))))))))))),
    NewSubMenu('~E~dit', hcEdit, NewMenu(
      StdEditMenuItems(
      NewLine(
      NewItem('~S~how clipboard', '', kbNoKey, cmShowClip, hcShowClip,
      nil)))),
    NewSubMenu('~S~earch', hcSearch, NewMenu(
      NewItem('~F~ind...', '', kbNoKey, cmFind, hcFind,
      NewItem('~R~eplace...', '', kbNoKey, cmReplace, hcReplace,
      NewItem('~S~earch again', '', kbNoKey, cmSearchAgain, hcSearchAgain,
      nil)))),
    NewSubMenu ('~T~ools',hcTools,NewMenu (
      NewItem ('~C~alendar','',kbNoKey,cmCalendar,hcSCalendar,
      NewItem ('Ca~l~culator','',kbNoKey,cmCalculator,hcSCalculator,
      NewItem ('~V~iew doc','',kbNoKey,cmViewDoc,hcViewDoc,
      nil)))),
    NewSubMenu ('~O~ptions',hcOptions,NewMenu (
      NewItem ('~E~ngine...','',kbNoKey,cmEngineConfig,hcEngine,
      NewItem ('~C~olors...','',kbNoKey,cmColors,hcOColors,
      NewItem ('~V~ideo toggle','',kbNoKey,cmVideoToggle,hcVideoToggle,
      nil)))),
    NewSubMenu ('~W~indow',hcWindows,NewMenu(
      StdWindowMenuItems (
      nil)),nil)))))))))
end;

procedure TCyberBase.InitStatusLine;

var

  R : TRect;

begin
  GetExtent (R);
  R.A.Y := R.B.Y-1;
  StatusLine := New (PStatusLine,Init(R,
    NewStatusDef (0,$FFFF,
      NewStatusKey ('~F1~ Help', kbF1, cmHelp,
      NewStatusKey ('~F3~ Open',kbF3,cmOpenTable,
      NewStatusKey ('~Alt+F3~ Close',kbAltF3,cmClose,
      NewStatusKey ('~Alt+X~ Exit',kbAltX,cmQuit,
      NewStatusKey ('',kbCtrlF2,cmSaveConfig,
      NewStatusKey ('',kbCtrlF3,cmLoadConfig,
      NewStatusKey ('',kbF4,cmCreateTable,
      NewStatusKey ('',kbCtrlF5,cmResize,
      NewStatusKey ('',kbF10,cmMenu,
      nil))))))))),nil)))
end;

{
Let user know if heap allocation cuts into the safety pool.
}

procedure TCyberBase.OutOfMemory;

begin
  MessageBox ('Not enough memory available to complete operation.  Try closing some windows!',
  nil,mfError+mfOkButton)
end;

{
Load desk top from stream.
}

procedure TCyberBase.LoadDesktop (var S : TStream);

var

  Pal : PString;

begin
  Pal := S.ReadStr;
  if Pal <> nil then
  begin
    Application^.GetPalette^ := Pal^;
    DoneMemory;
    DisposeStr (Pal)
  end
end;

{
Store desk top on stream.
}

procedure TCyberBase.StoreDesktop(var S: TStream);

var

  Pal: PString;

begin
  Pal := @Application^.GetPalette^;
  S.WriteStr (Pal)
end;

var

  CBApp : TCyberBase;

begin
  CBApp.Init;
  SysErrorFunc := AppSystemError;
  CBApp.Run;
  CBApp.Done
end.
