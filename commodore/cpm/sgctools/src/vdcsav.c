/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

uchar vdcRegsToSave[] =      /* vdc registers to save and restore */
{
0,   1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13,
20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
34, 35, 36
};

uchar vdcRegs[sizeof(vdcRegsToSave)-1]; /* saved vdc registers */

/* save and restore key vdc registers */

void savevdc(void)
{
  uchar I;

  for(I = 0; I < sizeof(vdcRegs); I++)    /* save key vdc regs */
    vdcRegs[I] = invdc(vdcRegsToSave[I]);
}

void restorevdc(void)
{
  uchar I;

  for(I = 0; I < sizeof(vdcRegs); I++)  /* restore vdc regs saved with savevdc() */
    outvdc(vdcRegsToSave[I],vdcRegs[I]);
}
