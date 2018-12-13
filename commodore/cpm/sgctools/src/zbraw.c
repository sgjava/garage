/*
Z Blaster RAW player 1.1

(C) 1994,1996 Steve Goldsmith
All Rights Reserved

Play 4 bit PCM files with nibble swapping feature.

Compiled with HI-TECH C 3.09 (CP/M-80).

To compile with HI-TECH C and SG C Tools source on same disk use:
C ZBRAW.C -LC128

SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <stdio.h>
#include <stdlib.h>
#include <stat.h>
#include <string.h>
#include <cpm.h>
#include <hitech.h>
#include <cia.h>
#include <sid.h>

#define appMaxSize 65535
#define appMinHz   3999
#define appMaxHz   15001

void disphelp(void);
void disptime(void);
void starttimer(ulong Hz);
void play(void);
void swap4bit(void);
long getfilesize(char *FileName);
void load(char *FileName);

uchar *appBufPtr;           /* buffer to hold sample */
FILE  *appRawFile;          /* raw file pointer */
ulong appHz, appSize;
static ciaTODRec appTODZero = {0,0,0,0};
ciaTODRec appTODTime;

/*
Main program parses command line, convert params, loads and plays RAW file
through SID.
*/

main(int argc, char *argv[])
{
  appBufPtr = NULL; /* set buffer to nil */
  puts("\nZ Blaster Raw Player 1.1 05/15/94 (C) 1994,1996 Steve Goldsmith");
  if (argc > 2)     /* make sure we have 3 or more params */
  {
    sscanf(argv[2],"%ld",&appHz);             /* convert hz param to long */
    if (appHz > appMinHz && appHz < appMaxHz) /* check hz range */
    {
      bdos(45,0x0FE);                     /* bdos return and display error */
      appSize = getfilesize(argv[1]);          /* get raw file size*/
      if (appSize > 0 && appSize < appMaxSize) /* check file size */
      {
        appBufPtr = (uchar *) malloc(appSize); /* alloc buffer */
        if (appBufPtr != NULL)
        {
          load(argv[1]);
          if (strcmp(argv[3],"SN") == 0)
          {
            printf("Swapping nibbles, ");
            settodcia(cia2,appTODZero);
            swap4bit();
            disptime();
          }
          printf("Playing, ");
          settodcia(cia2,appTODZero);
          play();
          disptime();
          free(appBufPtr);
        }
        else
          puts("\nUnable to allocate memory.");
      }
      else
        if (appSize > 0)
          puts("\nFile too large.");
        else
          puts("\nUnable to open file.");
    }
    else
      puts("\nHz value must be >= 4000 and <= 15000.");
  }
  else
    disphelp();
}

/*
Display program help.
*/

void disphelp(void)
{
  puts("\nZBRAW {U:D:}filespec hertz {sn}");
  puts("\nZBRAW FILENAME.RAW 8000 SN (swap nibbles before playing)");
  puts("ZBRAW FILENAME.RAW 15000   (no nibble swap)");
}

/*
Display current time in HH:MM:SS format using CIA 2's TOD clock.
*/

void disptime(void)
{
  ciaTODStr TODStr;

  gettodcia(cia2,appTODTime);   /* get tod time */
  todstrcia(appTODTime,TODStr); /* convert bcd time to string */
  TODStr[8] = 0;                /* drop 1/10th seconds */
  printf("%s\n",TODStr);        /* output time */
}

/*
Clear ICR and start timer A in continuous mode using Hz value.
*/

void starttimer(ulong Hz)
{
  setintctrlcia(cia2,ciaClearIcr);
  settimeracia(cia2,timervalcia(Hz),ciaCPUCont);
}

/*
Play sample from buffer.
*/

void play(void)
{
#asm
  di
#endasm
  starttimer(appHz);               /* start hz timer */
  playzb4sid(appBufPtr,appSize);   /* play sample */
#asm
  ei
#endasm
}

/*
Swap nibbles in buffer for inverted RAWs.
*/

void swap4bit(void)
{
  register ushort I;

  for(I = 0;  I < appSize; I++)
    appBufPtr[I] = (appBufPtr[I] << 4) | (appBufPtr[I] >> 4);
}

/*
Return file size or 0 for error.
*/

long getfilesize(char *FileName)
{
  struct stat  StatRec;

  if (stat(FileName,&StatRec) == 0)
    return(StatRec.st_size);
  else
    return(0);
}

/*
Load file into buffer and display load time.
*/

void load(char *FileName)
{
  if ((appRawFile = fopen(FileName,"rb")) != NULL)
  {
    printf("\nReading %s, %ld bytes, ",FileName,appSize);
    settodcia(cia2,appTODZero);
    fread(appBufPtr,sizeof(uchar),appSize,appRawFile);
    fclose(appRawFile);
    disptime();
  }
  else
    puts("\nUnable to open file.");
}
