{
SG Tools (C) 1992 Parsec, Inc.

VDC Screen Manager
}

{VDC current settings record}

type

  TVDC = record
    RamType,
    Version,
    ScreenColor,
    CursorTop,
    CursorBottom,
    Mode : byte;
    ScrHorz,
    ScrVert,
    ScrSize,
    DispMem,
    AttrMem,
    DispPage1,
    AttrPage1,
    DispPage2,
    AttrPage2,
    CharDefMem,
    BitMap : integer
  end;

{Global VDC screen manager vars}

var

  vdcSettings : TVDC;

{map current VDC layout}

procedure MapVDC;

begin
  with vdcSettings do
  begin
    DispMem := ReadVDC (vdcDispStartAddrHi)*256+
               ReadVDC (vdcDispStartAddrLo);
    AttrMem := ReadVDC (vdcAttrStartAddrHi)*256+
               ReadVDC (vdcAttrStartAddrLo);
    if (ReadVDC (vdcCharTotalVert) and $1f) > $0f then
      CharDefMem :=
      (ReadVDC (vdcCharSetStartAddr) and $c0)*256
    else
      CharDefMem :=
      (ReadVDC (vdcCharSetStartAddr) and $e0)*256;
    BitMap := 0
  end
end;

{fill VDC memory}

procedure FillMemVDC (FillMem, FillLen : integer;
                      Filler : byte);

var

  Blocks, Remain, I : byte;

begin
  WriteVDC (vdcUpdateAddrHi,HI (FillMem));  {start hi}
  WriteVDC (vdcUpdateAddrLo,LO (FillMem));  {start lo}
  WriteVDC (vdcVertSmoothScroll,            {block write feature}
  ReadVDC (vdcVertSmoothScroll) and $7f);
  WriteVDC (vdcCPUData,Filler);             {byte to block write}
  if FillLen > vdcMaxBlock then
  begin
    Blocks := FillLen div vdcMaxBlock;
    Remain := FillLen mod vdcMaxBlock;
    for I := 1 to Blocks do
      WriteVDC (vdcWordCount,vdcMaxBlock); {write blocks}
    if Remain > 1 then
      WriteVDC (vdcWordCount,Remain-1)     {write block remaining}
  end
  else
    if FillLen > 1 then
      WriteVDC (vdcWordCount,FillLen-1);   {write block}
end;

{copy VDC memory to VDC memory}

procedure CopyMemVDC (SMem, DMem, CopyLen : integer);

var

  Blocks, Remain, I : byte;

begin
  WriteVDC (vdcUpdateAddrHi,Hi (DMem));
  WriteVDC (vdcUpdateAddrLo,Lo (DMem));
  WriteVDC (vdcVertSmoothScroll,
  ReadVDC (vdcVertSmoothScroll) or $80);     {block copy}
  WriteVDC (vdcBlockCopySourceAddrHi,Hi (SMem));
  WriteVDC (vdcBlockCopySourceAddrLo,Lo (SMem));
  if CopyLen > vdcMaxBlock then
  begin
    Blocks := CopyLen div vdcMaxBlock;
    Remain := CopyLen mod vdcMaxBlock;
    for I := 1 to Blocks do
      WriteVDC (vdcWordCount,vdcMaxBlock);   {copy blocks}
    if Remain > 0 then
      WriteVDC (vdcWordCount,Remain)         {copy block remaining}
  end
  else
    if CopyLen > 0 then
      WriteVDC (vdcWordCount,CopyLen)        {copy block}
end;

{set VDC display and attribute start}

procedure SetDispPageVDC (DP, AP : integer);

begin
  WriteVDC (vdcDispStartAddrHi,Hi (DP));
  WriteVDC (vdcDispStartAddrLo,Lo (DP));
  WriteVDC (vdcAttrStartAddrHi,Hi (AP));
  WriteVDC (vdcAttrStartAddrLo,Lo (AP))
end;

{copy VDC display and attribute memory to VDC memory}

procedure CopyDispVDC (SDP, SAP, DDP, DAP : integer);

begin
  CopyMemVDC (SDP,DDP,vdcSettings.ScrSize);
  CopyMemVDC (SAP,DAP,vdcSettings.ScrSize)
end;

{set new display start, update pointers and copy new screen to old}

procedure FlipPageVDC;

begin
  with vdcSettings do
  begin
    SetDispPageVDC (DispMem,AttrMem);
    if DispMem = DispPage1 then
    begin
      DispMem := DispPage2;
      AttrMem := AttrPage2;
      CopyDispVDC (DispPage1,AttrPage1,DispPage2,AttrPage2)
    end
    else
    begin
      DispMem := DispPage1;
      AttrMem := AttrPage1;
      CopyDispVDC (DispPage2,AttrPage2,DispPage1,AttrPage1)
    end
  end
end;

{set cursor top, bottom and mode}

procedure SetCursorVDC (Top, Bottom, Mode : byte);

begin
  Mode := Mode shl 5;
  Top := Top or Mode;
  WriteVDC (vdcCurStartScanLine,Top);
  WriteVDC (vdcCurEndScanLine,Bottom)
end;

{fill VDC display screen with byte}

procedure ClrScrVDC (Ch : byte);

begin
  FillMemVDC (vdcSettings.DispMem,vdcSettings.ScrSize,Ch)
end;

{fill VDC attribute screen with byte}

procedure ClrAttrVDC (Attr : byte);

begin
  FillMemVDC (vdcSettings.AttrMem,vdcSettings.ScrSize,Attr)
end;

{set VDC screen fore/background color}

procedure SetScrColVDC (BgCol, FgCol : byte);

begin
  WriteVDC (vdcFgBgColor,FgCol*16+BgCol)
end;

{initilize settings record}

procedure InitVDC;

begin
  MapVDC;
  with vdcSettings do
  begin
    Version := PortIn ($d600) and $07;
    RamType := ReadVDC (vdcCharSetStartAddr) and vdcRam4164;
    ScreenColor := ReadVDC (vdcFgBgColor);
    CursorTop := ReadVDC (vdcCurStartScanLine);
    CursorBottom := ReadVDC (vdcCurEndScanLine);
    Mode := ReadVDC (vdcHorzSmoothScroll);
    ScrHorz := ReadVDC (vdcHorzDisp);
    ScrVert := ReadVDC (vdcVertDisp);
    ScrSize := ScrHorz*ScrVert;
    DispPage1 := DispMem;
    AttrPage1 := AttrMem;
    DispPage2 := AttrPage1+$0800;
    AttrPage2 := DispPage2+$0800
  end
end;

{restore important VDC registers}

procedure DoneVDC;

begin
  with vdcSettings do
  begin
    SetDispPageVDC (DispPage1,AttrPage1);
    WriteVDC (vdcFgBgColor,ScreenColor);
    WriteVDC (vdcCurStartScanLine,CursorTop);
    WriteVDC (vdcCurEndScanLine,CursorBottom);
    WriteVDC (vdcHorzSmoothScroll,Mode)
  end
end;
