/*
 * Copyright (c) Steven P. Goldsmith. All rights reserved.
 *
 * C128 CP/M VIC Demo!
 *
 */

#include <sys.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include <hitech.h>

/*
 * VIC offset in memory (bank 1)
 */
ushort vicOfs = 0x4000;

/*
 * Color memory
 */
ushort colMem = 0xd800;

/*
 * Lookup for fast pixel selection
 */
uchar bitTable[8] = { 128, 64, 32, 16, 8, 4, 2, 1 };

/*
 * Sprite definition
 */
uchar sprData[] = { 0x00, 0x7e, 0x00, 0x03, 0xff, 0xc0, 0x07, 0xff, 0xe0, 0x1f,
        0xff, 0xf8, 0x1f, 0xff, 0xf8, 0x3f, 0xff, 0xfc, 0x7f, 0xff, 0xfe, 0x7f,
        0xff, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0x7f, 0xff, 0xfe, 0x7f, 0xff, 0xfe, 0x3f,
        0xff, 0xfc, 0x1f, 0xff, 0xf8, 0x1f, 0xff, 0xf8, 0x07, 0xff, 0xe0, 0x03,
        0xff, 0xc0, 0x00, 0x7e, 0x00 };

/*
 * Scan standard and extended keys.
 */
uchar *keyScan() {
    uchar saveDdrA, saveDdrB, keyMask, i;
    uchar *ciaKeyScan = malloc(11);
    /* Save CIA 1 DDRs */
    saveDdrA = inp(0xdc02);
    saveDdrB = inp(0xdc03);
    outp(0xdc02, 0xff);
    outp(0xdc03, 0x00);
    /* Scan standard keys */
    for (i = 0, keyMask = 1; i < 8; i++, keyMask <<= 1) {
        outp(0xdc00, ~keyMask);
        ciaKeyScan[i] = inp(0xdc01);
    }
    /* Scan extended keys */
    for (keyMask = 1; i < 11; i++, keyMask <<= 1) {
        outp(0xd02f, ~keyMask);
        outp(0xdc00, 0xff);
        ciaKeyScan[i] = inp(0xdc01);
    }
    outp(0xdc00, 0x7f);
    outp(0xd02f, 0xff);
    /* Restore CIA 1 DDRs */
    outp(0xdc02, saveDdrA);
    outp(0xdc03, saveDdrB);
    return ciaKeyScan;
}

/*
 * Return single row of key scan.
 */
readKey(uchar index) {
    uchar *ciaKeyScan = keyScan();
    uchar key = ciaKeyScan[index];
    free(ciaKeyScan);
    return key;
}

/*
 * Read VDC register.
 */
uchar inVdc(uchar regNum) {
    outp(0xd600, regNum);
    while ((inp(0xd600) & 0x80) == 0x00)
        ;
    return (inp(0xd601));
}

/*
 * Write VDC register.
 */
void outVdc(uchar regNum, uchar regVal) {
    outp(0xd600, regNum);
    while ((inp(0xd600) & 0x80) == 0x00)
        ;
    outp(0xd601, regVal);
}

/*
 * Copy VDC character set to VIC memory.
 */
void vdcToChrMem(uchar *chr, ushort vdcMem, ushort chars) {
    register uchar c;
    ushort i;
    outVdc(18, (uchar) (vdcMem >> 8));
    outVdc(19, (uchar) vdcMem);
    for (i = 0; i < chars; i++) {
        for (c = 0; c < 8; c++) {
            chr[(i * 8) + c] = inVdc(31);
        }
        /* Skip bottom 8 bytes of VDC data */
        for (c = 0; c < 8; c++) {
            inVdc(31);
        }
    }
}

/*
 * Set VIC to MMU bank 0 or 1.
 */
setVicMmuBank(uchar mmuRcr) {
    /* Set MMU RCR bit 6 to point VIC to MMU bank */
    outp(0xd506, (inp(0xd506) & 0xbf) | (mmuRcr * 0x40));
}

/*
 * Set VIC bank to 0 - 3.
 */
setVicBank(uchar vicBank) {
    uchar saveDdr = inp(0xdd02);
    /* Set DDR port A to write */
    outp(0xdd02, inp(0xdd02) | 0x03);
    /* Set VIC to bank 0-3 */
    outp(0xdd00, (inp(0xdd00) & 0xfc) | (3 - vicBank));
    outp(0xdd02, saveDdr);
}

/*
 * Set ecm, bmm and mcm to 0 (off) or 1 (on).
 */
setVicMode(uchar ecm, uchar bmm, uchar mcm) {
    /* Set enhanced color and char/bitmap mode */
    outp(0xd011, (inp(0xd011) & 0x9f) | ((ecm * 0x40) + (bmm * 0x20)));
    /* Set multicolor mode */
    outp(0xd016, (inp(0xd016) & 0xef) | (mcm * 0x10));
}

/*
 * Set screen 0-15 and character set 0-7 memory locations.
 */
void setVicScrMem(uchar scrMem, uchar chrMem) {
    outp(0xd018, (scrMem * 16) + (chrMem * 2));
}

/*
 * Set character mode.
 */
setChrMode(uchar mmuRcr, uchar vicBank, uchar scrMem, uchar chrMem) {
    setVicMmuBank(mmuRcr);
    setVicBank(vicBank);
    setVicMode(0, 0, 0);
    setVicScrMem(scrMem, chrMem);
}

/*
 * Clear screen using 16 bit word.
 */
void clearScr(uchar *scr, uchar c) {
    register ushort i;
    ushort *scr16 = (ushort *) scr;
    ushort c16 = (c << 8) + c;
    for (i = 0; i < 500; i++) {
        scr16[i] = c16;
    }
}

/*
 * Clear screen color memory.
 */
void clearCol(uchar color) {
    register ushort i;
    for (i = 0; i < 1000; i++) {
        outp(colMem + i, color);
    }
}

/*
 * Set screen 0-15 and bitmap 0-1 memory locations.
 */
void setVicBmpMem(uchar scrMem, uchar bmpMem) {
    outp(0xd018, (scrMem * 16) | (bmpMem * 8));
}

/*
 * Set bitmap mode.
 */
setBmpMode(uchar mmuRcr, uchar vicBank, uchar scrMem, uchar bmpMem) {
    setVicMmuBank(mmuRcr);
    setVicBank(vicBank);
    setVicMode(0, 1, 0);
    setVicBmpMem(scrMem, bmpMem);
}

/*
 * Clear bitmap using 16 bit word.
 */
void clearBmp(uchar *bmp) {
    register ushort i;
    ushort *bmp16 = (ushort *) bmp;
    for (i = 0; i < 4000; i++) {
        bmp16[i] = 0x0000;
    }
}

/*
 * Set pixel.
 */
void setPix(uchar *bmp, ushort x, uchar y) {
    ushort pixByte = 40 * (y & 0xf8) + (x & 0x1f8) + (y & 0x07);
    bmp[pixByte] = bmp[pixByte] | (bitTable[x & 0x07]);
}

/*
 * Draw line using modified bresenham's algorithm.
 */
void drawLine(uchar *bmp, int x1, int y1, int x2, int y2) {
    int xInc, yInc, dx, dy, x, y, c, r;
    dx = x2 - x1; /* delta x */
    if (dx < 0) /* adjust for negative delta */
    {
        xInc = -1;
        dx = -dx;
    } else
        xInc = 1;
    dy = y2 - y1; /* delta y */
    if (dy < 0) /* adjust for negative delta */
    {
        yInc = -1;
        dy = -dy;
    } else if (dy > 0)
        yInc = 1;
    else
        yInc = 0;
    x = x1;
    y = y1;
    setPix(bmp, x, y); /* set first point */
    if (dx > dy) /* always draw with positive increment */
    {
        r = dx >> 1;
        for (c = 1; c <= dx; c++) {
            x += xInc;
            r += dy;
            if (r >= dx) {
                y += yInc;
                r -= dx;
            }
            setPix(bmp, x, y);
        }
    } else {
        r = dy >> 1;
        for (c = 1; c <= dy; c++) {
            y += yInc;
            r += dx;
            if (r >= dy) {
                x += xInc;
                r -= dy;
            }
            setPix(bmp, x, y);
        }
    }
}

/*
 * Draw rectangle using line drawing.
 */
void drawRect(uchar *bmp, int x1, int y1, int x2, int y2) {
    /* Top */
    drawLine(bmp, x1, y1, x2, y1);
    /* Left */
    drawLine(bmp, x1, y1, x1, y2);
    /* Right */
    drawLine(bmp, x2, y1, x2, y2);
    /* Bottom */
    drawLine(bmp, x1, y2, x2, y2);
}

/*
 * Draw ellipse using digital differential analyzer (DDA) method.
 */
void drawEllipse(uchar *bmp, int xc, int yc, int a, int b) {
    long aa = (long) a * a; /* a^2 */
    long bb = (long) b * b; /* b^2 */
    long aa2 = aa << 1; /* 2(a^2) */
    long bb2 = bb << 1; /* 2(b^2) */
    {
        long x = 0;
        long y = b;
        long xbb2 = 0;
        long yaa2 = y * aa2;
        long errVal = -y * aa; /* b^2 x^2 + a^2 y^2 - a^2 b^2 -b^2x */
        while (xbb2 <= yaa2) /* draw octant from top to top right */
        {
            setPix(bmp, xc + x, yc + y);
            setPix(bmp, xc + x, yc - y);
            setPix(bmp, xc - x, yc + y);
            setPix(bmp, xc - x, yc - y);
            x += 1;
            xbb2 += bb2;
            errVal += xbb2 - bb;
            if (errVal >= 0) {
                y -= 1;
                yaa2 -= aa2;
                errVal -= yaa2;
            }
        }
    }
    {
        long x = a;
        long y = 0;
        long xbb2 = x * bb2;
        long yaa2 = 0;
        long errVal = -x * bb;
        while (xbb2 > yaa2) /* draw octant from right to top right */
        {
            setPix(bmp, xc + x, yc + y);
            setPix(bmp, xc + x, yc - y);
            setPix(bmp, xc - x, yc + y);
            setPix(bmp, xc - x, yc - y);
            y += 1;
            yaa2 += aa2;
            errVal += yaa2 - aa;
            if (errVal >= 0) {
                x -= 1;
                xbb2 -= bb2;
                errVal -= xbb2;
            }
        }
    }
}

/*
 * Print to bitmap screen.
 */
void printBmp(uchar *bmp, uchar *scr, uchar *chr, uchar x, uchar y, uchar color,
        char *str) {
    ushort *bmp16 = (ushort *) bmp;
    ushort *chr16 = (ushort *) chr;
    ushort bmpOfs = (y * 160) + (x * 4);
    ushort colOfs = (y * 40) + x;
    ushort len = strlen(str);
    ushort i, chrOfs, destOfs;
    uchar c;
    for (i = 0; i < len; i++) {
        chrOfs = str[i] * 4;
        destOfs = i * 4;
        scr[colOfs + i] = color;
        for (c = 0; c < 4; c++) {
            bmp16[bmpOfs + destOfs + c] = chr16[chrOfs + c];
        }
    }
}

/*
 * Print centered text on top line in bitmap.
 */
void bannerBmp(uchar *bmp, uchar *scr, uchar *chr, char *str) {
    uchar x = ((40 - strlen(str)) / 2) - 1;
    printBmp(bmp, scr, chr, x, 0, 0x36, str);
}

/*
 * Draw lines.
 */
void lines(uchar *bmp, uchar *scr, uchar *chr) {
    ushort i;
    clearBmp(bmp);
    clearScr(scr, 16);
    bannerBmp(bmp, scr, chr, " Lines ");
    for (i = 0; i < 16; i++) {
        drawLine(bmp, 0, 0, i * 20, 199);
        drawLine(bmp, 319, 0, 319 - (i * 20), 199);
    }
    while (readKey(0) != 253)
        ;
}

/*
 * Draw rectangles.
 */
void rects(uchar *bmp, uchar *scr, uchar *chr) {
    ushort x1, x2;
    uchar y1, y2;
    clearBmp(bmp);
    clearScr(scr, 16);
    bannerBmp(bmp, scr, chr, " Rectangles ");
    while (readKey(0) != 253) {
        x1 = (rand() / 130);
        y1 = (rand() / 210) + 10;
        x2 = x1 + (rand() / 330) + 6;
        y2 = y1 + (rand() / 665) + 6;
        if (x1 > 314) {
            x1 = 314;
        } else if (y1 > 192) {
            y1 = 194;
        } else if (x2 > 317) {
            x2 = 318;
        } else if (y2 > 197) {
            y2 = 197;
        }
        drawRect(bmp, x1, y1, x2, y2);
    }
}

/*
 * Draw ellipses.
 */
void ellipses(uchar *bmp, uchar *scr, uchar *chr) {
    ushort i;
    clearBmp(bmp);
    clearScr(scr, 16);
    bannerBmp(bmp, scr, chr, " Ellipses ");
    for (i = 1; i < 9; i++) {
        drawEllipse(bmp, 159, 99, i * 19, i * 10);
    }
    while (readKey(0) != 253)
        ;
}

/*
 * Draw chars in all color combos.
 */
void showColors(uchar *bmp, uchar *scr, uchar *chr) {
    uchar r, c;
    clearBmp(bmp);
    clearScr(scr, 16);
    bannerBmp(bmp, scr, chr, " Color combos for chars in bitmap ");
    for (r = 0; r < 15; r++) {
        for (c = 0; c < 15; c++) {
            printBmp(bmp, scr, chr, c + 12, r + 2, (r * 16) + c, "*");
        }
    }
    while (readKey(0) != 253)
        ;
}

/*
 * Bitmap based demo.
 */
void bitmap(uchar *bmp, uchar *scr, uchar *chr) {
    srand(inp(0xd012));
    setBmpMode(1, 1, 2, 1);
    lines(bmp, scr, chr);
    rects(bmp, scr, chr);
    ellipses(bmp, scr, chr);
    showColors(bmp, scr, chr);
}

/*
 * Enable sprite and configure for both screens.
 */
void enableSpr(uchar *scr1, uchar *scr2, uchar *spr, uchar sprNum, uchar sprCol) {
    uchar sprMem = ((ushort) spr - vicOfs) / 64;
    /* Set sprite memory location for both screens */
    scr1[1016 + sprNum] = sprMem;
    scr2[1016 + sprNum] = sprMem;
    /* Sprite color */
    outp(0xd027 + sprNum, sprCol);
    /* Sprite enable */
    outp(0xd015, inp(0xd015) | (1 << sprNum));
}

/*
 * Disable sprite.
 */
void disableSpr(uchar sprNum) {
    /* Sprite disable */
    outp(0xd015, inp(0xd015) & ~(1 << sprNum));
}

/*
 * Set sprite location.
 */
void setSprLoc(uchar sprNum, ushort x, uchar y) {
    /* Set sprite X */
    if (x > 255) {
        outp(0xd010, inp(0xd010) | (1 << sprNum));
        outp(0xd000 + (sprNum * 2), x - 256);
    } else {
        outp(0xd010, inp(0xd010) & ~(1 << sprNum));
        outp(0xd000 + (sprNum * 2), x);
    }
    /* Sprite Y */
    outp(0xd001 + (sprNum * 2), y);
}

/*
 * Animate sprites.
 */
void sprites(uchar *scr1, uchar *scr2, uchar *spr, uchar numSpr) {
    uchar i;
    ushort sprX[8];
    uchar sprY[8];
    int xDir[8], yDir[8];
    clearScr(scr1, 32);
    clearCol(0);
    /* Set screen to scr1 */
    outp(0xd018, (inp(0xd018) & 0x0e) | (((ushort) scr1 - vicOfs) / 64));
    /* Enable sprites */
    for (i = 0; i < numSpr; i++) {
        sprX[i] = rand() / 105;
        sprY[i] = rand() / 166;
        xDir[i] = 1;
        yDir[i] = 1;
        setSprLoc(i, sprX[i], sprY[i]);
        enableSpr(scr1, scr2, spr, i, i + 1);
    }
    while (readKey(0) != 253) {
        /* Calculate sprite pos */
        for (i = 0; i < numSpr; i++) {
            sprX[i] += xDir[i];
            sprY[i] += yDir[i];
            if (sprX[i] > 319) {
                sprX[i] = 319;
                xDir[i] = -1;
            } else if (sprX[i] < 24) {
                sprX[i] = 24;
                xDir[i] = 1;
            } else if (sprY[i] > 230) {
                sprY[i] = 230;
                yDir[i] = -1;
            } else if (sprY[i] < 50) {
                sprY[i] = 50;
                yDir[i] = 1;
            }
        }
        /* Move sprites */
        for (i = 0; i < numSpr; i++) {
            setSprLoc(i, sprX[i], sprY[i]);
        }
    }
    /* Disable all sprites */
    outp(0xd015, 0x00);
}

/*
 * Print to text screen.
 */
void printScr(uchar *scr, uchar x, uchar y, uchar color, char *str) {
    ushort scrOfs = (y * 40) + x;
    ushort colOfs = colMem + scrOfs;
    ushort len = strlen(str);
    ushort i;
    for (i = 0; i < len; i++) {
        scr[scrOfs + i] = str[i];
        outp(colOfs + i, color);
    }
}

/*
 * Bounce color text string around screen.
 */
void textBounce(uchar *scr) {
    uchar x, y, xDir, yDir, color;
    clearScr(scr, 32);
    clearCol(1);
    x = 0;
    y = 0;
    xDir = 1;
    yDir = 1;
    color = 1;
    srand(inp(0xd012));
    while (readKey(0) != 253) {
        printScr(scr, x, y, color, "Fast screen output for CP/M");
        x += xDir;
        y += yDir;
        if (x > 12) {
            xDir = -1;
        } else if (x < 1) {
            xDir = 1;
        }
        if (y > 23) {
            yDir = -1;
        } else if (y < 1) {
            yDir = 1;
        }
        if (rand() > 26000) {
            color = (rand() / 2184) + 1;
        }
    }
}

/*
 * Scroll down and render top line on non-visable screen.
 */
void snowPage(uchar *scr1, uchar *scr2) {
    uchar regVal;
    register ushort i;
    ushort *scr1w = (ushort *) scr1;
    ushort *scr2w = (ushort *) scr2 + 20;
    /* Scroll using 16 bit words */
    for (i = 0; i < 480; i++) {
        scr2w[i] = scr1w[i];
    }
    /* Draw random snow */
    for (i = 0; i < 40; i++) {
        if (rand() > 27000) {
            scr2[i] = 46;
        } else {
            scr2[i] = 32;
        }
    }
    regVal = (inp(0xd018) & 0x0e) | (((ushort) scr2 - vicOfs) / 64);
    while (inp(0xd012) != 0xff)
        ;
    outp(0xd018, regVal);
}

/*
 * Create snow falling effect.
 */
void snow(uchar *scr1, uchar *scr2) {
    uchar *scr = scr1;
    clearScr(scr1, 32);
    clearScr(scr2, 32);
    clearCol(1);
    while (readKey(0) != 253) {
        if (scr == scr1) {
            snowPage(scr1, scr2);
            scr = scr2;
        } else {
            snowPage(scr2, scr1);
            scr = scr1;
        }
    }
}

/*
 * Side scroll and page flip.
 */
void scrollPage(uchar *scr1, uchar *scr2, uchar y, uchar newChar) {
    uchar i, regVal;
    /* Scroll bottom 3 lines left */
    for (i = 0; i < 3; i++) {
        memcpy(scr2 + (i * 40) + 880, scr1 + (i * 40) + 881, 39);
        scr2[(i * 40) + 919] = 32;
    }
    scr2[(y * 40) + 39] = newChar;
    regVal = (inp(0xd018) & 0x0e) | (((ushort) scr2 - vicOfs) / 64);
    while (inp(0xd012) != 0xfc)
        ;
    outp(0xd018, regVal);
}

/*
 * Side scroller with sprite.
 */
void scroll(uchar *scr1, uchar *scr2, uchar *chr, uchar *spr) {
    uchar i, sprNum;
    int sprY = 100;
    int dir = 1;
    int y = 24;
    int chrPos = 7;
    uchar *scr = scr1;
    sprNum = 0;
    clearScr(scr1, 32);
    clearScr(scr2, 32);
    clearCol(1);
    /* Set botom 2 lines to gray */
    for (i = 0; i < 40; i++) {
        outp(colMem + 920 + i, 15);
        outp(colMem + 960 + i, 12);
    }
    /* Define chars 0-7 as decending bars */
    for (i = 0; i < 8; i++) {
        chr[(i * 8) + i] = 0xff;
    }
    /* Copy sprite data to sprite memory */
    for (i = 0; i < sizeof(sprData); i++) {
        spr[i] = sprData[i];
    }
    /* Enable sprite */
    enableSpr(scr1, scr2, spr, sprNum, 1);
    setSprLoc(sprNum, 136, 100);
    while (readKey(0) != 253) {
        if (rand() > 27000) {
            if (dir == 1) {
                dir = -1;
            } else {
                dir = 1;
            }
        }
        chrPos += dir;
        if (chrPos < 0) {
            if (y > 22) {
                y--;
                chrPos = 7;
            } else {
                chrPos = 0;
            }
        } else if (chrPos > 7) {
            if (y < 24) {
                y++;
                chrPos = 0;
            } else {
                chrPos = 7;
            }
        }
        sprY += dir;
        if (sprY < 100) {
            sprY = 100;
        } else if (sprY > 225) {
            sprY = 225;
        }
        if (scr == scr1) {
            scrollPage(scr1, scr2, y, chrPos);
            scr = scr2;
        } else {
            scrollPage(scr2, scr1, y, chrPos);
            scr = scr1;
        }
        while (inp(0xd012) != 0xfc)
            ;
        /* Sprite Y */
        outp(0xd001 + (sprNum << 1), sprY);
    }
    /* Disable sprite */
    disableSpr(sprNum);
}

/*
 * Text/sprite based demos.
 */
void text(uchar *scr1, uchar *scr2, uchar *chr, uchar *spr) {
    setChrMode(1, 1, 2, 0);
    /* Copy VDC alt char set to VIC mem */
    vdcToChrMem(chr, 0x3000, 256);
    srand(inp(0xd012));
    textBounce(scr1);
    snow(scr1, scr2);
    scroll(scr1, scr2, chr, spr);
    sprites(scr1, scr2, spr, 8);
    clearCol(1);
}

main() {
    /* Allocate memory, so program doesn't effect VIC memory */
    uchar *vicMem = (uchar *) malloc(22000);
    /* Assign pointers to various VIC memory locations */
    uchar *chr = (uchar *) vicOfs;
    uchar *scr1 = (uchar *) vicOfs + 0x0800;
    uchar *scr2 = (uchar *) vicOfs + 0x0c00;
    uchar *spr = (uchar *) vicOfs + 0x2000;
    uchar *bmp = (uchar *) vicOfs + 0x2000;
    printf(
            "\nBuf:  %04x\nChr:  %04x\nScr1: %04x\nScr2: %04x\nSpr:  %04x\nBmp:  %04x",
            vicMem, chr, scr1, scr2, spr, bmp);
    puts("\n\nPress Return for next screen!");
    /* Clear CIA 1 ICR status */
    inp(0xdc0d);
    /* Clear all CIA 1 IRQ enable bits */
    outp(0xdc0d, 0x7f);
    /* Clear CIA 2 ICR status */
    inp(0xdd0d);
    /* Clear all CIA 2 IRQ enable bits */
    outp(0xdd0d, 0x7f);
    text(scr1, scr2, chr, spr);
    bitmap(bmp, scr1, chr);
    /* CPM default */
    setChrMode(0, 0, 11, 3);
    /* Enable CIA 1 IRQ */
    outp(0xdc0d, 0x82);
    free(vicMem);
}
