/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

/* sets which disp and attr page is showing */

void setdsppagevdc(ushort DPage, ushort APage)
{
  outvdc(vdcDspStAddrHi,(uchar) (DPage >> 8));
  outvdc(vdcDspStAddrLo,(uchar) DPage);
  outvdc(vdcAttrStAddrHi,(uchar) (APage >> 8));
  outvdc(vdcAttrStAddrLo,(uchar) APage);
}
