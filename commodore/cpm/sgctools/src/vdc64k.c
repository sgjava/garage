/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

/* is vdc in 64k mode? */

uchar is64kvdc(void)
{
  if((invdc(vdcChSetStAddr) & 0x10) == 0x10)
    return(1);
  else
    return(0);
}

/* set vdc to 64k mode */

void set64kvdc(void)
{
  outvdc (vdcChSetStAddr,invdc(vdcChSetStAddr) | 0x10);
}
