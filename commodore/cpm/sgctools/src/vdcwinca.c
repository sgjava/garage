/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <string.h>
#include <hitech.h>
#include <vdc.h>

extern uchar  vdcScrHorz;
extern ushort vdcAttrMem;

/* clear attr window given x1, y1, x2, y2 rectangle in current page */

void clrwinattrvdc(uchar X1, uchar Y1, uchar X2, uchar Y2, uchar Ch)
{
  uchar XLen;
  ushort AttrOfs;

  AttrOfs = Y1*vdcScrHorz+vdcAttrMem+X1;
  XLen = X2-X1+1;
  for(; Y1 <= Y2; Y1++)
  {
    fillmemvdc(AttrOfs,XLen,Ch);
    AttrOfs += vdcScrHorz;
  }
}
