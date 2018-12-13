/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <stdlib.h>
#include <hitech.h>
#include <vdc.h>

/* copy buffer to vdc mem */

void buftomemvdc(uchar *BufPtr, ushort VidMem, ushort CopyLen)
{
  register ushort I;

  if (BufPtr != NULL)
  {
    outvdc(vdcUpdAddrHi,(uchar) (VidMem >> 8));
    outvdc(vdcUpdAddrLo,(uchar) VidMem);
    for(I = 0; I < CopyLen; I++)
      outvdc(vdcCPUData,BufPtr[I]);
  }
}
