/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <sid.h>

/* start release cycle */

void releasesid(ushort Voice, uchar Waveform)
{
  outp(Voice+4,Waveform);
}
