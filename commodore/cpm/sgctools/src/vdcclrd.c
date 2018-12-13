/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

extern ushort vdcScrSize;
extern ushort vdcDispMem;

/* fast disp page clear with any byte */

void clrscrvdc(uchar Ch)
{
  fillmemvdc(vdcDispMem,vdcScrSize,Ch);
}
