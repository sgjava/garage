{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

CyberTools API DLL import unit.
}

unit CyberAPI;

{$I APP.INC}

interface

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

var

  vgaPageLoc : array[0..7] of pointer;
  vgaChrTableLoc : array[0..7] of pointer;

implementation

procedure SetSeqCont; external 'VGA';
function GetSeqCont; external 'VGA';
procedure SetCRTCont; external 'VGA';
function GetCRTCont; external 'VGA';
procedure SetGraphCont; external 'VGA';
function GetGraphCont; external 'VGA';
procedure SetAttrCont; external 'VGA';
function GetAttrCont; external 'VGA';
procedure SetMiscOutput; external 'VGA';
function GetMiscOutput; external 'VGA';

{screen oritnted routines using low level access}

procedure WaitVertSync; external 'VGA';
procedure WaitDispEnable; external 'VGA';
procedure SetChrWidth8; external 'VGA';
procedure SetChrWidth9; external 'VGA';
function IsChrWidth9; external 'VGA';
procedure SetPage; external 'VGA';
procedure CopyScrMem; external 'VGA';

{256 color dac routines using low level access}

procedure SetDAC; external 'VGA';
procedure GetDAC; external 'VGA';
procedure SetDACBlock; external 'VGA';
procedure GetDACBlock; external 'VGA';
procedure FadeOutDAC; external 'VGA';
procedure FadeInDAC; external 'VGA';

{character generator routines using low level access}

procedure AccessFontMem; external 'VGA';
procedure AccessScreenMem; external 'VGA';
procedure FontMapSelect; external 'VGA';
procedure FontMapVal; external 'VGA';
procedure FontTableLoc; external 'VGA';
procedure SetRamTable; external 'VGA';
function GetRamTable; external 'VGA';
procedure SetTablePix; external 'VGA';
procedure DrawTableLine; external 'VGA';
procedure DrawTableEllipse; external 'VGA';

{routines using vga bios}

function VGACardActive; external 'VGA';
procedure BiosSetVideo; external 'VGA';

{attribute controller and 256 color dac routines using bios}

procedure BiosSetPalReg; external 'VGA';
function BiosGetPalReg; external 'VGA';
procedure BiosSetDAC; external 'VGA';
procedure BiosGetDAC; external 'VGA';
procedure BiosSetDACBlock; external 'VGA';
procedure BiosGetDACBlock; external 'VGA';

{character generator routines using bios}

procedure BiosFontMapSelect; external 'VGA';
function BiosGetChrHeight; external 'VGA';
function BiosGetRomTablePtr; external 'VGA';
function BiosCopyRomTable; external 'VGA';
procedure BiosSetChrTable; external 'VGA';
procedure BiosLoadFont; external 'VGA';
procedure BiosSetFont; external 'VGA';
procedure BiosLoad8X8Font; external 'VGA';
procedure BiosLoad8X14Font; external 'VGA';
procedure BiosLoad8X16Font; external 'VGA';
procedure BiosSet8X8Font; external 'VGA';
procedure BiosSet8X14Font; external 'VGA';
procedure BiosSet8X16Font; external 'VGA';

{mouse functions using int 33h}

procedure MouseTextMask; external 'VGA';

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

begin
  InitVGA
end.
