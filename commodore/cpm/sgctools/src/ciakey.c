/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <sys.h>
#include <hitech.h>
#include <cia.h>

ciaKeyRec ciaKeyScan;

void getkeyscia(void)
{
  register uchar I, SaveA, SaveB, KeyMask;

  SaveA = inp(cia1+ciaDataDirA);
  SaveB = inp(cia1+ciaDataDirB);
  outp(cia1+ciaDataDirA,0xFF);
  outp(cia1+ciaDataDirB,0x00);
  for(I = 0, KeyMask = 1; I < 8; I++, KeyMask <<= 1)
  {
    outp(cia1+ciaDataA,~KeyMask);
    ciaKeyScan[I] = inp(cia1+ciaDataB);
  }
  for(KeyMask = 1; I < sizeof(ciaKeyScan); I++, KeyMask <<= 1)
  {
    outp(vicExtKey,~KeyMask);
    outp(cia1+ciaDataA,0xFF);
    ciaKeyScan[I] = inp(cia1+ciaDataB);
  }
  outp(vicExtKey,0x07);
  outp(cia1+ciaDataDirA,SaveA);
  outp(cia1+ciaDataDirB,SaveB);
}
