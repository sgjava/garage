/*
SG C Tools 1.8 Demo

(C) 1994,2017 Steve Goldsmith
All Rights Reserved

SG C Tools Demo shows how to use most of the features available with SG C
Tools.

Compiled with HI-TECH C 3.09 (CP/M-80).

To compile with HI-TECH C and SG C Tools source on same disk use:
C DEMO.C -LC128
*/

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <conio.h>
#include <sys.h>
#include <stat.h>
#include <cpm.h>
#include <hitech.h>
#include <vdc.h>
#include <cia.h>
#include <sid.h>
#include <pcx.h>
#include <demo.h>

uchar *appChSetBufPtr; /* char set buffer pointer */
uchar appColors[] =    /* colors for 64k graphics */
{
vdcDarkGray,
vdcDarkBlue,
vdcLightBlue,
vdcLightBlue,
vdcDarkCyan,
vdcDarkCyan,
vdcDarkCyan,
vdcLightCyan,
vdcLightCyan,
vdcLightCyan,
vdcMediumGray,
vdcMediumGray,
vdcWhite,
vdcMediumGray,
vdcMediumGray,
vdcLightCyan,
vdcLightCyan,
vdcLightCyan,
vdcDarkCyan,
vdcDarkCyan,
vdcDarkCyan,
vdcLightBlue,
vdcLightBlue,
vdcDarkBlue,
vdcDarkGray
};

char *appMenuItems[6] =            /* text used by this app */
{
"[A] Keyboard, joy stick, paddle and mouse controls",
"[B] SID sound effects",
"[C] Play 4 bit digitized sound",
"[D] 80 X 50 interlaced text",
"[E] 640 X 200 graphics",
"[F] 640 X 200 PCX image, [CONTROL] & [RUN STOP] status",
};

char *app16KHelp[3] =
{
"DO NOT select [S] option if your C128 has a 16K VDC!",
"If you have a 64K VDC use [S] to get color, text and",
"interlace in graphics mode!"
};

char *appSoundSeq[4] =
{
"Plane",
"Shots",
"Bomb dropping",
"Explosion"
};

uchar appMenuRect[]    = {10,2,69,13};  /* menu window location */
uchar app16KRect[]     = {10,16,69,21}; /* 16k help window location */
uchar appSoundRect[]   = {19,7,59,17};  /* sound window location */
uchar appControlRect[] = {10,2,69,14};  /* control window location */

ciaTODRec appTOD = {0,0,0,0}; /* used to set tod clock to 12 am */

char  appRawName[] = {"DEMO.RAW"};
ulong appHz        = 8000;

char  appPcxName1[] = {"DEMO1.PCX"};
char  appPcxName2[] = {"DEMO2.PCX"};

main()
{
  init();
  run();
  done();
}

void initbitmapi64k(void)
{
  if(is64kvdc())
  {
    vdcBitMapMemSize = 49152;
    setcursorvdc(0,0,vdcCurNone);    /* turn cursor off */
    outvdc(vdcFgBgColor,vdcBlack);   /* black screen */
    attrsoffvdc();
    setbitmapintvdc(appBitMapMem,appAttrMem,vdcDarkBlue,vdcBlack);
    mapvdc();
    clrbitmapvdc(0);
  }
}

void initbitmap64k(void)
{
  vdcBitMapMemSize = 16000;
  setcursorvdc(0,0,vdcCurNone);    /* turn cursor off */
  outvdc(vdcFgBgColor,vdcBlack);   /* black screen */
  attrsoffvdc();                   /* disable attrs */
  setbitmapvdc(appBitMapMem,appAttrMem,vdcBlack,vdcBlack); /* black fg bg */
  mapvdc();                        /* set global vdc vars to reflect changes */
  clrattrvdc(vdcBlack);
  clrbitmapvdc(0);                 /* clear bit map */
  attrsonvdc();                    /* enable attrs */
}

void initbitmap16k(void)
{
  vdcBitMapMemSize = 16000;
  setcursorvdc(0,0,vdcCurNone);    /* turn cursor off */
  outvdc(vdcFgBgColor,vdcBlack);   /* black screen */
  attrsoffvdc();                   /* disable attrs to work on 16k vdc */
  setbitmapvdc(vdcDispMem,vdcAttrMem,vdcWhite,vdcBlack);
  clrbitmapvdc(0);                 /* clear bit map */
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

void draw16khelp(uchar Rect[])
{
  uchar I;

  winvdc(Rect[0],Rect[1],Rect[2],Rect[3],appMenuWinCo,"VDC Help");
  for(I=0; I < 3; I++)
    printstrvdc(Rect[0]+2,Rect[1]+I+2,appMenuTxtCo,app16KHelp[I]);
}

void drawmenu(uchar Rect[])
{
  uchar I;

  outvdc(vdcFgBgColor,appMenuScrCo); /* set new screen color */
  setcursorvdc(0,0,vdcCurNone);      /* turn cursor off */
  clrattrvdc(appDeskCo);             /* draw desk top */
  clrscrvdc(137);
  filldspvdc(0,0,vdcScrHorz,32);
  fillattrvdc(0,0,vdcScrHorz,appClockCo);
  printstrvdc(1,0,appClockCo,"CP/M");
  printstrvdc(67,0,appClockCo,"RUN");
  winvdc(Rect[0],Rect[1],Rect[2],Rect[3],appMenuWinCo,"SG C Tools 1.8 Demo (C) 2017");
  for(I=0; I < 6; I++)
    printstrvdc(Rect[0]+2,Rect[1]+I+2,appMenuTxtCo,appMenuItems[I]);
  if(is64kvdc())
  {
    printstrvdc(Rect[0]+2,Rect[3]-3,appMenuTxtCo,"[G] 640 X 480 graphics");
    printstrvdc(Rect[0]+2,Rect[3]-2,appMenuTxtCo,"[H] 640 X 480 interlace PCX image");
  }
  else
  {
    printstrvdc(Rect[0]+2,Rect[3]-2,appMenuTxtCo,"[S] Set 64K mode");
    draw16khelp(app16KRect);
  }
  printstrvdc(Rect[0]+2,Rect[3]-1,appMenuTxtCo,"[X] Exit to CP/M");
}

void graphicsview(void) /* view graphics until key pressed */
{
  while (!(kbhit()));
  getch();
  outvdc(vdcFgBgColor,vdcBlack);
  attrsoffvdc();
  restorechrsets();
  restorevdc();
  mapvdc();
  drawmenu(appMenuRect);
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
    drawmenu(appMenuRect);
  }
}

void ilace80x50text(void)
{
  uchar I;

  outvdc(vdcFgBgColor,appIScrCo); /* set new screen color */
  setdsppagevdc(vdcDispMem,vdcAttrMem << 1);
  set80x50textvdc();
  mapvdc();                       /* map changes */
  clrattrvdc(appIDeskCo);
  clrscrvdc(137);
  winvdc(10,5,69,44,appIWinCo,"Interlace 80 X 50 Mode");
  printstrvdc(11,43,appIWinTxtCo,
  "All functions that operate in 80 X 25 work in 80 X 50 too!");
  for (I = 1; I <= 36; I++)       /* scroll window */
    scrollupvdc(11,7,68,43);
  while (!(kbhit()));
  getch();
  clrattrvdc(vdcAltChrSet);
  clrscrvdc(32);
  restorevdc();
  mapvdc();
  drawmenu(appMenuRect);
}

void graphics640x200(void)
{
  int I;
  uchar X, Y;

  if(is64kvdc())
  {
    initbitmap64k();
    for(I = 0; I <= sizeof(appColors); I++)
      fillattrvdc(0,I,vdcScrHorz,appColors[I]);
  }
  else
    initbitmap16k();
  for(I = 0; I <= 639; I += 80)
  {
    linevdc(319,0,I,199);
    linevdc(I,0,319,199);
  }
  for(I = 32; I <= 319; I += 32)
  {
    ellipsevdc(319,99,I,I/4);
  }
  if(is64kvdc())
  {
    printbmvdc(12,1,appGrTextCo,
    "SG C Tools makes it easy to use text in GRAPHICS mode!");
    printbmvdc(32,3,appGrTextCo,"Bit map colors");
    for (Y = 0; Y < 16; Y++)
      for (X = 0; X < 16; X++)
        printbmvdc(X+31,Y+5,(Y << 4) | X,"*");
  }
  graphicsview();
}

void pcx640x200(char * FileName)
{
  bdos(45,0x0FE);
  if (initpcx(FileName) == pcxErrNone)
  {
    if (pcxXSize < 641 && pcxYSize < 201)
    {
      if(is64kvdc())
      {
        initbitmap64k();
        clrattrvdc(vdcWhite);
      }
      else
        initbitmap16k();
      decodefilepcx(0,0);
      donepcx();
      graphicsview();
    }
    else
      donepcx();
  }
}

void graphics640x480(void)
{
  int I;

  if(is64kvdc())
  {
    initbitmapi64k();
    for(I = 0; I <= 639; I += 80)
    {
      lineivdc(319,0,I,479);
      lineivdc(I,0,319,479);
    }
    for(I = 32; I <= 319; I += 32)
    {
      ellipseivdc(319,239,I,I/2);
    }
    printbmivdc(10,11,
    "SG C Tools makes it easy to use text in interlace GRAPHICS too!");
    graphicsview();
  }
}

void pcx640x480(char * FileName)
{
  if(is64kvdc())
  {
    bdos(45,0x0FE);
    if (initpcx(FileName) == pcxErrNone)
    {
      if (pcxXSize < 641 && pcxYSize < 481)
      {
        initbitmapi64k();
        decodefileintpcx(0,0);
        donepcx();
        graphicsview();
      }
      else
        donepcx();
    }
  }
}

void delay(ushort D) /* delay in milliseconds (1/1000 sec) */
{
  setintctrlcia(cia2,ciaClearIcr); /* disable all cia 2 interrupts */
  settimerbcia(cia2,D,ciaCountA);  /* timer b counts timer a underflows */
  settimeracia(cia2,timervalcia(1000),ciaCPUCont); /* set timer a 1/1000 sec */
  while ((inp(cia2+ciaIntCtrl) & 0x02) == 0);      /* wait for count down */
}

void planesound(void)
{
  ushort Pulse;
  ushort Freq = 2047;

  volumesid(15,0);
  envelopesid(sidVoice1,12,10,0,0);
  attacksid(sidVoice1,sidWaveSqu);
  for(Pulse = 0; Pulse < 3840; Pulse += 10)
  {
    pulsewavesid(sidVoice1,Pulse);
    freqsid(sidVoice1,Freq);
    Freq -= 5;
    delay(2);
  }
  releasesid(sidVoice1,sidWaveSqu);
  delay(6);
  freqsid(sidVoice1,0);
}

void shotssound(void)
{
  uchar I;

  volumesid(15,0);
  for(I = 0; I < 20; I++)
  {
    envelopesid(sidVoice1,0,3,0,0);
    freqsid(sidVoice1,5360);
    attacksid(sidVoice1,sidWaveNoi);
    delay(100);
    releasesid(sidVoice1,sidWaveNoi);
    delay(6);
  }
  freqsid(sidVoice1,0);
}

void explodesound(void)
{
  volumesid(15,0);
  envelopesid(sidVoice1,0,0,15,11);
  freqsid(sidVoice1,200);
  attacksid(sidVoice1,sidWaveNoi);
  delay(8);
  releasesid(sidVoice1,sidWaveNoi);
  delay(2400);
  freqsid(sidVoice1,0);
}

void bombdropsound(void)
{
  ushort I;

  volumesid(15,0);
  envelopesid(sidVoice3,13,0,15,0);
  freqsid(sidVoice3,0);
  attacksid(sidVoice3,sidWaveTri);
  for(I = 32000; I > 200; I -= 200)
  {
    freqsid(sidVoice3,I);
    delay(18);
  }
  releasesid(sidVoice3,sidWaveTri);
  delay(6);
  freqsid(sidVoice3,0);
}

void soundseq(uchar Rect[], uchar Seq)
{
  scrollupvdc(Rect[0]+1,Rect[1]+2,Rect[2]-1,Rect[3]-1);
  fillattrvdc(Rect[0]+2,Rect[3]-3,Rect[2]-Rect[0]-2,appSoundTxt2Co);
  printstrvdc(Rect[0]+2,Rect[3]-2,appSoundTxt1Co,appSoundSeq[Seq]);
}

void soundwin(uchar Rect[])
{
  uchar I;

  winvdc(Rect[0],Rect[1],Rect[2],Rect[3],appSoundWinCo,"SID Sound Effects");
  for(I = 0; I < 4; I++)
  {
    soundseq(Rect,I);
    switch (I)
    {
      case 0 :
        planesound();
        break;
      case 1 :
        shotssound();
        break;
      case 2 :
        bombdropsound();
        break;
      case 3 :
        explodesound();
        break;
    }
  }
  drawmenu(appMenuRect);
}

void playraw(char * FileName, ulong Hz)
{
  uchar  *RawBufPtr;
  FILE   *RawFile;
  ulong  RawSize;
  struct stat  StatRec;

  RawBufPtr = NULL;
  bdos(45,0x0FE);
  if (stat(FileName,&StatRec) == 0)
    RawSize = StatRec.st_size;
  else
    RawSize = 0;
  if (RawSize > 0)
  {
    RawBufPtr = (uchar *) malloc(RawSize);
    if (RawBufPtr != NULL)
    {
      if ((RawFile = fopen(FileName,"rb")) != NULL)
      {
        fread(RawBufPtr,sizeof(uchar),RawSize,RawFile);
        fclose(RawFile);
#asm
  di
#endasm
        setintctrlcia(cia2,ciaClearIcr);
        settimeracia(cia2,timervalcia(Hz),ciaCPUCont);
        playzb4sid(RawBufPtr,RawSize);
#asm
  ei
#endasm
      }
      free(RawBufPtr);
    }
  }
}

void controlswin(uchar Rect[])
{
  char  StrBuf[45];

  winvdc(Rect[0],Rect[1],Rect[2],Rect[3],appCtrlWinCo,"Controls");
  printstrvdc(Rect[0]+2,Rect[1]+2,appCtrlTxt1Co,"Keyboard   0   1   2   3   4   5   6   7   8   9   10 ");
  printstrvdc(Rect[0]+2,Rect[1]+4,appCtrlTxt1Co,"Joystick   1   2  ");
  printstrvdc(Rect[0]+2,Rect[1]+6,appCtrlTxt1Co,"Paddle     1   2   3   4  ");
  printstrvdc(Rect[0]+2,Rect[1]+8,appCtrlTxt1Co,"1351 Mouse X1  Y1  X2  Y2 ");
  printstrvdc(Rect[0]+21,Rect[1]+11,appCtrlTxt2Co | vdcBlink,
  " [RUN STOP] to exit ");
#asm
  di
#endasm
  do
  {
    getpotssid();  /* read controls */
    getmousesid();
    getjoyscia();
    getkeyscia();

    sprintf(StrBuf,"%4u%4u%4u%4u%4u%4u%4u%4u%4u%4u%4u",
    ciaKeyScan[0],ciaKeyScan[1],ciaKeyScan[2],ciaKeyScan[3],
    ciaKeyScan[4],ciaKeyScan[5],ciaKeyScan[6],ciaKeyScan[7],
    ciaKeyScan[8],ciaKeyScan[9],ciaKeyScan[10]);
    printstrvdc(Rect[0]+12,Rect[1]+3,appCtrlTxt2Co,StrBuf);

    sprintf(StrBuf,"%4u%4u",ciaJoy1,ciaJoy2);
    printstrvdc(Rect[0]+12,Rect[1]+5,appCtrlTxt2Co,StrBuf);

    sprintf(StrBuf,"%4u%4u%4u%4u",sidPot1X,sidPot1Y,sidPot2X,sidPot2Y);
    printstrvdc(Rect[0]+12,Rect[1]+7,appCtrlTxt2Co,StrBuf);

    sprintf(StrBuf,"%4u%4u%4u%4u",sidMouse1X,sidMouse1Y,sidMouse2X,sidMouse2Y);
    printstrvdc(Rect[0]+12,Rect[1]+9,appCtrlTxt2Co,StrBuf);
  }
  while(ciaKeyScan[7] != 127);
#asm
  ei
#endasm
  drawmenu(appMenuRect);
}

void dispclock(void)
{
  ciaTODStr TODStr;

  gettodcia(cia1,appTOD);
  todstrcia(appTOD,TODStr);
  printstrvdc(6,0,appClockCo,TODStr);
  gettodcia(cia2,appTOD);
  todstrcia(appTOD,TODStr);
  TODStr[8] = 0;                          /* get rid of am/pm extension */
  printstrvdc(71,0,appClockCo,TODStr);
}

void init(void)
{
  settodcia(cia2,appTOD);
  clearsid();
  savevdc();
  mapvdc();
  appChSetBufPtr = NULL;
}

void run(void)
{
  char  InKey;

  winvdc(21,5,58,10,vdcAltChrSet+vdcDarkGreen,"Info");
  printstrvdc(23,7,vdcAltChrSet+vdcBlink+vdcLightGreen,
  "Saving character sets to buffer");
  if(savechrsets())     /* check if vdc in 16k mode */
  {
    drawmenu(appMenuRect);
    do
    {
      while (!(kbhit()))
        dispclock();
      InKey = toupper(getch());
      switch (InKey)
      {
        case 'A':
          controlswin(appControlRect);
          break;
        case 'B':
          soundwin(appSoundRect);
          break;
        case 'C':
          playraw(appRawName,appHz);
          break;
        case 'D':
          ilace80x50text();
          break;
        case 'E':
          graphics640x200();
          break;
        case 'F':
          pcx640x200(appPcxName1);
          break;
        case 'G':
          graphics640x480();
          break;
        case 'H':
          pcx640x480(appPcxName2);
          break;
        case 'S':
          set64kmode();
          break;
      }
    }
    while (InKey != 'X');
  }
}

void done(void)
{
  clearsid();
  if(appChSetBufPtr != NULL)
    free(appChSetBufPtr);
  restorevdc();     /* restore registers saved by savevdc() */
  putchar(0x1A);    /* adm-3a clear-home cursor */
}
