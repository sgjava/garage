{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Cyber Invaders game implemented with character sprite views.  Invader
formations are controlled by a bit map array of longints, the ship is
controlled with the key board and the UFO is randomly controlled.  Each level
gets harder with more invaders and UFO bombs.  After the 7th level it
randomly selects invaders with the hardest level.

Levels 1-7 use VGA font tables 1-7 to select different invader types.  The
font tables are loaded with the config stream at initialization.  The desktop
uses font 0 table and animation uses font 1 table.  Invaders and UFO DAC
color is also set by level.

Dialog's State method used to select font table, color and turn off sound
when focus changes.
}

unit GameDlg;

{$I APP.INC}

interface

uses

  DOS, Objects, App, Views, Dialogs, Drivers, ColorSel,
  VGA, CommDlgs, TVStr, CGCmds;

const

  gameMatLines = 7;  {static sprite matrix size+1 in 32 bit lines}
  gameInvAttr  = 9;  {dac register used by invaders}
  gameUfoAttr  = 10; {dac register used by ufo}

type

  gameMatrix = array [0..gameMatLines] of longint;

  PBackView = ^TBackView;
  TBackView = object (TView)
    procedure Draw; virtual;
  end;

  PSpriteView = ^TSpriteView;
  TSpriteView = object (TView)
    FrameSize,
    FramePos,
    EndPos,
    PalIndex : byte;
    Dir : TPoint;
    SpriteStr : PString;
    constructor Init (var Bounds : TRect; S : PString; D : TPoint);
    procedure CalcMove; virtual;
    procedure Draw; virtual;
  end;

  PUfoView = ^TUfoView;
  TUfoView = object (TSpriteView)
    procedure CalcMove; virtual;
  end;

  PBombView = ^TBombView;
  TBombView = object (TSpriteView)
    procedure CalcMove; virtual;
  end;

  PExpView = ^TExpView;
  TExpView = object (TSpriteView)
    procedure CalcMove; virtual;
  end;

  PShipView = ^TShipView;
  TShipView = object (TSpriteView)
    procedure CalcMove; virtual;
  end;

  PShotView = ^TShotView;
  TShotView = object (TSpriteView)
    procedure CalcMove; virtual;
  end;

  PHeadView = ^THeadView;
  THeadView = object (TSpriteView)
    Delay,
    DelayVal : word;
    procedure CalcMove; virtual;
  end;

  FreqTablePtr = ^FreqTable;
  FreqTable = array[0..8191] of word;

  PGameDlg = ^TGameDlg;
  TGameDlg = object (TDialog)
    CurCh,
    LeftCh,
    RightCh,
    ShootCh,
    StopCh : char;
    CurSndSeq,
    EndSndSeq,
    gameState,
    InvaderCnt,
    InvaderPts,
    UfoBomb : word;
    Level,
    ShipCnt,
    LastTimer,
    Score : longint;
    FreqData : FreqTablePtr;
    Ufo : PUfoView;
    Bomb : PBombView;
    Exp : PExpView;
    Ship : PShipView;
    Shot : PShotView;
    Head : PHeadView;
    AniGroup : PGroup;
    ScoreLine,
    ShipsLine,
    LevelLine : PInputLine;
    constructor Init (T : string; LC,RC,SC,PC : char);
    destructor Done; virtual;
    procedure SetState (AState : word; Enable : boolean); virtual;
    function GetPalette: PPalette; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure SoundOff;
    procedure SetSound (SndArr : pointer; E : word);
    procedure PlaySound;
    procedure NextLevel;
    procedure DispScore;
    procedure DispLevel;
    procedure DispShips;
    procedure InvaderHit (P : PSpriteView);
    procedure MatrixInvaders (X1, Y1, D : integer; Mat : gameMatrix);
    procedure DrawInvaders;
    procedure DeleteInvaders;
    procedure InitUfo;
    procedure DrawUfo;
    procedure InitShip;
    procedure DrawShip;
    procedure InitSprites;
    procedure DrawSprites;
  end;

  GameOptsData = record {game options dialog data}
    Left,
    Right,
    Shoot,
    Stop : string[1];
    SoundFlag : integer
  end;

  PGameOptsDlg = ^TGameOptsDlg;
  TGameOptsDlg = object (TDialog)
    constructor Init;
  end;

const

  {game states}

  gameAnimate    = $0001;
  gameShipHit    = $0002;
  gameInvaderHit = $0004;
  gamePlaySound  = $0100;
  gameSoundOn    = $0200;
  gameEndRound   = $1000;
  gameEndGame    = $2000;

  {dialog palette additions for animation}

  CAniColor = #$00#$00#$00#$00#$00#$00#$00;
  CAniPal   = #136#137#138#139#140#141#142;

  {dialog palette additions for graphics color}

  CGraphColor   = #$00;
  CGraphPal     = #143;

  {sprite frame sequences using character values}

  gameInvader : string[12] =
  #1#2#255+
  #3#4#5+
  #6#7#8+
  #9#10#11;

  gameUFO : string[6] =
  #12#13#255+
  #14#15#16;

  gameBomb : string[4] =
  #17#18#19#20;

  gameExp : string[18] =
  #21#21#21#21#22#22#22#22#23#23#23#23#22#22#22#22#21#21#21#21;

  gameShip : string[12] =
  #24#25#255+
  #26#27#28+
  #29#30#31+
  #32#33#34;

  gameShot : string[4] =
  #35#36#37#38;

  gameHead : string[140] =
  #255#64#65#66#67+
  #68#69#70#70#72+
  #73#74#75#76#77+
  #78#79#80#81#82+

  #255#83#84#85#86+
  #255#87#88#89#90+
  #255#91#92#93#94+
  #255#95#96#97#98+

  #255#99#100#101#102+
  #255#103#104#105#106+
  #255#107#108#109#110+
  #255#111#112#113#114+

  #255#115#116#117#118+
  #255#119#120#121#122+
  #255#123#124#125#126+
  #255#127#128#129#255+

  #255#130#131#132#133+
  #255#134#135#136#137+
  #255#138#139#140#141+
  #255#142#143#144#255+

  #255#145#146#147#148+
  #255#149#150#151#152+
  #255#153#154#155#156+
  #255#157#158#159#255+

  #255#160#161#162#255+
  #255#163#164#165#166+
  #255#167#168#169#170+
  #255#171#172#173#255;

  {invader formations in 32 X 8 matrix.  1 bits = invader, 0 = no invader}

  gameMatBlock1 : gameMatrix =
  (
  $ffff0000,
  $ffff0000,
  $ffff0000,
  $ffff0000,
  $00000000,
  $00000000,
  $00000000,
  $00000000
  );

  gameMatBlock2 : gameMatrix =
  (
  $00000000,
  $fff00000,
  $00000000,
  $fff00000,
  $00000000,
  $fff00000,
  $00000000,
  $00000000
  );

  gameMatBlock3 : gameMatrix =
  (
  $fff00000,
  $00000000,
  $fff00000,
  $00000000,
  $fff00000,
  $00000000,
  $00000000,
  $00000000
  );

  gameMatBlock4 : gameMatrix =
  (
  $ffff0000,
  $ffff0000,
  $ffff0000,
  $ffff0000,
  $ffff0000,
  $ffff0000,
  $ffff0000,
  $ffff0000
  );

  gameMatBlock5 : gameMatrix =
  (
  $00000000,
  $ffff0000,
  $00000000,
  $ffff0000,
  $00000000,
  $ffff0000,
  $00000000,
  $ffff0000
  );

  gameMatBlock6 : gameMatrix =
  (
  $fffff000,
  $00000000,
  $fffff000,
  $00000000,
  $fffff000,
  $00000000,
  $fffff000,
  $00000000
  );

  {dac rgb colors for invader/ufo levels 1-7}

  gameInvColor : array [0..6] of array [0..vgaRGBMax] of byte =
  (
  (0,63,0),
  (0,0,63),
  (63,0,0),
  (0,47,47),
  (63,63,0),
  (31,63,0),
  (15,63,15)
  );

  {sound effect frequency tables for pc speaker in 8253 timer values}
  {0001h = 1.193180 MHz, ffffh = 18.2065 Hz}

  sndShot : array[0..1] of word =
  ($4000,$3000);

  sndInvader : array[0..2] of word =
  ($0800,$1000,$2000);

  sndUfo : array[0..8] of word =
  ($1100,$1200,$1100,$1300,$1200,$1400,$1300,$1500,$1400);

  sndShip : array[0..8] of word =
  ($1000,$2000,$3000,$4000,$5000,$6000,$7000,$8000,$9000);

implementation

{
TBackView is the animation group's background.
}

procedure TBackView.Draw;

var

  Buf : TDrawBuffer;

begin
  MoveChar (Buf[0],' ',GetColor (33),Size.X);
  WriteLine (0,0,Size.X,Size.Y,Buf)
end;

{
TSpriteView is the base view for all other sprite decendents.
}

constructor TSpriteView.Init (var Bounds : TRect; S : PString; D : TPoint);

begin
  inherited Init (Bounds);
  SpriteStr := S;             {sprite frame string}
  Dir := D;                   {x and y direction}
  FrameSize := Size.X*Size.Y; {characters used in frame}
  FramePos := 1;              {start with first frame}
  EndPos := Length (SpriteStr^)-FrameSize+1 {last frame}
end;

{
This is what gives life to the sprite.  Default calc uses desending invaders
logic which restart at top when they reach the bottom on animation group.
}

procedure TSpriteView.CalcMove;

begin
  if Dir.X > 0 then
  begin                       {see if x dir = 1 (moving left)}
    if FramePos < EndPos then {if not last frame then inc for next}
      Inc (FramePos,FrameSize)
    else
    begin                     {if last frame then move sprite x dir chrs}
      Origin.X := Origin.X+Dir.X;
      FramePos := 1
    end
  end
  else
    if Dir.X < 0 then
    begin
      if FramePos > 1 then
        Dec (FramePos,FrameSize)
      else
      begin
        Origin.X := Origin.X+Dir.X;
        FramePos := EndPos
      end
    end;
  if Origin.X > Owner^.Size.X then {boundry checking logic}
  begin
    FramePos := EndPos;
    Origin.X := Owner^.Size.X;
    Dir.X := -1;
    Inc (Origin.Y);
    if Origin.Y > Owner^.Size.Y then
      Origin.Y := 0
  end
  else
    if Origin.X < -Size.X  then
    begin
      FramePos := 1;
      Origin.X := -Size.X;
      Dir.X := 1;
      Inc (Origin.Y);
      if Origin.Y > Owner^.Size.Y then
        Origin.Y := 0
    end
end;

{
Draw current frame.
}

procedure TSpriteView.Draw;

var

  Buf : TDrawBuffer;
  X, Y : byte;

begin
  for Y := 0 to Size.Y-1 do
  begin
    for X := 0 to Size.X-1 do
      MoveChar(Buf[X],SpriteStr^[Y*Size.X+X+FramePos],GetColor (PalIndex),1);
    WriteLine (0,Y,Size.X,1,Buf)
  end
end;

{
TUfoView adds logic for UFO starting at random y axis and moving horz.  UFO
also randomly drops bombs.
}

procedure TUfoView.CalcMove;

begin
  if Dir.X > 0 then
  begin
    if FramePos < EndPos then
      Inc (FramePos,FrameSize)
    else
    begin
      Origin.X := Origin.X+Dir.X;
      FramePos := 1
    end
  end
  else
    if Dir.X < 0 then
    begin
      if FramePos > 1 then
        Dec (FramePos,FrameSize)
      else
      begin
        Origin.X := Origin.X+Dir.X;
        FramePos := EndPos
      end
    end;
  if Origin.X > Owner^.Size.X then
  begin
    FramePos := EndPos;
    Origin.X := Owner^.Size.X;
    Dir.X := -1;
    Origin.Y := Random (Owner^.Size.Y-4)
  end
  else
    if Origin.X < -Size.X then
    begin
      FramePos := 1;
      Origin.X := -Size.X;
      Dir.X := 1;
      Origin.Y := Random (Owner^.Size.Y-4)
    end
end;

{
TBombView adds logic for decending bomb that hides when it hits bottom of
animation group.
}

procedure TBombView.CalcMove;

begin
  if State and sfVisible = sfVisible then
  begin
    if FramePos < EndPos then
      Inc (FramePos,FrameSize)
    else
    begin
      Origin.Y := Origin.Y+Dir.Y;
      FramePos := 1
    end
  end
end;

{
TExpView logic for updating frames without moving.
}

procedure TExpView.CalcMove;

begin
  if State and sfVisible = sfVisible then
  begin
    if FramePos < EndPos then
      Inc (FramePos,FrameSize)
    else
      Hide
  end
end;

{
TShipView adds logic to move horz and stop when min/max width of animation
group is reached.
}

procedure TShipView.CalcMove;

begin {logic moves ship in horz dir}
  if State and sfVisible = sfVisible then
  begin
    if (Origin.X < Owner^.Size.X-1) and (Dir.X > 0) then
    begin
      if FramePos < EndPos then
        Inc (FramePos,FrameSize)
      else
      begin
        Origin.X := Origin.X+Dir.X;
        FramePos := 1
      end
    end;
    if (Origin.X >= 0) and (Dir.X < 0) then
    begin
      if FramePos > 1 then
        Dec (FramePos,FrameSize)
      else
      begin
        Origin.X := Origin.X+Dir.X;
        FramePos := EndPos
      end
    end
  end
end;

{
TShotView adds logic for vert moving shot.
}

procedure TShotView.CalcMove;

begin
  if FramePos < EndPos then
    Inc (FramePos,FrameSize)
  else
  begin
    Origin.Y := Origin.Y+Dir.Y;
    FramePos := 1
  end;
  if Origin.Y < 0 then
    Hide
end;

{
THeadView adds logic for delayed updating of frames without moving.
}

procedure THeadView.CalcMove;

begin {logic for updating frames without moving}
  if State and sfVisible = sfVisible then
  begin
    Dec (Delay);
    if Delay = 0 then
    begin
      if FramePos < EndPos then
        Inc (FramePos,FrameSize)
      else
        Hide;
      Delay := DelayVal
    end
  end
end;

{
TGameDlg is complete 'invaders' style game implemented with character
sprites.  Characters params are passed to allow custom control of ship.
}

constructor TGameDlg.Init (T : string; LC,RC,SC,PC : char);

var

  R : TRect;
  BackView : PBackView;

begin
  R.Assign (0,0,75,20);
  inherited Init (R,T);
  Options := Options or ofCentered;
  Palette := dpBlueDialog;                   {use blue dialog}
  gameState := gameState or gameAnimate;     {turn animation on}
  ShipCnt := 5;                              {current ships}
  InvaderCnt := 0;                           {cueernt invader count}
  CurSndSeq := 0;                            {current sound seq}
  EndSndSeq := 0;                            {last sound seq}
  FreqData := nil;                           {pointer to freq array}
  LastTimer := longint (Ptr (Seg0040,$6c)^); {use bios for sound timing}
  LeftCh := UpCase (LC);                     {ship control chars}
  RightCh := UpCase (RC);
  ShootCh := UpCase (SC);
  StopCh := UpCase (PC);

  R.Assign (63,3,73,4);
  ScoreLine := New (PInputLine,Init (R,8));
  ScoreLine^.Options := ScoreLine^.Options and not ofSelectable;
  Insert (ScoreLine);
  DispScore;
  R.Assign (62,2,68,3);
  Insert (New (PLabel,Init (R,'Score',nil)));

  R.Assign (63,5,73,6);
  LevelLine := New (PInputLine,Init (R,8));
  LevelLine^.Options := ScoreLine^.Options and not ofSelectable;
  Insert (LevelLine);
  DispLevel;
  R.Assign (62,4,68,5);
  Insert (New (PLabel,Init (R,'Level',nil)));

  R.Assign (63,7,73,8);
  ShipsLine := New (PInputLine,Init (R,8));
  ShipsLine^.Options := ScoreLine^.Options and not ofSelectable;
  Insert (ShipsLine);
  DispShips;
  R.Assign (62,6,68,7);
  Insert (New (PLabel,Init (R,'Ships',nil)));

  R.Assign(62, 15, 73, 17);
  Insert(New(PButton, Init(R, '~P~lay', cmAniOn, bfNormal)));
  R.Assign(62, 17, 73, 19);
  Insert(New(PButton, Init(R, '~S~top', cmAniOff, bfNormal)));

  R.Assign (2,1,62,19);
  AniGroup := New (PGroup, Init (R));
  AniGroup^.GetExtent (R);
  BackView := New (PBackView, Init (R));
  AniGroup^.Insert (BackView);
  InitSprites;             {initilize sprites}
  Insert (AniGroup)
end;

{
Turn off sound before inherited Done.
}

destructor TGameDlg.Done;

begin
  SoundOff;
  inherited Done
end;

{
This allows game to select correct font when multiple games are running.
}

procedure TGameDlg.SetState (AState : word; Enable : boolean);

begin
  inherited SetState (AState,Enable);
  if AState = sfFocused then
  begin
    if Level < 8 then {set custom dac colors and font}
    begin
      SoundOff;
      SetDAC (GetAttrCont (gameInvAttr),gameInvColor[Level-1,0],
      gameInvColor[Level-1,1],gameInvColor[Level-1,2]);
      SetDAC (GetAttrCont (gameUfoAttr),gameInvColor[Level-1,0],
      gameInvColor[Level-1,1],gameInvColor[Level-1,2]);
      FontMapSelect (vgaChrTableMap1[0],vgaChrTableMap2[Level])
    end
    else
    begin
      SoundOff;
      FontMapSelect (vgaChrTableMap1[0],vgaChrTableMap2[Random (7)+1])
    end
  end
end;

{
Define additional colors for animation starting at dialog palette index 33.
}

function TGameDlg.GetPalette: PPalette;

const

  CNewBlueDialog = CBlueDialog+CAniPal;
  CNewCyanDialog = CCyanDialog+CAniPal;
  CNewGrayDialog = CGrayDialog+CAniPal;
  P: array[dpBlueDialog..dpGrayDialog] of string[Length(CNewBlueDialog)] =
  (CNewBlueDialog, CNewCyanDialog, CNewGrayDialog);

begin
  GetPalette := @P[Palette];
end;

procedure TGameDlg.HandleEvent(var Event: TEvent);

{
Shoot missle from current ship location.
}

procedure ShipShot;

begin
  if Shot^.State and sfVisible = 0 then
  begin
    SetSound (@sndShot,1);
    Shot^.Origin.X := Ship^.Origin.X;
    if Ship^.FramePos > 6 then
      Inc (Shot^.Origin.X);
    Shot^.Origin.Y := Ship^.Origin.Y-1;
    Shot^.FramePos := 1;
    Shot^.Show
  end
end;

{
Ship was hit by something and restarts current level.  Ship hides while head
animation is playing.  If no ships are let then gameState is set for no
animation and end game.
}

procedure ShipHit;

var

  TempStr : String[8];

begin
  SetSound (@sndShip,8);
  gameState := gameState and not gameShipHit;
  Ship^.Hide;
  Dec (ShipCnt);      {ship dead}
  DispShips;          {show ships left}
  with Head^ do       {start head animation}
  begin
    FramePos := 1;
    Origin.X := Ship^.Origin.X-2;
    Origin.Y := Ship^.Origin.Y-3;
    Show
  end;
  Dec (Level);        {restart current level}
  NextLevel;
  if ShipCnt = 0 then {no ships left}
  begin
    gameState := (gameState and not gameAnimate) or gameEndGame;
    TempStr := 'GAME END';
    ShipsLine^.SetData (TempStr);
    SoundOff
  end
end;

begin
  inherited HandleEvent(Event);
    case Event.What of
      evKeyDown :
      if (gameState and gameAnimate <> 0) and
      (State and sfFocused <> 0) and
      (Ship^.State and sfVisible <> 0) then
      begin                                 {handle custom controls}
        CurCh := Upcase (Event.CharCode);
        if CurCh = LeftCh then
          Ship^.Dir.X := -1
        else
          if CurCh = RightCh then
            Ship^.Dir.X := 1
          else
            if CurCh = StopCh then
              Ship^.Dir.X := 0
            else
              if CurCh = ShootCh then
                ShipShot
              else
                Exit;
        ClearEvent (Event)
      end;
      evCommand:
      begin {process commands}
        case Event.Command of
          cmAniOff :
          begin
            gameState := gameState and not gameAnimate;
            SoundOff
          end;
          cmAniOn  : gameState := gameState or gameAnimate
        else
          Exit
        end;
        ClearEvent (Event)
      end;
      evBroadcast :
      if (gameState and gameAnimate <> 0) and
      (gameState and gameEndGame = 0) and
      (State and sfFocused <> 0) then
      begin {process broadcasts}
        case Event.Command of
          cmAnimate : {animation driver}
          begin
            PlaySound;
            DrawSprites;
            if gameState and gameInvaderHit <> 0 then
            begin
              gameState := gameState and not gameInvaderHit;
              DispScore
            end;
            if gameState and gameShipHit <> 0 then
              ShipHit;
            if gameState and gameEndRound <> 0 then
              NextLevel
          end
        end
      end
    end
end;

{
Silence PC speaker if sound was enabled.
}

procedure TGameDlg.SoundOff;

begin
  if gameState and gameSoundOn <> 0 then
    asm
      in      al,61h
      and     al,11111100b
      out     61h,al
    end
end;

{
Start sound sequence if sound enabled and another sound is not playing.
}

procedure TGameDlg.SetSound (SndArr : pointer; E : word);

begin
  if (gameState and gameSoundOn <> 0) and
  (gameState and gamePlaySound = 0) then
  begin
    CurSndSeq := 0;        {first freq word}
    EndSndSeq := E;        {last freq word}
    FreqData := SndArr;    {freq table}
    gameState := gameState or gamePlaySound
  end
end;

{
Set sound word if sound enabled, sound playing and 1/18 second has elasped.
}

procedure TGameDlg.PlaySound;

var

  FData : word;

begin
  if (gameState and gameSoundOn <> 0) and
  (gameState and gamePlaySound <> 0) and
  (longint (Ptr (Seg0040,$6c)^) <> LastTimer) then
  begin
    if CurSndSeq <= EndSndSeq then
    begin
      LastTimer := longint (Ptr (Seg0040,$6c)^); {get current bios time}
      FData := FreqData^[CurSndSeq];             {get freq word}
      asm
        mov     al,10110110b {channel 2, lsb/msb, square wave, binary}
        out     43h,al
        mov     ax,FData     {get freq word}
        out     42h,al       {store low byte}
        mov     al,ah
        out     42h,al       {stord high byte}
        in      al,61h
        or      al,00000011b {speaker on, use 8253 timer channel 2}
        out     61h,al
      end;
      Inc (CurSndSeq)        {set to read next word in freq table}
    end
    else
    begin                    {end of sound sequence reached}
      SoundOff;
      gameState := gameState and not gamePlaySound
    end
  end
end;

{
Set next level based on current level.  After 7th level random invader
sprites are selected with hardest formation and maximum UFO bombs.
}

procedure TGameDlg.NextLevel;

begin
  gameState := gameState and not gameEndRound; {clear for new round}
  Inc (Level);      {set next level}
  DispLevel;        {display level}
  DeleteInvaders;   {delete and remaining invaders}
  if Level < 8 then {set custom dac colors and font}
  begin
    SetDAC (GetAttrCont (gameInvAttr),gameInvColor[Level-1,0],
    gameInvColor[Level-1,1],gameInvColor[Level-1,2]);
    SetDAC (GetAttrCont (gameUfoAttr),gameInvColor[Level-1,0],
    gameInvColor[Level-1,1],gameInvColor[Level-1,2]);
    FontMapSelect (vgaChrTableMap1[0],vgaChrTableMap2[Level])
  end;
  case Level of   {formation, points and bomb chances}
    1 :
    begin
      MatrixInvaders (10,1,1,gameMatBlock1);
      InvaderPts := 100;
      UfoBomb := 20
    end;
    2 :
    begin
      MatrixInvaders (10,3,1,gameMatBlock1);
      InvaderPts := 100;
      UfoBomb := 15
    end;
    3 :
    begin
      MatrixInvaders (10,1,1,gameMatBlock2);
      MatrixInvaders (10,1,-1,gameMatBlock3);
      InvaderPts := 200;
      UfoBomb := 10
    end;
    4 :
    begin
      MatrixInvaders (10,2,1,gameMatBlock2);
      MatrixInvaders (10,2,-1,gameMatBlock3);
      InvaderPts := 200;
      UfoBomb := 8
    end;
    5 :
    begin
      MatrixInvaders (8,-2,1,gameMatBlock4);
      InvaderPts := 300;
      UfoBomb := 7
    end;
    6 :
    begin
      MatrixInvaders (8,0,1,gameMatBlock4);
      InvaderPts := 300;
      UfoBomb := 5
    end;
    7 :
    begin
      MatrixInvaders (0,0,1,gameMatBlock5);
      MatrixInvaders (0,0,-1,gameMatBlock6);
      InvaderPts := 400;
      UfoBomb := 2
    end
    else {select hardest formation and maximum ufo bombs}
    begin
      FontMapSelect (vgaChrTableMap1[0],vgaChrTableMap2[Random (7)+1]);
      MatrixInvaders (0,0,1,gameMatBlock5);
      MatrixInvaders (0,0,-1,gameMatBlock6);
      InvaderPts := 500;
      UfoBomb := 0
    end
  end
end;

{
Display score with leading 0s.
}

procedure TGameDlg.DispScore;

var

  TempStr : String[8];

begin
  FormatStr (TempStr,'%0#%08d',Score);
  ScoreLine^.SetData (TempStr)
end;

{
Display level right justified.
}

procedure TGameDlg.DispLevel;

var

  TempStr : String[8];

begin
  FormatStr (TempStr,'%0#%8d',Level);
  LevelLine^.SetData (TempStr)
end;

{
Display ships right justifed.
}

procedure TGameDlg.DispShips;

var

  TempStr : String[8];

begin
  FormatStr (TempStr,'%0#%8d',ShipCnt);
  ShipsLine^.SetData (TempStr)
end;

{
Invader hit by something.  Sets end round game state if last invader killed.
}

procedure TGameDlg.InvaderHit (P : PSpriteView);

begin
  SetSound (@sndInvader,2);
  P^.Hide;
  Dec (InvaderCnt);
  if InvaderCnt = 0 then {end round if last invader}
    gameState := gameState or gameEndRound;
  gameState := gameState or gameInvaderHit
end;

{
Use bit map table of longints to determine where to place invaders.
1 bits = invader, 0 bits = no invader.  You can also control starting X,Y and
direction.
}

procedure TGameDlg.MatrixInvaders (X1, Y1, D : integer; Mat : gameMatrix);

var

  X, Y : integer;
  BitPos : longint;
  B, R : TRect;
  P : TPoint;
  SV : PSpriteView;

begin
  AniGroup^.GetBounds (B);
  P.X := D; {set x dir}
  P.Y := 0; {set y dir}
  for Y := 0 to gameMatLines do      {do for each longint}
  begin
    BitPos := $8000000;              {start from left most bit}
    for X := 0 to 31 do              {process 32 bits}
    begin
      if Mat[Y] and BitPos <> 0 then {create sprite if bit set}
      begin
        R.Assign (X*3+X1+B.A.X, Y*2+Y1+B.A.Y, X*3+X1+B.A.X+3, Y*2+Y1+B.A.Y+1);
        SV := New (PSpriteView, Init (R,@gameInvader,P));
        SV^.PalIndex := 34;          {set new tv palette index}
        AniGroup^.Insert (SV);
        Inc (InvaderCnt)             {add 1 to invader count}
      end;
      if X <> 31 then                {shift bit right for next compare}
        BitPos := BitPos shr 1
    end
  end
end;

{
Move all invaders and detect collision between invader/ship or invader/shot.
}

procedure TGameDlg.DrawInvaders;

procedure DrawSpr (P : PSpriteView); far;

begin
  if TypeOf (P^) = TypeOf (TSpriteView) then
  begin
    P^.CalcMove;
    P^.DrawView;
    if (P^.State and sfVisible <> 0) then {invader hit ship?}
    begin
      if (Ship^.State and sfVisible <> 0) and
      (P^.Origin.Y = Ship^.Origin.Y) and
      (P^.Origin.X = Ship^.Origin.X) then
      begin
        InvaderHit (P);
        gameState := gameState or gameShipHit
      end;
      if (Shot^.State and sfVisible <> 0) and
      (P^.Origin.Y = Shot^.Origin.Y) and
      (((Shot^.Origin.X = P^.Origin.X) or
      (Shot^.Origin.X = P^.Origin.X+1) or
      (Shot^.Origin.X = P^.Origin.X+2))) then {invader hit shot?}
      begin
        Shot^.Hide;
        Score := Score+InvaderPts;
        InvaderHit (P)
      end
    end
  end
end;

begin {update and draw all invader sprites in group}
  AniGroup^.ForEach (@DrawSpr)
end;

{
Remove all invaders from animation group.
}

procedure TGameDlg.DeleteInvaders;

procedure DeleteSpr (P : PSpriteView); far;

begin
  if TypeOf (P^) = TypeOf (TSpriteView) then
    Dispose (P,Done);
  InvaderCnt := 0
end;

begin {delete all invader type sprites in group}
  AniGroup^.ForEach (@DeleteSpr)
end;

{
Set up UFO and bomb sprites.
}

procedure TGameDlg.InitUfo;

var

  R : TRect;
  P : TPoint;

begin
  P.X := 0;
  P.Y := 1;
  R.Assign (0,0,1,1);
  Bomb := New (PBombView, Init (R,@gameBomb,P));
  Bomb^.PalIndex := 36;
  Bomb^.Hide;
  AniGroup^.Insert (Bomb);

  P.X := 0;
  P.Y := 0;
  Exp := New (PExpView, Init (R,@gameExp,P));
  Exp^.PalIndex := 37;
  Exp^.Hide;
  AniGroup^.Insert (Exp);

  P.X := 1;
  P.Y := 0;
  R.Assign (0,0,3,1);
  Ufo := New (PUfoView, Init (R,@gameUFO,P));
  Ufo^.PalIndex := 35;
  AniGroup^.Insert (Ufo)
end;

{
Draw UFO and bomb and detect collision between bomb/ship, ufo/shot and
explosion/ship.
}

procedure TGameDlg.DrawUfo;

begin
  if (Bomb^.State and sfVisible = 0) and
  (Ufo^.Origin.X = Ship^.Origin.X) and
  (Random (UfoBomb) = 0) then            {randomly drop bombs on ship}
  begin
    Bomb^.Origin.X := Ufo^.Origin.X;
    Bomb^.Origin.Y := Ufo^.Origin.Y;
    Bomb^.Show
  end;
  if (Bomb^.State and sfVisible = sfVisible) and
  (Bomb^.Origin.Y = AniGroup^.Size.Y) then
  begin                              {if bomb hits bottom then explode}
    Exp^.Origin.X := Bomb^.Origin.X;
    Exp^.Origin.Y := Bomb^.Origin.Y-1;
    Exp^.FramePos := 1;
    Bomb^.Hide;
    Exp^.Show
  end;
  Ufo^.CalcMove;
  Bomb^.CalcMove;
  Exp^.CalcMove;
  Ufo^.DrawView;
  Bomb^.DrawView;
  Exp^.DrawView;
  if (Shot^.State and sfVisible <> 0) and
  (Shot^.Origin.Y = Ufo^.Origin.Y) and
  (((Shot^.Origin.X = Ufo^.Origin.X) or
  (Shot^.Origin.X = Ufo^.Origin.X+1) or
  (Shot^.Origin.X = Ufo^.Origin.X+2))) then {ufo hit shot?}
  begin
    SetSound (@sndUfo,8);
    Shot^.Hide;
    Score := Score+500;
    DispScore;
    with Ufo^ do
    begin
      FramePos := 1;
      Origin.X := -Size.X;
      Dir.X := 1;
      Origin.Y := Random (Owner^.Size.Y-4)
    end
  end;
  if (Bomb^.State and sfVisible <> 0) and
  (Ship^.State and sfVisible <> 0) and
  (Bomb^.Origin.Y = Ship^.Origin.Y) and
  (((Bomb^.Origin.X = Ship^.Origin.X) or
  (Bomb^.Origin.X = Ship^.Origin.X+1) or
  (Bomb^.Origin.X = Ship^.Origin.X+2))) then {bomb hit ship?}
  begin
    Bomb^.Hide;
    gameState := gameState or gameShipHit
  end;
  if (Exp^.State and sfVisible <> 0) and
  (Ship^.State and sfVisible <> 0) and
  (Exp^.Origin.Y = Ship^.Origin.Y) and
  (((Exp^.Origin.X = Ship^.Origin.X) or
  (Exp^.Origin.X = Ship^.Origin.X+1) or
  (Exp^.Origin.X = Ship^.Origin.X+2))) then {ship hit bomb explosion?}
  begin
    Exp^.Hide;
    gameState := gameState or gameShipHit
  end
end;

{
Set up ship and shot and death head.
}

procedure TGameDlg.InitShip;

var

  B, R : TRect;
  P : TPoint;

begin
  AniGroup^.GetBounds (B);

  P.X := 0;
  P.Y := 0;
  R.Assign (B.B.X div 2-1,B.B.Y-2,B.B.X div 2+2,B.B.Y-1);
  Ship := New (PShipView, Init (R,@gameShip,P));
  Ship^.PalIndex := 38;
  AniGroup^.Insert (Ship);

  P.X := 0;
  P.Y := -1;
  R.Assign (B.A.X+1,B.A.Y,B.A.X+2,B.A.Y+1);
  Shot := New (PShotView, Init (R,@gameShot,P));
  Shot^.PalIndex := 39;
  Shot^.Hide;
  AniGroup^.Insert (Shot);

  R.Assign (0,0,5,4);
  P.X := 0;
  P.Y := 0;
  Head := New (PHeadView, Init (R,@gameHead,P));
  Head^.PalIndex := 38;
  Head^.Hide;
  Head^.DelayVal := 7;
  Head^.Delay := 7;
  AniGroup^.Insert (Head);
end;

{
Draw ship, shot and death head.  When death head hides then the ship returns.
}

procedure TGameDlg.DrawShip;

begin
  Ship^.CalcMove;
  Shot^.CalcMove;
  Head^.CalcMove;
  Ship^.DrawView;
  Shot^.DrawView;
  Head^.DrawView;
  if (Head^.State and sfVisible = 0) and
  (Ship^.State and sfVisible = 0) then   {if head and ship hidden show ship}
  begin
    Ship^.Origin.X := AniGroup^.Size.X div 2-1;
    Ship^.Dir.X := 0;
    Ship^.Show
  end
end;

{
Initilize all sprites.
}

procedure TGameDlg.InitSprites;

begin
  InitShip;
  InitUfo;
  NextLevel
end;

{
Draw all sprites and background.
}

procedure TGameDlg.DrawSprites;

begin
  AniGroup^.Lock;
  DrawInvaders;
  DrawUfo;
  DrawShip;
  AniGroup^.Last^.DrawView;
  AniGroup^.Unlock
end;

{
TGameOptsDlg allows you to customize ship controls and turn sound on/off.
}

constructor TGameOptsDlg.Init;

var

  R : TRect;
  Field : PInputLine;
  CheckBox : PCheckBoxesCF;

begin
  R.Assign (0,0,29,10);
  inherited Init (R,'Controls');

  R.Assign (10,2,13,3);
  Field := New(PInputLine,Init(R,1));
  Insert (Field);
  R.Assign(1,2,7,3);
  Insert (New (PLabel,Init (R,'~L~eft',Field)));

  R.Assign (10,3,13,4);
  Field := New(PInputLine,Init(R,1));
  Insert (Field);
  R.Assign(1,3,7,4);
  Insert (New (PLabel,Init (R,'~R~ight',Field)));

  R.Assign (10,4,13,5);
  Field := New(PInputLine,Init(R,1));
  Insert (Field);
  R.Assign(1,4,7,5);
  Insert (New (PLabel,Init (R,'~S~hoot',Field)));

  R.Assign (10,5,13,6);
  Field := New(PInputLine,Init(R,1));
  Insert (Field);
  R.Assign(1,5,7,6);
  Insert (New (PLabel,Init (R,'S~t~op',Field)));

  R.Assign (15,3,27,4);
  CheckBox := New (PCheckBoxesCF,Init(R,NewSItem ('On/Off',nil)));
  Insert (CheckBox);
  R.Assign(14,2,20,3);
  Insert (New (PLabel,Init (R,'Soun~d~',CheckBox)));

  R.Assign (2,7,12,9);
  Insert (New (PButton,Init (R,'O~K~',cmOk,bfDefault)));
  R.Assign (16,7,26,9);
  Insert (New (PButton,Init (R,'Cancel',cmCancel,bfNormal)))
end;

end.
