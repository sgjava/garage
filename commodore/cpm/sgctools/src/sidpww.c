/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <sid.h>

/* set pulse waveform width */

void pulsewavesid(ushort Voice, ushort Width)
{
  outp(Voice+2,(uchar) Width);
  outp(Voice+3,(uchar) (Width >> 8));
}
