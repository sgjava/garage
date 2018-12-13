{
SG Tools (C) 1992 Parsec, Inc.

The Keyboard Input module allows raw CP/M input.
}

const

{CP/M keyboard mapping}

  kbNoKey  = 0;
  kbCtrlA  = 1;  kbCtrlB  = 2;  kbCtrlC  = 3;  kbCtrlD  = 4;  kbCtrlE  = 5;
  kbCtrlF  = 6;  kbCtrlG  = 7;  kbCtrlH  = 8;  kbCtrlI  = 9;  kbCtrlJ  = 10;
  kbCtrlK  = 11; kbCtrlL  = 12; kbCtrlM  = 13; kbCtrlN  = 14; kbCtrlO  = 15;
  kbCtrlP  = 16; kbCtrlQ  = 17; kbCtrlR  = 18; kbCtrlS  = 19; kbCtrlT  = 20;
  kbCtrlU  = 21; kbCtrlV  = 22; kbCtrlW  = 23; kbCtrlX  = 24; kbCtrlY  = 25;
  kbCtrlZ  = 26; kbEsc    = 27; kbCtrlFS = 28; kbCtrlGS = 29; kbCtrlRS = 30;
  kbCtrlUS = 31; kbDel    = 127;

function GetKey (IoType : byte) : byte;

begin
  GetKey := BDos (bdosDirectCon,IoType)
end;
