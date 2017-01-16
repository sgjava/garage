{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Commands used by CyberAnimate app.
}

unit CACmds;

{$I APP.INC}

interface

const

{app commands}

  cmLoadFont    = 1000;
  cmLoadPCX2    = 1001;
  cmLoadPCX256  = 1002;
  cmPlaySnip    = 1003;
  cmMakeSnip    = 1004;
  cmDirChange   = 1005;
  cmRestoreDef  = 1006;
  cmScreenOpts  = 1007;
  cmAdjPal      = 1008;
  cmSaveConfig  = 1009;
  cmLoadConfig  = 1010;
  cmAbout       = 1011;
  cmViewDoc     = 1012;
  cmColors      = 1013;
  cmNewFileList = 1014;
  cmFileBrowse  = 1015;
  cmAddFile     = 1016;

{dialog commands}

  cmStep = 1100;
  cmPlay = 1101;
  cmPCX  = 1102;

implementation

end.
