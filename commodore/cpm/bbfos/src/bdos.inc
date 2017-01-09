{
SG Tools (C) 1992 Parsec, Inc.

Common BDOS constants
}

{BDOS function numbers}

const

  bdosDirectCon    = $06;
  bdosSelectDisk   = $0e;
  bdosSearchFirst  = $11;
  bdosSearchNext   = $12;
  bdosCurrentDisk  = $19;
  bdosSetDMAAddr   = $1a;
  bdosUserCode     = $20;
  bdosSetErrorMode = $2d;

{error modes}

  bdosRetErrMode     = $ff;
  bdosRetDispErrMode = $fe;
  bdosDefErrMode     = $fd;

{direct console I/O modes}

  bdosConInStat = $ff;
  bdosConStat   = $fe;
  bdosConIn     = $fd;

{BDOS memory locations}

  bdosDefaultFCB = $5c;

type

  bdosNameStr = string[8];
  bdosExtStr = string[4];
  bdosPathStr = string[15];
  bdosPDMABuf = ^bdosDMABuf;
  bdosDMABuf = array[0..127] of byte;
  bdosPFCBRec = ^bdosFCBRec;
  bdosFCBRec = record
    Drive : byte;
    FileName : array[0..7] of char;
    FileType : array[0..2] of char;
    Extent : byte;
    Reserved1 : byte;
    Reserved2 : byte;
    RecCount : byte;
    Reserved3 : array[0..15] of byte;
    CurrentRec : byte;
    RandomRec : array[0..2] of byte
  end;
