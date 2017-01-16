{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Color VGA low level access routines.  Check display type before using any
VGA dependent routines.

Added support for DOS DLL generation in CyberAPI.
}

{$I APP.INC}

{$IFDEF UseDLL}
library VGA;
{$ELSE}
unit VGA;
{$ENDIF}

{$IFNDEF UseDLL}
interface
{$ENDIF}

uses

{$IFDEF UseDLL}
  CyberAPI,
{$ENDIF}
  Memory;

{$IFNDEF UseDLL}
const

{color vga index and data ports}

  vgaAttrIndex          = $03c0;
  vgaAttrData           = $03c1;
    vgaAttrMode           = $10;
    vgaAttrOverscan       = $11;
    vgaAttrCPEnable       = $12;
    vgaAttrHorzPelPan     = $13;
    vgaAttrColorSel       = $14;
  vgaMiscOutWrite       = $03c2;
  vgaSeqIndex           = $03c4;
    vgaSeqReset           = $00;
    vgaSeqClockMode       = $01;
    vgaSeqMapMask         = $02;
    vgaSeqChrMapSel       = $03;
    vgaSeqMemMode         = $04;
  vgaDACPelMask         = $03c6;
  vgaDACRead            = $03c7;
  vgaDACWrite           = $03c8;
  vgaDACPelData         = $03c9;
  vgaMiscOutRead        = $03cc;
  vgaGraphIndex         = $03ce;
    vgaGraphReset         = $00;
    vgaGraphEnable        = $01;
    vgaGraphColorCmp      = $02;
    vgaGraphFuncSel       = $03;
    vgaGraphReadMap       = $04;
    vgaGraphMode          = $05;
    vgaGraphMisc          = $06;
    vgaGraphDontCare      = $07;
    vgaGraphBitMask       = $08;
  vgaCRTIndex           = $03d4;
    vgaCRTHorzTotal       = $00;
    vgaCRTHorzDispEnd     = $01;
    vgaCRTStartHorzBlank  = $02;
    vgaCRTEndHorzBlank    = $03;
    vgaCRTStartHorzRescan = $04;
    vgaCRTEndHorzRescan   = $05;
    vgaCRTVertTotal       = $06;
    vgaCRTOverflow        = $07;
    vgaCRTVertPelPan      = $08;
    vgaCRTMaxScanLine     = $09;
    vgaCRTCurStart        = $0a;
    vgaCRTCurEnd          = $0b;
    vgaCRTStartAddrHi     = $0c;
    vgaCRTStartAddrLo     = $0d;
    vgaCRTCurLocHi        = $0e;
    vgaCRTCurLocLo        = $0f;
    vgaCRTStartVertRescan = $10;
    vgaCRTEndVertRescan   = $11;
    vgaCRTVertDispEnd     = $12;
    vgaCRTOffset          = $13;
    vgaCRTUnderlineLoc    = $14;
    vgaCRTStartVertBlank  = $15;
    vgaCRTEndVertBlank    = $16;
    vgaCRTModeControl     = $17;
    vgaCRTLineCompare     = $18;
  vgaCRTStatus          = $03da;

{256 color palette}

  vgaRGBMax      = 2;
  vgaDACRegMax   = 255;
  vgaPaletteSize = 768;

{25 line vga text screen offsets and addrs}

  vgaPageOfsLoc : array[0..7] of word =
  ($0000,$0800,$1000,$1800,$2000,$2800,$3000,$3800);

  vgaPageLocOfs : array[0..7] of word =
  ($0000,$1000,$2000,$3000,$4000,$5000,$6000,$7000);

  vgaScrWidth = 80;
  vgaScrSize25 = 2000;
  vgaScrSize50 = 4000;

{character generator/fonts}

  vgaMaxChrTables = 8; {vga can only have 8 resident fonts at a time}
  vgaMaxChrHeight = 32;
  vgaMaxChrs      = 256;
  vgaChrTableSize = 8192;

{info byte used by bios int 10h, func 11h, subfunc 30h}

  vgaRom8x14    = 2; vgaRom8x8     = 3; vgaRomAlt8x8  = 4;
  vgaRomAlt9x14 = 5; vgaRom8x16    = 6; vgaRomAlt9x16 = 7;

{vga character table locations}

  vgaChrTableLocOfs : array[0..7] of word =
  ($0000,$4000,$8000,$c000,$2000,$6000,$a000,$e000);

{vga character map select settings}

  vgaChrTableMap1 : array[0..7] of byte =
  ($00,01,$02,$03,$10,$11,$12,$13);
  vgaChrTableMap2 : array[0..7] of byte =
  ($00,$04,$08,$0c,$20,$24,$28,$2c);

{use bit look up table for speed when accessing single character bits}

  vgaBitTable : array[0..7] of byte = (128,64,32,16,8,4,2,1);

{codes returned by bios for active and passive video cards}

  vgaNoCard   =  0; vgaMDAMDA    =  1; vgaCGACGA   = 2; vgaEGAEGA  =  4;
  vgaEGAMDA   =  5; vgaVGAMono   =  7; vgaVGAColor = 8; vgaMCGACGA = 10;
  vgaMCGAMono = 11; vgaMCGAColor = 12;

  vgaDataBufMax = 65519; {max misc graphics buffer size}

  vgaScr256Line = 320;   {length of bios 13h 256 color line}

type

  vgaDataBufPtr = ^vgaDataBuf;
  vgaDataBuf = array[0..vgaDataBufMax] of byte;
  vgaPalettePtr = ^vgaPalette;
  vgaPalette = array[0..vgaDACRegMax,0..vgaRGBMax] of byte;
  vgaChrTablePtr = ^vgaChrTable;
  vgaChrTable = array [0..vgaChrTableSize-1] of byte;
  vgaLine256 = array[0..319] of byte;         {mode 13h 256 color line}
  vgaScreen256 = array[0..199] of vgaLine256; {mode 13h 256 color screen}

{low level vga port access}

procedure SetSeqCont (IndexReg, DataReg : byte);
function GetSeqCont (IndexReg : byte) : byte;
procedure SetCRTCont (IndexReg, DataReg : byte);
function GetCRTCont (IndexReg : byte) : byte;
procedure SetGraphCont (IndexReg, DataReg : byte);
function GetGraphCont (IndexReg : byte) : byte;
procedure SetAttrCont (IndexReg, DataReg : byte);
function GetAttrCont (IndexReg : byte) : byte;
procedure SetMiscOutput (DataReg : byte);
function GetMiscOutput : byte;

{screen oritnted routines using low level access}

procedure WaitVertSync;
procedure WaitDispEnable;
procedure SetChrWidth8;
procedure SetChrWidth9;
function IsChrWidth9 : boolean;
procedure SetPage (StartOfs : word);
procedure CopyScrMem (Src, Dest : pointer; Len : word);

{256 color dac routines using low level access}

procedure SetDAC (RegNum, R, G, B : byte);
procedure GetDAC (RegNum : byte; var R, G, B : byte);
procedure SetDACBlock (PalPtr : pointer; StartReg, RegCnt : word);
procedure GetDACBlock (PalPtr : pointer; StartReg, RegCnt : word);
procedure FadeOutDAC (FadeInc : byte);
procedure FadeInDAC (DefPal : vgaPalettePtr; FadeInc : byte);

{character generator routines using low level access}

procedure AccessFontMem;
procedure AccessScreenMem;
procedure FontMapSelect (Font1, Font2 : byte);
procedure FontMapVal (MapSel : byte; var Font1, Font2 : byte);
procedure FontTableLoc (MapSel : byte; var Font1Ptr, Font2Ptr : pointer);
procedure SetRamTable (StartChr,TotalChrs,Height : word;
                       BufAddr, ChrAddr : vgaChrTablePtr);
function GetRamTable (StartChr,TotalChrs,Height : word;
                      ChrAddr : vgaChrTablePtr) : vgaChrTablePtr;
procedure SetTablePix (X,Y,XLen,Height : word;
                       ChrAddr : vgaChrTablePtr; PixOn : boolean);
procedure DrawTableLine (X1,Y1,X2,Y2,XLen,Height : integer;
                         ChrAddr : vgaChrTablePtr; PixOn : boolean);
procedure DrawTableEllipse (XC,YC,A,B,XLen,Height : integer;
                           ChrAddr : vgaChrTablePtr; PixOn : boolean);

{routines using vga bios}

function VGACardActive : boolean;
procedure BiosSetVideo (Mode : byte);

{attribute controller and 256 color dac routines using bios}

procedure BiosSetPalReg (RegNum, RegData : byte);
function BiosGetPalReg (RegNum : byte) : byte;
procedure BiosSetDAC (RegNum, R, G, B : byte);
procedure BiosGetDAC (RegNum : byte; var R, G, B : byte);
procedure BiosSetDACBlock (PalPtr : pointer; StartReg, RegCnt : word);
procedure BiosGetDACBlock (PalPtr : pointer; StartReg, RegCnt : word);

{character generator routines using bios}

procedure BiosFontMapSelect (Font1, Font2 : byte);
function BiosGetChrHeight : byte;
function BiosGetRomTablePtr (Info : byte) : pointer;
function BiosCopyRomTable (Info : byte) : vgaChrTablePtr;
procedure BiosSetChrTable (ChrTable : byte);
procedure BiosLoadFont (ChrData : pointer; ChrTable, ChrHeight :byte;
                        StartChr, NumChrs : word);
procedure BiosSetFont (ChrData : pointer; ChrTable, ChrHeight :byte;
                       StartChr, NumChrs : word);
procedure BiosLoad8X8Font (ChrTable : byte);
procedure BiosLoad8X14Font (ChrTable : byte);
procedure BiosLoad8X16Font (ChrTable : byte);
procedure BiosSet8X8Font (ChrTable : byte);
procedure BiosSet8X14Font (ChrTable : byte);
procedure BiosSet8X16Font (ChrTable : byte);

{mouse functions using int 33h}

procedure MouseTextMask (AndMask, XorMask : word);
{$ENDIF}

var

  vgaPageLoc : array[0..7] of pointer;
  vgaChrTableLoc : array[0..7] of pointer;

{$IFNDEF UseDLL}
implementation
{$ENDIF}

{low level vga port access}

procedure SetSeqCont (IndexReg, DataReg : byte); 
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     dx,vgaSeqIndex {sequencer controller index port}
  mov     al,IndexReg
  mov     ah,DataReg
  out     dx,ax          {set index/data at same time}
end;

function GetSeqCont (IndexReg : byte) : byte;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     dx,vgaSeqIndex {sequencer controller index port}
  mov     al,IndexReg
  out     dx,al          {index to read}
  inc     dx             {sequencer controller data port}
  in      al,dx
end;

procedure SetCRTCont (IndexReg, DataReg : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     dx,vgaCRTIndex {crt controller index port}
  mov     al,IndexReg
  mov     ah,DataReg
  out     dx,ax          {set index/data at same time}
end;

function GetCRTCont (IndexReg : byte) : byte;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     dx,vgaCRTIndex {crt controller index port}
  mov     al,IndexReg
  out     dx,al          {index to read}
  inc     dx             {crt controller data port}
  in      al,dx
end;

procedure SetGraphCont (IndexReg, DataReg : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     dx,vgaGraphIndex {graphics controller index port}
  mov     al,IndexReg
  mov     ah,DataReg
  out     dx,ax            {set index/data at same time}
end;

function GetGraphCont (IndexReg : byte) : byte;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     dx,vgaGraphIndex {graphics controller index port}
  mov     al,IndexReg
  out     dx,al            {index to read}
  inc     dx               {graphics controller data port}
  in      al,dx
end;

procedure SetAttrCont (IndexReg, DataReg : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  call    WaitVertSync    {wait until vertical sync active/reset attr cont to index mode}
  mov     dx,vgaAttrIndex {attribute controller combined index/data port}
  mov     al,IndexReg     {index with bit 5 clear to disconnect crt cont and attr cont}
  out     dx,al           {index to write}
  mov     al,DataReg
  out     dx,al           {write data to index}
  mov     dx,vgaCRTStatus {crt controller input status port}
  in      al,dx           {reset attribute controller to index instead of data}
  mov     dx,vgaAttrIndex {attribute controller combined index/data port}
  mov     al,20h          {set bit to connect crt cont and attr cont}
  out     dx,al
  call    WaitDispEnable  {wait until display enable active}
end;

function GetAttrCont (IndexReg : byte) : byte;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  call    WaitVertSync    {wait until vertical sync active/reset attr cont to index mode}
  mov     dx,vgaAttrIndex {attribute controller combined write index/data port}
  mov     al,IndexReg
  out     dx,al           {index to read}
  mov     dx,vgaAttrData  {attribute controller read data port}
  in      al,dx           {read data}
  xchg    al,ah           {save data}
  mov     dx,vgaCRTStatus {crt controller input status port}
  in      al,dx           {reset attribute controller to index instead of data}
  mov     dx,vgaAttrIndex {attribute controller combined index/data port}
  mov     al,20h          {set bit to connect crt cont and attr cont}
  out     dx,al
  call    WaitDispEnable  {wait until display enable active}
  xchg    al,ah
end;

procedure SetMiscOutput (DataReg : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     dx,vgaMiscOutWrite {misc output write port}
  mov     al,DataReg
  out     dx,al
end;

function GetMiscOutput : byte;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     dx,vgaMiscOutRead {misc output read port}
  in      al,dx
end;

{screen oritnted routines using low level access}

procedure WaitVertSync;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     dx,vgaCrtStatus
@rep1:                    {repeat}
  in      al,dx
  test    al,08h
  jz      @rep1           {until vert sync active}
end;

procedure WaitDispEnable;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     dx,vgaCrtStatus
@rep1:                    {repeat}
  in      al,dx
  test    al,08h
  jnz     @rep1           {until display enable active}
end;

procedure SetChrWidth8;
{$IFDEF UseDLL}
export;
{$ENDIF}

begin
  SetMiscOutput (GetMiscOutput and $f3); {640 horz pix, 25.175 mhz clock}
  SetSeqCont (vgaSeqReset,$01);          {seq cont reset 1}
  SetSeqCont (vgaSeqClockMode,$01);      {8 pix per clock}
  SetSeqCont (vgaSeqReset,$03);          {seq cont reset 1 and 2}
  SetAttrCont (vgaAttrHorzPelPan,$00)    {horz pel panning val for 8 pix}
end;

procedure SetChrWidth9;
{$IFDEF UseDLL}
export;
{$ENDIF}

begin
  SetMiscOutput (GetMiscOutput or $04); {720 horz pix, 28.322 mhz clock}
  SetSeqCont (vgaSeqReset,$01);         {seq cont reset 1}
  SetSeqCont (vgaSeqClockMode,$00);     {9 pix per clock}
  SetSeqCont (vgaSeqReset,$03);         {seq cont reset 1 and 2}
  SetAttrCont (vgaAttrHorzPelPan,$08)   {horz pel panning val for 9 pix}
end;

function IsChrWidth9 : boolean;
{$IFDEF UseDLL}
export;
{$ENDIF}

begin {true if 720 horz pix 28.322 mhz clock set}
  IsChrWidth9 := (GetMiscOutput and $0c) = $04
end;

procedure SetPage (StartOfs : word);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     bl,vgaCRTStartAddrLo   {bl = crtc start addr lo reg}
  mov     bh,byte ptr StartOfs   {bh = offest lo}
  mov     cl,vgaCRTStartAddrHi   {cl = crtc start addr hi reg}
  mov     ch,byte ptr StartOfs+1 {ch = offset hi}
  call    WaitDispEnable         {wait until display enable active}
  mov     dx,vgaCRTIndex         {dx = crtc addr reg}
  mov     ax,bx                  {ax = crtc start addr lo}
  out     dx,ax
  mov     ax,cx                  {ax = crtc start addr hi}
  out     dx,ax
end;

procedure CopyScrMem (Src, Dest : pointer; Len : word);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  push    ds      {save ds}
  lds     si,Src  {ds:si = source addr}
  les     di,Dest {es:di = dest addr}
  mov     cx,Len  {cx = words to fill}
  cld             {inc si and di}
  rep     movsw   {copy words}
  pop     ds      {restore ds}
end;

{256 color dac routines using low level access}

procedure SetDAC (RegNum, R, G, B : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  call    WaitVertSync   {wait until vertical sync active}
  mov     dx,vgaDACWrite {dac pel write address port}
  mov     al,RegNum      {dac register to write}
  out     dx,al
  inc     dx             {dac pel data port}
  mov     al,R           {write rgb data}
  out     dx,al
  mov     al,G
  out     dx,al
  mov     al,B
  out     dx,al
  call    WaitDispEnable {wait until display enable active}
end;

procedure GetDAC (RegNum : byte; var R, G, B : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  call    WaitVertSync     {wait until vertical sync active}
  mov     dx,vgaDACRead    {dac pel read address port}
  mov     al,RegNum        {dac register to write}
  out     dx,al
  mov     dx,vgaDACPelData {dac pel data port}
  in      al,dx
  les     di,R             {es:di = @r}
  mov     es:[di],al       {r = red val}
  in      al,dx
  les     di,G             {es:di = @g}
  mov     es:[di],al       {g = green val}
  in      al,dx
  les     di,B             {es:di = @b}
  mov     es:[di],al       {b = blue val}
  call    WaitDispEnable   {wait until display enable active}
end;

procedure SetDACBlock (PalPtr : pointer; StartReg, RegCnt : word);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  les     si,PalPtr        {palette pointer}
  mov     bl,3             {break up into 3 loops to prevent flicker}
  mov     ax,StartReg      {first dac register to set}
  mov     dx,vgaDACWrite   {dac pel write address port}
  out     dx,al
@rep1:                     {repeat}
  mov     cx,RegCnt        { number of dac registers to set}
  call    WaitVertSync     { wait until vertical sync active}
  mov     dx,vgaDACPelData { dac pel data port}
@rep2:                     { repeat}
  mov     al,es:[si]       {  al = dac register setting}
  out     dx,al
  inc     si               {  si = si+1}
  loop    @rep2            { cx = cx-1; until cx = 0}
  call    WaitDispEnable   { wait until display enable active}
  dec     bl               { bl = bl -1}
  jnz     @rep1            {until bl = 0}
end;

procedure GetDACBlock (PalPtr : pointer; StartReg, RegCnt : word);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  les     si,PalPtr        {palette pointer}
  mov     bl,3             {break up into 3 loops to prevent flicker}
  mov     ax,StartReg      {first dac register to read}
  mov     dx,vgaDACRead    {dac pel read address port}
  out     dx,al
@rep1:                     {repeat}
  mov     cx,RegCnt        { number of dac registers to set}
  call    WaitVertSync     { wait until vertical sync active}
  mov     dx,vgaDACPelData { dac pel data port}
@rep2:                     { repeat}
  in      al,dx            {  al = dac register setting}
  mov     es:[si],al       {  move into palette}
  inc     si               {  si = si+1}
  loop    @rep2            { cx = cx-1; until cx = 0}
  call    WaitDispEnable   { wait until display enable active}
  dec     bl               { bl = bl-1}
  jnz     @rep1            {until bl = 0}
end;

procedure FadeOutDAC (FadeInc : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}

var

  EndFlag : boolean;
  Rgb, Dac : byte;
  CurPal : vgaPalette;

begin {decrement all dac regs until all dac regs = 0}
  GetDACBlock (@CurPal,0,256);
  repeat
    EndFlag := true;
    for Dac := 0 to vgaDACRegMax do
      for Rgb := 0 to vgaRGBMax do
        if CurPal[Dac,Rgb] >= FadeInc then
        begin
          Dec (CurPal[Dac,Rgb],FadeInc);
          EndFlag := false
        end
        else
          CurPal[Dac,Rgb] := 0;
    SetDACBlock (@CurPal,0,256)
  until EndFlag
end;

procedure FadeInDAC (DefPal : vgaPalettePtr; FadeInc : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}

var

  EndFlag : boolean;
  Rgb, Dac : byte;
  CurPal : vgaPalette;

begin {inc all dac regs until all dac regs = default palette}
  GetDACBlock (@CurPal,0,256);
  repeat
    EndFlag := true;
    for Dac := 0 to vgaDACRegMax do
      for Rgb := 0 to vgaRGBMax do
        if CurPal[Dac,Rgb] <= DefPal^[Dac,Rgb]-FadeInc then
        begin
          Inc (CurPal[Dac,Rgb],FadeInc);
          EndFlag := false
        end
        else
          CurPal[Dac,Rgb] := DefPal^[Dac,Rgb];
    SetDACBlock (@CurPal,0,256)
  until EndFlag
end;

{character generator routines using low level access}

procedure AccessFontMem;
{$IFDEF UseDLL}
export;
{$ENDIF}

begin
  asm
    pushf {disable interrupts}
    cli
  end;
  SetSeqCont (vgaSeqMemMode,$07);     {256k, linear mode, chain 4}
  SetGraphCont (vgaGraphReadMap,$02); {use latch 2 for cpu reads}
  SetGraphCont (vgaGraphMode,$00);    {read mode 0, linear access, not 256 color}
  SetGraphCont (vgaGraphMisc,$04);    {text mode, linear access, video ram at a000h}
  SetSeqCont (vgaSeqMapMask,$04);     {access bitplane #2}
  asm
    popf {enable interrupts}
  end
end;

procedure AccessScreenMem;
{$IFDEF UseDLL}
export;
{$ENDIF}

begin
  asm
    pushf {disable interrupts}
    cli
  end;
  SetSeqCont (vgaSeqMapMask,$03);     {access bitplane #0 and #1}
  SetSeqCont (vgaSeqMemMode,$03);     {256k, odd/even mode, chain 4}
  SetGraphCont (vgaGraphReadMap,$00); {use latch 0 for cpu reads}
  SetGraphCont (vgaGraphMode,$10);    {read mode 0, odd/even addr, not 256 color}
  SetGraphCont (vgaGraphMisc,$0e);    {text mode, odd/even addr, video ram at b800h}
  asm
    popf {enable interrupts}
  end
end;

procedure FontMapSelect (Font1, Font2 : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}

begin {set map select for both fonts}
  SetSeqCont (vgaSeqChrMapSel,Font1 or Font2)
end;

procedure FontMapVal (MapSel : byte; var Font1, Font2 : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}

begin {convert map select into linear value 0 - 7}
  Font1 := ((MapSel and $10) shr 2) or (MapSel and $03);
  Font2 := ((MapSel and $20) shr 3) or ((MapSel and $0c) shr 2)
end;

procedure FontTableLoc (MapSel : byte; var Font1Ptr, Font2Ptr : pointer);
{$IFDEF UseDLL}
export;
{$ENDIF}

var

  Font1, Font2 : byte;

begin {convert map select value to pointers of table location}
  FontMapVal (MapSel,Font1,Font2);
  Font1Ptr := vgaChrTableLoc[Font1];
  Font2Ptr := vgaChrTableLoc[Font2]
end;

{
Set character table from system ram.
}

procedure SetRamTable (StartChr,TotalChrs,Height : word;
                       BufAddr, ChrAddr : vgaChrTablePtr);
{$IFDEF UseDLL}
export;
{$ENDIF}

var

  ChrCode, ChrEle : word;

begin
  for ChrCode := 0 to TotalChrs-1 do
    for ChrEle := 0 to Height-1 do
      ChrAddr^[(ChrCode+StartChr)*vgaMaxChrHeight+ChrEle] :=
      BufAddr^[ChrCode*Height+ChrEle]
end;

{
Get character table from vga ram.
}

function GetRamTable (StartChr,TotalChrs,Height : word;
                      ChrAddr : vgaChrTablePtr) : vgaChrTablePtr;
{$IFDEF UseDLL}
export;
{$ENDIF}

var

  ChrCode, ChrEle : word;
  ChrTablePtr : vgaChrTablePtr;

begin
  ChrTablePtr := MemAlloc (Height*TotalChrs);
  if ChrTablePtr <> nil then
  begin
    for ChrCode := 0 to TotalChrs-1 do
      for ChrEle := 0 to Height-1 do
        ChrTablePtr^[ChrCode*Height+ChrEle] :=
        ChrAddr^[(ChrCode+StartChr)*vgaMaxChrHeight+ChrEle]
  end;
  GetRamTable := ChrTablePtr
end;

{
Set/clear pixel in character table.  Pixel look up table implemented for
speed.
}

procedure SetTablePix (X,Y,XLen,Height : word;
                       ChrAddr : vgaChrTablePtr; PixOn : boolean);
{$IFDEF UseDLL}
export;
{$ENDIF}

var

  ChrCode, ChrEle : word;

begin
  ChrCode := (X shr 3)+(Y div Height*XLen); {char code}
  ChrEle := Y mod Height;                   {char byte}
  if PixOn then
    ChrAddr^[ChrCode*vgaMaxChrHeight+ChrEle] :=
    ChrAddr^[ChrCode*vgaMaxChrHeight+ChrEle] or
    vgaBitTable[(X and 7)]                  {set pix}
  else
    ChrAddr^[ChrCode*vgaMaxChrHeight+ChrEle] :=
    ChrAddr^[ChrCode*vgaMaxChrHeight+ChrEle] and not
    vgaBitTable[(X and 7)]                  {clear pix}
end;

{
Draw line in character table using modified bresenham's (DDA) algorithm.
}

procedure DrawTableLine (X1,Y1,X2,Y2,XLen,Height : integer;
                         ChrAddr : vgaChrTablePtr; PixOn : boolean);
{$IFDEF UseDLL}
export;
{$ENDIF}

var

  DX, DY, X, Y, XInc, YInc, C, R : integer;

begin
  XInc := 1;
  DX := X2-X1; {delta x}
  if DX < 0 then
  begin        {adjust for negative delta}
    XInc := -1;
    DX := -DX
  end;
  DY := Y2-Y1; {delta y}
  if DY < 0 then
  begin        {adjust for negative delta}
    YInc := -1;
    DY := -DY
  end
  else
    if DY > 0 then
      YInc := 1
    else
      YInc := 0;
  X := X1;
  Y := Y1;
  SetTablePix (X,Y,XLen,Height,ChrAddr,PixOn); {set first point}
  if DX > DY then {always draw with positive increment}
  begin
    R := DX shr 1;
    for C := 1 to DX do
    begin
      X := X+XInc;
      R := R+DY;
      if R >= DX then
      begin
        Y := Y+YInc;
        R := R-DX
      end;
      SetTablePix (X,Y,XLen,Height,ChrAddr,PixOn)
    end
  end
  else
  begin
    R := DY shr 1;
    for C := 1 to DY do
    begin
      Y := Y+YInc;
      R := R+DX;
      if R >= DY then
      begin
        X := X+XInc;
        R := R-DY
      end;
      SetTablePix (X,Y,XLen,Height,ChrAddr,PixOn)
    end
  end
end;

{
Draw ellipse in char table using digital differential analyzer (DDA) method.
}

procedure DrawTableEllipse (XC,YC,A,B,XLen,Height : integer;
                            ChrAddr : vgaChrTablePtr; PixOn : boolean);
{$IFDEF UseDLL}
export;
{$ENDIF}

var

  X, Y : integer;
  AA, AA2, YAA2,
  BB, BB2, XBB2,
  ErrVal : longint;

begin
  AA := longint (A)*A; {a^2}
  BB := longint (B)*B; {b^2}
  AA2 := AA shl 1;     {2(a^2)}
  BB2 := BB shl 1;     {2(b^2)}
  X := 0;
  Y := B;
  XBB2 := 0;
  YAA2 := Y*AA2;
  ErrVal := -Y*AA;      {b^2 x^2 + a^2 y^2 - a^2 b^2 - a^2y}
  while XBB2 <= YAA2 do {draw octant from top to top right}
  begin
    SetTablePix (XC+X,YC+Y,XLen,Height,ChrAddr,PixOn);
    SetTablePix (XC+X,YC-Y,XLen,Height,ChrAddr,PixOn);
    SetTablePix (XC-X,YC+Y,XLen,Height,ChrAddr,PixOn);
    SetTablePix (XC-X,YC-Y,XLen,Height,ChrAddr,PixOn);
    Inc (X);
    XBB2 := XBB2+BB2;
    ErrVal := ErrVal+XBB2-BB;
    if ErrVal >= 0 then
    begin
      Dec (Y);
      YAA2 := YAA2-AA2;
      ErrVal := ErrVal-YAA2
    end
  end;
  X := A;
  Y := 0;
  XBB2 := X*BB2;
  YAA2 := 0;
  ErrVal := -X*BB;     {b^2 x^2 + a^2 y^2 - a^2 b^2 - b^2x}
  while XBB2 > YAA2 do {draw octant from right to top right}
  begin
    SetTablePix (XC+X,YC+Y,XLen,Height,ChrAddr,PixOn);
    SetTablePix (XC+X,YC-Y,XLen,Height,ChrAddr,PixOn);
    SetTablePix (XC-X,YC+Y,XLen,Height,ChrAddr,PixOn);
    SetTablePix (XC-X,YC-Y,XLen,Height,ChrAddr,PixOn);
    Inc (Y);
    YAA2 := YAA2+AA2;
    ErrVal := ErrVal+YAA2-AA;
    if ErrVal >= 0 then
    begin
      Dec (X);
      XBB2 := XBB2-BB2;
      ErrVal := ErrVal-XBB2
    end
  end
end;

{routines using vga bios}

function VGACardActive : boolean;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1a00h   {ah = func 1ah, al = sub func 00h active/passive video card}
  int     10h        {bios int}
  xchg    al,ah
  sub     al,al      {al = 0 false}
  cmp     ah,1ah
  jnz     @endif1
  cmp     bl,vgaVGAColor
  jnz     @endif1
  inc     al         {al = 1 true}
@endif1:
end;

procedure BiosSetVideo (Mode : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  sub     ah,ah   {ah = func 00h set video mode}
  mov     al,Mode {al = video mode}
  int     10h     {bios int}
end;

{attribute controller and 256 color dac routines using bios}

procedure BiosSetPalReg (RegNum, RegData : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1000h   {ah = func 10h, al = subfunc 00 set palette reg}
  mov     bh,RegData {bh = register settings}
  mov     bl,RegNum  {bl = palette reg}
  int     10h        {bios int}
end;

function BiosGetPalReg (RegNum : byte) : byte;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     bl,RegNum {bl = palette reg}
  mov     ax,1007h  {ah = func 10h, al = subfunc 07h get palette reg}
  int     10h       {bios int}
  mov     al,bh
end;

procedure BiosSetDAC (RegNum, R, G, B : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  xor     bh,bh     {bh = 0}
  mov     bl,RegNum {bx = palette reg}
  mov     ax,1010h  {ah = func 10h, al = subfunc 10h set dac register}
  mov     dh,R      {dh = red}
  mov     ch,G      {ch = green}
  mov     cl,B      {cl = blue}
  int     10h       {bios int}
end;

procedure BiosGetDAC (RegNum : byte; var R, G, B : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  xor     bh,bh      {bh = 0}
  mov     bl,RegNum  {bx = palette reg}
  mov     ax,1015h   {ah = func 10h, al = subfunc 10h get dac register}
  int     10h        {bios int}
  les     di,R       {es:di = @r}
  mov     es:[di],dh {r = red val}
  les     di,G       {es:di = @g}
  mov     es:[di],ch {g = green val}
  les     di,B       {es:di = @b}
  mov     es:[di],cl {b = blue val}
end;

procedure BiosSetDACBlock (PalPtr : pointer; StartReg, RegCnt : word);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1012h        {ah = func 10h, al = sub func 12h set block of dac registers}
  mov     bx,StartReg     {bx = starting register}
  mov     cx,RegCnt       {cx = number of registers}
  les     dx,PalPtr       {es:dx = palette addr}
  int     10h             {bios int}
end;

procedure BiosGetDACBlock (PalPtr : pointer; StartReg, RegCnt : word);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1017h        {ah = func 10h, al = subfunc 17h read block of dac registers}
  mov     bx,StartReg     {bx = starting register}
  mov     cx,RegCnt       {cx = number of registers}
  les     dx,PalPtr       {es:dx = palette addr}
  int     10h
end;

{character generator routines using bios}

procedure BiosFontMapSelect (Font1, Font2 : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1103h {ah = func 11h, al = subfunc 3 set chr map select}
  mov     bl,font1 {bl = font 1}
  or      bl,font2 {bl = bl or font 2}
  int     10h      {bios int}
end;


function BiosGetChrHeight : byte;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1130h {ah = func 11h, al = subfunc 30 sys info}
  mov     bh,6     {bh = get chr table height}
  push    bp       {save bp}
  int     10h      {bios int}
  pop     bp       {restore bp}
  mov     ax,cx    {ax = cx current bytes per chr}
end;

function BiosGetRomTablePtr (Info : byte) : pointer;
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1130h {ah = func 11h, al = subfunc 30 sys info}
  mov     bh,Info  {bh = type of info}
  push    bp       {save bp}
  int     10h      {bios int}
  mov     ax,bp    {ax = bp chr table ofs}
  pop     bp       {restore bp}
  mov     dx,es    {dx = es chr table seg}
end;

function BiosCopyRomTable (Info : byte) : vgaChrTablePtr;
{$IFDEF UseDLL}
export;
{$ENDIF}

var

  Hgt : word;
  Src, Dest : vgaChrTablePtr;

begin {copy rom font to ram}
  Src := BiosGetRomTablePtr (Info);
  Dest := nil;
  case Info of
    vgaRom8x8     : Hgt := 8;
    vgaRomAlt8x8  : Hgt := 8;
    vgaRom8x14    : Hgt := 14;
    vgaRomAlt9x14 : Hgt := 14;
    vgaRom8x16    : Hgt := 16;
    vgaRomAlt9x16 : Hgt := 16
  end;
  Dest := MemAlloc (Hgt*vgaMaxChrs);
  if Dest <> nil then
    Move (Src^,Dest^,Hgt*vgaMaxChrs);
  BiosCopyRomTable := Dest
end;

procedure BiosSetChrTable (ChrTable : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1103h    {ah = func 11h, al = subfunc 03h}
  mov     bl,ChrTable {bl = chr table}
  int     10h         {bios int}
end;

procedure BiosLoadFont (ChrData : pointer; ChrTable, ChrHeight :byte;
                        StartChr, NumChrs : word);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1100h     {ah = func 11h, al = subfunc 00h}
  mov     bh,ChrHeight {bh = chr height}
  mov     bl,ChrTable  {bl = chr table}
  mov     cx,NumChrs   {cx = num of chrs}
  mov     dx,StartChr  {dx = starting chr}
  les     si,ChrData   {es:si = chr data start addr}
  push    bp           {save bp}
  mov     bp,si        {bp = chr data start ofs}
  int     10h          {bios int}
  pop     bp           {restore bp}
end;

procedure BiosSetFont (ChrData : pointer; ChrTable, ChrHeight :byte;
                       StartChr, NumChrs : word);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1110h     {ah = func 11h, al = subfunc 10h}
  mov     bh,ChrHeight {bh = chr height}
  mov     bl,ChrTable  {bl = chr table}
  mov     cx,NumChrs   {cx = num of chrs}
  mov     dx,StartChr  {dx = starting chr}
  les     si,ChrData   {es:si = chr data start addr}
  push    bp           {save bp}
  mov     bp,si        {bp = chr data start ofs}
  int     10h          {bios int}
  pop     bp           {restore bp}
end;

procedure BiosLoad8X8Font (ChrTable : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1102h    {ah = func 11h, al = subfunc 02h}
  mov     bl,ChrTable {bl = chr table}
  int     10h         {bios int}
end;

procedure BiosLoad8X14Font (ChrTable : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1101h    {ah = func 11h, al = subfunc 01h}
  mov     bl,ChrTable {bl = chr table}
  int     10h         {bios int}
end;

procedure BiosLoad8X16Font (ChrTable : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1104h    {ah = func 11h, al = subfunc 04h}
  mov     bl,ChrTable {bl = chr table}
  int     10h         {bios int}
end;

procedure BiosSet8X8Font (ChrTable : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1112h    {ah = func 11h, al = subfunc 12h}
  mov     bl,ChrTable {bl = chr table}
  int     10h         {bios int}
end;

procedure BiosSet8X14Font (ChrTable : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1111h    {ah = func 11h, al = subfunc 11h}
  mov     bl,ChrTable {bl = chr table}
  int     10h         {bios int}
end;

procedure BiosSet8X16Font (ChrTable : byte);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,1114h    {ah = func 11h, al = subfunc 14h}
  mov     bl,ChrTable {bl = chr table}
  int     10h         {bios int}
end;

{mouse functions using int 33h}

procedure MouseTextMask (AndMask, XorMask : word);
{$IFDEF UseDLL}
export;
{$ENDIF}
assembler;

asm
  mov     ax,0ah     {set bit mask for text cursor}
  sub     bx,bx
  mov     cx,AndMask {and mask}
  mov     dx,XorMask {xor mask}
  int     33h        {mouse interrupt}
end;

procedure InitVGA; {set up vga mem pointers to work in protected mode too}

var

  I : byte;

begin
  for I := 0 to 7 do
  begin
    vgaPageLoc[I] := Ptr (SegB800,vgaPageLocOfs[I]);
    vgaChrTableLoc[I] := Ptr (SegA000,vgaChrTableLocOfs[I])
  end
end;

{$IFDEF UseDLL}
exports

  SetSeqCont,
  GetSeqCont,
  SetCRTCont,
  GetCRTCont,
  SetGraphCont,
  GetGraphCont,
  SetAttrCont,
  GetAttrCont,
  SetMiscOutput,
  GetMiscOutput,

  {screen oritnted routines using low level access}

  WaitVertSync,
  WaitDispEnable,
  SetChrWidth8,
  SetChrWidth9,
  IsChrWidth9,
  SetPage,
  CopyScrMem,

  {256 color dac routines using low level access}

  SetDAC,
  GetDAC,
  SetDACBlock,
  GetDACBlock,
  FadeOutDAC,
  FadeInDAC,

  {character generator routines using low level access}

  AccessFontMem,
  AccessScreenMem,
  FontMapSelect,
  FontMapVal,
  FontTableLoc,
  SetRamTable,
  GetRamTable,
  SetTablePix,
  DrawTableLine,
  DrawTableEllipse,

  {routines using vga bios}

  VGACardActive,
  BiosSetVideo,

  {attribute controller and 256 color dac routines using bios}

  BiosSetPalReg,
  BiosGetPalReg,
  BiosSetDAC,
  BiosGetDAC,
  BiosSetDACBlock,
  BiosGetDACBlock,

  {character generator routines using bios}

  BiosFontMapSelect,
  BiosGetChrHeight,
  BiosGetRomTablePtr,
  BiosCopyRomTable,
  BiosSetChrTable,
  BiosLoadFont,
  BiosSetFont,
  BiosLoad8X8Font,
  BiosLoad8X14Font,
  BiosLoad8X16Font,
  BiosSet8X8Font,
  BiosSet8X14Font,
  BiosSet8X16Font,

  {mouse functions using int 33h}

  MouseTextMask;
{$ENDIF}

begin
  InitVGA
end.
