library VGADLL;

uses

  VGA;

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

begin
end.
