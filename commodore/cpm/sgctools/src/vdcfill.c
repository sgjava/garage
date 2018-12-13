/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

/* fast fill using block writes */

void fillmemvdc(ushort FillMem, ushort FillLen, uchar Filler)
{
  uchar Blocks, Remain;
  register uchar I;

  outvdc(vdcUpdAddrHi,(uchar) (FillMem >> 8));
  outvdc(vdcUpdAddrLo,(uchar) FillMem);
  outvdc(vdcVtSmScroll,(invdc(vdcVtSmScroll) & 0x7F));
  outvdc(vdcCPUData,Filler);
  if (FillLen > vdcMaxBlock)
  {
    Blocks = FillLen/vdcMaxBlock;
    Remain = FillLen%vdcMaxBlock;
    for(I = 1; I <= Blocks; I++)
      outvdc(vdcWordCnt,vdcMaxBlock);
    if (Remain > 1)
      outvdc(vdcWordCnt,--Remain);
  }
  else
    if (FillLen > 1)
      outvdc(vdcWordCnt,--FillLen);
}
