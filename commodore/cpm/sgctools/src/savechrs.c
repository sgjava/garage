/*
SG C Tools 1.8 Demo

(C) 1993,2017 Steve Goldsmith
All Rights Reserved

Saves both VDC character sets to a binary file. Not compatible with CDF format
from Pascal SG Tools.

Compiled with HI-TECH C 3.09 (CP/M-80).

To compile with HI-TECH C and SG C Tools source on same disk use:
C SAVECHRS.C -LC128
*/

#include <stdio.h>
#include <stdlib.h>
#include <hitech.h>
#include <vdc.h>

void disphelp(void);
void savecharsets(char *FileName);

extern ushort vdcCharMem;
extern ushort vdcCharMemSize;

main(int argc, char *argv[])
{
  puts("\nSAVECHRS (C) 1993,2017 Steve Goldsmith");
  if (argc == 2)
  {
    savevdc();
    mapvdc();
    savecharsets(argv[1]);
    restorevdc();
  }
  else
    disphelp();
}

void disphelp(void)
{
  puts("\nTo save VDC character definitions use:\n");
  puts("SAVECHRS FILENAME.EXT");
}

void savecharsets(char *FileName)
{
  uchar  *BufPtr;
  FILE   *CharFile;

  if ((CharFile = fopen(FileName,"wb")) != NULL)
  {
    puts("\nCopying VDC to buffer...");
    BufPtr = memtobufvdc(vdcCharMem,vdcCharMemSize);
    printf("Copying buffer to %s...\n",FileName);
    fwrite(BufPtr,sizeof(uchar),vdcCharMemSize,CharFile);
    free(BufPtr);
    fclose(CharFile);
  }
}
