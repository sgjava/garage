{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

CyberTerm is a powerful multi-session ANSI terminal application using Async
Professional 2.01 from Turbo Power.  CyberScript compiler included with
complete IDE support built into app.

Borland Pascal 7.x or Turbo Pascal 7.x, Turbo Vision 2.x and Async
Professional 2.x from Turbo Power are required to compile.

Set IDE directories to

\BP\UNITS;
\BP\EXAMPLES\DOS\TVDEMO;
\BP\EXAMPLES\DOS\TVFM;
\BP\APRO;

I used \BP\APRO when I installed Async Pro 2.01.  The rest of the path names
use BP 7.x defaults.  If you changed any of these then use the correct paths
in Options|Directories...  APDEFINE.INC in Async Pro was in its default state.
See APP.INC for global compiler switches.
}

{$I APP.INC}
{$X+}

program CyberTerm;

uses

  Dos,                           {system units}
  Memory, Drivers, Objects,      {tv units}
  Views, Menus, Dialogs, Editors,
  App, MsgBox, StdDlg, ColorSel,
  Gadgets, HelpFile,             {tv demo units}
  ViewText,                      {tvfm units}
  ApMisc, OoAbsPcl,              {async pro units}
  TermDlgs, CommDlgs, TVStr,     {cybertools units}
  CTHelp, CTCmds;


type

  TCyberTerm = object(TApplication)
    AppOptions : word;
    PhoneData : TTermConfigDlgRec;
    GenData : TTermGenDlgRec;
    GenOpts : TTermGenOptsRec;
    Clock : PClockView;
    Heap : PHeapView;
    ClipWindow : PCyEditWindow;
    constructor Init;
    function ErrorBox : boolean;
    procedure AboutBox;
    procedure Idle; virtual;
    procedure ClearDeskTop;
    procedure LogWindow;
    function OpenEditor (FileName : FNameStr; Visible : Boolean) : PCyEditWindow;
    procedure RestoreDesktop (F : PathStr);
    procedure SaveDeskTop (F : PathStr);
    procedure GetEvent (var Event : TEvent); virtual;
    function GetPalette : PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    procedure OutOfMemory; virtual;
    procedure LoadDesktop (var S : TStream);
    procedure StoreDesktop (var S : TStream);
  end;

const

  appViewDocBuf = 8192;       {buffer size for viewing doc file}
  appLogWinBuf  = 16384;      {buffer size for log window}
  appHelpInUse  = $8000;      {used by help system}
  appHelpName = 'CTHELP.HLP'; {help file name}
  appDocName  = 'CYBER.DOC';  {doc file name}
  appCfgName = 'CYTERM.CFG';  {config file name}
  appExeName  = 'CYTERM.EXE'; {name used to locate .exe for older dos}
  appCfgHeaderLen = 10;       {header used by config stream}
  appCfgHeader : string[appCfgHeaderLen] = 'CYBERTERM'#26;

  CSysColor = #$00#$00#$00;   {app palette additions for tv system stuff}
  CSysPal   = #136#137#138;

constructor TCyberTerm.Init;

var

  R : TRect;

begin
  MaxHeapSize := 12288; {192K app heap}
  LowMemSize := 2048;   {32K  safety pool}
  inherited Init;
  RegisterObjects;     {register stuff for stream access}
  RegisterViews;
  RegisterMenus;
  RegisterDialogs;
  RegisterApp;
  RegisterHelpFile;
  RegisterEditors;
  RegisterTerm;         {register term objects}

  GetExtent (R);        {gadgets included with tvdemo}
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

  RestoreDeskTop (appCfgName);
  AboutBox;
  LogWindow;

  EditorDialog := StdEditorDialog;
  ClipWindow := OpenEditor ('', False); {create clip board}
  if ClipWindow <> nil then
  begin
    Clipboard := ClipWindow^.Editor;
    Clipboard^.CanUndo := false
  end;
  DisableCommands ([cmSave, cmSaveAs, cmCut, cmCopy, cmPaste, cmClear,
  cmUndo, cmFind, cmReplace, cmSearchAgain, cmCloseAll,cmAbortScript,
  cmHangUp,cmEchoToggle,cmAbortXfer,cmCapture]);
end;

{
Display and return true if async error else return false.
}

function TCyberTerm.ErrorBox : boolean;

begin
  if GetAsyncStatus = ecOk then
    ErrorBox := false
  else
  begin
    MessageBox (#3+StatusStr (GetAsyncStatus),nil,mfOkButton+mfError);
    ErrorBox := true
  end
end;

{
Show program name, version, (C) and mode.
}

procedure TCyberTerm.AboutBox;

begin
  HelpCtx := hcAbout;
  MessageBox(
    #3'Turbo Vision CyberTools 2.6'#13+
    #3'(C) 1994 Steve Goldsmith'#13+
{$IFDEF DPMI}
    #3'CyberTerm DPMI',
{$ELSE}
    #3'CyberTerm REAL',
{$ENDIF}
    nil, mfInformation or mfOKButton);
  HelpCtx := hcNoContext
end;

{
Update commands, gadgets and terminal windows during idle processing.
}

procedure TCyberTerm.Idle;

function IsTileable (P : PView) : boolean; far;

begin
  IsTileable := (P^.Options and ofTileable <> 0) and
  (P^.State and sfVisible <> 0)
end;

begin
  inherited Idle;
  Clock^.Update;                               {update tvdemo gadgets}
  Heap^.Update;
  if Desktop^.Current <> nil then              {see if anything is}
  begin                                        {on the desk top}
    EnableCommands ([cmCloseAll]);
    if Desktop^.FirstThat (@IsTileable) <> nil then {see if any tileable}
      EnableCommands ([cmTile,cmCascade])           {windows are on the}
    else                                            {desk top}
      DisableCommands ([cmTile,cmCascade]);
    Message (Desktop,evBroadcast,cmTermIdle,@Self)  {do all terms idle tasks}
  end
  else
    DisableCommands ([cmCloseAll,cmTile,cmCascade]);
  if ((Desktop^.Current <> nil) and
  (Desktop^.Current^.State and sfModal = sfModal))
  or (AppOptions and appHelpInUse = appHelpInUse) then {see if modal dialog}
    DisableCommands ([cmQuit])                         {is on the desk top}
  else
    EnableCommands ([cmQuit]);
end;

{
Close all windows on desk top.
}

procedure TCyberTerm.ClearDeskTop;

procedure CloseDlg (P : PView); far;

begin
  Message (P,evCommand,cmClose,nil)
end;

begin
  Desktop^.ForEach (@CloseDlg)
end;

{
Log window logs comm events.
}

procedure TCyberTerm.LogWindow;

var

  LogWin : PLogWin;

begin
  LogWin := New (PLogWin, Init ('Log',appLogWinBuf));
  LogWin^.HelpCtx := hcLogWindow;
  InsertWindow (LogWin)
end;

{
Open text editor.
}

function TCyberTerm.OpenEditor (FileName : FNameStr; Visible : Boolean) : PCyEditWindow;

var

  P : PWindow;
  R : TRect;

begin
  DeskTop^.GetExtent(R);
  Dec (R.B.Y,7);
  P := New (PCyEditWindow, Init (R, FileName, wnNoNumber));
  P^.HelpCtx := hcTextEditor;
  if not Visible then P^.Hide;
  OpenEditor := PCyEditWindow (Application^.InsertWindow(P));
end;

{
Restore desk top stream.
}

procedure TCyberTerm.RestoreDesktop (F : PathStr);

var

  S : PStream;
  Signature : string[appCfgHeaderLen];

begin
  S := New (PBufStream,Init (F,stOpenRead,1024));
  if LowMemory then OutOfMemory
  else
    if S^.Status <> stOk then
    begin
      MessageBox (#3'Unable to open file',nil,mfOkButton+mfError)
    end
    else
    begin
      Signature[0] := Char (appCfgHeaderLen);
      S^.Read (Signature[1],appCfgHeaderLen);
      if Signature = appCfgHeader then {see if signature is right}
      begin
        S^.Read (GenData,SizeOf (GenData)); {read data from stream}
        S^.Read (GenOpts,SizeOf (GenOpts));
        LoadDesktop (S^);
        LoadIndexes (S^);
        if PhoneData.PhoneList.List <> nil then {dispose old list}
          Dispose (PhoneData.PhoneList.List,Done);
        PhoneData.PhoneList.List := PPhoneCollection (S^.Get);
        ShadowAttr := GetColor (136);   {tv shadow color}
        SysColorAttr := (GetColor (137) shl 8) or GetColor (137); {tv system error color}
        ErrorAttr := GetColor (138);    {tv palette index error color}
        Application^.ReDraw; {draw app with new config}
        if S^.Status <> stOk then
          MessageBox (#3'Stream error',nil,mfOkButton+mfError);
      end
      else
        MessageBox (#3'Invalid configuration format',nil,mfOkButton+mfError)
    end;
  Dispose (S,Done)
end;

{
Save desk top stream.
}

procedure TCyberTerm.SaveDesktop (F : PathStr);

var

  CfgFile : File;
  S : PStream;

begin
  S := New(PBufStream,Init (F,stCreate,1024));
  if not LowMemory and (S^.Status = stOk) then
  begin
    S^.Write (appCfgHeader[1],appCfgHeaderLen);
    S^.Write (GenData,SizeOf (GenData));
    S^.Write (GenOpts,SizeOf (GenOpts));
    StoreDesktop (S^);
    StoreIndexes (S^);
    S^.Put (PhoneData.PhoneList.List);
    if S^.Status <> stOk then
    begin {if stream error then delete file}
      MessageBox (#3'Could not create stream',nil,mfOkButton+mfError);
      Dispose (S,Done);
      Assign (CfgFile,F);
      {$I-} Erase (CfgFile); {$I+}
      Exit
    end
  end;
  Dispose (S,Done)
end;

{
Intercept cmHelp to display help even when views are in modal state.
}

procedure TCyberTerm.GetEvent (var Event : TEvent);

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
          MessageBox (#3'Could not open help file', nil, mfError + mfOkButton);
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

function TCyberTerm.GetPalette: PPalette;

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

procedure TCyberTerm.HandleEvent(var Event: TEvent);

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
  InsertWindow (T)
end;

{
Load .CGF file.
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
Return focused term window or nil if none focused.
}

function GetFocusTerm : PTermWin;

var

  FT : PTermWin;

function IsFocused (V : PView) : boolean; far;

begin
  IsFocused := (TypeOf (V^) = TypeOf (TTermWin)) and
  (PTermWin (V)^.State and sfFocused <> 0)
end;

begin
  FT := PTermWin (Desktop^.FirstThat (@IsFocused));
  if FT = nil then
    MessageBox ('No terminal windows focused on desk top.',nil,mfOkButton+mfError);
  GetFocusTerm := FT
end;

{
Return first term window in Z order or nil if none focused.
}

function GetFirstTerm : PTermWin;

var

  FT : PTermWin;

function IsThere (V : PView) : boolean; far;

begin
  IsThere := (TypeOf (V^) = TypeOf (TTermWin))
end;

begin
  FT := PTermWin (Desktop^.FirstThat (@IsThere));
  if FT = nil then
    MessageBox (#3'No terminal windows on desk top.',nil,mfOkButton+mfError);
  GetFirstTerm := FT
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
Hang up focused term window.
}

procedure Hangup;

var

  T : PTermWin;

begin
  T := GetFocusTerm;
  if T <> nil then
  begin
    if T^.Valid (cmClose) then {if ok to close then ok to hang up too}
      T^.CmdState := (T^.CmdState and not ctCmdDialPause) or
      ctCmdHangUp {hang up line}
  end
end;

{
Toggle focused term window's echo
}

procedure ToggleEcho;

var

  T : PTermWin;

begin
  T := GetFocusTerm;
  if T <> nil then
  begin
    if T^.Term^.TermOptions and ctLocalEcho = 0 then
      T^.Term^.TermOptions := T^.Term^.TermOptions or ctLocalEcho
    else
      T^.Term^.TermOptions := T^.Term^.TermOptions and not ctLocalEcho
  end
end;

{
Capture toggle if term window's command state = 0 (no commands).
}

procedure CaptureToggle (TW : PDirWindow);

var

  F : PathStr;
  T : PTermWin;

begin
  T := GetFirstTerm;
  if T <> nil then
  begin
    if T^.CmdState = 0 then
    begin
      F := TreeFileName (TW,'CAP',true);
      if F <> '' then
        T^.Capture (F,0)
    end
    else
      MessageBox ('Cannot capture while commands in progress.',nil,mfOkButton+mfError)
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
    MessageBox ('No file list found on desk top.',nil,mfOkButton+mfError);
    NewFileList;
    D := nil
  end;
  GetFileList := D
end;

{
Download files.  Handle getting name for X modem and ASCII, since they are
not provided by protocol.
}

procedure Download (ProtNum : word);

var

  T : PTermWin;
  D : PStrListDlg;

begin
  T := GetFocusTerm;
  if T <> nil then
    if T^.CmdState = 0 then
    begin
      if ProtNum in[Xmodem..Xmodem1KG,Ascii] then
      begin
        D := GetFileList;
        if D <> nil then
        begin
          T^.FileListColl := PStringCollection (D^.StrBox^.List);
          T^.ProtocolNum := ProtNum;
          T^.CmdState := ctCmdXferInit+ctCmdDownload
        end
      end
      else
      begin
        T^.ProtocolNum := ProtNum;
        T^.CmdState := ctCmdXferInit+ctCmdDownload
      end
    end
end;

{
Upload files from file list.
}

procedure Upload (ProtNum : word);

var

  T : PTermWin;
  D : PStrListDlg;

begin
  T := GetFocusTerm;
  if T <> nil then
    if T^.CmdState = 0 then
    begin
      D := GetFileList;
      if D <> nil then
      begin
        T^.FileListColl := PStringCollection (D^.StrBox^.List);
        T^.ProtocolNum := ProtNum;
        T^.CmdState := ctCmdXferInit
      end
    end
end;

{
Abort file transfer in progress.
}

procedure AbortXfer;

var

  T : PTermWin;

begin
  T := GetFocusTerm;
  if T <> nil then
    if T^.CmdState and ctCmdXfer <> 0 then
      T^.CmdState := T^.CmdState or ctCmdXferAbort
end;

{
Abort script
}

procedure AbortScript;

var

  T : PTermWin;

begin
  T := GetFocusTerm;
  if T <> nil then
  begin
    if T^.Valid (cmClose) then {if ok to close then ok to abort too}
    begin
      if T^.CmdState and ctCmdScript <> 0 then
      begin
        T^.CmdState := T^.CmdState and not
        (ctCmdDial or ctCmdDialPause or ctCmdScript);
        T^.UpdateLog ('Script aborted')
      end
      else
        MessageBox ('Unable to abort script',nil,mfOkButton+mfError);
    end
  end
end;

{
Return terminal window pointer if no async or view buffer errors.
}

function TermWindow (P : PTermRec) : PTermWin;

var

  TW : PTermWin;

{see if view is a term win and uses same com port}

function IsTermWin (V : PView) : boolean; far;

begin
  IsTermWin :=  (TypeOf (V^) = TypeOf (TTermWin)) and
  (PTermWin (V)^.UPort.GetComName = P^.ComName)
end;

begin
  pointer (TW) := Desktop^.FirstThat (@IsTermWin);
  if TW <> nil then
  begin
    if TW^.Valid (cmClose) then {see if it's ok to close}
    begin
      TW^.Close;
      TW := nil
    end
  end;
  if TW = nil then              {see if ok to create new window}
  begin
    New (TW,Init (P^.Name,P,@GenOpts));
    if ValidView (TW) <> nil then
    begin
      if ErrorBox then
      begin
        Dispose (TW,Done);
        TW := nil
      end
      else
        if TW^.Term^.DrawBuf^[TW^.Term^.Lines] = nil then
        begin
          TW^.UpdateLog ('View buffer too large'); {ran out of heap!}
          Dispose (TW,Done);
          TW := nil;
          MessageBox ('View buffer too large.  Reduce terminal length and try again.',
          nil,mfOkButton+mfError)
        end
        else
          InsertWindow (TW)
    end
  end
  else
    TW := nil;
  TermWindow := TW
end;

{
Open phone book to dial, add, edit and delete records.  Records added to list
are preserved even if dialog exits with cmCancel.
}

procedure PhoneBook;

var

  D : PTermConfigDlg;
  TW : PTermWin;

begin
  D := New (PTermConfigDlg,Init);
  if PhoneData.PhoneList.List = nil then       {create new list if needed}
    PhoneData.PhoneList.List := New (PPhoneCollection,Init (0,1));
  D^.PhoneCollPtr := PhoneData.PhoneList.List; {tell dialog where list is}
  D^.HelpCtx := hcPhoneBookDlg;
  if ExecuteDialog (D,@PhoneData) = cmOK then
  begin
    if PhoneData.PhoneList.List^.Count > 0 then {check for empty list}
    begin
      TW := TermWindow (PhoneData.PhoneList.List^.At (
      PhoneData.PhoneList.Selection));
      if TW <> nil then {init modem and dial if window created}
      begin
        TW^.HelpCtx := hcTermWindow;
        if TW^.Term^.TermOptions and ctReqCTS <> 0 then
          TW^.CmdState := ctCmdInit+ctCmdDial+ctCmdCTSWait {wait for cts}
        else
          TW^.CmdState := ctCmdInit+ctCmdDial              {skip cts wait}
      end
    end
  end
end;

{
Compile and run focused edit window script in term window.
}

procedure RunScript;

var

  D : PTermConfigDlg;
  TW : PTermWin;
  E : PCyEditWindow;
  C : TScriptCompile;

begin
  E := GetEditor (true); {get focused editor}
  if E <> nil then
  begin
    D := New (PTermConfigDlg,Init);
    if PhoneData.PhoneList.List = nil then       {create new list if needed}
      PhoneData.PhoneList.List := New (PPhoneCollection,Init (0,1));
    D^.PhoneCollPtr := PhoneData.PhoneList.List; {tell dialog where list is}
    D^.HelpCtx := hcPhoneBookDlg;
    if ExecuteDialog (D,@PhoneData) = cmOK then
    begin
      if PhoneData.PhoneList.List^.Count > 0 then {check for empty list}
      begin
        TW := TermWindow (PhoneData.PhoneList.List^.At (
        PhoneData.PhoneList.Selection));
        if TW <> nil then    {compile script if term window created}
        begin
          TW^.HelpCtx := hcTermWindow;
          TW^.ScriptEng := New (PScriptEng,Init (TW));
          C.Init (E,TW);
          if C.Compile then
          begin
            if TW^.Term^.TermOptions and ctReqCTS <> 0 then
              TW^.CmdState := ctCmdCTSWait+ctCmdScript {wait for cts before start}
            else
              TW^.CmdState := ctCmdScript;             {start script}
            TW^.UpdateLog ('Start script')
          end;
          C.Done
        end
      end
    end
  end
end;

{
Open new text editor.
}

procedure FileNew;

begin
  OpenEditor ('', True)
end;

{
Open .SCR script source file.
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
Save as .SCR script source file.
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
  ClipWindow^.Select;
  ClipWindow^.Show
end;

{
General options.
}

procedure General;

var

  D : PTermGenDlg;

begin
  D := New (PTermGenDlg,Init);
  D^.HelpCtx := hcTermOpts;
  if ExecuteDialog (D,@GenData) <> cmCancel then
    GenDlgToGenOpts (GenData,GenOpts)
end;

{
Tree window is a file browser.
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
Switch between 25 and 43/50 line mode.
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
  Desktop^.GetExtent (R)
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
Force all oftileable windows to top.
}

procedure TileableOnTop (P : PView); far;

begin
  if (P^.Options and ofTileable = ofTileable) then
    P^.MakeFirst
end;

{
See if anything is on desk top.
}

function IsThere (P : PView) : Boolean; far;

begin
  IsThere := (P^.State and sfActive = sfActive)
end;

begin
  if Event.What = evCommand then
    case Event.Command of {we want to see these events before inherited}
      cmSaveAs  :
      begin
        TreeWindow ('Save As','*.SCR',cmSaveAs,true);
        ClearEvent (Event)
      end;
      cmCascade : Desktop^.ForEach (@TileableOnTop);
      cmTile    : Desktop^.ForEach (@TileableOnTop);
      cmQuit    :
      begin
        ClearDeskTop;        {try to close all windows on desk top}
        if DeskTop^.FirstThat (@IsThere) <> nil then
          ClearEvent (Event) {if any views on desk top then do not quit}
      end
    end;
  inherited HandleEvent (Event);
  case Event.What of
    evCommand:
    case Event.Command of             {process commands}
      cmPhoneBook     : PhoneBook;
      cmGeneral       : General;
      cmNewLogWin     : LogWindow;
      cmHangUp        : HangUp;
      cmEchoToggle    : ToggleEcho;
      cmToggleVideo   : ToggleVideo;
      cmRunScript     : RunScript;
      cmAbortScript   : AbortScript;
      cmColors        : Colors;
      cmSaveConfig    : TreeWindow ('Save Config Stream','*.CFG',cmSaveConfig,true);
      cmLoadConfig    : TreeWindow ('Load Config Stream','*.CFG',cmLoadConfig,true);
      cmFileBrowse    : TreeWindow ('File List Builder','*.*',cmAddFile,true);
      cmCapture       : TreeWindow ('Capture File','*.CAP',cmCapture,true);
      cmOpen          : TreeWindow ('Open Script Source','*.SCR',cmOpen,true);
      cmNewFileList   : NewFileList;
      cmNew           : FileNew;
      cmShowClip      : ShowClip;
      cmXmodemDown    : Download (Xmodem);
      cmXmodem1KDown  : Download (Xmodem1K);
      cmXmodem1KGDown : Download (Xmodem1KG);
      cmYmodemDown    : Download (Ymodem);
      cmYmodemGDown   : Download (YmodemG);
      cmZmodemDown    : Download (Zmodem);
      cmKermitDown    : Download (Kermit);
      cmAsciiDown     : Download (Ascii);
      cmXmodemUp      : Upload (Xmodem);
      cmXmodem1KUp    : Upload (Xmodem1K);
      cmXmodem1KGUp   : Upload (Xmodem1KG);
      cmYmodemUp      : Upload (Ymodem);
      cmYmodemGUp     : Upload (YmodemG);
      cmZmodemUp      : Upload (Zmodem);
      cmKermitUp      : Upload (Kermit);
      cmAsciiUp       : Upload (Ascii);
      cmAbortXfer     : AbortXfer;
      cmViewDoc       : ViewTextFile (appDocName);
      cmAbout         : AboutBox;
      cmCloseAll      : ClearDeskTop
    end;
    evBroadcast:
    case Event.Command of             {process broadcasts}
      cmSaveConfig    : SaveConfigFile (PDirWindow (Event.InfoPtr));
      cmLoadConfig    : LoadConfigFile (PDirWindow (Event.InfoPtr));
      cmAddFile       : AddFileToList (PDirWindow (Event.InfoPtr));
      cmCapture       : CaptureToggle (PDirWindow (Event.InfoPtr));
      cmOpen          : FileOpen (PDirWindow (Event.InfoPtr));
      cmSaveAs        : SaveFileAs (PDirWindow (Event.InfoPtr))
    end
  end
end;

{
Menu.
}

procedure TCyberTerm.InitMenuBar;

var

  R : TRect;

begin
  GetExtent (R);
  R.B.Y := R.A.Y+1;
  MenuBar := New (PMenuBar,Init (R,NewMenu (
    NewSubMenu ('~F~ile',hcFile,NewMenu (
      NewItem ('~R~un script','F9',kbF9,cmRunScript,hcRunScript,
      NewSubMenu ('~T~ext',hcText,NewMenu (
        NewItem ('~N~ew', 'F4', kbF4, cmNew, hcNewText,
        NewItem ('~O~pen...', 'F3', kbF3, cmOpen, hcOpenText,
        NewItem ('~S~ave', 'F2', kbF2, cmSave, hcSaveText,
        NewItem ('Sa~v~e as...', '', kbNoKey, cmSaveAs, hcSaveAsText,
        NewItem ('Save a~l~l', '', kbNoKey, cmSaveAll, hcSaveAllText,
        nil)))))),
        NewSubMenu ('~D~own load',hcDownload,NewMenu (
          NewItem ('~Z~ modem','',kbNoKey,cmZmodemDown,hcDownload,
          NewItem ('~Y~ modem','',kbNoKey,cmYmodemDown,hcDownload,
          NewItem ('Y modem ~G~','',kbNoKey,cmYmodemGDown,hcDownload,
          NewItem ('~X~ modem','',kbNoKey,cmXmodemDown,hcDownload,
          NewItem ('X modem ~1~K','',kbNoKey,cmXmodem1KDown,hcDownload,
          NewItem ('X mode~m~ 1KG','',kbNoKey,cmXmodem1KGDown,hcDownload,
          NewItem ('~K~ermit','',kbNoKey,cmKermitDown,hcDownload,
          NewItem ('~A~scii','',kbNoKey,cmAsciiDown,hcDownload,
          nil))))))))),
        NewSubMenu ('~U~p load',hcUpload,NewMenu (
          NewItem ('~Z~ modem','',kbNoKey,cmZmodemUp,hcUpload,
          NewItem ('~Y~ modem','',kbNoKey,cmYmodemUp,hcUpload,
          NewItem ('Y modem ~G~','',kbNoKey,cmYmodemGUp,hcUpload,
          NewItem ('~X~ modem','',kbNoKey,cmXmodemUp,hcUpload,
          NewItem ('X modem ~1~K','',kbNoKey,cmXmodem1KUp,hcUpload,
          NewItem ('X mode~m~ 1KG','',kbNoKey,cmXmodem1KGUp,hcUpload,
          NewItem ('~K~ermit','',kbNoKey,cmKermitUp,hcUpload,
          NewItem ('~A~scii','',kbNoKey,cmAsciiUp,hcUpload,
          nil))))))))),
      NewSubMenu ('~L~ist',hcList,NewMenu (
        NewItem ('~N~ew','',kbNoKey,cmNewFileList,hcNewFileList,
        NewItem ('~B~uilder...','',kbNoKey,cmFileBrowse,hcFileListBuild,
        nil))),
      NewSubMenu ('~C~onfig',hcConfig,NewMenu (
        NewItem ('~L~oad...','Ctrl+F3',kbCtrlF3,cmLoadConfig,hcLoadConfig,
        NewItem ('~S~ave...','Ctrl+F2',kbCtrlF2,cmSaveConfig,hcSaveConfig,
        nil))),
      NewLine (
      NewItem ('~V~iew doc','',kbNoKey,cmViewDoc,hcViewDoc,
      NewItem ('~A~bout','',kbNoKey,cmAbout,hcAbout,
      NewLine (
      NewItem ('E~x~it','Alt-X',kbAltX,cmQuit,hcExit,
      nil)))))))))))),
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
    NewSubMenu ('~T~erminal',hcTerminal,NewMenu (
      NewItem ('~P~hone book...','F7',kbF7,cmPhoneBook,hcPhoneBook,
      NewItem ('~C~apture...','',kbNoKey,cmCapture,hcCapture,
      NewItem ('~H~ang up','',kbNoKey,cmHangUp,hcHangUp,
      NewItem ('~E~cho toggle','',kbNoKey,cmEchoToggle,hcEchoToggle,
      NewItem ('~S~cript abort','',kbNoKey,cmAbortScript,hcAbortScript,
      NewItem ('Transfer ~a~bort','',kbNoKey,cmAbortXfer,hcAbortXfer,
      nil))))))),
    NewSubMenu ('~O~ptions',hcOptions,NewMenu (
      NewItem ('~T~erminal...','',kbNoKey,cmGeneral,hcOTerminal,
      NewItem ('~C~olors...','',kbNoKey,cmColors,hcOColors,
      NewItem ('~V~ideo toggle','',kbNoKey,cmToggleVideo,hcVideoToggle,
      nil)))),
    NewSubMenu ('~W~indow',hcWindows,NewMenu(
      StdWindowMenuItems (
      NewItem ('New ~l~og window','F8',kbF8,cmNewLogWin,hcNewLogWin,
      nil))),nil)))))))))
end;

{
Status line.
}

procedure TCyberTerm.InitStatusLine;

var

  R : TRect;

begin
  GetExtent (R);
  R.A.Y := R.B.Y-1;
  StatusLine := New (PStatusLine,Init(R,
    NewStatusDef (0,$FFFF,
      NewStatusKey ('~F1~ Help', kbF1, cmHelp,
      NewStatusKey ('',kbF2,cmSave,
      NewStatusKey ('',kbF3,cmOpen,
      NewStatusKey ('',kbF4,cmNew,
      NewStatusKey ('',kbF7,cmPhoneBook,
      NewStatusKey ('',kbF8,cmNewLogWin,
      NewStatusKey ('',kbF9,cmRunScript,
      NewStatusKey ('~Alt-F3~ Close',kbAltF3,cmClose,
      NewStatusKey ('~Alt-X~ Exit',kbAltX,cmQuit,
      NewStatusKey ('',kbCtrlF2,cmSaveConfig,
      NewStatusKey ('',kbCtrlF3,cmLoadConfig,
      NewStatusKey ('',kbCtrlF5,cmResize,
      NewStatusKey ('',kbF10,cmMenu,
      nil))))))))))))),nil)))
end;

{
Let user know if heap allocation cuts into the safety pool.
}

procedure TCyberTerm.OutOfMemory;

begin
  MessageBox ('Not enough memory available to complete operation.  Try closing some windows!',
  nil,mfError+mfOkButton);
end;

{
Load desk top from stream.
}

procedure TCyberTerm.LoadDesktop (var S : TStream);

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

procedure TCyberTerm.StoreDesktop(var S: TStream);

var

  Pal: PString;

begin
  Pal := @Application^.GetPalette^;
  S.WriteStr (Pal)
end;

{
Main app.
}

var

  CTApp : TCyberTerm;

begin
  CTApp.Init;
  SysErrorFunc := AppSystemError;
  CTApp.Run;
  CTApp.Done
end.
