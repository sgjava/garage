/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

extern uchar  vdcScrHorz;
extern ushort vdcAttrMem;

/* fill attr mem given x and y offset in current page */

void fillattrvdc(uchar X, uchar Y, uchar ALen, uchar Attr)
{
  fillmemvdc(Y*vdcScrHorz+vdcAttrMem+X,ALen,Attr);
}
