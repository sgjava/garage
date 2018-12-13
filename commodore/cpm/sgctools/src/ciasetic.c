/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <cia.h>

/* set cia interrupt control register */

void setintctrlcia (ushort C, uchar Icr)
{
  inp(C+ciaIntCtrl);      /* clear cia icr status */
  outp(C+ciaIntCtrl,Icr); /* set or clear icr irq enable bits */
}
