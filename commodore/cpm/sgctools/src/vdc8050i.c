/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

/* set 80 x 50 interlaced text mode with 8 x 8 chars */

void set80x50textvdc(void)
{
  outvdc(vdcHzTotal,128);
  outvdc(vdcVtTotal,64);
  outvdc(vdcVtDisp,50);
  outvdc(vdcVtSyncPos,58);
  outvdc(vdcIlaceMode,3);
  outvdc(vdcChTotalVt,7);
}
