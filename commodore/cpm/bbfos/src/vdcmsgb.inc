{
SG Tools (C) 1992 Parsec, Inc.

VDC message box.  No line wrapping inside window.
}

const

  mbXSize = 40;
  mbYSize = 4;

procedure MsgBox (X,Y,W,T : byte;
                  Msg : fwMaxStr);

begin
  DrawWinVDC (X,Y,X+mbXSize,Y+mbYSize,W,'Information');
  FWriteVDC (X+1,Y+2,T,Msg)
end;

