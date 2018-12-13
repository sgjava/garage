{
Blue Bastards From Outer Space (C) 1992 Steve Goldsmith
C128 CP/M support from SG Tools (C) 1992 Parsec, Inc. and
SG Tools Pro (C) 1992 Steve Goldsmith

Character sprite control module
}

procedure SetBastard (B : byte;
                      P,X1,Y1,XD,YD : integer;
                      A : byte;
                      DF : boolean);

begin
  with appBastards[B] do
  begin
    Points := P;
    X := X1;
    Y := Y1;
    XDir := XD;
    YDir := YD;
    Attr := A;
    DispFlag := DF
  end
end;

procedure InitBastards (X1,Y1,X2,Y2 : integer);

var

  I : byte;

begin
  for I := appFirstBastard to appLastBastard do
  begin
    with appBastards[I] do
    begin
      XMin := X1;
      YMin := Y1;
      XMax := X2;
      YMax := Y2
    end;
    SetBastard (I,appBastardPoints,Random (appBastardRanX)+appWallLen,2,
    0,1,appBastardColor,false)
  end
end;

procedure EraseBastard (B : byte);

begin
  with appBastards[B] do
    if DispFlag then
      FWriteVDC (X,Y,appGameScrColor,appBastardClrStr)
end;

procedure KillBastard (B : byte);

begin
  with appBastards[B] do
  begin
    FWriteVDC (X,Y,appGameScrColor,appBastardClrStr);
    DispFlag := false
  end
end;

function MoveBastard (B : byte) : ChrSprStr;

var

  DispOfs : integer;

begin
  with appBastards[B] do
  begin
    if DispFlag then
    begin
      if (Y > YMin) and (Y < YMax) and
      (X > XMin) and (X < XMax) then
      begin
        if Random (appBastardRanY)=0 then
        begin
          if Random (5)=0 then
            YDir := -1
          else
            YDir := 0
        end
        else
          YDir := 1;
        if Random (6)=0 then
        begin
          if Random (2)=0 then
            XDir := 1
          else
            XDir := -1
        end;
        X := X+XDir;
        Y := Y+YDir;
        DispOfs := vdcSettings.DispMem+Y*vdcSettings.ScrHorz+X;
        WriteVDC (vdcUpdateAddrHi,Hi (DispOfs));
        WriteVDC (vdcUpdateAddrLo,Lo (DispOfs));
        MoveBastard := Chr (ReadVDC (vdcCPUData))+
        Chr(ReadVDC (vdcCPUData));
        FWriteVDC (X,Y,Attr,appBastardStr)
      end
      else
        KillBastard (B)
    end
    else
      MoveBastard := appBastardClrStr
  end
end;

procedure DrawBastards;

var

  I : byte;

begin
  for I := appFirstBastard to appLastBastard do
    with appBastards[I] do
      if DispFlag then
        FWriteVDC (X,Y,Attr,appBastardStr)
end;

procedure SetShip (P,X1,Y1,XD,YD : integer;
                   A : byte;
                   DF : boolean);

begin
  with appShip do
  begin
    Points := P;
    X := X1;
    Y := Y1;
    XDir := XD;
    YDir := YD;
    Attr := A;
    DispFlag := DF
  end
end;

procedure InitShip (X1,Y1,X2,Y2 : integer);

begin
  with appShip do
  begin
    XMin := X1;
    YMin := Y1;
    XMax := X2;
    YMax := Y2
  end;
  SetShip (0,0,0,0,0,0,false)
end;

procedure EraseShip;

begin
  with appShip do
    if DispFlag then
      FWriteVDC (X,Y,appGameScrColor,appBastardClrStr)
end;

procedure KillShip;

begin
  with appShip do
  begin
    FWriteVDC (X,Y,appGameScrColor,appBastardClrStr);
    DispFlag := false
  end
end;

procedure DrawShip;

begin
  with appShip do
    if DispFlag then
      FWriteVDC (X,Y,Attr,appShipStr)
end;

function MoveShip : boolean;

begin
  with appShip do
  begin
    if DispFlag then
    begin
      if Y < YMax then
      begin
        X := X+XDir;
        Y := Y+YDir;
        FWriteVDC (X,Y,Attr,appShipStr);
        MoveShip := false;
        ShipMoveSound
      end
      else
        MoveShip := true
    end
    else
      MoveShip := false
  end
end;
