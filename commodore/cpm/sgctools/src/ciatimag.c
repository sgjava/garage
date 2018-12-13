/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <cia.h>

/* get cia timer a */

ushort gettimeracia (ushort C)
{
  return(inp(C+ciaTimerALo) | (inp(C+ciaTimerAHi) << 8));
}
