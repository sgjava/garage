{
Blue Bastards From Outer Space (C) 1992 Steve Goldsmith
C128 CP/M support from SG Tools (C) 1992 Parsec, Inc. and
SG Tools Pro (C) 1992 Steve Goldsmith

Game declarations module
}

const

  appTitleWinColor = vdcLightBlue;
  appWallPaperColor = vdcLightCyan;
  appScrColor = vdcBlack;
  appWallPaperChr = 137;
  appTitleStr1 = #128#32#129#32#130#32#131#32#32#128#32#132#32#133#32#134#32#132#32#135#32#136#32#133;
  appTitleStr2 = #160#32#161#32#162#32#163#32#32#160#32#164#32#165#32#166#32#164#32#167#32#168#32#165;
  appTitleStr3 = 'From Outer Space';
  appTitleStr4 = #138' 1992 Steve Goldsmith All Rights Reserved';
  appTitleStr5 = 'Hold down [RETURN] to start or [ESC] to exit.  [ESC] during game play';
  appTitleStr6 = 'returns you to this screen.  Laser control requires joystick in port 2.';
  appGameScrColor = vdcBlack;
  appGameScrClr = 32;
  appStartPhase = 0;
  appEndPhase = 2;
  appPhaseColors : array[appStartPhase..appEndPhase] of byte =
  (
  vdcBlack,
  vdcDarkGray,
  vdcMediumGray
  );

  appLeftWallX = 0;
  appRightWallX = 76;
  appWallYStart = 2;
  appWallYEnd = 21;
  appWallLen = 4;
  appWallChr = 0;
  appWall = #0;

  appBottomXStart = 0;
  appBottomYStart = 22;
  appBottomYEnd = 24;
  appBottomLen = 80;
  appBaseColor = vdcMediumGray;

  appFirstLaser = 0;
  appLastLaser = 5;
  appLeftLaserX = 2;
  appRightLaserX = 76;
  appLeftLaser = #1#2;
  appRightLaser = #3#4;
  appLaserColor = vdcDarkGreen;
  appBeamX = appWallLen;
  appBeamLen = 72;
  appBeam = 9;
  appBeamColor = vdcLightYellow;
  appActLaserColor = vdcLightGreen;

  appFirstCell = 0;
  appLastCell = 5;
  appCellY = 23;
  appCell = #5#6;
  appCellClr = #32#32;
  appCellColor = vdcLightGreen;

  appStatusX = 0;
  appStatusY = 0;
  appScoreX = 65;
  appHiScoreX = 74;
  appStatusText =
  'Blue Bastards From Outer Space    '#138' 1992 Steve Goldsmith    Score       Hi';
  appStatusColor = vdcLightCyan;

  appBastardPoints = 1;
  appBastardLevel = 100;
  appBastardRanStart = 121;
  appBastardRanInc = 20;
  appBastardStr = #7#8;
  appBastardClrStr = #32#32;
  appFirstBastard = 0;
  appLastBastard = 9;
  appBastardRanX = 72;
  appBastardRanY = 3;
  appBastardColor = vdcDarkBlue;

  appShipRandom = 500;
  appShipStr = #10#11;
  appShipColor = vdcDarkPurple;

type

  ChrSprStr = string[2];
  ChrSprite = record
    X,
    Y,
    XMin,
    YMin,
    XMax,
    YMax,
    Points,
    XDir,
    YDir : integer;
    Attr : byte;
    DispFlag : boolean;
    ChrSprite : ChrSprStr;
  end;

  appObjStr = string[2];
  appObjRec = record
    Active : boolean;
    X,Y : byte;
    ObjStr : appObjStr;
  end;
  appLaserArr = array[appFirstLaser..appLastLaser] of appObjRec;
  appCellArr = array[appFirstCell..appLastCell] of appObjRec;

const

  appLaserDft : appLaserArr =
  (
  (Active:true;X:appLeftLaserX;Y:6;ObjStr:appLeftLaser),
  (Active:true;X:appLeftLaserX;Y:12;ObjStr:appLeftLaser),
  (Active:true;X:appLeftLaserX;Y:18;ObjStr:appLeftLaser),
  (Active:true;X:appRightLaserX;Y:6;ObjStr:appRightLaser),
  (Active:true;X:appRightLaserX;Y:12;ObjStr:appRightLaser),
  (Active:true;X:appRightLaserX;Y:18;ObjStr:appRightLaser)
  );

  appCells : appCellArr =
  (
  (Active:true;X:15;Y:appCellY;ObjStr:appCell),
  (Active:true;X:25;Y:appCellY;ObjStr:appCell),
  (Active:true;X:35;Y:appCellY;ObjStr:appCell),
  (Active:true;X:45;Y:appCellY;ObjStr:appCell),
  (Active:true;X:55;Y:appCellY;ObjStr:appCell),
  (Active:true;X:65;Y:appCellY;ObjStr:appCell)
  );

  appVol = 6;
  appMaxVol = 15;
  appMaxName = 11;
  appNameArr : array[0..appMaxName] of bdosPathStr =
  (
  'BLUE',
  'BASTARD',
  'FROM',
  'OUTER',
  'SPACE',
  'DESTROY',
  'LASER',
  'REPAIR',
  'SHIP',
  'BASE',
  'IMHIT',
  'COMPLETE'
  );

  appMaxChordName = 7;
  appChordNameArr : array[0..appMaxChordName] of bdosPathStr =
  (
  'GSEQ1',
  'GSEQ2',
  'GSEQ3',
  'GSEQ4',
  'GSEQ5',
  'GSEQ6',
  'GSEQ7',
  'GSEQ8'
  );

  appMaxChord = 54;
  appChordArr : array[0..appMaxChord] of integer =
  (
  0,1,2,-1,0,1,2,-1,0,1,2,
  6,7,
  3,3,3,4,3,3,3,4,
  5,5,5,4,3,4,
  3,3,3,4,3,3,3,4,
  5,5,5,4,5,4,
  3,3,3,4,3,3,3,4,
  5,5,5,4,4,4
  );

var

  appShipCell,
  appActiveLaser,
  appLasersLeft,
  appScore,
  appHiScore,
  appBastardRan,
  appBastardsKilled : integer;
  appLasers : appLaserArr;
  appBastards : array[appFirstBastard..appLastBastard] of ChrSprite;
  appShip : ChrSprite;
