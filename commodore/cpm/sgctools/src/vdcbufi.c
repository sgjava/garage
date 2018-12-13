/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <stdlib.h>
#include <hitech.h>
#include <vdc.h>

/* alloc buffer and copy vdc mem into it */

uchar * memtobufvdc(ushort VidMem, ushort CopyLen)
{
  register ushort I;
  uchar *BufPtr;

  BufPtr = (uchar *) malloc(CopyLen);
  if (BufPtr != NULL)
  {
    outvdc(vdcUpdAddrHi,(uchar) (VidMem >> 8));
    outvdc(vdcUpdAddrLo,(uchar) VidMem);
    for(I = 0; I < CopyLen; I++)
      BufPtr[I] = invdc(vdcCPUData);
  }
  return(BufPtr);
}
