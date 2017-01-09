{
SG Tools Pro (C) 1992 Steve Goldsmith

VDC interlace manager
}

procedure Use64KVDC;

begin
  WriteVDC (vdcCharSetStartAddr,
  ReadVDC (vdcCharSetStartAddr) or $10)
end;

procedure SetCharDefMem (MemLoc : integer);

begin
  vdcSettings.CharDefMem := Memloc;
  WriteVDC (vdcCharSetStartAddr,
  (ReadVDC (vdcCharSetStartAddr) and $10) or
  (Hi (MemLoc) and $e0));
end;

procedure SetInterlace (HT, VT, VD, VS, IM, CT : byte);

begin
  WriteVDC (vdcHorzTotal,HT);
  WriteVDC (vdcVertTotal,VT);
  WriteVDC (vdcVertDisp,VD);
  WriteVDC (vdcVertSyncPos,VS);
  WriteVDC (vdcInterlaceMode,IM);
  WriteVDC (vdcCharTotalVert,CT)
end;

procedure InitInterlace;

begin
  with vdcSettings do
  begin
    DispMem := $0000;
    AttrMem := $1000;
    DispPage1 := DispMem;
    AttrPage1 := AttrMem;
    DispPage2 := AttrPage1+$1000;
    AttrPage2 := DispPage2+$1000;
    ScrVert := 50;
    ScrSize := ScrHorz*ScrVert;
    CopyMemVDC (vdcSettings.CharDefMem,$4000,8192);
    SetCharDefMem ($4000);
    SetDispPageVDC (DispMem,AttrMem)
  end;
  SetInterlace (128,64,50,58,3,7)
end;

procedure DoneInterlace;

begin
  with vdcSettings do
  begin
    DispMem := $0000;
    AttrMem := $0800;
    DispPage1 := DispMem;
    AttrPage1 := AttrMem;
    DispPage2 := AttrPage1+$0800;
    AttrPage2 := DispPage2+$0800;
    ScrVert := 25;
    ScrSize := ScrHorz*ScrVert;
    CopyMemVDC (vdcSettings.CharDefMem,$2000,8192);
    SetCharDefMem ($2000)
  end;
  SetInterlace (126,32,25,29,0,7)
end;
