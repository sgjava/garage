/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

extern ushort vdcDispMem;

/* set pixel in 640 x 200 bit map */

void setpixvdc(int X, int Y)
{
  uchar  SaveByte;
  ushort PixByte;
  static uchar BitTable[8] = {128,64,32,16,8,4,2,1};

  PixByte = vdcDispMem+(Y << 6)+(Y << 4)+(X >> 3);
  outvdc(vdcUpdAddrHi,(uchar) (PixByte >> 8));
  outvdc(vdcUpdAddrLo,(uchar) PixByte);
  SaveByte = invdc(vdcCPUData);
  outvdc(vdcUpdAddrHi,(uchar) (PixByte >> 8));
  outvdc(vdcUpdAddrLo,(uchar) PixByte);
  outvdc(vdcCPUData,SaveByte | BitTable[X & 0x07]);
}
