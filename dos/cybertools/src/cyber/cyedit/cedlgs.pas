{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

CyberEdit dialogs.
}

unit CEDlgs;

{$I APP.INC}

interface

uses

  DOS, Objects, App, Views, Dialogs, Drivers, Validate, MsgBox,
  VGA, TVStr, CommDlgs, CECmds;

type

  PChrSetEditView = ^TChrSetEditView;
  TChrSetEditView = object (TView)
    ChrVal : longint;
    procedure Draw; virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  PChrSetEditDlg = ^TChrSetEditDlg;
  TChrSetEditDlg = object (TDialog)
    PasteChr : integer;
    ChrStatus : PInputLine;
    ChrView : PChrSetEditView;
    constructor Init (Name : PathStr);
    procedure HandleEvent (var Event : TEvent); virtual;
    function GetPalette: PPalette; virtual;
  end;

  PChrEditView = ^TChrEditView;
  TChrEditView = object (TView)
    FontArray : array [0..15] of byte;
    procedure Draw; virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
  end;

  PChrEditDlg = ^TChrEditDlg;
  TChrEditDlg = object (TDialog)
    ChrVal,
    FontTable : integer;
    ChrEditor : PChrEditView;
    constructor Init (C, F : integer);
    procedure SizeLimits (var Min, Max : TPoint); virtual;
  end;

  PIconView = ^TIconView;
  TIconView = object (TView)
    StartChr,
    IconLen : integer;
    AppCommand : word;
    constructor Init (X, Y, StChr, ILen : integer);
    procedure Draw; virtual;
    procedure HandleEvent (var Event : TEvent); virtual;
    procedure SetState (AState : word; Enable : boolean); virtual;
  end;

  PToolBarDlg = ^TToolBarDlg;
  TToolBarDlg = object (TDialog)
    constructor Init (StChr, ILen, Icons : integer; StartCmd : word);
    procedure SizeLimits (var Min, Max : TPoint); virtual;
  end;

implementation

{
Character selector dialog used to display char set ot edit.  Foreground color
must have bit 3 set (colors 8 - 15) to display the second VGA font.
}

{TChrSetEditView}

procedure TChrSetEditView.Draw;

var

  Buf : TDrawBuffer;
  X, Y : Integer;
  Color : word;

begin
  Color := GetColor(33);      {color added after last dialog entry}
  for Y := 0 to Size.Y - 1 do {draw character set to fit view}
  begin
    for X := 0 to Size.X - 1 do
      Buf[X] := (Y*Size.X+X) or (Color shl 8);
    WriteBuf (0,Y,Size.X,1,Buf);
  end;
  ShowCursor
end;

procedure TChrSetEditView.HandleEvent (var Event : TEvent);

var

  CurLoc : TPoint;

begin
  inherited HandleEvent (Event);
  if Event.What = evMouseDown then {handle mouse events}
  begin
    repeat
      if MouseInView (Event.Where) then
      begin
        MakeLocal (Event.Where,CurLoc);
        SetCursor (CurLoc.X, CurLoc.Y); {plot cursor}
        ChrVal := Cursor.X+32*Cursor.Y; {calc char val from position}
        Message (Owner,evBroadcast,cmCharSelected,@Self)
      end
    until not MouseEvent (Event, evMouseMove);
    if Event.Double then {double click to select char to edit}
      Message (Application,evBroadcast,cmCharEdit,Owner);
    ClearEvent (Event)
  end
  else
    if Event.What = evKeyDown then {handle keyboard events}
      with Cursor do
      begin
        case Event.KeyCode of
          kbHome     : SetCursor (0,Y);
          kbEnd      : SetCursor (Size.X-1,Y);
          kbUp       : if Y > 0 then
                         SetCursor (X,Y-1);
          kbDown     : if Y < Size.Y-1 then
                         SetCursor (X,Y+1);
          kbLeft     : if X > 0 then
                         SetCursor (X-1,Y);
          kbRight    :
          begin
            if X < Size.X-1 then
              SetCursor (X+1,Y)
          end
          else
            Exit
        end;
        ChrVal := Cursor.X+32*Cursor.Y; {calc char val from position}
        Message (Owner,evBroadcast,cmCharSelected,@Self);
        ClearEvent(Event)
      end
end;

{TChrSetEditDlg}

constructor TChrSetEditDlg.Init (Name : PathStr);

var

  R : TRect;

begin
  DeskTop^.GetExtent (R);
  R.A.X := R.B.X-39;
  R.B.X := R.A.X+36;
  R.A.Y := R.A.Y+1;
  R.B.Y := R.A.Y+14;
  inherited Init (R,Name);
  Options := Options or ofFirstClick;

  R.Assign (2,2,34,10);
  ChrView := New (PChrSetEditView,Init (R));
  ChrView^.Options := ChrView^.Options or ofSelectable;
  ChrView^.BlockCursor;
  Insert (ChrView);

  R.Assign (7,11,29,12);
  ChrStatus := New (PInputLine,Init (R,32));
  ChrStatus^.Options := ChrStatus^.Options and not ofSelectable;
  Insert (ChrStatus)
end;

procedure TChrSetEditDlg.HandleEvent (var Event : TEvent);

var

  TempStr : string;

begin
  if Event.What = evKeyDown then
    if Event.CharCode = #32 then
      Message (Application,evBroadcast,cmCharInvert,@Self)
    else
      case Event.KeyCode of
        kbEnter     : Message (Application,evBroadcast,cmCharEdit,@Self);
        kbDel       : Message (Application,evBroadcast,cmCharDelete,@Self);
        kbCtrlLeft  : Message (Application,evBroadcast,cmCharLeft,@Self);
        kbCtrlRight : Message (Application,evBroadcast,cmCharRight,@Self);
        kbCtrlPgUp  : Message (Application,evBroadcast,cmCharUp,@Self);
        kbCtrlPgDn  : Message (Application,evBroadcast,cmCharDown,@Self);
        kbShiftIns  : Message (Application,evBroadcast,cmCharPaste,@Self);
        kbCtrlIns   :
        begin
          PasteChr := ChrView^.ChrVal;
          FormatStr (TempStr,'Paste char = %0#%3d',ChrView^.ChrVal);
          ChrStatus^.SetData (TempStr)
        end
      end;
  inherited HandleEvent (Event);
  if (Event.What = evBroadcast) and
  (Event.Command = cmCharSelected) then
  begin
    FormatStr (TempStr,'Dec ³%0#%3d³   Hex ³%0#%02x³',ChrView^.ChrVal);
    ChrStatus^.SetData (TempStr)
  end;
end;

{
Get graphic color addition to dialog palette.
}

function TChrSetEditDlg.GetPalette : PPalette;

const

  CNewBlueDialog = CBlueDialog+CCharPal;
  CNewCyanDialog = CCyanDialog+CCharPal;
  CNewGrayDialog = CGrayDialog+CCharPal;
  P: array[dpBlueDialog..dpGrayDialog] of string[Length(CNewBlueDialog)] =
  (CNewBlueDialog,CNewCyanDialog,CNewGrayDialog);

begin
  GetPalette := @P[Palette]
end;

{TChrEditView}

procedure TChrEditView.Draw;

var

  Buf: TDrawBuffer;
  X, Y: Integer;
  Color: word;

begin
  Color := GetColor(2);
  for Y := 0 to Size.Y-1 do {draw character to fit view}
  begin
    for X := 0 to 7 do
      if FontArray [Y] and vgaBitTable [X] = 0 then
        Buf[X] := 249 or (Color shl 8)
      else
        Buf[X] := 178 or (Color shl 8);
    WriteBuf (0,Y,8,1,Buf);
  end;
  ShowCursor
end;

procedure TChrEditView.HandleEvent (var Event : TEvent);

var

  CurLoc : TPoint;

begin
  inherited HandleEvent (Event);
  if Event.What = evMouseDown then {handle mouse events}
  begin
    repeat
      if MouseInView (Event.Where) then
      begin
        MakeLocal (Event.Where,CurLoc);
        SetCursor (CurLoc.X, CurLoc.Y);
        if Event.Buttons and mbRightButton = 0 then
          FontArray [Cursor.Y] :=
          FontArray [Cursor.Y] or vgaBitTable[Cursor.X]
        else
          FontArray [Cursor.Y] :=
          FontArray [Cursor.Y] and not vgaBitTable[Cursor.X];
        PChrEditDlg (Owner)^.Lock;
        DrawView;
        PChrEditDlg (Owner)^.Unlock;
        Message (Application,evBroadcast,cmCharChanged,Owner)
      end
    until not MouseEvent (Event, evMouseMove);
    ClearEvent (Event)
  end
  else
    if Event.What = evKeyDown then {handle keyboard events}
      with Cursor do
      begin
        if Event.CharCode = #32 then
        begin
          FontArray [Y] := FontArray [Y] xor vgaBitTable[X];
          PChrEditDlg (Owner)^.Lock;
          DrawView;
          PChrEditDlg (Owner)^.Unlock;
          Message (Application,evBroadcast,cmCharChanged,Owner)
        end
        else
          case Event.KeyCode of
            kbEnter    : Message (Application,evBroadcast,cmCharChanged,Owner);
            kbHome     : SetCursor (0,Y);
            kbEnd      : SetCursor (Size.X-1,Y);
            kbUp       : if Y > 0 then
                           SetCursor (X,Y-1);
            kbDown     : if Y < Size.Y-1 then
                           SetCursor (X,Y+1);
            kbLeft     : if X > 0 then
                           SetCursor (X-1,Y);
            kbRight    : if X < Size.X-1 then
                           SetCursor (X+1,Y)
          end;
        ClearEvent(Event)
      end
end;

{TChrEditDlg}

constructor TChrEditDlg.Init (C, F : integer);

var

  TempData : string;
  R : TRect;
  ChrStatus : PInputLine;

begin
  R.Assign (9,1,19,20);
  inherited Init (R,'');
  Options := Options or ofFirstClick;
  ChrVal := C;
  FontTable := F;

  R.Assign (1,1,9,2);
  ChrStatus := New (PInputLine,Init (R,8));
  ChrStatus^.Options := ChrStatus^.Options and not ofSelectable;
  TempData := IntToStr (F)+':'+IntToStr (C);
  ChrStatus^.SetData (TempData);
  Insert (ChrStatus);

  R.Assign (1,2,9,18);
  ChrEditor := New (PChrEditView,Init (R));
  ChrEditor^.Options := ChrEditor^.Options or ofSelectable;
  ChrEditor^.BlockCursor;
  Insert (ChrEditor)
end;

procedure TChrEditDlg.SizeLimits (var Min, Max : TPoint);

begin
  inherited SizeLimits (Min, Max);
  Min.X := 10
end;

{TIconView}

constructor TIconView.Init (X, Y, StChr, ILen : integer);

var

 R : TRect;

begin
  R.Assign (X,Y,X+ILen,Y+1);
  inherited Init (R);
  Options := Options or (ofSelectable+ofFirstClick);
  EventMask := EventMask or evBroadcast;
  StartChr := StChr;
  IconLen := ILen
end;

{
Use custom draw to handle icon's colors for various states.
}

procedure TIconView.Draw;

var

  Buf : TDrawBuffer;
  Color : word;
  X : byte;

begin
  if State and sfDisabled <> 0 then
    Color := GetColor (1)    {disabled color}
  else
    if State and sfFocused = 0 then
      Color := GetColor (2)  {normal color}
    else
      Color := GetColor (8); {focused color}
  for X := 0 to Size.X-1 do
    Buf[X] := (StartChr+X) or (Color shl 8);
  WriteLine (0,0,Size.X,1,Buf)
end;

{
Mouse click or enter on icon sends icon's command to main app.
}

procedure TIconView.HandleEvent (var Event : TEvent);

begin
  inherited HandleEvent (Event);
  case Event.What of
    evBroadcast:
    if Event.Command = cmCommandSetChanged then
    begin
      SetState (sfDisabled,not CommandEnabled (AppCommand));
      DrawView
    end;
    evMouseDown :
    begin
      Message (Application,evCommand,AppCommand,@Self);
      ClearEvent (Event)
    end;
    evKeyDown:
    if Event.KeyCode = kbEnter then
    begin
      Message (Application,evCommand,AppCommand,@Self);
      ClearEvent(Event)
    end
  end
end;

{
Make sure icon is redrawn with correct colors during state changes.
}

procedure TIconView.SetState (AState : word; Enable : boolean);

begin
  inherited SetState (AState,Enable);
  if AState = sfFocused then
    DrawView
end;

{
TToolBarDlg uses a set of characters to form a graphic icons.  Icons are
expected to be the same size.
}

constructor TToolBarDlg.Init (StChr, ILen, Icons : integer; StartCmd : word);

var

  I : integer;
  R : TRect;
  Icon : PIconView;

begin
  R.Assign (1,1,8,Icons*2+2);
  inherited Init (R,'');
  Options := Options or ofFirstClick;
  State := State and not sfShadow;
  Flags := Flags and not wfClose;
  for I := 0 to Icons-1 do
  begin
    Icon := New (PIconView, Init (2,I*2+1,I*ILen+StChr,ILen));
    Icon^.AppCommand := StartCmd+I;
    Insert (Icon)
  end;
  for I := 1 to Icons-1 do
  begin
    R.Assign (1,I*2,Size.X-1,I*2+1);
    Insert (New (PStaticText,
    Init (R,FillStr ('Ä',ILen+2)))) {icon seperator}
  end;
  SelectNext (false)
end;

procedure TToolBarDlg.SizeLimits (var Min, Max : TPoint);

begin
  inherited SizeLimits (Min, Max);
  Min.X := 7
end;

end.
