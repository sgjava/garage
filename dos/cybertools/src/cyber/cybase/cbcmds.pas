{
Turbo Vision CyberTools 2.6 beta
(C) 1994 Steve Goldsmith
All Rights Reserved

Commands used by CyberBase app.
}

unit CBCmds;

{$I APP.INC}

interface

const

{app commands}

  cmOpenTable    = 200;
  cmCreateTable  = 201;
  cmCreateIndex  = 202;
  cmDeleteIndex  = 203;
  cmAppendTable  = 204;
  cmCopyTable    = 205;
  cmRenameTable  = 206;
  cmDeleteTable  = 207;
  cmEmptyTable   = 208;
  cmEncryptTable = 209;
  cmDecryptTable = 210;
  cmUpgradeTable = 211;
  cmAddPassword  = 212;
  cmShowClip     = 213;

  cmAbout        = 1000;
  cmEngineConfig = 1001;
  cmVideoToggle  = 1002;
  cmCalendar     = 1003;
  cmCalculator   = 1004;
  cmViewDoc      = 1005;
  cmColors       = 1006;
  cmSaveConfig   = 1007;
  cmLoadConfig   = 1008;
  cmNewFileList  = 1009;
  cmFileBrowse   = 1010;
  cmAddFile      = 1011;

implementation

end.
