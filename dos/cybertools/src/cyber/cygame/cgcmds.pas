{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Commands used by CyberGame app.
}

unit CGCmds;

{$I APP.INC}

interface

const

{app commands}

  cmLoadFont    = 1000;
  cmLoadPCX     = 1001;
  cmRestoreDef  = 1002;
  cmScreenOpts  = 1003;
  cmControlOpts = 1004;
  cmAdjPal      = 1005;
  cmSaveConfig  = 1006;
  cmLoadConfig  = 1007;
  cmAbout       = 1008;
  cmViewDoc     = 1009;
  cmColors      = 1010;
  cmNewGame     = 1011;

{animation dialog commands}

  cmAniOn   = 2000;
  cmAniOff  = 2001;
  cmAnimate = 2002;

implementation

end.
