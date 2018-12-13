/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <cia.h>

/* set cia timer b and control reg b */

void settimerbcia (ushort C, ushort Latch, uchar CtrlReg)
{
  outp(C+ciaTimerBLo,(uchar) Latch);        /* timer latch lo */
  outp(C+ciaTimerBHi,(uchar) (Latch >> 8)); /* timer latch hi */
  outp(C+ciaControlB,CtrlReg);              /* set timer controls */
}
