/*
Z Blaster Convert 1.1

(C) 1994,1996 Steve Goldsmith
All Rights Reserved

Z Blaster Convert 8 bit .SND file to 4 bit .RAW

Compiled with HI-TECH C 3.09 (CP/M-80).

To compile with HI-TECH C and SG C Tools source on same disk use:
C ZBCNV.C -LC128

SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved
*/

#include <stdio.h>
#include <stdlib.h>
#include <stat.h>
#include <cpm.h>
#include <hitech.h>
#include <cia.h>

#define appBufSize 8192 /* size of conversion buffer */

void disphelp(void);
void disptime(void);
void convert(char *SndFileName, char *RawFileName);

uchar *appBufPtr;                  /* conversion buffer */
FILE  *appSndFile, *appRawFile;
static ciaTODRec appTODZero = {0,0,0,0};
ciaTODRec appTODTime;

/*
Main program parses command line, converts params and converts .SND file to
.RAW file.
*/

main(int argc, char *argv[])
{
  puts("\nZ Blaster Convert 1.1 05/15/94 (C) 1994,1996 Steve Goldsmith");
  if (argc == 3)
  {
    appBufPtr = (uchar *) malloc(appBufSize); /* alloc converions buffer */
    if (appBufPtr != NULL)
    {
      bdos(45,0x0FE);                /* bdos return and display error mode */
      convert(argv[1],argv[2]);      /* convert raw file */
      free(appBufPtr);               /* dispose buffer */
    }
  }
  else
    disphelp();
}

/*
Display program help.
*/

void disphelp(void)
{
  puts("\nZBCNV {U:D:}filespec {U:D:}filespec");
  puts("\nZBCNV FILENAME.SND FILENAME.RAW (.SND is 8 bit and .RAW is 4 bit)");
}

/*
Display CIA 2 TOD clock in HH:MM:SS format.
*/

void disptime(void)
{
  ciaTODStr TODStr;

  gettodcia(cia2,appTODTime);    /* get tod time */
  todstrcia(appTODTime,TODStr);  /* convert to string */
  TODStr[8] = 0;                 /* drop 1/10th seconds */
  printf(", %s\n",TODStr);       /* display time */
}

/*
Convert 8 bit raw data to 4 bit raw data.
*/

void convert(char *SndFileName, char *RawFileName)
{
  struct stat  StatRec;
  ushort I, BytesRead;
  ulong  CnvBytes, CnvStep, CnvNext;

  if (stat(SndFileName,&StatRec) == 0)
  {
    if ((appSndFile = fopen(SndFileName,"rb")) != NULL)
    {
      if ((appRawFile = fopen(RawFileName,"wb")) != NULL)
      {
        CnvBytes = 0;
        CnvStep = StatRec.st_size / 10; /* progress steps */
        CnvNext = CnvStep;
        printf("\nConverting %s, %ld bytes, ..........,\b\b\b\b\b\b\b\b\b\b\b",
        SndFileName,StatRec.st_size);
        settodcia(cia2,appTODZero);
        do
        {
          BytesRead = fread(appBufPtr,sizeof(uchar),appBufSize,appSndFile);
          for (I = 0; I < BytesRead; I += 2) /* pack 2 8 bit samples into 1 byte */
            appBufPtr[I >> 1] = ((appBufPtr[I] >> 4) << 4) |
            (appBufPtr[I+1] >> 4);
          fwrite(appBufPtr,sizeof(uchar),BytesRead >> 1,appRawFile);
          CnvBytes += BytesRead;
          while (CnvBytes >= CnvNext)
          {
            printf("*"); /* show progress */
            CnvNext += CnvStep;
          }
        }
        while (BytesRead == appBufSize);
        fclose(appRawFile);
        disptime();
      }
      else
        puts("\nUnable to open output file.");
      fclose(appSndFile);
    }
    else
      puts("\nUnable to open input file.");
  }
  else
    puts("\nUnable to open input file.");
}
