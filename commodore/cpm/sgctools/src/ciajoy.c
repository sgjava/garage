/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <cia.h>

uchar ciaJoy1;
uchar ciaJoy2;

/* read joy sticks.  disable interrupts before calling or cp/m's key scan */
/* routine will affect values */

void getjoyscia(void)
{
  register uchar SaveReg;

  SaveReg = inp(cia1+ciaDataDirA);
  outp(cia1+ciaDataDirA,0x00);
  ciaJoy2 = inp(cia1+ciaDataA) & ciaNone;
  outp(cia1+ciaDataDirA,SaveReg);

  SaveReg = inp(cia1+ciaDataDirB);
  outp(cia1+ciaDataDirB,0x00);
  ciaJoy1 = inp(cia1+ciaDataB) & ciaNone;
  outp(cia1+ciaDataDirB,SaveReg);
}
