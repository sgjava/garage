{
Blue Bastards From Outer Space (C) 1992 Steve Goldsmith
C128 CP/M support from SG Tools (C) 1992 Parsec, Inc. and
SG Tools Pro (C) 1992 Steve Goldsmith

Main program
}

program BlueBastards;

{$A+,B+,C-,R-,U-,V-,X+}

{SG Tools Pro include files}

{$I NUMSTR.INC}
{$I BDOS.INC}
{$I KEYIN.INC}
{$I PORT.INC}
{$I JOYSTICK.INC}
{$I SID.INC}
{$I ZBPLAY.INC}
{$I ZBFREAD.INC}
{$I ZBFMPLAY.INC}
{$I VDC.INC}
{$I VDCCONST.INC}
{$I VDCSCMGR.INC}
{$I VDCILACE.INC}
{$I CGFFILE.INC}
{$I VDCCGFR.INC}
{$I VDCFW.INC}
{$I VDCWIN.INC}
{$I BLUE1.INC}
{$I BLUE2.INC}
{$I BLUE3.INC}
{$I BLUE4.INC}
{$I BLUE5.INC}

begin
  Init;
  Run;
  Done
end.
