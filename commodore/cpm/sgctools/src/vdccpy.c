/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

/* fast copy using block copy */

void copymemvdc(ushort SMem, ushort DMem, ushort CopyLen)
{
  uchar Blocks, Remain;
  register uchar I;

  outvdc(vdcUpdAddrHi,(uchar) (DMem >> 8));
  outvdc(vdcUpdAddrLo,(uchar) DMem);
  outvdc(vdcVtSmScroll,(invdc(vdcVtSmScroll) | 0x80));
  outvdc(vdcBlkCpySrcAddrHi,(uchar) (SMem >> 8));
  outvdc(vdcBlkCpySrcAddrLo,(uchar) SMem);
  if (CopyLen > vdcMaxBlock)
  {
    Blocks = CopyLen/vdcMaxBlock;
    Remain = CopyLen%vdcMaxBlock;
    for(I = 1; I <= Blocks; I++)
      outvdc(vdcWordCnt,vdcMaxBlock);
    if (Remain > 0)
      outvdc(vdcWordCnt,Remain);
  }
  else
    if (CopyLen > 0)
      outvdc(vdcWordCnt,CopyLen);
}
