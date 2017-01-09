/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <stdio.h>
#include <hitech.h>
#include <vdc.h>
#include <pcx.h>

extern uchar   vdcScrHorz;
extern ushort  vdcDispMem;
extern FILE    *pcxFile;
extern pcxHead pcxHeader;
extern ushort  pcxYSize;

/* decode 2 bit .pcx line to interlace vdc. */

void decodelineintpcx(ushort X, ushort Y)
{
  register uchar KeyByte, RunCnt;
  register ushort DecodeCnt = 0;
  register ushort DispOfs;

  if ((Y & 1) == 0)
  {
    Y >>= 1;
    DispOfs = Y*vdcScrHorz+vdcDispMem+X;
  }
  else
  {
    Y >>= 1;
    DispOfs = Y*vdcScrHorz+vdcOddFldOfs+vdcDispMem+X;
  }
  outvdc(vdcUpdAddrHi,(uchar) (DispOfs >> 8));
  outvdc(vdcUpdAddrLo,(uchar) DispOfs);
  do
  {
    KeyByte = fgetc(pcxFile) & 0xFF;
    if ((KeyByte & 0xC0) == 0xC0)
    {
      RunCnt = KeyByte & 0x3F;
      KeyByte = fgetc(pcxFile);
      outvdc(vdcVtSmScroll,(invdc(vdcVtSmScroll) & 0x7F));
      outvdc(vdcCPUData,KeyByte);
      if (RunCnt > 1)
        outvdc(vdcWordCnt,RunCnt-1);
      DispOfs += RunCnt;
      DecodeCnt += RunCnt;
    }
    else
    {
      outvdc(vdcCPUData,KeyByte);
      DispOfs++;
      DecodeCnt++;
    }
  }
  while(DecodeCnt < pcxHeader.BytesPerLine);
}

void decodefileintpcx(ushort X, ushort Y)
{
  register short I;

  for (I = 0; I < pcxYSize; I++, Y++)
    decodelineintpcx(X,Y);
}
