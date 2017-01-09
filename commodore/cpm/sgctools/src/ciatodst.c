/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#include <hitech.h>
#include <cia.h>

/* convert bcd byte to 2 char base 10 */

void todcharcia (uchar Bcd, char *TODStr)
{
  TODStr[0] = (Bcd >> 4)+48;
  TODStr[1] = (Bcd & 0x0F)+48;
}

/* convert cia tod bcd format to string */

void todstrcia (uchar *TOD, char *TODStr)
{
  if((TOD[0] & 0x80) == 0)
  {
    todcharcia(TOD[0],&TODStr[0]);
    TODStr[9] = 'A';
  }
  else
  {
    todcharcia((TOD[0] & 0x7F),&TODStr[0]);
    TODStr[9] = 'P';
  }
  TODStr[8] = ' ';
  TODStr[10] = 'M';
  TODStr[2] = ':';
  todcharcia(TOD[1],&TODStr[3]);
  TODStr[5] = ':';
  todcharcia(TOD[2],&TODStr[6]);
  TODStr[sizeof(ciaTODStr)-1] = 0;
}
