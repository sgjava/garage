/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <vdc.h>

/* low level vdc i/o */

uchar invdc(uchar RegNum)
{
  outp(vdcStatusReg,RegNum);                  /* internal vdc register to read */
  while ((inp(vdcStatusReg) & 0x80) == 0x00); /* wait for status bit to be set */
  return(inp(vdcDataReg));                    /* read register */
}

void outvdc(uchar RegNum, uchar RegVal)
{
  outp(vdcStatusReg,RegNum);                  /* internal vdc register to write */
  while ((inp(vdcStatusReg) & 0x80) == 0x00); /* wait for status bit to be set */
  outp(vdcDataReg,RegVal);                    /* write register */
}
