{
SG Tools (C) 1992 Parsec, Inc.

Common VDC constants
}

const

{VDC registers}

  vdcHorzTotal             = 0;  vdcHorzDisp              = 1;
  vdcHorzSyncPos           = 2;  vdcVertHorzSyncWidth     = 3;
  vdcVertTotal             = 4;  vdcVertTotalAdj          = 5;
  vdcVertDisp              = 6;  vdcVertSyncPos           = 7;
  vdcInterlaceMode         = 8;  vdcCharTotalVert         = 9;
  vdcCurStartScanLine      = 10; vdcCurEndScanLine        = 11;
  vdcDispStartAddrHi       = 12; vdcDispStartAddrLo       = 13;
  vdcCurPosHi              = 14; vdcCurPosLo              = 15;
  vdcLightPenVert          = 16; vdcLightPenHorz          = 17;
  vdcUpdateAddrHi          = 18; vdcUpdateAddrLo          = 19;
  vdcAttrStartAddrHi       = 20; vdcAttrStartAddrLo       = 21;
  vdcCharDispHorz          = 22; vdcCharDispVert          = 23;
  vdcVertSmoothScroll      = 24; vdcHorzSmoothScroll      = 25;
  vdcFgBgColor             = 26; vdcAddrIncPerRow         = 27;
  vdcCharSetStartAddr      = 28; vdcUnderlineScanLineCnt  = 29;
  vdcWordCount             = 30; vdcCPUData               = 31;
  vdcBlockCopySourceAddrHi = 32; vdcBlockCopySourceAddrLo = 33;
  vdcDispEnableStart       = 34; vdcDispEnableEnd         = 35;
  vdcRamRefresh            = 36;

{VDC cursor modes}

  vdcCurSolid  = 0; vdcCurNone   = 1; vdcCurRate16 = 2; vdcCurRate32 = 3;

{VDC display attributes}

  vdcAltChrSet = $80; vdcRvsVid    = $40; vdcUnderline = $20; vdcBlink     = $10;
  vdcRed       = $08; vdcGreen     = $04; vdcBlue      = $02; vdcIntensity = $01;

{VDC RGB colors}

  vdcBlack       = 0;  vdcDarkGray    = 1;  vdcDarkBlue    = 2;  vdcLightBlue   = 3;
  vdcDarkGreen   = 4;  vdcLightGreen  = 5;  vdcDarkCyan    = 6;  vdcLightCyan   = 7;
  vdcDarkRed     = 8;  vdcLightRed    = 9;  vdcDarkPurple  = 10; vdcLightPurple = 11;
  vdcDarkYellow  = 12; vdcLightYellow = 13; vdcMediumGray  = 14; vdcWhite       = 15;

{VDC ram types}

  vdcRam4416 = $00; vdcRam4164 = $10;

{VDC version}

  vdcVer7a = 0; vdcVer8  = 1; vdcVer9  = 1;

{VDC max sizes}

  vdcMaxBlock = 255;
