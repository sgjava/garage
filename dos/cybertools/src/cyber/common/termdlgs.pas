{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

ANSI/VT100 emulator, terminal window, log window, phone book, file transfer
protocols, CyberScript (tm) script compiler/engine and supporting dialogs.
Async Pro 2.x library for com routines.
}

unit TermDlgs;

{$I APP.INC}

interface

uses

  Dos, Drivers, Memory, Objects, Views, Dialogs, App,
  Validate, StdDlg, MsgBox, DirView,
  ApUart, ApPort, ApMisc, ApTimer, OoCom, OoAbsPcl,
  OoZModem, OoYModem, OoXModem, OoKermit, OoAscii,
  OoArchiv, OoZip,
{$IFDEF UseNewEdit}
  NewEdit,
{$ELSE}
  Editors,
{$ENDIF}
{$IFDEF UseParadox}
  OOPXEng, PXEngine, PXEdit,
{$ENDIF}
  CommDlgs, TVStr, IniTV, CTHelp;

const

  ctLineMax     = 1023; {max line length - 1}
  ctLinesMax    = 1023; {max number of lines - 1}
  ctCapBufSize  = 4096; {capture buffer size}
  ctXferLogWait = 2;    {number of secs between xfer status logging}
  ctGenWait     = 2;    {number of secs for general pause}
  ctIniName     = 'CYTERM.INI'; {ini file name}

  {term window options}

  ctUseDTR    = $0001; {use dtr for receive flow control}
  ctUseRTS    = $0002; {use rts for receive flow control}
  ctReqDSR    = $0004; {require dsr before transmittting}
  ctReqCTS    = $0008; {require cts before transmittting}
  ctHardFlow  = $000f; {mask of just hardware flow options}
  ctXONXOFF   = $0010; {software flow control}
  ctFIFO      = $0020; {use 16550a uart fifo buffering}
  ctLocalEcho = $0040; {local echo}
  ctVT100     = $0080; {use vt100 emulation}
  ctRawCap    = $0100; {capture raw data}
  ctStripHi   = $0200; {strip high bit from char}
  ctAutoZm    = $0400; {automatic zmodem}

  {term window states}

  ctCmdInit      = $00000001; {send init string}
  ctCmdDial      = $00000002; {send dial string}
  ctCmdDialPause = $00000004; {pausing between redials}
  ctCmdRespWait  = $00000008; {waiting for modem response}
  ctCmdRespRec   = $00000010; {received response}
  ctCmdRespTime  = $00000020; {no response before time out}
  ctCmdHangUp    = $00000040; {hang up modem}
  ctCmdDTRLow    = $00000080; {dtr in low state}
  ctCmdCTSWait   = $00000100; {waiting for cts to go high}
  ctCmdCTSLow    = $00000200; {cts in low state}
  ctCmdScript    = $00000400; {script engine in use}
  ctCmdXferStat  = $00000800; {ok to do auto status updates}
  ctCmdXferInit  = $00001000; {init file xfer}
  ctCmdXfer      = $00002000; {xfering file}
  ctCmdDownload  = $00004000; {download = 1, upload = 0}
  ctCmdXferAbort = $00008000; {abort file xfer}
  ctCmdXferMask  = $0000f800; {mask of just xfer commands}
  ctCmdGenPause  = $00010000; {general pause}
  ctCmdGetRate   = $00020000; {get connect rate after carrier or connect}
  ctCmdInitTask  = $00040000; {initialize task flag}
  ctCmdLockWin   = $80000000; {do not allow term win to close}

  {ansi emulator options}

  ctAnsiInverse = $0001; {inverse on}
  ctAnsiIntense = $0002; {intense on}
  ctAnsiBlink   = $0004; {blink on}
  ctAnsiInvis   = $0008; {invisible on}
  ctAnsiAttr    = $000f; {just attr flags}
  ctAnsi7bit    = $0010; {strip high bit from char}
  ctAnsiVT100   = $1000; {vt100}

  ctAnsiIntMax = 20;   {max integer params}
  ctAnsiStrMax = 100;  {max param string size}

  {script engine state}

  ctScrStWaitFor = $0001; {waiting for string or time out}
  ctScrStInpBox  = $0002; {waiting for input box}
  ctScrStLogOn   = $0004; {enable engine logging}
  ctScrStLock    = $0008; {lock script processing}
  ctScrStAbort   = $8000; {enable abort on time out}

  {used to translate radio button value to baud}
  ctBaudTable : array [0..8] of longint =
  (300,1200,2400,4800,9600,19200,38400,57600,115200);

  {used to translate parity to char}
  ctParityChar : array[0..4] of char = ('N','O','E','M','S');

  ctSepChar = ',';          {used to seperate substrings in waitmultistring}

  ctBell      = #7;         {char constants used by emulator and ansi view}
  ctBS        = #8;
  ctTab       = #9;
  ctLF        = #10;
  ctFF        = #12;        {form feed clears screen}
  ctCR        = #13;
  ctSO        = #14;        {shift out}
  ctSI        = #15;        {shift in}
  ctEsc       = #27;        {escape}
  ctSP        = #32;        {space used as clear char}
  ctCrLf      = ctCR+ctLF;  {cr/lf combo}

  ctCharColor = $0700;      {default term view char color}

  cmPhoneAdd    = 65200;    {phone book commands}
  cmPhoneDelete = 65201;
  cmPhoneEdit   = 65202;
  cmPhoneCall   = 65203;
  cmTermIdle    = 65204;    {process term's idle task}
  cmTermCapChar = 65205;    {capture character}
  cmTermInpEnd  = 65206;    {ok on terminal input box}
  cmTermInpCan  = 65207;    {cancel on temminal input box}
  cmListEnd     = 65208;    {ok on list box}
  cmListCan     = 65209;    {cancel on list box}
  cmListInsert  = 65210;    {insert string in list box}
  cmListDraw    = 65211;    { draw list box}

  cmRunScript     = 101;
  cmAbortScript   = 102;
  cmAbortAll      = 103;
  cmHangUp        = 104;
  cmEchoToggle    = 105;
  cmAbortXfer     = 106;
  cmCaptureOn     = 107;
  cmCaptureOff    = 108;
                            {commands active when term windows on desktop}
  ctTermCmds = [cmAbortScript,cmHangUp,cmEchoToggle,cmAbortXfer,cmCaptureOn,cmCaptureOff,cmAbortAll];

{object type ids}

  rsTermRec   = 65000;
  rsPhoneColl = 65001;

type

  ctLineBufPtr = ^ctLineBuf;
  ctLineBuf = array[0..ctLineMax] of word;

  ctScrBufPtr = ^ctScrBuf;
  ctScrBuf = array[0..ctLinesMax] of ctLineBufPtr;

  ctIntParam = array[0..ctAnsiIntMax] of integer;

  ctUartPortPtr = ^ctUartPort;
  ctUartPort = object (UartPort)
    UartWin : PView;
    function UserAbort : boolean; virtual;
    procedure PutString (S : string); virtual;
    procedure ScanForMultiString (SL : string; SepChar : char;
                                 var FoundS : string;
                                 var FoundI : byte); virtual;
  end;

  ctZmodemProtocolPtr = ^ctZmodemProtocol;
  ctZmodemProtocol = object (ZmodemProtocol)
    ProtWin : PView;
  end;

  ctYmodemProtocolPtr = ^ctYmodemProtocol;
  ctYmodemProtocol = object (YmodemProtocol)
    ProtWin : PView;
  end;

  ctXmodemProtocolPtr = ^ctXmodemProtocol;
  ctXmodemProtocol = object (XmodemProtocol)
    ProtWin : PView;
  end;

  ctKermitProtocolPtr = ^ctKermitProtocol;
  ctKermitProtocol = object (KermitProtocol)
    ProtWin : PView;
  end;

  ctAsciiProtocolPtr = ^ctAsciiProtocol;
  ctAsciiProtocol = object (AsciiProtocol)
    ProtWin : PView;
  end;

  ctScrType = ( {script engine var types}
  ctNone,
  ctPString,
  ctPWord,
  ctPLongInt,
  ctPDouble,
  ctPVarAssign
{$IFDEF UseParadox}
 ,ctPTable
{$ENDIF}
  );

  ctScrCommand = (                      {script commands}
  ctScrWaitFor,   {wait for string}
  ctScrSend,      {send string}
  ctScrGetResp,   {assign last response to string}
  ctScrSetResp,   {assign string to last response}
  ctScrSendCap,   {send string to capture file}
  ctScrGetBlock,  {assign last response to string}
  ctScrIfEqu,     {if left var = right var do next command}
  ctScrIfNotEqu,  {if left var <> right var do next command}
  ctScrIfLess,    {if left var < right var do next command}
  ctScrIfGreat,   {if left var > right var do next command}
  ctScrIfLessEq,  {if left var <= right var do next command}
  ctScrIfGreatEq, {if left var >= right var do next command}
  ctScrVarAsn,    {assign right var to left var}
  ctScrVarAdd,    {add right var to left var}
  ctScrVarSub,    {subtract right var from left var}
  ctScrVarMul,    {multiply left var by right var}
  ctScrVarDiv,    {divide left var by right var}
  ctScrSubStr,    {set last response to substring of last response}
  ctScrInpBox,    {input box}
  ctScrListBox,   {list box}
  ctScrInpWait,   {input box wait}
{$IFDEF UseParadox}
  ctScrFldGet,    {get field value}
  ctScrFldPut,    {put field value}
  ctScrBlobImp,   {import import.txt into blob memo field}
  ctScrBlobGet,   {get next line from blob memo field}
  ctScrBlobOpen,  {open blob memo field}
  ctScrBlobClose, {close blob memo field}
  ctScrRecSrcPri, {search generic record by primary key}
  ctScrRecSrcSec, {search generic record by secondary key}
  ctScrTabError,  {get last table error string}
  ctScrTabName,   {paradox table name}
  ctScrTabCreate, {create paradox table from data dictionary}
  ctScrTabOpen,   {open paradox table}
  ctScrTabClose,  {close paradox table}
  ctScrTabHome,   {move to table home}
  ctScrTabEnd,    {move to table end}
  ctScrTabNext,   {move to next record}
  ctScrTabPrev,   {move to previous record}
  ctScrRecDel,    {delete current record}
  ctScrRecGet,    {get generic record}
  ctScrRecPut,    {put generic record}
  ctScrRecClr,    {clear generic record}
  ctScrRecUpd,    {update generic record}
{$ENDIF}
  ctScrWaitSecs,  {set waitfor seconds}
  ctScrMouseX,    {get mouse x from last double click}
  ctScrMouseY,    {get mouse y from last double click}
  ctSrcDelayTics, {delay 1/18 sec system ticks}
  ctSrcConStat,   {return connect status}
  ctSrcPadRight,  {right pas last response}
  ctScrCall,      {jump to a label and save return address}
  ctScrReturn,    {return from call}
  ctScrGoto,      {jump to a label}
  ctScrLabel,     {create new label}
  ctScrCapApp,    {use term win's capture append file toggle routine}
  ctScrCapNew,    {use term win's capture overwrite file toggle routine}
  ctScrTxtOpen,   {open text file}
  ctScrEraseFil,  {erase file}
  ctScrUnZipFil,  {UnZip file}
  ctScrZmodemD,   {use term win's z modem download routine}
  ctScrZmodemU,   {use term win's z modem upload routine}
  ctScrXModemU,   {use term win's x modem upload routine}
  ctScrVarStr,    {create new string var}
  ctScrVarInt,    {create new integer var}
  ctScrVarDbl,    {create new double var}
{$IFDEF UseParadox}
  ctScrVarTab,    {create new paradox table cursor}
{$ENDIF}
  ctScrSepChar,   {set waitformulti string seperator}
  ctScrGetChar,   {add to getblock delim set}
  ctScrSubmit,    {submit script to que}
  ctScrSendLog,   {output string to log}
  ctScrSendList,  {add string to list box}
  ctScrCapOff,    {turn off term win's capture routine}
  ctScrTxtClose,  {close text file}
  ctScrTxtGet,    {get next line of text}
  ctScrDraw,      {draw term from buffer}
  ctScrDrawList,  {draw listbox}
  ctScrInit,      {use term win's init routine}
  ctScrDial,      {use term win's dial routine}
  ctScrHangUp,    {use term win's hang up routine}
  ctScrLogOn,     {turn log on}
  ctScrLogOff,    {turn log off}
  ctScrAbortOn,   {turn time out abort on}
  ctScrAbortOff,  {turn time out abort off}
  ctScrWriLogOn,  {turn time out abort on}
  ctScrWriLogOff, {turn time out abort off}
  ctScrEchoOn,    {turn time out abort on}
  ctScrEchoOff,   {turn time out abort off}
  ctScrLock,      {lock script processing}
  ctScrUnLock,    {unlock script processing}
  ctScrGetIni,    {get ini string and store in response}
  ctScrPutIni,    {put response string into ini file}
  ctScrOpenIni,   {open ini file}
  ctScrCloseIni,  {close ini file}
  ctScrEditFile,  {edit file}
  ctScrEnd        {end script}
  );

  PWord = ^word;
  PLongInt = ^longint;
  PDouble = ^double;

  PStackNode = ^TStackNode;
  TStackNode = object (TObject)
    Loc : word;
  end;

  PVarNode = ^TVarNode;
  TVarNode = object (TObject)
    VarType : ctScrType;
    VarDataPtr : pointer;
    VarName : PString;
  end;

  PVarAssign = ^TVarAssign;
  TVarAssign = record
    VarCur,
    VarNew : PVarNode;
  end;

{$IFDEF UseParadox}
  PVarTable = ^TVarTable;
  TVarTable = record
    TabName : PathStr;
    TabCur : PCursor;
  end;
{$ENDIF}

  PScriptNode = ^TScriptNode;
  TScriptNode = object (TObject)
    ScCommand  : ctScrCommand;
    ScDataPtr  : PVarNode;
  end;

  PScriptEng = ^TScriptEng;
  TScriptEng = object (TObject)
    TxtFileOpen : boolean;
    SepChar : char;
    LDouble,
    RDouble : byte;
    MouseX,
    MouseY : integer;
    ScriptState,
    CurCommand,
    WaitForSecs : word;
    WaitResp,
    LastResp : string;
    TxtFile : Text;
    GetBlockSet : CharSet;
    ScriptTimer : EventTimer;
    NodeCollPtr,
    VarCollPtr,
    StackCollPtr : PCollection;
    ScriptWin : PView;
    IniFile : PIni;
{$IFDEF UseParadox}
    BlobPos,
    BlobSiz : longint;
    DataBasePtr : PDataBase;
    EnginePtr : PEngine;
{$ENDIF}
    constructor Init (T : PView);
    destructor Done; virtual;
    procedure DisposeNodes; virtual;
    procedure LogErr (ErrStr : string); virtual;
    procedure PushAddr (NodeAddr : word);
    function PopAddr : word;
    procedure ProcessCommand; virtual;
    function AddCommand (Node : PScriptNode) : boolean; virtual;
    function AddVar (Node : PVarNode) : boolean; virtual;
    function GetVarPtr (VName : string) : PVarNode; virtual;
    procedure LogCommand; virtual;
  end;

  PLabelNode = ^TLabelNode;
  TLabelNode = object (TObject)
    Loc : word;
    Name : PString;
  end;

  PScriptCompile = ^TScriptCompile;
  TScriptCompile = object (TObject)
    CurLine,
    CurChar,
    LastChar,
    NodeNum : word;
    CmdStr,
    ParStr : string;
    CmdNum : ctScrCommand;
    LabelCollPtr : PCollection;
    TWin : PView;
    EditWin : PCyEditWindow;
    ScriptEng : PScriptEng;
    constructor Init (E : PCyEditWindow; T : PView);
    destructor Done; virtual;
    function AddLabel (Node : PLabelNode) : boolean; virtual;
    function GetLabelPtr (LName : string) : PLabelNode; virtual;
    function GetLine (var TempStr : string) : boolean; virtual;
    procedure LogErr (ErrStr : string); virtual;
    procedure ParseLine (S : string); virtual;
    function FindCommand : boolean; virtual;
    function Pass1 (S : string) : boolean; virtual;
    function Pass2 (S : string) : boolean; virtual;
    function Compile : boolean; virtual;
  end;

  PScriptQue = ^TScriptQue;
  TScriptQue = object (TObject)
    LastDone : boolean;
    QueColl : PCollection;
    TermWin : PView;
{$IFDEF UseParadox}
    DataBasePtr : PDataBase;
    EnginePtr : PEngine;
{$ENDIF}
    constructor Init;
    destructor Done; virtual;
    procedure AddToQue (FileName : PathStr);
    procedure DoTask;
  end;

  PTermRec = ^TTermRec;
  TTermRec = object (TObject)
    Name,
    PhoneNum : string[25];
    DLPath : PathStr;
    InitStr : string[30];
    ComName : ComNameType;
    Baud : longint;
    Parity : ParityType;
    DataBits : DataBitType;
    StopBits : StopBitType;
    ComOptions,
    TermOpts : word;
    constructor Load (var S : TStream);
    procedure Store (var S : TStream); virtual;
  end;

  PTermGenOptsRec = ^TTermGenOptsRec;
  TTermGenOptsRec = record
    TermWidth,
    TermLen,
    TermDraw,
    InBuf,
    OutBuf,
    WaitCTS,
    WaitResp,
    WaitDTR,
    DialWait,
    DialPause,
    Redial : word;
    CancelChar : char;
    DialPrefix : string [20];
    RespOK,
    RespError,
    RespConnect,
    RespNoCarr,
    RespNoAns,
    RespBusy,
    RespVoice,
    RespRing,
    RespNoTone,
    RespCarrier : string[30];
  end;

  ctEmuState = ( {emulator states}
  ctWaiting,
  ctEscCode,
  ctAnsiParse,
  ctKeyParse,
  ctG0Parse,
  ctG1Parse
  );

  ctEmuCommands = (                {commands returned by emulator}
  ctEmuNone,         {char was used by emulator, ignore}
  ctEmuChar,         {display char}
  ctEmuGotoXY,       {goto x,y cursor position}
  ctEmuUp,           {cursor up}
  ctEmuDown,         {cursor down}
  ctEmuRight,        {cursor right}
  ctEmuLeft,         {cursor left}
  ctEmuClrBelow,     {clear screen below cursor}
  ctEmuClrAbove,     {clear screen above cursor}
  ctEmuClrScr,       {clear screen}
  ctEmuClrEndLine,   {clear from cursor to end of line}
  ctEmuClrStartLine, {clear from cursor to the start of line}
  ctEmuClrLine,      {clear line}
  ctEmuSetMode,      {set video mode}
  ctEmuInsLine,      {insert lines}
  ctEmuDelLine,      {delete lines}
  ctEmuInsChar,      {insert chars}
  ctEmuDelChar,      {delete chars}
  ctEmuResetMode,    {reset video mode}
  ctEmuSetAttr,      {set video attribute }
  ctEmuSaveCurPos,   {save cursor position}
  ctEmuResCurPos,    {restore cursor position}
  ctEmuDevStatRep,   {report device status}
  ctEmuKeyRemap,     {remap ibm keyboard}
  ctEmuCRLF,         {cr/lf combo}
  ctEmuSetTabStop,   {set tab stop}
  ctEmuPowerOn,      {set defaults to power on}
  ctEmuError         {error}
  );

  ctChrMode = (
    ctASCII,
    ctLineDrawing
  );

  PAnsiEmu = ^TAnsiEmu;
  TAnsiEmu = object (TObject)
    X,
    Y,
    Attr,
    SaveAttr,
    ChrMask : byte;
    AnsiOptions,
    ParamIndex : word;
    AnsiState : ctEmuState;
    AnsiCmd : ctEmuCommands;
    AnsiChr : char;
    ParStr,
    KeyStr : string;
    G0CharSet,
    G1CharSet : ctChrMode;
    CurCharSet : ^ctChrMode;
    IntParam : ctIntParam;
    constructor Init (TxtColor : word);
    procedure ProcessChar (C : Char); virtual;
  end;

  PAnsiTerm = ^TAnsiTerm;
  TAnsiTerm = object (TScroller)
    XBuf,
    YBuf,
    DrawColor,
    BufChars,
    SaveCurX,
    SaveCurY,
    SaveAttr,
    LineLen,
    Lines,
    LineSize,
    MaxBufChars,
    TermOptions : word;
    DrawBuf : ctScrBufPtr;
    UPortPtr : ctUartPortPtr;
    AnsiEmu : TAnsiEmu;
    constructor Init(var Bounds: TRect; AHScrollBar, AVScrollBar : PScrollBar;
                     GenOptsPtr : PTermGenOptsRec; APort : ctUartPortPtr);
    destructor Done; virtual;
    procedure Draw; virtual;
    procedure AdjustBuffer; virtual;
    procedure TrackCursor; virtual;
    procedure PutViewChar; virtual;
    procedure SetAttr; virtual;
    procedure SetBufXY; virtual;
    procedure ClearScr; virtual;
    procedure ClearBelow; virtual;
    procedure ClearAbove; virtual;
    procedure ClearEOL; virtual;
    procedure ClearSOL; virtual;
    procedure ClearLine; virtual;
    procedure Up; virtual;
    procedure Down; virtual;
    procedure Left; virtual;
    procedure Right; virtual;
    procedure SaveCurPos; virtual;
    procedure RestoreCurPos; virtual;
    procedure DeviceStatus; virtual;
    procedure CRLF; virtual;
    procedure ProcAnsiChar (C : char); virtual;
    function GetTextStr (X, Y : integer) : string; virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  ctZmodemInit = (
    ctGotNone,
    ctGotr,
    ctGotz
  );

  PTermWin = ^TTermWin;
  TTermWin = object (TDialog)
    CaptureOn,
    WriteLogOn : boolean;
    RespFound : byte;
    CapBufPos,
    RedialCnt,
    ProtocolNum : word;
    CmdState,
    FileListSize,
    ConnectBaud : longint;
    RateStr,
    RespStr,
    RespWaitStr,
    OkStr : string;
    CapFileName : PathStr;
    CapFile : file;
    CapFileBuf : array [0..ctCapBufSize-1] of byte;
    TermTimer : EventTimer;
    TermRec : PTermRec;
    GenOptsRec : PTermGenOptsRec;
    UPort : ctUartPort;
    Protocol : AbstractProtocolPtr;
    UploadList : FileListPtr;
    FileListColl : PStringCollection;
    Term : PAnsiTerm;
    ScriptEng : PScriptEng;
    ScriptQue : TScriptQue;
    ZmodemDet : ctZmodemInit;
    constructor Init (WinTitle : TTitleStr; TermRecPtr : PTermRec;
                      GenOptsPtr : PTermGenOptsRec);
    destructor Done; virtual;
    procedure WaitCTSLow; virtual;
    procedure HangUp; virtual;
    procedure UpdateLog (S : string); virtual;
    procedure UpdateLogRaw (S : string; PosQue : word); virtual;
    procedure GetResp; virtual;
    procedure PutCmd (Cmd, Resp : string; RSecs : word); virtual;
    procedure InitXfer; virtual;
    function XferStatusStr : string; virtual;
    procedure XferTask; virtual;
    procedure InitModem; virtual;
    procedure DialLog (Raw : boolean); virtual;
    procedure Dial; virtual;
    procedure DialPause; virtual;
    procedure GenPause; virtual;
    procedure GetConnectRate; virtual;
    procedure ProcessScript; virtual;
    procedure IdleTask; virtual;
    procedure Capture (FName : PathStr; Cmd : word); virtual;
    procedure CaptureClose; virtual;
    procedure WriteCapFile (C : char); virtual;
    procedure SetState (AState : word; Enable : boolean); virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
    function Valid (Command : word) : boolean; virtual;
  end;

  PPhoneCollection = ^TPhoneCollection;
  TPhoneCollection = object (TSortedCollection)
    function KeyOf (Item : pointer) : pointer; virtual;
    function Compare (Key1, Key2 : pointer) : integer; virtual;
  end;

  TTermListBoxRec = record
    List : PPhoneCollection;
    Selection : Word;
  end;

  PTermListBox = ^TTermListBox;
  TTermListBox = object (TCySortedListBox)
    function GetText (Item : integer; MaxLen : integer) : string; virtual;
  end;

  TTermConfigDlgRec = record
    PhoneList : TTermListBoxRec;
    Name,
    PhoneNum : string[25];
    DLPath : PathStr;
    InitStr : string[128];
    ComPort,
    Baud,
    DataBits,
    Parity,
    StopBits,
    TermOpts : integer;
  end;

  PTermConfigDlg = ^TTermConfigDlg;
  TTermConfigDlg = object (TDialog)
    PhoneCollPtr : PPhoneCollection;
    NameLine,
    PhoneLine,
    PathLine,
    InitLine : PInputLine;
    ComButtons,
    BaudButtons,
    DataButtons,
    ParityButtons,
    StopButtons : PRadioButtons;
    OptBoxes : PCheckBoxes;
    FieldBox : PTermListBox;
    constructor Init;
    procedure AddRec; virtual;
    procedure DeleteRec; virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  TTermGenDlgRec = record
    TermWidthStr,
    TermLenStr,
    TermDrawStr,
    InBufStr,
    OutBufStr,
    WaitCTSStr : string [6];
    DialPrefixStr : string [20];
    DialWaitStr,
    DialPauseStr,
    RedialStr : string[6];
    RespOKStr,
    RespErrorStr,
    RespConnectStr,
    RespNoCarrStr,
    RespNoAnsStr,
    RespBusyStr,
    RespVoiceStr,
    RespRingStr,
    RespNoToneStr,
    RespCarrierStr : string[30];
    CancelCharStr,
    WaitRespStr,
    WaitDTRStr : string [6];
  end;

  PTermGenDlg = ^TTermGenDlg;
  TTermGenDlg = object (TDialog)
    constructor Init;
  end;

  PScrQueNode = ^TScrQueNode;
  TScrQueNode = object (TObject)
    ScrName : PathStr;
  end;

  PTermInpDlg = ^TTermInpDlg;
  TTermInpDlg = object (TDialog)
    MsgSent : boolean;
    ComName : ComNameType;
    TermInp : PInputLine;
    constructor Init (C : ComNameType; I, L : string);
    procedure Close; virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  PTermListDlg = ^TTermListDlg;
  TTermListDlg = object (TDialog)
    MsgSent : boolean;
    ComName : ComNameType;
    StrList : PStringCollection;
    StrBox : PCySortedListBox;
    constructor Init (C : ComNameType; T : string);
    destructor Done; virtual;
    procedure Close; virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

procedure GenDlgToGenOpts (GenDlg : TTermGenDlgRec; var GenOpts : TTermGenOptsRec);
procedure RegisterTerm;

const

  RTermRec : TStreamRec = (           {registration record for term rec}
    ObjType: rsTermRec;
    VmtLink: Ofs(TypeOf(TTermRec)^);
    Load: @TTermRec.Load;
    Store: @TTermRec.Store);

  RPhoneCollection : TStreamRec = (   {registration record for phone collection}
    ObjType: rsPhoneColl;
    VmtLink: Ofs(TypeOf(TPhoneCollection)^);
    Load: @TSortedCollection.Load;    {no need to add new load/store}
    Store: @TSortedCollection.Store);

implementation

const

  {script language commands (key words) for compiler}

  ctScrCommands : array [ctScrWaitFor..ctScrEnd] of string[20] = (
  'WAITFOR',
  'SEND',
  'GETRESP',
  'SETRESP',
  'SENDCAPTURE',
  'GETBLOCK',
  'IF=',
  'IF<>',
  'IF<',
  'IF>',
  'IF<=',
  'IF>=',
  'ASSIGN',
  'ADD',
  'SUB',
  'MUL',
  'DIV',
  'SUBSTRRESP',
  'INPUTBOX',
  'LISTBOX',
  'INPUTBOXWAIT',
{$IFDEF UseParadox}
  'FIELDGET',
  'FIELDPUT',
  'BLOBIMPORT',
  'BLOBGET',
  'BLOBOPEN',
  'BLOBCLOSE',
  'SEARCHPRIMARY',
  'SEARCHSECONDARY',
  'TABLEERROR',
  'TABLENAME',
  'TABLECREATE',
  'TABLEOPEN',
  'TABLECLOSE',
  'TABLEHOME',
  'TABLEEND',
  'TABLENEXT',
  'TABLEPREV',
  'RECORDDELETE',
  'RECORDGET',
  'RECORDPUT',
  'RECORDCLEAR',
  'RECORDUPDATE',
{$ENDIF}
  'WAITFORSECS',
  'MOUSEX',
  'MOUSEY',
  'DELAY',
  'CONNECTSTATUS',
  'PADRIGHTRESP',
  'CALL',
  'RETURN',
  'GOTO',
  'LABEL',
  'CAPTUREAPP',
  'CAPTURENEW',
  'OPENTEXTREAD',
  'ERASEFILE',
  'UNZIPFILE',
  'DOWNLOADZMODEM',
  'UPLOADZMODEM',
  'UPLOADXMODEM',
  'STRING',
  'LONGINT',
  'DOUBLE',
{$IFDEF UseParadox}
  'TABLE',
{$ENDIF}
  'WAITFORSEPCHAR',
  'ADDGETDELIM',
  'SUBMIT',
  'SENDLOG',
  'SENDLIST',
  'CAPTUREOFF',
  'CLOSETEXTREAD',
  'GETTEXT',
  'DRAW',
  'DRAWLISTBOX',
  'INIT',
  'DIAL',
  'HANGUP',
  'LOGON',
  'LOGOFF',
  'ABORTON',
  'ABORTOFF',
  'LOGSYSON',
  'LOGSYSOFF',
  'ECHOON',
  'ECHOOFF',
  'LOCK',
  'UNLOCK',
  'GETINI',
  'PUTINI',
  'OPENINI',
  'CLOSEINI',
  'EDITFILE',
  'END'
  );

{
Convert general options dialog data to a format the application uses.
}

procedure GenDlgToGenOpts (GenDlg : TTermGenDlgRec; var GenOpts : TTermGenOptsRec);

begin
  with GenDlg do
    with GenOpts do
    begin
      TermWidth   := StrToInt (TermWidthStr);
      TermLen     := StrToInt (TermLenStr);
      TermDraw    := StrToInt (TermDrawStr);
      InBuf       := StrToInt (InBufStr);
      OutBuf      := StrToInt (OutBufStr);
      WaitCTS     := StrToInt (WaitCTSStr);
      DialWait    := StrToInt (DialWaitStr);
      DialPause   := StrToInt (DialPauseStr);
      Redial      := StrToInt (RedialStr);
      WaitResp    := StrToInt (WaitRespStr);
      WaitDTR     := StrToInt (WaitDTRStr);
      CancelChar  := char (StrToInt (CancelCharStr));
      DialPrefix  := UpCaseStr (DialPrefixStr);
      RespOK      := RespOKStr;
      RespError   := RespErrorStr;
      RespConnect := RespConnectStr;
      RespNoCarr  := RespNoCarrStr;
      RespNoAns   := RespNoAnsStr;
      RespBusy    := RespBusyStr;
      RespVoice   := RespVoiceStr;
      RespRing    := RespRingStr;
      RespNoTone  := RespNoToneStr;
      RespCarrier := RespCarrierStr
    end
end;

{
Register term objects for stream access.
}

procedure RegisterTerm;

begin
  RegisterType (RPhoneCollection);
  RegisterType (RTermRec)
end;

{
Protocol log file procedure.  I was forced to use a non-OOP approach for the
following routine because Turbo Power's use of a procedural 'hook' instead of
a virtual method. :(  This is also why I had to decend each protocol object.
}

procedure ctLogStatus (AP : AbstractProtocolPtr; LogFileStatus : LogFileType); far;

var

  TWin : PTermWin;

begin
  case AP^.GetProtocol of     {get protocol's term window}
    Zmodem            : TWin := PTermWin (ctZmodemProtocolPtr (AP)^.ProtWin);
    Ymodem..YModemG   : TWin := PTermWin (ctYmodemProtocolPtr (AP)^.ProtWin);
    Xmodem..Xmodem1KG : TWin := PTermWin (ctXmodemProtocolPtr (AP)^.ProtWin);
    Kermit            : TWin := PTermWin (ctKermitProtocolPtr (AP)^.ProtWin);
    Ascii             : TWin := PTermWin (ctAsciiProtocolPtr (AP)^.ProtWin)
  end;
  case LogFileStatus of       {update term window's log}
    lfReceiveStart, lfTransmitStart :
    begin
      TWin^.UpdateLog ('  '); {indent file status in log}
      TWin^.CmdState := TWin^.CmdState or ctCmdXferStat {ok to auto update log status}
    end;
    lfReceiveOk, lfReceiveFail, lfReceiveSkip,
    lfTransmitOk, lfTransmitFail, lfTransmitSkip :
    begin
      if TWin^.Protocol^.BytesTransferred > 0 then
        TWin^.UpdateLogRaw (TWin^.XferStatusStr+' '+StatusStr (GetAsyncStatus),0);
      TWin^.CmdState := TWin^.CmdState and not ctCmdXferStat
    end
  end;
end;

{
Accept file procedure checks for duplicate names and generates unique
file name suffix from '00' to '99'.
}

function ctAcceptFile (AP : AbstractProtocolPtr) : boolean; far;

var

  I, IoError : integer;
  FileName,
  TempStr : PathStr;
  F : File;

begin
  I := 0;
  FileName := AP^.GetFileName;
  repeat
    Assign (F,FileName);
    {$I-} Reset (F); {$I+}
    IoError := IoResult;
    if IoError = 0 then
    begin
      {$I-} Close (F); {$I+}
      TempStr := PadRightStr (GetFileNameStr (FileName),'0',8);
      byte (TempStr[7]) := I div 10+byte('0');
      byte (TempStr[8]) := I mod 10+byte('0');
      FileName := TempStr+GetExtStr (FileName);
      Inc (I)
    end;
  until (IoError <> 0) or (I > 99);
  AP^.SetReceiveFilename (FileName);
  ctAcceptFile := (IoError <> 0)
end;

{
Another 'hook' to handle chars during WaitForChar/String.
}

procedure ctWaitChar (APPtr : AbstractPortPtr; C : Char); far;

var

  TWin : PTermWin;

begin
  TWin := PTermWin (ctUartPortPtr (APPtr)^.UartWin);
  TWin^.Term^.ProcAnsiChar (C); {process with emulator}
  if ((TWin^.Term^.BufChars > 0) and (not TWin^.UPort.CharReady)) or
  (TWin^.Term^.BufChars > TWin^.Term^.MaxBufChars) then
  begin
    TWin^.Term^.TrackCursor;
    TWin^.Term^.DrawView;
    TWin^.Term^.BufChars := 0
  end
end;

{
UART port user abort checks the term win's command state for abort flag.
This is used instead of a procedural 'hook' since AbstractPort.UserAbort
calls the procedural hook.
}

function ctUartPort.UserAbort : boolean;

var

  TWin : PTermWin;

begin
  TWin := PTermWin (UartWin);
  if TWin^.CmdState and ctCmdXferAbort = 0 then
    UserAbort := false
  else
  begin
    TWin^.CmdState := TWin^.CmdState and not ctCmdXferAbort;
    UserAbort := true
  end
end;

{
Handle terminal window local echo.
}

procedure ctUartPort.PutString (S : string);

var

  I : integer;
  TWin : PTermWin;

begin
  inherited PutString (S);
  TWin := PTermWin (UartWin);
  with TWin^.Term^ do
    if (TermOptions and ctLocalEcho <> 0) and
    (TWin^.CmdState and ctCmdXfer = 0) then
    begin {echo to terminal}
      for I := 1 to byte (S[0]) do
        PTermWin (UartWin)^.Term^.ProcAnsiChar (S[I]) {process with emulator}
    end
end;

{
Like WaitForMultiString that can be called without eating possible matches
because of time out.  This will allow it to be polled in an event driven
enviornment. :)
}

procedure ctUartPort.ScanForMultiString (SL : string; SepChar : char;
                                        var FoundS : string;
                                        var FoundI : byte);
const

  MaxSubs = 128;

var

  C : char;
  I, CMask : byte;
  SubCnt : byte;
  CurSub : byte;
  LastIndex : byte;
  Candidate : array[1..MaxSubs] of boolean;
  SubPos : array[1..MaxSubs] of byte;
  FirstChar : array[1..MaxSubs] of char;
  CurBufPos, BufPos : word;
  TWin : PTermWin;

{return true if a full match of any substring is found}

function MatchOneChar(MC : Char) : Boolean;

var

  I : byte;
  Index : byte;
  CurFound : boolean;
  SubIndex : byte;

begin
  Index := 1;
  SubIndex := 1;
  CurSub := 1;
  CurFound := false;
  MatchOneChar := false;
  for I := 1 to byte (SL[0]) do
    if SL[I] = SepChar then
    begin {end of substring}
      if not CurFound then
        Candidate[CurSub] := false {last substring didn't match char}
      else
        if Candidate[CurSub] then
        begin {prepare for next position}
          if SubPos[CurSub] = SubIndex-1 then
          begin {last substr was a last char match}
            MatchOneChar := true;
            LastIndex := CurSub
          end
          else {set for next position}
            Inc (SubPos[CurSub])
        end;
      Inc (CurSub); {prepare for next substring}
      SubIndex := 1
    end
    else
    begin {wait for right pos in substring}
      if SubIndex = SubPos[CurSub] then {found right position}
        if MC <> SL[I] then
        begin {failed match at sub pos}
          Candidate[CurSub] := false;
          SubPos[CurSub] := 1;
          if FirstChar[CurSub] = MC then
          begin {check again for possible match at position 1}
            Candidate[CurSub] := true;
            CurFound := true
          end
        end
        else
        begin {match this pos and sub str}
          CurFound := true;
          Candidate[CurSub] := true;
          if I = Length(SL) then
          begin {handle end of string}
            MatchOneChar := true;
            LastIndex := CurSub
          end
        end;
      Inc (SubIndex)
    end;
  if not CurFound then {handle candidate at end of string}
    Candidate[CurSub] := false
  else
    if Candidate[CurSub] then
    begin {prepare for next position}
      if (SubPos[CurSub] = SubIndex-1) then
      begin {last sub str was a last char match}
        MatchOneChar := true;
        LastIndex := CurSub
      end
      else {set for next position}
        Inc(SubPos[CurSub])
    end;
  BufPos := SubCnt;
  while (BufPos > 0) and (not Candidate [BufPos]) do {see if any candidates}
    Dec (BufPos);
  if BufPos = 0 then {eat char if no candidates}
  begin
    Dec (CurBufPos); {adjust peek position}
    GetChar (C);
    WaitChar (@Self,C)
  end
end;

{return substring given index}

function ExtractString (Index : byte) : string;

var

  I : byte;
  StartLoc : byte;
  S : string;
  Len : byte;
  SCnt : byte;

begin
  StartLoc := 1;
  SCnt := 0;
  I := 1;
  while (I <= Length(SL)) do {find the index'th delim}
    if (SL[I] = SepChar) or (I = byte (SL[0])) then
    begin
      Inc (SCnt);
      if SCnt = Index then
      begin {extract string}
        if (SL[I] <> SepChar) and (I = byte (SL[0])) then
          Len := (I-StartLoc)+1
        else
          Len := I-StartLoc;
        Move (SL[StartLoc], S[1], Len);
        S[0] := Char (Len);
        ExtractString := S;
        Exit
      end
      else
      begin
        StartLoc := I+1;
        Inc (I)
      end
    end
    else
      Inc (I);
  ExtractString := ''
end;

begin
  TWin := PTermWin (UartWin);
  if TWin^.TermRec^.TermOpts and ctStripHi = 0 then
    CMask := $ff
  else
    CMask := $7f;
  AsyncStatus := 0; {init vars}
  FoundS := '';
  FoundI := 0;
  CurBufPos := 1;
  if SL = '' then {check for empty string}
    GotError (epNonFatal+ecInvalidArgument);
  if FlagIsSet (PR^.Flags,ptIgnoreDelimCase) then {upcase target string}
    for I := 1 to byte (SL[0]) do
      SL[I] := Upcase(SL[I]);
  SubCnt := 1; {find number of substrings and save first char of each substring}
  FirstChar[1] := SL[1];
  for I := 1 to byte (SL[0]) do
    if SL[I] = SepChar then
    begin
      Inc (SubCnt);
      if I < 255 then
        FirstChar[SubCnt] := SL[I+1]
    end;
  if (SubCnt > 255) or (SubCnt = 0) then
    GotError (epNonFatal+ecInvalidArgument);
  FillChar (Candidate, MaxSubs, 0); {init arrays}
  FillChar (SubPos, MaxSubs, 1);
  PeekChar (C,CurBufPos); {get next char}
  byte (C) := byte (C) and CMask;
  while AsyncStatus = ecOk do
  begin
    if FlagIsSet (PR^.Flags,ptIgnoreDelimCase) then
      C := Upcase (C); {upcase char}
    if MatchOneChar (C) then
    begin {found a complete match}
      FoundI := LastIndex;
      FoundS := ExtractString (LastIndex);
      for BufPos := 1 to CurBufPos do {eat buffer}
      begin
        GetChar (C);
        WaitChar (@Self, C)
      end;
      Exit
    end;
    Inc (CurBufPos);
    PeekChar (C,CurBufPos); {get next char}
    byte (C) := byte (C) and CMask
  end
end;

{
TScriptEng is a script engine that uses a TScriptNode collection to drive the
engine.  Dynamic vars are stored in a TVarNode collection.  Dynamic run time
call stack also implemented.
}

{
Create collections and set default engine values.
}

constructor TScriptEng.Init (T : PView);

begin
  inherited Init;
  ScriptWin := T;
  NodeCollPtr := New (PCollection,Init (0,50));  {script node collection}
  VarCollPtr := New (PCollection,Init (0,50));   {var node collection}
  StackCollPtr := New (PCollection,Init (0,10)); {stack node collection}
  SepChar := ctSepChar; {waitformulti seperator char}
  GetBlockSet := [];    {getblock delim set}
  WaitForSecs := 60;    {waitfor time in secs}
  LDouble := 10;        {decimals to the left of .}
  RDouble := 2;         {decimals to the right of .}
  TxtFileOpen := false  {text file not open}
end;

{
Dispose script node collection.
}

destructor TScriptEng.Done;

begin
  DisposeNodes;
  if TxtFileOpen then {close text file if open}
    {$I-} SYSTEM.Close (TxtFile); {$I+}
  if IniFile <> nil then
    Dispose (IniFile,Done);
  inherited Done
end;

{
Dispose script/var nodes and data inside them.
}

procedure TScriptEng.DisposeNodes;

{dispose of dynamic vars and var names}

procedure KillData (Item : pointer); far;

var

  V : PVarNode;

begin
  V := PVarNode (Item);
  if V^.VarDataPtr <> nil then
    case V^.VarType of     {dispose by var type}
      ctPString    : DisposeStr (PString (V^.VarDataPtr));
      ctPWord      : Dispose (PWord (V^.VarDataPtr));
      ctPLongInt   : Dispose (PLongInt (V^.VarDataPtr));
      ctPDouble    : Dispose (PDouble (V^.VarDataPtr));
      ctPVarAssign : Dispose (PVarAssign (V^.VarDataPtr))
{$IFDEF UseParadox}
      ;ctPTable    :
      begin {dispose table cursor and table var}
        if PVarTable (V^.VarDataPtr)^.TabCur <> nil then
          Dispose (PVarTable (V^.VarDataPtr)^.TabCur,Done);
        Dispose (PVarTable (V^.VarDataPtr))
      end
{$ENDIF}
    end;
  if V^.VarName <> nil then {dispose name str}
    DisposeStr (V^.VarName)
end;

begin
  if VarCollPtr <> nil then
  begin
    VarCollPtr^.ForEach (@KillData); {dispose node data before collection}
    Dispose (VarCollPtr,Done);       {dispose var nodes}
    VarCollPtr := nil
  end;
  if NodeCollPtr <> nil then         {dispose script nodes}
  begin
    Dispose (NodeCollPtr,Done);
    NodeCollPtr := nil
  end;
  if StackCollPtr <> nil then        {dispose call stack}
  begin
    Dispose (StackCollPtr,Done);
    StackCollPtr := nil
  end
end;

{
Show error in log and halt engine.
}

procedure TScriptEng.LogErr (ErrStr : string);

begin
  with PTermWin (ScriptWin)^ do
  begin
    UpdateLog ('Script engine error: '+ErrStr);
    CmdState := CmdState and not ctCmdScript {halt engine processing}
  end
end;

{
Push node location on LIFO stack.
}

procedure TScriptEng.PushAddr (NodeAddr : word);

var

  S : PStackNode;

begin
  if StackCollPtr^.Count < 16000 then
  begin
    S := New (PStackNode, Init);
    S^.Loc := NodeAddr;
    StackCollPtr^.Insert (S); {add node to end of list}
    if LowMemory then
      LogErr ('stack out of memory')
  end
  else
    LogErr ('stack overflow')
end;

{
Pop node location from LIFO stack
}

function TScriptEng.PopAddr : word;

var

  S : PStackNode;

begin
  if StackCollPtr^.Count > 0 then
  begin
    S := StackCollPtr^.At (StackCollPtr^.Count-1); {last node}
    PopAddr := S^.Loc;
    StackCollPtr^.Free (S) {dispose stack node}
  end
  else
    LogErr ('stack empty')
end;

{
Handle current script command in collection.
}

procedure TScriptEng.ProcessCommand;

var

  N : PScriptNode;
  V : PVarNode;

procedure TimeOut;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if ScriptState and ctScrStAbort <> 0 then
    begin
      UpdateLog ('All scripts aborted');
      ScriptQue.QueColl^.FreeAll;
      CmdState := (CmdState and not ctCmdScript) or ctCmdHangUp
    end
  end
end;

{wait for string or time out}

procedure ScrWaitFor;

var

  RespFnd : byte;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if ScriptState and ctScrStWaitFor <> 0 then
    begin
      if not TimerExpired (ScriptTimer) then
      begin
        UPort.ScanForMultiString (WaitResp,SepChar,LastResp,RespFnd);
        if RespFnd > 0 then {match found}
        begin
          ScriptState  := ScriptState and not ctScrStWaitFor;
          Inc (CurCommand)
        end
      end
      else {no match found before time out}
      begin
        UpdateLog ('WaitFor time out');
        LastResp := '';
        ScriptState  := ScriptState and not ctScrStWaitFor;
        TimeOut;
        Inc (CurCommand)
      end
    end
    else {init waitfor}
    begin
      if V^.VarDataPtr <> nil then
      begin
        LogCommand;
        case V^.VarType of {convert all var types to string}
          ctPString  : WaitResp := PString (V^.VarDataPtr)^;
          ctPLongInt : WaitResp := IntToStr (PLongInt (V^.VarDataPtr)^);
          ctPDouble  : WaitResp := TrimStr (DblToStr (PDouble (V^.VarDataPtr)^,
                       LDouble,RDouble))
        end;
        NewTimerSecs (ScriptTimer,WaitForSecs); {start timer}
        ScriptState  := ScriptState or ctScrStWaitFor
      end
      else {null var}
      begin
        ScriptState  := ScriptState and not ctScrStWaitFor;
        Inc (CurCommand)
      end
    end
  end
end;

{get block of chars with/without dilim}

procedure ScrGetBlock;

var

  BlkBytes : word;
  I : byte;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if ScriptState and ctScrStWaitFor <> 0 then
    begin
      if not TimerExpired (ScriptTimer) then
      begin
        UPort.GetBlockDirect (LastResp[1],
        PLongInt (V^.VarDataPtr)^,BlkBytes,GetBlockSet);
        if AsyncStatus = ecOK then {match found}
        begin
          byte (LastResp[0]) := BlkBytes; {string length}
          if PLongInt (V^.VarDataPtr)^ = 0 then
            Dec (byte (LastResp[0]));     {set length to exclude delim}
          for I := 1 to BlkBytes do {echo to emulator}
            Term^.ProcAnsiChar (LastResp[I]);
          ScriptState  := ScriptState and not ctScrStWaitFor;
          Inc (CurCommand)
        end
      end
      else {no match found before time out}
      begin
        UpdateLog ('GetBlock time out');
        LastResp := '';
        ScriptState  := ScriptState and not ctScrStWaitFor;
        TimeOut;
        Inc (CurCommand)
      end
    end
    else   {start time out timer}
    begin
      LogCommand;
      if PLongInt (V^.VarDataPtr)^ > 255 then {handle overflow}
        PLongInt (V^.VarDataPtr)^ := 255; {set to max block size}
      NewTimerSecs (ScriptTimer,WaitForSecs);
      ScriptState  := ScriptState or ctScrStWaitFor
    end
  end
end;

{send string out port}

procedure ScrSend;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then {convert all var types to string}
    begin
      case V^.VarType of
        ctPString  : UPort.PutString (PString (V^.VarDataPtr)^);
        ctPLongInt : UPort.PutString (IntToStr (PLongInt (V^.VarDataPtr)^));
        ctPDouble  : UPort.PutString (TrimStr (DblToStr (PDouble (V^.VarDataPtr)^,
                     LDouble,RDouble)))
      end
    end;
    Inc (CurCommand)
  end
end;

{get response from waitfor or getblock}

procedure ScrGetResp;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if LastResp <> '' then       {assign response}
    begin
      case V^.VarType of
        ctPString  :
        begin
          if V^.VarDataPtr <> nil then {dispose old var}
            DisposeStr (PString (V^.VarDataPtr));
          V^.VarDataPtr := NewStr (LastResp)
        end;
        ctPLongInt : PLongInt (V^.VarDataPtr)^ := StrToInt (TrimStr (LastResp));
        ctPDouble  : PDouble (V^.VarDataPtr)^ := StrToDbl (TrimStr (LastResp))
      end
    end
    else
    begin {null response}
      case V^.VarType of
        ctPString  :
        begin
          if V^.VarDataPtr <> nil then {dispose old var}
            DisposeStr (PString (V^.VarDataPtr));
          V^.VarDataPtr := nil
        end;
        ctPLongInt : PLongInt (V^.VarDataPtr)^ := 0;
        ctPDouble  : PDouble (V^.VarDataPtr)^ := 0.0
      end
    end;
    LogCommand;
    Inc (CurCommand)
  end
end;

{set response string}

procedure ScrSetResp;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if V^.VarDataPtr <> nil then {dispose old var}
    begin
      case V^.VarType of
        ctPString  : LastResp := PString (V^.VarDataPtr)^;
        ctPLongInt : LastResp := IntToStr (PLongInt (V^.VarDataPtr)^);
        ctPDouble  : LastResp := TrimStr (DblToStr (PDouble (V^.VarDataPtr)^,
                     LDouble,RDouble))
      end
    end
    else
      LastResp := '';
    LogCommand;
    Inc (CurCommand)
  end
end;

{send string to opened capture file}

procedure ScrSendCap;

var

  I : byte;
  TempStr : string;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if V^.VarDataPtr <> nil then
    begin
      case V^.VarType of
        ctPString  : TempStr := PString (V^.VarDataPtr)^;
        ctPLongInt : TempStr := IntToStr (PLongInt (V^.VarDataPtr)^);
        ctPDouble  : TempStr := TrimStr (DblToStr (PDouble (V^.VarDataPtr)^,
                     LDouble,RDouble))
      end;
      for I := 1 to byte (TempStr[0]) do
        Message (Owner,evBroadcast,cmTermCapChar,@TempStr[I]) {capture}
    end;
    LogCommand;
    Inc (CurCommand)
  end
end;

{boolean commands}

procedure ScrIf;

var

  BoolOk : boolean;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      case VarCur^.VarType of
        ctPString : {string boolean functions}
        begin
          if (VarCur^.VarDataPtr <> nil) and
          (VarNew^.VarDataPtr <> nil) then {both strings <> nil}
          begin
            case N^.ScCommand of {eval and set boolean flag}
              ctScrIfEqu :
                BoolOk := PString (VarCur^.VarDataPtr)^ =
                PString (VarNew^.VarDataPtr)^;
              ctScrIfNotEqu :
                BoolOk := PString (VarCur^.VarDataPtr)^ <>
                PString (VarNew^.VarDataPtr)^;
              ctScrIfLess :
                BoolOk := PString (VarCur^.VarDataPtr)^ <
                PString (VarNew^.VarDataPtr)^;
              ctScrIfGreat :
                BoolOk := PString (VarCur^.VarDataPtr)^ >
                PString (VarNew^.VarDataPtr)^;
              ctScrIfLessEq :
                BoolOk := PString (VarCur^.VarDataPtr)^ <=
                PString (VarNew^.VarDataPtr)^;
              ctScrIfGreatEq :
                BoolOk := PString (VarCur^.VarDataPtr)^ >=
                PString (VarNew^.VarDataPtr)^
            end
          end
          else {handle nil strings}
            case N^.ScCommand of {eval and set boolean flag}
              ctScrIfEqu :
                BoolOk := ((VarCur^.VarDataPtr = nil) and
                (VarNew^.VarDataPtr = nil));
              ctScrIfNotEqu :
                BoolOk := not ((VarCur^.VarDataPtr = nil) and
                (VarNew^.VarDataPtr = nil));
              ctScrIfLess :
                BoolOk := ((VarCur^.VarDataPtr = nil) and
                (VarNew^.VarDataPtr <> nil));
              ctScrIfGreat :
                BoolOk := ((VarCur^.VarDataPtr <> nil) and
                (VarNew^.VarDataPtr = nil));
              ctScrIfLessEq :
                BoolOk := ((VarCur^.VarDataPtr = nil) and
                (VarNew^.VarDataPtr <> nil)) or
                ((VarCur^.VarDataPtr = nil) and
                (VarNew^.VarDataPtr = nil));
              ctScrIfGreatEq :
                BoolOk := ((VarCur^.VarDataPtr <> nil) and
                (VarNew^.VarDataPtr = nil)) or
                ((VarCur^.VarDataPtr = nil) and
                (VarNew^.VarDataPtr = nil))
            end
         end;
         ctPLongInt : {longint boolean functions}
         begin
            case N^.ScCommand of  {eval and set boolean flag}
              ctScrIfEqu :
                BoolOk := PLongInt (VarCur^.VarDataPtr)^ =
                PLongInt (VarNew^.VarDataPtr)^;
              ctScrIfNotEqu :
                BoolOk := PLongInt (VarCur^.VarDataPtr)^ <>
                PLongInt (VarNew^.VarDataPtr)^;
              ctScrIfLess :
                BoolOk := PLongInt (VarCur^.VarDataPtr)^ <
                PLongInt (VarNew^.VarDataPtr)^;
              ctScrIfGreat :
                BoolOk := PLongInt (VarCur^.VarDataPtr)^ >
                PLongInt (VarNew^.VarDataPtr)^;
              ctScrIfLessEq :
                BoolOk := PLongInt (VarCur^.VarDataPtr)^ <=
                PLongInt (VarNew^.VarDataPtr)^;
              ctScrIfGreatEq :
                BoolOk := PLongInt (VarCur^.VarDataPtr)^ >=
                PLongInt (VarNew^.VarDataPtr)^
            end
         end;
         ctPDouble : {double boolean functions}
         begin
            case N^.ScCommand of  {eval and set boolean flag}
              ctScrIfEqu :
                BoolOk := PDouble (VarCur^.VarDataPtr)^ =
                PDouble (VarNew^.VarDataPtr)^;
              ctScrIfNotEqu :
                BoolOk := PDouble (VarCur^.VarDataPtr)^ <>
                PDouble (VarNew^.VarDataPtr)^;
              ctScrIfLess :
                BoolOk := PDouble (VarCur^.VarDataPtr)^ <
                PDouble (VarNew^.VarDataPtr)^;
              ctScrIfGreat :
                BoolOk := PDouble (VarCur^.VarDataPtr)^ >
                PDouble (VarNew^.VarDataPtr)^;
              ctScrIfLessEq :
                BoolOk := PDouble (VarCur^.VarDataPtr)^ <=
                PDouble (VarNew^.VarDataPtr)^;
              ctScrIfGreatEq :
                BoolOk := PDouble (VarCur^.VarDataPtr)^ >=
                PDouble (VarNew^.VarDataPtr)^;
            end
         end
      end
    end;
    if not BoolOk then {boolean function failed, so skip next node}
      Inc (CurCommand);
    Inc (CurCommand)
  end
end;

{math functions}

procedure ScrMath;

var

  TempStr : string;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      case VarCur^.VarType of
        ctPString : {string math}
        begin
          case N^.ScCommand of {you can only add strings}
            ctScrVarAdd :
            begin
              if VarCur^.VarDataPtr <> nil then
              begin
                TempStr := PString (VarCur^.VarDataPtr)^;
                DisposeStr (PString (VarCur^.VarDataPtr));
              end
              else
                TempStr := '';
              if VarNew^.VarDataPtr <> nil then
                VarCur^.VarDataPtr := NewStr (TempStr+
                PString (VarNew^.VarDataPtr)^)
              else
                VarCur^.VarDataPtr := NewStr (TempStr)
            end
          end
        end;
        ctPLongInt : {longint math}
        begin
           case N^.ScCommand of {calc}
             ctScrVarAdd :
               PLongInt (VarCur^.VarDataPtr)^ :=
               PLongInt (VarCur^.VarDataPtr)^ +
               PLongInt (VarNew^.VarDataPtr)^;
             ctScrVarSub :
               PLongInt (VarCur^.VarDataPtr)^ :=
               PLongInt (VarCur^.VarDataPtr)^ -
               PLongInt (VarNew^.VarDataPtr)^;
             ctScrVarMul :
               PLongInt (VarCur^.VarDataPtr)^ :=
               PLongInt (VarCur^.VarDataPtr)^ *
               PLongInt (VarNew^.VarDataPtr)^;
             ctScrVarDiv :
               if PLongInt (VarNew^.VarDataPtr)^ <> 0 then
                 PLongInt (VarCur^.VarDataPtr)^ :=
                 PLongInt (VarCur^.VarDataPtr)^ div
                 PLongInt (VarNew^.VarDataPtr)^
               else {handle divide by 0}
                 LogErr ('divide by zero')
           end
        end;
        ctPDouble : {double math}
        begin
           case N^.ScCommand of {calc}
             ctScrVarAdd :
               PDouble (VarCur^.VarDataPtr)^ :=
               PDouble (VarCur^.VarDataPtr)^ +
               PDouble (VarNew^.VarDataPtr)^;
             ctScrVarSub :
               PDouble (VarCur^.VarDataPtr)^ :=
               PDouble (VarCur^.VarDataPtr)^ -
               PDouble (VarNew^.VarDataPtr)^;
             ctScrVarMul :
               PDouble (VarCur^.VarDataPtr)^ :=
               PDouble (VarCur^.VarDataPtr)^ *
               PDouble (VarNew^.VarDataPtr)^;
             ctScrVarDiv :
               if PDouble (VarNew^.VarDataPtr)^ <> 0 then
                 PDouble (VarCur^.VarDataPtr)^ :=
                 PDouble (VarCur^.VarDataPtr)^ /
                 PDouble (VarNew^.VarDataPtr)^
               else {handle divide by 0}
                 LogErr ('divide by zero')
           end
        end
     end
   end;
   Inc (CurCommand)
  end
end;

{assign value to var}

procedure ScrVarAsn;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      case VarCur^.VarType of
        ctPString :
        begin
          if VarCur^.VarDataPtr <> nil then {dispose current string}
            DisposeStr (PString (VarCur^.VarDataPtr));
          if VarNew^.VarDataPtr <> nil then {assign new string}
            VarCur^.VarDataPtr := NewStr (PString (VarNew^.VarDataPtr)^)
          else {null string}
            VarCur^.VarDataPtr := nil;
         end;
         ctPLongInt : {assign longint}
           PLongInt (VarCur^.VarDataPtr)^ :=
           PLongInt (VarNew^.VarDataPtr)^;
         ctPDouble : {assign double}
           PDouble (VarCur^.VarDataPtr)^ :=
           PDouble (VarNew^.VarDataPtr)^
       end
     end;
    Inc (CurCommand)
  end
end;

{$IFDEF UseParadox}

{put field from current record}

procedure ScrFldPut;


begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      if PVarTable (VarCur^.VarDataPtr)^.TabCur <> nil then
      begin
        with PVarTable (VarCur^.VarDataPtr)^.TabCur^.genericRec^ do
          putString (PLongint (VarNew^.VarDataPtr)^,TrimStr (LastResp))
      end
    end;
    Inc (CurCommand)
  end
end;

{get field from current record}

procedure ScrFldGet;

var

  Blank : boolean;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      if PVarTable (VarCur^.VarDataPtr)^.TabCur <> nil then
      begin
        with PVarTable (VarCur^.VarDataPtr)^.TabCur^.genericRec^ do
          getString (PLongint (VarNew^.VarDataPtr)^,
          LastResp,Blank)
      end
    end;
    Inc (CurCommand)
  end
end;

{import text file into blob}

procedure ScrBlobImp;

var

  BlobLine : string;
  BlobTxt : text;
  BlobBuf : array [0..4095] of char;
  BlobFile : file of byte;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      if PVarTable (VarCur^.VarDataPtr)^.TabCur <> nil then
      begin
        Assign (BlobFile,
        AddExtStr (GetFileNameStr (
        PVarTable (VarCur^.VarDataPtr)^.TabName),'TXT'));
        {$I-} Reset (BlobFile); {$I+}
        if IoResult = 0 then {capture file open?}
        begin
          {$I-} BlobSiz := FileSize (BlobFile); {$I+}
          {$I-} SYSTEM.Close (BlobFile); {$I+}
          Assign (BlobTxt,
          AddExtStr (GetFileNameStr (
          PVarTable (VarCur^.VarDataPtr)^.TabName),'TXT'));
          SetTextBuf (BlobTxt,BlobBuf);
          {$I-} Reset (BlobTxt); {$I+}
          if IoResult = 0 then {capture file open?}
          begin
            with PVarTable (VarCur^.VarDataPtr)^.TabCur^.genericRec^ do
            begin
              BlobPos := 0;
              openBlobWrite (PLongint (VarNew^.VarDataPtr)^,BlobSiz,false);
              while (not Eof (BlobTxt)) and (IoResult = 0) do
              begin
                {$I-} Readln (BlobTxt,BlobLine); {$I+}
                BlobLine := BlobLine+#10;
                putBlob (PLongint (VarNew^.VarDataPtr)^,
                byte (BlobLine[0]),BlobPos,@BlobLine[1]);
                Inc (BlobPos,byte (BlobLine[0]))
              end;
              closeBlob (PLongint (VarNew^.VarDataPtr)^,true);
              openBlobWrite (PLongint (VarNew^.VarDataPtr)^,BlobPos,true);
              closeBlob (PLongint (VarNew^.VarDataPtr)^,true)
            end;
            {$I-} SYSTEM.Close (BlobTxt) {$I+}
          end
        end
      end
    end;
    Inc (CurCommand)
  end
end;

{open blob}

procedure ScrBlobOpen;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      if PVarTable (VarCur^.VarDataPtr)^.TabCur <> nil then
      begin
        with PVarTable (VarCur^.VarDataPtr)^.TabCur^ do
        begin
          if genericRec^.openBlobRead (PLongint (VarNew^.VarDataPtr)^,
          false) = PXSUCCESS then
          begin
            BlobPos := 0;
            BlobSiz := genericRec^.getBlobSize (PLongint (VarNew^.VarDataPtr)^)
          end
        end
      end
    end;
    Inc (CurCommand)
  end
end;

{close blob}

procedure ScrBlobClose;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      if PVarTable (VarCur^.VarDataPtr)^.TabCur <> nil then
      begin
        with PVarTable (VarCur^.VarDataPtr)^.TabCur^ do
          genericRec^.closeBlob (PLongint (VarNew^.VarDataPtr)^,false)
      end
    end;
    Inc (CurCommand)
  end
end;

{get memo blob line}

procedure ScrBlobGet;

var

  I : integer;
  BlobRead : longint;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if (PTermWin (ScriptWin)^.UPort.OutBuffUsed = 0) and
    (PTermWin (ScriptWin)^.UPort.CheckTE) then
    begin
      LogCommand;
      with PVarAssign (V^.VarDataPtr)^ do
      begin
        if PVarTable (VarCur^.VarDataPtr)^.TabCur <> nil then
        begin
          with PVarTable (VarCur^.VarDataPtr)^.TabCur^ do
          begin
            if BlobPos < BlobSiz then
            begin
              if BlobSiz-BlobPos > 255 then
                BlobRead := 255
              else
                BlobRead := BlobSiz-BlobPos;
              genericRec^.getBlob (PLongint (VarNew^.VarDataPtr)^,
              BlobRead,BlobPos,@LastResp[1]);
              I := 1;
              while (I <= BlobRead) and (LastResp[I] <> #10) do
                Inc (I);
              if I > 1  then
                byte (LastResp[0]) := I
              else
                LastResp := '';
              if LastResp <> '' then
              begin
                if LastResp[byte (LastResp[0])] = #10 then
                  Dec (byte (LastResp[0]))
              end;
              Inc (BlobPos,I)
            end
            else {end of blob}
              lastError := PXERR_BLOBINVOFFSET
          end
        end
      end;
      Inc (CurCommand)
    end
  end
end;

{put current record}

procedure ScrRecPut;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarTable (V^.VarDataPtr)^ do
    begin
      if TabCur <> nil then
      begin
        with TabCur^ do
          appendRec (genericRec); {write rec}
      end
    end;
    Inc (CurCommand)
  end
end;

{update current record}

procedure ScrRecUpd;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarTable (V^.VarDataPtr)^ do
    begin
      if TabCur <> nil then
      begin
        with TabCur^ do
          updateRec (genericRec); {write rec}
      end
    end;
    Inc (CurCommand)
  end
end;

{get current record}

procedure ScrRecGet;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarTable (V^.VarDataPtr)^ do
    begin
      if TabCur <> nil then
      begin
        with TabCur^ do
          getRecord (genericRec)
      end
    end;
    Inc (CurCommand)
  end
end;

{search record by primary key}

procedure ScrRecSrcPri;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      if PVarTable (VarCur^.VarDataPtr)^.TabCur <> nil then
      begin
        with PVarTable (VarCur^.VarDataPtr)^.TabCur^ do
          lastError := PXSrchKey (getTableHandle,genericRec^.recH,
          PLongint (VarNew^.VarDataPtr)^,SearchFirst)
      end
    end;
    Inc (CurCommand)
  end
end;

{search record by secondary key}

procedure ScrRecSrcSec;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      if PVarTable (VarCur^.VarDataPtr)^.TabCur <> nil then
      begin
        with PVarTable (VarCur^.VarDataPtr)^.TabCur^ do
          lastError := PXSrchFld (getTableHandle,genericRec^.recH,
          PLongint (VarNew^.VarDataPtr)^,SearchFirst)
      end
    end;
    Inc (CurCommand)
  end
end;

{get current record}

procedure ScrRecClr;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarTable (V^.VarDataPtr)^ do
    begin
      if TabCur <> nil then
      begin
        with TabCur^ do
        begin
          genericRec^.clear
        end
      end
    end;
    Inc (CurCommand)
  end
end;

{close paradox table if open}

procedure ScrTabHome;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarTable (V^.VarDataPtr)^ do
    begin
      if TabCur <> nil then
      begin
        with TabCur^ do
        begin
          gotoBegin;
          if lastError = PXSUCCESS then
            gotoNext
        end
      end
    end;
    Inc (CurCommand)
  end
end;

{close paradox table if open}

procedure ScrTabEnd;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarTable (V^.VarDataPtr)^ do
    begin
      if TabCur <> nil then
      begin
        with TabCur^ do
        begin
          gotoEnd;
          if lastError = PXSUCCESS then
            gotoPrev
        end
      end
    end;
    Inc (CurCommand)
  end
end;

{goto next record}

procedure ScrTabNext;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarTable (V^.VarDataPtr)^ do
    begin
      if TabCur <> nil then
      begin
        with TabCur^ do
        begin
          gotoNext;
        end
      end
    end;
    Inc (CurCommand)
  end
end;

{goto previous record}

procedure ScrTabPrev;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarTable (V^.VarDataPtr)^ do
    begin
      if TabCur <> nil then
      begin
        with TabCur^ do
        begin
          gotoPrev
        end
      end
    end;
    Inc (CurCommand)
  end
end;

{delete current record}

procedure ScrRecDel;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarTable (V^.VarDataPtr)^ do
    begin
      if TabCur <> nil then
      begin
        with TabCur^ do
        begin
          deleteRec
        end
      end
    end;
    Inc (CurCommand)
  end
end;

{get last table error}

procedure ScrTabError;

begin
  with PTermWin (ScriptWin)^ do
  begin
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      if PVarTable (VarCur^.VarDataPtr)^.TabCur <> nil then
      begin
        if VarNew^.VarDataPtr <> nil then {dispose old var}
          DisposeStr (PString (VarNew^.VarDataPtr));
        VarNew^.VarDataPtr := NewStr (EnginePtr^.getErrorMessage (
        PVarTable (VarCur^.VarDataPtr)^.TabCur^.lastError))
      end
    end;
    LogCommand;
    Inc (CurCommand)
  end
end;

{open paradox table if closed}

procedure ScrTabOpen;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      if PVarTable (VarCur^.VarDataPtr)^.TabCur = nil then
        PVarTable (VarCur^.VarDataPtr)^.TabCur :=
        New (PCursor,InitAndOpen (DataBasePtr,
        PVarTable (VarCur^.VarDataPtr)^.TabName,
        PLongint (VarNew^.VarDataPtr)^,false))
    end;
    Inc (CurCommand)
  end
end;

{close paradox table if open}

procedure ScrTabClose;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarTable (V^.VarDataPtr)^ do
    begin
      if TabCur <> nil then
      begin
        Dispose (TabCur,Done);
        TabCur := nil
      end
    end;
    Inc (CurCommand)
  end
end;

{paradox table name}

procedure ScrTabName;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
    begin
      if VarNew^.VarDataPtr <> nil then
      PVarTable (VarCur^.VarDataPtr)^.TabName :=
      PString (VarNew^.VarDataPtr)^
    end;
    Inc (CurCommand)
  end
end;

{create table from data dictionary}

procedure ScrTabCreate;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
      CreateTableDataDict (DataBasePtr,PString (V^.VarDataPtr)^);
    Inc (CurCommand)
  end
end;

{$ENDIF}

{jump to another node and preserve return address}

procedure ScrCall;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    PushAddr (CurCommand+1);              {return to next node}
    if CmdState and ctCmdScript <> 0 then {new command node to execute}
      CurCommand := PWord (V^.VarDataPtr)^
  end
end;

{return from call command}

procedure ScrReturn;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    CurCommand := PopAddr {pop node off stack}
  end
end;

{jump to another node}

procedure ScrGoto;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    CurCommand := PWord (V^.VarDataPtr)^ {new command node to execute}
  end
end;

{waitfor seconds before time out}

procedure ScrWaitSecs;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    WaitForSecs := PLongInt (V^.VarDataPtr)^;
    Inc (CurCommand)
  end
end;

{get mouse x}

procedure ScrMouseX;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    PLongInt (V^.VarDataPtr)^ := MouseX;
    Inc (CurCommand)
  end
end;

{get mouse y}

procedure ScrMouseY;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    PLongInt (V^.VarDataPtr)^ := MouseY;
    Inc (CurCommand)
  end
end;

{delay 1/18 secs}

procedure ScrDelayTics;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if ScriptState and ctScrStWaitFor <> 0 then
    begin
      if TimerExpired (ScriptTimer) then
      begin
        ScriptState  := ScriptState and not ctScrStWaitFor;
        Inc (CurCommand)
      end
    end
    else   {start tic timer}
    begin
      LogCommand;
      NewTimer (ScriptTimer,PLongInt (V^.VarDataPtr)^);
      ScriptState  := ScriptState or ctScrStWaitFor
    end
  end
end;

{return connect status}

procedure ScrConStat;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    PLongInt (V^.VarDataPtr)^ := byte (UPort.CheckDCD);
    Inc (CurCommand)
  end
end;

{right pad last response}

procedure ScrPadRight;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    LastResp := PadRightStr (LastResp,' ',PLongInt (V^.VarDataPtr)^ );
    Inc (CurCommand)
  end
end;

{get substring of last response}

procedure ScrSubStr;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
      LastResp := Copy (LastResp,
      PLongInt (VarCur^.VarDataPtr)^,
      PLongInt (VarNew^.VarDataPtr)^);
   Inc (CurCommand)
  end
end;

{get response from ini file}

procedure ScrGetIni;

var

 S1, S2 : string;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
      if IniFile <> nil then
      begin
        if VarCur^.VarDataPtr <> nil then
          S1 := PString (VarCur^.VarDataPtr)^
        else
          S1 := '';
        if VarNew^.VarDataPtr <> nil then
          S2 := PString (VarNew^.VarDataPtr)^
        else
          S2 := '';
        LastResp := IniFile^.GetProfileString (S2,S1,'ERROR')
      end;
    Inc (CurCommand)
  end
end;

{write response to ini file}

procedure ScrPutIni;

var

 S1, S2 : string;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    with PVarAssign (V^.VarDataPtr)^ do
      if IniFile <> nil then
      begin
        if VarCur^.VarDataPtr <> nil then
          S1 := PString (VarCur^.VarDataPtr)^
        else
          S1 := '';
        if VarNew^.VarDataPtr <> nil then
          S2 := PString (VarNew^.VarDataPtr)^
        else
          S2 := '';
        IniFile^.SetProfileString (S2,S1,LastResp)
      end;
    Inc (CurCommand)
  end
end;

{waitformulti delim char}

procedure ScrSepChar;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
      SepChar := PString (V^.VarDataPtr)^[1]; {new delim}
    Inc (CurCommand)
  end
end;

{add to get block delim char set}

procedure ScrGetChar;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
      GetBlockSet := GetBlockSet+[PString (V^.VarDataPtr)^[1]]
    else
      GetBlockSet := []; {empty set}
    Inc (CurCommand)
  end
end;

{submit script to que}

procedure ScrSubmit;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
      ScriptQue.AddToQue (PString (V^.VarDataPtr)^);
    Inc (CurCommand)
  end
end;

{output string to log}

procedure ScrSendLog;

var

  TempFlag : boolean;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
    begin
      TempFlag := WriteLogOn;
      WriteLogOn := true;
      UpdateLog (PString (V^.VarDataPtr)^);
      WriteLogOn := TempFlag
    end;
    Inc (CurCommand)
  end
end;

{send string to list box}

procedure ScrSendList;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
      Message (DeskTop,evBroadcast,cmListInsert,V^.VarDataPtr); {capture}
    Inc (CurCommand)
  end
end;

{open ini file}

procedure ScrOpenIni;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
    begin
      if IniFile = nil then
      begin
        IniFile := New (PIni,Init (50,50,PString (V^.VarDataPtr)^,false,true));
        IniFile^.SetFlushMode (true)
      end
    end;
    Inc (CurCommand)
  end
end;

{edit file}

procedure ScrEditFile;

var

  P : PWindow;
  R : TRect;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
    begin
      DeskTop^.GetExtent(R);
      Dec (R.B.Y,7);
      P := New (PCyEditWindow, Init (R, PString (V^.VarDataPtr)^, wnNoNumber));
      P^.HelpCtx := hcTextEditor;
      Application^.InsertWindow (P)
    end;
    Inc (CurCommand)
  end
end;

{capture append}

procedure ScrCapApp;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
      Capture (PString (V^.VarDataPtr)^,cmYes);
    Inc (CurCommand)
  end
end;

{capture overwrite}

procedure ScrCapNew;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
      Capture (PString (V^.VarDataPtr)^,cmNo);
    Inc (CurCommand)
  end
end;

{open text file}

procedure ScrTxtOpen;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
    begin
      if not TxtFileOpen then
      begin
        Assign (TxtFile,PString (V^.VarDataPtr)^);
        {$I-} Reset (TxtFile); {$I+}
        TxtFileOpen :=  IoResult = 0  {text file open?}
      end
    end;
    Inc (CurCommand)
  end
end;

{erase file}

procedure ScrEraseFil;

var

  EraseFile : file;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
    begin
      Assign (EraseFile,PString (V^.VarDataPtr)^);
     {$I-} Reset (EraseFile); {$I+}
      if IoResult = 0 then {capture file open?}
      begin
        {$I-} SYSTEM.Close (EraseFile); {$I+}
        {$I-} Erase (EraseFile) {$I+}
      end
    end;
    Inc (CurCommand)
  end
end;

{unzip file}

procedure ScrUnZipFil;

var

  UZ : UnZip;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then
    begin
      if UZ.Init (PString (V^.VarDataPtr)^) then
      begin
        UZ.SetOutPutPath (JustPathName (PString (V^.VarDataPtr)^));
        UZ.Extract ('*.*');
        UZ.Done
      end
    end;
    Inc (CurCommand)
  end
end;

{zmodem download}

procedure ScrZmodemD;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    ProtocolNum := Zmodem;
    CmdState := CmdState or ctCmdXferInit or ctCmdDownload;
    Inc (CurCommand)
  end
end;

{upload file}

procedure ScrUpload;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if CmdState and ctCmdXfer = 0 then
    begin
      if ScriptState and ctScrStWaitFor <> 0 then
      begin
        if FileListColl <> nil then
        begin
          Dispose (FileListColl,Done);
          FileListColl := nil
        end;
        ScriptState  := ScriptState and not ctScrStWaitFor;
        Inc (CurCommand)
      end
      else   {init upload}
      begin
        LogCommand;
        if FileListColl = nil then
        begin
          FileListColl := New (PStringCollection,Init (1,0));
          if V^.VarDataPtr <> nil then
            FileListColl^.Insert (NewStr (PString (V^.VarDataPtr)^));
          case N^.ScCommand of
            ctScrZmodemU : ProtocolNum := Zmodem;
            ctScrXModemU : ProtocolNum := Xmodem;
          end;
          CmdState := CmdState or ctCmdXferInit;
          ScriptState  := ScriptState or ctScrStWaitFor
        end
        else
          LogErr ('file list in use')
      end
    end
  end
end;

{input box}

procedure ScrInpBox;

var

  InpBox : PTermInpDlg;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then {convert all var types to string}
    begin
      case V^.VarType of
        ctPString  : InpBox := New (PTermInpDlg,Init (TermRec^.ComName,
                     LastResp,PString (V^.VarDataPtr)^));
        ctPLongInt : InpBox := New (PTermInpDlg,Init (TermRec^.ComName,
                     LastResp,IntToStr (PLongInt (V^.VarDataPtr)^)));
        ctPDouble  : InpBox := New (PTermInpDlg,Init (TermRec^.ComName,
                     LastResp,TrimStr (DblToStr (PDouble (V^.VarDataPtr)^,
                     LDouble,RDouble))))
      end;
      Application^.InsertWindow (InpBox);
      ScriptState := ScriptState or ctScrStInpBox
    end;
    Inc (CurCommand)
  end
end;

{input box wait}

procedure ScrInpWait;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if ScriptState and ctScrStWaitFor <> 0 then
    begin
      if ScriptState and ctScrStInpBox = 0 then
      begin
        ScriptState  := ScriptState and not ctScrStWaitFor;
        Inc (CurCommand)
      end;
      if TimerExpired (ScriptTimer) then
      begin
        UpdateLog ('InputBoxWait time out');
        ScriptState  := ScriptState and not ctScrStWaitFor;
        TimeOut;
        Inc (CurCommand)
      end
    end
    else
    begin
      LogCommand;
      NewTimerSecs (ScriptTimer,WaitForSecs); {start timer}
      ScriptState  := ScriptState or ctScrStWaitFor
    end
  end
end;

{list box}

procedure ScrListBox;

var

  ListBox : PTermListDlg;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if V^.VarDataPtr <> nil then {convert all var types to string}
    begin
      ListBox := New (PTermListDlg,Init (TermRec^.ComName,
      PString (V^.VarDataPtr)^));
      Application^.InsertWindow (ListBox);
      ScriptState := ScriptState or ctScrStInpBox
    end;
    Inc (CurCommand)
  end
end;

{hang up modem}

procedure ScrHangUp;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    CmdState := (CmdState and not ctCmdDialPause) or ctCmdHangUp;
    Inc (CurCommand)
  end
end;

{dial modem}

procedure ScrDial;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if ScriptState and ctScrStWaitFor <> 0 then
    begin
      ScriptState := ScriptState and not ctScrStWaitFor;
      Inc (CurCommand)
    end
    else
    begin
      LogCommand;
      ScriptState := ScriptState or ctScrStWaitFor;
      CmdState := CmdState or ctCmdDial
    end
  end
end;

{turn capture off}

procedure ScrCapOff;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    CaptureClose;
    Inc (CurCommand)
  end
end;

{close text file if open}

procedure ScrTxtClose;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if TxtFileOpen then
    begin
      {$I-} SYSTEM.Close (TxtFile); {$I+}
      TxtFileOpen := IoResult <> 0
    end;
    Inc (CurCommand)
  end
end;

{get next text line if open}

procedure ScrTxtGet;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if TxtFileOpen then
    begin
      if not eof (TxtFile) then
      begin
      {$I-} ReadLn (TxtFile,LastResp); {$I+}
       if IoResult <> 0 then
         LastResp := #26
      end
      else
         LastResp := #26
    end
    else
      LastResp := #26;
    Inc (CurCommand)
  end
end;

{draw term from buffer}

procedure ScrDraw;

var

  C : char;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    while UPort.CharReady do
    begin
      UPort.GetChar (C);
      Uport.WaitChar (@UPort,C)
    end;
    Inc (CurCommand)
  end
end;

{draw list box}

procedure ScrDrawList;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    Message (Desktop,evBroadcast,cmListDraw,@Self);
    Inc (CurCommand)
  end
end;

{init modem}

procedure ScrInit;

begin
  with PTermWin (ScriptWin)^ do
  begin
    if ScriptState and ctScrStWaitFor <> 0 then
    begin
      ScriptState := ScriptState and not ctScrStWaitFor;
      Inc (CurCommand)
    end
    else
    begin
      LogCommand;
      ScriptState := ScriptState or ctScrStWaitFor;
      CmdState := CmdState or ctCmdInit
    end
  end
end;

{logging on}

procedure ScrLogOn;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    ScriptState := ScriptState or ctScrStLogOn;
    Inc (CurCommand)
  end
end;

{logging off}

procedure ScrLogOff;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    ScriptState := ScriptState and not ctScrStLogOn;
    Inc (CurCommand)
  end
end;

{time out abort on}

procedure ScrAbortOn;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    ScriptState := ScriptState or ctScrStAbort;
    Inc (CurCommand)
  end
end;

{time out abort off}

procedure ScrAbortOff;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    ScriptState := ScriptState and not ctScrStAbort;
    Inc (CurCommand)
  end
end;

{sys messages on}

procedure ScrWriLogOn;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    WriteLogOn := true;
    Inc (CurCommand)
  end
end;

{sys messages off}

procedure ScrWriLogOff;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    WriteLogOn := false;
    Inc (CurCommand)
  end
end;

{local echo on}

procedure ScrEchoOn;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    Term^.TermOptions := Term^.TermOptions or ctLocalEcho;
    Inc (CurCommand)
  end
end;

{local echo off}

procedure ScrEchoOff;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    Term^.TermOptions := Term^.TermOptions and not ctLocalEcho;
    Inc (CurCommand)
  end
end;

{lock script}

procedure ScrLock;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    ScriptState := ScriptState or ctScrStLock;
    Inc (CurCommand)
  end
end;

{unlock script}

procedure ScrUnlock;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    ScriptState := ScriptState and not ctScrStLock;
    Inc (CurCommand)
  end
end;

{close ini file}

procedure ScrCloseIni;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    if IniFile <> nil then
    begin
      Dispose (IniFile,Done);
      IniFile := nil
    end;
    Inc (CurCommand)
  end
end;

{end script}

procedure ScrEnd;

begin
  with PTermWin (ScriptWin)^ do
  begin
    LogCommand;
    CmdState := CmdState and not ctCmdScript;
    ScriptState := ScriptState and not ctScrStLock;
    UpdateLog ('End script')
  end
end;

begin
  N := PScriptNode (NodeCollPtr^.At (CurCommand));
  V := N^.ScDataPtr;
  with PTermWin (ScriptWin)^ do
  begin
    case N^.ScCommand of
      ctScrWaitFor : ScrWaitFor;
      ctScrGetBlock : ScrGetBlock;
      ctScrGetResp : ScrGetResp;
      ctScrSend : ScrSend;
      ctScrSetResp : ScrSetResp;
      ctScrVarAsn : ScrVarAsn;
      ctScrIfEqu,
      ctScrIfNotEqu,
      ctScrIfLess,
      ctScrIfGreat,
      ctScrIfLessEq,
      ctScrIfGreatEq : ScrIf;
      ctScrVarAdd,
      ctScrVarSub,
      ctScrVarMul,
      ctScrVarDiv : ScrMath;
      ctScrSendCap : ScrSendCap;
      ctScrGoto : ScrGoto;
      ctScrCall : ScrCall;
      ctScrReturn : ScrReturn;
      ctScrCapApp : ScrCapApp;
      ctScrCapNew : ScrCapNew;
      ctScrCapOff : ScrCapOff;
      ctSrcPadRight : ScrPadRight;
      ctScrSubStr : ScrSubStr;
      ctScrGetIni : ScrGetIni;
      ctScrPutIni : ScrPutIni;
      ctScrSendList : ScrSendList;
      ctScrOpenIni : ScrOpenIni;
      ctScrTxtGet : ScrTxtGet;
      ctScrTxtOpen : ScrTxtOpen;
      ctScrTxtClose : ScrTxtClose;
      ctScrEditFile : ScrEditFile;
{$IFDEF UseParadox}
      ctScrFldGet : ScrFldGet;
      ctScrFldPut : ScrFldPut;
      ctScrRecGet : ScrRecGet;
      ctScrRecPut : ScrRecPut;
      ctScrRecUpd : ScrRecUpd;
      ctScrBlobGet : ScrBlobGet;
      ctScrBlobImp : ScrBlobImp;
      ctScrRecSrcPri : ScrRecSrcPri;
      ctScrRecSrcSec : ScrRecSrcSec;
      ctScrRecClr : ScrRecClr;
      ctScrTabHome : ScrTabHome;
      ctScrTabEnd : ScrTabEnd;
      ctScrTabNext : ScrTabNext;
      ctScrTabPrev : ScrTabPrev;
      ctScrRecDel : ScrRecDel;
      ctScrTabError : ScrTabError;
      ctScrBlobOpen : ScrBlobOpen;
      ctScrBlobClose : ScrBlobClose;
      ctScrTabOpen : ScrTabOpen;
      ctScrTabClose : ScrTabClose;
      ctScrTabName : ScrTabName;
      ctScrTabCreate : ScrTabCreate;
{$ENDIF}
      ctScrZmodemD : ScrZmodemD;
      ctScrZmodemU,
      ctScrXModemU : ScrUpload;
      ctScrInpBox : ScrInpBox;
      ctScrListBox : ScrListBox;
      ctScrInpWait : ScrInpWait;
      ctScrDraw : ScrDraw;
      ctScrDrawList : ScrDrawList;
      ctScrWaitSecs : ScrWaitSecs;
      ctScrMouseX : ScrMouseX;
      ctScrMouseY : ScrMouseY;
      ctSrcDelayTics : ScrDelayTics;
      ctSrcConStat : ScrConStat;
      ctScrSepChar : ScrSepChar;
      ctScrGetChar : ScrGetChar;
      ctScrAbortOn : ScrAbortOn;
      ctScrAbortOff : ScrAbortOff;
      ctScrEraseFil : ScrEraseFil;
      ctScrUnZipFil : ScrUnZipFil;
      ctScrSendLog : ScrSendLog;
      ctScrLogOn : ScrLogOn;
      ctScrLogOff : ScrLogOff;
      ctScrWriLogOn : ScrWriLogOn;
      ctScrWriLogOff : ScrWriLogOff;
      ctScrEchoOn : ScrEchoOn;
      ctScrEchoOff : ScrEchoOff;
      ctScrLock : ScrLock;
      ctScrUnlock : ScrUnlock;
      ctScrInit : ScrInit;
      ctScrDial : ScrDial;
      ctScrHangUp : ScrHangUp;
      ctScrSubmit : ScrSubmit;
      ctScrCloseIni : ScrCloseIni;
      ctScrEnd : ScrEnd
    end
  end
end;

{
Add command to collection.
}

function TScriptEng.AddCommand (Node : PScriptNode) : boolean;

begin
  NodeCollPtr^.Insert (Node); {add command to list}
  AddCommand := not LowMemory
end;

{
Add var to collection.
}

function TScriptEng.AddVar (Node : PVarNode) : boolean;

begin
  VarCollPtr^.Insert (Node); {add var to list}
  AddVar := not LowMemory
end;

{
Return pointer to PVarNode given var name or nil if name not found.
}

function TScriptEng.GetVarPtr (VName : string) : PVarNode;

function SameName (Item : pointer) : boolean; far;

begin
  SameName := (PVarNode (Item)^.VarName <> nil) and
  (PVarNode (Item)^.VarName^ = VName)
end;

begin
  VName := UpCaseStr (VName);                    {force to upper case}
  GetVarPtr := VarCollPtr^.FirstThat (@SameName) {return var node/nil}
end;

{
Show current command in term's log if logging enabled.
}

procedure TScriptEng.LogCommand;

var

  LStr : string;
  N : PScriptNode;
  V : PVarNode;

begin
  if (ScriptState and ctScrStLogOn <> 0) and
  (CurCommand <= NodeCollPtr^.Count-1) then
  begin
    N := PScriptNode (NodeCollPtr^.At (CurCommand));
    V := N^.ScDataPtr;
    LStr := IntToRightStr (CurCommand,6)+' '+ctScrCommands[N^.ScCommand];
    if (V <> nil) then
      case V^.VarType of {format output string by var type}
        ctPString     :
          if V^.VarDataPtr <> nil then
            LStr := LStr+' '#39+PString (V^.VarDataPtr)^+#39
          else
            LStr := LStr+' '#39#39;
        ctPLongInt    : LStr := LStr+' '+IntToStr (PLongInt (V^.VarDataPtr)^);
        ctPDouble     : LStr := LStr+' '+TrimStr (DblToStr (PDouble (V^.VarDataPtr)^,
                        LDouble,RDouble));
        ctPWord       : LStr := LStr+' '+IntToStr (PWord (V^.VarDataPtr)^);
{$IFDEF UseParadox}
        ctPTable      : LStr := LStr+' '+V^.VarName^;
{$ENDIF}
        ctPVarAssign  : {format output string to assign type var}
        begin
          with PVarAssign (V^.VarDataPtr)^ do
          begin
            LStr := LStr+' '+VarCur^.VarName^+', ';
            if VarNew^.VarName <> nil then
              LStr := LStr+VarNew^.VarName^
            else
              case VarNew^.VarType of {format output string by var type}
                ctPString     :
                  if VarNew^.VarDataPtr <> nil then
                    LStr := LStr+#39+PString (VarNew^.VarDataPtr)^+#39
                  else
                    LStr := LStr+#39#39;
                ctPLongInt    : LStr := LStr+IntToStr (PLongInt (
                                VarNew^.VarDataPtr)^);
                ctPDouble     : LStr := LStr+TrimStr (DblToStr (PDouble (
                                VarNew^.VarDataPtr)^,LDouble,RDouble))
{$IFDEF UseParadox}
               ;ctPTable      : LStr := LStr+' '+VarNew^.VarName^
{$ENDIF}
              end
          end
        end
      end;
    PTermWin (ScriptWin)^.UpdateLog (LStr) {update log}
  end
end;

{
TScriptCompile compiles a TCyEditWindow script source into command and var
nodes that a TScriptEngine uses.  Compile time errors are displayed in
the Term window's log and highlighted in source.
}

constructor TScriptCompile.Init (E : PCyEditWindow; T : PView);

begin
  inherited Init;
  LabelCollPtr := New (PCollection,Init (0,5)); {label node collection}
  EditWin := E;
  TWin := T;
  ScriptEng := PTermWin (TWin)^.ScriptEng
end;

{
Dispose label collection.
}

destructor TScriptCompile.Done;

procedure KillData (Item : pointer); far;

var

  L : PLabelNode;

begin
  L := PLabelNode (Item);
  if L^.Name <> nil then
    DisposeStr (L^.Name)
end;

begin
  if LabelCollPtr <> nil then
  begin
    LabelCollPtr^.ForEach (@KillData); {dispose node data before collection}
    Dispose (LabelCollPtr,Done)
  end;
  inherited Done
end;

{
Add label to collection.
}

function TScriptCompile.AddLabel (Node : PLabelNode) : boolean;

begin
  LabelCollPtr^.Insert (Node); {add var to list}
  AddLabel := not LowMemory
end;

{
Return pointer to PLabelNode given label name or nil if name not found.
}

function TScriptCompile.GetLabelPtr (LName : string) : PLabelNode;

function SameName (Item : pointer) : boolean; far;

begin
  SameName := (PLabelNode (Item)^.Name <> nil) and
  (PLabelNode (Item)^.Name^ = LName)
end;

begin
  LName := UpCaseStr (LName); {force to upper case}
  GetLabelPtr := LabelCollPtr^.FirstThat (@SameName)
end;

{
Get next line from editor dilimited by CR/LF.  Return false if end of edit
buffer.
}

function TScriptCompile.GetLine (var TempStr : string) : boolean;

var

  ExitGet : boolean;
  C : char;

begin
  ExitGet := false;
  TempStr := '';
  LastChar := CurChar;
  GetLine := CurChar < EditWin^.Editor^.BufLen;
  while (CurChar < EditWin^.Editor^.BufLen) and
  (byte (TempStr[0]) < 255) and (not ExitGet) do
  begin
    C := EditWin^.Editor^.BufChar (CurChar);
    case C of
      ctCR : Inc (CurChar); {skip cr}
      ctLF :                {skip/exit lf}
      begin
        Inc (CurChar);
        ExitGet := true
      end
      else {append char to string}
      begin
        TempStr := TempStr+EditWin^.Editor^.BufChar (CurChar);
        Inc (CurChar)
      end
    end
  end
end;

{
Display error in log and focus in editor window
}

procedure TScriptCompile.LogErr (ErrStr : string);

var

  S : string;

begin
  S := 'Error line '+IntToStr (CurLine)+': '+ErrStr;
  PTermWin (TWin)^.UpdateLog (S);
  with EditWin^ do
  begin
    Editor^.SetSelect (LastChar,CurChar-2,true);
    Editor^.TrackCursor (true);
    Select {show error line in editor}
  end
end;

{
Parse string into upper case command string and param string.  String must
not = '' or start with ';'.
}

procedure TScriptCompile.ParseLine (S : string);

var

  CmdDPos : byte;

begin
  CmdDPos := Pos (' ',S); {see if we have any params}
  if CmdDPos > 1 then
  begin
    CmdStr := UpCaseStr (Copy (S,1,CmdDPos-1));
    ParStr := TrimStr (Copy (S,CmdDPos,byte (S[0])-CmdDPos+1))
  end
  else                    {no param dilimiter ' '}
  begin
    CmdStr := UpCaseStr (S);
    ParStr := ''
  end
end;

{
Search command table for match.
}

function TScriptCompile.FindCommand : boolean;

begin
  CmdNum := ctScrWaitFor;
  while (CmdNum <= ctScrEnd) and
  (ctScrCommands [CmdNum] <> CmdStr) do {use linear search to find}
    Inc (CmdNum);
  FindCommand := (CmdNum <= ctScrEnd)
end;

{
Pass 1 parses line into command and params.
}

function TScriptCompile.Pass1 (S : string) : boolean;

var

  ParamVar : boolean;
  ParInt : longint;
  ParDbl : double;
  AsnStr1, AsnStr2, AsnStr3 : string;

{convert string param}

function GetStrParam : boolean;

begin
  if ParStr <> '' then
  begin
    case UpCase (ParStr[1]) of
      'A'..'Z' :                  {variable}
      begin
        ParamVar := true;
        GetStrParam := true
      end;
      #39 :                       {string constant}
      begin
        ParamVar := false;
        Delete(ParStr,1,1);                   {delete first '}
        if (ParStr <> '') and
        (ParStr[byte (ParStr[0])] = #39) then {check for ending '}
        begin
          Dec (byte (ParStr[0]));             {delete ending '}
          GetStrParam := true
        end
        else                                  {no ending ' found}
        begin
          LogErr ('no ending '#39' found in '+ParStr);
          GetStrParam := false
        end
      end;
      '#' :                                 {numeric char constant}
      begin
        ParamVar := false;
        Delete(ParStr,1,1);                 {delete #}
        ParStr := char (StrToInt (ParStr)); {convert num str to char}
        GetStrParam := true
      end
      else                                  {param didn't start with valid char}
      begin
        LogErr ('param must start with '#39', # or A..Z');
        GetStrParam := false
      end
    end
  end
  else
  begin
    LogErr ('param missing');
    GetStrParam := false
  end
end;

{convert longint param}

function GetIntParam : boolean;

begin
  if ParStr <> '' then
  begin
    case UpCase (ParStr[1]) of
      '0'..'9','-','+' : {integer constant}
      begin
        ParInt := StrToInt (ParStr);
        ParamVar := false;
        GetIntParam := true
      end;
      'A'..'Z' : {variable}
      begin
        ParamVar := true;
        GetIntParam := true
      end
      else
      begin
        LogErr ('param must start with +, -, 0..9 or A..Z');
        GetIntParam := false
      end
    end
  end
  else
  begin
    LogErr ('param missing');
    GetIntParam := false
  end
end;

{convert double param}

function GetDblParam : boolean;

begin
  if ParStr <> '' then
  begin
    case UpCase (ParStr[1]) of
      '0'..'9','-','+','.' : {double constant}
      begin
        ParDbl := StrToDbl (ParStr);
        ParamVar := false;
        GetDblParam := true
      end;
      'A'..'Z' : {variable}
      begin
        ParamVar := true;
        GetDblParam := true
      end
      else
      begin
        LogErr ('param must start with ., +, -, 0..9 or A..Z');
        GetDblParam := false
      end
    end
  end
  else
  begin
    LogErr ('param missing');
    GetDblParam := false
  end
end;

{get assign type params (name1,name2)}

function GetAssignParam : boolean;

var

  EPos : byte;

begin
  EPos := Pos (',',ParStr); {find , seperator}
  if EPos > 0 then
  begin
    AsnStr1 := ParStr;
    byte (AsnStr1[0]) := EPos-1;
    AsnStr1 := TrimStr (AsnStr1);
    if EPos < byte (ParStr[0]) then
    begin
      AsnStr2 := TrimStr (Copy (ParStr,EPos+1,byte (ParStr[0])-EPos));
      GetAssignParam := true
    end
    else
    begin
      LogErr ('right param missing');
      GetAssignParam := false
    end
  end
  else
  begin
    LogErr ('no , seperator');
    GetAssignParam := false
  end
end;

{process valid commands and params}

function ProcessCommand : boolean;

var

  CmdOk : boolean;
  N : PScriptNode;
  V, V2, V3 : PVarNode;
  L : PLabelNode;

function MakeStrNode (S : string) : PVarNode;

var

  VN : PVarNode;

begin
  VN := New (PVarNode,Init);
  VN^.VarType := ctPString;
  VN^.VarDataPtr := NewStr (S);
  MakeStrNode := VN
end;

function MakeIntNode (I : longint) : PVarNode;

var

  VN : PVarNode;

begin
  VN := New (PVarNode,Init);
  VN^.VarType := ctPLongint;
  VN^.VarDataPtr := New (PLongInt);
  PLongInt (VN^.VarDataPtr)^ := I;
  MakeIntNode := VN
end;

function MakeDblNode (D : double) : PVarNode;

var

  VN : PVarNode;

begin
  VN := New (PVarNode,Init);
  VN^.VarType := ctPDouble;
  VN^.VarDataPtr := New (PDouble);
  PDouble (VN^.VarDataPtr)^ := D;
  MakeDblNode := VN
end;

{$IFDEF UseParadox}
function MakeTabNode : PVarNode;

var

  VN : PVarNode;

begin
  VN := New (PVarNode,Init);
  VN^.VarType := ctPTable;
  VN^.VarDataPtr := New (PVarTable);
  FillChar (PVarTable (VN^.VarDataPtr)^,SizeOf (TVarTable),0);
  MakeTabNode := VN
end;
{$ENDIF}

function MakeVarAsnNode (VN1, VN2 : PVarNode) : PVarNode;

var

  VN : PVarNode;
  VA : PVarAssign;

begin
  VA := New (PVarAssign);
  VA^.VarCur := VN1;
  VA^.VarNew := VN2;
  VN := New (PVarNode,Init);
  VN^.VarType := ctPVarAssign;
  VN^.VarDataPtr := VA;
  MakeVarAsnNode := VN
end;

function MakeCmdNode (C : ctScrCommand; DPtr : pointer) : PScriptNode;

var

  SN : PScriptNode;

begin
  SN := New (PScriptNode,Init);
  SN^.ScCommand := C;
  SN^.ScDataPtr := DPtr;
  MakeCmdNode := SN
end;

begin
  CmdOk := FindCommand;
  if CmdOk then {command found, compile into script node and/or var node}
  begin
    case CmdNum of

      ctScrWaitFor,
      ctScrSend,
      ctScrGetResp,
      ctScrSetResp,
      ctScrSendCap,
      ctScrCapApp,
      ctScrCapNew,
      ctScrZmodemU,
      ctScrXModemU,
      ctScrTxtOpen,
      ctScrEraseFil,
      ctScrUnZipFil,
      ctScrSepChar,
      ctScrGetChar,
      ctScrSubmit,
      ctScrSendLog,
      ctScrSendList,
      ctScrOpenIni,
      ctScrEditFile,
{$IFDEF UseParadox}
      ctScrTabCreate,
{$ENDIF}
      ctScrInpBox,
      ctScrListBox : {get string param as const or var}
      begin
        if GetStrParam then
        begin
          if ParamVar then
          begin
            V := ScriptEng^.GetVarPtr (ParStr);
            if V <> nil then
            begin
              case CmdNum of
                ctScrWaitFor,
                ctScrSend,
                ctScrGetResp,
                ctScrSetResp,
                ctScrSendCap,
                ctScrInpBox : CmdOk := true; {handles any var type}
                else
                  CmdOk := (V^.VarType = ctPString) {only string type allowed}
              end;
              if CmdOk then
              begin
                N := MakeCmdNode (CmdNum,V);
                CmdOk := ScriptEng^.AddCommand (N)
              end
              else
                LogErr ('var incorrect type '+ParStr)
            end
            else
            begin
              LogErr ('undefined var '+ParStr);
              CmdOk := false
            end
          end
          else {create var for constant}
          begin
            V := MakeStrNode (ParStr);
            ScriptEng^.AddVar (V);
            N := MakeCmdNode (CmdNum,V);
            CmdOk := ScriptEng^.AddCommand (N)
          end
        end
        else
          CmdOk := false
      end;

      ctScrIfEqu,
      ctScrIfNotEqu,
      ctScrIfLess,
      ctScrIfGreat,
      ctScrIfLessEq,
      ctScrIfGreatEq,
      ctScrVarAsn,
      ctScrVarAdd,
      ctScrVarSub,
      ctScrVarMul,
      ctScrVarDiv,
      ctScrSubStr,
      ctScrGetIni,
      ctScrPutIni : {assign var}
      begin
        if (ParStr <> '') and
        (UpCase (ParStr[1]) in ['A'..'Z']) then
        begin
          if GetAssignParam then
          begin
            V := ScriptEng^.GetVarPtr (AsnStr1);
            if V <> nil then
            begin
              ParStr := AsnStr2;
              case V^.VarType of
                ctPString  : CmdOK := GetStrParam;
                ctPLongInt : CmdOK := GetIntParam;
                ctPDouble  : CmdOK := GetDblParam
              end;
              if CmdOk then
              begin
                if ParamVar then
                  V2 := ScriptEng^.GetVarPtr (ParStr)
                else {create constant var}
                begin
                  case V^.VarType of
                    ctPString  : V2 := MakeStrNode (ParStr);
                    ctPLongInt : V2 := MakeIntNode (ParInt);
                    ctPDouble  : V2 := MakeDblNode (ParDbl)
                  end;
                  ScriptEng^.AddVar (V2);
                end;
                if V2 <> nil then
                begin
                  CmdOk := (V^.VarType = V2^.VarType);
                  if CmdOK then
                  begin
                    V3 := MakeVarAsnNode (V,V2);
                    ScriptEng^.AddVar (V3);
                    N := MakeCmdNode (CmdNum,V3);
                    CmdOk := ScriptEng^.AddCommand (N)
                  end
                  else
                    LogErr ('var incorrect type '+ParStr)
                end
                else
                begin
                  LogErr ('undefined var '+ParStr);
                  CmdOk := false
                end
              end
            end
            else
            begin
              LogErr ('undefined var '+AsnStr1);
              CmdOk := false
            end
          end
          else {get params failed}
            CmdOk := false
        end
        else
        begin
          LogErr ('var required');
          CmdOk := false
        end
      end;

      ctScrVarStr,
      ctScrVarInt,
      ctScrVarDbl
{$IFDEF UseParadox}
      ,ctScrVarTab
{$ENDIF}
      : {create new var}
      begin
        case CmdNum of
          ctScrVarStr : CmdOK := GetStrParam;
          ctScrVarInt : CmdOK := GetIntParam;
          ctScrVarDbl : CmdOK := GetDblParam
{$IFDEF UseParadox}
          ;ctScrVarTab : CmdOK := GetStrParam
{$ENDIF}
        end;
        if CmdOk then
        begin
          if ParamVar then
          begin
            if ScriptEng^.GetVarPtr (ParStr) = nil then
            begin
              case CmdNum of
                ctScrVarStr : V := MakeStrNode (''); {nil string}
                ctScrVarInt : V := MakeIntNode (0);  {new longint}
                ctScrVarDbl : V := MakeDblNode (0.0) {new double}
{$IFDEF UseParadox}
                ;ctScrVarTab : V := MakeTabNode      {new table}
{$ENDIF}
              end;
              V^.VarName := NewStr (UpCaseStr (ParStr)); {alloc var name}
              ScriptEng^.AddVar (V);                     {add to var list}
              CmdOk := true
            end
            else
            begin
              LogErr ('duplicate var name');
              CmdOk := false
            end
          end
          else
          begin
            LogErr ('var name must start with A..Z');
            CmdOk := false
          end
        end
      end;

{$IFDEF UseParadox}
      ctScrTabName,
      ctScrTabError,
      ctScrTabOpen,
      ctScrBlobImp,
      ctScrBlobGet,
      ctScrBlobOpen,
      ctScrBlobClose,
      ctScrRecSrcPri,
      ctScrRecSrcSec,
      ctScrFldGet,
      ctScrFldPut,
      ctScrTabClose,
      ctScrTabHome,
      ctScrTabEnd,
      ctScrTabNext,
      ctScrTabPrev,
      ctScrRecDel,
      ctScrRecGet,
      ctScrRecPut,
      ctScrRecUpd,
      ctScrRecClr : {paradox table functions}
      begin
        if (ParStr <> '') and
        (UpCase (ParStr[1]) in ['A'..'Z']) then
        begin
          case CmdNum of
            ctScrTabName,
            ctScrTabError,
            ctScrFldGet,
            ctScrFldPut,
            ctScrBlobImp,
            ctScrBlobGet,
            ctScrBlobOpen,
            ctScrBlobClose,
            ctScrRecSrcPri,
            ctScrRecSrcSec,
            ctScrTabOpen : CmdOk := GetAssignParam;
            ctScrTabClose,
            ctScrTabEnd,
            ctScrTabNext,
            ctScrTabPrev,
            ctScrRecDel,
            ctScrRecGet,
            ctScrRecPut,
            ctScrRecUpd,
            ctScrRecClr,
            ctScrTabHome :
            begin
              CmdOk := GetStrParam;
              AsnStr1 := ParStr;
              AsnStr2 := ParStr
            end
          end;
          if CmdOk then
          begin
            V := ScriptEng^.GetVarPtr (AsnStr1);
            if V <> nil then
            begin
              ParStr := AsnStr2;
              if V^.VarType = ctPTable then
              begin
                case CmdNum of
                  ctScrTabName,
                  ctScrTabError : CmdOk := GetStrParam;
                  ctScrFldGet,
                  ctScrFldPut,
                  ctScrBlobImp,
                  ctScrBlobGet,
                  ctScrBlobOpen,
                  ctScrBlobClose,
                  ctScrRecSrcPri,
                  ctScrRecSrcSec,
                  ctScrTabOpen  : CmdOk := GetIntParam
                end;
                if CmdOk then
                begin
                  case CmdNum of
                    ctScrTabName,
                    ctScrTabError,
                    ctScrFldGet,
                    ctScrFldPut,
                    ctScrBlobImp,
                    ctScrBlobGet,
                    ctScrBlobOpen,
                    ctScrBlobClose,
                    ctScrRecSrcPri,
                    ctScrRecSrcSec,
                    ctScrTabOpen :
                    begin
                      if ParamVar then
                         V2 := ScriptEng^.GetVarPtr (ParStr)
                       else {create constant var}
                       begin
                         case CmdNum of
                           ctScrTabName : V2 := MakeStrNode (ParStr);
                           ctScrFldGet,
                           ctScrFldPut,
                           ctScrBlobImp,
                           ctScrBlobGet,
                           ctScrBlobOpen,
                           ctScrBlobClose,
                           ctScrRecSrcPri,
                           ctScrRecSrcSec,
                           ctScrTabOpen : V2 := MakeIntNode (ParInt)
                         end;
                         ScriptEng^.AddVar (V2)
                       end
                    end
                  end;
                  if V2 <> nil then
                  begin
                    case CmdNum of
                      ctScrTabName,
                      ctScrTabError : CmdOk := V2^.VarType = ctPString;
                      ctScrFldGet,
                      ctScrFldPut,
                      ctScrBlobImp,
                      ctScrBlobGet,
                      ctScrBlobOpen,
                      ctScrBlobClose,
                      ctScrRecSrcPri,
                      ctScrRecSrcSec,
                      ctScrTabOpen : CmdOk := V2^.VarType = ctPLongint
                    end;
                    case CmdNum of
                      ctScrTabName,
                      ctScrTabError,
                      ctScrFldGet,
                      ctScrFldPut,
                      ctScrBlobImp,
                      ctScrBlobGet,
                      ctScrBlobOpen,
                      ctScrBlobClose,
                      ctScrRecSrcPri,
                      ctScrRecSrcSec,
                      ctScrTabOpen :
                      begin
                        if CmdOK then
                        begin
                          V3 := MakeVarAsnNode (V,V2);
                          ScriptEng^.AddVar (V3);
                          N := MakeCmdNode (CmdNum,V3);
                          CmdOk := ScriptEng^.AddCommand (N)
                        end
                        else
                          LogErr ('var incorrect type '+ParStr)
                      end;
                      ctScrTabClose,
                      ctScrTabEnd,
                      ctScrTabNext,
                      ctScrTabPrev,
                      ctScrRecDel,
                      ctScrRecGet,
                      ctScrRecPut,
                      ctScrRecUpd,
                      ctScrRecClr,
                      ctScrTabHome :
                      begin
                        N := MakeCmdNode (CmdNum,V);
                        CmdOk := ScriptEng^.AddCommand (N)
                      end
                    end
                  end
                  else
                  begin
                    LogErr ('undefined var '+ParStr);
                    CmdOk := false
                  end
                end
              end
              else
              begin
                LogErr ('var incorrect type '+ParStr);
                CmdOk := false
              end
            end
            else
            begin
              LogErr ('undefined var '+AsnStr1);
              CmdOk := false
            end
          end
        end
        else
        begin
          LogErr ('var required');
          CmdOk := false
        end
      end;

{$ENDIF}

      ctScrGetBlock,
      ctSrcDelayTics,
      ctSrcConStat,
      ctSrcPadRight,
      ctScrWaitSecs,
      ctScrMouseX,
      ctScrMouseY : {get longint param}
      begin
        if GetIntParam then
        begin
          if ParamVar then
          begin
            V := ScriptEng^.GetVarPtr (ParStr);
            if V <> nil then
            begin
              if V^.VarType = ctPLongInt then
              begin
                N := MakeCmdNode (CmdNum,V);
                CmdOk := ScriptEng^.AddCommand (N)
              end
              else
              begin
                LogErr ('var incorrect type '+ParStr);
                CmdOk := false
              end
            end
            else
            begin
              LogErr ('undefined var '+ParStr);
              CmdOk := false
            end
          end
          else {create var for constant}
          begin
            V := MakeIntNode (ParInt);
            ScriptEng^.AddVar (V);
            N := MakeCmdNode (CmdNum,V);
            CmdOk := ScriptEng^.AddCommand (N)
          end
        end
        else
          CmdOk := false
      end;

      ctScrLabel : {create label}
      begin
        if GetStrParam then
        begin
          if ParamVar then {make sure label starts with a..z}
          begin
            if GetLabelPtr (ParStr) = nil then
            begin
              L := New (PLabelNode,Init);
              L^.Name := NewStr (UpCaseStr (ParStr));
              L^.Loc := ScriptEng^.NodeCollPtr^.Count;
              CmdOk := AddLabel (L)
            end
            else
            begin
              LogErr ('duplicate label');
              CmdOk := false
            end
          end
          else
          begin
            LogErr ('label must start with A..Z');
            CmdOk := false
          end
        end
        else
          CmdOk := false
      end;

      ctScrCall,
      ctScrGoto : {goto label}
      begin
        if GetStrParam then
        begin
          if ParamVar then
          begin              {node location is resolved on pass 2}
            N := MakeCmdNode (CmdNum,nil);
            CmdOk := ScriptEng^.AddCommand (N)
          end
          else
          begin
            LogErr ('label must start with A..Z');
            CmdOk := false
          end
        end
        else
          CmdOk := false
      end;

      ctScrInpWait,
      ctScrReturn,
      ctScrZmodemD,
      ctScrCapOff,
      ctScrTxtClose,
      ctScrTxtGet,
      ctScrDraw,
      ctScrDrawList,
      ctScrInit,
      ctScrDial,
      ctScrHangUp,
      ctScrLogOn,
      ctScrLogOff,
      ctScrAbortOn,
      ctScrAbortOff,
      ctScrWriLogOn,
      ctScrWriLogOff,
      ctScrEchoOn,
      ctScrEchoOff,
      ctScrLock,
      ctScrUnlock,
      ctScrCloseIni,
      ctScrEnd : {no params}
      begin
        N := MakeCmdNode (CmdNum,nil);
        CmdOk := ScriptEng^.AddCommand (N)
      end

    end
  end
  else
    LogErr ('invalid command');
  ProcessCommand := CmdOk
end;

begin
  S := TrimStr (S); {trim head/tail spaces}
  ParseLine (S);
  if S[1] <> ';' then
    Pass1 := ProcessCommand
  else
    Pass1 := true {comment}
end;

{
Pass 2 resolves forward branches.
}

function TScriptCompile.Pass2 (S : string) : boolean;

{process commands}

function ProcessCommand : boolean;

var

  CmdOk : boolean;
  N : PScriptNode;
  V : PVarNode;
  L : PLabelNode;

begin
  CmdOk := FindCommand;
  case CmdNum of
    ctScrSend,
    ctScrWaitFor,
    ctScrGetResp,
    ctScrSetResp,
    ctScrSendCap,
    ctScrIfEqu,
    ctScrIfNotEqu,
    ctScrIfLess,
    ctScrIfGreat,
    ctScrIfLessEq,
    ctScrIfGreatEq,
    ctScrVarAsn,
    ctScrVarAdd,
    ctScrVarSub,
    ctScrVarMul,
    ctScrVarDiv,
    ctScrSubStr,
    ctScrGetIni,
    ctScrPutIni,
{$IFDEF UseParadox}
    ctScrTabName,
    ctScrTabCreate,
    ctScrTabError,
    ctScrTabOpen,
    ctScrBlobImp,
    ctScrBlobGet,
    ctScrBlobOpen,
    ctScrBlobClose,
    ctScrRecSrcPri,
    ctScrRecSrcSec,
    ctScrFldGet,
    ctScrFldPut,
    ctScrTabClose,
    ctScrTabHome,
    ctScrTabEnd,
    ctScrTabNext,
    ctScrTabPrev,
    ctScrRecDel,
    ctScrRecGet,
    ctScrRecPut,
    ctScrRecUpd,
    ctScrRecClr,
{$ENDIF}
    ctScrReturn,
    ctScrGetBlock,
    ctScrWaitSecs,
    ctScrMouseX,
    ctScrMouseY,
    ctSrcDelayTics,
    ctSrcConStat,
    ctSrcPadRight,
    ctScrCapApp,
    ctScrCapNew,
    ctScrTxtOpen,
    ctScrEraseFil,
    ctScrUnZipFil,
    ctScrZmodemD,
    ctScrZmodemU,
    ctScrXModemU,
    ctScrSepChar,
    ctScrGetChar,
    ctScrSubmit,
    ctScrSendLog,
    ctScrSendList,
    ctScrOpenIni,
    ctScrEditFile,
    ctScrInpBox,
    ctScrListBox,
    ctScrCapOff,
    ctScrTxtClose,
    ctScrTxtGet,
    ctScrDraw,
    ctScrDrawList,
    ctScrInit,
    ctScrInpWait,
    ctScrDial,
    ctScrHangUp,
    ctScrLogOn,
    ctScrLogOff,
    ctScrAbortOn,
    ctScrAbortOff,
    ctScrWriLogOn,
    ctScrWriLogOff,
    ctScrEchoOn,
    ctScrEchoOff,
    ctScrLock,
    ctScrUnlock,
    ctScrCloseIni,
    ctScrEnd : {these commands generate script nodes}
    begin
      Inc (NodeNum);
      CmdOk := true
    end;

    ctScrCall,
    ctScrGoto : {resolve node address from label}
    begin
      L := GetLabelPtr (ParStr);
      if L <> nil then
      begin
        V := New (PVarNode,Init);
        V^.VarType := ctPWord;
        V^.VarDataPtr := New (PWord);
        PWord (V^.VarDataPtr)^ := L^.Loc;
        ScriptEng^.AddVar (V);
        N := PScriptNode (ScriptEng^.NodeCollPtr^.At (NodeNum));
        N^.ScDataPtr := V;
        Inc (NodeNum);
        CmdOk := true
      end
      else
      begin
        LogErr ('label not found '+ParStr);
        CmdOk := false
      end
    end
  end;
  ProcessCommand := CmdOk
end;

begin
  S := TrimStr (S); {trim head/tail spaces}
  if S[1] <> ';' then
  begin
    ParseLine (S);
    Pass2 := ProcessCommand
  end
  else
    Pass2 := true   {only ; in line}
end;

{
Compile script source.
}

function TScriptCompile.Compile : boolean;

var

  CompileOk : boolean;
  SLine : string;
  N : PScriptNode;

begin
  PTermWin (TWin)^.UpdateLog ('Pass 1 '+EditWin^.Editor^.FileName);
  CompileOk := true;                                {exit compile flag}
  SLine := '';
  while (GetLine (SLine)) and (CompileOk) do
  begin
    Inc (CurLine);
    if SLine <> '' then
      CompileOk := Pass1 (SLine)
  end;
  if CompileOk then             {if pass 1 ok then do pass 2}
  begin
    N := New (PScriptNode,Init);
    N^.ScCommand := ctScrEnd;
    ScriptEng^.AddCommand (N);
    PTermWin (TWin)^.UpdateLog ('Pass 2 ');
    CurLine := 0;               {reset editor positions}
    CurChar := 0;
    LastChar := 0;
    while (GetLine (SLine)) and (CompileOk) do
    begin
      Inc (CurLine);
      if SLine <> '' then
        CompileOk := Pass2 (SLine)
    end;
    if CompileOk then {if pass 2 ok then show compiled lines, etc.}
    begin
      SLine := IntToStr (CurLine)+' lines, '+
      IntToStr (ScriptEng^.NodeCollPtr^.Count)+' commands, '+
      IntToStr (ScriptEng^.VarCollPtr^.Count)+' vars';
      PTermWin (TWin)^.UpdateLogRaw (SLine,0);
    end
  end;
  Compile := CompileOk
end;

{
Script que engine processes scripts in order added to the que.
}

constructor TScriptQue.Init;

begin
  QueColl := New (PCollection,Init (0,10)); {que node collection}
  LastDone := false
end;

{
Dispose que collection.
}

destructor TScriptQue.Done;

begin
  Dispose (QueColl,Done); {dispose que nodes}
end;

{
Add a script file to que.
}

procedure TScriptQue.AddToQue (FileName : PathStr);

var

  Q : PScrQueNode;

begin
  Q := New (PScrQueNode, Init);
  Q^.ScrName := FileName;
  QueColl^.Insert (Q)
end;

{
Release next script.
}

procedure TScriptQue.DoTask;

var

  FN : PathStr;
  F : file;
  R : TRect;
  C : TScriptCompile;
  E : PCyEditWindow;

begin
  if QueColl^.Count > 0 then
  begin
    FN := PScrQueNode (QueColl^.At (0))^.ScrName;
    Assign (F,FN);
    {$I-} Reset (F); {$I+}
    if IoResult = 0 then
    begin
      {$I-} Close (F); {$I+}
      DeskTop^.GetExtent (R);
      E := New (PCyEditWindow, Init (R,FN,wnNoNumber));
      E^.Hide;
      Application^.InsertWindow (E);
      if PTermWin (TermWin)^.ScriptEng <> nil then
        Dispose (PTermWin (TermWin)^.ScriptEng,Done); {dispose current compiled script}
      PTermWin (TermWin)^.ScriptEng := New (PScriptEng,Init (TermWin));
  {$IFDEF UseParadox}
      PTermWin (TermWin)^.ScriptEng^.EnginePtr := EnginePtr;
      PTermWin (TermWin)^.ScriptEng^.DataBasePtr := DataBasePtr;
  {$ENDIF}
      C.Init (E,TermWin);
      if C.Compile then
      begin
        LastDone := false;
        PTermWin (TermWin)^.CmdState :=
        PTermWin (TermWin)^.CmdState or ctCmdScript or ctCmdLockWin; {start script}
        PTermWin (TermWin)^.UpdateLog ('Start script')
      end;
      C.Done;
      E^.Close;
      QueColl^.Free (QueColl^.At (0))
    end
    else
    begin
      PTermWin (TermWin)^.UpdateLog ('Error opening '+FN);
      QueColl^.Free (QueColl^.At (0))
    end
  end
  else
  begin
    if not LastDone then
    begin
      LastDone := true;
      PTermWin (TermWin)^.CmdState :=
      PTermWin (TermWin)^.CmdState and not ctCmdLockWin {unlock window}
    end
  end
end;

{
TTermRec terminal record is a streamable object which can be saved with the
desktop or other streams.
}

{
Load entire record structure.
}

constructor TTermRec.Load (var S : TStream);

begin
  S.Read (Name,SizeOf (Name));
  S.Read (PhoneNum,SizeOf (PhoneNum));
  S.Read (DLPath,SizeOf (DLPath));
  S.Read (InitStr,SizeOf (InitStr));
  S.Read (ComName,SizeOf (ComName));
  S.Read (Baud,SizeOf (Baud));
  S.Read (Parity,SizeOf (Parity));
  S.Read (DataBits,SizeOf (DataBits));
  S.Read (StopBits,SizeOf (StopBits));
  S.Read (ComOptions,SizeOf (ComOptions));
  S.Read (TermOpts,SizeOf (TermOpts))
end;

{
Store entire record structure.
}

procedure TTermRec.Store (var S : TStream);

begin
  S.Write (Name,SizeOf (Name));
  S.Write (PhoneNum,SizeOf (PhoneNum));
  S.Write (DLPath,SizeOf (DLPath));
  S.Write (InitStr,SizeOf (InitStr));
  S.Write (ComName,SizeOf (ComName));
  S.Write (Baud,SizeOf (Baud));
  S.Write (Parity,SizeOf (Parity));
  S.Write (DataBits,SizeOf (DataBits));
  S.Write (StopBits,SizeOf (StopBits));
  S.Write (ComOptions,SizeOf (ComOptions));
  S.Write (TermOpts,SizeOf (TermOpts))
end;

{
Stand alone ANSI/VT100 emulator object converts numeric (0;31m) params on the
fly.  Keyboard redefinition commands (0;87;"FORMAT A:";13p) store numeric
params as normal and save string params between "".  See DOS or related
manual for more info on ANSI escape sequences.
}

constructor TAnsiEmu.Init (TxtColor : word);

begin
  Attr := TxtColor; {set start up attr}
  ChrMask := $ff;   {default to 8 bit char}
  G0CharSet := ctASCII;
  G1CharSet := ctASCII;     {default both char sets to north american ascii}
  CurCharSet := @G0CharSet; {current char set g0}
  AnsiState := ctWaiting
end;

{
Parse ANSI input and convert to commands.
}

procedure TAnsiEmu.ProcessChar (C : Char);

var

  I : integer;

{
Get last param, handle null params and VT100 emulation.
}

procedure GetLastParam;

begin
  if ParStr <> '' then
    IntParam[ParamIndex] := StrToInt (ParStr)
  else
  begin
    if (C = 'J') or (C = 'K') then
    begin
      if AnsiOptions and ctAnsiVT100 <> 0 then {handle vt100 emulation}
        IntParam[ParamIndex] := 0
      else
        IntParam[ParamIndex] := 2
    end
    else
    begin
      if C <> 'm' then
        IntParam[ParamIndex] := 1                {handle null param}
      else
        IntParam[ParamIndex] := 0
    end
  end
end;

const

  lineChars : array[0..31] of byte = (
  32,4,176,9,12,13,10,248,241,18,11,217,191,218,192,197,196,
  196,196,196,196,195,180,193,194,179,243,242,227,216,156,7
  );

begin
  byte (AnsiChr) := byte (C) and ChrMask;

  case AnsiState of

    ctWaiting :
    begin
      case AnsiChr of
        ctEsc :
        begin {got escape}
          AnsiState := ctEscCode;
          AnsiCmd := ctEmuNone
        end;
        ctSI : CurCharSet := @G0CharSet; {shift in for g0}
        ctSO : CurCharSet := @G1CharSet; {shift out for g1}
        ctFF :
        begin {got form feed}
          AnsiCmd := ctEmuClrScr {form feed char clears screen}
        end
        else
        begin
          if (CurCharSet^ = ctLineDrawing) and {xlate graphics characters}
          (AnsiChr > #94) and (AnsiChr < #128) then
            AnsiChr := Chr (lineChars[byte (AnsiChr) - 95]);
          AnsiCmd := ctEmuChar {wasn't any chars above, so this is a normal char}
        end
      end
    end;

    ctEscCode :
    begin
      AnsiState := ctWaiting;
      case AnsiChr of

        '[' : {parse ansi params}
        begin
          ParStr := '';
          ParamIndex := 0;
          AnsiState := ctAnsiParse;
          AnsiCmd := ctEmuNone
        end;

        'D' : {index down }
          AnsiCmd := ctEmuDown;

        'E' : {carriage return/line feed combination}
          AnsiCmd := ctEmuCRLF;

        'M' : {reverse index}
          AnsiCmd := ctEmuUp;

        'H' : {set tab stop}
          AnsiCmd := ctEmuSetTabStop;

        '7' : {save cursor description}
        begin
          SaveAttr := Attr;
          AnsiCmd := ctEmuSaveCurPos
        end;

        '8' : {restore cursor description}
        begin
          Attr := SaveAttr;
          AnsiCmd := ctEmuResCurPos
        end;

        '=' : ;  {enable application keypad}

        '>' : ;  {enable numeric keypad}

        'c' : {reset terminal to power on defaults}
          AnsiCmd := ctEmuPowerOn;

        '(' : {select character set g0}
          AnsiState := ctG0Parse;

        ')' :  {select character set g1}
          AnsiState := ctG1Parse;

        '#' : ; {set double high/wide characters}

        ^X,
        ^Z  :  {cancel escape sequence}
          AnsiCmd := ctEmuNone;

        'Z' : ; {transmit the terminal id}

        '\' :  ;      {could these mean something}
        '<' :  ;
        'P' :  ;
        '*' :
        else
          AnsiCmd := ctEmuChar {unknown sequence}
      end
    end;

    ctAnsiParse :
    begin
      case AnsiChr of

        '0'..'9' : {numeric param}
        begin
          if byte (ParStr[0]) < ctAnsiStrMax then
          begin {store param char for later processing}
            ParStr := ParStr+AnsiChr;
            AnsiCmd := ctEmuNone
          end
          else {param buffer overflow}
            AnsiCmd := ctEmuError
        end;

        ';' : {param seperator, so convert param to integer}
        begin
          if ParamIndex <= ctAnsiIntMax then
          begin
            if ParStr <> '' then {param not null, so convert}
            begin
              IntParam[ParamIndex] := StrToInt (ParStr);
              Inc (ParamIndex);
              ParStr := '';
              AnsiCmd := ctEmuNone
            end
          end
          else
            AnsiCmd := ctEmuError
        end;

        'm' : {set color}
        begin
          GetLastParam;
          X := Attr;
          for I := 0 to ParamIndex do
          begin
            if AnsiOptions and ctAnsiInverse <> 0 then
            begin {if inverse then swap color nibbles}
              X := X and $77;
              X := (X shl 4) or (X shr 4)
            end;
            case IntParam[I] of
              0       :
              begin
                X := $07;                      {reset to white on black}
                AnsiOptions :=
                AnsiOptions and not ctAnsiAttr {clear all attr flags}
              end;
              1,4     : AnsiOptions :=
                        AnsiOptions or ctAnsiIntense;      {bold}
              2,22,24 : AnsiOptions :=
                        AnsiOptions and not ctAnsiIntense; {dim}
              5       : AnsiOptions :=
                        AnsiOptions or ctAnsiBlink;        {blink}
              7       : AnsiOptions :=
                        AnsiOptions or ctAnsiInverse;      {inverse}
              8       : AnsiOptions :=
                        AnsiOptions or ctAnsiInvis;        {invisible}
              25      : AnsiOptions :=
                        AnsiOptions and not ctAnsiBlink;   {cancel blink}
              27      : AnsiOptions :=
                        AnsiOptions and not ctAnsiInverse; {cancel inverse}

              30      : X := (X and $f8) or $00; {black}
              31      : X := (X and $f8) or $04; {red}
              32      : X := (X and $f8) or $02; {green}
              33      : X := (X and $f8) or $06; {yellow}
              34      : X := (X and $f8) or $01; {blue}
              35      : X := (X and $f8) or $05; {magenta}
              36      : X := (X and $f8) or $03; {cyan}
              37      : X := (X and $f8) or $07; {white}

              40      : X := (X and $8f) or $00; {black}
              41      : X := (X and $8f) or $40; {red}
              42      : X := (X and $8f) or $20; {green}
              43      : X := (X and $8f) or $60; {yellow}
              44      : X := (X and $8f) or $10; {blue}
              45      : X := (X and $8f) or $50; {magenta}
              46      : X := (X and $8f) or $30; {cyan}
              47      : X := (X and $8f) or $70; {white}
            end
          end;
          if AnsiOptions and ctAnsiInverse <> 0 then
            X := (X shl 4) or (X shr 4);  {if inverse then swap color nibbles}
          if AnsiOptions and ctAnsiInvis <> 0 then
            X := $00;                     {invisiable is black on black}
          if AnsiOptions and ctAnsiIntense <> 0 then
            X := X or $08;                {set forground intensity bit}
          if AnsiOptions and ctAnsiBlink <> 0 then
            X := X or $80;                {set blink bit}
          Attr := X;                      {save result}
          AnsiCmd := ctEmuSetAttr
        end;

        'f', 'H' : {set cursor position}
        begin
          GetLastParam;
          Y := IntParam[0];
          X := IntParam[1];
          AnsiCmd := ctEmuGotoXY
        end;

        'A' : {cursor up}
        begin
          GetLastParam;
          Y := IntParam[0];
          AnsiCmd := ctEmuUp
        end;

        'B' : {cursor down}
        begin
          GetLastParam;
          Y := IntParam[0];
          AnsiCmd := ctEmuDown
        end;

        'C' : {cursor right}
        begin
          GetLastParam;
          X := IntParam[0];
          AnsiCmd := ctEmuRight
        end;

        'D' : {cursor left}
        begin
          GetLastParam;
          X := IntParam[0];
          AnsiCmd := ctEmuLeft
        end;

        'J' : {clear screen}
        begin
          GetLastParam;
          case IntParam[0] of
            0 : AnsiCmd := ctEmuClrBelow;
            1 : AnsiCmd := ctEmuClrAbove;
            2 : AnsiCmd := ctEmuClrScr
          else
            AnsiCmd := ctEmuError
          end
        end;

        'K' : {clear line}
        begin
          GetLastParam;
          case IntParam[0] of
            0 : AnsiCmd := ctEmuClrEndLine;
            1 : AnsiCmd := ctEmuClrStartLine;
            2 : AnsiCmd := ctEmuClrLine
          else
            AnsiCmd := ctEmuError
          end
        end;

        '=','?' : AnsiCmd := ctEmuNone; {set/reset mode seperators}

        'h' : {set video mode}
        begin
          GetLastParam;
          X := IntParam[0];
          AnsiCmd := ctEmuSetMode
        end;

        'l' : {reset video mode}
        begin
          GetLastParam;
          X := IntParam[0];
          AnsiCmd := ctEmuResetMode
        end;

        's' : AnsiCmd := ctEmuSaveCurPos; {save cursor pos}

        'u' : AnsiCmd := ctEmuResCurPos;  {restore cursor pos}

        'n' : AnsiCmd := ctEmuDevStatRep; {send cursor pos}

        'L' : AnsiCmd := ctEmuInsLine; {insert lines}

        'M' : AnsiCmd := ctEmuDelLine; {delete lines}

        '@' : AnsiCmd := ctEmuInsChar; {insert chars}

        'P' : AnsiCmd := ctEmuDelChar; {delete chars}

        'p' : {ibm keyboard remap}
        begin
          GetLastParam;
          X := IntParam[0];
          AnsiCmd := ctEmuKeyRemap
        end;

        '"' : {start quote mode}
        begin
          AnsiState := ctKeyParse;
          AnsiCmd := ctEmuNone
        end
        else {unrecoginized command}
        begin
          AnsiState := ctWaiting;
          AnsiCmd := ctEmuError
        end
      end;
      if AnsiCmd <> ctEmuNone then {got command or error, so}
        AnsiState := ctWaiting
    end;

    ctG0Parse :
    begin
      AnsiState := ctWaiting;
      AnsiCmd := ctEmuNone;
      case AnsiChr of
        'B' : G0CharSet := ctASCII; {North American ASCII set}
        '0' : G0CharSet := ctLineDrawing; {Line Drawing}
        '1' : G0CharSet := ctASCII; {Alternative Character}
        '2' : G0CharSet := ctLineDrawing; {Alternative Line drawing}
        'A' : G0CharSet := ctASCII; {British}
        'C' : G0CharSet := ctASCII; {Finnish}
        'E' : G0CharSet := ctASCII; {Danish or Norwegian}
        'H' : G0CharSet := ctASCII; {Swedish}
        'K' : G0CharSet := ctASCII; {German}
        'Q' : G0CharSet := ctASCII; {French Canadian}
        'R' : G0CharSet := ctASCII; {Flemish or French/Belgian}
        'Y' : G0CharSet := ctASCII; {Italian}
        'Z' : G0CharSet := ctASCII; {Spanish}
        '4' : G0CharSet := ctASCII; {Dutch}
        '5' : G0CharSet := ctASCII; {Finnish}
        '6' : G0CharSet := ctASCII; {Danish or Norwegian}
        '7' : G0CharSet := ctASCII; {Swedish}
        '=' : G0CharSet := ctASCII  {Swiss (French or German)}
      end
    end;

    ctG1Parse :
    begin
      AnsiState := ctWaiting;
      AnsiCmd := ctEmuNone;
      case AnsiChr of
        'B' : G1CharSet := ctASCII; {North American ASCII set}
        '0' : G1CharSet := ctLineDrawing; {Line Drawing}
        '1' : G1CharSet := ctASCII; {Alternative Character}
        '2' : G1CharSet := ctLineDrawing; {Alternative Line drawing}
        'A' : G1CharSet := ctASCII; {British}
        'C' : G1CharSet := ctASCII; {Finnish}
        'E' : G1CharSet := ctASCII; {Danish or Norwegian}
        'H' : G1CharSet := ctASCII; {Swedish}
        'K' : G1CharSet := ctASCII; {German}
        'Q' : G1CharSet := ctASCII; {French Canadian}
        'R' : G1CharSet := ctASCII; {Flemish or French/Belgian}
        'Y' : G1CharSet := ctASCII; {Italian}
        'Z' : G1CharSet := ctASCII; {Spanish}
        '4' : G1CharSet := ctASCII; {Dutch}
        '5' : G1CharSet := ctASCII; {Finnish}
        '6' : G1CharSet := ctASCII; {Danish or Norwegian}
        '7' : G1CharSet := ctASCII; {Swedish}
        '=' : G1CharSet := ctASCII  {Swiss (French or German)}
      end
    end;

    ctKeyParse :
    begin
      if byte (ParStr[0]) < ctAnsiStrMax then
      begin
        if AnsiChr <> '"' then {build param str until " terminator}
          ParStr := ParStr+AnsiChr
        else
        begin
          KeyStr := ParStr; {save redefine key string}
          ParStr := '';
          AnsiState := ctWaiting
        end;
        AnsiCmd := ctEmuNone
      end
      else {param buffer overflow}
      begin
        AnsiState := ctWaiting;
        AnsiCmd := ctEmuError
      end
    end

  end
end;

{
TAnsiTerm ANSI terminal using TAnsiEmu emulator and virtual view buffer.
}

{
Create virtual view buffer, fire up ANSI emulator, set default char color and
clear view.  If any lines cannot be allocated on the heap then they are set
to nil.  Your application should check the last line and make sure it's not
nil before inserting window.  DO NOT call any TAnsiTerm methods unless you
check the last line.
}

constructor TAnsiTerm.Init(var Bounds: TRect; AHScrollBar, AVScrollBar : PScrollBar;
                           GenOptsPtr : PTermGenOptsRec; APort : ctUartPortPtr);

var

  I : integer;

begin
  inherited Init (Bounds, AHScrollBar, AvScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  MaxBufChars := GenOptsPtr^.TermDraw;
  LineLen := GenOptsPtr^.TermWidth-1;
  Lines := GenOptsPtr^.TermLen-1;
  LineSize := (LineLen+1)*SizeOf (word);
  DrawBuf := MemAlloc ((Lines+1)*  {allocate line pointers}
  SizeOf (ctLineBufPtr));
  for I := 0 to Lines do           {allocate lines}
    DrawBuf^[I] := MemAlloc (LineSize);
  AnsiEmu.Init (Hi (ctCharColor)); {init ansi emulator}
  UPortPtr := APort;               {async pro abstract port object}
  DrawColor := ctCharColor;        {default view char color}
  SetLimit (LineLen+1,Lines+1);    {set scroller limits}
  if DrawBuf^[Lines] <> nil then   {clear view buffer if last line <> nil}
    ClearScr
end;

{
Dispose draw buffer.
}

destructor TAnsiTerm.Done;

var

  I : integer;

begin
  if DrawBuf <> nil then
  begin
    for I := 0 to Lines do
      if DrawBuf^[I] <> nil then
        FreeMem (DrawBuf^[I],LineSize);
    if DrawBuf <> nil then
      FreeMem (DrawBuf,(Lines+1)*SizeOf (ctLineBufPtr))
  end;
  inherited Done
end;

{
Draw view and position cursor.
}

procedure TAnsiTerm.Draw;

var

  Y : integer;

begin
  for Y := 0 to Size.Y-1 do
    WriteBuf (0,Y,Size.X,1,DrawBuf^[Delta.Y+Y]^[Delta.X]);
  SetCursor (XBuf-Delta.X,YBuf-Delta.Y);
  ShowCursor
end;

{
Adjust X and Y buffer position if values overflow.  The entire view buffer is
scrolled if there is an attempt to go below the end of buffer.
}

procedure TAnsiTerm.AdjustBuffer;

var

  I : integer;
  C : word;

begin
  if XBuf > LineLen then
  begin
    XBuf := 0;
    Inc (YBuf)
  end;
  if YBuf > Lines then
  begin
    for I := 1 to Lines do
      Move(DrawBuf^[I]^[0],DrawBuf^[I-1]^[0],LineSize);
    C := DrawColor or byte (ctSP);
    for I := 0 to LineLen do
      DrawBuf^[Lines]^[I] := C;
    YBuf := Lines
  end
end;

{
Track view buffer cursor.
}

procedure TAnsiTerm.TrackCursor;

var

  X,Y : integer;

begin
  if YBuf-Delta.Y >= Size.Y then
    Y := YBuf-Size.Y+1
  else
    if YBuf < Delta.Y then
      Y := YBuf
    else
      Y := Delta.Y;
  if XBuf-Delta.X >= Size.X then
    X := XBuf-Size.X+1
  else
    if XBuf < Delta.X then
      X := XBuf
    else
      X := Delta.X;
  if (Y <> Delta.Y) or (X <> Delta.X) then
    ScrollTo (X,Y)
end;

{
Put char in view buffer.  CR, LF, BS and Tab translated.  BS destructive
in local echo mode.
}

procedure TAnsiTerm.PutViewChar;

begin
  case AnsiEmu.AnsiChr of
    ctCR   : XBuf := 0;
    ctLF   : Inc (YBuf);
    ctBS   : if XBuf > 0 then
             begin
               Dec (XBuf);
               if TermOptions and ctLocalEcho <> 0 then
                 DrawBuf^[YBuf]^[XBuf] := DrawColor or byte (ctSP)
             end;
    ctTab  : Inc (XBuf,8);
    ctBell : ; {add sound if needed}
    else       {store char as is in buffer}
    begin
      DrawBuf^[YBuf]^[XBuf] := DrawColor or byte (AnsiEmu.AnsiChr);
      Inc (XBuf)
    end
  end;
  Inc (BufChars);
  AdjustBuffer
end;

{
Set draw color.
}

procedure TAnsiTerm.SetAttr;

begin
  DrawColor := AnsiEmu.X shl 8 {move color to hi byte}
end;

{
Set X,Y in view buffer.  Same as GotoXY with 0,0 starting point instead of
1,1.
}

procedure TAnsiTerm.SetBufXY;

begin
  if AnsiEmu.X-1 <= LineLen then {set x if not overflow}
    XBuf := AnsiEmu.X-1
  else
    XBuf := LineLen;
  if AnsiEmu.Y-1 <= Lines then   {set y if not overflow}
    YBuf := AnsiEmu.Y-1
  else
    YBuf := Lines;
  Inc (BufChars)
end;

{
Clear entire view buffer, position cursor and scroll to 0,0.
}

procedure TAnsiTerm.ClearScr;

var

  X,Y : integer;
  C : word;

begin
  C := DrawColor or byte (ctSP);
  for Y := 0 to Lines do
    for X := 0 to LineLen do
      DrawBuf^[Y]^[X] := C;
  XBuf := 0;
  YBuf := 0;
  TrackCursor;
  Inc (BufChars)
end;

{
Clear from cursor down.
}

procedure TAnsiTerm.ClearBelow;

var

  X,Y : integer;
  C : word;

begin
  C := DrawColor or byte (ctSP);
  for Y := YBuf to Lines do
    for X := 0 to LineLen do
      DrawBuf^[Y]^[X] := C;
  Inc (BufChars)
end;

{
Clear from cursor up.
}

procedure TAnsiTerm.ClearAbove;

var

  X,Y : integer;
  C : word;

begin
  C := DrawColor or byte (ctSP);
  for Y := 0 to YBuf do
    for X := 0 to LineLen do
      DrawBuf^[Y]^[X] := C;
  Inc (BufChars)
end;

{
Clear from cursor to end of line.
}

procedure TAnsiTerm.ClearEOL;

var

  X : integer;
  C : word;

begin
  C := DrawColor or byte (ctSP);
  for X := XBuf to LineLen do
    DrawBuf^[YBuf]^[X] := C;
  Inc (BufChars)
end;

{
Clear from cursor to start of line.
}

procedure TAnsiTerm.ClearSOL;

var

  X : integer;
  C : word;

begin
  C := DrawColor or byte (ctSP);
  for X := 0 to XBuf do
    DrawBuf^[YBuf]^[X] := C;
  Inc (BufChars)
end;

{
Clear entire line.
}

procedure TAnsiTerm.ClearLine;

var

  X : integer;
  C : word;

begin
  C := DrawColor or byte (ctSP);
  for X := 0 to LineLen do
    DrawBuf^[YBuf]^[X] := C;
  Inc (BufChars)
end;

{
Position buffer cursor up Y lines and handle overflow.
}

procedure TAnsiTerm.Up;

var

  Y : integer;

begin
  Y := YBuf-AnsiEmu.Y;
  if Y >= 0 then
    YBuf := Y
  else
    YBuf := 0;
  Inc (BufChars)
end;

{
Position buffer cursor down Y lines and handle overflow.
}

procedure TAnsiTerm.Down;

var

  Y : integer;

begin
  Y := YBuf+AnsiEmu.Y;
  if Y <= Lines then
    YBuf := Y
  else
    YBuf := Lines;
  Inc (BufChars)
end;

{
Position buffer cursor left X chars and handle overflow.
}

procedure TAnsiTerm.Left;

var

  X : integer;

begin
  X := XBuf-AnsiEmu.X;
  if X >= 0 then
    XBuf := X
  else
    XBuf := 0;
  Inc (BufChars)
end;

{
Position buffer cursor right X chars and handle overflow.
}

procedure TAnsiTerm.Right;

var

  X : integer;

begin
  X := XBuf+AnsiEmu.X;
  if X <= LineLen then
    XBuf := X
  else
    XBuf := LineLen;
  Inc (BufChars)
end;

{
Save buffer cursor position and attributes.
}

procedure TAnsiTerm.SaveCurPos;

begin
  SaveCurX := XBuf;
  SaveCurY := YBuf;
  SaveAttr := DrawColor;
  Inc (BufChars)
end;

{
Restore buffer cursor position and attributes.
}

procedure TAnsiTerm.RestoreCurPos;

begin
  XBuf := SaveCurX;
  YBuf := SaveCurY;
  DrawColor := SaveAttr;
  Inc (BufChars)
end;

{
Send ANSI cursor position out port.  This is also used to detect ANSI by most
ANSI compatible hosts.
}

procedure TAnsiTerm.DeviceStatus;

begin
  UPortPtr^.PutString (ctEsc+'['+IntToStr (YBuf-Delta.Y+1)+
  ';'+IntToStr (XBuf-Delta.X+1)+'R')
end;

{
Carriage return line feed combo.
}

procedure TAnsiTerm.CRLF;

begin
  XBuf := 0;
  Inc (YBuf);
  Inc (BufChars)
end;

{
Send char to ANSI emulator and process commands.  Changes are made to the
view buffer.
}

procedure TAnsiTerm.ProcAnsiChar (C : char);

begin
  AnsiEmu.ProcessChar (C);  {do ansi processing}
  if TermOptions and ctRawCap <> 0 then
    Message (Owner,evBroadcast,cmTermCapChar,@C) {capture}
  else
    if AnsiEmu.AnsiCmd = ctEmuChar then
      Message (Owner,evBroadcast,cmTermCapChar,@C); {capture}
  case AnsiEmu.AnsiCmd of   {handle ansi commands}
    ctEmuNone         : ;
    ctEmuChar         : PutViewChar;
    ctEmuGotoXY       : SetBufXY;
    ctEmuUp           : Up;
    ctEmuDown         : Down;
    ctEmuRight        : Right;
    ctEmuLeft         : Left;
    ctEmuSetAttr      : SetAttr;
    ctEmuClrScr       : ClearScr;
    ctEmuClrBelow     : ClearBelow;
    ctEmuClrAbove     : ClearAbove;
    ctEmuClrEndLine   : ClearEOL;
    ctEmuClrStartLine : ClearSOL;
    ctEmuClrLine      : ClearLine;
    ctEmuSaveCurPos   : SaveCurPos;
    ctEmuResCurPos    : RestoreCurPos;
    ctEmuCRLF         : CRLF;
    ctEmuDevStatRep   : DeviceStatus
  end
end;

{
Return text string.
}

function TAnsiTerm.GetTextStr (X, Y : integer) : string;

var

  I : integer;
  S : string;

begin
  for I := X to LineLen do
    byte (S[I-X+1]) := Lo (DrawBuf^[Y]^[I]);
  byte (S[0]) := LineLen-X;
  GetTextStr := S
end;

{
Handle terminal input by sending char out port.  Arrow keys are converted to
ANSI movements.  No longer checks PTermWin (Owner)^.CmdState = 0.
}

procedure TAnsiTerm.HandleEvent (var Event : TEvent);

begin
  inherited HandleEvent (Event);
  if Event.What = evKeyDown then
  begin
    if Event.CharCode <> #0 then
    begin
      UPortPtr^.PutString (Event.CharCode);
      TrackCursor; {draw after each char when typing}
      DrawView;
      BufChars := 0
    end
    else
      case Event.KeyCode of
        kbUp       : UPortPtr^.PutString (ctEsc+'[A');
        kbDown     : UPortPtr^.PutString (ctEsc+'[B');
        kbLeft     : UPortPtr^.PutString (ctEsc+'[D');
        kbRight    : UPortPtr^.PutString (ctEsc+'[C')
      else
        Exit
      end;
    ClearEvent (Event)
  end
end;

{
TTermWin uses a TAnsiView to create a scrollable and resiable ANSI terminal
window.
}

{
Open port, set hardware and/or software flow control, set FIFO buffering,
create ANSI view, set VT100 emulation and insert valid ANSI view.
}

constructor TTermWin.Init (WinTitle : TTitleStr; TermRecPtr : PTermRec;
                           GenOptsPtr : PTermGenOptsRec);

var

  R : TRect;
  HScrollBar, VScrollBar : PScrollBar;

begin
  Desktop^.GetExtent (R);
  R.B.Y := R.B.Y-7;
  inherited Init (R,WinTitle);
  Options := Options or ofTileable;
  Flags := wfMove+wfGrow+wfClose+wfZoom;
  GrowMode := gfGrowRel;
  Palette := dpBlueDialog;

  HScrollBar := StandardScrollBar (sbHorizontal or sbHandleKeyboard);
  Insert (HScrollBar);
  VScrollBar := StandardScrollBar (sbVertical or sbHandleKeyboard);
  Insert (VScrollBar);

  CaptureOn := false; {capture off by default}
  WriteLogOn := true; {writes to log on by default}
  TermRec := TermRecPtr;
  GenOptsRec := GenOptsPtr;
  RedialCnt := GenOptsRec^.Redial;
  with TermRec^ do
  begin
    ConnectBaud := Baud;
    UPort.InitCustom (ComName,Baud,Parity,DataBits,StopBits, {open port}
    GenOptsRec^.InBuf,GenOptsRec^.OutBuf,ComOptions);
    if GetAsyncStatus = ecOk then
    begin
      UPort.UartWin := @Self; {abort procedure needs window address}
      UPort.SetWaitCharProc (ctWaitChar); {waitforchar/string procedure}
      UpdateLog ('Opening port ');
      if TermOpts and ctHardFlow <> 0 then {use 90% full and 10% resume}
        UPort.HWFlowEnable (GenOptsRec^.InBuf-(GenOptsRec^.InBuf div 10),
        GenOptsRec^.InBuf div 10,TermOpts and ctHardFlow)
      else
        UPort.HWFlowDisable;
      if TermOpts and ctXONXOFF <> 0 then {set software flow control}
        UPort.SWFlowEnable (GenOptsRec^.InBuf-(GenOptsRec^.InBuf shr 2),
        GenOptsRec^.InBuf shr 2)          {use 75% full and 25% resume}
      else
        UPort.SWFlowDisable;
      if TermOpts and ctFIFO <> 0 then  {set fifo buffering}
      begin
        if ClassifyUart (UPort.GetBaseAddr, false) = U16550A then
        begin
          SetFifoBuffering (UPort.GetBaseAddr, True, 4);
          UpdateLog ('16550A UART FIFO buffering on')
        end
        else
          UpdateLog (UartTypeString[ClassifyUart (UPort.GetBaseAddr, false)]+
          ' UART does not support FIFO buffering')
      end;
      GetExtent (R);
      R.Grow (-1,-1);
      New (Term, Init (R,HScrollBar,VScrollBar, {create ansi view}
      GenOptsPtr,@UPort));
      Term^.TermOptions := TermOpts;            {set term options}
      if TermOpts and ctVT100 <> 0 then         {set vt100 emulation}
        Term^.AnsiEmu.AnsiOptions :=
        Term^.AnsiEmu.AnsiOptions or ctAnsiVT100;
      if TermOpts and ctStripHi <> 0 then       {set strip high bit}
      begin
        Term^.AnsiEmu.AnsiOptions :=
        Term^.AnsiEmu.AnsiOptions or ctAnsi7bit;
        Term^.AnsiEmu.ChrMask := $7f {strip high bit}
      end;
      if Application^.ValidView (Term) <> nil then
        Insert (Term);
      with GenOptsPtr^ do {assign modem responses}
      begin
        RespWaitStr :=    {possible dial responses}
        RespConnect+ctSepChar+
        RespError+ctSepChar+
        RespNoCarr+ctSepChar+
        RespNoAns+ctSepChar+
        RespNoTone+ctSepChar+
        RespBusy;
        OkStr :=          {response to non-dial commands}
        RespOK+ctSepChar+RespError
      end
    end
  end;
  ScriptQue.Init;
  ScriptQue.TermWin := @Self
end;

{
Close capture file and port.
}

destructor TTermWin.Done;

begin
  ScriptQue.Done;
  if ScriptEng <> nil then
    Dispose (ScriptEng,Done);
  CaptureClose;
  UpdateLog ('Closing port, '+StatusStr (GetAsyncStatus));
  UPort.Done;
  inherited Done
end;

{
Wait while CTS low.
}

procedure TTermWin.WaitCTSLow;

begin
  if CmdState and ctCmdCTSLow <> 0 then
  begin
    if not TimerExpired (TermTimer) then
    begin
      if UPort.CheckCTS then {if cts high then set command state}
        CmdState := CmdState and not (ctCmdCTSWait or ctCmdCTSLow)
    end
    else {cts stayed low until time out}
    begin
      UpdateLog ('CTS time out');
      CmdState := CmdState and not (ctCmdCTSWait or ctCmdCTSLow)
    end
  end
  else {set timer to wait for cts high}
  begin
    NewTimerSecs (TermTimer,GenOptsRec^.WaitCTS);
    CmdState := CmdState or ctCmdCTSLow
  end
end;

{
Hang up during dial phase with cancel char or lower DTR any other time.
}

procedure TTermWin.HangUp;

begin
  if CmdState and (ctCmdDialPause or ctCmdDial) = 0 then
  begin
    if CmdState and ctCmdDTRLow <> 0 then
    begin {time to raise dtr?}
      if TimerExpired (TermTimer) then
      begin
        UPort.SetDTR (True);
        CmdState := CmdState and not (ctCmdHangUp or ctCmdDTRLow)
      end
    end
    else {use dtr to hang up}
    begin
      UPort.SetDTR (False);
      CmdState := CmdState or ctCmdDTRLow;
      NewTimerSecs (TermTimer,GenOptsRec^.WaitDTR)
    end
  end
  else
  begin   {if in dial phase use cancel char}
    UPort.FlushOutBuffer;
    UPort.PutString (GenOptsRec^.CancelChar);
    CmdState := CmdState and not
    (ctCmdHangUp or ctCmdDial or
    ctCmdRespWait or ctCmdRespRec or ctCmdRespTime)
  end
end;

{
Display time, com port and string in window log if one is open.  Null strings
are ignored.
}

procedure TTermWin.UpdateLog (S : string);

var

  I : word;

begin
  if (WriteLogOn)  and (S <> '') then
  begin
    I := 1;
    while (I < 255) and (I <= byte (S[0])) do
    begin
      if S[I] = ctLF then
      begin
        SYSTEM.Delete (S,I,1);
        SYSTEM.Insert ('[LF]',S,I);
        Inc (I,3)
      end
      else
        if S[I] = ctCR then
        begin
          SYSTEM.Delete (S,I,1);
          SYSTEM.Insert('[CR]',S,I);
          Inc (I,3)
        end;
      Inc (I)
    end;
    S := TimeStr+' '+ComNameString (TermRec^.ComName)+' '+S;
    Message (Desktop,evBroadcast,cmUpdateLog,@S) {update log}
  end
end;

{
Display string in log window if one is open.  Null strings are ignored.
PosQue can be used to allow multiple updates (overwrites) on same line.
}

procedure TTermWin.UpdateLogRaw (S : string; PosQue : word);

var

  I : word;

begin
  if (WriteLogOn) and (S <> '') then
  begin
    I := 1;
    while (I < 255) and (I <= byte (S[0])) do
    begin
      if S[I] = ctLF then
      begin
        SYSTEM.Delete (S,I,1);
        SYSTEM.Insert ('[LF]',S,I);
        Inc (I,3)
      end
      else
        if S[I] = ctCR then
        begin
          SYSTEM.Delete (S,I,1);
          SYSTEM.Insert('[CR]',S,I);
          Inc (I,3)
        end;
      Inc (I)
    end;
    if PosQue > 0 then {back up chars}
      Message (Desktop,evBroadcast,cmUpdateLogBack,@S) {update log}
    else
      Message (Desktop,evBroadcast,cmUpdateLogRaw,@S) {update log}
  end
end;

{
Wait for modem's response to command or time out.
}

procedure TTermWin.GetResp;

begin
  if not TimerExpired (TermTimer) then
  begin
    UPort.ScanForMultiString (RespWaitStr,ctSepChar,RespStr,RespFound);
    if RespFound > 0 then
      CmdState := (CmdState and not ctCmdRespWait) or ctCmdRespRec
  end
  else
    CmdState := (CmdState and not ctCmdRespWait) or ctCmdRespTime
end;

{
Send command to modem and set response wait flag.
}

procedure TTermWin.PutCmd (Cmd, Resp : string; RSecs : word);

begin
  UPort.FlushOutBuffer;       {kill data waiting to go out}
  UPort.PutString (Cmd+ctCR); {send command string terminated by cr}
  CmdState := CmdState or ctCmdRespWait;
  RespStr := '';                 {null old response}
  RespWaitStr := Resp;           {possible responses}
  NewTimerSecs (TermTimer,RSecs) {set response timer}
end;

{
Create protocol objects and set up for background processing.
}

procedure TTermWin.InitXfer;

{add string length+1 to account for file list separator}

procedure StrSize (Item : pointer); far;

begin
  FileListSize := FileListSize+byte (PString (Item)^[0])+1
end;

{add file from string collection to async pro file list}

procedure AddToList (Item : pointer); far;

begin
  Protocol^.AddFileToList (UploadList,PString (Item)^)
end;

begin
  if CmdState and ctCmdDownload <> 0 then
    UpdateLog (ProtocolTypeString[ProtocolNum]+' download start')
  else
    UpdateLog (ProtocolTypeString[ProtocolNum]+' upload start');
  case ProtocolNum of {allocate/init protocol object by type}
    Ascii :
    begin
      New (ctAsciiProtocolPtr (Protocol), Init (@UPort));
      ctAsciiProtocolPtr (Protocol)^.ProtWin := @Self
    end;
    Kermit :
    begin
      New (ctKermitProtocolPtr (Protocol), Init (@UPort));
      ctKermitProtocolPtr (Protocol)^.ProtWin := @Self;
      ctKermitProtocolPtr (Protocol)^.SetOverwriteOption (WriteAnyway)
    end;
    Xmodem :
    begin
      New (ctXmodemProtocolPtr (Protocol), Init (@UPort,false,false));
      ctXmodemProtocolPtr (Protocol)^.ProtWin := @Self
    end;
    Xmodem1K :
    begin
      New (ctXmodemProtocolPtr (Protocol), Init (@UPort,true,false));
      ctXmodemProtocolPtr (Protocol)^.ProtWin := @Self
    end;
    Xmodem1KG :
    begin
      New (ctXmodemProtocolPtr (Protocol), Init (@UPort,true,true));
      ctXmodemProtocolPtr (Protocol)^.ProtWin := @Self
    end;
    Ymodem :
    begin
      New (ctYmodemProtocolPtr (Protocol), Init (@UPort,true,false));
      ctYmodemProtocolPtr (Protocol)^.ProtWin := @Self
    end;
    YmodemG :
    begin
      New (ctYmodemProtocolPtr (Protocol), Init (@UPort,true,true));
      ctYmodemProtocolPtr (Protocol)^.ProtWin := @Self
    end;
    Zmodem :
    begin
      New (ctZmodemProtocolPtr (Protocol), Init (@UPort));
      ctZmodemProtocolPtr (Protocol)^.ProtWin := @Self;
      if CmdState and ctCmdDownload <> 0 then {z modem file management}
        ctZmodemProtocolPtr (Protocol)^.SetFileMgmtOptions (
        true,false,WriteClobber)
      else
        ctZmodemProtocolPtr (Protocol)^.SetFileMgmtOptions (
        false,false,WriteClobber)
    end
  end;
  Protocol^.SetLogFileProc (ctLogStatus); {set log file procedure}
  Protocol^.SetAcceptFileFunc (ctAcceptFile); {set accept file function}
  if ProtocolNum in[Xmodem..YModemG] then {x/y modem set up}
    with ctXmodemProtocolPtr (Protocol)^ do
    begin
      SetBlockWait (RelaxedBlockWait);
      SetHandshakeWait (DefHandShakeWait,0);
      SetOverwriteOption (WriteAnyway)
    end;
  if CmdState and ctCmdDownload <> 0 then
  begin
    if ProtocolNum in[Xmodem..Xmodem1KG,Ascii] then {get x modem/ascii name}
      Protocol^.SetReceiveFilename (PString (FileListColl^.At (0))^)
    else                                             {set down load path}
      Protocol^.SetDestinationDirectory (TermRec^.DLPath);
    Protocol^.PrepareReceivePart
  end
  else
  begin
    FileListSize := 0;
    FileListColl^.ForEach (@StrSize);   {calc file list size}
    Inc (FileListSize);                 {adjust for end of list marker #0}
    Protocol^.MakeFileList (UploadList,FileListSize);
    FileListColl^.ForEach (@AddToList); {add strings to list}
    Protocol^.SetFileList (UploadList);
    Protocol^.SetNextFileFunc (NextFileList); {set procedural hook}
    Protocol^.PrepareTransmitPart             {prep xmit}
  end;
  Protocol^.SetActualBPS (ConnectBaud); {set actual baud to connect baud}
  NewTimerSecs (TermTimer,ctXferLogWait);     {set log timer}
  CmdState := (CmdState and not ctCmdXferInit) or ctCmdXfer
end;

{
Return current file name, bytes xfered, chars per sec and total errors.
}

function TTermWin.XferStatusStr : string;

var

  ElSecs,
  ChPerSec : longint;

begin
  ElSecs := Tics2Secs (Protocol^.GetElapsedTics);
  if (Protocol^.BytesTransferred > 0) and
  (ElSecs > 0) then {calc cps}
    ChPerSec := Protocol^.BytesTransferred div ElSecs
  else
    ChPerSec := 0;
  XferStatusStr :=                     {make string}
  PadRightStr (Protocol^.GetFileName,' ',12)+
  IntToRightStr (Protocol^.GetFileSize,10)+
  IntToRightStr (Protocol^.BytesTransferred,10)+
  IntToRightStr (ChPerSec,7)+
  IntToRightStr (Protocol^.GetTotalErrors,4)
end;

{
Process protocal and update xfer status.
}

procedure TTermWin.XferTask;

var

  StatStr : string;

begin
  if CmdState and ctCmdDownload <> 0 then
  begin {process protocol downloads}
    if Protocol^.ProtocolReceivePart = psFinished then
    begin
      UpdateLog (StatusStr (GetAsyncStatus));
      UpdateLog (ProtocolTypeString[ProtocolNum]+' down load end');
      Dispose (Protocol,Done);
      CmdState := CmdState and not
      (ctCmdDownload or ctCmdXfer or ctCmdXferStat)
    end
  end
  else
  begin {process protocol uploads}
    if Protocol^.ProtocolTransmitPart = psFinished then
    begin
      UpdateLog (StatusStr (GetAsyncStatus));
      UpdateLog (ProtocolTypeString[ProtocolNum]+' up load end');
      Protocol^.DisposeFileList (UploadList,FileListSize);
      Dispose (Protocol,Done);
      CmdState := CmdState and not (ctCmdXfer or ctCmdXferStat)
    end
  end;
  if (CmdState and ctCmdXferStat <> 0) and
  (TimerExpired (TermTimer)) then
  begin {update status in log window}
    NewTimerSecs (TermTimer,ctXferLogWait);
    if Protocol^.BytesTransferred > 0 then
    begin
      StatStr := XferStatusStr;
      UpdateLogRaw (StatStr,byte (StatStr[0]))
    end
  end
end;

{
Send modem initialize string and wait for OK, ERROR or time out.
}

procedure TTermWin.InitModem;

begin
  if CmdState and ctCmdGenPause <> 0 then
    GenPause
  else
    if CmdState and (ctCmdRespRec or ctCmdRespTime) = 0 then
    begin
      if TermRec^.InitStr <> '' then
        with GenOptsRec^ do
          PutCmd (TermRec^.InitStr,RespOK+ctSepChar+RespError,WaitResp)
      else
        CmdState := CmdState and not ctCmdInit
    end
    else
    begin
      if CmdState and ctCmdRespRec = 0 then {no response before time out}
        UpdateLog ('Response time out');
      CmdState := (CmdState and not         {pause before dial}
      (ctCmdInit or ctCmdRespRec or ctCmdRespTime)) or ctCmdGenPause
    end
end;

{
Display dial status in log.  Designed for multiple updates on one line.
}

procedure TTermWin.DialLog (Raw : boolean);

var

  DStr : string;

begin
  DStr := IntToStr (GenOptsRec^.Redial-RedialCnt+1)+
  ' of '+IntToStr (GenOptsRec^.Redial+1)+', '+RespStr;
  if Raw then
    UpdateLogRaw (DStr,byte (DStr[0]))
  else
    UpdateLogRaw (DStr,0)
end;

{
Dial phone number and set up DialWait timer.
}

procedure TTermWin.Dial;

var

  I : integer;

begin
  if CmdState and ctCmdDialPause <> 0 then
    DialPause
  else
    if CmdState and ctCmdGetRate <> 0 then
      GetConnectRate
    else
      if CmdState and (ctCmdRespRec or ctCmdRespTime) = 0 then
      begin
        if TermRec^.PhoneNum <> '' then
        begin
          if RedialCnt = GenOptsRec^.Redial then
            UpdateLog (TermRec^.Name+', '+TermRec^.PhoneNum+', ');
          RespStr := 'DIALING';
          RateStr := '';
          DialLog (true);
          with GenOptsRec^ do
            PutCmd (DialPrefix+TermRec^.PhoneNum,
            RespConnect+ctSepChar+RespError+ctSepChar+RespNoCarr+ctSepChar+
            RespNoAns+ctSepChar+RespNoTone+ctSepChar+RespBusy+
            ctSepChar+RespCarrier,GenOptsRec^.DialWait);
        end
        else
          CmdState := CmdState and not ctCmdDial
      end
      else
      begin
        if CmdState and ctCmdRespRec <> 0 then       {got response}
        begin
          if (RespStr = GenOptsRec^.RespConnect) or
          (RespStr = GenOptsRec^.RespCarrier) then {'connect' or carrier response}
          begin
            DialLog (false); {got 'connect'}
            CmdState := CmdState or ctCmdGetRate
          end
          else
          begin
            DialLog (true);
            NewTimerSecs (TermTimer,GenOptsRec^.DialPause); {set pause timer}
            CmdState := CmdState or ctCmdDialPause or ctCmdHangUp
          end
        end
        else {response time out}
        begin
          RespStr := 'TIME OUT';
          DialLog (true);
          NewTimerSecs (TermTimer,GenOptsRec^.DialPause); {set pause timer}
          CmdState := CmdState or ctCmdDialPause or ctCmdHangUp
        end;
        CmdState := CmdState and not
        (ctCmdDial or ctCmdRespRec or ctCmdRespTime)
      end
end;

{
Pause between redial attempts.
}

procedure TTermWin.DialPause;

begin
  if RedialCnt > 0 then
  begin
    if TimerExpired (TermTimer) then
    begin
      Dec (RedialCnt);
      CmdState := (CmdState and not ctCmdDialPause) or ctCmdDial
    end
  end
  else
  begin
    DialLog (false);
    UpdateLog ('Unable to connect after '+
    IntToStr (GenOptsRec^.Redial+1)+' attempts');
    CmdState := (CmdState and not (ctCmdDialPause or ctCmdScript)) or ctCmdHangUp
  end
end;

{
General pause used for delay between init command and dial sequence, but can
used for other delays.
}

procedure TTermWin.GenPause;

begin
  if CmdState and ctCmdInitTask <> 0 then
  begin
    if TimerExpired (TermTimer) then
    begin
      UPort.WaitForString (ctLF,0); {eat chars until lf found}
      CmdState := CmdState and not (ctCmdGenPause or ctCmdInitTask)
    end
  end
  else
  begin
    UPort.WaitForString (ctLF,0); {eat chars until lf found}
    NewTimerSecs (TermTimer,ctGenWait); {set pause timer}
    CmdState := CmdState or ctCmdInitTask
  end
end;

{
Get rate from modem CARRIER or CONNECT response.
}

procedure TTermWin.GetConnectRate;

var

  Err : integer;
  Baud : longint;
  C : char;

begin
  if CmdState and ctCmdInitTask <> 0 then
  begin
    if not TimerExpired (TermTimer) then
    begin
      if UPort.CharReady then
      begin
        UPort.GetChar (C);
        Term^.ProcAnsiChar (C);
        case C of
          ' ' : ;
          '0'..'9' : RateStr := RateStr+C
          else
          begin
            Val (RateStr,Baud,Err);
            if Baud > 0 then
              ConnectBaud := Baud;
            CmdState := CmdState and not (ctCmdGetRate or ctCmdInitTask);
            if RespStr = GenOptsRec^.RespCarrier then {did we get 'carrier'?}
            begin {wait for connect response}
              CmdState := CmdState or ctCmdRespWait or ctCmdGetRate;
              RespWaitStr := GenOptsRec^.RespConnect;       {'connect' response}
              NewTimerSecs (TermTimer,GenOptsRec^.WaitResp) {set response timer}
            end
          end
        end
      end
    end
    else
    begin {didn't get block before time out}
      UpdateLog ('Did not get connect rate');
      CmdState := CmdState and not (ctCmdGetRate or ctCmdInitTask)
    end
  end
  else
  begin
    if CmdState and (ctCmdRespRec or ctCmdRespTime) = 0 then
    begin
      NewTimerSecs (TermTimer,GenOptsRec^.WaitResp); {set response timer}
      CmdState := CmdState or ctCmdInitTask
    end
    else
    begin
      if CmdState and ctCmdRespRec = 0 then {no response before time out}
        UpdateLog ('Timed out waiting for '+RespWaitStr)
      else
        UpdateLog (RespWaitStr);
      CmdState := (CmdState and not
      (ctCmdGetRate or ctCmdRespRec or ctCmdRespTime))
    end
  end
end;

{
Process script
}

procedure TTermWin.ProcessScript;

begin
  if ScriptEng <> nil then
  begin
    if ScriptEng^.NodeCollPtr^.Count > 0 then
    begin
      repeat
        ScriptEng^.ProcessCommand
      until ScriptEng^.ScriptState and ctScrStLock = 0
    end
    else
    begin
      CmdState := CmdState and not ctCmdScript;
      UpdateLog ('Script collection empty')
    end
  end
  else
  begin
    UpdateLog ('Script collection nil');
    CmdState := CmdState and not ctCmdScript
  end
end;

{
Process modem commands, dialing and ANSI view processing.  The ANSI view's
I/O processing is not called during commands.  All I/O is handled by
the commands themselfs.
}

procedure TTermWin.IdleTask;

var

  C : char;

begin
  if CmdState = 0 then
  begin
    with Term^ do
    begin
      while (UPort.CharReady) and (MaxBufChars > BufChars) do
      begin
        UPort.GetChar (C); {get char from port}
        ProcAnsiChar (C);  {do ansi processing}
        if TermRec^.TermOpts and ctAutoZm <> 0 then
          case ZmodemDet of
            ctGotNone :
              if C = 'r' then
                ZmodemDet := ctGotr;
            ctGotr :
              if C <> 'z' then
                ZmodemDet := ctGotNone
              else
                ZmodemDet := ctGotz;
            ctGotz :
            begin
              if C = ctCR then
              begin
                ProtocolNum := Zmodem;
                CmdState := CmdState or ctCmdXferInit or ctCmdDownload
              end;
              ZmodemDet := ctGotNone
            end
          end
      end;
      if BufChars > 0 then {if any chars were buffered then draw view}
      begin
        if not UPortPtr^.CharReady then
          TrackCursor;     {make sure cursor visible if no chars ready}
        DrawView;          {draw view buffer}
        BufChars := 0      {reset buffer count}
      end
    end
  end
  else              {process state commands}
  begin
    if CmdState and ctCmdCTSWait = 0 then {not waiting for cts high}
    begin
      if CmdState and ctCmdHangUp = 0 then {not hanging up}
      begin
        if CmdState and ctCmdRespWait = 0 then {no response pending}
        begin
          if CmdState and (ctCmdInit or ctCmdGenPause) <> 0 then {send modem init string}
            InitModem
          else
            if CmdState and (ctCmdDial or
            ctCmdDialPause or ctCmdGetRate) <> 0 then {dial modem}
              Dial
            else
              if CmdState and ctCmdXfer <> 0 then {xfer file}
                XferTask
              else
                if CmdState and ctCmdXferInit <> 0 then {init file xfer}
                  InitXfer
                else
                  if CmdState and ctCmdScript <> 0 then {process script}
                    ProcessScript
        end
        else
          GetResp
      end
      else
        HangUp
    end
    else
      WaitCTSLow
  end;
  if CmdState and ctCmdScript = 0 then
      ScriptQue.DoTask {process script que}
end;

{
Toggle capture on/off and handle append/overwrite operation.
}

procedure TTermWin.Capture (FName : PathStr; Cmd : word);

var

  PromptOvWrt : boolean;

begin
  if not CaptureOn then
  begin
    if Cmd = cmNo then
      PromptOvWrt := false
    else
      PromptOvWrt := true;
    CapFileName := FName;
    Assign (CapFile,CapFileName);
    {$I-} Reset (CapFile,1); {$I+}
    if IoResult = 0 then   {see if file exists before writes}
    begin
      {$I-} SYSTEM.Close (CapFile); {$I+}
      if Cmd = 0 then
        Cmd := MessageBox ('File already exists.  Do you wish to append?',nil,mfConfirmation or mfYesNoCancel);
      case Cmd of
        cmYes :
        begin
          {$I-} Reset (CapFile,1); {$I+}
          if IOResult = 0 then
          begin
            {$I-} Seek (CapFile,FileSize (CapFile)); {$I+}
            if IoResult = 0 then
            begin
              UpdateLog ('Capture append '+CapFileName);
              CaptureOn := true
            end
          end
        end;
        cmNo  :
        begin
          if not PromptOvWrt then
            Cmd := cmYes
          else
            Cmd := MessageBox ('Do you wish to overwrite file?',nil,mfConfirmation or mfYesNoCancel);
          if Cmd = cmYes then
          begin
            {$I-} Rewrite (CapFile,1); {$I+}
            if IoResult = 0 then
            begin
              UpdateLog ('Capture overwrite '+CapFileName);
              CaptureOn := true
            end
          end
        end
      end
    end
    else {file doesn't exist}
    begin
      {$I-} Rewrite (CapFile,1); {$I+}
      if IoResult = 0 then
      begin
        UpdateLog ('Capture new file '+CapFileName);
        CaptureOn := true
      end
    end
  end
  else
    UpdateLog ('Capture file already open '+CapFileName)
end;

{
Close capture file if open.
}

procedure TTermWin.CaptureClose;

var

  WriteSize : word;

begin
  if CaptureOn then
  begin
    UpdateLog ('Capture close '+CapFileName);
    if CapBufPos > 0 then {flush buffer}
    begin
      {$I-} BlockWrite (CapFile,CapFileBuf,CapBufPos,WriteSize); {$I+}
      CapBufPos := 0
    end;
    {$I-} SYSTEM.Close (CapFile); {$I+}
    CaptureOn := false
  end
  else
    UpdateLog ('Capture file already closed '+CapFileName)
end;

{
Buffered file i/o used for performance.
}

procedure TTermWin.WriteCapFile (C : char);

var

  WriteSize : word;

begin
  if CaptureOn then
  begin
    if CapBufPos = ctCapBufSize then
    begin
      CapBufPos := 0;
      {$I-} BlockWrite (CapFile,CapFileBuf,SizeOf (CapFileBuf),WriteSize) {$I+}
    end;
    CapFileBuf [CapBufPos] := byte (C);
    Inc (CapBufPos)
  end
end;

{
Enable/disable term commands when entering/leaving window.
}

procedure TTermWin.SetState (AState : word; Enable : boolean);

begin
  inherited SetState (AState, Enable);
  if AState = sfActive then
  begin
    if Enable then
      EnableCommands (ctTermCmds)
    else  {leaving window focus}
      DisableCommands (ctTermCmds)
  end
end;

{
Handle idle task.
}

procedure TTermWin.HandleEvent (var Event : TEvent);

var

 MLoc : TPoint;
 L : PListBox;

begin
  inherited HandleEvent (Event);
  case Event.What of
    evBroadcast :
    begin
      case Event.Command of
        cmTermIdle    : IdleTask;
        cmTermCapChar : WriteCapFile (PChar (Event.InfoPtr)^);
        cmTermInpEnd  :
        begin
          if ScriptEng <> nil then
            with ScriptEng^ do
            begin
              if TermRec^.ComName = PTermInpDlg (Event.InfoPtr)^.ComName then
              begin
                LastResp := PString (PTermInpDlg (Event.InfoPtr)^.TermInp^.Data)^;
                ScriptState := ScriptState and not ctScrStInpBox
              end
            end
        end;
        cmTermInpCan  :
        begin
          if ScriptEng <> nil then
            if TermRec^.ComName = PTermInpDlg (Event.InfoPtr)^.ComName then
              with ScriptEng^ do
              begin
                LastResp := '';
                ScriptState := ScriptState and not ctScrStInpBox
              end
        end;
        cmListEnd  :
        begin
          if ScriptEng <> nil then
            with ScriptEng^ do
            begin
              if TermRec^.ComName = PTermInpDlg (Event.InfoPtr)^.ComName then
              begin
                L := PTermListDlg (Event.InfoPtr)^.StrBox;
                if L^.List^.Count > 0 then
                  LastResp := PString (L^.List^.At (L^.Focused))^
                else
                  LastResp := '';
                ScriptState := ScriptState and not ctScrStInpBox
              end
            end
        end;
        cmListCan  :
        begin
          if ScriptEng <> nil then
            if TermRec^.ComName = PTermInpDlg (Event.InfoPtr)^.ComName then
              with ScriptEng^ do
              begin
                LastResp := '';
                ScriptState := ScriptState and not ctScrStInpBox
              end
        end
      end
    end;
    evMouseDown :
    begin
      if Term^.MouseInView (Event.Where) then
      begin
        if ScriptEng <> nil then
        begin
          MakeLocal (Event.Where,MLoc);
          ScriptEng^.LastResp := Term^.GetTextStr (0,Term^.Delta.Y+MLoc.Y-1);
          ScriptEng^.MouseX := Term^.Delta.X+MLoc.X;
          ScriptEng^.MouseY := Term^.Delta.Y+MLoc.Y
        end
      end
    end
  end
end;

{
Make sure no commands are in effect before closing window.
}

function TTermWin.Valid (Command : word) : boolean;

var

  Temp : boolean;

begin
  Temp := inherited Valid (Command);
  if Command = cmClose then
    Temp := (CmdState and (ctCmdXferMask or ctCmdLockWin) = 0);
  Valid := Temp
end;

{
TPhoneCollection is a collection sorted by name.
}

function TPhoneCollection.KeyOf (Item : pointer) : pointer;

begin
  KeyOf := @PTermRec (Item)^.Name
end;

function TPhoneCollection.Compare (Key1, Key2 : pointer) : integer;

begin
  if PString (Key1)^ = PString (Key2)^ then
    Compare := 0
  else
    if PString (Key1)^ < PString (Key2)^ then
      Compare := -1
    else
      Compare := 1
end;

{
TTermListBox is pick list using a TTermRec collection.
}

function TTermListBox.GetText(Item: Integer; MaxLen: Integer): String;

var

  P : PTermRec;

begin
  if List <> nil then
  begin
    P := PTermRec (List^.At (Item));
    GetText :=
    PadRightStr (P^.Name,' ',SizeOf (P^.Name)-1)+'³'+
    PadRightStr (P^.PhoneNum,' ',SizeOf (P^.PhoneNum)-1)+'³'+
    'COM'+IntToStr (integer (P^.ComName)+1)+'³'+
    IntToRightStr (P^.Baud,6)+'³'+
    IntToStr (P^.DataBits)+
    ctParityChar[byte (P^.Parity)]+
    IntToStr (P^.StopBits)
  end
  else
    GetText := ''
end;

{
TTermConfigDlg allows you to add, delete and edit phone book entries.
}

constructor TTermConfigDlg.Init;

var

  R : TRect;
  VScrollBar : PScrollBar;

begin
  R.Assign (0,0,75,21);
  inherited Init (R,'Phone Book');
  Options := Options or ofCentered;

  R.Assign (72,3,73,7);
  New (VScrollBar,Init (R));
  Insert (VScrollBar);

  R.Assign (2,3,72,7);
  FieldBox := New (PTermListBox,Init (R,1,VScrollBar));
  Insert (FieldBox);
  R.Assign (1,2,22,3);
  Insert (New (PLabel,Init (R,'~L~ist',FieldBox)));

  R.Assign (2,8,29,9);
  NameLine := New (PInputLine,Init(R,25));
  Insert (NameLine);
  R.Assign (1,7,6,8);
  Insert (New (PLabel,Init (R,'~N~ame',NameLine)));

  R.Assign (30,8,51,9);
  PhoneLine := New (PInputLine,Init(R,25));
  Insert (PhoneLine);
  R.Assign (29,7,35,8);
  Insert (New (PLabel,Init (R,'~P~hone',PhoneLine)));

  R.Assign (2,10,29,11);
  PathLine := New (PInputLine,Init(R,SizeOf (PathStr)-1));
  Insert (PathLine);
  R.Assign (1,9,16,10);
  Insert (New (PLabel,Init (R,'Download pat~h~',PathLine)));

  R.Assign (30,10,51,11);
  InitLine := New (PInputLine,Init(R,30));
  Insert (InitLine);
  R.Assign (29,9,47,10);
  Insert (New (PLabel,Init (R,'~M~odem init string',InitLine)));

  R.Assign (52,8,73,11);
  ComButtons := New (PRadioButtons,Init(R,
    NewSItem ('1',
    NewSItem ('2',
    NewSItem ('3',
    NewSItem ('4',
    NewSItem ('5',
    NewSItem ('6',
    NewSItem ('7',
    NewSItem ('8',
    nil))))))))));
  Insert (ComButtons);
  R.Assign (51,7,55,8);
  Insert (New (PLabel,Init (R,'Com',ComButtons)));

  R.Assign (2,12,35,15);
  BaudButtons := New (PRadioButtons,Init(R,
    NewSItem ('300',
    NewSItem ('1200',
    NewSItem ('2400',
    NewSItem ('4800',
    NewSItem ('9600',
    NewSItem ('19200',
    NewSItem ('38400',
    NewSItem ('57600',
    NewSItem ('115200',
    nil)))))))))));
  Insert (BaudButtons);
  R.Assign (1,11,6,12);
  Insert (New (PLabel,Init (R,'~B~aud',BaudButtons)));

  R.Assign (36,12,50,15);
  DataButtons := New (PRadioButtons,Init(R,
    NewSItem ('5',
    NewSItem ('6',
    NewSItem ('7',
    NewSItem ('8',
    nil))))));
  Insert (DataButtons);
  R.Assign (35,11,45,12);
  Insert (New (PLabel,Init (R,'Da~t~a bits',DataButtons)));

  R.Assign (51,12,65,15);
  ParityButtons := New (PRadioButtons,Init(R,
    NewSItem ('N',
    NewSItem ('O',
    NewSItem ('E',
    NewSItem ('M',
    NewSItem ('S',
    nil)))))));
  Insert (ParityButtons);
  R.Assign (50,11,57,12);
  Insert (New (PLabel,Init (R,'Parit~y~',ParityButtons)));

  R.Assign (66,12,73,15);
  StopButtons := New (PRadioButtons,Init(R,
    NewSItem ('1',
    NewSItem ('2',
    nil))));
  Insert (StopButtons);
  R.Assign (65,11,70,12);
  Insert (New (PLabel,Init (R,'~S~top',StopButtons)));

  R.Assign (2,16,42,20);
  OptBoxes := New (PCheckBoxes,Init(R,
    NewSItem ('Use DTR',
    NewSItem ('Use RTS',
    NewSItem ('Req DSR',
    NewSItem ('Req CTS',
    NewSItem ('XON/XOFF',
    NewSItem ('FIFO',
    NewSItem ('Echo',
    NewSItem ('VT100',
    NewSItem ('Raw Cap',
    NewSItem ('7 bit',
    NewSItem ('Zmodem',
    nil)))))))))))));
  Insert (OptBoxes);
  R.Assign (1,15,14,16);
  Insert (New (PLabel,Init (R,'~O~ptions',OptBoxes)));

  R.Assign (43,16,53,18);
  Insert (New (PButton,Init (R,'~D~ial',cmOk,bfDefault)));
  R.Assign (53,16,63,18);
  Insert (New (PButton,Init (R,'~A~dd',cmPhoneAdd,bfNormal)));
  R.Assign (63,16,73,18);
  Insert (New (PButton,Init (R,'D~e~lete',cmPhoneDelete,bfNormal)));
  R.Assign (43,18,53,20);
  Insert (New (PButton,Init (R,'~C~opy',cmPhoneEdit,bfNormal)));
  R.Assign (53,18,63,20);
  Insert (New (PButton,Init (R,'Done',cmCancel,bfNormal)));
  SelectNext (false)
end;

{
Adds TTermRec to pick list.  Accepts names that are not '' or duplicated.
}

procedure TTermConfigDlg.AddRec;

var

  P : PTermRec;

function SameName (Item : pointer) : boolean; far;

begin {see if name matches on from list}
  SameName := (UpCaseStr (PTermRec (Item)^.Name) =
  UpCaseStr (NameLine^.Data^))
end;

begin
  if NameLine^.Data^ <> '' then {null name?}
  begin
    if PhoneCollPtr^.FirstThat (@SameName) = nil then {does name exist in list?}
    begin
      P := New (PTermRec,Init);
      with P^ do
      begin
        Name := NameLine^.Data^;
        PhoneNum := PhoneLine^.Data^;
        DLPath := UpCaseStr (PathLine^.Data^);
        InitStr := UpCaseStr (InitLine^.Data^);
        ComName := ComNameType (ComButtons^.Value);
        Baud := ctBaudTable[BaudButtons^.Value];
        Parity := ParityType (ParityButtons^.Value);
        DataBits := DataBitType (DataButtons^.Value)+5;
        StopBits := StopBitType (StopButtons^.Value)+1;
        ComOptions := ptReturnDelimiter+ptExecutePartialPuts+
                      ptDropModemOnClose+ptRaiseModemOnOpen+
                      ptRestoreOnClose;
        TermOpts := OptBoxes^.Value
      end;
      PhoneCollPtr^.Insert (P);                        {add to list}
      FieldBox^.SetRange (FieldBox^.List^.Count);      {set list's range}
      FieldBox^.FocusItem (PhoneCollPtr^.IndexOf (P)); {focus inserted item}
      FieldBox^.DrawView                               {draw box}
    end
    else
    begin
      MessageBox (#3'Duplicate name',nil,mfError or mfOKButton);
      NameLine^.Focus
    end
  end
  else
  begin
    MessageBox (#3'Name blank',nil,mfError or mfOKButton);
    NameLine^.Focus
  end
end;

{
Delete field from field pick list.
}

procedure TTermConfigDlg.DeleteRec;

begin
  if FieldBox^.Range > 0 then
  begin
    PhoneCollPtr^.AtDelete (FieldBox^.Focused);
    FieldBox^.SetRange (FieldBox^.List^.Count);
    FieldBox^.DrawView
  end
end;

procedure TTermConfigDlg.HandleEvent (var Event : TEvent);

{
Edit current field in list.
}

procedure EditRec;

var

  P : PTermRec;
  I : integer;

begin
  if FieldBox^.Range > 0 then
  begin
    P := PhoneCollPtr^.At (FieldBox^.Focused);
    with P^ do
    begin
      NameLine^.SetData (Name);
      PhoneLine^.SetData (PhoneNum);
      PathLine^.SetData (DLPath);
      InitLine^.SetData (InitStr);
      I := integer (ComName);
      ComButtons^.SetData (I);
      I := 0;
      while ctBaudTable [I] <> Baud do
        Inc (I);
      BaudButtons^.SetData (I);
      I := integer (Parity);
      ParityButtons^.SetData (I);
      I := DataBits-5;
      DataButtons^.SetData (I);
      I := StopBits-1;
      StopButtons^.SetData (I);
      OptBoxes^.SetData (TermOpts)
    end
  end
end;

begin
  if ((Event.What = evMouseDown) and (Event.Double) and
  (FieldBox^.MouseInView (Event.Where))) then
  begin
    Event.What := evCommand;
    Event.Command := cmOK;
    PutEvent (Event);
    ClearEvent (Event)
  end;
  inherited HandleEvent (Event);
  case Event.What of
    evCommand :
    begin {process commands}
      case Event.Command of
        cmPhoneAdd    : AddRec;
        cmPhoneDelete : DeleteRec;
        cmPhoneEdit   : EditRec
      else
        Exit
      end;
      ClearEvent (Event)
    end
  end
end;

{
TTermGenDlg collects general information about the terminal.
}

constructor TTermGenDlg.Init;

var

  R : TRect;
  Field : PInputLine;

begin
  R.Assign (0,0,52,14);
  inherited Init (R,'Terminal Options');
  Options := Options or ofCentered;

  R.Assign (2,3,9,4);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (80,132)));
  Insert (Field);
  R.Assign (1,2,7,3);
  Insert (New (PLabel,Init (R,'~W~idth',Field)));

  R.Assign (10,3,17,4);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (50,1000)));
  Insert (Field);
  R.Assign (9,2,16,3);
  Insert (New (PLabel,Init (R,'Length',Field)));

  R.Assign (18,3,25,4);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (1,8192)));
  Insert (Field);
  R.Assign (17,2,22,3);
  Insert (New (PLabel,Init (R,'Draw',Field)));

  R.Assign (26,3,33,4);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (2048,32768)));
  Insert (Field);
  R.Assign (25,2,31,3);
  Insert (New (PLabel,Init (R,'Input',Field)));

  R.Assign (34,3,41,4);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (2048,32768)));
  Insert (Field);
  R.Assign (33,2,40,3);
  Insert (New (PLabel,Init (R,'Output',Field)));

  R.Assign (42,3,49,4);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (1,60)));
  Insert (Field);
  R.Assign (41,2,50,3);
  Insert (New (PLabel,Init (R,'CTS wait',Field)));

  R.Assign (2,5,24,6);
  Field := New(PInputLine,Init(R,20));
  Insert (Field);
  R.Assign (1,4,13,5);
  Insert (New (PLabel,Init (R,'~D~ial prefix',Field)));

  R.Assign (26,5,33,6);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (1,3600)));
  Insert (Field);
  R.Assign (25,4,30,5);
  Insert (New (PLabel,Init (R,'Wait',Field)));

  R.Assign (34,5,41,6);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (1,3600)));
  Insert (Field);
  R.Assign (33,4,39,5);
  Insert (New (PLabel,Init (R,'Pause',Field)));

  R.Assign (42,5,49,6);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (1,1000)));
  Insert (Field);
  R.Assign (41,4,50,5);
  Insert (New (PLabel,Init (R,'Redial',Field)));

  R.Assign (2,7,9,8);
  Field := New(PInputLine,Init(R,30));
  Insert (Field);
  R.Assign (1,6,4,7);
  Insert (New (PLabel,Init (R,'~O~K',Field)));

  R.Assign (10,7,17,8);
  Field := New(PInputLine,Init(R,30));
  Insert (Field);
  R.Assign (9,6,15,7);
  Insert (New (PLabel,Init (R,'Error',Field)));

  R.Assign (18,7,25,8);
  Field := New(PInputLine,Init(R,30));
  Insert (Field);
  R.Assign (17,6,25,7);
  Insert (New (PLabel,Init (R,'Connect',Field)));

  R.Assign (26,7,33,8);
  Field := New(PInputLine,Init(R,30));
  Insert (Field);
  R.Assign (25,6,33,7);
  Insert (New (PLabel,Init (R,'No carr',Field)));

  R.Assign (34,7,41,8);
  Field := New(PInputLine,Init(R,30));
  Insert (Field);
  R.Assign (33,6,40,7);
  Insert (New (PLabel,Init (R,'No ans',Field)));

  R.Assign (42,7,49,8);
  Field := New(PInputLine,Init(R,30));
  Insert (Field);
  R.Assign (41,6,46,7);
  Insert (New (PLabel,Init (R,'Busy',Field)));

  R.Assign (2,9,9,10);
  Field := New(PInputLine,Init(R,30));
  Insert (Field);
  R.Assign (1,8,7,9);
  Insert (New (PLabel,Init (R,'~V~oice',Field)));

  R.Assign (10,9,17,10);
  Field := New(PInputLine,Init(R,30));
  Insert (Field);
  R.Assign (9,8,14,9);
  Insert (New (PLabel,Init (R,'Ring',Field)));

  R.Assign (18,9,25,10);
  Field := New(PInputLine,Init(R,30));
  Insert (Field);
  R.Assign (17,8,25,9);
  Insert (New (PLabel,Init (R,'No tone',Field)));

  R.Assign (26,9,33,10);
  Field := New(PInputLine,Init(R,30));
  Insert (Field);
  R.Assign (25,8,33,9);
  Insert (New (PLabel,Init (R,'Carrier',Field)));

  R.Assign (34,9,39,10);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (0,255)));
  Insert (Field);
  R.Assign (33,8,39,9);
  Insert (New (PLabel,Init (R,'Can',Field)));

  R.Assign (40,9,44,10);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (1,60)));
  Insert (Field);
  R.Assign (39,8,44,9);
  Insert (New (PLabel,Init (R,'Resp',Field)));

  R.Assign (45,9,49,10);
  Field := New(PInputLine,Init(R,6));
  Field^.SetValidator (New (PRangeValidator,Init (1,60)));
  Insert (Field);
  R.Assign (44,8,49,9);
  Insert (New (PLabel,Init (R,'DTR low',Field)));

  R.Assign (15,11,25,13);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (26,11,36,13);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)));
  SelectNext (false)
end;

{
Terminal input.
}

constructor TTermInpDlg.Init (C : ComNameType; I, L : string);

var

  R : TRect;

begin
  R.Assign (0,0,60,8);
  inherited Init (R,ComNameString (C)+' Input Box');
  Options := Options or ofCentered;
  ComName := C;
  R.Assign (2,3,58,4);
  TermInp := New(PInputLine,Init(R,255));
  Insert (TermInp);
  R.Assign (2,2,58,3);
  Insert (New (PStaticText,Init (R,L)));
  TermInp^.SetData (I);

  R.Assign (20,5,30,7);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (31,5,41,7);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)));
  SelectNext (false);
  MsgSent := false
end;

procedure TTermInpDlg.Close;

begin
  if not MsgSent then
    Message (Desktop,evBroadcast,cmTermInpCan,@Self);
  inherited Close
end;

procedure TTermInpDlg.HandleEvent (var Event : TEvent);

begin
  case Event.What of
    evKeyDown:
      case Event.KeyCode of
        kbEsc:
        begin
          Message (Desktop,evBroadcast,cmTermInpCan,@Self);
          MsgSent := true;
          Close;
          Exit
        end
      end;
    evCommand :
      case Event.Command of
        cmOk     :
        begin
          Message (Desktop,evBroadcast,cmTermInpEnd,@Self);
          MsgSent := true;
          Close;
          Exit
        end;
        cmCancel :
        begin
          Message (Desktop,evBroadcast,cmTermInpCan,@Self);
          MsgSent := true;
          Close;
          Exit
        end
      end
  end;
  inherited HandleEvent (Event)
end;

{
Terminal list select.
}

constructor TTermListDlg.Init (C : ComNameType; T : string);

var

  R : TRect;
  VScrollBar : PScrollBar;

begin
  R.Assign (0,0,77,12);
  inherited Init (R,ComNameString (C)+' '+T);
  Options := Options or ofCentered;
  ComName := C;

  R.Assign (74,3,75,8);
  New (VScrollBar,Init (R));
  Insert (VScrollBar);

  R.Assign (2,3,74,8);
  StrBox := New (PCySortedListBox,Init (R,1,VScrollBar));
  Insert (StrBox);
  R.Assign (1,2,74,3);
  Insert (New (PLabel,Init (R,'~L~ist',StrBox)));
  StrList := New (PStringCollection, Init(0,100));
  StrBox^.NewList (StrList);

  R.Assign (28,9,38,11);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (39,9,49,11);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)));
  SelectNext (false)
end;

destructor TTermListDlg.Done;

begin
  Dispose (StrList,Done);
  inherited Done
end;

procedure TTermListDlg.Close;

begin
  if not MsgSent then
    Message (Desktop,evBroadcast,cmListCan,@Self);
  inherited Close
end;

procedure TTermListDlg.HandleEvent (var Event : TEvent);

begin
  case Event.What of
    evKeyDown:
      case Event.KeyCode of
        kbEsc:
        begin
          Message (Desktop,evBroadcast,cmListCan,@Self);
          MsgSent := true;
          Close;
          Exit
        end
      end;
    evBroadcast :
      case Event.Command of
        cmListInsert :
        begin
          StrList^.Insert (NewStr (PString (Event.InfoPtr)^));
          StrBox^.SetRange (StrList^.Count)
        end;
        cmListDraw :
        begin
          StrBox^.DrawView
        end
      end;
    evCommand :
      case Event.Command of
        cmOk     :
        begin
          Message (Desktop,evBroadcast,cmListEnd,@Self);
          MsgSent := true;
          Close;
          Exit
        end;
        cmCancel :
        begin
          Message (Desktop,evBroadcast,cmListCan,@Self);
          MsgSent := true;
          Close;
          Exit
        end
      end;
    evMouseDown :
      if (Event.Double) and
      (StrBox^.MouseInView (Event.Where)) then
      begin
        Event.What := evCommand;
        Event.Command := cmOK;
        PutEvent (Event);
        ClearEvent (Event)
      end
  end;
  inherited HandleEvent (Event)
end;

end.
