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
extern ushort vdcAttrMem;

/* scroll window down given x1, y1, x2, y2 rectangle in current page */

void scrolldownvdc(uchar X1, uchar Y1, uchar X2, uchar Y2)
{
  uchar XLen;
  ushort DispOfs, AttrOfs;

  DispOfs = Y2*vdcScrHorz+vdcDispMem+X1;
  AttrOfs = Y2*vdcScrHorz+vdcAttrMem+X1;
  XLen = X2-X1+1;
  for(Y2++; Y2 > Y1; Y2--)
  {
    copymemvdc(DispOfs,DispOfs+vdcScrHorz,XLen);
    copymemvdc(AttrOfs,AttrOfs+vdcScrHorz,XLen);
    DispOfs -= vdcScrHorz;
    AttrOfs -= vdcScrHorz;
  }
}
