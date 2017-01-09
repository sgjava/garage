/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

extern uchar  vdcScrHorz;
extern ushort vdcDispMem;

/* clear window given x1, y1, x2, y2 rectangle in current page */

void clrwinvdc(uchar X1, uchar Y1, uchar X2, uchar Y2, uchar Ch)
{
  uchar XLen;
  ushort DispOfs;

  DispOfs = Y1*vdcScrHorz+vdcDispMem+X1;
  XLen = X2-X1+1;
  for(; Y1 <= Y2; Y1++)
  {
    fillmemvdc(DispOfs,XLen,Ch);
    DispOfs += vdcScrHorz;
  }
}
