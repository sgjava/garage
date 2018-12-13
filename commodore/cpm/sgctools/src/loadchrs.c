/*
SG C Tools 1.8 Demo

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Loads both VDC character sets from a binary file.

Compiled with HI-TECH C 3.09 (CP/M-80).

To compile with HI-TECH C and SG C Tools source on same disk use:
C SAVECHRS.C -LC128
*/

#include <stdio.h>
#include <stdlib.h>
#include <hitech.h>
#include <vdc.h>

void disphelp(void);
void loadcharsets(char *FileName);

extern ushort vdcCharMem;
extern ushort vdcCharMemSize;

main(int argc, char *argv[])
{
  puts("\nLOADCHRS (C) 1993,1996 Steve Goldsmith");
  if (argc == 2)
  {
    savevdc();
    mapvdc();
    loadcharsets(argv[1]);
    restorevdc();
  }
  else
    disphelp();
}

void disphelp(void)
{
  puts("\nTo load VDC character definitions use:\n");
  puts("LOADCHRS FILENAME.EXT");
}

void loadcharsets(char *FileName)
{
  uchar  *BufPtr;
  FILE   *CharFile;

  if ((CharFile = fopen(FileName,"rb")) != NULL)
  {
    BufPtr = (uchar *) malloc(vdcCharMemSize);
    if (BufPtr != NULL)
    {
      printf("\nCopying %s to buffer...\n",FileName);
      fread(BufPtr,sizeof(uchar),vdcCharMemSize,CharFile);
      puts("Copying buffer to VDC...");
      buftomemvdc(BufPtr,vdcCharMem,vdcCharMemSize);
      free(BufPtr);
    }
    fclose(CharFile);
  }
}
