/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <cia.h>

/* get cia time of day clock */

void gettodcia (ushort C, uchar *TOD)
{
  TOD[0] = inp(C+ciaTODHrs); /* c = cia chip addr */
  TOD[1] = inp(C+ciaTODMin);
  TOD[2] = inp(C+ciaTODSec);
  TOD[3] = inp(C+ciaTODTen);
}
