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

FILE    *pcxFile;
pcxHead pcxHeader;
ushort  pcxXSize, pcxYSize;

/* init decode 2 bit .pcx */

short initpcx(char *FileName)
{
  if ((pcxFile = fopen(FileName,"rb")) != NULL)
  {
    if (fread((uchar *) &pcxHeader,1,sizeof(pcxHeader),pcxFile) == sizeof(pcxHeader))
    {
      if (pcxHeader.Manufacturer == 0x0A)
      {
        if (pcxHeader.BitsPerPixel == 1)
        {
          pcxXSize = (pcxHeader.XMax - pcxHeader.XMin)+1;
          pcxYSize = (pcxHeader.YMax - pcxHeader.YMin)+1;
          return(pcxErrNone);
        }
        else
          return(pcxErrNot2Bit);
      }
      else
        return(pcxErrNotPCX);
    }
    else
      return(pcxErrHeader);
  }
  else
    return(pcxErrFile);
}

void donepcx(void)
{
  fclose(pcxFile);
}
