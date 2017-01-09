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
extern ushort vdcDispMem;

/* fast vdc string print given x and y offset in current page */

void printstrvdc(uchar X, uchar Y, uchar Attr, char *TextStr)
{
  register uchar I, TextLen;
  ushort DispOfs;

  TextLen = strlen(TextStr);
  if(TextLen > 0)
  {
  DispOfs = Y*vdcScrHorz+vdcDispMem+X; /* calc disp mem offset */
  fillattrvdc(X,Y,TextLen,Attr);       /* use block fill for attrs */
  outvdc(vdcUpdAddrHi,(uchar) (DispOfs >> 8));
  outvdc(vdcUpdAddrLo,(uchar) DispOfs); /* set addr of first char */
  for(I = 0; TextStr[I]; I++)          /* send str to vdc disp mem */
    outvdc(vdcCPUData,TextStr[I]);
  }
}
