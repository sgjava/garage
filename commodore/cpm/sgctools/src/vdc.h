/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#define vdcStatusReg 0xD600    /* vdc status register */
#define vdcDataReg   0xD601    /* vdc data register */

#define vdcHzTotal          0  /* vdc internal registers */
#define vdcHzDisp           1
#define vdcHzSyncPos        2
#define vdcVtHzSyncWidth    3
#define vdcVtTotal          4
#define vdcVtTotalAdj       5
#define vdcVtDisp           6
#define vdcVtSyncPos        7
#define vdcIlaceMode        8
#define vdcChTotalVt        9
#define vdcCurStScanLine   10
#define vdcCurEndScanLine  11
#define vdcDspStAddrHi     12
#define vdcDspStAddrLo     13
#define vdcCurPosHi        14
#define vdcCurPosLo        15
#define vdcLightPenVt      16
#define vdcLightPenHz      17
#define vdcUpdAddrHi       18
#define vdcUpdAddrLo       19
#define vdcAttrStAddrHi    20
#define vdcAttrStAddrLo    21
#define vdcChDspHz         22
#define vdcChDspVt         23
#define vdcVtSmScroll      24
#define vdcHzSmScroll      25
#define vdcFgBgColor       26
#define vdcAddrIncPerRow   27
#define vdcChSetStAddr     28
#define vdcUlScanLineCnt   29
#define vdcWordCnt         30
#define vdcCPUData         31
#define vdcBlkCpySrcAddrHi 32
#define vdcBlkCpySrcAddrLo 33
#define vdcDispEnableSt    34
#define vdcDispEnableEnd   35
#define vdcRamRefresh      36

#define vdcBlack        0      /* vdc rgb colors */
#define vdcDarkGray     1
#define vdcDarkBlue     2
#define vdcLightBlue    3
#define vdcDarkGreen    4
#define vdcLightGreen   5
#define vdcDarkCyan     6
#define vdcLightCyan    7
#define vdcDarkRed      8
#define vdcLightRed     9
#define vdcDarkPurple  10
#define vdcLightPurple 11
#define vdcDarkYellow  12
#define vdcLightYellow 13
#define vdcMediumGray  14
#define vdcWhite       15

#define vdcAltChrSet 0x80      /* vdc text mode attribute bits */
#define vdcRvsVid    0x40
#define vdcUnderline 0x20
#define vdcBlink     0x10
#define vdcRed       0x08
#define vdcGreen     0x04
#define vdcBlue      0x02
#define vdcIntensity 0x01

#define vdcCurSolid  0         /* vdc cursor modes used by setcursorvdc() */
#define vdcCurNone   1
#define vdcCurRate16 2
#define vdcCurRate32 3

#define vdcMaxBlock      255   /* vdc character set stuff */
#define vdcCharsPerSet   256
#define vdcMaxCharBytes  32

#define vdcOddFldOfs     21360 /* 640 X 480 interlace odd field offset */

extern uchar invdc(uchar RegNum);
extern void outvdc(uchar RegNum, uchar RegVal);
extern void mapvdc(void);
extern void savevdc(void);
extern void restorevdc(void);

extern void fillmemvdc(ushort FillMem, ushort FillLen, uchar Filler);
extern void copymemvdc(ushort SMem, ushort DMem, ushort CopyLen);

extern uchar * memtobufvdc(ushort VidMem, ushort CopyLen);
extern void buftomemvdc(uchar *BufPtr, ushort VidMem, ushort CopyLen);

extern uchar is64kvdc(void);
extern void set64kvdc(void);
extern void attrsoffvdc(void);
extern void attrsonvdc(void);
extern void setcursorvdc(uchar Top, uchar Bottom, uchar Mode);
extern void setcharvdc(ushort CharMem);
extern void setdsppagevdc(ushort DPage, ushort APage);

extern void clrscrvdc(uchar Ch);
extern void clrattrvdc(uchar Attr);
extern void filldspvdc(uchar X, uchar Y, uchar CLen, uchar Ch);
extern void fillattrvdc(uchar X, uchar Y, uchar ALen, uchar Attr);
extern void copydspvdc(ushort SDPage, ushort SAPage, ushort DDPage, ushort DAPage);

extern void scrollupvdc(uchar X1, uchar Y1, uchar X2, uchar Y2);
extern void scrolldownvdc(uchar X1, uchar Y1, uchar X2, uchar Y2);
extern void clrwinvdc(uchar X1, uchar Y1, uchar X2, uchar Y2, uchar Ch);
extern void clrwinattrvdc(uchar X1, uchar Y1, uchar X2, uchar Y2, uchar Ch);
extern void winvdc(uchar X1, uchar Y1, uchar X2, uchar Y2, uchar Attr, char *Title);

extern void printstrvdc(uchar X, uchar Y, uchar Attr, char *TextStr);

extern void setbitmapvdc(ushort DispMem, ushort AttrMem, uchar F, uchar B);
extern void clrbitmapvdc(uchar Filler);
extern void setpixvdc(int X, int Y);
extern void linevdc(int X1, int Y1, int X2, int Y2);
extern void ellipsevdc(int XC, int YC, int A, int B);
extern void printbmvdc(uchar X, uchar Y, uchar Attr, char *TextStr);

extern void set80x50textvdc(void);
extern void setbitmapintvdc(ushort DispMem, ushort AttrMem, uchar F, uchar B);
extern void setpixivdc(int X, int Y);
extern void lineivdc(int X1, int Y1, int X2, int Y2);
extern void ellipseivdc(int XC, int YC, int A, int B);
extern void printbmivdc(uchar X, uchar Y, char *TextStr);
