/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

extern vdcDispMem;
extern vdcBitMapMemSize;

/* clear bit map */

void clrbitmapvdc(uchar Filler)
{
  fillmemvdc(vdcDispMem,vdcBitMapMemSize,Filler);
}
