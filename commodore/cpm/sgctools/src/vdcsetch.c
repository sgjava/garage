/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

/* set char def mem addr */

void setcharvdc(ushort CharMem)
{
  outvdc(vdcChSetStAddr,
  (invdc(vdcChSetStAddr) & 0x10) | ((uchar) (CharMem >> 8) & 0xE0));
}
