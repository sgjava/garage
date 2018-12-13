/*
PCX'EM 1.2

(C) 1994,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).

To compile with HI-TECH C and SG C Tools 1.6 source on same disk use:
C PCXEM.C -LC128

To view a PCX in 640 X 480 interlace:

PCXEM {U:D:}filespec {color}
PCXEM PCXEM.PCX 4
Views PCXEM.PCX on green background.

Use [CTRL] [RUN STOP] to toggle off disk status line before running.
*/

#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>
#include <cpm.h>
#include <hitech.h>
#include <vdc.h>
#include <pcx.h>

extern uchar  vdcScrHorz;
extern ushort vdcDispMem;
extern ushort vdcAttrMem;
extern ushort vdcCharMem;
extern ushort vdcCharMemSize;
extern ushort vdcBitMapMemSize;
extern ushort pcxXSize;
extern ushort pcxYSize;

#define appBitMapMem 0x4000 /* bit map location */
#define appAttrMem   0x0800 /* attr location */

uchar *appChSetBufPtr = NULL; /* char set buffer pointer */
uchar appColor = vdcDarkBlue; /* pcx foreground color */

void disphelp(void);
void set64kmode(void);
void initbitmap64k(void);
uchar savechrsets(void);
void restorechrsets(void);
void graphicsview(void);

/*
Main program saves key VDC registers, maps the VDC, sets bit map size to 48K,
sets 64K mode, parses and converts command line params, sets interlace bit map
mode, decodes and views PCX file then restores normal CP/M mode text mode.
All errors are reported in text mode.
*/

main(int argc, char *argv[])
{
  puts("\nPCX'EM 1.2 03/05/94 (C) 1994,1996 Steve Goldsmith");
  if (argc > 1)
  {
    savevdc();
    mapvdc();
    vdcBitMapMemSize = 49152;
    set64kmode();
    if (argc > 2)
      sscanf(argv[2],"%d",&appColor);
    bdos(45,0x0FE);
    switch (initpcx(argv[1]))
    {
      case pcxErrNone:
        if (pcxXSize < 641 && pcxYSize < 481)
        {
          if(savechrsets())
          {
            initbitmap64k();
            decodefileintpcx(0,0);
            donepcx();
            graphicsview();
            clrattrvdc(0);
            clrattrvdc(32);
            restorevdc();
            putchar(0x1A); /* use cp/m to clear screen */
          }
        }
        else
        {
          donepcx();
          puts("\nImage cannot be larger than 640 X 480.");
        }
        break;
      case pcxErrFile:
        puts("\nUnable to open file.");
        break;
      case pcxErrHeader:
        donepcx();
        puts("\nCannot read header.");
        break;
      case pcxErrNotPCX:
        donepcx();
        puts("\nFile not .PCX format.");
        break;
      case pcxErrNot2Bit:
        donepcx();
        puts("\nFile not 2 color.");
        break;
    }
    if(appChSetBufPtr != NULL)
      free(appChSetBufPtr);
  }
  else
    disphelp();
}

/*
Simple help.
*/

void disphelp(void)
{
  puts("\nPCXEM {U:D:}filespec {color}");
  puts("{color} background must be VDC color 0 - 15.");
  puts("\nPCXEM PCXEM.PCX 4 (view PCXEM.PCX on green background)");
  puts("\n\x01B\x047\x032IMPORTANT:\x01B\x047\x030 Use [CTRL] [RUN STOP] to toggle off disk status line.");
}

/*
Set VDC to 64K mode if not in 64K mode.
*/

void set64kmode(void)
{
  if(!(is64kvdc()) && appChSetBufPtr == NULL)
  {
    if(savechrsets())
    {
      restorevdc();         /* make sure all registers are default value */
      set64kvdc();          /* set 64k mode */
      savevdc();            /* reflect change to reg 28 */
      outvdc(vdcFgBgColor,vdcBlack);
      attrsoffvdc();
      restorechrsets();     /* restore char sets destroyed by setting 64k mode */
      clrattrvdc(0);
      clrscrvdc(32);
      restorevdc();
      mapvdc();
      free(appChSetBufPtr); /* dispose buffer */
      appChSetBufPtr = NULL;
    }
  }
}

/*
Set and clear bit map.
*/

void initbitmap64k(void)
{
  setcursorvdc(0,0,vdcCurNone);    /* turn cursor off */
  attrsoffvdc();
  setbitmapintvdc(appBitMapMem,appAttrMem,vdcBlack,vdcBlack);
  mapvdc();                        /* set global vdc vars to reflect changes */
  clrbitmapvdc(0);                 /* clear bit map */
  outvdc(vdcFgBgColor,appColor << 4);
}

/*
Save char sets if not in 64K mode.
*/

uchar savechrsets(void)
{
  if(is64kvdc())
    return(1);
  else
  {
    appChSetBufPtr = memtobufvdc(vdcCharMem,vdcCharMemSize);
    if (appChSetBufPtr != NULL)
      return(1);
    else
      return(0);
  }
}

/*
Restore char sets if buffer is not null.
*/

void restorechrsets(void)
{
  if(appChSetBufPtr != NULL)
    buftomemvdc(appChSetBufPtr,vdcCharMem,vdcCharMemSize);
}

/*
Wait until key is pressed then clear bit map.
*/

void graphicsview(void) /* view graphics until key pressed */
{
  while (!(kbhit()));
  getch();
  outvdc(vdcFgBgColor,vdcBlack);   /* black screen */
  clrbitmapvdc(0);
}
