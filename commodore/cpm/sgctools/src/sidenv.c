/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <sid.h>

/* set adsr envelope.  all adsr values must be >= 0 and <= 15 */

void envelopesid(ushort Voice, uchar Attack, uchar Decay, uchar Sustain, uchar Release)
{
  outp(Voice+5,(Attack << 4) | Decay);
  outp(Voice+6,(Sustain << 4) | Release);
}
