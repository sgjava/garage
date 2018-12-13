/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <cpm.h>
#include <hitech.h>
#include <vdc.h>
#include <cia.h>
#include <sid.h>

/* 64k vdc locations */

#define appBitMapMem 0x4000
#define appAttrMem   0x0800

extern uchar     vdcScrHorz;
extern ushort    vdcDispMem;
extern ushort    vdcAttrMem;
extern ushort    vdcCharMem;
extern ushort    vdcCharMemSize;
extern ushort    vdcBitMapMemSize;
extern ciaKeyRec ciaKeyScan;

void waitkey(uchar KeyScan, uchar KeyVal);
uchar savechrsets(void);
void restorechrsets(void);
void set64kmode(void);
void dographics(void);

void init(void);
void run(void);
void done(void);

uchar *appChSetBufPtr; /* char set buffer pointer */

main()
{
  init();
  run();
  done();
}

void waitkey(uchar KeyScan, uchar KeyVal)
{
  do
  {
    getkeyscia();
  }
  while(ciaKeyScan[KeyScan] != KeyVal);
}

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

void restorechrsets(void)
{
  if(appChSetBufPtr != NULL)
  {
    outvdc(vdcFgBgColor,vdcBlack); /* set foreground-background to black */
    attrsoffvdc();                 /* disable attrs */
    buftomemvdc(appChSetBufPtr,vdcCharMem,vdcCharMemSize);
  }
}

void set64kmode(void)
{
  if(!(is64kvdc()) && appChSetBufPtr != NULL)
  {
    restorevdc();         /* make sure all registers are default value */
    set64kvdc();          /* set 64k mode */
    savevdc();            /* reflect change to reg 28 */
    restorechrsets();     /* restore char sets destroyed by setting 64k mode */
    free(appChSetBufPtr); /* dispose buffer */
    appChSetBufPtr = NULL;
    restorevdc();
    mapvdc();
  }
}

void dographics(void)
{
  int I;

  if(is64kvdc())
  {
    vdcBitMapMemSize = 49152;
    attrsoffvdc();
    setbitmapintvdc(appBitMapMem,appAttrMem,vdcDarkBlue,vdcBlack);
    mapvdc();
    clrbitmapvdc(0);

    for(I = 0; I <= 639; I += 80)
    {
      lineivdc(319,0,I,479);
      lineivdc(I,0,319,479);
    }
    for(I = 0; I <= 199; I += 32)
    {
      ellipseivdc(319,239,I,I);
    }
    printbmivdc(10,11,
    "SG C Tools makes it easy to use text in interlace GRAPHICS too!");
#asm
  di
#endasm
    waitkey(7,127);
#asm
  ei
#endasm
    outvdc(vdcFgBgColor,vdcBlack);
    attrsoffvdc();
    restorechrsets();
    restorevdc();
    mapvdc();
  }
}

void init(void)
{
  savevdc();
  mapvdc();
  appChSetBufPtr = NULL;
}

void run(void)
{
  if(savechrsets())
  {
    set64kmode();
    dographics();
  }
}

void done(void)
{
  if(appChSetBufPtr != NULL)
    free(appChSetBufPtr);
  restorevdc();     /* restore registers saved by savevdc() */
  bdos(2,0x1A);     /* adm-3a clear-home cursor */
}
