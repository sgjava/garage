  InitVDC;                       {fire up screen manager}
  SetScrColVDC (vdcDarkGray,vdcDarkGray);  {set app screen color}
  SetCursorVDC (0,0,vdcCurNone); {turn cursor off}
  InitInterlace;
  ClrScrVDC (32);
  ClrAttrVDC (vdcAltChrSet+vdcDarkGray);
