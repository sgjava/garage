{
Turbo Vision CyberTools 2.6
(C) 1994 Steve Goldsmith
All Rights Reserved

Commands and resource IDs used by CyberTerm app.
}

unit CTCmds;

{$I APP.INC}

interface

const

{app commands}

  cmShowClip      = 100;

  cmSaveConfig    = 1000;
  cmLoadConfig    = 1001;
  cmPhoneBook     = 1002;
  cmGeneral       = 1003;
  cmXmodemDown    = 1004;
  cmXmodemUp      = 1005;
  cmXmodem1KDown  = 1006;
  cmXmodem1KUp    = 1007;
  cmXmodem1KGDown = 1008;
  cmXmodem1KGUp   = 1009;
  cmYmodemDown    = 1010;
  cmYmodemUp      = 1011;
  cmYmodemGDown   = 1012;
  cmYmodemGUp     = 1013;
  cmZmodemDown    = 1014;
  cmZmodemUp      = 1015;
  cmKermitDown    = 1016;
  cmKermitUp      = 1017;
  cmAsciiDown     = 1018;
  cmAsciiUp       = 1019;
  cmAbout         = 1020;
  cmViewDoc       = 1021;
  cmColors        = 1022;
  cmNewFileList   = 1023;
  cmFileBrowse    = 1024;
  cmToggleVideo   = 1025;
  cmNewLogWin     = 1026;

{commands sent by tree window}

  cmAddFile       = 1040;

implementation

end.
