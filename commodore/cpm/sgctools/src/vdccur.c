/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

/* set cursor's top and bottom scan lines and mode */

void setcursorvdc(uchar Top, uchar Bottom, uchar Mode)
{
  outvdc(vdcCurStScanLine,(Top | (Mode << 5)));
  outvdc(vdcCurEndScanLine,Bottom);
}
