/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <cia.h>

/* set cia time of day clock */

void settodcia (ushort C, uchar *TOD)
{
  outp(C+ciaControlB,(inp(C+ciaControlB) & 0x7F)); /* bit 7 = 0 sets tod clock */
  outp(C+ciaTODHrs,TOD[0]);
  outp(C+ciaTODMin,TOD[1]);
  outp(C+ciaTODSec,TOD[2]);
  outp(C+ciaTODTen,TOD[3]);
}
