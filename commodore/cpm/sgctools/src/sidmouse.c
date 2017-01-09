/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <sid.h>

extern uchar sidPot1X;
extern uchar sidPot1Y;
extern uchar sidPot2X;
extern uchar sidPot2Y;

uchar sidMouse1X = 0;
uchar sidMouse1Y = 0;
uchar sidMouse2X = 0;
uchar sidMouse2Y = 0;

/* read 1351 compatible mouse in port 1 and 2 */

void getmousesid(void)
{
  if((sidPot1X & 0x01) == 0)
    sidMouse1X = (sidPot1X & 0x7F) >> 1;
  if((sidPot1Y & 0x01) == 0)
    sidMouse1Y = (sidPot1Y & 0x7F) >> 1;
  if((sidPot2X & 0x01) == 0)
    sidMouse2X = (sidPot2X & 0x7F) >> 1;
  if((sidPot2Y & 0x01) == 0)
    sidMouse2Y = (sidPot2Y & 0x7F) >> 1;
}
