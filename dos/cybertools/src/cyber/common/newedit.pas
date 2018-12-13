{ FILE:  newedit.pas }



unit NewEdit;

{$I APP.INC}



{ ******************************************************************** }
{                                                                      }
{ NOTICE:  The following code was written by Borland International.    }
{          The code is for use by TP6.0 users.  Keep the copyright     }
{          notice intact!                                              }
{                                                                      }
{          Turbo Pascal 6.0                                            }
{          Turbo Vision Demo                                           }
{          Copyright (c) 1990 by Borland International                 }
{                                                                      }
{          I have taken the liberty of prettying up the source.        }
{          I have also taken the liberty of adding additional features.}
{          Search for the following keywords and compare your original }
{          editors code to any code between the Start/Stop comments    }
{          for changes.                                                }
{                                                                      }
{ Label    Description:                                                }
{ ------   ------------                                                }
{                                                                      }
{ CENTER - Added a feature to center text on a line.                   }
{          Centering only works to Right_Margin.                       }
{                                                                      }
{ CTRLBK - Added new key to map to ^QH.  Does the same thing.          }
{                                                                      }
{ HOMEND - Added feature to move cursor to top and bottom of page      }
{          using the [Ctrl]-[Home] and [Ctrl]-[End] keys.              }
{                                                                      }
{ LOAD   - Fixed bug that prevented load operations and added new      }
{          stream reads to handle new TEditor objects.                 }
{                                                                      }
{ MARK   - A place mark type feature.  Exactly the same as WordStar's  }
{          ^K# and ^Q#, except that the mark is for the exact poistion }
{          the cursor is at in a line, not just the start of a line.   }
{                                                                      }
{ INDENT - Change AutoIndent from a ^O to a ^QI call.                  }
{                                                                      }
{ INSLIN - Insert new line at cursor and maintain cursor position.     }
{                                                                      }
{ JLINE  - A jump to line number feature.  Pressing ^JL will bring     }
{          up a dialog box asking the line number to jump to.          }
{                                                                      }
{ PRETAB - Preset tab feature.  Tabs are preset in increments of 7.    }
{          The user can call up a dialog and set the tabs in any way   }
{          they want.  Uses WordStar ^OI feature.  Note that a "real"  }
{          tab (^I) is no longer supported.  Tabs are converted to     }
{          spaces if you are inserting text, and only move the cursor  }
{          to the next tab stop if you are overwriting text.           }
{                                                                      }
{ REFDOC - Reformats a document from either the beginning or the       }
{          current line the cursor is on.                              }
{                                                                      }
{ REFORM - Reformats a paragraph to the Right_Margin setting.          }
{          This feature works regardless if wordwrap is active,        }
{          as a standalone ^B call.                                    }
{                                                                      }
{ RMSET  - User can set the Right_Margin by pressing ^OR.  A dialog    }
{          box comes up asking you for the Right_Margin you want.      }
{          The dialog box has the current Right_Margin displayed in    }
{          it.  There is only one dialog button "cmOK."  Selecting     }
{          this button, or aborting, will maintain the current margin. }
{          Default Right_Margin is 76.  Valid entries are >10 or < 256.}
{                                                                      }
{ SAVE   - Add new save options.  Keep F2 as the default cmSave to     }
{          save file and continue editing, but tie ^KS to it also.     }
{          Add ^KT to cmSaveAs to save current file to another file.   }
{          Add ^KD and ^KX as cmSaveDone to do an immediate save and   }
{          automatically remove the editor from the desktop.           }
{                                                                      }
{ SCRLBG - Added a bug fix so editor doesn't consume ScrollbarChanged  }
{          events.                                                     }
{                                                                      }
{ SCRLDN - Added feature to scroll the screen up a line-at-a-time      }
{          by pressing ^Z.                                             }
{                                                                      }
{ SCRLUP - Added feature to scroll the screen down a line-at-a-time    }
{          by pressing ^W.                                             }
{                                                                      }
{ SELDEL - Disallowed editor default of arbitrarily deleting selected  }
{          text when any key is pressed.  You now use the [Del] key.   }
{                                                                      }
{ SELWRD - Added feature to select a word only by pressing ^KT.        }
{                                                                      }
{ STATS  - Changed the appearance of the PIndicator line.              }
{          It now shows "M" for modified, "I" for AutoIndent,          }
{          and "W" for wordwrap.                                       }
{                                                                      }
{ STORE  - Fixed bug that prevented store operations and added new     }
{          stream writes to handle new TEditor objects.  Send thanks   }
{          to Johnathan Stein CIS: 76576,470 in the form of a lollipop }
{          for finding this bug.                                       }
{                                                                      }
{ UNDO   - Added IDE ^QL undo feature.  ^U is still functional.        }
{                                                                      }
{ WRAP   - A word wrap modification.  Allows user to toggle wordwrap   }
{          on or off.  If on, wordwrap will occur when the cursor      }
{          reaches +1 of the current Right_Margin setting.  Wrap works }
{          as a "push the line out until cursor gets to Right_Margin"  }
{          principle.  Wordwrap also supports the AutoIndent feature.  }
{                                                                      }
{ Al Andersen - 02/29/92.                                              }
{                                                                      }
{ ******************************************************************** }


{$F+,I-,O+,S-,V-,X+,D-}



interface

uses Drivers,
     Objects,
     Views,
     Dialogs;



CONST { Command constants for saving files and finding text. }

  cmFind        = 82;
  cmReplace     = 83;
  cmSearchAgain = 84;

  { SAVE - Start. }

  cmSaveDone    = 85;

  { SAVE - Stop.  }



CONST { New editor commands that user may want to put into a menu. }

  { CENTER - Start. }
  { HOMEND - Start. }
  { INSLIN - Start. }
  { JLINE  - Start. }
  { MARK   - Start. }
  { PRETAB - Start. }
  { REFDOC - Start. }
  { REFORM - Start. }
  { RMSET  - Start. }
  { SCRLDN - Start. }
  { SCRLDN - Start. }
  { SELWRD - Start. }
  { WRAP   - Start. }

  cmCenterText  = 200;
  cmEndPage     = 201;
  cmHomePage    = 202;
  cmIndentMode  = 203;
  cmInsertLine  = 204;
  cmJumpLine    = 205;
  cmJumpMark0   = 206;
  cmJumpMark1   = 207;
  cmJumpMark2   = 208;
  cmJumpMark3   = 209;
  cmJumpMark4   = 210;
  cmJumpMark5   = 211;
  cmJumpMark6   = 212;
  cmJumpMark7   = 213;
  cmJumpMark8   = 214;
  cmJumpMark9   = 215;
  cmReformDoc   = 216;
  cmReformPara  = 217;
  cmRightMargin = 218;
  cmScrollDown  = 219;
  cmScrollUp    = 220;
  cmSelectWord  = 221;
  cmSetMark0    = 222;
  cmSetMark1    = 223;
  cmSetMark2    = 224;
  cmSetMark3    = 225;
  cmSetMark4    = 226;
  cmSetMark5    = 227;
  cmSetMark6    = 228;
  cmSetMark7    = 229;
  cmSetMark8    = 230;
  cmSetMark9    = 231;
  cmSetTabs     = 232;
  cmTabKey      = 233;
  cmWordWrap    = 234;


  { WRAP   - Stop. }
  { SELWRD - Stop. }
  { SCRLUP - Stop. }
  { SCRLDN - Stop. }
  { RMSET  - Stop. }
  { REFORM - Stop. }
  { REFDOC - Stop. }
  { PRETAB - Stop. }
  { MARK   - Stop. }
  { JLINE  - Stop. }
  { INSLIN - Stop. }
  { HOMEND - Stop. }
  { CENTER - Stop. }



CONST { Command constants for cursor movement and modifying text. }

  cmCharLeft      = 500;
  cmCharRight     = 501;
  cmWordLeft      = 502;
  cmWordRight     = 503;
  cmLineStart     = 504;
  cmLineEnd       = 505;
  cmLineUp        = 506;
  cmLineDown      = 507;
  cmPageUp        = 508;
  cmPageDown      = 509;
  cmTextStart     = 510;
  cmTextEnd       = 511;
  cmNewLine       = 512;
  cmBackSpace     = 513;
  cmDelChar       = 514;
  cmDelWord       = 515;
  cmDelStart      = 516;
  cmDelEnd        = 517;
  cmDelLine       = 518;
  cmInsMode       = 519;
  cmStartSelect   = 520;
  cmHideSelect    = 521;
  cmUpdateTitle   = 523;

  { STATS - Start. }

  cmBludgeonStats = 524;

  { STATS - Stop. } { Needed this for TEditWindow.HandleEvent }



CONST { Editor constants for dialog boxes. }

  edOutOfMemory   = 0;
  edReadError     = 1;
  edWriteError    = 2;
  edCreateError   = 3;
  edSaveModify    = 4;
  edSaveUntitled  = 5;
  edSaveAs        = 6;
  edFind          = 7;
  edSearchFailed  = 8;
  edReplace       = 9;
  edReplacePrompt = 10;

  { JLINE  - Start. }
  { PRETAB - Start. }
  { REFDOC - Start. }
  { RMSET  - Start. }
  { WRAP   - Start. }

  edJumpToLine         = 11;
  edPasteNotPossible   = 12;
  edReformatDocument   = 13;
  edReformatNotAllowed = 14;
  edReformNotPossible  = 15;
  edReplaceNotPossible = 16;
  edRightMargin        = 17;
  edSetTabStops        = 18;
  edWrapNotPossible    = 19;

  { WRAP   - Stop. }
  { RMSET  - Stop. }
  { REFDOC - Stop. }
  { PRETAB - Stop. }
  { JLINE  - Stop. }



CONST { Editor flag constants for dialog options. }

  efCaseSensitive   = $0001;
  efWholeWordsOnly  = $0002;
  efPromptOnReplace = $0004;
  efReplaceAll      = $0008;
  efDoReplace       = $0010;
  efBackupFiles     = $0100;



CONST { Constants for object palettes. }

  CIndicator = #2#3;
  CEditor    = #6#7;
  CMemo      = #26#27;



CONST { Length constants. }

  MaxLineLength = 256;

  { PRETAB - Start. }

  Tab_Stop_Length = 74;

  { PRETAB - Stop. }



TYPE

  TEditorDialog = function (Dialog : Integer; Info : Pointer) : Word;



TYPE

  PIndicator = ^TIndicator;
  TIndicator = object (TView)

    Location   : Objects.TPoint;
    Modified   : Boolean;

    { STATS - Start. }

    AutoIndent   : Boolean;          { Added boolean for AutoIndent mode. }
    WordWrap     : Boolean;          { Added boolean for WordWrap mode.   }

    { STATS - Stop. }

    constructor Init (var Bounds : TRect);
    procedure   Draw; virtual;
    function    GetPalette : Views.PPalette; virtual;
    procedure   SetState (AState : Word; Enable : Boolean); virtual;

    { STATS - Start. }

    procedure   SetValue (ALocation : Objects.TPoint; IsAutoIndent : Boolean;
                                                      IsModified   : Boolean;
                                                      IsWordWrap   : Boolean);

    { STATS - Stop. } { Changed parameter calls to show them on TIndicator line. }

  end;



TYPE

  PEditBuffer = ^TEditBuffer;
  TEditBuffer = array[0..65519] of Char;



TYPE

  PEditor = ^TEditor;
  TEditor = object (TView)

    HScrollBar         : PScrollBar;
    VScrollBar         : PScrollBar;
    Indicator          : PIndicator;
    Buffer             : PEditBuffer;
    BufSize            : Word;
    BufLen             : Word;
    GapLen             : Word;
    SelStart           : Word;
    SelEnd             : Word;
    CurPtr             : Word;
    CurPos             : Objects.TPoint;
    Delta              : Objects.TPoint;
    Limit              : Objects.TPoint;
    DrawLine           : Integer;
    DrawPtr            : Word;
    DelCount           : Word;
    InsCount           : Word;
    IsValid            : Boolean;
    CanUndo            : Boolean;
    Modified           : Boolean;
    Selecting          : Boolean;
    Overwrite          : Boolean;
    AutoIndent         : Boolean;

    { WRAP - Start. }

    BlankLine          : Word;    { First blank line after a paragraph.      }
    Word_Wrap          : Boolean; { Added boolean to toggle wordwrap on/off. }

    { WRAP - Stop. }

    { JLINE - Start. }

    Line_Number        : string [4]; { Holds line number to jump to. }

    { JLINE - Stop. }

    { RMSET - Start. }

    Right_Margin       : Integer; { Added integer to set right margin.       }

    { RMSET - Stop. }

    { PRETAB - Start. }

    Tab_Settings : String[Tab_Stop_Length]; { Added string to hold tab stops. }

    { PRETAB - Stop. }

    constructor Init (var Bounds : TRect; AHScrollBar, AVScrollBar : PScrollBar;
                          AIndicator : PIndicator; ABufSize : Word);
    constructor Load (var S : Objects.TStream);
    destructor Done; virtual;
    function   BufChar (P : Word) : Char;
    function   BufPtr (P : Word) : Word;
    procedure  ChangeBounds (var Bounds : TRect); virtual;
    procedure  ConvertEvent (var Event : Drivers.TEvent); virtual;
    function   CursorVisible : Boolean;
    procedure  DeleteSelect;
    procedure  DoneBuffer; virtual;
    procedure  Draw; virtual;
    function   GetPalette : Views.PPalette; virtual;
    procedure  HandleEvent (var Event : Drivers.TEvent); virtual;
    procedure  InitBuffer; virtual;
    function   InsertBuffer (var P : PEditBuffer; Offset, Length : Word;
                                     AllowUndo, SelectText : Boolean) : Boolean;
    function   InsertFrom (Editor : PEditor) : Boolean; virtual;
    function   InsertText (Text : Pointer; Length : Word; SelectText : Boolean) : Boolean;
    procedure  ScrollTo (X, Y : Integer);
    function   Search (const FindStr : String; Opts : Word) : Boolean;
    function   SetBufSize (NewSize : Word) : Boolean; virtual;
    procedure  SetCmdState (Command : Word; Enable : Boolean);
    procedure  SetSelect (NewStart, NewEnd : Word; CurStart : Boolean);
    procedure  SetState (AState : Word; Enable : Boolean); virtual;
    procedure  Store (var S : Objects.TStream);
    procedure  TrackCursor (Center : Boolean);
    procedure  Undo;
    procedure  UpdateCommands; virtual;
    function   Valid (Command : Word) : Boolean; virtual;

  private

    KeyState       : Integer;
    LockCount      : Byte;
    UpdateFlags    : Byte;

    { MARK - Start. }

    Place_Marker   : Array [1..10] of Word; { Inserted array to hold place markers. }
    Search_Replace : Boolean; { Added boolean to test for Search and Replace insertions. }

    { MARK - Stop. }

    { CENTER - Start. }

    procedure  Center_Text (Select_Mode : Byte);

    { CENTER - Stop. } { Added procedure to center a line of text. }

    function   CharPos (P, Target : Word) : Integer;
    function   CharPtr (P : Word; Target : Integer) : Word;

    { WRAP -   Start. }

    procedure  Check_For_Word_Wrap (Select_Mode : Byte; Center_Cursor : Boolean);

    { WRAP -   Stop. } { Added procedure to check for word wrap. }

    function   ClipCopy : Boolean;
    procedure  ClipCut;
    procedure  ClipPaste;
    procedure  DeleteRange (StartPtr, EndPtr : Word; DelSelect : Boolean);
    procedure  DoSearchReplace;
    procedure  DoUpdate;

    { WRAP -   Start. }

    function   Do_Word_Wrap (Select_Mode : Byte; Center_Cursor : Boolean) : Boolean;

    { WRAP -   Stop. } { Added procedure to check for word wrap. }

    procedure  DrawLines (Y, Count : Integer; LinePtr : Word);
    procedure  FormatLine (var DrawBuf; LinePtr : Word; Width : Integer; Colors : Word);
    procedure  Find;
    function   GetMousePtr (Mouse : Objects.TPoint) : Word;
    function   HasSelection : Boolean;
    procedure  HideSelect;

    { INSLIN - Start. }

    procedure  Insert_Line (Select_Mode : Byte);

    { INSLIN - Stop. } { Added procedure to insert line at cursor. }

    function   IsClipboard : Boolean;

    { MARK -   Start. }

    procedure  Jump_Place_Marker (Element : Byte; Select_Mode : Byte);

    { MARK -   Stop. } { Added procedure to jump to a place marker if ^Q# is pressed. }

    { JLINE -  Start }

    procedure  Jump_To_Line  (Select_Mode : Byte);

    { JLINE -  Stop. }

    function   LineEnd (P : Word) : Word;
    function   LineMove (P : Word; Count : Integer) : Word;
    function   LineStart (P : Word) : Word;
    procedure  Lock;

    { WRAP -   Start. }

    function NewLine (Select_Mode : Byte) : Boolean;

    { WRAP -   Stop. } { Included a new parameter. }

    function   NextChar (P : Word) : Word;
    function   NextLine (P : Word) : Word;
    function   NextWord (P : Word) : Word;
    function   PrevChar (P : Word) : Word;
    function   PrevLine (P : Word) : Word;
    function   PrevWord (P : Word) : Word;

    { REFDOC - Start. }

    procedure  Reformat_Document (Select_Mode : Byte; Center_Cursor : Boolean);

    { REFDOC - Stop. } { Added procedure to allow document reformatting. }

    { REFORM - Start. }

    function   Reformat_Paragraph (Select_Mode   : Byte;
                                   Center_Cursor : Boolean) : Boolean;

    { REFORM - Stop. } { Added procedure to reformat paragraphs. }

    { WRAP -   Start. }

    procedure  Remove_EOL_Spaces (Select_Mode : Byte);

    { WRAP -   Stop. }  { Added procedure to remove spaces at end of a line. }

    procedure  Replace;

    { SCRLDN - Start. }

    procedure  Scroll_Down;

    { SCRLDN - Stop. }

    { SCRLUP - Start. }

    procedure  Scroll_Up;

    { SCRLUP - Stop. }

    { SELWRD - Start. }

    procedure  Select_Word;

    { SELWRD - Stop. } { Added procedure to allow selecting a word only. }

    procedure  SetBufLen (Length : Word);
    procedure  SetCurPtr (P : Word; SelectMode : Byte);

    { MARK -   Start. }

    procedure  Set_Place_Marker (Element : Byte);

    { MARK -   Stop. } { Added procedure to set a Place_Marker if ^K# is pressed. }

    { RMSET -  Start. }

    procedure  Set_Right_Margin;

    { RMSET -  Stop. } { Added procedure to set Right_Margin via a dialog box. }

    { PRETAB - Start. }

    procedure  Set_Tabs;

    { PRETAB - Stop. } { Added procedure to allow preset tabs. }

    procedure  StartSelect;

    { PRETAB - Start. }

    procedure  Tab_Key (Select_Mode : Byte);

    { PRETAB - Stop. } { Added procedure to process Tab key as spaces or movment. }

    procedure  ToggleInsMode;
    procedure  Unlock;
    procedure  Update (AFlags : Byte);

    { MARK -   Start. }

    procedure  Update_Place_Markers (AddCount : Word; KillCount : Word;
                                     StartPtr : Word;    EndPtr : Word);

    { MARK -   Stop. } { Added procedure to update Place_Marker as we change text. }

  end;



TYPE

  TMemoData = record

    Length : Word;
    Buffer : TEditBuffer;

  end;



TYPE

  PMemo = ^TMemo;
  TMemo = object (TEditor)

    constructor Load (var S : Objects.TStream);
    function    DataSize : Word; virtual;
    procedure   GetData (var Rec); virtual;
    function    GetPalette : Views.PPalette; virtual;
    procedure   HandleEvent (var Event : Drivers.TEvent); virtual;
    procedure   SetData (var Rec); virtual;
    procedure   Store (var S : Objects.TStream);

  end;



TYPE

  PFileEditor = ^TFileEditor;
  TFileEditor = object (TEditor)

    FileName : FNameStr;

    constructor Init (var Bounds : TRect; AHScrollBar, AVScrollBar : PScrollBar;
                          AIndicator : PIndicator; AFileName : FNameStr);
    constructor Load (var S : Objects.TStream);
    procedure   DoneBuffer; virtual;
    procedure   HandleEvent (var Event : Drivers.TEvent); virtual;
    procedure   InitBuffer; virtual;
    function    LoadFile : Boolean;
    function    Save : Boolean;
    function    SaveAs : Boolean;
    function    SaveFile : Boolean;
    function    SetBufSize (NewSize : Word) : Boolean; virtual;
    procedure   Store (var S : Objects.TStream);
    procedure   UpdateCommands; virtual;
    function    Valid (Command : Word) : Boolean; virtual;

  end;



TYPE

  PEditWindow = ^TEditWindow;
  TEditWindow = object (TWindow)

    Editor : PFileEditor;

    constructor Init (var Bounds : TRect; FileName : FNameStr; ANumber : Integer);
    constructor Load (var S : Objects.TStream);
    procedure   Close; virtual;
    function    GetTitle (MaxSize : Integer) : Views.TTitleStr; virtual;
    procedure   HandleEvent (var Event : Drivers.TEvent); virtual;
    procedure   SizeLimits(var Min, Max: TPoint); virtual;
    procedure   Store (var S : Objects.TStream);

  end;



function DefEditorDialog (Dialog : Integer; Info : Pointer) : Word;
function CreateFindDialog: PDialog;
function CreateReplaceDialog: PDialog;
function JumpLineDialog : PDialog;
function ReformDocDialog : PDialog;
function RightMarginDialog : PDialog;
function TabStopDialog : Dialogs.PDialog;
function StdEditorDialog(Dialog: Integer; Info: Pointer): Word;

CONST

  { PRETAB - Start. }
  { WRAP   - Start. }

  WordChars    : set of Char = ['!'..#255];

  { WRAP   - Stop. }
  { PRETAB - Stop. } { Changed set parameters to allow punctuation. }



  { ------------------------------------------------- }
  {                                                   }
  { The Allow_Reformat boolean is a programmer hook.  }
  { I've placed this here to allow programmers to     }
  { determine whether or not paragraph and document   }
  { reformatting are allowed if Word_Wrap is not      }
  { active.  Some people say don't allow, and others  }
  { say allow it.  I've left it up to the programmer. }
  { Set to FALSE if not allowed, or TRUE if allowed.  }
  {                                                   }
  { ------------------------------------------------- }

  Allow_Reformat : Boolean = True;

  EditorDialog   : TEditorDialog = DefEditorDialog;
  EditorFlags    : Word = efBackupFiles + efPromptOnReplace;
  FindStr        : String[80] = '';
  ReplaceStr     : String[80] = '';
  Clipboard      : PEditor = nil;



TYPE

  TFindDialogRec = record

    Find    : String[80];
    Options : Word;

  end;



  TReplaceDialogRec = record

       Find : String[80];
    Replace : String[80];
    Options : Word;

  end;



  { RMSET - Start. }

  TRightMarginRec = record

    Margin_Position : String[3];

  end;

  { RMSET - Stop. } { Record required by Right_Margin_Dialog. }



  { PRETAB - Start. }

  TTabStopRec = record

    Tab_String : String [Tab_Stop_Length];

  end;

  { PRETAB - Stop. } { Record required by Tab_Stop_Dialog. }



CONST { VMT constants. }

  REditor   : TStreamRec = (ObjType : 70;
                            VmtLink : Ofs (TypeOf (TEditor)^);
                               Load : @TEditor.Load;
                              Store : @TEditor.Store);


  RMemo     : TStreamRec = (ObjType : 71;
                            VmtLink : Ofs (TypeOf (TMemo)^);
                               Load : @TMemo.Load;
                              Store : @TMemo.Store);


  RFileEditor : TStreamRec = (ObjType : 72;
                              VmtLink : Ofs (TypeOf (TFileEditor)^);
                                 Load : @TFileEditor.Load;
                                Store : @TFileEditor.Store);


  RIndicator : TStreamRec = (ObjType : 73;
                             VmtLink : Ofs (TypeOf (TIndicator)^);
                                Load : @TIndicator.Load;
                               Store : @TIndicator.Store);


  REditWindow : TStreamRec = (ObjType : 74;
                              VmtLink : Ofs (TypeOf (TEditWindow)^);
                                 Load : @TEditWindow.Load;
                                Store : @TEditWindow.Store);



procedure RegisterEditors;




implementation



uses

  Memory, Dos, App, StdDlg, MsgBox, CmdFile;



CONST { Update flag constants. }

  ufUpdate = $01;
  ufLine   = $02;
  ufView   = $04;

  { STATS - Start. }

  ufStats  = $05;

  { STATS - Stop. }



CONST { SelectMode constants. }

  smExtend = $01;
  smDouble = $02;



CONST

  sfSearchFailed = $FFFF;



CONST { Arrays that hold all the command keys and options. }

  { CTRLBK - Start. }
  { HOMEND - Start. }
  { INDENT - Start. }
  { INSLIN - Start. }
  { JLINE  - Start. }
  { PRETAB - Start. }
  { REFORM - Start. }
  { SCRLDN - Start. }
  { SCRLDN - Start. }

  FirstKeys : array[0..46 * 2] of Word = (46, Ord (^A),    cmWordLeft,
                                              Ord (^B),    cmReformPara,
                                              Ord (^C),    cmPageDown,
                                              Ord (^D),    cmCharRight,
                                              Ord (^E),    cmLineUp,
                                              Ord (^F),    cmWordRight,
                                              Ord (^G),    cmDelChar,
                                              Ord (^H),    cmBackSpace,
                                              Ord (^I),    cmTabKey,
                                              Ord (^J),    $FF04,
                                              Ord (^K),    $FF02,
                                              Ord (^L),    cmSearchAgain,
                                              Ord (^M),    cmNewLine,
                                              Ord (^N),    cmInsertLine,
                                              Ord (^O),    $FF03,
                                              Ord (^Q),    $FF01,
                                              Ord (^R),    cmPageUp,
                                              Ord (^S),    cmCharLeft,
                                              Ord (^T),    cmDelWord,
                                              Ord (^U),    cmUndo,
                                              Ord (^V),    cmInsMode,
                                              Ord (^W),    cmScrollUp,
                                              Ord (^X),    cmLineDown,
                                              Ord (^Y),    cmDelLine,
                                              Ord (^Z),    cmScrollDown,
                                              kbLeft,      cmCharLeft,
                                              kbRight,     cmCharRight,
                                              kbCtrlLeft,  cmWordLeft,
                                              kbCtrlRight, cmWordRight,
                                              kbHome,      cmLineStart,
                                              kbEnd,       cmLineEnd,
                                              kbCtrlHome,  cmHomePage,
                                              kbCtrlEnd,   cmEndPage,
                                              kbUp,        cmLineUp,
                                              kbDown,      cmLineDown,
                                              kbPgUp,      cmPageUp,
                                              kbPgDn,      cmPageDown,
                                              kbCtrlPgUp,  cmTextStart,
                                              kbCtrlPgDn,  cmTextEnd,
                                              kbIns,       cmInsMode,
                                              kbDel,       cmDelChar,
                                              kbCtrlBack,  cmDelStart,
                                              kbShiftIns,  cmPaste,
                                              kbShiftDel,  cmCut,
                                              kbCtrlIns,   cmCopy,
                                              kbCtrlDel,   cmClear);

  { SCRLUP - Stop. } { Added ^W to scroll screen up.         }
  { SCRLDN - Stop. } { Added ^Z to scroll screen down.       }
  { REFORM - Stop. } { Added ^B for paragraph reformatting.  }
  { PRETAB - Stop. } { Added ^I for preset tabbing.          }
  { JLINE  - Stop. } { Added ^J to jump to a line number.    }
  { INSLIN - Stop. } { Added ^N to insert line at cursor.    }
  { INDENT - Stop. } { Removed ^O and put it into ^QI.       }
  { HOMEND - Stop. } { Added kbCtrlHome and kbCtrlEnd pages. }
  { CTRLBK - Stop. } { Added kbCtrlBack same as ^QH.         }

  { INDENT - Start. }
  { MARK   - Start. }
  { REFDOC - Start. }
  { UNDO   - Start. }

  QuickKeys : array[0..21 * 2] of Word = (21, Ord ('0'), cmJumpMark0,
                                              Ord ('1'), cmJumpMark1,
                                              Ord ('2'), cmJumpMark2,
                                              Ord ('3'), cmJumpMark3,
                                              Ord ('4'), cmJumpMark4,
                                              Ord ('5'), cmJumpMark5,
                                              Ord ('6'), cmJumpMark6,
                                              Ord ('7'), cmJumpMark7,
                                              Ord ('8'), cmJumpMark8,
                                              Ord ('9'), cmJumpMark9,
                                              Ord ('A'), cmReplace,
                                              Ord ('C'), cmTextEnd,
                                              Ord ('D'), cmLineEnd,
                                              Ord ('F'), cmFind,
                                              Ord ('H'), cmDelStart,
                                              Ord ('I'), cmIndentMode,
                                              Ord ('L'), cmUndo,
                                              Ord ('R'), cmTextStart,
                                              Ord ('S'), cmLineStart,
                                              Ord ('U'), cmReformDoc,
                                              Ord ('Y'), cmDelEnd);

  { UNDO   - Stop. } { Added IDE undo feature of ^QL.                  }
  { REFDOC - Stop. } { Added document reformat feature if ^QU pressed. }
  { MARK   - Stop. } { Added cmJumpMark# to allow place marking.       }
  { INDENT - Stop. } { Moved IndentMode here from Firstkeys.           }

  { MARK   - Start. }
  { SAVE   - Start. }
  { SELWRD - Start. }

  BlockKeys : array[0..20 * 2] of Word = (20, Ord ('0'), cmSetMark0,
                                              Ord ('1'), cmSetMark1,
                                              Ord ('2'), cmSetMark2,
                                              Ord ('3'), cmSetMark3,
                                              Ord ('4'), cmSetMark4,
                                              Ord ('5'), cmSetMark5,
                                              Ord ('6'), cmSetMark6,
                                              Ord ('7'), cmSetMark7,
                                              Ord ('8'), cmSetMark8,
                                              Ord ('9'), cmSetMark9,
                                              Ord ('B'), cmStartSelect,
                                              Ord ('C'), cmPaste,
                                              Ord ('D'), cmSave,
                                              Ord ('F'), cmSaveAs,
                                              Ord ('H'), cmHideSelect,
                                              Ord ('K'), cmCopy,
                                              Ord ('S'), cmSave,
                                              Ord ('T'), cmSelectWord,
                                              Ord ('Y'), cmCut,
                                              Ord ('X'), cmSaveDone);

  { SELWRD - Stop. } { Added ^KT to select word only. }
  { SAVE   - Stop. } { Added ^KD, ^KF, ^KS, ^KX key commands.   }
  { MARK   - Stop. } { Added cmSetMark# to allow place marking. }

  { CENTER - Start. }
  { PRETAB - Start. }
  { RMSET  - Start. }
  { WRAP   - Start. }

  FormatKeys : array[0..4 * 2] of Word = (4,  Ord ('C'), cmCenterText,
                                              Ord ('I'), cmSetTabs,
                                              Ord ('R'), cmRightMargin,
                                              Ord ('W'), cmWordWrap);

  { WRAP   - Stop. } { Added Wordwrap feature if ^OW pressed.          }
  { RMSET  - Stop. } { Added set right margin feature if ^OR pressed.  }
  { PRETAB - Stop. } { Added preset tab feature if ^OI pressed.        }
  { CENTER - Stop. } { Added center text option ^OC for a line.        }



  { JLINE - Start. }

  JumpKeys : array[0..1 * 2] of Word = (1, Ord ('L'), cmJumpLine);

  { JLINE - Stop. } { Added jump to line number feature if ^JL pressed. }



  { CENTER - Start. }
  { JLINE  - Start. }
  { PRETAB - Start. }
  { WRAP   - Start. }

  KeyMap : array[0..4] of Pointer = (@FirstKeys,
                                     @QuickKeys,
                                     @BlockKeys,
                                     @FormatKeys,
                                     @JumpKeys);

  { WRAP   - Stop. } { Added @FormatKeys for new ^O? keys. }
  { PRETAB - Stop. } { Added @FormatKeys for new ^O? keys. }
  { JLINE  - Stop. } { Added @JumpKeys for new ^J? keys.   }
  { CENTER - Stop. } { Added @FormatKeys for new ^O? keys. }



{ -------------------------------------------------------------------------- }



function DefEditorDialog (Dialog : Integer; Info : Pointer) : Word;

begin

  DefEditorDialog := Views.cmCancel;


end; { DefEditorDialog }

function CreateFindDialog: PDialog;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 38, 12);
  D := New(PDialog, Init(R, 'Find'));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Assign(3, 3, 32, 4);
    Control := New(PInputLine, Init(R, 80));
    Control^.HelpCtx := CmdFile.hcDFindText;
    Insert(Control);
    R.Assign(2, 2, 15, 3);
    Insert(New(PLabel, Init(R, '~T~ext to find', Control)));
    R.Assign(32, 3, 35, 4);
    Insert(New(PHistory, Init(R, PInputLine(Control), 10)));

    R.Assign(3, 5, 35, 7);
    Control := New(PCheckBoxes, Init(R,
        NewSItem ('~C~ase sensitive',
        NewSItem ('~W~hole words only',nil))));
    Control^.HelpCtx := CmdFile.hcCCaseSensitive;
    Insert(Control);

    R.Assign(14, 9, 24, 11);
    Control := New (PButton, Init(R, 'O~K~',cmOk,bfDefault));
    Control^.HelpCtx := CmdFile.hcDOk;
    Insert (Control);

    Inc(R.A.X, 12); Inc(R.B.X, 12);
    Control := New (PButton, Init(R, 'Cancel',cmCancel, bfNormal));
    Control^.HelpCtx := CmdFile.hcDCancel;
    Insert (Control);

    SelectNext(False);
  end;
  CreateFindDialog := D;
end;

function CreateReplaceDialog: PDialog;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 40, 16);
  D := New(PDialog, Init(R, 'Replace'));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Assign(3, 3, 34, 4);
    Control := New(PInputLine, Init(R, 80));
    Control^.HelpCtx := CmdFile.hcDFindText;
    Insert(Control);
    R.Assign(2, 2, 15, 3);
    Insert(New(PLabel, Init(R, '~T~ext to find', Control)));
    R.Assign(34, 3, 37, 4);
    Insert(New(PHistory, Init(R, PInputLine(Control), 10)));

    R.Assign(3, 6, 34, 7);
    Control := New(PInputLine, Init(R, 80));
    Control^.HelpCtx := CmdFile.hcDReplaceText;
    Insert(Control);
    R.Assign(2, 5, 12, 6);
    Insert(New(PLabel, Init(R, '~N~ew text', Control)));
    R.Assign(34, 6, 37, 7);
    Insert(New(PHistory, Init(R, PInputLine(Control), 11)));

    R.Assign(3, 8, 37, 12);
    Control := New (Dialogs.PCheckBoxes, Init (R,
      NewSItem ('~C~ase sensitive',
      NewSItem ('~W~hole words only',
      NewSItem ('~P~rompt on replace',
      NewSItem ('~R~eplace all', nil))))));
    Control^.HelpCtx := CmdFile.hcCCaseSensitive;
    Insert (Control);

    R.Assign (8, 13, 18, 15);
    Control := New (PButton, Init (R, 'O~K~', cmOk, bfDefault));
    Control^.HelpCtx := CmdFile.hcDOk;
    Insert (Control);

    R.Assign (22, 13, 32, 15);
    Control := New (PButton, Init (R, 'Cancel', cmCancel, bfNormal));
    Control^.HelpCtx := CmdFile.hcDCancel;
    Insert (Control);

    SelectNext(False);
  end;
  CreateReplaceDialog := D;
end;

function JumpLineDialog : PDialog;
VAR
  D      : PDialog;
  R      : TRect;
  Control: PView;
Begin
  R.Assign (0, 0, 26, 8);
  D := New(PDialog, Init(R, 'Jump To'));
  with D^ do
    begin
      Options := Options or ofCentered;

      R.Assign (3, 2, 15, 3);
      Control := New (Dialogs.PStaticText, Init (R, 'Line Number:'));
      Insert (Control);

      R.Assign (15, 2, 21, 3);
      Control := New (Dialogs.PInputLine, Init (R, 4));
      Control^.HelpCtx := CmdFile.hcDLineNumber;
      Insert (Control);

      R.Assign (21, 2, 24, 3);
      Insert (New (Dialogs.PHistory, Init (R, Dialogs.PInputLine (Control), 12)));

      R.Assign (2, 5, 12, 7);
      Control := New (Dialogs.PButton, Init (R, '~O~K', Views.cmOK, Dialogs.bfDefault));
      Control^.HelpCtx := CmdFile.hcDOk;
      Insert (Control);

      R.Assign (14, 5, 24, 7);
      Control := New (Dialogs.PButton, Init (R, '~C~ancel', Views.cmCancel, Dialogs.bfNormal));
      Control^.HelpCtx := CmdFile.hcDCancel;
      Insert (Control);

      SelectNext (False);
    end;
  JumpLineDialog := D;
end; { JumpLineDialog }
{ ------------------------------------------------------------------------ }

function ReformDocDialog : Dialogs.PDialog;
  { This is a local function that brings up a dialog box  }
  { that asks where to start reformatting the document.   }
VAR
  R            : TRect;
  D            : Dialogs.PDialog;
  Control      : Views.PView;
Begin
  R.Assign (0, 0, 32, 11);
  D := New (Dialogs.PDialog, Init (R, 'Reformat Document'));
  with D^ do
    begin
      Options := Options or ofCentered;

      R.Assign (2, 2, 30, 3);
      Control := New (Dialogs.PStaticText, Init (R, 'Please select where to begin'));
      Insert (Control);

      R.Assign (3, 3, 29, 4);
      Control := New (Dialogs.PStaticText, Init (R, 'reformatting the document:'));
      Insert (Control);

      R.Assign (50, 5, 68, 6);
      Control := New (Dialogs.PLabel, Init (R, 'Reformat Document', Control));
      Insert (Control);

      R.Assign (5, 5, 26, 7);
      Control := New (Dialogs.PRadioButtons, Init (R,
        NewSItem ('Current Line',
        NewSItem ('Entire Document', Nil))));
      Control^.HelpCtx := CmdFile.hcDReformDoc;
      Insert (Control);

      R.Assign (4, 8, 14, 10);
      Control := New (Dialogs.PButton, Init (R, '~O~K', Views.cmOK, Dialogs.bfDefault));
      Control^.HelpCtx := CmdFile.hcDOk;
      Insert (Control);

      R.Assign (17, 8, 27, 10);
      Control := New (Dialogs.PButton, Init (R, '~C~ancel', Views.cmCancel, Dialogs.bfNormal));
      Control^.HelpCtx := CmdFile.hcDCancel;
      Insert (Control);

      SelectNext (False);
    end;
    ReformDocDialog := D;
end; { ReformDocDialog }
{ ------------------------------------------------------------------------ }

function RightMarginDialog : Dialogs.PDialog;
  { This is a local function that brings up a dialog box }
  { that allows the user to change the Right_Margin.     }
VAR
  R        : TRect;
  D        : PDialog;
  Control  : PView;
Begin
  R.Assign (0, 0, 26, 8);
  D := New (Dialogs.PDialog, Init (R, 'Right Margin'));
  with D^ do
    begin
      Options := Options or ofCentered;

      R.Assign (5, 2, 13, 3);
      Control := New (Dialogs.PStaticText, Init (R, 'Setting:'));
      Insert (Control);

      R.Assign (13, 2, 18, 3);
      Control := New (Dialogs.PInputLine, Init (R, 3));
      Control^.HelpCtx := CmdFile.hcDRightMargin;
      Insert (Control);

      R.Assign (18, 2, 21, 3);
      Insert (New (Dialogs.PHistory, Init (R, Dialogs.PInputLine (Control), 13)));

      R.Assign (2, 5, 12, 7);
      Control := New (Dialogs.PButton, Init (R, 'OK', Views.cmOK, Dialogs.bfDefault));
      Control^.HelpCtx := CmdFile.hcDOk;
      Insert (Control);

      R.Assign (14, 5, 24, 7);
      Control := New (Dialogs.PButton, Init (R, '~C~ancel', Views.cmCancel, Dialogs.bfNormal));
      Control^.HelpCtx := CmdFile.hcDCancel;
      Insert (Control);

      SelectNext (False);
    end;
  RightMarginDialog := D;
end; { RightMarginDialog; }
{ ------------------------------------------------------------------------ }

function TabStopDialog : Dialogs.PDialog;
  { This is a local function that brings up a dialog box }
  { that allows the user to set their own tab stops.     }
VAR
  Index      : Integer;          { Local Indexing variable.                 }
  R          : TRect;
  D          : PDialog;
  Control    : PView;
  Tab_Stop   : String[2];        { Local string to print tab column number. }
Begin
  R.Assign (0, 0, 80, 8);
  D := New (Dialogs.PDialog, Init (R, 'Tab Settings'));
  with D^ do
    begin
      Options := Options or ofCentered;

      R.Assign (2, 2, 77, 3);
      Control := New (Dialogs.PStaticText, Init (R,
                  ' ....|....|....|....|....|....|....|....|....|....|....|....|....|....|....'));
      Insert (Control);

      for Index := 1 to 7 do
        begin
          R.Assign (Index * 10 + 1, 1, Index * 10 + 3, 2);
          Str (Index * 10, Tab_Stop);
          Control := New (Dialogs.PStaticText, Init (R, Tab_Stop));
          Insert (Control);
        end;

      R.Assign (2, 3, 78, 4);
      Control := New (Dialogs.PInputLine, Init (R, 74));
      Control^.HelpCtx := CmdFile.hcDTabStops;
      Insert (Control);

      R.Assign (38, 5, 41, 6);
      Insert (New (Dialogs.PHistory, Init (R, Dialogs.PInputLine (Control), 14)));

      R.Assign (27, 5, 37, 7);
      Control := New (Dialogs.PButton, Init (R, '~O~K', Views.cmOK, Dialogs.bfDefault));
      Control^.HelpCtx := CmdFile.hcDOk;
      Insert (Control);

      R.Assign (42, 5, 52, 7);
      Control := New (Dialogs.PButton, Init (R, '~C~ancel', Views.cmCancel, Dialogs.bfNormal));
      Control^.HelpCtx := CmdFile.hcDCancel;
      Insert (Control);
      SelectNext (False);
    end;
  TabStopDialog := D;
end { TabStopDialog };

function StdEditorDialog(Dialog: Integer; Info: Pointer): Word;
var
  R: TRect;
  T: TPoint;
begin
  case Dialog of
    edOutOfMemory:
      StdEditorDialog := MessageBox('Not enough memory for this operation.',
        nil, mfError + mfOkButton);
    edReadError:
      StdEditorDialog := MessageBox('Error reading file %s.',
        @Info, mfError + mfOkButton);
    edWriteError:
      StdEditorDialog := MessageBox('Error writing file %s.',
        @Info, mfError + mfOkButton);
    edCreateError:
      StdEditorDialog := MessageBox('Error creating file %s.',
        @Info, mfError + mfOkButton);
    edSaveModify:
      StdEditorDialog := MessageBox('%s has been modified. Save?',
        @Info, mfInformation + mfYesNoCancel);
    edSaveUntitled:
      StdEditorDialog := MessageBox('Save untitled file?',
        nil, mfInformation + mfYesNoCancel);
    edSaveAs:
      StdEditorDialog :=
        Application^.ExecuteDialog(New(PFileDialog, Init('*.*',
        'Save file as', '~N~ame', fdOkButton, 101)), Info);
    edFind:
      StdEditorDialog :=
        Application^.ExecuteDialog(CreateFindDialog, Info);
    edSearchFailed:
      StdEditorDialog := MessageBox('Search string not found.',
        nil, mfError + mfOkButton);
    edReplace:
      StdEditorDialog :=
        Application^.ExecuteDialog(CreateReplaceDialog, Info);
    edReplacePrompt:
      begin
        { Avoid placing the dialog on the same line as the cursor }
        R.Assign(0, 1, 40, 8);
        R.Move((Desktop^.Size.X - R.B.X) div 2, 0);
        Desktop^.MakeGlobal(R.B, T);
        Inc(T.Y);
        if TPoint(Info).Y <= T.Y then
          R.Move(0, Desktop^.Size.Y - R.B.Y - 2);
        StdEditorDialog := MessageBoxRect(R, 'Replace this occurence?',
          nil, mfYesNoCancel + mfInformation);
      end;
    edJumpToLine:
      StdEditorDialog := Application^.ExecuteDialog(JumpLineDialog, Info);
    { Added new cases to allow jumping to a line number. }
    edSetTabStops:
      StdEditorDialog := Application^.ExecuteDialog(TabStopDialog, Info);
    { Added new cases to support re-setting tab stops. }
    edPasteNotPossible:
      StdEditorDialog := MessageBox (^C'WORDWRAP ON:  Paste not possible' + #13
                        + ' in current margins when at end'  + #13
                        + ' of line.', nil, mfError + mfOkButton);
    edReformatDocument:
      StdEditorDialog := Application^.ExecuteDialog(ReformDocDialog, Info);
    { REFDOC - Stop. }
    edReformatNotAllowed:
      StdEditorDialog := MessageBox (^C'You must turn on wordwrap' + #13
                       +^C'before you can reformat.',
                        nil, mfError + mfOkButton);
    edReformNotPossible:
      StdEditorDialog := MessageBox (^C'Paragraph reformat not possible.'   + #13
                       + ' while trying to wrap current line' + #13
                       + ' with current margins.', nil, mfError + mfOkButton);
    edReplaceNotPossible:
      StdEditorDialog := MessageBox (^C'WORDWRAP ON:  Replace not possible' + #13
                       + ' in current margins when at end of' + #13
                       + ' line.', nil, mfError + mfOkButton);
    edRightMargin:
      StdEditorDialog := Application^.ExecuteDialog(RightMarginDialog, Info);
    { Added new cases to support right margin settings. }
    edWrapNotPossible:
      StdEditorDialog := MessageBox (^C'WORDWRAP ON:  Wordwrap not possible' + #13
                       + ' in current margins with continuous' + #13
                       + ' line.', nil, mfError + mfOKButton);
    { Added new cases to support wordwrap and paragraph reformatting. }
  else
    StdEditorDialog := MessageBox (^C'Unknown dialog requested!', nil,
                       mfError + mfOkButton);
  end;
end;



{ -------------------------------------------------------------------------- }



function Min(X, Y: Integer): Integer; near; assembler;

asm
        MOV     AX,X
        CMP     AX,Y
        JLE     @@1
        MOV     AX,Y
@@1:


end; { Min }



{ -------------------------------------------------------------------------- }



function Max(X, Y: Integer): Integer; near; assembler;

asm
        MOV     AX,X
        CMP     AX,Y
        JGE     @@1
        MOV     AX,Y
@@1:


end; { Max }



{ -------------------------------------------------------------------------- }



function MinWord(X, Y: Word): Word; near; assembler;

asm
        MOV     AX,X
        CMP     AX,Y
        JBE     @@1
        MOV     AX,Y
@@1:


end; { MinWord }



{ -------------------------------------------------------------------------- }



function MaxWord(X, Y: Word): Word; near; assembler;

asm
        MOV     AX,X
        CMP     AX,Y
        JAE     @@1
        MOV     AX,Y
@@1:


end; { MaxWord }



{ -------------------------------------------------------------------------- }



function CountLines(var Buf; Count: Word): Integer; near; assembler;

asm
        LES     DI,Buf
        MOV     CX,Count
        XOR     DX,DX
        MOV     AL,0DH
        CLD
@@1:    JCXZ    @@2
        REPNE   SCASB
        JNE     @@2
        INC     DX
        JMP     @@1
@@2:    MOV     AX,DX


end; { CountLines }



{ -------------------------------------------------------------------------- }



function ScanKeyMap(KeyMap: Pointer; KeyCode: Word): Word; near; assembler;

asm
        PUSH    DS
        LDS     SI,KeyMap
        MOV     DX,KeyCode
        CLD
        LODSW
        MOV     CX,AX
@@1:    LODSW
        MOV     BX,AX
        LODSW
        CMP     BL,DL
        JNE     @@3
        OR      BH,BH
        JE      @@4
        CMP     BH,DH
        JE      @@4
@@3:    LOOP    @@1
        XOR     AX,AX
@@4:    POP     DS


end; { ScanKeyMap }



{ -------------------------------------------------------------------------- }



function Scan(var Block; Size: Word; Str: String): Word; near; assembler;

asm
        PUSH    DS
        LES     DI,Block
        LDS     SI,Str
        MOV     CX,Size
        JCXZ    @@3
        CLD
        LODSB
        CMP     AL,1
        JB      @@5
        JA      @@1
        LODSB
        REPNE   SCASB
        JNE     @@3
        JMP     @@5
@@1:    XOR     AH,AH
        MOV     BX,AX
        DEC     BX
        MOV     DX,CX
        SUB     DX,AX
        JB      @@3
        LODSB
        INC     DX
        INC     DX
@@2:    DEC     DX
        MOV     CX,DX
        REPNE   SCASB
        JNE     @@3
        MOV     DX,CX
        MOV     CX,BX
        REP     CMPSB
        JE      @@4
        SUB     CX,BX
        ADD     SI,CX
        ADD     DI,CX
        INC     DI
        OR      DX,DX
        JNE     @@2
@@3:    XOR     AX,AX
        JMP     @@6
@@4:    SUB     DI,BX
@@5:    MOV     AX,DI
        SUB     AX,WORD PTR Block
@@6:    DEC     AX
        POP     DS


end; { Scan }



{ -------------------------------------------------------------------------- }

function IScan(var Block; Size: Word; Str: String): Word; near; assembler;

var
  S: String;
asm
        PUSH    DS
        MOV     AX,SS
        MOV     ES,AX
        LEA     DI,S
        LDS     SI,Str
        XOR     AH,AH
        LODSB
        STOSB
        MOV     CX,AX
        MOV     BX,AX
        JCXZ    @@9
@@1:    LODSB
        CMP     AL,'a'
        JB      @@2
        CMP     AL,'z'
        JA      @@2
        SUB     AL,20H
@@2:    STOSB
        LOOP    @@1
        SUB     DI,BX
        LDS     SI,Block
        MOV     CX,Size
        JCXZ    @@8
        CLD
        SUB     CX,BX
        JB      @@8
        INC     CX
@@4:    MOV     AH,ES:[DI]
        AND     AH,$DF
@@5:    LODSB
        AND     AL,$DF
        CMP     AL,AH
        LOOPNE  @@5
        JNE     @@8
        DEC     SI
        MOV     DX,CX
        MOV     CX,BX
@@6:    REPE    CMPSB
        JE      @@10
        MOV     AL,DS:[SI-1]
        CMP     AL,'a'
        JB      @@7
        CMP     AL,'z'
        JA      @@7
        SUB     AL,20H
@@7:    CMP     AL,ES:[DI-1]
        JE      @@6
        SUB     CX,BX
        ADD     SI,CX
        ADD     DI,CX
        INC     SI
        MOV     CX,DX
        OR      CX,CX
        JNE     @@4
@@8:    XOR     AX,AX
        JMP     @@11
@@9:    MOV     AX, 1
        JMP     @@11
@@10:   SUB     SI,BX
        MOV     AX,SI
        SUB     AX,WORD PTR Block
        INC     AX
@@11:   DEC     AX
        POP     DS
end;

{ -------------------------------------------------------------------------- }



         { ---------------------------------------------------- }
         {                                                      }
         { The following methods are for the TINDICATOR object. }
         {                                                      }
         { ---------------------------------------------------- }



constructor TIndicator.Init (var Bounds : TRect);

VAR

  R : TRect;

begin

  Inherited Init (Bounds);
  GrowMode := gfGrowLoY + gfGrowHiY;



end; { TIndicator.Init }



{ -------------------------------------------------------------------------- }



procedure TIndicator.Draw;

VAR

  Color : Byte;
  Frame : Char;
  L     : array[0..1] of Longint;
  S     : String[15];
  B     : Views.TDrawBuffer;

begin

  if State and sfDragging = 0 then
    begin
      Color := GetColor (1);
      Frame := #205;
    end
  else
    begin
      Color := GetColor (2);
      Frame := #196;
    end;

  MoveChar (B, Frame, Color, Size.X);



  { STATS - Start. }

  { -------------------------------------------------------------------- }
  {                                                                      }
  { If the text has been modified, put an 'M' in the TIndicator display. }
  {                                                                      }
  { -------------------------------------------------------------------- }


  if Modified then
    WordRec (B[1]).Lo := 77;



  { ---------------------------------------------------------- }
  {                                                            }
  { If WordWrap is active put a 'W' in the TIndicator display. }
  { Otherwise, just use the current frame character.           }
  {                                                            }
  { ---------------------------------------------------------- }


  if WordWrap then
    WordRec (B[2]).Lo := 87
  else
    WordRec (B[2]).Lo := Byte (Frame);



  { --------------------------------------------------------- }
  {                                                           }
  { If AutoIndent is active put an 'I' in TIndicator display. }
  { Otherwise, just use the current frame character.          }
  {                                                           }
  { --------------------------------------------------------- }


  if AutoIndent then
    WordRec (B[0]).Lo := 73
  else
    WordRec (B[0]).Lo := Byte (Frame);

  L[0] := Location.Y + 1;
  L[1] := Location.X + 1;

  FormatStr (S, ' %d:%d ', L);
  MoveStr (B[9 - Pos (':', S)], S, Color);       { Changed original 8 to 9. }
  WriteBuf (0, 0, Size.X, 1, B);

  { STATS - Stop. } { Changed who goes where in B array and added new code. }


end; { TIndicator.Draw }



{ -------------------------------------------------------------------------- }



function TIndicator.GetPalette : Views.PPalette;

CONST

  P : string[Length (CIndicator)] = CIndicator;

begin

  GetPalette := @P;


end; { TIndicator.GetPalette }



{ -------------------------------------------------------------------------- }



procedure TIndicator.SetState (AState : Word; Enable : Boolean);

begin

  Inherited SetState (AState, Enable);
  if AState = sfDragging
    then DrawView;


end; { TIndicator.SetState }



{ -------------------------------------------------------------------------- }



{ STATS - Start. }

procedure TIndicator.SetValue (ALocation : Objects.TPoint; IsAutoIndent : Boolean;
                                                           IsModified   : Boolean;
                                                           IsWordWrap   : Boolean);

begin

  if   (Longint (Location) <> Longint (ALocation))
    or (AutoIndent <> IsAutoIndent)
    or (Modified <> IsModified)
    or (WordWrap <> IsWordWrap) then
  begin
    Location   := ALocation;
    AutoIndent := IsAutoIndent;    { Added provisions to show AutoIndent. }
    Modified   := IsModified;
    WordWrap   := IsWordWrap;      { Added provisions to show WordWrap.   }

    DrawView;
  end;


end; { TIndicator.SetValue }

{ STATS - Stop. } { Changed parameter calls to show them on TIndicator line. }



{ -------------------------------------------------------------------------- }



         { ------------------------------------------------- }
         {                                                   }
         { The following methods are for the TEDITOR object. }
         {                                                   }
         { ------------------------------------------------- }



constructor TEditor.Init (var Bounds : TRect;
                              AHScrollBar, AVScrollBar : PScrollBar;
                              AIndicator : PIndicator; ABufSize : Word);

{ MARK - Start. }

VAR

  Element : Byte;      { Place_Marker array element to initialize array with. }

{ MARK - Stop. } { Added Element variable. }

begin

  Inherited Init (Bounds);
  GrowMode := gfGrowHiX + gfGrowHiY;
  Options := Options or ofSelectable;
  EventMask := evMouseDown + evKeyDown + evCommand + evBroadcast;
  ShowCursor;

  HScrollBar := AHScrollBar;
  VScrollBar := AVScrollBar;

  Indicator := AIndicator;
  BufSize := ABufSize;
  CanUndo := True;
  InitBuffer;

  if assigned(Buffer) then
    IsValid := True
  else
    begin
      EditorDialog (edOutOfMemory, nil);
      BufSize := 0;
    end;

  SetBufLen (0);

  { MARK - Start. }

  for Element := 1 to 10 do
    Place_Marker[Element] := 0;

  { MARK - Stop. } { Added code to initialize Place_Marker array to zero's. }

  { PRETAB - Start. }

  Element := 1;

  while Element <= 70 do
    begin
      if Element mod 5 = 0 then
        Insert ('x', Tab_Settings, Element)
      else
        Insert (#32, Tab_Settings, Element);
      Inc (Element);
    end;

  { PRETAB - Stop. }

  { WRAP - Start. }

  Right_Margin := 76; { Default Right_Margin value.  Change it if you want another. }

  { WRAP - Stop. }


end; { TEditor.Init }



{ -------------------------------------------------------------------------- }



constructor TEditor.Load (var S : Objects.TStream);

begin

  Inherited Load (S);

  GetPeerViewPtr (S, HScrollBar);
  GetPeerViewPtr (S, VScrollBar);
  GetPeerViewPtr (S, Indicator);
  S.Read (BufSize, SizeOf (Word));


  { LOAD - Start. }

  S.Read (CanUndo, SizeOf (Boolean));

  { LOAD - Stop. } { This item caused load/store bug. }


  { STATS  - Start. }
  { JLINE  - Start. }
  { MARK   - Start. }
  { RMSET  - Start. }
  { PRETAB - Start. }
  { WRAP   - Start. }

  S.Read (AutoIndent,   SizeOf (AutoIndent));
  S.Read (Line_Number,  SizeOf (Line_Number));
  S.Read (Place_Marker, SizeOf (Place_Marker));
  S.Read (Right_Margin, SizeOf (Right_Margin));
  S.Read (Tab_Settings, SizeOf (Tab_Settings));
  S.Read (Word_Wrap,    SizeOf (Word_Wrap));

{  CanUndo := True; }

  { WRAP   - Stop. }
  { PRETAB - Stop. }
  { RMSET  - Stop. }
  { MARK   - Stop. }
  { JLINE  - Stop. }
  { STATS  - Stop. } { Added these to allow load/store operations. }

  InitBuffer;

  if Assigned(Buffer) then
    IsValid := True
  else
    begin
      EditorDialog (edOutOfMemory, nil);
      BufSize := 0;
    end;

  Lock;

  SetBufLen (0);


end; { TEditor.Load }



{ -------------------------------------------------------------------------- }



destructor TEditor.Done;

begin

  DoneBuffer;
  Inherited Done;


end; { TEditor.Done }



{ -------------------------------------------------------------------------- }



function TEditor.BufChar (P : Word) : Char; assembler;

asm
        LES     DI,Self
        MOV     BX,P
        CMP     BX,ES:[DI].TEditor.CurPtr
        JB      @@1
        ADD     BX,ES:[DI].TEditor.GapLen
@@1:    LES     DI,ES:[DI].TEditor.Buffer
        MOV     AL,ES:[DI+BX]


end; { TEditor.BufChar }



{ -------------------------------------------------------------------------- }



function TEditor.BufPtr (P : Word) : Word; assembler;

asm
        LES     DI,Self
        MOV     AX,P
        CMP     AX,ES:[DI].TEditor.CurPtr
        JB      @@1
        ADD     AX,ES:[DI].TEditor.GapLen
@@1:


end; { TEditor.BufPtr }



{ -------------------------------------------------------------------------- }



{ CENTER - Start. }

procedure TEditor.Center_Text (Select_Mode : Byte);


  { ---------------------------------------------------- }
  {                                                      }
  { This procedure will center the current line of text. }
  { Centering is based on the current Right_Margin.      }
  { If the Line_Length exceeds the Right_Margin, or the  }
  { line is just a blank line, we exit and do nothing.   }
  {                                                      }
  { ---------------------------------------------------- }


VAR

  Spaces      : array [1..80] of Char;  { Array to hold spaces we'll insert. }
  Index       : Byte;                   { Index into Spaces array.           }
  Line_Length : Integer;                { Holds the length of the line.      }

  E : Word;                             { End of the current line.           }
  S : Word;                             { Start of the current line.         }

begin

  E := LineEnd (CurPtr);
  S := LineStart (CurPtr);



  { --------------------------------------------------------- }
  {                                                           }
  { If the line is blank (only a CR/LF on it) then do noting. }
  {                                                           }
  { --------------------------------------------------------- }


  if E = S then
    Exit;



  { ----------------------------------------------------------------- }
  {                                                                   }
  { Set CurPtr to start of line.  Check if line begins with a space.  }
  { We must strip out any spaces from the beginning, or end of lines. }
  { If line does not start with space, make sure line length does not }
  { exceed the Right_Margin.  If it does, then do nothing.            }
  {                                                                   }
  { ----------------------------------------------------------------- }


  SetCurPtr (S, Select_Mode);
  Remove_EOL_Spaces (Select_Mode);

  if Buffer^[CurPtr] = #32 then
    begin



      { ----------------------------------------------------------------- }
      {                                                                   }
      { If the next word is greater than the end of line then do nothing. }
      { If the line length is greater than Right_Margin then do nothing.  }
      { Otherwise, delete all spaces at the start of line.                }
      { Then reset end of line and put CurPtr at start of modified line.  }
      {                                                                   }
      { ----------------------------------------------------------------- }

      E := LineEnd (CurPtr);

      if NextWord (CurPtr) > E then
        Exit;
      if E - NextWord (CurPtr) > Right_Margin then
        Exit;

      DeleteRange (CurPtr, NextWord (CurPtr), True);

      E := LineEnd (CurPtr);
      SetCurPtr (LineStart (CurPtr), Select_Mode);

    end
  else
    if E - CurPtr > Right_Margin then
      Exit;



  { --------------------------------------------------- }
  {                                                     }
  { Now we determine the real length of the line.       }
  { Then we subtract the Line_Length from Right_Margin. }
  { Dividing the result by two tells us how many spaces }
  { must be inserted at start of line to center it.     }
  { When we're all done, set the CurPtr to end of line. }
  {                                                     }
  { --------------------------------------------------- }


  Line_Length := E - CurPtr;

  for Index := 1 to ((Right_Margin - Line_Length) DIV 2) do
    Spaces[Index] := #32;

  InsertText (@Spaces, Index, False);
  SetCurPtr (LineEnd (CurPtr), Select_Mode);


end; { TEditor.Center_Text }

{ CENTER - Stop. }



{ -------------------------------------------------------------------------- }



procedure TEditor.ChangeBounds (var Bounds : TRect);

begin

  SetBounds (Bounds);
  Delta.X := Max (0, Min (Delta.X, Limit.X - Size.X));
  Delta.Y := Max (0, Min (Delta.Y, Limit.Y - Size.Y));
  Update (ufView);


end; { TEditor.ChangeBounds }



{ -------------------------------------------------------------------------- }



function TEditor.CharPos (P, Target : Word) : Integer;

VAR

  Pos : Integer;

begin

  Pos := 0;

  while P < Target do
  begin
    if BufChar (P) = #9 then
      Pos := Pos or 7;
    Inc (Pos);
    Inc (P);
  end;

  CharPos := Pos;


end; { TEditor.CharPos }



{ -------------------------------------------------------------------------- }



function TEditor.CharPtr (P : Word; Target : Integer) : Word;

VAR

  Pos : Integer;

begin

  Pos := 0;

  while (Pos < Target) and (P < BufLen) and (BufChar (P) <> #13) do
  begin
    if BufChar (P) = #9 then
      Pos := Pos or 7;
    Inc (Pos);
    Inc (P);
  end;

  if Pos > Target then
    Dec (P);

  CharPtr := P;


end; { TEditor.CharPtr }



{ -------------------------------------------------------------------------- }



{ WRAP - Start. }

procedure TEditor.Check_For_Word_Wrap (Select_Mode   : Byte;
                                       Center_Cursor : Boolean);



  { ------------------------------------------------- }
  {                                                   }
  { This procedure checks if CurPos.X > Right_Margin. }
  { If it is, then we Do_Word_Wrap.  Simple, eh?      }
  {                                                   }
  { ------------------------------------------------- }

begin

  if CurPos.X > Right_Margin then
    Do_Word_Wrap (Select_Mode, Center_Cursor);


end; {Check_For_Word_Wrap}

{ WRAP - Stop. }



{ -------------------------------------------------------------------------- }



function TEditor.ClipCopy : Boolean;

begin

  ClipCopy := False;

  if Assigned(Clipboard) and (Clipboard <> @Self) then
  begin
    ClipCopy := Clipboard^.InsertFrom (@Self);
    Selecting := False;
    Update (ufUpdate);
  end;


end; { TEditor.ClipCopy }



{ -------------------------------------------------------------------------- }



procedure TEditor.ClipCut;

begin

  if ClipCopy then
  begin

    { MARK - Start. }

    Update_Place_Markers (0,
                          Self.SelEnd - Self.SelStart,
                          Self.SelStart,
                          Self.SelEnd);
    { MARK - Stop. }

    DeleteSelect;

  end;


end; { TEditor.ClipCut }



{ -------------------------------------------------------------------------- }



procedure TEditor.ClipPaste;

begin



  if Assigned(Clipboard) and (Clipboard <> @Self) then
    begin



      { WRAP - Start. }

      { ---------------------------------------------- }
      {                                                }
      { Do not allow paste operations that will exceed }
      { the Right_Margin when Word_Wrap is active and  }
      { cursor is at EOL.                              }
      {                                                }
      { ---------------------------------------------- }


      if Word_Wrap and (CurPos.X > Right_Margin) then

        begin
          EditorDialog (edPasteNotPossible, nil);
          Exit;
        end;

      { WRAP - Stop. }



      { MARK - Start. }

      { ---------------------------------------------------- }
      {                                                      }
      { The editor will not copy selected text if the CurPtr }
      { is not the same value as the SelStart.  However, it  }
      { does return an InsCount.  This may, or may not, be a }
      { bug.  We don't want to update the Place_Marker if    }
      { there's no text copied.                              }
      {                                                      }
      { ---------------------------------------------------- }

      if CurPtr = SelStart then

        Update_Place_Markers (Clipboard^.SelEnd - Clipboard^.SelStart,
                              0,
                              Clipboard^.SelStart,
                              Clipboard^.SelEnd);

      { MARK - Stop. }

      InsertFrom (Clipboard);


    end;


end; { TEditor.ClipPaste }



{ -------------------------------------------------------------------------- }



procedure TEditor.ConvertEvent (var Event : Drivers.TEvent);

VAR

  ShiftState : Byte absolute $40:$17;
  Key        : Word;


begin

  if Event.What = evKeyDown then
  begin

    if (ShiftState and $03 <> 0)
                   and (Event.ScanCode >= $47)
                   and (Event.ScanCode <= $51) then
      Event.CharCode := #0;

    Key := Event.KeyCode;

    if KeyState <> 0 then
    begin
      if (Lo (Key) >= $01) and (Lo (Key) <= $1A) then
        Inc (Key, $40);
      if (Lo (Key) >= $61) and (Lo (Key) <= $7A) then
        Dec (Key, $20);
    end;

    Key := ScanKeyMap (KeyMap[KeyState], Key);
    KeyState := 0;

    if Key <> 0 then
      if Hi (Key) = $FF then
        begin
          KeyState := Lo (Key);
          ClearEvent (Event);
        end
      else
        begin
          Event.What := evCommand;
          Event.Command := Key;
        end;
  end;


end; { TEditor.ConvertEvent }



{ -------------------------------------------------------------------------- }



function TEditor.CursorVisible : Boolean;

begin

  CursorVisible := (CurPos.Y >= Delta.Y) and (CurPos.Y < Delta.Y + Size.Y);

end; { TEditor.CursorVisible }



{ -------------------------------------------------------------------------- }



procedure TEditor.DeleteRange (StartPtr, EndPtr : Word; DelSelect : Boolean);


begin

  { MARK - Start. }

  Update_Place_Markers (0, EndPtr - StartPtr, StartPtr, EndPtr);

  { MARK - Stop. } { This will update Place_Marker for all deletions. }
                   { EXCEPT the Remove_EOL_Spaces deletion.           }

  if HasSelection and DelSelect then
    DeleteSelect
  else
    begin
      SetSelect (CurPtr, EndPtr, True);
      DeleteSelect;
      SetSelect (StartPtr, CurPtr, False);
      DeleteSelect;
    end;


end; { TEditor.DeleteRange }



{ -------------------------------------------------------------------------- }



procedure TEditor.DeleteSelect;

begin

  InsertText (nil, 0, False);

end; { TEditor.DeleteSelect }



{ -------------------------------------------------------------------------- }


procedure TEditor.DoneBuffer;

begin

  if assigned(Buffer) then
  begin
    FreeMem (Buffer, BufSize);
    Buffer := nil;
  end;

end; { TEditor.DoneBuffer }



{ -------------------------------------------------------------------------- }



procedure TEditor.DoSearchReplace;

VAR

  I : Word;
  C : Objects.TPoint;

begin
  repeat

    I := Views.cmCancel;

    if not Search (FindStr, EditorFlags) then
      begin
        if EditorFlags and (efReplaceAll + efDoReplace) <>
            (efReplaceAll + efDoReplace) then
          EditorDialog (edSearchFailed, nil)
      end
    else

      if EditorFlags and efDoReplace <> 0 then
      begin

        I := cmYes;
        if EditorFlags and efPromptOnReplace <> 0 then
        begin
          MakeGlobal (Cursor, C);
          I := EditorDialog (edReplacePrompt, Pointer (C));
        end;

        if I = cmYes then
          begin

            { WRAP - Start. }

            { ---------------------------------------- }
            {                                          }
            { If Word_Wrap is active and we are at EOL }
            { disallow replace by bringing up a dialog }
            { stating that replace is not possible.    }
            {                                          }
            { ---------------------------------------- }

            if Word_Wrap and
               ((CurPos.X + (Length (ReplaceStr) - Length (FindStr))) > Right_Margin) then
              EditorDialog (edReplaceNotPossible, nil)
            else

            { WRAP - Stop. }

              begin

                Lock;

                { MARK - Start. }

                Search_Replace := True;

                if length (ReplaceStr) < length (FindStr) then
                  Update_Place_Markers (0,
                                        Length (FindStr) - Length (ReplaceStr),
                                        CurPtr - Length (FindStr) + Length (ReplaceStr),
                                        CurPtr)
                else
                  if length (ReplaceStr) > length (FindStr) then
                    Update_Place_Markers (Length (ReplaceStr) - Length (FindStr),
                                          0,
                                          CurPtr,
                                          CurPtr + (Length (ReplaceStr) - Length (FindStr)));

                { MARK - Stop. }

                InsertText (@ReplaceStr[1], Length (ReplaceStr), False);

                { MARK - Start. }

                Search_Replace := False;

                { MARK - Stop. }

                TrackCursor (False);
                Unlock;

             end;
          end;
      end;

  until (I = Views.cmCancel) or (EditorFlags and efReplaceAll = 0);


end; { TEditor.DoSearchReplace }



{ -------------------------------------------------------------------------- }



procedure TEditor.DoUpdate;

begin

  if UpdateFlags <> 0 then
  begin

    SetCursor (CurPos.X - Delta.X, CurPos.Y - Delta.Y);

    if UpdateFlags and ufView <> 0 then
      DrawView
    else
      if UpdateFlags and ufLine <> 0 then
        DrawLines (CurPos.Y - Delta.Y, 1, LineStart (CurPtr));

    if assigned(HScrollBar) then
      HScrollBar^.SetParams (Delta.X, 0, Limit.X - Size.X, Size.X div 2, 1);

    if assigned(VScrollBar) then
      VScrollBar^.SetParams (Delta.Y, 0, Limit.Y - Size.Y, Size.Y - 1, 1);

    { STATS - Start. }

    if assigned(Indicator) then
      Indicator^.SetValue (CurPos, AutoIndent, Modified, Word_Wrap);

    { STATS - Stop. } { Added AutoIndent and Word_Wrap parameters. }

    if State and sfActive <> 0 then
      UpdateCommands;

    UpdateFlags := 0;

  end;


end; { TEditor.DoUpdate }



{ -------------------------------------------------------------------------- }



{ WRAP - Start. }

function TEditor.Do_Word_Wrap (Select_Mode   : Byte;
                               Center_Cursor : Boolean) : Boolean;



  { ---------------------------------------------------------------------- }
  {                                                                        }
  { This procedure does the actual wordwrap.  It always assumes the CurPtr }
  { is at Right_Margin + 1.  It makes several tests for special conditions }
  { and processes those first.  If they all fail, it does a normal wrap.   }
  {                                                                        }
  { ---------------------------------------------------------------------- }


VAR

  A : Word;          { Distance between line start and first word on line. }
  C : Word;          { Current pointer when we come into procedure.        }
  L : Word;          { BufLen when we come into procedure.                 }
  P : Word;          { Position of pointer at any given moment.            }
  S : Word;          { Start of a line.                                    }

begin

  Do_Word_Wrap := False;
  Select_Mode := 0;

  if BufLen >= (BufSize - 1) then
    exit;

  C := CurPtr;
  L := BufLen;
  S := LineStart (CurPtr);



  { -------------------------------------------------------------------- }
  {                                                                      }
  { If first character in the line is a space and autoindent mode is on  }
  { then we check to see if NextWord(S) exceeds the CurPtr.  If it does, }
  { we set CurPtr as the AutoIndent marker.  If it doesn't, we will set  }
  { NextWord(S) as the AutoIndent marker.  If neither, we set it to S.   }
  {                                                                      }
  { -------------------------------------------------------------------- }


  if AutoIndent and (Buffer^[S] = ' ') then
    begin
      if NextWord (S) > CurPtr then
        A := CurPtr
      else
        A := NextWord (S);
    end
  else
    A := NextWord (S);



  { --------------------------------------------------------- }
  {                                                           }
  { Though NewLine will remove EOL spaces, we do it here too. }
  { This catches the instance where a user may try to space   }
  { completely across the line, in which case CurPtr.X = 0.   }
  {                                                           }
  { --------------------------------------------------------- }


  Remove_EOL_Spaces (Select_Mode);

  if CurPos.X = 0 then
    begin
      NewLine (Select_Mode);
      Do_Word_Wrap := True;
      Exit;
    end;



  { --------------------------------------------------------------------------- }
  {                                                                             }
  { At this point we have one of five situations:                               }
  {                                                                             }
  { 1)  AutoIndent is on and this line is all spaces before CurPtr.             }
  { 2)  AutoIndent is off and this line is all spaces before CurPtr.            }
  { 3)  AutoIndent is on and this line is continuous characters before CurPtr.  }
  { 4)  AutoIndent is off and this line is continuous characters before CurPtr. }
  { 5)  This is just a normal line of text.                                     }
  {                                                                             }
  { Conditions 1 through 4 have to be taken into account before condition 5.    }
  {                                                                             }
  { --------------------------------------------------------------------------- }



  { ------------------------------------------------------------ }
  {                                                              }
  { First, we see if there are all spaces and/or all characters. }
  { Then we determine which one it really is.  Finally, we take  }
  { a course of action based on the state of AutoIndent.         }
  {                                                              }
  { ------------------------------------------------------------ }



  if PrevWord (CurPtr) <= S then
    begin

      P := CurPtr - 1;

      while ((Buffer^[P] <> ' ') and (P > S)) do
        Dec (P);



      { -------------------------------------------------------------- }
      {                                                                }
      { We found NO SPACES.  Conditions 4 and 5 are treated the same.  }
      { We can NOT do word wrap and put up a dialog box stating such.  }
      { Delete character just entered so we don't exceed Right_Margin. }
      {                                                                }
      { -------------------------------------------------------------- }


      if P = S then
        begin
          EditorDialog (edWrapNotPossible, nil);
          DeleteRange (PrevChar (CurPtr), CurPtr, True);
          Exit;
        end
      else
        begin



          { ------------------------------------------------------- }
          {                                                         }
          { There are spaces.  Now find out if they are all spaces. }
          { If so, see if AutoIndent is on.  If it is, turn it off, }
          { do a NewLine, and turn it back on.  Otherwise, just do  }
          { the NewLine.  We go through all of these gyrations for  }
          { AutoIndent.  Being way out here with a preceding line   }
          { of spaces and wrapping with AutoIndent on is real dumb! }
          { However, the user expects something.  The wrap will NOT }
          { autoindent, but they had no business being here anyway! }
          {                                                         }
          { ------------------------------------------------------- }


          P := CurPtr - 1;

          while ((Buffer^[P] = ' ') and (P > S)) do
            Dec (P);

          if P = S then
            begin

              if Autoindent then
                begin
                  AutoIndent := False;
                  NewLine (Select_Mode);
                  AutoIndent := True;
                end
              else
                NewLine (Select_Mode);
              end; { AutoIndent }

            end; { P = S for spaces }

        end { P = S for no spaces }

    else { PrevWord (CurPtr) <= S }

      begin


        { ---------------------------------------------------------------- }
        {                                                                  }
        { Hooray!  We actually had a plain old line of text to wrap!       }
        { Regardless if we are pushing out a line beyond the Right_Margin, }
        { or at the end of a line itself, the following will determine     }
        { exactly where to do the wrap and re-set the cursor accordingly.  }
        { However, if P = A then we can't wrap.  Show dialog and exit.     }
        {                                                                  }
        { ---------------------------------------------------------------- }


        P := CurPtr;

        while P - S > Right_Margin do
          P := PrevWord (P);

        if (P = A) then
          begin
            EditorDialog (edReformNotPossible, nil);
            SetCurPtr (P, Select_Mode);
            Exit;
          end;

        SetCurPtr (P, Select_Mode);
        NewLine (Select_Mode);

    end; { PrevWord (CurPtr <= S }



  { ---------------------------------------------------------- }
  {                                                            }
  { Track the cursor here (it is at CurPos.X = 0) so the view  }
  { will redraw itself at column 0.  This eliminates having it }
  { redraw starting at the current cursor and not being able   }
  { to see text before the cursor.  Of course, we also end up  }
  { redrawing the view twice, here and back in HandleEvent.    }
  {                                                            }
  { Reposition cursor so user can pick up where they left off. }
  {                                                            }
  { ---------------------------------------------------------- }


  TrackCursor (Center_Cursor);
  SetCurPtr (C - (L - BufLen), Select_Mode);

  Do_Word_Wrap := True;


end; { TEditor.Do_Word_Wrap }

{ WRAP - Stop. }



{ -------------------------------------------------------------------------- }



procedure TEditor.Draw;

begin

  if DrawLine <> Delta.Y then
  begin
    DrawPtr := LineMove (DrawPtr, Delta.Y - DrawLine);
    DrawLine := Delta.Y;
  end;

  DrawLines (0, Size.Y, DrawPtr);


end; { TEditor.Draw }



{ -------------------------------------------------------------------------- }



procedure TEditor.DrawLines (Y, Count : Integer; LinePtr : Word);

VAR

  Color : Word;
  B     : array[0..MaxLineLength - 1] of Word;

begin

  Color := GetColor ($0201);

  while Count > 0 do
  begin
    FormatLine (B, LinePtr, Delta.X + Size.X, Color);
    WriteBuf (0, Y, Size.X, 1, B[Delta.X]);
    LinePtr := NextLine (LinePtr);
    Inc (Y);
    Dec (Count);
  end;


end; { TEditor.DrawLines }



{ -------------------------------------------------------------------------- }



procedure TEditor.Find;

VAR

  FindRec : TFindDialogRec;

begin

  with FindRec do
  begin

    Find := FindStr;
    Options := EditorFlags;

    if EditorDialog (edFind, @FindRec) <> Views.cmCancel then
    begin
      FindStr := Find;
      EditorFlags := Options and not efDoReplace;
      DoSearchReplace;
    end;

  end;


end; { TEditor.Find }



{ -------------------------------------------------------------------------- }



procedure TEditor.FormatLine (var DrawBuf; LinePtr : Word;
                                  Width  : Integer;
                                  Colors : Word); assembler;

asm
        PUSH    DS
        LDS     BX,Self
        LES     DI,DrawBuf
        MOV     SI,LinePtr
        XOR     DX,DX
        CLD
        MOV     AH,Colors.Byte[0]
        MOV     CX,DS:[BX].TEditor.SelStart
        CALL    @@10
        MOV     AH,Colors.Byte[1]
        MOV     CX,DS:[BX].TEditor.CurPtr
        CALL    @@10
        ADD     SI,DS:[BX].TEditor.GapLen
        MOV     CX,DS:[BX].TEditor.SelEnd
        ADD     CX,DS:[BX].TEditor.GapLen
        CALL    @@10
        MOV     AH,Colors.Byte[0]
        MOV     CX,DS:[BX].TEditor.BufSize
        CALL    @@10
        JMP     @@31
@@10:   SUB     CX,SI
        JA      @@11
        RETN
@@11:   LDS     BX,DS:[BX].TEditor.Buffer
        ADD     SI,BX
        MOV     BX,Width
@@12:   LODSB
        CMP     AL,' '
        JB      @@20
@@13:   STOSW
        INC     DX
@@14:   CMP     DX,BX
        JAE     @@30
        LOOP    @@12
        LDS     BX,Self
        SUB     SI,DS:[BX].TEditor.Buffer.Word[0]
        RETN
@@20:   CMP     AL,0DH
        JE      @@30
        CMP     AL,09H
        JNE     @@13
        MOV     AL,' '
@@21:   STOSW
        INC     DX
        TEST    DL,7
        JNE     @@21
        JMP     @@14
@@30:   POP     CX
@@31:   MOV     AL,' '
        MOV     CX,Width
        SUB     CX,DX
        JBE     @@32
        REP     STOSW
@@32:   POP     DS


end; {TEditor.FormatLine}



{ -------------------------------------------------------------------------- }



function TEditor.GetMousePtr (Mouse : Objects.TPoint) : Word;

begin

  MakeLocal (Mouse, Mouse);
  Mouse.X := Max (0, Min (Mouse.X, Size.X - 1));
  Mouse.Y := Max (0, Min (Mouse.Y, Size.Y - 1));

  GetMousePtr := CharPtr (LineMove (DrawPtr, Mouse.Y + Delta.Y - DrawLine),
                          Mouse.X + Delta.X);


end; { TEditor.GetMousePtr }



{ -------------------------------------------------------------------------- }



function TEditor.GetPalette : Views.PPalette;

CONST

  P : String[Length (CEditor)] = CEditor;

begin

  GetPalette := @P;


end; { TEditor.GetPalette }



{ -------------------------------------------------------------------------- }



procedure TEditor.HandleEvent (var Event : Drivers.TEvent);

VAR

  ShiftState   : Byte absolute $40:$17;
  CenterCursor : Boolean;
  SelectMode   : Byte;
  I            : Integer;
  NewPtr       : Word;
  D            : Objects.TPoint;
  Mouse        : Objects.TPoint;



  { ------------------------------------------------------------------------ }



  { SCRLBG - Start }

  { procedure CheckScrollBar (P : PScrollBar; var D : Integer); }
  function CheckScrollBar (P : PScrollBar; var D : Integer) : Boolean;

  { SCRLBG - Stop. } { Changed froma procedure to a function. }

  begin

    { SCRLBG - Start. }

    CheckScrollBar := FALSE;

    { SCRLBG - Stop. } { Set function return to default to FALSE. }

    if (Event.InfoPtr = P) and (P^.Value <> D) then
    begin
      D := P^.Value;
      Update (ufView);

      { SCRLBG - Start. }

      CheckScrollBar := TRUE;

      { SCRLBG - Stop. } { Set function return to TRUE. }

    end;


  end; {CheckScrollBar}



  { ------------------------------------------------------------------------ }



begin

  Inherited HandleEvent (Event);
  ConvertEvent (Event);
  CenterCursor := not CursorVisible;
  SelectMode := 0;

  if Selecting or (ShiftState and $03 <> 0) then
    SelectMode := smExtend;

  case Event.What of

    Drivers.evMouseDown:

      begin
        if Event.Double then
          SelectMode := SelectMode or smDouble;

        repeat
          Lock;

          if Event.What = evMouseAuto then
          begin
            MakeLocal (Event.Where, Mouse);
            D := Delta;
            if Mouse.X < 0 then
              Dec (D.X);
            if Mouse.X >= Size.X then
              Inc (D.X);
            if Mouse.Y < 0 then
              Dec (D.Y);
            if Mouse.Y >= Size.Y then
              Inc (D.Y);
            ScrollTo (D.X, D.Y);
          end;

          SetCurPtr (GetMousePtr (Event.Where), SelectMode);
          SelectMode := SelectMode or smExtend;
          Unlock;

        until not MouseEvent (Event, evMouseMove + evMouseAuto);

      end; { Drivers.evMouseDown }

    Drivers.evKeyDown:

      case Event.CharCode of

        #32..#255:

          begin
            Lock;

            if Overwrite and not HasSelection then
              if CurPtr <> LineEnd (CurPtr) then
                SelEnd := NextChar (CurPtr);

            InsertText (@Event.CharCode, 1, False);

            { WRAP - Start. }

            if Word_Wrap then
              Check_For_Word_Wrap (SelectMode, CenterCursor);

            { WRAP - Stop. } { Added code to check for wordwrap. }

            TrackCursor (CenterCursor);
            Unlock;

          end;

      else

        Exit;

      end; { Drivers.evKeyDown }

    Drivers.evCommand:

      case Event.Command of

        cmFind        : Find;
        cmReplace     : Replace;
        cmSearchAgain : DoSearchReplace;

      else

        begin

          Lock;

          case Event.Command of

            cmCut         : ClipCut;
            cmCopy        : ClipCopy;
            cmPaste       : ClipPaste;
            cmUndo        : Undo;
            cmClear       : DeleteSelect;
            cmCharLeft    : SetCurPtr (PrevChar  (CurPtr), SelectMode);
            cmCharRight   : SetCurPtr (NextChar  (CurPtr), SelectMode);
            cmWordLeft    : SetCurPtr (PrevWord  (CurPtr), SelectMode);
            cmWordRight   : SetCurPtr (NextWord  (CurPtr), SelectMode);
            cmLineStart   : SetCurPtr (LineStart (CurPtr), SelectMode);
            cmLineEnd     : SetCurPtr (LineEnd   (CurPtr), SelectMode);
            cmLineUp      : SetCurPtr (LineMove  (CurPtr, -1), SelectMode);
            cmLineDown    : SetCurPtr (LineMove  (CurPtr, 1),  SelectMode);
            cmPageUp      : SetCurPtr (LineMove  (CurPtr, - (Size.Y - 1)), SelectMode);
            cmPageDown    : SetCurPtr (LineMove  (CurPtr, Size.Y - 1), SelectMode);
            cmTextStart   : SetCurPtr (0, SelectMode);
            cmTextEnd     : SetCurPtr (BufLen, SelectMode);

            { WRAP - Start. }

            cmNewLine     : NewLine (SelectMode);

            { WRAP - Stop. } { Add new parameter to call. }

            cmBackSpace   : DeleteRange (PrevChar (CurPtr), CurPtr, True);
            cmDelChar     : DeleteRange (CurPtr, NextChar (CurPtr), True);
            cmDelWord     : DeleteRange (CurPtr, NextWord (CurPtr), False);
            cmDelStart    : DeleteRange (LineStart (CurPtr), CurPtr, False);
            cmDelEnd      : DeleteRange (CurPtr, LineEnd (CurPtr), False);
            cmDelLine     : DeleteRange (LineStart (CurPtr), NextLine (CurPtr), False);
            cmInsMode     : ToggleInsMode;
            cmStartSelect : StartSelect;
            cmHideSelect  : HideSelect;

            { STATS - Start. }

            cmIndentMode  : begin
                              AutoIndent := not AutoIndent;
                              Update (ufStats);
                            end; { Added provision to update TIndicator if ^QI pressed. }

            { STATS - Stop. }

            { CENTER - Start. }
            { HOMEND - Start. }
            { INSLIN - Start. }
            { JLINE  - Start. }
            { MARK   - Start. }
            { PRETAB - Start. }
            { REFDOC - Start. }
            { REFORM - Start. }
            { RMSET  - Start. }
            { SCRLDN - Start. }
            { SCRLUP - Start. }
            { SELWRD - Start. }
            { WRAP   - Start. }

            cmCenterText  : Center_Text (SelectMode);
            cmEndPage     : SetCurPtr (LineMove  (CurPtr, Delta.Y - CurPos.Y + Size.Y - 1), SelectMode);
            cmHomePage    : SetCurPtr (LineMove  (CurPtr, -(CurPos.Y - Delta.Y)), SelectMode);
            cmInsertLine  : Insert_Line (SelectMode);
            cmJumpLine    : Jump_To_Line (SelectMode);
            cmReformDoc   : Reformat_Document (SelectMode, CenterCursor);
            cmReformPara  : Reformat_Paragraph (SelectMode, CenterCursor);
            cmRightMargin : Set_Right_Margin;
            cmScrollDown  : Scroll_Down;
            cmScrollUp    : Scroll_Up;
            cmSelectWord  : Select_Word;
            cmSetTabs     : Set_Tabs;
            cmTabKey      : Tab_Key (SelectMode);

            { STATS  - Start. }

            cmWordWrap    : begin
                              Word_Wrap := not Word_Wrap;
                              Update (ufStats);
                            end; { Added provision to update TIndicator if ^OW pressed. }

            { STATS  - Stop. }

            cmSetMark0    : Set_Place_Marker (10);
            cmSetMark1    : Set_Place_Marker  (1);
            cmSetMark2    : Set_Place_Marker  (2);
            cmSetMark3    : Set_Place_Marker  (3);
            cmSetMark4    : Set_Place_Marker  (4);
            cmSetMark5    : Set_Place_Marker  (5);
            cmSetMark6    : Set_Place_Marker  (6);
            cmSetMark7    : Set_Place_Marker  (7);
            cmSetMark8    : Set_Place_Marker  (8);
            cmSetMark9    : Set_Place_Marker  (9);

            cmJumpMark0   : Jump_Place_Marker (10, SelectMode);
            cmJumpMark1   : Jump_Place_Marker  (1, SelectMode);
            cmJumpMark2   : Jump_Place_Marker  (2, SelectMode);
            cmJumpMark3   : Jump_Place_Marker  (3, SelectMode);
            cmJumpMark4   : Jump_Place_Marker  (4, SelectMode);
            cmJumpMark5   : Jump_Place_Marker  (5, SelectMode);
            cmJumpMark6   : Jump_Place_Marker  (6, SelectMode);
            cmJumpMark7   : Jump_Place_Marker  (7, SelectMode);
            cmJumpMark8   : Jump_Place_Marker  (8, SelectMode);
            cmJumpMark9   : Jump_Place_Marker  (9, SelectMode);

            { WRAP   - Stop. } { Added cmWordWrap event.                  }
            { SELWRD - Stop. } { Added cmSelectWord event.                }
            { SCRLUP - Stop. } { Added cmScrollUp event.                  }
            { SCRLDN - Stop. } { Added cmScrollDown event.                }
            { RMSET  - Stop. } { Added cmRightMargin event.               }
            { REFORM - Stop. } { Added cmReformPara event.                }
            { REFDOC - Stop. } { Added cmReformDoc event.                 }
            { PRETAB - Stop. } { Added cmTabKey event.                    }
            { MARK   - Stop. } { Added cmSetMark# and cmJumpMark# events. }
            { JLINE  - Stop. } { Added cmJumpLine event.                  }
            { INSLIN - Stop. } { Added cmInsertLine event.                }
            { HOMEND - Stop. } { Added cmHomePage and cmEndPage events.   }
            { CENTER - Stop. { { Added cmCenterText event.                }

          else

            Unlock;
            Exit;

          end; { Event.Command (Inner) }

          TrackCursor (CenterCursor);

          { WRAP - Start. }

          { ------------------------------------------------------------ }
          {                                                              }
          { If the user presses any key except cmNewline or cmBackspace  }
          { we need to check if the file has been modified yet.  There   }
          { can be no spaces at the end of a line, or wordwrap doesn't   }
          { work properly.  We don't want to do this if the file hasn't  }
          { been modified because the user could be bringing in an ASCII }
          { file from an editor that allows spaces at the EOL.  If we    }
          { took them out in that scenario the "M" would appear on the   }
          { TIndicator line and the user would get upset or confused.    }
          {                                                              }
          { ------------------------------------------------------------ }


          if (Event.Command <> cmNewLine)   and
             (Event.Command <> cmBackSpace) and
             (Event.Command <> cmTabKey)    and
              Modified then
            Remove_EOL_Spaces (SelectMode);

          { WRAP - Stop. } { Added code to check for wordwrap, and to  }
                           { ignore removing EOL spaces for cmNewLine. }

          Unlock;

        end; { Event.Command (Outer) }

      end; { Drivers.evCommand }

    Drivers.evBroadcast:

      case Event.Command of
        cmScrollBarChanged:
          if (Event.InfoPtr = HScrollBar) or
            (Event.InfoPtr = VScrollBar) then
          begin

            { SCRLBG - Start. }
            { Borland fixed the scroll bar problem with the above if}

            CheckScrollBar (HScrollBar, Delta.X);
            CheckScrollBar (VScrollBar, Delta.Y);

          end
          else
            exit;
      else

        Exit;

      end; { Drivers.evBroadcast }

  end;

  ClearEvent (Event);


end; { TEditor.HandleEvent }



{ -------------------------------------------------------------------------- }



function TEditor.HasSelection : Boolean;

begin

  HasSelection := SelStart <> SelEnd;


end; { TEditor.HasSelection }



{ -------------------------------------------------------------------------- }



procedure TEditor.HideSelect;

begin

  Selecting := False;
  SetSelect (CurPtr, CurPtr, False);


end; { TEditor.HideSelect }



{ -------------------------------------------------------------------------- }



procedure TEditor.InitBuffer;

begin

  Buffer := MemAlloc (BufSize);


end; { TEditor.InitBuffer }



{ -------------------------------------------------------------------------- }



function TEditor.InsertBuffer (var P : PEditBuffer;
                               Offset,    Length     : Word;
                               AllowUndo, SelectText : Boolean) : Boolean;

VAR

  SelLen   : Word;
  DelLen   : Word;
  SelLines : Word;
  Lines    : Word;
  NewSize  : Longint;

begin

  InsertBuffer := True;
  Selecting := False;

  SelLen := SelEnd - SelStart;

  if (SelLen = 0) and (Length = 0) then
    Exit;

  DelLen := 0;

  if AllowUndo then
    if CurPtr = SelStart then
      DelLen := SelLen
    else
      if SelLen > InsCount then
        DelLen := SelLen - InsCount;

  NewSize := Longint (BufLen + DelCount - SelLen + DelLen) + Length;

  if NewSize > BufLen + DelCount then
    if (NewSize > $FFF0) or not SetBufSize (NewSize) then
      begin
        EditorDialog (edOutOfMemory, nil);
        InsertBuffer := False;
        SelEnd := SelStart;
        Exit;
      end;

  SelLines := CountLines (Buffer^[BufPtr (SelStart)], SelLen);

  if CurPtr = SelEnd then
  begin

    if AllowUndo then
    begin
      if DelLen > 0 then
        Move (Buffer^[SelStart], Buffer^[CurPtr + GapLen - DelCount - DelLen], DelLen);
      Dec (InsCount, SelLen - DelLen);
    end;

    CurPtr := SelStart;
    Dec (CurPos.Y, SelLines);

  end;

  if Delta.Y > CurPos.Y then
    begin
      Dec (Delta.Y, SelLines);
      if Delta.Y < CurPos.Y then
        Delta.Y := CurPos.Y;
    end;

  if Length > 0 then
    Move (P^[Offset], Buffer^[CurPtr], Length);

  Lines := CountLines (Buffer^[CurPtr], Length);

  Inc (CurPtr, Length);
  Inc (CurPos.Y, Lines);

  DrawLine := CurPos.Y;
  DrawPtr := LineStart (CurPtr);

  CurPos.X := CharPos (DrawPtr, CurPtr);

  if not SelectText then
    SelStart := CurPtr;

  SelEnd := CurPtr;

  Inc (BufLen, Length - SelLen);
  Dec (GapLen, Length - SelLen);

  if AllowUndo then
    begin
      Inc (DelCount, DelLen);
      Inc (InsCount, Length);
    end;

  Inc (Limit.Y, Lines - SelLines);
  Delta.Y := Max (0, Min (Delta.Y, Limit.Y - Size.Y));

  if not IsClipboard then
    Modified := True;

  SetBufSize (BufLen + DelCount);

  if (SelLines = 0) and (Lines = 0) then
    Update (ufLine)
  else
    Update (ufView);


end; { TEditor.InsertBuffer }



{ -------------------------------------------------------------------------- }



function TEditor.InsertFrom (Editor : PEditor) : Boolean;

begin

  InsertFrom := InsertBuffer (Editor^.Buffer,
    Editor^.BufPtr (Editor^.SelStart),
    Editor^.SelEnd - Editor^.SelStart, CanUndo, IsClipboard);


end; { TEditor.InsertFrom }



{ -------------------------------------------------------------------------- }



{ INSLIN - Start. }

procedure TEditor.Insert_Line (Select_Mode : Byte);


  { --------------------------------------------------------------- }
  {                                                                 }
  { This procedure inserts a newline at the current cursor position }
  { if a ^N is pressed.  Unlike cmNewLine, the cursor will return   }
  { to its original position.  If the cursor was at the end of a    }
  { line, and its spaces were removed, the cursor returns to the    }
  { end of the line instead.                                        }
  {                                                                 }
  { --------------------------------------------------------------- }



begin

  NewLine (Select_Mode);
  SetCurPtr (LineEnd (LineMove (CurPtr, -1)), Select_Mode);


end; { TEditor.Insert_Line }

{ INSLIN - Stop. }



{ -------------------------------------------------------------------------- }



function TEditor.InsertText (Text       : Pointer;
                             Length     : Word;
                             SelectText : Boolean) : Boolean;

begin

  { MARK - Start. }

  if assigned(Text) and not Search_Replace then
    Update_Place_Markers (Length, 0, Self.SelStart, Self.SelEnd);

  { MARK - Stop } { This will update Place_Marker ONLY if we are inserting text.}
                  { ClipPaste and deletions of any sort are handled elsewhere.  }

  InsertText := InsertBuffer (PEditBuffer (Text),
                0, Length, CanUndo, SelectText);


end; { TEditor.InsertText }



{ -------------------------------------------------------------------------- }



function TEditor.IsClipboard : Boolean;

begin

  IsClipboard := Clipboard = @Self;


end; { TEditor.IsClipboard }



{ -------------------------------------------------------------------------- }



{ MARK - Start. }

procedure TEditor.Jump_Place_Marker (Element : Byte; Select_Mode : Byte);


  { ---------------------------------------------------------- }
  {                                                            }
  { This procedure jumps to a place marker if ^Q# is pressed.  }
  { We don't go anywhere if Place_Marker[Element] is not zero. }
  {                                                            }
  { ---------------------------------------------------------- }


begin

  if (not IsClipboard) and (Place_Marker[Element] <> 0) then
    SetCurPtr (Place_Marker[Element], Select_Mode);


end; { TEditor.Jump_Place_Marker }

{ MARK - Stop. }



{ -------------------------------------------------------------------------- }



{ JLINE - Start. }

procedure TEditor.Jump_To_Line (Select_Mode : Byte);


  { ------------------------------------------------ }
  {                                                  }
  { This function brings up a dialog box that allows }
  { the user to select a line number to jump to.     }
  {                                                  }
  { ------------------------------------------------ }


VAR

  Code       : Integer;         { Used for Val conversion.      }
  Temp_Value : Integer;         { Holds converted dialog value. }

begin


  if EditorDialog (edJumpToLine, @Line_Number) <> Views.cmCancel then
    begin



      { ---------------------------------------------- }
      {                                                }
      { Convert the Line_Number string to an interger. }
      { Put it into Temp_Value.  If the number is not  }
      { in the range 1..9999 abort.  If the number is  }
      { our current Y position, abort.  Otherwise,     }
      { go to top of document, and jump to the line.   }
      { There are faster methods.  This one's easy.    }
      { Note that CurPos.Y is always 1 less than what  }
      { the TIndicator line says.                      }
      {                                                }
      { ---------------------------------------------- }


      val (Line_Number, Temp_Value, Code);

      if (Temp_Value < 1) or (Temp_Value > 9999) then
        Exit;

      if Temp_Value = CurPos.Y + 1 then
        Exit;

      SetCurPtr (0, Select_Mode);
      SetCurPtr (LineMove (CurPtr, Temp_Value - 1), Select_Mode);

    end;


end; {TEditor.Jump_To_Line}

{ JLINE - Stop. }



{ -------------------------------------------------------------------------- }



function TEditor.LineEnd (P : Word) : Word; assembler;

asm
        PUSH    DS
        LDS     SI,Self
        LES     BX,DS:[SI].TEditor.Buffer
        MOV     DI,P
        MOV     AL,0DH
        CLD
        MOV     CX,DS:[SI].TEditor.CurPtr
        SUB     CX,DI
        JBE     @@1
        ADD     DI,BX
        REPNE   SCASB
        JE      @@2
        MOV     DI,DS:[SI].TEditor.CurPtr
@@1:    MOV     CX,DS:[SI].TEditor.BufLen
        SUB     CX,DI
        JCXZ    @@4
        ADD     BX,DS:[SI].TEditor.GapLen
        ADD     DI,BX
        REPNE   SCASB
        JNE     @@3
@@2:    DEC     DI
@@3:    SUB     DI,BX
@@4:    MOV     AX,DI
        POP     DS


end; { TEditor.LineEnd }



{ -------------------------------------------------------------------------- }



function TEditor.LineMove (P : Word; Count : Integer) : Word;

VAR

  Pos : Integer;
  I   : Word;

begin

  I := P;
  P := LineStart (P);
  Pos := CharPos (P, I);

  while Count <> 0 do
  begin
    I := P;
    if Count < 0 then
      begin
        P := PrevLine (P);
        Inc (Count);
      end
    else
      begin
        P := NextLine (P);
        Dec (Count);
      end;
  end;

  if P <> I then
    P := CharPtr (P, Pos);

  LineMove := P;


end; { TEditor.LineMove }



{ -------------------------------------------------------------------------- }



function TEditor.LineStart (P : Word) : Word; assembler;

asm
        PUSH    DS
        LDS     SI,Self
        LES     BX,DS:[SI].TEditor.Buffer
        MOV     DI,P
        MOV     AL,0DH
        STD
        MOV     CX,DI
        SUB     CX,DS:[SI].TEditor.CurPtr
        JBE     @@1
        ADD     BX,DS:[SI].TEditor.GapLen
        ADD     DI,BX
        DEC     DI
        REPNE   SCASB
        JE      @@2
        SUB     BX,DS:[SI].TEditor.GapLen
        MOV     DI,DS:[SI].TEditor.CurPtr
@@1:    MOV     CX,DI
        JCXZ    @@4
        ADD     DI,BX
        DEC     DI
        REPNE   SCASB
        JNE     @@3
@@2:    INC     DI
        INC     DI
        SUB     DI,BX
        CMP     DI,DS:[SI].TEditor.CurPtr
        JE      @@4
        CMP     DI,DS:[SI].TEditor.BufLen
        JE      @@4
        CMP     ES:[BX+DI].Byte,0AH
        JNE     @@4
        INC     DI
        JMP     @@4
@@3:    XOR     DI,DI
@@4:    MOV     AX,DI
        POP     DS


end; { TEditor.LineStart }



{ -------------------------------------------------------------------------- }



procedure TEditor.Lock;

begin

  Inc (LockCount);


end; { TEditor.Lock }



{ -------------------------------------------------------------------------- }



{ WRAP - Start. }

function TEditor.NewLine (Select_Mode : Byte) : Boolean;



CONST

  CrLf : array[1..2] of Char = #13#10;

VAR

  I : Word;          { Used to track spaces for AutoIndent.                 }
  P : Word;          { Position of Cursor when we arrive and after Newline. }

begin

  P := LineStart (CurPtr);
  I := P;



  { -------------------------------------------------------- }
  {                                                          }
  { The first thing we do is remove any End Of Line spaces.  }
  { Then we check to see how many spaces are on beginning    }
  { of a line.   We need this check to add them after CR/LF  }
  { if AutoIndenting.  Last of all we insert spaces required }
  { for the AutoIndenting, if it was on.                     }
  {                                                          }
  { -------------------------------------------------------- }


  Remove_EOL_Spaces (Select_Mode);

  while (I < CurPtr) and ((Buffer^[I] = ' ') or (Buffer^[I] = #9)) do
     Inc (I);

  if InsertText (@CrLf, 2, False) = FALSE then
    exit;

  if AutoIndent then
    InsertText (@Buffer^[P], I - P, False);



  { ------------------------------------------------ }
  {                                                  }
  { Remember where the CurPtr is at this moment.     }
  { Remember the length of the buffer at the moment. }
  { Go to the previous line and remove EOL spaces.   }
  { Once removed, re-set the cursor to where we were }
  { minus any spaces that might have been removed.   }
  {                                                  }
  { ------------------------------------------------ }


  I := BufLen;
  P := CurPtr;

  SetCurPtr (LineMove (CurPtr, - 1), Select_Mode);
  Remove_EOL_Spaces (Select_Mode);

  if I - BufLen <> 0 then
    SetCurPtr (P - (I - BufLen), Select_Mode)
  else
    SetCurPtr (P, Select_Mode);


end; { TEditor.NewLine }

{ WRAP - Stop. } { Added new parameter and new code to support wordwrap. }



{ -------------------------------------------------------------------------- }



function TEditor.NextChar (P : Word) : Word; assembler;

asm
        PUSH    DS
        LDS     SI,Self
        MOV     DI,P
        CMP     DI,DS:[SI].TEditor.BufLen
        JE      @@2
        INC     DI
        CMP     DI,DS:[SI].TEditor.BufLen
        JE      @@2
        LES     BX,DS:[SI].TEditor.Buffer
        CMP     DI,DS:[SI].TEditor.CurPtr
        JB      @@1
        ADD     BX,DS:[SI].TEditor.GapLen
@@1:    CMP     ES:[BX+DI-1].Word,0A0DH
        JNE     @@2
        INC     DI
@@2:    MOV     AX,DI
        POP     DS


end; { TEditor.NextChar }



{ -------------------------------------------------------------------------- }



function TEditor.NextLine (P : Word) : Word;

begin

  NextLine := NextChar (LineEnd (P));


end; { TEditor.NextLine }



{ -------------------------------------------------------------------------- }



function TEditor.NextWord (P : Word) : Word;


begin

  while (P < BufLen) and (BufChar (P) in WordChars) do
    P := NextChar (P);

  while (P < BufLen) and not (BufChar (P) in WordChars) do
    P := NextChar (P);

  NextWord := P;


end; { TEditor.NextWord }



{ -------------------------------------------------------------------------- }



function TEditor.PrevChar (P : Word) : Word; assembler;

asm
        PUSH    DS
        LDS     SI,Self
        MOV     DI,P
        OR      DI,DI
        JE      @@2
        DEC     DI
        JE      @@2
        LES     BX,DS:[SI].TEditor.Buffer
        CMP     DI,DS:[SI].TEditor.CurPtr
        JB      @@1
        ADD     BX,DS:[SI].TEditor.GapLen
@@1:    CMP     ES:[BX+DI-1].Word,0A0DH
        JNE     @@2
        DEC     DI
@@2:    MOV     AX,DI
        POP     DS


end; { TEditor.PrevChar }



{ -------------------------------------------------------------------------- }



function TEditor.PrevLine (P : Word) : Word;

begin

  PrevLine := LineStart (PrevChar (P));


end; { TEditor.PrevLine }



{ -------------------------------------------------------------------------- }



function TEditor.PrevWord (P : Word) : Word;

begin

  while (P > 0) and not (BufChar (PrevChar (P)) in WordChars) do
    P := PrevChar (P);

  while (P > 0) and (BufChar (PrevChar (P)) in WordChars) do
    P := PrevChar (P);

  PrevWord := P;


end; { TEditor.PrevWord }



{ -------------------------------------------------------------------------- }



{ REFDOC - Start. }

procedure TEditor.Reformat_Document (Select_Mode : Byte; Center_Cursor : Boolean);


  { -------------------------------------------------------------------- }
  {                                                                      }
  { This procedure will do a reformat of the entire document, or just    }
  { from the current line to the end of the document, if ^QU is pressed. }
  { It simply brings up the correct dialog box, and then calls the       }
  { TEditor.Reformat_Paragraph procedure to do the actual reformatting.  }
  {                                                                      }
  { -------------------------------------------------------------------- }


CONST

  efCurrentLine   = $0000;  { Radio button #1 selection for dialog box.  }
  efWholeDocument = $0001;  { Radio button #2 selection for dialog box.  }

VAR

  Reformat_Options : Word;  { Holds the dialog options for reformatting. }


begin



  { ----------------------------------------------------------------- }
  {                                                                   }
  { Check if Word_Wrap is toggled on.  If NOT on, check if programmer }
  { allows reformatting of document and if not show user dialog that  }
  { says reformatting is not permissable.                             }
  {                                                                   }
  { ----------------------------------------------------------------- }


  if not Word_Wrap then
    begin
      if not Allow_Reformat then
        begin
          EditorDialog (edReformatNotAllowed, nil);
          Exit;
        end;
      Word_Wrap := True;
      Update (ufStats);
    end;



  { ------------------------------------------------------------- }
  {                                                               }
  { Default radio button option to 1st one.  Bring up dialog box. }
  {                                                               }
  { ------------------------------------------------------------- }


  Reformat_Options := efCurrentLine;

  if EditorDialog (edReformatDocument, @Reformat_Options) <> Views.cmCancel then
    begin



      { ----------------------------------------------------------- }
      {                                                             }
      { If the option to reformat the whole document was selected   }
      { we need to go back to start of document.  Otherwise we stay }
      { on the current line.  Call Reformat_Paragraph until we get  }
      { to the end of the document to do the reformatting.          }
      {                                                             }
      { ----------------------------------------------------------- }


      if Reformat_Options and efWholeDocument <> 0 then
        SetCurPtr (0, Select_Mode);

      Unlock;

      repeat
        Lock;

        if NOT Reformat_Paragraph (Select_Mode, Center_Cursor) then
          Exit;

        TrackCursor (False);
        Unlock;
      until CurPtr = BufLen;

    end;


end; { TEditor.Reformat_Document }

{ REFDOC - Stop. }



{ -------------------------------------------------------------------------- }



{ REFORM - Start. }

function TEditor.Reformat_Paragraph (Select_Mode   : Byte;
                                     Center_Cursor : Boolean) : Boolean;


  { ------------------------------------------------------------------------- }
  {                                                                           }
  { This procedure will do a reformat of the current paragraph if ^B pressed. }
  { The feature works regardless if wordrap is on or off.  It also supports   }
  { the AutoIndent feature.  Reformat is not possible if the CurPos exceeds   }
  { the Right_Margin.  Right_Margin is where the EOL is considered to be.     }
  {                                                                           }
  { ------------------------------------------------------------------------- }


CONST

  Space : array [1..2] of Char = #32#32;

VAR

  C : Word;  { Position of CurPtr when we come into procedure. }
  E : Word;  { End of a line.                                  }
  S : Word;  { Start of a line.                                }

begin

  Reformat_Paragraph := False;



  { ----------------------------------------------------------------- }
  {                                                                   }
  { Check if Word_Wrap is toggled on.  If NOT on, check if programmer }
  { allows reformatting of paragraph and if not show user dialog that }
  { says reformatting is not permissable.                             }
  {                                                                   }
  { ----------------------------------------------------------------- }


  if not Word_Wrap then
    begin
      if not Allow_Reformat then
        begin
          EditorDialog (edReformatNotAllowed, nil);
          Exit;
        end;
      Word_Wrap := True;
      Update (ufStats);
    end;



  C := CurPtr;
  E := LineEnd (CurPtr);
  S := LineStart (CurPtr);



  { ---------------------------------------------------- }
  {                                                      }
  { Reformat possible only if current line is NOT blank! }
  {                                                      }
  { ---------------------------------------------------- }


  if E <> S then
    begin



      { ------------------------------------------ }
      {                                            }
      { Reformat is NOT possible if the first word }
      { on the line is beyond the Right_Margin.    }
      {                                            }
      { ------------------------------------------ }


      S := LineStart (CurPtr);

      if NextWord (S) - S >= Right_Margin - 1 then
        begin
          EditorDialog (edReformNotPossible, nil);
          Exit;
        end;



      { ----------------------------------------------- }
      {                                                 }
      { First objective is to find the first blank line }
      { after this paragraph so we know when to stop.   }
      { That could be the end of the document.          }
      {                                                 }
      { ----------------------------------------------- }


      Repeat
        SetCurPtr (LineMove (CurPtr, 1), Select_Mode);
        E := LineEnd (CurPtr);
        S := LineStart (CurPtr);
        BlankLine := E;
      until ((CurPtr = BufLen) or (E = S));

      SetCurPtr (C, Select_Mode);

      repeat



        { ------------------------------------------------ }
        {                                                  }
        { Set CurPtr to LineEnd and remove the EOL spaces. }
        { Pull up the next line and remove its EOL space.  }
        { First make sure the next line is not BlankLine!  }
        { Insert spaces as required between the two lines. }
        {                                                  }
        { ------------------------------------------------ }


        SetCurPtr (LineEnd (CurPtr), Select_Mode);
        Remove_EOL_Spaces (Select_Mode);
        if CurPtr <> Blankline - 2 then
          DeleteRange (CurPtr, Nextword (CurPtr), True);
        Remove_EOL_Spaces (Select_Mode);

        case Buffer^[CurPtr-1] of
          '!' : InsertText (@Space, 2, False);
          '.' : InsertText (@Space, 2, False);
          ':' : InsertText (@Space, 2, False);
          '?' : InsertText (@Space, 2, False);
        else
          InsertText (@Space, 1, False);
        end;



        { --------------------------------------------------------- }
        {                                                           }
        { Reset CurPtr to EOL.  While line length is > Right_Margin }
        { go Do_Word_Wrap.  If wordrap failed, exit routine.        }
        {                                                           }
        { --------------------------------------------------------- }


        SetCurPtr (LineEnd (CurPtr), Select_Mode);

        while LineEnd (CurPtr) - LineStart (CurPtr) > Right_Margin do
          if not Do_Word_Wrap (Select_Mode, Center_Cursor) then
              Exit;



        { -------------------------------------------------------- }
        {                                                          }
        { If LineEnd - LineStart > Right_Margin then set CurPtr    }
        { to Right_Margin on current line.  Otherwise we set the   }
        { CurPtr to LineEnd.  This gyration sets up the conditions }
        { to test for time of loop exit.                           }
        {                                                          }
        { -------------------------------------------------------- }


        if LineEnd (CurPtr) - LineStart (CurPtr) > Right_Margin then
          SetCurPtr (LineStart (CurPtr) + Right_Margin, Select_Mode)
        else
          SetCurPtr (LineEnd (CurPtr), Select_Mode);

      until ((CurPtr >= BufLen) or (CurPtr >= BlankLine - 2));

    end;



  { --------------------------------------------------------------------- }
  {                                                                       }
  { If not at the end of the document reset CurPtr to start of next line. }
  { This should be a blank line between paragraphs.                       }
  {                                                                       }
  { --------------------------------------------------------------------- }


  if CurPtr < BufLen then
    SetCurPtr (LineMove (CurPtr, 1), Select_Mode);


  Reformat_Paragraph := True;


end; { TEditor.Reformat_Paragraph }

{ REFORM - Stop. }



{ -------------------------------------------------------------------------- }



{ WRAP - Start. }

procedure TEditor.Remove_EOL_Spaces (Select_Mode : Byte);


  { ----------------------------------------------------------- }
  {                                                             }
  { This procedure tests to see if there are consecutive spaces }
  { at the end of a line (EOL).  If so, we delete all spaces    }
  { after the last non-space character to the end of line.      }
  { We then reset the CurPtr to where we ended up at.           }
  {                                                             }
  { ----------------------------------------------------------- }


VAR

  C : Word;           { Current pointer when we come into procedure. }
  E : Word;           { End of line.                                 }
  P : Word;           { Position of pointer at any given moment.     }
  S : Word;           { Start of a line.                             }

begin

  C := CurPtr;
  E := LineEnd (CurPtr);
  P := E;
  S := LineStart (CurPtr);



  { ------------------------------------------------------ }
  {                                                        }
  { Start at the end of a line and move towards the start. }
  { Find first non-space character in that direction.      }
  {                                                        }
  { ------------------------------------------------------ }


  while (P > S) and (BufChar (PrevChar (P)) = #32) do
    P := PrevChar (P);



  { ---------------------------------------- }
  {                                          }
  { If we found any spaces then delete them. }
  {                                          }
  { ---------------------------------------- }


  if P < E then
    begin

      SetSelect (P, E, True);
      DeleteSelect;

      { MARK - Start. }

      Update_Place_Markers (0, E - P, P, E);

      { MARK - Stop. } { This will update Place_Marker for EOL deletions. }
                       { All other deletions are handled by DeleteRange.  }

    end;



  { --------------------------------------------------- }
  {                                                     }
  { If C, our pointer when we came into this procedure, }
  { is less than the CurPtr then reset CurPtr to C so   }
  { cursor is where we started.  Otherwise, set it to   }
  { the new CurPtr, for we have deleted characters.     }
  {                                                     }
  { --------------------------------------------------- }


  if C < CurPtr then
    SetCurPtr (C, Select_Mode)
  else
    SetCurPtr (CurPtr, Select_Mode);


end; { TEditor.Remove_EOL_Spaces }

{ WRAP - Stop. }



{ -------------------------------------------------------------------------- }



procedure TEditor.Replace;

VAR

  ReplaceRec : TReplaceDialogRec;

begin

  with ReplaceRec do
  begin

    Find := FindStr;
    Replace := ReplaceStr;
    Options := EditorFlags;

    if EditorDialog (edReplace, @ReplaceRec) <> Views.cmCancel then
    begin
      FindStr := Find;
      ReplaceStr := Replace;
      EditorFlags := Options or efDoReplace;
      DoSearchReplace;
    end;
  end;


end; { TEditor.Replace }



{ -------------------------------------------------------------------------- }



{ SCRLDN - Start. }

procedure TEditor.Scroll_Down;


  { -------------------------------------------------------------- }
  {                                                                }
  { This procedure will scroll the screen up, and always keep      }
  { the cursor on the CurPos.Y position, but not necessarily on    }
  { the CurPos.X.  If CurPos.Y scrolls off the screen, the cursor  }
  { will stay in the upper left corner of the screen.  This will   }
  { simulate the same process in the IDE.  The CurPos.X coordinate }
  { only messes up if we are on long lines and we then encounter   }
  { a shorter or blank line beneath the current one as we scroll.  }
  { In that case, it goes to the end of the new line.              }
  {                                                                }
  { -------------------------------------------------------------- }


VAR

  C : Word;           { Position of CurPtr when we enter procedure. }
  P : Word;           { Position of CurPtr at any given time.       }
  W : Objects.TPoint; { CurPos.Y of CurPtr and P ('.X and '.Y).     }

begin



  { ---------------------------------------------------------------------- }
  {                                                                        }
  { Remember current cursor position.  Remember current CurPos.Y position. }
  { Now issue the equivalent of a [Ctrl]-[End] command so the cursor will  }
  { go to the bottom of the current screen.  Reset the cursor to this new  }
  { position and then send FALSE to TrackCursor so we fool it into         }
  { incrementing Delta.Y by only +1.  If we didn't do this it would try    }
  { to center the cursor on the screen by fiddling with Delta.Y.           }
  {                                                                        }
  { ---------------------------------------------------------------------- }


  C := CurPtr;
  W.X := CurPos.Y;

  P := LineMove (CurPtr, Delta.Y - CurPos.Y + Size.Y);

  SetCurPtr (P, 0);

  TrackCursor (False);



  { -------------------------------------------------------------------- }
  {                                                                      }
  { Now remember where the new CurPos.Y is.  See if distance between new }
  { CurPos.Y and old CurPos.Y are greater than the current screen size.  }
  { If they are, we need to move cursor position itself down by one.     }
  { Otherwise, send the cursor back to our original CurPtr.              }
  {                                                                      }
  { -------------------------------------------------------------------- }


  W.Y := CurPos.Y;

  if W.Y - W.X > Size.Y - 1 then
    SetCurPtr (LineMove (C, 1), 0)
  else
    SetCurPtr (C, 0);


end; { TEditor.Scroll_Down }

{ SCRLDN - Stop. } { Added this complete procedure to simulate IDE function. }



{ -------------------------------------------------------------------------- }



{ SCRLUP - Start. }

procedure TEditor.Scroll_Up;


  { -------------------------------------------------------------- }
  {                                                                }
  { This procedure will scroll the screen down, and always keep    }
  { the cursor on the CurPos.Y position, but not necessarily on    }
  { the CurPos.X.  If CurPos.Y scrolls off the screen, the cursor  }
  { will stay in the bottom left corner of the screen.  This will  }
  { simulate the same process in the IDE.  The CurPos.X coordinate }
  { only messes up if we are on long lines and we then encounter   }
  { a shorter or blank line beneath the current one as we scroll.  }
  { In that case, it goes to the end of the new line.              }
  {                                                                }
  { -------------------------------------------------------------- }


VAR

  C : Word;           { Position of CurPtr when we enter procedure. }
  P : Word;           { Position of CurPtr at any given time.       }
  W : Objects.TPoint; { CurPos.Y of CurPtr and P ('.X and '.Y).     }

begin



  { ---------------------------------------------------------------------- }
  {                                                                        }
  { Remember current cursor position.  Remember current CurPos.Y position. }
  { Now issue the equivalent of a [Ctrl]-[Home] command so the cursor will }
  { go to the top of the current screen.  Reset the cursor to this new     }
  { position and then send FALSE to TrackCursor so we fool it into         }
  { decrementing Delta.Y by only -1.  If we didn't do this it would try    }
  { to center the cursor on the screen by fiddling with Delta.Y.           }
  {                                                                        }
  { ---------------------------------------------------------------------- }


  C := CurPtr;
  W.Y := CurPos.Y;

  P := LineMove (CurPtr, -(CurPos.Y - Delta.Y + 1));

  SetCurPtr (P, 0);

  TrackCursor (False);



  { -------------------------------------------------------------------- }
  {                                                                      }
  { Now remember where the new CurPos.Y is.  See if distance between new }
  { CurPos.Y and old CurPos.Y are greater than the current screen size.  }
  { If they are, we need to move the cursor position itself up by one.   }
  { Otherwise, send the cursor back to our original CurPtr.              }
  {                                                                      }
  { -------------------------------------------------------------------- }


  W.X := CurPos.Y;

  if W.Y - W.X > Size.Y - 1 then
    SetCurPtr (LineMove (C, -1), 0)
  else
    SetCurPtr (C, 0);


end; { TEditor.Scroll_Up }

{ SCRLDN - Stop. } { Added this complete procedure to simulate IDE function. }



{ -------------------------------------------------------------------------- }



procedure TEditor.ScrollTo (X, Y : Integer);

begin

  X := Max (0, Min (X, Limit.X - Size.X));
  Y := Max (0, Min (Y, Limit.Y - Size.Y));

  if (X <> Delta.X) or (Y <> Delta.Y) then
  begin
    Delta.X := X;
    Delta.Y := Y;
    Update (ufView);
  end;


end; { TEditor.ScrollTo }



{ -------------------------------------------------------------------------- }



function TEditor.Search (const FindStr : String; Opts : Word) : Boolean;

VAR

  I   : Word;
  Pos : Word;

begin

  Search := False;
  Pos := CurPtr;

  repeat

    if Opts and efCaseSensitive <> 0 then
      I := Scan (Buffer^[BufPtr (Pos)], BufLen - Pos, FindStr)
    else
      I := IScan (Buffer^[BufPtr (Pos)], BufLen - Pos, FindStr);

    if (I <> sfSearchFailed) then
    begin

      Inc (I, Pos);

      if (Opts and efWholeWordsOnly = 0) or
         not (((I <> 0) and (BufChar (I - 1) in WordChars)) or
              ((I + Length (FindStr) <> BufLen) and
               (BufChar (I + Length (FindStr)) in WordChars))) then
        begin
          Lock;
          SetSelect (I, I + Length (FindStr), False);
          TrackCursor (not CursorVisible);
          Unlock;
          Search := True;
          Exit;
        end
      else
        Pos := I + 1;

    end;

  until I = sfSearchFailed;


end; { TEditor.Search }



{ -------------------------------------------------------------------------- }



{ SELWRD - Start. }

procedure TEditor.Select_Word;


  { ------------------------------------------------------------------ }
  {                                                                    }
  { This procedure will select the a word to put into the clipboard.   }
  { I've added it just to maintain compatibility with the IDE editor.  }
  { Note that selection starts at the current cursor position and ends }
  { when a space or the end of line is encountered.                    }
  {                                                                    }
  { ------------------------------------------------------------------ }


VAR

  E : Word;           { End of the current line.                           }
  Select_Mode : Byte; { Allows us to turn select mode on inside procedure. }

begin

  E := LineEnd (CurPtr);



  { ----------------------------------------------------------- }
  {                                                             }
  { If the cursor is on a space or at the end of a line, abort. }
  { Stupid action on users part for you can't select blanks!    }
  {                                                             }
  { ----------------------------------------------------------- }


  if (BufChar (CurPtr) = #32) or (CurPtr = E) then
    Exit;



  { ------------------------------------------------------------ }
  {                                                              }
  { Turn on select mode and tell editor to start selecting text. }
  { As long as we have a character > a space (this is done to    }
  { exclude CR/LF pairs at end of a line) and we are NOT at the  }
  { end of a line, set the CurPtr to the next character.         }
  { Once we find a space or CR/LF, selection is done and we      }
  { automatically put the selected word into the Clipboard.      }
  {                                                              }
  { ------------------------------------------------------------ }


  Select_Mode := smExtend;
  StartSelect;

  while (BufChar (NextChar (CurPtr)) > #32) and (CurPtr < E) do
    SetCurPtr (NextChar (CurPtr), Select_Mode);

  SetCurPtr (NextChar (CurPtr), Select_Mode);
  ClipCopy;


end; {TEditor.Select_Word }

{SELWRD - Stop. }



{ -------------------------------------------------------------------------- }



procedure TEditor.SetBufLen (Length : Word);


begin

  BufLen := Length;
  GapLen := BufSize - Length;

  SelStart := 0;
  SelEnd := 0;

  CurPtr := 0;

  Longint (CurPos) := 0;
  Longint (Delta) := 0;

  Limit.X := MaxLineLength;
  Limit.Y := CountLines (Buffer^[GapLen], BufLen) + 1;

  DrawLine := 0;
  DrawPtr := 0;

  DelCount := 0;
  InsCount := 0;

  Modified := False;
  Update (ufView);


end; { TEditor.SetBufLen }



{ -------------------------------------------------------------------------- }



function TEditor.SetBufSize (NewSize : Word) : Boolean;

begin

  SetBufSize := NewSize <= BufSize;


end; { TEditor.SetBufSize }



{ -------------------------------------------------------------------------- }



procedure TEditor.SetCmdState (Command : Word; Enable : Boolean);

VAR

  S : Views.TCommandSet;

begin

  S := [Command];

  if Enable and (State and sfActive <> 0) then
    EnableCommands (S)
  else
    DisableCommands (S);


end; { TEditor.SetCmdState }



{ -------------------------------------------------------------------------- }



procedure TEditor.SetCurPtr (P : Word; SelectMode : Byte);

VAR

  Anchor : Word;

begin

  if SelectMode and smExtend = 0 then
    Anchor := P
  else
    if CurPtr = SelStart then
      Anchor := SelEnd
    else
      Anchor := SelStart;

  if P < Anchor then
    begin

      if SelectMode and smDouble <> 0 then
      begin
        P := PrevLine (NextLine (P));
        Anchor := NextLine (PrevLine (Anchor));
      end;

      SetSelect (P, Anchor, True);

    end
  else
    begin

      if SelectMode and smDouble <> 0 then
      begin
        P := NextLine (P);
        Anchor := PrevLine (NextLine (Anchor));
      end;

      SetSelect (Anchor, P, False);

    end;


end; { TEditor.SetCurPtr }



{ -------------------------------------------------------------------------- }



{ MARK - Start. }

procedure TEditor.Set_Place_Marker (Element : Byte);


  { -------------------------------------------------------------------- }
  {                                                                      }
  { This procedure sets a place marker for the CurPtr if ^K# is pressed. }
  {                                                                      }
  { -------------------------------------------------------------------- }


begin

  if not IsClipboard then
    Place_Marker[Element] := CurPtr;


end; { TEditor.Set_Place_Marker }

{ MARK - Stop. }



{ -------------------------------------------------------------------------- }



{ RMSET - Start. }

procedure TEditor.Set_Right_Margin;


  { ----------------------------------------- }
  {                                           }
  { This procedure will bring up a dialog box }
  { that allows the user to set Right_Margin. }
  { Values must be < MaxLineLength and > 9.   }
  {                                           }
  { ----------------------------------------- }


VAR

  Code        : Integer;          { Used for Val conversion.      }
  Margin_Data : TRightMarginRec;  { Holds dialog results.         }
  Temp_Value  : Integer;          { Holds converted dialog value. }

begin

  with Margin_Data do
    begin

      Str (Right_Margin, Margin_Position);

      if EditorDialog (edRightMargin, @Margin_Position) <> Views.cmCancel then
        begin
          val (Margin_Position, Temp_Value, Code);
          if (Temp_Value <= MaxLineLength) and (Temp_Value > 9) then
            Right_Margin := Temp_Value;
        end;

    end;


end; { TEditor.Set_Right_Margin }


{ RMSET - Stop. }



{ -------------------------------------------------------------------------- }



procedure TEditor.SetSelect (NewStart, NewEnd : Word; CurStart : Boolean);

VAR

  Flags : Byte;
  P     : Word;
  L     : Word;

begin

  if CurStart then
    P := NewStart
  else
    P := NewEnd;

  Flags := ufUpdate;

  if (NewStart <> SelStart) or (NewEnd <> SelEnd) then
    if (NewStart <> NewEnd) or (SelStart <> SelEnd) then
      Flags := ufView;

  if P <> CurPtr then
  begin

    if P > CurPtr then
      begin
        L := P - CurPtr;
        Move (Buffer^[CurPtr + GapLen], Buffer^[CurPtr], L);
        Inc (CurPos.Y, CountLines (Buffer^[CurPtr], L));
        CurPtr := P;
      end
    else
      begin
        L := CurPtr - P;
        CurPtr := P;
        Dec (CurPos.Y, CountLines (Buffer^[CurPtr], L));
        Move (Buffer^[CurPtr], Buffer^[CurPtr + GapLen], L);
      end;

    DrawLine := CurPos.Y;
    DrawPtr := LineStart (P);

    CurPos.X := CharPos (DrawPtr, P);

    DelCount := 0;
    InsCount := 0;

    SetBufSize (BufLen);

  end;

  SelStart := NewStart;
  SelEnd := NewEnd;

  Update (Flags);


end; { TEditor.Select }



{ -------------------------------------------------------------------------- }



procedure TEditor.SetState (AState : Word; Enable : Boolean);

begin

  Inherited SetState (AState, Enable);

  case AState of

    Views.sfActive: begin
                      if assigned(HScrollBar) then
                        HScrollBar^.SetState (Views.sfVisible, Enable);
                      if assigned(VScrollBar) then
                        VScrollBar^.SetState (Views.sfVisible, Enable);
                      if assigned(Indicator) then
                        Indicator^.SetState (Views.sfVisible, Enable);
                      UpdateCommands;
                    end;

    Views.sfExposed: if Enable then Unlock;

  end;


end; { TEditor.SetState }



{ -------------------------------------------------------------------------- }



{ PRETAB - Start. }

procedure TEditor.Set_Tabs;



  { ----------------------------------------- }
  {                                           }
  { This procedure will bring up a dialog box }
  { that allows the user to set tab stops.    }
  {                                           }
  { ----------------------------------------- }


VAR

  Index    : Integer;      { Index into string array. }
  Tab_Data : TTabStopRec;  { Holds dialog results.    }

begin

  with Tab_Data do
    begin



      { --------------------------------------------- }
      {                                               }
      { Assign current Tab_Settings to Tab_String.    }
      { Bring up the tab dialog so user can set tabs. }
      {                                               }
      { --------------------------------------------- }


      Tab_String := Copy (Tab_Settings, 1, Tab_Stop_Length);

      if EditorDialog (edSetTabStops, @Tab_String) <> Views.cmCancel then
        begin



          { --------------------------------------------------------------- }
          {                                                                 }
          { If Tab_String comes back as empty then set Tab_Settings to nil. }
          { Otherwise, find the last character in Tab_String that is not    }
          { a space and copy Tab_String into Tab_Settings up to that spot.  }
          {                                                                 }
          { --------------------------------------------------------------- }


          if Length (Tab_String) = 0 then
            begin
              FillChar (Tab_Settings, SizeOf (Tab_Settings), #0);
              Tab_Settings[0] := #0;
              Exit;
            end
          else
            begin
              Index := Length (Tab_String);
              while Tab_String[Index] <= #32 do
                Dec (Index);
              Tab_Settings := Copy (Tab_String, 1, Index);
            end;

        end;

  end;


end; { TEditor.Set_Tabs }

{ PRETAB - Stop. }



{ -------------------------------------------------------------------------- }



procedure TEditor.StartSelect;

begin

  HideSelect;
  Selecting := True;


end; { TEditor.StartSelect }



{ -------------------------------------------------------------------------- }



procedure TEditor.Store (var S : Objects.TStream);

begin

  Inherited Store (S);

  PutPeerViewPtr (S, HScrollBar);
  PutPeerViewPtr (S, VScrollBar);
  PutPeerViewPtr (S, Indicator);
  S.Write (BufSize, SizeOf (Word));


  { STORE - Start. }

  S.Write (Canundo, SizeOf (Boolean));

  { STORE - Stop. } {This item caused load/store bug. }


  { STATS  - Start. }
  { JLINE  - Start. }
  { MARK   - Start. }
  { RMSET  - Start. }
  { PRETAB - Start. }
  { WRAP   - Start. }

  S.Write (AutoIndent,   SizeOf (AutoIndent));
  S.Write (Line_Number,  SizeOf (Line_Number));
  S.Write (Place_Marker, SizeOf (Place_Marker));
  S.Write (Right_Margin, SizeOf (Right_Margin));
  S.Write (Tab_Settings, SizeOf (Tab_Settings));
  S.Write (Word_Wrap,    SizeOf (Word_Wrap));

  { WRAP   - Stop. }
  { PRETAB - Stop. }
  { RMSET  - Stop. }
  { MARK   - Stop. }
  { JLINE  - Stop. }
  { STATS  - Stop. } { Added these to allow load/store operations. }


end; { Editor.Store }



{ -------------------------------------------------------------------------- }



{ PRETAB - Start. }


procedure TEditor.Tab_Key (Select_Mode : Byte);


  { ------------------------------------------------------------------ }
  {                                                                    }
  { This function determines if we are in overstrike or insert mode,   }
  { and then moves the cursor if overstrike, or adds spaces if insert. }
  {                                                                    }
  { ------------------------------------------------------------------ }


VAR

  E        : Word;                   { End of current line.                }
  Index    : Integer;                { Loop counter.                       }
  Position : Integer;                { CurPos.X position.                  }
  S        : Word;                   { Start of current line.              }
  Spaces   : array [1..80] of Char;  { Array to hold spaces for insertion. }


begin

  E := LineEnd (CurPtr);
  S := LineStart (CurPtr);



  { -------------------------------------------- }
  {                                              }
  { Find the current horizontal cursor position. }
  { Now loop through the Tab_Settings string and }
  { find the next available tab stop.            }
  {                                              }
  { -------------------------------------------- }


  Position := CurPos.X + 1;

  repeat
    Inc (Position);
  until (Tab_Settings[Position] <> #32) or (Position >= Ord (Tab_Settings[0]));

  E := CurPos.X;
  Index := 1;



  { ---------------------------------------------------- }
  {                                                      }
  { Now we enter a loop to go to the next tab position.  }
  { If we are in overwrite mode, we just move the cursor }
  { through the text to the next tab stop.  If we are in }
  { insert mode, we add spaces to the Spaces array for   }
  { the number of times we loop.                         }
  {                                                      }
  { ---------------------------------------------------- }


  while Index < Position - E do
    begin
      if Overwrite then
        begin
          if (Position > LineEnd (CurPtr) - LineStart (CurPtr))
              or (Position > Ord (Tab_Settings[0])) then
            begin
              SetCurPtr (LineStart (LineMove (CurPtr, 1)), Select_Mode);
              Exit;
            end
          else
            if CurPtr < BufLen then
              SetCurPtr (NextChar (CurPtr), Select_Mode);
        end
      else
        begin
          if (Position > Right_Margin) or (Position > Ord (Tab_Settings[0])) then
            begin
              SetCurPtr (LineStart (LineMove (CurPtr, 1)), Select_Mode);
              Exit;
            end
          else
            Spaces[Index] := #32;
        end;

      Inc (Index);

  end;



  { -------------------------------------------------------------------- }
  {                                                                      }
  { If we are insert mode, we insert spaces to the next tab stop.        }
  { When we're all done, the cursor will be sitting on the new tab stop. }
  {                                                                      }
  { -------------------------------------------------------------------- }


  if not OverWrite then
    InsertText (@Spaces, Index - 1, False);


end; { TEditor.Tab_Key }

{ PRETAB - Stop. }



{ -------------------------------------------------------------------------- }



procedure TEditor.ToggleInsMode;

begin

  Overwrite := not Overwrite;
  SetState (sfCursorIns, not GetState (sfCursorIns));


end; { TEditor.ToggleInsMode }



{ -------------------------------------------------------------------------- }



procedure TEditor.TrackCursor (Center : Boolean);

begin

  if Center then
    ScrollTo (CurPos.X - Size.X + 1, CurPos.Y - Size.Y div 2)
  else
    ScrollTo (Max (CurPos.X - Size.X + 1, Min (Delta.X, CurPos.X)),
              Max (CurPos.Y - Size.Y + 1, Min (Delta.Y, CurPos.Y)));


end; { TEditor.TrackCursor }



{ -------------------------------------------------------------------------- }



procedure TEditor.Undo;

VAR

  Length : Word;

begin

  if (DelCount <> 0) or (InsCount <> 0) then
  begin

    { MARK - Start. }

    Update_Place_Markers (DelCount, 0, CurPtr, CurPtr + DelCount);

    { MARK - Stop. } { Update Place_Marker array if we undelete text. }

    SelStart := CurPtr - InsCount;
    SelEnd := CurPtr;
    Length := DelCount;
    DelCount := 0;
    InsCount := 0;
    InsertBuffer (Buffer, CurPtr + GapLen - Length, Length, False, True);

  end;


end; { TEditor.Undo }



{ -------------------------------------------------------------------------- }



procedure TEditor.Unlock;

begin

  if LockCount > 0 then
  begin
    Dec (LockCount);
    if LockCount = 0 then
      DoUpdate;
  end;


end; { TEditor.Unlock }



{ -------------------------------------------------------------------------- }



procedure TEditor.Update (AFlags : Byte);

begin

  UpdateFlags := UpdateFlags or AFlags;

  if LockCount = 0 then
    DoUpdate;


end; { TEditor.Update }



{ -------------------------------------------------------------------------- }



procedure TEditor.UpdateCommands;

begin

  SetCmdState (cmUndo, (DelCount <> 0) or (InsCount <> 0));

  if not IsClipboard then
    begin
      SetCmdState (cmCut, HasSelection);
      SetCmdState (cmCopy, HasSelection);
      SetCmdState (cmPaste, assigned(Clipboard) and (Clipboard^.HasSelection));
    end;

  SetCmdState (cmClear, HasSelection);
  SetCmdState (cmFind, True);
  SetCmdState (cmReplace, True);
  SetCmdState (cmSearchAgain, True);


end; { TEditor.UpdateCommands }



{ -------------------------------------------------------------------------- }



{ MARK - Start. }

procedure TEditor.Update_Place_Markers (AddCount : Word; KillCount : Word;
                                        StartPtr : Word;    EndPtr : Word);


  { -------------------------------------------------------- }
  {                                                          }
  { This procedure updates the position of the place markers }
  { as the user inserts and deletes text in the document.    }
  {                                                          }
  { -------------------------------------------------------- }


VAR

  Element : Byte;     { Place_Marker array element to traverse array with. }


begin

  for Element := 1 to 10 do
    begin
      if AddCount > 0 then
        begin
          if (Place_Marker[Element] >= Curptr)
              and (Place_Marker[Element] <> 0) then
            Place_Marker[Element] := Place_Marker[Element] + AddCount;
        end
      else
        begin
          if Place_Marker[Element] >= StartPtr then
            begin
              if (Place_Marker[Element] >= StartPtr) and
                 (Place_Marker[Element] < EndPtr) then
                Place_marker[Element] := 0
              else
                begin
                  if integer (Place_Marker[Element]) - integer (KillCount) > 0 then
                    Place_Marker[Element] := Place_Marker[Element] - KillCount
                  else
                    Place_Marker[Element] := 0;
                end;
            end;
        end;
    end;

  { WRAP - Start. }

  if AddCount > 0 then
    BlankLine := BlankLine + AddCount
  else
    begin
      if integer (BlankLine) - Integer (KillCount) > 0 then
        BlankLine := BlankLine - KillCount
      else
        BlankLine := 0;
    end;

  { WRAP - Stop. }


end; { TEditor.Update_Place_Markers }

{MARK - Stop. }



{ -------------------------------------------------------------------------- }



function TEditor.Valid (Command : Word) : Boolean;

begin

  Valid := IsValid;


end; { TEditor.Valid }



{ -------------------------------------------------------------------------- }



         { ----------------------------------------------- }
         {                                                 }
         { The following methods are for the TMEMO object. }
         {                                                 }
         { ----------------------------------------------- }



constructor TMemo.Load (var S : Objects.TStream);

VAR

  Length : Word;

begin

  Inherited Load (S);
  S.Read (Length, SizeOf (Word));

  if IsValid then
    begin
      S.Read (Buffer^[BufSize - Length], Length);
      SetBufLen (Length);
    end
  else
    S.Seek (S.GetPos + Length);


end; { TMemo.Load }



{ -------------------------------------------------------------------------- }



function TMemo.DataSize : Word;

begin

  DataSize := BufSize + SizeOf (Word);


end; { TMemo.DataSize }



{ -------------------------------------------------------------------------- }



procedure TMemo.GetData (var Rec);

VAR

  Data : TMemoData absolute Rec;

begin

  Data.Length := BufLen;
  Move (Buffer^, Data.Buffer, CurPtr);
  Move (Buffer^[CurPtr + GapLen], Data.Buffer[CurPtr], BufLen - CurPtr);
  FillChar (Data.Buffer[BufLen], BufSize - BufLen, 0);


end; { TMemo.GetData }



{ -------------------------------------------------------------------------- }



function TMemo.GetPalette : Views.PPalette;

CONST

  P : String[Length (CMemo)] = CMemo;

begin

  GetPalette := @P;


end; { TMemo.GetPalette }



{ -------------------------------------------------------------------------- }



procedure TMemo.HandleEvent (var Event : Drivers.TEvent);

begin

  if (Event.What <> Drivers.evKeyDown) or (Event.KeyCode <> Drivers.kbTab) then
    Inherited HandleEvent (Event);


end; { TMemo.HandleEvent }



{ -------------------------------------------------------------------------- }



procedure TMemo.SetData (var Rec);

VAR

  Data : TMemoData absolute Rec;

begin

  Move (Data.Buffer, Buffer^[BufSize - Data.Length], Data.Length);
  SetBufLen (Data.Length);


end; { TMemo.SetData }



{ -------------------------------------------------------------------------- }



procedure TMemo.Store (var S : Objects.TStream);

begin

  Inherited Store (S);
  S.Write (BufLen, SizeOf (Word));
  S.Write (Buffer^, CurPtr);
  S.Write (Buffer^[CurPtr + GapLen], BufLen - CurPtr);


end; { TMemo.Store }



{ -------------------------------------------------------------------------- }



         { ----------------------------------------------------- }
         {                                                       }
         { The following methods are for the TFILEEDITOR object. }
         {                                                       }
         { ----------------------------------------------------- }



constructor TFileEditor.Init (var Bounds : TRect;
                              AHScrollBar, AVScrollBar : PScrollBar;
                              AIndicator : PIndicator;
                              AFileName  : FNameStr);

begin

  Inherited Init (Bounds, AHScrollBar, AVScrollBar, AIndicator, 0);

  if AFileName <> '' then
  begin

    FileName := FExpand (AFileName);
    if IsValid then
      IsValid := LoadFile;

  end;


end; { TFileEditor.Init }



{ -------------------------------------------------------------------------- }



constructor TFileEditor.Load (var S : Objects.TStream);

VAR

  SStart : Word;
  SEnd   : Word;
  Curs   : Word;

begin

  Inherited Load (S);
  BufSize := 0;

  S.Read (FileName[0], SizeOf (Char));
  S.Read (Filename[1], Length (FileName));

  if IsValid then
    IsValid := LoadFile;

  S.Read (SStart, SizeOf (Word));
  S.Read (SEnd, SizeOf (Word));
  S.Read (Curs, SizeOf (Word));

  if IsValid and (SEnd <= BufLen) then
  begin
    SetSelect (SStart, SEnd, Curs = SStart);
    TrackCursor (True);
  end;


end; { TFileEditor.Load }



{ -------------------------------------------------------------------------- }



procedure TFileEditor.DoneBuffer;

begin

  if assigned(Buffer) then
    DisposeBuffer (Buffer);


end; { TFileEditor.DoneBuffer }



{ -------------------------------------------------------------------------- }



procedure TFileEditor.HandleEvent (var Event : Drivers.TEvent);

begin

  Inherited HandleEvent (Event);

  case Event.What of
    Drivers.evCommand:
      case Event.Command of

        cmSave   : Save;
        cmSaveAs : SaveAs;

        { SAVE - Start. }

        cmSaveDone : if Save then
                       Message (Owner, Drivers.evCommand, Views.cmClose, nil);

        { SAVE - Stop. } { Added code to remove editor if ^KD or ^KX pressed. }

      else
        Exit;
      end;
  else
    Exit;
  end;

  ClearEvent (Event);


end; { TFileEditor.HandleEvent }



{ -------------------------------------------------------------------------- }



procedure TFileEditor.InitBuffer;

begin

  NewBuffer(Pointer(Buffer), $1000);

  { LOAD  - Start. }
  { STORE - Start. }


  { STORE - Stop. }
  { LOAD  - Stop. }


end; { TFileEditor.InitBuffer }



{ -------------------------------------------------------------------------- }



function TFileEditor.LoadFile: Boolean;

VAR

  Length: Word;
  FSize: Longint;
  F: File;

begin

  LoadFile := False;
  Length := 0;
  Assign(F, FileName);
  Reset(F, 1);
  if IOResult <> 0 then EditorDialog(edReadError, @FileName)
  else
  begin
    FSize := FileSize(F);
    if (FSize > $FFF0) or not SetBufSize(Word(FSize)) then
      EditorDialog(edOutOfMemory, nil) else
    begin
      BlockRead(F, Buffer^[BufSize - Word(FSize)], FSize);
      if IOResult <> 0 then EditorDialog(edReadError, @FileName) else
      begin
        LoadFile := True;
        Length := FSize;
      end;
    end;

    Close(F);

  end;

  SetBufLen(Length);

end; { TFileEditor.LoadFile }


{ -------------------------------------------------------------------------- }



function TFileEditor.Save : Boolean;

begin

  if FileName = '' then
    Save := SaveAs
  else
    Save := SaveFile;


end; { TFileEditor.Save }



{ -------------------------------------------------------------------------- }



function TFileEditor.SaveAs : Boolean;

begin

  SaveAs := False;

  if EditorDialog (edSaveAs, @FileName) <> Views.cmCancel then
  begin

    FileName := FExpand (FileName);
    Message (Owner, Drivers.evBroadcast, cmUpdateTitle, nil);
    SaveAs := SaveFile;

    if IsClipboard then
      FileName := '';
  end;


end; { TFileEditor.SaveAs }



{ -------------------------------------------------------------------------- }



function TFileEditor.SaveFile : Boolean;

VAR

  F          : File;
  BackupName : Objects.FNameStr;
  D          : DOS.DirStr;
  N          : DOS.NameStr;
  E          : DOS.ExtStr;

begin

  SaveFile := False;

  if EditorFlags and efBackupFiles <> 0 then
  begin
    FSplit (FileName, D, N, E);
    BackupName := D + N + '.BAK';
    Assign (F, BackupName);
    Erase (F);
    Assign (F, FileName);
    Rename (F, BackupName);
    InOutRes := 0;
  end;

  Assign (F, FileName);
  Rewrite (F, 1);

  if IOResult <> 0 then
    EditorDialog (edCreateError, @FileName)
  else
    begin

      BlockWrite (F, Buffer^, CurPtr);
      BlockWrite (F, Buffer^[CurPtr + GapLen], BufLen - CurPtr);

      if IOResult <> 0 then
        EditorDialog (edWriteError, @FileName)
      else
        begin
          Modified := False;
          Update (ufUpdate);
          SaveFile := True;
        end;
        Close (F);
      end;


end; { TFileEditor.SaveFile }



{ -------------------------------------------------------------------------- }



function TFileEditor.SetBufSize (NewSize : Word) : Boolean;
VAR
  N : Word;
begin
  SetBufSize := False;
  if NewSize = 0 then NewSize := $1000 else
    if NewSize > $F000 then NewSize := $FFF0 else
      NewSize := (NewSize + $0FFF) and $F000;
  if NewSize <> BufSize then
  begin
    if NewSize > BufSize then
      if not SetBufferSize(Buffer, NewSize) then Exit;
    N := BufLen - CurPtr + DelCount;
    Move(Buffer^[BufSize - N], Buffer^[NewSize - N], N);
    if NewSize < BufSize then SetBufferSize(Buffer, NewSize);
    BufSize := NewSize;
    GapLen := BufSize - BufLen;
  end;
  SetBufSize := True;
end; { TFileEditor.SetBufSize }



{ -------------------------------------------------------------------------- }



procedure TFileEditor.Store (var S : Objects.TStream);

begin

  Inherited Store (S);
  S.Write (FileName, Length (FileName) + 1);
  S.Write (SelStart, SizeOf (Word) * 3);


end; { TFileEditor.Store }



{ -------------------------------------------------------------------------- }



procedure TFileEditor.UpdateCommands;

begin

  Inherited UpdateCommands;

  SetCmdState (cmSave, True);
  SetCmdState (cmSaveAs, True);

  { SAVE - Start. }

  SetCmdState (cmSaveDone, True);

  { SAVE - Stop. } { Added cmSaveDone toggle. }



  { -------------------------------------------------------------------- }
  {                                                                      }
  { The following SetCmdState calls are included to allow you to disable }
  { any custom menu options you design for the editor features.  I have  }
  { commented them out.  You pay a price in speed performance for EACH   }
  { option you uncomment.  Read the MENU section of NEWEDIT.DOC!         }
  {                                                                      }
  { -------------------------------------------------------------------- }


  { CENTER - Start. }
  { HOMEND - Start. }
  { INSLIN - Start. }
  { JLINE  - Start. }
  { MARK   - Start. }
  { PRETAB - Start. }
  { REFDOC - Start. }
  { REFORM - Start. }
  { RMSET  - Start. }
  { SCRLDN - Start. }
  { SCRLDN - Start. }
  { SELWRD - Start. }
  { WRAP   - Start. }

  { SetCmdState (cmCenterText, True);  }
  { SetCmdState (cmEndPage, True);     }
  { SetCmdState (cmHomePage, True);    }
  { SetCmdState (cmIndentMode, True);  }
  { SetCmdState (cmInsertLine, True);  }
  { SetCmdState (cmJumpLine, True);    }
  { SetCmdState (cmJumpMark0, True);   }
  { SetCmdState (cmJumpMark1, True);   }
  { SetCmdState (cmJumpMark2, True);   }
  { SetCmdState (cmJumpMark3, True);   }
  { SetCmdState (cmJumpMark4, True);   }
  { SetCmdState (cmJumpMark5, True);   }
  { SetCmdState (cmJumpMark6, True);   }
  { SetCmdState (cmJumpMark7, True);   }
  { SetCmdState (cmJumpMark8, True);   }
  { SetCmdState (cmJumpMark9, True);   }
  { SetCmdState (cmReformDoc, True);   }
  { SetCmdState (cmReformPara, True);  }
  { SetCmdState (cmRightMargin, True); }
  { SetCmdState (cmScrollDown, True);  }
  { SetCmdState (cmScrollUp, True);    }
  { SetCmdState (cmSelectWord, True);  }
  { SetCmdState (cmSetMark0, True);    }
  { SetCmdState (cmSetMark1, True);    }
  { SetCmdState (cmSetMark2, True);    }
  { SetCmdState (cmSetMark3, True);    }
  { SetCmdState (cmSetMark4, True);    }
  { SetCmdState (cmSetMark5, True);    }
  { SetCmdState (cmSetMark6, True);    }
  { SetCmdState (cmSetMark7, True);    }
  { SetCmdState (cmSetMark8, True);    }
  { SetCmdState (cmSetMark9, True);    }
  { SetCmdState (cmSetTabs, True);     }
  { SetCmdState (cmTabKey, True);      }
  { SetCmdState (cmWordWrap, True);    }


  { WRAP   - Stop. }
  { SELWRD - Stop. }
  { SCRLUP - Stop. }
  { SCRLDN - Stop. }
  { RMSET  - Stop. }
  { REFORM - Stop. }
  { REFDOC - Stop. }
  { PRETAB - Stop. }
  { MARK   - Stop. }
  { JLINE  - Stop. }
  { INSLIN - Stop. }
  { HOMEND - Stop. }
  { CENTER - Stop. } { This was required so these command constants may }
                     { be used in enabling and disabling menu options.  }


end; { TFileEditor.UpdateCommands }



{ -------------------------------------------------------------------------- }



function TFileEditor.Valid (Command : Word) : Boolean;

VAR

  D : Integer;

begin

  if Command = Views.cmValid then
    Valid := IsValid
  else
    begin

      Valid := True;

      if Modified then
      begin

        if FileName = '' then
          D := edSaveUntitled
        else
          D := edSaveModify;

        case EditorDialog (D, @FileName) of
          Views.cmYes    : Valid := Save;
          Views.cmNo     : Modified := False;
          Views.cmCancel : Valid := False;

        end;

      end;

    end;


end; { TFileEditor.Valid }



{ -------------------------------------------------------------------------- }



         { ----------------------------------------------------- }
         {                                                       }
         { The following methods are for the TEDITWINDOW object. }
         {                                                       }
         { ----------------------------------------------------- }



constructor TEditWindow.Init (var Bounds   : TRect;
                                  FileName : Objects.FNameStr;
                                  ANumber  : Integer);

VAR

  HScrollBar : Views.PScrollBar;
  VScrollBar : Views.PScrollBar;
  Indicator  : PIndicator;
  R          : TRect;

begin

  Inherited Init (Bounds, '', ANumber);
  Options := Options or Views.ofTileable;

  R.Assign (18, Size.Y - 1, Size.X - 2, Size.Y);
  HScrollBar := New (Views.PScrollBar, Init (R));
  HScrollBar^.Hide;
  Insert (HScrollBar);

  R.Assign (Size.X - 1, 1, Size.X, Size.Y - 1);
  VScrollBar := New (Views.PScrollBar, Init (R));
  VScrollBar^.Hide;
  Insert (VScrollBar);

  R.Assign (2, Size.Y - 1, 16, Size.Y);
  Indicator := New (PIndicator, Init (R));
  Indicator^.Hide;
  Insert (Indicator);

  GetExtent (R);
  R.Grow (-1, -1);
  Editor := New (PFileEditor, Init (R, HScrollBar, VScrollBar, Indicator, FileName));

  Insert (Editor);


end; { TEditWindow.Init }



{ -------------------------------------------------------------------------- }



constructor TEditWindow.Load (var S : Objects.TStream);

begin

  Inherited Load (S);
  GetSubViewPtr (S, Editor);


end; { TEditWindow.Load }



{ -------------------------------------------------------------------------- }



procedure TEditWindow.Close;

begin

  if Editor^.IsClipboard then
    Hide
  else
    Inherited Close;


end; { TEditWindow.Close }



{ -------------------------------------------------------------------------- }



function TEditWindow.GetTitle (MaxSize : Integer) : Views.TTitleStr;

begin

  if Editor^.IsClipboard then
    GetTitle := 'Clipboard'
  else
    if Editor^.FileName = '' then
      GetTitle := 'Untitled'
    else
      GetTitle := Editor^.FileName;


end; { TEditWindow.GetTile }



{ -------------------------------------------------------------------------- }



procedure TEditWindow.HandleEvent (var Event : Drivers.TEvent);

begin

  Inherited HandleEvent (Event);

  if (Event.What = Drivers.evBroadcast) then
    { and (Event.Command = cmUpdateTitle) then }



    { STATS - Start. }

    { -------------------------------------------------------------------- }
    {                                                                      }
    { Changed if statement above so I could test for cmBlugeonStats.       }
    { Stats would not show up when loading a file until a key was pressed. }
    {                                                                      }
    { -------------------------------------------------------------------- }


    case Event.Command of
      cmUpdateTitle   : begin
                          Frame^.DrawView;
                          ClearEvent (Event);
                        end;

      cmBludgeonStats : begin
                          Editor^.Update (ufStats);
                          ClearEvent (Event);
                        end;
    end;

    { STATS - Stop. }


end; { TEditWindow.HandleEvent }



{ -------------------------------------------------------------------------- }
procedure TEditWindow.SizeLimits(var Min, Max: TPoint);
begin
  inherited SizeLimits(Min, Max);
  Min.X := 23;
end;


procedure TEditWindow.Store (var S : Objects.TStream);

begin

  Inherited Store (S);
  PutSubViewPtr (S, Editor);


end; { TEditWindow.Store }


{ -------------------------------------------------------------------------- }



procedure RegisterEditors;

begin

  RegisterType (REditor);
  RegisterType (RMemo);
  RegisterType (RFileEditor);
  RegisterType (RIndicator);
  RegisterType (REditWindow);

end; { RegisterEditors }



{ -------------------------------------------------------------------------- }



end. { Unit NewEdit }
