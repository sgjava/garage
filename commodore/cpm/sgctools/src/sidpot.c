/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <cia.h>
#include <sid.h>

uchar sidPot1X;
uchar sidPot1Y;
uchar sidPot2X;
uchar sidPot2Y;

/* read all pots.  disable interrupts before calling or cp/m's key scan */
/* routine will affect values */

void getpotssid(void)
{
  register uchar SaveReg;

  SaveReg = inp(cia1+ciaDataDirA);    /* save data dir reg */
  outp(cia1+ciaDataDirA,0xC0);        /* set bits 6 and 7 to output */
  outp(cia1+ciaDataA,ciaPotsPort1);   /* set 4066 to read port 1 pots */
  setintctrlcia(cia2,ciaClearIcr);    /* disable all cia 2 interrupts */
  settimeracia(cia2,1636,ciaCPUOne);  /* 1.6 ms delay to get stable reading */
  while ((inp(cia2+ciaIntCtrl) & 0x01) == 0);
  sidPot1X = inp(sidPotX);            /* read pots */
  sidPot1Y = inp(sidPotY);
  outp(cia1+ciaDataA,ciaPotsPort2);   /* set 4066 to read port 2 pots */
  setintctrlcia(cia2,ciaClearIcr);
  settimeracia(cia2,1636,ciaCPUOne);  /* 1.6 ms delay to get stable reading */
  while ((inp(cia2+ciaIntCtrl) & 0x01) == 0);
  sidPot2X = inp(sidPotX);            /* read pots */
  sidPot2Y = inp(sidPotY);
  outp(cia1+ciaDataDirA,SaveReg);     /* restore data dir reg */
}
