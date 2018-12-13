{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Commands used by CyberEdit app.
}

unit CECmds;

{$I APP.INC}

interface

const

{tool bar commands}

  cmLoadFont     = 100;
  cmSaveFont     = 101;
  cmDirChange    = 102;
  cmShellToDos   = 103;
  cmScreenOpts   = 104;
  cmExit         = 105;
  cmBarHelp      = 106;

{app commands}

  cmLoadPCX      = 1000;
  cmSavePCX      = 1001;
  cmSaveConfig   = 1002;
  cmLoadConfig   = 1003;
  cmAbout        = 1004;
  cmAsciiTab     = 1005;
  cmViewDoc      = 1006;
  cmColors       = 1007;
  cmAdjPal       = 1008;
  cmCharSelector = 1009;
  cmRestoreDef   = 1010;
  cmToolBar      = 1011;

{character selector commands}

  cmCharSelected   = 1200;
  cmCharEdit       = 1201;
  cmCharChanged    = 1202;
  cmCharDelete     = 1203;
  cmCharPaste      = 1204;
  cmCharInvert     = 1205;
  cmCharLeft       = 1206;
  cmCharRight      = 1207;
  cmCharUp         = 1208;
  cmCharDown       = 1209;

implementation

end.
