/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <vdc.h>

/* plot circle points in eights */

void circlepointsvdc(int XC, int YC, int X, int Y)
{
  setpixivdc(XC+X,YC+Y);
  setpixivdc(XC-X,YC+Y);
  setpixivdc(XC+X,YC-Y);
  setpixivdc(XC-X,YC-Y);
  setpixivdc(XC+Y,YC+X);
  setpixivdc(XC-Y,YC+X);
  setpixivdc(XC+Y,YC-X);
  setpixivdc(XC-Y,YC-X);
}

/* draw circle in 640 x 680 interlace bit map using bresenham's algorithm */

void circleivdc(int XC, int YC, int R)
{
  int P, X, Y;

  X = 0;          /* select first point as (x,y) = (0,r) */
  Y = R;
  P = 3-(R << 1);
  while(X < Y)
  {
    circlepointsvdc(XC,YC,X,Y);
    if(P < 0)
      P += (X << 2)+6;      /* next point (x+1,y) */
    else
    {
      P += ((X-Y) << 2)+10; /* next point (x+1,y-1) */
      Y--;
    }
    X++;
  }
  if(X == Y)
    circlepointsvdc(XC,YC,X,Y);
}
