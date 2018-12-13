{
Blue Bastards From Outer Space (C) 1992 Steve Goldsmith
C128 CP/M support from SG Tools (C) 1992 Parsec, Inc. and
SG Tools Pro (C) 1992 Steve Goldsmith

Game control module
}

procedure PhaseIn;

var

  I : byte;

begin
  for I := appStartPhase to appEndPhase do
  begin
    ClrAttrVDC (appPhaseColors[I]);
    FlipPageVDC;
    Delay (500)
  end
end;

procedure PhaseOut;

var

  I : byte;

begin
  for I := appEndPhase downto appStartPhase do
  begin
    ClrAttrVDC (appPhaseColors[I]);
    FlipPageVDC;
    Delay (500)
  end
end;

procedure DrawDeskTop;

begin
  ClrScrVDC (appWallPaperChr);
  ClrAttrVDC (appWallPaperColor);
  DrawWinVDC (2,5,76,18,appTitleWinColor,'');
  FWriteVDC (28,7,vdcBlink or vdcDarkBlue,appTitleStr1);
  FWriteVDC (28,8,vdcBlink or vdcDarkBlue,appTitleStr2);
  FWriteVDC (32,10,vdcUnderline+vdcLightBlue,appTitleStr3);
  FWriteVDC (19,12,vdcDarkCyan,appTitleStr4);
  FWriteVDC (4,15,vdcLightCyan,appTitleStr5);
  FWriteVDC (4,16,vdcLightCyan,appTitleStr6)
end;

procedure DrawBase;

var

   Y : byte;

begin
  ClrScrVDC (appGameScrClr);    {clear screen}
  ClrAttrVDC (appGameScrColor); {clear screen attributes}
  FWriteVDC (appStatusX,appStatusY,appStatusColor,appStatusText);
  for Y := appWallYStart to appWallYEnd do
  begin
    FillDispVDC (appLeftWallX,Y,appWallLen,appWallChr);
    FillAttrVDC (appLeftWallX,Y,appWallLen,appBaseColor);
    FillDispVDC (appRightWallX,Y,appWallLen,appWallChr);
    FillAttrVDC (appRightWallX,Y,appWallLen,appBaseColor)
  end;
  for Y := appBottomYStart to appBottomYEnd do
  begin
    FillDispVDC (appBottomXStart,Y,appBottomLen,appWallChr);
    FillAttrVDC (appBottomXStart,Y,appBottomLen,appBaseColor)
  end;
  for Y := appFirstLaser to appLastLaser do
    FWriteVDC (appLasers[Y].X,appLasers[Y].Y,
    appLaserColor,appLasers[Y].ObjStr);
  for Y := appFirstCell to appLastCell do
    FWriteVDC (appCells[Y].X,appCells[Y].Y,
    appCellColor,appCells[Y].ObjStr)
end;

procedure KillLaser (L : byte);

begin
  FWriteVDC (appCells[L].X,appCells[L].Y,
  appGameScrColor,appCellClr);
  FWriteVDC (appLasers[L].X,appLasers[L].Y,
  appGameScrColor,appCellClr);
  appLasersLeft := appLasersLeft-1;
  appLasers[L].Active := false;
  KillLaserSound
end;

procedure RepairLaser (L : byte);

begin
  if appLasers[L].Active = false then
  begin
    if appActiveLaser <> L then
      FWriteVDC (appLasers[L].X,appLasers[L].Y,
      appLaserColor,appLasers[L].ObjStr)
    else
      FWriteVDC (appLasers[L].X,appLasers[L].Y,
      appActLaserColor,appLasers[L].ObjStr);
    FWriteVDC (appCells[L].X,appCells[L].Y,
    appCellColor,appCells[L].ObjStr);
    appLasersLeft := appLasersLeft+1;
    appLasers[L].Active := true;
    RepairLaserSound
  end
end;

procedure MoveBastards;

var

  I,J : byte;
  Detect : ChrSprStr;

begin
  EraseShip;
  for I := appFirstBastard to appLastBastard do
    EraseBastard (I);
  for I := appFirstBastard to appLastBastard do
  begin
    if (Random (appBastardRan)=0) and
    (not appBastards[I].DispFlag) then
      SetBastard (I,appBastardPoints,Random (appBastardRanX)+appWallLen,3,
      0,1,appBastardColor,true);
    Detect := MoveBastard (I);
    if Detect <> appCellClr then
      for J := appFirstLaser to appLastLaser do
        if (appLasers[J].Active) and
        (appBastards[I].Y = appLasers[J].Y) and
        ((appBastards[I].X = appLasers[J].X-1) or
        (appBastards[I].X = appLasers[J].X) or
        (appBastards[I].X = appLasers[J].X+1)) then
        begin
          KillBastard (I);
          KillLaser (J)
        end
        else
          if (appLasers[J].Active) and
          (appBastards[I].Y = appCells[J].Y) and
          ((appBastards[I].X = appCells[J].X-1) or
          (appBastards[I].X = appCells[J].X) or
          (appBastards[I].X = appCells[J].X+1)) then
          begin
            KillBastard (I);
            KillLaser (J)
          end;
      if Pos (appWall,Detect) <> 0 then
        KillBastard (I)
      else
        if (appShip.DispFlag) and
           (appBastards[I].DispFlag) and
           (appBastards[I].Y = appShip.Y) and
           ((appBastards[I].X = appShip.X-1) or
           (appBastards[I].X = appShip.X) or
           (appBastards[I].X = appShip.X+1)) then
           begin
             KillBastard (I);
             KillShip;
             KillShipSound
           end
  end;
  BastardMoveSound
end;

procedure MoveRepairShip;

begin
  if (Random (appShipRandom)=0) and
  (not appShip.DispFlag) then
  begin
    appShipCell := Random (appLastCell+1);
    SetShip (appBastardPoints,appCells[appShipCell].X,2,
    0,1,appShipColor,true);
  end;
  if MoveShip then
  begin
    RepairLaser (appShipCell);
    KillShip
  end
end;

procedure ActivateLaser (N : byte);

begin
  if appLasers[N].Active then
  begin
    if appLasers[appActiveLaser].Active then
      FWriteVDC (appLasers[appActiveLaser].X,appLasers[appActiveLaser].Y,
      appLaserColor,appLasers[appActiveLaser].ObjStr);
    FWriteVDC (appLasers[N].X,appLasers[N].Y,
    appActLaserColor,appLasers[N].ObjStr);
    appActiveLaser := N
  end
end;

procedure ShootLaser (L : byte);

var

  I : byte;

begin
  with appLasers[L] do
  begin
    if Active then
    begin
      LaserSound;
      MoveBastards;
      FillDispVDC (appBeamX,Y,appBeamLen,appBeam);
      DrawShip;
      DrawBastards;
      FillAttrVDC (appBeamX,Y,appBeamLen,appBeamColor);
      FlipPageVDC;
      for I := appFirstBastard to appLastBastard do
        if (appBastards[I].Y = Y) and (appBastards[I].DispFlag) then
        begin
          appScore := appScore+appBastards[I].Points;
          if appScore > appHiScore then
          appHiScore := appScore;
          appBastardsKilled := appBastardsKilled+1;
          if (appBastardsKilled = appBastardLevel) and
          (appBastardRan > 1) then
          begin
            appBastardRan := appBastardRan-appBastardRanInc;
            appBastardsKilled := 0
          end;
          KillBastard (I);
          KillBastardSound
        end;
      if (appShip.DispFlag) and (appShip.Y = Y) then
      begin
        KillShip;
        KillShipSound
      end;
      FillDispVDC (appBeamX,Y,appBeamLen,appGameScrClr);
      FillAttrVDC (appBeamX,Y,appBeamLen,appGameScrColor);
      FWriteVDC (appScoreX,appStatusY,appStatusColor,IntStr (appScore));
      FWriteVDC (appHiScoreX,appStatusY,appStatusColor,IntStr (appHiScore))
    end
  end
  end;

procedure JoyControl;

var

  JoyVal : byte;

begin
  JoyVal := ReadJoy2;
  if JoyVal and joyLeft = 0 then
  begin
    if (JoyVal and joyUp = 0) then
      ActivateLaser (0)
    else
      if (JoyVal and joyDown = 0) then
        ActivateLaser (2)
      else
        ActivateLaser (1)
  end
  else
    if JoyVal and joyRight = 0 then
    begin
      if (JoyVal and joyUp = 0) then
        ActivateLaser (3)
      else
        if (JoyVal and joyDown = 0) then
          ActivateLaser (5)
        else
          ActivateLaser (4)
  end;
  if JoyVal and joyFire = 0 then
    ShootLaser (appActiveLaser)
end;

procedure InitGame;

begin
  Randomize;
  appScore := 0;
  if appScore >= appHiScore then
    appHiScore := appScore;
  appLasersLeft := appLastLaser+1;
  appLasers := appLaserDft;
  appActiveLaser := 0;
  appBastardRan := appBastardRanStart;
  appBastardsKilled := 0;
  InitBastards (0,1,78,24);
  InitShip (0,1,78,appWallYEnd);
  DrawBase;
  PhaseIn;
  DrawBase;
  ActivateLaser (0)
end;
