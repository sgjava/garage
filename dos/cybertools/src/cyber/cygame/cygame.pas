{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

CyberGame application shows how to use character sprites in a multi-level
'Invaders' type arcade game.

Borland Pascal 7.x or Turbo Pascal 7.x and Turbo Vision 2.x are required to
compile.

Set IDE directories to

\BP\UNITS;
\BP\EXAMPLES\DOS\TVDEMO;
\BP\EXAMPLES\DOS\TVFM;

These path names are BP 7.x defaults.  If you changed any of these then use
the correct paths in Options|Directories...  See APP.INC for global compiler
switches.
}

program CyberGame;

{$I APP.INC}
{$X+}

uses

  Dos,                           {bp units}
  Memory, Drivers, Objects,      {tv units}
  Views, Menus, Dialogs,
  App, MsgBox, StdDlg, ColorSel,
  Gadgets, HelpFile,             {tvdemo units}
  ViewText,                      {tvfm units}
  CGHelp, CGCmds,                {cybertools units}
  VGA, VGACGFil, GameDlg, PCX,
  CommDlgs, TVStr;

const

  appDocName  = 'CYBER.DOC';  {doc file name}
  appCfgName  = 'CYGAME.CFG'; {config stream file name}
  appHelpName = 'CGHELP.HLP'; {help file name}
  appExeName  = 'CYGAME.EXE'; {name used to locate .exe for older dos}
  appCfgHeaderLen = 10;       {header used by config stream}
  appCfgHeader : string[appCfgHeaderLen] = 'CYBERGAME'#26;
  appViewDocBuf = 8192;       {buffer size for viewing doc file}

  appChrWidth8  = $01;        {set app options bit to 1 to select option}
  appPageMode   = $02;
  app8Colors    = $04;
  appHelpInUse  = $8000;      {used by help system}
  appScrOpts    = $07;        {mask of just screen options}

  appGraphWinX = 32;          {x = 32*8 = 256 pixels}
  appGraphWinY = 8;           {y = 8*16 = 128 pixels}
  appFadeInc   = 8;           {fade in/out increment}

  CSysColor = #$00#$00#$00;   {app palette additions for tv system stuff}
  CSysPal   = #144#145#146;

type

  TCyberGame = object (TApplication)
    FontTable1,
    FontTable2,
    FirstChr,
    LastChr : byte;
    AppOptions,
    PageOfs,
    DefChrHeight : word;
    Page : pointer;
    DefFont : vgaChrTablePtr;
    DacPalette : vgaPalette;
    ScrData : ScrOptsData;
    CtlData : GameOptsData;
    Clock : PClockView;
    Heap : PHeapView;
    constructor Init;
    destructor Done; virtual;
    procedure SetCustomScreen;
    procedure FlipPage;
    procedure ClearDeskTop;
    procedure Idle; virtual;
    procedure AboutBox;
    procedure LoadFontTable (ChrData : pointer;
                             ChrTable, ChrHeight :byte;
                             StartChr, NumChrs : word);
    function SaveFontTable (ChrTable, ChrHeight :byte;
                            StartChr, NumChrs : word) : vgaChrTablePtr;
    procedure RestoreDesktop (F : PathStr);
    procedure SaveDeskTop (F : PathStr);
    procedure GetEvent (var Event : TEvent); virtual;
    function GetPalette : PPalette; virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
    procedure InitDeskTop; virtual;
    procedure InitMenuBar; virtual;
    procedure InitStatusLine; virtual;
    procedure OutOfMemory; virtual;
    procedure LoadDesktop (var S : TStream);
    procedure StoreDesktop (var S : TStream);
  end;

{
Initilize TV app.
}

constructor TCyberGame.Init;

var

  R :TRect;

begin
  LowMemSize := 512;    {8192 byte safety pool}
  inherited Init;
  RegisterObjects;      {register stuff for stream access}
  RegisterViews;
  RegisterMenus;
  RegisterDialogs;
  RegisterApp;
  RegisterHelpFile;

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

  RestoreDesktop (appCfgName); {load config stream}
  AboutBox;
  Randomize                    {animation dialogs use random numbers}
end;

{
Done TV app.
}

destructor TCyberGame.Done;

begin
  ClearDeskTop;               {make sure all games closed}
  if DefFont <> nil then      {dispose default font}
    FreeMem (DefFont,vgaMaxChrs*DefChrHeight);
  FadeOutDAC (appFadeInc);    {fade to black}
  SetVideoMode (StartUpMode); {this resets all the custom stuff with bios}
  inherited Done
end;

{
Sets screen page if not not flipping, 8 or 16 color mode, 8 or 9 pixel width,
font map, DAC palette and mouse mask.
}

procedure TCyberGame.SetCustomScreen;

begin
  HideMouse;
  if AppOptions and appPageMode = 0 then
    SetPage (vgaPageOfsLoc[0]); {screen page 0 for non page flipping displays}
  if AppOptions and app8Colors = app8Colors then
    SetAttrCont (vgaAttrCPEnable,$07)  {use 8 colors}
  else
    SetAttrCont (vgaAttrCPEnable,$0f); {use 16 colors}
  if AppOptions and appChrWidth8 = appChrWidth8 then
  begin
    if IsChrWidth9 then
      SetChrWidth8 {640 x 400 screen}
  end
  else
  begin
    if not IsChrWidth9 then
      SetChrWidth9 {720 x 400 screen}
  end;
  FontMapSelect (vgaChrTableMap1[FontTable1],
  vgaChrTableMap2[FontTable2]);    {select font tables}
  SetDACBlock (@DacPalette,0,256); {set 256 color palette}
  MouseTextMask ($ffff,$f700);     {set mouse mask for both fonts}
  ShowMouse
end;

{
Copy screen page 0 to new non-visiable page and flip to new page.
}

procedure TCyberGame.FlipPage;

begin
  CopyScrMem (ScreenBuffer,Page,vgaScrSize25);
  SetPage (PageOfs);
  if PageOfs = vgaPageOfsLoc[1] then
  begin
    PageOfs := vgaPageOfsLoc[2];
    Page := vgaPageLoc[2]
  end
  else
  begin
    PageOfs := vgaPageOfsLoc[1];
    Page := vgaPageLoc[1]
  end;
  WaitVertSync {wait for vga vert sync before drawing anything}
end;

{
Remove all closeable windows from desk top.
}

procedure TCyberGame.ClearDeskTop;

procedure CloseDlg (P : PView); far;

begin
  Message (P,evCommand,cmClose,nil)
end;

begin
  Desktop^.ForEach (@CloseDlg)
end;

{
Handle app's idle time processing.
}

procedure TCyberGame.Idle;

{return true if any view on desk top is tileable}

function IsTileable (P : PView) : boolean; far;

begin
  IsTileable := (P^.Options and ofTileable <> 0) and
  (P^.State and sfVisible <> 0)
end;

begin
  inherited Idle;
  Clock^.Update; {update tvdemo gadgets}
  Heap^.Update;
  if Desktop^.Current <> nil then              {see if anything is}
  begin                                        {on the desk top}
    EnableCommands ([cmCloseAll]);
    if Desktop^.FirstThat (@IsTileable) <> nil then {see if any tileable}
      EnableCommands ([cmTile,cmCascade])           {windows are on the}
    else                                            {desk top}
      DisableCommands ([cmTile,cmCascade]);
    Message (DeskTop,evBroadcast,cmAnimate,nil) {update all animation dialogs}
  end
  else
    DisableCommands ([cmCloseAll,cmTile,cmCascade]);
  if ((Desktop^.Current <> nil) and
  (Desktop^.Current^.State and sfModal = sfModal)) or
  (AppOptions and appHelpInUse = appHelpInUse) then    {see if modal dialog}
    DisableCommands ([cmQuit])                         {is on the desk top}
  else
    EnableCommands ([cmQuit]);
  if AppOptions and appPageMode = appPageMode then
    FlipPage  {if page mode is enabled then flip page each idle cycle}
end;

{
Display info about app.
}

procedure TCyberGame.AboutBox;

begin
  HelpCtx := hcAbout;
  MessageBox(
    #3'Turbo Vision CyberTools 2.6'#13+
    #3'(C) 1994 Steve Goldsmith'#13+
{$IFDEF DPMI}
    #3'CyberGame DPMI',
{$ELSE}
    #3'CyberGame REAL',
{$ENDIF}
    nil, mfInformation or mfOKButton);
  HelpCtx := hcNoContext
end;

{
Load font table from system RAM.
}

procedure TCyberGame.LoadFontTable (ChrData : pointer;
                                    ChrTable, ChrHeight :byte;
                                    StartChr, NumChrs : word);

begin
  HideMouse;
  AccessFontMem;
  SetRamTable (StartChr,NumChrs,ChrHeight,ChrData,vgaChrTableLoc[ChrTable]);
  AccessScreenMem;
  ShowMouse
end;

{
Save font table from video RAM.
}

function TCyberGame.SaveFontTable (ChrTable, ChrHeight :byte;
                                   StartChr, NumChrs : word) : vgaChrTablePtr;

begin
  HideMouse;
  AccessFontMem;
  SaveFontTable :=
  GetRamTable (StartChr,NumChrs,ChrHeight,vgaChrTableLoc [ChrTable]);
  AccessScreenMem;
  ShowMouse
end;

{
Restore desk top stream.
}

procedure TCyberGame.RestoreDesktop (F : PathStr);

var

  I : byte;
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
        S^.Read (AppOptions,SizeOf (AppOptions)); {read data from stream}
        S^.Read (CtlData,SizeOf (CtlData));
        S^.Read (FontTable1,SizeOf (FontTable1));
        S^.Read (FontTable2,SizeOf (FontTable2));
        S^.Read (FirstChr,SizeOf (FirstChr));
        S^.Read (LastChr,SizeOf (LastChr));
        S^.Read (DacPalette,SizeOf (DacPalette));

        if DefFont = nil then
          DefFont := MemAlloc (DefChrHeight*vgaMaxChrs);
        HideMouse; {no screen writes during font mem access}
        AccessFontMem;
        for I := 0 to 7 do
        begin
          S^.Read (DefFont^,DefChrHeight*vgaMaxChrs);
          SetRamTable (0,vgaMaxChrs,DefChrHeight,DefFont,vgaChrTableLoc[I])
        end;
        AccessScreenMem;
        ShowMouse;
        LoadDesktop (S^);
        LoadIndexes (S^);
        ShadowAttr := GetColor (144);   {tv shadow color}
        SysColorAttr := (GetColor (145) shl 8) or GetColor (145); {tv system error color}
        ErrorAttr := GetColor (146);    {tv palette index error color}
        Application^.ReDraw; {draw app with new config}
        if DefFont <> nil then
        begin
          FreeMem (DefFont,DefChrHeight*vgaMaxChrs);
          DefFont := SaveFontTable (FontTable1,DefChrHeight,0,vgaMaxChrs)
        end;
        SetCustomScreen;
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

procedure TCyberGame.SaveDesktop (F : PathStr);

var

  I : byte;
  CfgFile : File;
  S : PStream;
  SFont : vgaChrTablePtr;

begin
  S := New(PBufStream,Init (F,stCreate,1024));
  if not LowMemory and (S^.Status = stOk) then
  begin
    S^.Write (appCfgHeader[1],appCfgHeaderLen);
    S^.Write (AppOptions,SizeOf (AppOptions));
    S^.Write (CtlData,SizeOf (CtlData));
    S^.Write (FontTable1,SizeOf (FontTable1));
    S^.Write (FontTable2,SizeOf (FontTable2));
    S^.Write (FirstChr,SizeOf (FirstChr));
    S^.Write (LastChr,SizeOf (LastChr));
    GetDACBlock (@DacPalette,0,256);
    S^.Write(DacPalette,SizeOf (DacPalette));

    HideMouse; {no screen write during font mem access}
    AccessFontMem;
    for I := 0 to 7 do {save all 8 vga font tables}
    begin
      SFont := GetRamTable (0,vgaMaxChrs,DefChrHeight,vgaChrTableLoc[I]);
      S^.Write (SFont^,DefChrHeight*vgaMaxChrs);
      if SFont <> nil then
        FreeMem (SFont,DefChrHeight*vgaMaxChrs)
    end;
    AccessScreenMem;
    ShowMouse;

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

procedure TCyberGame.GetEvent (var Event : TEvent);

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

function TCyberGame.GetPalette: PPalette;

const

  CNewColor = CAppColor+CHelpColor+CAniColor+CGraphColor+CSysColor;
  CNewBlackWhite = CAppBlackWhite+CHelpBlackWhite+CAniColor+CGraphColor+CSysColor;
  CNewMonochrome = CAppMonochrome+CHelpMonochrome+CAniColor+CGraphColor+CSysColor;
  P: array[apColor..apMonochrome] of string[Length (CNewColor)] =
  (CNewColor, CNewBlackWhite, CNewMonochrome);

begin {add additional entries to the normal application palettes}
  GetPalette := @P[AppPalette];
end;

{
Process app events.
}

procedure TCyberGame.HandleEvent (var Event: TEvent);

{
Load CGF file and store in table.
}

procedure LoadChrFile (F : PathStr; ChrTbl : byte);

var

  ChrFile : TChrGenFile;

begin
  ChrFile.Init;
  ChrFile.OpenRead (F);
  if (ChrFile.IoError = 0) and
  (ChrFile.Header.Height = DefChrHeight) then
  begin
    ChrFile.ReadChrTable;
    LoadFontTable (
    ChrFile.ChrTablePtr,ChrTbl,ChrFile.Header.Height,
    ChrFile.Header.StartChr,ChrFile.Header.TotalChrs)
  end
  else
    MessageBox (#3'Problem reading font file.',nil,mfOkButton+mfError);
  ChrFile.FreeChrTable;
  ChrFile.Done
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
Load CGF file.
}

procedure LoadFontFile (TW : PDirWindow);

var

  F : PathStr;

begin
  F := TreeFileName (TW,'CGF',true);
  if F <> '' then
    LoadChrFile (F,FontTable1)
end;

{
Decode and view 2 color PCX file up to 640 X 480.  Actual viewing area is
determined by graphics window size.
}

procedure LoadPCXFile (TW : PDirWindow);

var

  F : PathStr;
  Decode : TPCXToChrTable;

begin
  F := TreeFileName (TW,'PCX',true);
  if F <> '' then
  begin
    HideMouse; {no screen writes during font mem access}
    Decode.Init (F,appGraphWinX,appGraphWinY,
    DefChrHeight,vgaChrTableLoc[FontTable2]);
    ShowMouse;
    if Decode.ReadError <> 0 then
      MessageBox (#3'Problem reading PCX file.',nil,mfOkButton+mfError);
    Decode.Done
  end
end;

{
Load DOC file.
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
Create new game dialog.
}

procedure GameDialog;

var

  P : PGameDlg;

begin
  with CtlData do
  begin
    P := New (PGameDlg,Init ('Cyber Invaders',Left[1],Right[1],Shoot[1],Stop[1]));
    if SoundFlag <> 0 then
      P^.gameState := P^.gameState or gameSoundOn
  end;
  P^.HelpCtx := hcGameDialog;
  InsertWindow (P)
end;

{
Restore default font loaded by config.
}

procedure RestoreDefFont;

begin
  if (DefFont <> nil) and
  (DefChrHeight = BiosGetChrHeight) then
    LoadFontTable (DefFont,FontTable1,DefChrHeight,0,vgaMaxChrs)
end;

{
Set custom screen options.
}

procedure ScreenOptions;

var

  D : PScrOptsDlg;

begin
  with ScrData do
  begin
    SMode := AppOptions and appScrOpts; {use only screen options}
    FontMapVal (GetSeqCont (vgaSeqChrMapSel),byte (FntTbl1),byte (FntTbl2));
    FChr := IntToStr (FirstChr);
    LChr := IntToStr (LastChr);
    D := New (PScrOptsDlg,Init);
    D^.Options := D^.Options or ofCentered;
    D^.HelpCtx := hcScreenDialog;
    if ExecuteDialog (D,@ScrData) <> cmCancel then
    begin
      AppOptions := (AppOptions and not appScrOpts)
      or SMode; {clear all scr opts bits and set bits returned from dialog}
      FontTable1 := FntTbl1;
      FontTable2 := FntTbl2;
      FirstChr := StrToInt (FChr);
      LastChr := StrToInt (LChr);
      SetCustomScreen {set screen with new settings}
    end
  end
end;

{
Game keyboard controls and sound toggle.
}

procedure ControlOptions;

var

  D : PGameOptsDlg;

begin
  D := New (PGameOptsDlg,Init);
  D^.Options := D^.Options or ofCentered;
  D^.HelpCtx := hcControlsDialog;
  ExecuteDialog (D,@CtlData)
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

function AniColorItems (const Next: PColorItem) : PColorItem;

begin
  AniColorItems :=
    ColorItem ('Background',       136,
    ColorItem ('Invaders',         137,
    ColorItem ('UFO',              138,
    ColorItem ('UFO bomb',         139,
    ColorItem ('UFO bomb explode', 140,
    ColorItem ('Base ship',        141,
    ColorItem ('Base ship shot',   142,
    ColorItem ('PCX graphics',     143,
    Next))))))))
end;

function SysColorItems (const Next: PColorItem) : PColorItem;

begin
  SysColorItems :=
    ColorItem ('Shadow',       144,
    ColorItem ('System error', 145,
    ColorItem ('Index error',  146,
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
  ColorGroup ('Animation',   AniColorItems(nil),
  ColorGroup ('System',      SysColorItems(nil),
  nil)))))))))))));
  D^.HelpCtx := hcColorDialog;
  if ExecuteDialog (D,Application^.GetPalette) <> cmCancel then
  begin
    DoneMemory; {dispose all group buffers}
    ReDraw;     {redraw application with new palette}
    ShadowAttr := GetColor (144);   {tv shadow color}
    SysColorAttr := (GetColor (145) shl 8) or GetColor (145); {tv system error color}
    ErrorAttr := GetColor (146)     {tv palette index error color}
  end
end;

{
Adjust 16 text colors at DAC level.
}

procedure AdjustPalette;

var

  D : PPalDlg;

begin
  D := New (PPalDlg,Init);
  D^.Options := D^.Options or ofCentered;
  D^.HelpCtx := hcPaletteDialog;
  if ExecuteDialog (D,nil) <> cmCancel then
    GetDACBlock (@DacPalette,0,256)
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
Force all oftileable windows to top.
}

procedure TileableOnTop (P : PView); far;

begin
  if (P^.Options and ofTileable = ofTileable) then
    P^.MakeFirst
end;

begin
  if (Event.What = evCommand) and
  ((Event.Command = cmCascade) or
  (Event.Command = cmTile)) then {seperate oftileable windows from nontileable ones}
    Desktop^.ForEach (@TileableOnTop);
  inherited HandleEvent (Event);
  case Event.What of
    evCommand:
      begin
        case Event.Command of {process commands}
          cmLoadFont    : TreeWindow ('Load Font File','*.CGF',cmLoadFont,true);
          cmLoadPCX     : TreeWindow ('Load PCX File','*.PCX',cmLoadPCX,true);
          cmSaveConfig  : TreeWindow ('Save Config Stream','*.CFG',cmSaveConfig,true);
          cmLoadConfig  : TreeWindow ('Load Config Stream','*.CFG',cmLoadConfig,true);
          cmViewDoc     : ViewTextFile (appDocName);
          cmAbout       : AboutBox;
          cmNewGame     : GameDialog;
          cmCloseAll    : ClearDeskTop;
          cmRestoreDef  : RestoreDefFont;
          cmScreenOpts  : ScreenOptions;
          cmControlOpts : ControlOptions;
          cmColors      : Colors;
          cmAdjPal      : AdjustPalette
        else
          Exit
        end
      end;
    evBroadcast :
    begin
      case Event.Command of {process broadcasts}
        cmLoadFont    : LoadFontFile (PDirWindow (Event.InfoPtr));
        cmLoadPCX     : LoadPCXFile (PDirWindow (Event.InfoPtr));
        cmSaveConfig  : SaveConfigFile (PDirWindow (Event.InfoPtr));
        cmLoadConfig  : LoadConfigFile (PDirWindow (Event.InfoPtr))
      end
    end
  end
end;

{
Assign desk top pattern char, page locations, set default char height from
bios and save current DAC palette.
}

procedure TCyberGame.InitDeskTop;

begin
  SetScreenMode (smCO80);              {make sure 80x25 active}
  inherited InitDeskTop;
  DeskTop^.Background^.Pattern := '�'; {new wall paper}
  Page := vgaPageLoc[1];
  PageOfs := vgaPageOfsLoc[1];
  DefChrHeight := BiosGetChrHeight;
  GetDACBlock (@DacPalette,0,256)      {save current vga palette}
end;

{
Menu.
}

procedure TCyberGame.InitMenuBar;

var

  R : TRect;

begin
  GetExtent (R);
  R.B.Y := R.A.Y+1;
  MenuBar := New (PMenuBar,Init (R,NewMenu (
    NewSubMenu ('~F~ile',hcFile,NewMenu (
    NewSubMenu ('~L~oad',hcLoadFile,NewMenu (
      NewItem ('~F~ont...','F3',kbF3,cmLoadFont,hcLoadFile,
      NewItem ('~P~CX...','Shift+F3',kbShiftF3,cmLoadPCX,hcLoadFile,
      NewItem ('~C~onfig...','Ctrl+F3',kbCtrlF3,cmLoadConfig,hcLoadFile,
      nil)))),
      NewItem ('~S~ave config...','Ctrl+F2',kbCtrlF2,cmSaveConfig,hcSaveFile,
      NewLine (
      NewItem ('~V~iew doc','',kbNoKey,cmViewDoc,hcViewDoc,
      NewItem ('~A~bout','',kbNoKey,cmAbout,hcAbout,
      NewLine (
      NewItem ('E~x~it','Alt+X',kbAltX,cmQuit,hcExit,
      nil)))))))),
    NewSubMenu('~W~indow',hcWindows,NewMenu(
      StdWindowMenuItems(
      NewItem ('~N~ew game','F7',kbF7,cmNewGame,hcNewGame,
      nil))),
    NewSubMenu ('~O~ptions',hcOptions,NewMenu (
      NewItem ('~S~creen...','',kbNoKey,cmScreenOpts,hcScreen,
      NewItem ('~C~olors...','',kbNoKey,cmColors,hcOColors,
      NewItem ('~A~djust palette...','',kbNoKey,cmAdjPal,hcAdjustPalette,
      NewItem ('~D~efault font','F4',kbNoKey,cmRestoreDef,hcDefaultFont,
      NewItem ('~G~ame controls...','Alt+G',kbNoKey,cmControlOpts,hcControls,
      nil)))))),nil))))))
end;

{
Status line.
}

procedure TCyberGame.InitStatusLine;

var

  R : TRect;

begin
  GetExtent (R);
  R.A.Y := R.B.Y-1;
  StatusLine := New (PStatusLine,Init(R,
    NewStatusDef (0,$FFFF,
      NewStatusKey ('~F1~ Help', kbF1, cmHelp,
      NewStatusKey ('~Alt+F3~ Close',kbAltF3,cmClose,
      NewStatusKey ('~Alt+X~ Exit',kbAltX,cmQuit,
      NewStatusKey ('',kbAltG,cmControlOpts,
      NewStatusKey ('',kbF4,cmRestoreDef,
      NewStatusKey ('',kbF3,cmLoadFont,
      NewStatusKey ('',kbShiftF3,cmLoadPCX,
      NewStatusKey ('',kbCtrlF2,cmSaveConfig,
      NewStatusKey ('',kbCtrlF3,cmLoadConfig,
      NewStatusKey ('',kbCtrlF5,cmResize,
      NewStatusKey ('',kbF10,cmMenu,
      nil))))))))))),nil)))
end;

{
Message when safety pool is cut into.
}

procedure TCyberGame.OutOfMemory;

begin
  MessageBox (#3'Not enough memory available to complete operation.  Try closing some windows!',
  nil,mfError+mfOkButton)
end;

{
Load desk top from stream.
}

procedure TCyberGame.LoadDesktop (var S : TStream);

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

procedure TCyberGame.StoreDesktop(var S: TStream);

var

  Pal: PString;

begin
  Pal := @Application^.GetPalette^;
  S.WriteStr (Pal)
end;

{
If VGA is present then start TV app else print error message.
}

var

  CFApp : TCyberGame;

begin
  if VGACardActive then
  begin
    CFApp.Init;
    SysErrorFunc := AppSystemError;
    CFApp.Run;
    CFApp.Done
  end
  else
    PrintStr (#13#10'VGA display required to run CyberGame!'#13#10);
end.
