/*
SG C Tools 1.8 Demo

(C) 1994,2017 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

/* 64k vdc locations */

#define appBitMapMem 0x4000
#define appAttrMem   0x0800

/* colors used by this app */

#define appClockCo     vdcAltChrSet+vdcRvsVid+vdcLightCyan
#define appMenuScrCo   vdcBlack
#define appDeskCo      vdcAltChrSet+vdcMediumGray
#define appMenuTxtCo   vdcAltChrSet+vdcLightCyan
#define appMenuWinCo   vdcAltChrSet+vdcLightBlue
#define appIScrCo      vdcBlack
#define appIDeskCo     vdcAltChrSet+vdcMediumGray
#define appIWinTxtCo   vdcAltChrSet+vdcDarkBlue
#define appIWinCo      vdcAltChrSet+vdcDarkBlue
#define appGrTextCo    (vdcDarkGray << 4) | vdcWhite
#define appSoundWinCo  vdcAltChrSet+vdcWhite
#define appSoundTxt1Co vdcAltChrSet+vdcLightGreen+vdcBlink
#define appSoundTxt2Co vdcAltChrSet+vdcDarkGreen
#define appCtrlTxt1Co  vdcAltChrSet+vdcRvsVid+vdcLightYellow
#define appCtrlTxt2Co  vdcAltChrSet+vdcWhite
#define appCtrlWinCo   vdcAltChrSet+vdcLightCyan

extern uchar     vdcScrHorz;
extern ushort    vdcDispMem;
extern ushort    vdcAttrMem;
extern ushort    vdcCharMem;
extern ushort    vdcCharMemSize;
extern ushort    vdcBitMapMemSize;

extern uchar     sidPot1X;
extern uchar     sidPot1Y;
extern uchar     sidPot2X;
extern uchar     sidPot2Y;
extern uchar     sidMouse1X;
extern uchar     sidMouse1Y;
extern uchar     sidMouse2X;
extern uchar     sidMouse2Y;

extern uchar     ciaJoy1;
extern uchar     ciaJoy2;
extern ciaKeyRec ciaKeyScan;

extern ushort    pcxXSize;
extern ushort    pcxYSize;

extern void initbitmapi64k(void);
extern void initbitmap64k(void);
extern void initbitmap16k(void);
extern uchar savechrsets(void);
extern void restorechrsets(void);
extern void draw16khelp(uchar Rect[]);
extern void drawmenu(uchar Rect[]);
extern void graphicsview(void);
extern void set64kmode(void);
extern void ilace80x50text(void);
extern void graphics640x200(void);
extern void pcx640x200(char * FileName);
extern void graphics640x480(void);
extern void pcx640x480(char * FileName);

extern void delay(ushort D);
extern void planesound(void);
extern void shotssound(void);
extern void explodesound(void);
extern void bombdropsound(void);
extern void soundseq(uchar Rect[], uchar Seq);
extern void soundwin(uchar Rect[]);
extern void playraw(char * FileName, ulong Hz);

extern void controlswin(uchar Rect[]);
extern void dispclock(void);

extern void init(void);
extern void run(void);
extern void done(void);
