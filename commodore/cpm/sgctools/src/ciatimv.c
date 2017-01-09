/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <cia.h>

/* convert hz to timer latch value */

ushort timervalcia (ulong Hz)
{
  return(ciaTimerFreq / Hz);
}
