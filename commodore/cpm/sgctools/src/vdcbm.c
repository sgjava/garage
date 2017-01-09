/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

/* set bit map mode, background and foreground colors */

void setbitmapvdc(ushort DispMem, ushort AttrMem, uchar F, uchar B)
{
  outvdc(vdcFgBgColor,(F << 4) | B);
  setdsppagevdc(DispMem,AttrMem);
  outvdc(vdcHzSmScroll,invdc(vdcHzSmScroll) | 0x80);
}
