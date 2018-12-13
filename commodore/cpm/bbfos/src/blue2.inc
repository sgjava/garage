{
Blue Bastards From Outer Space (C) 1992 Steve Goldsmith
C128 CP/M support from SG Tools (C) 1992 Parsec, Inc. and
SG Tools Pro (C) 1992 Steve Goldsmith

Sound module
}

procedure BastardMoveSound;

begin
  SetEnvelope (sidVoice1,0,0,1,1);
  SetFreq (sidVoice1,0,100);
  StartADS (sidVoice1,sidWaveNoi);
  StartRel (sidVoice1,sidWaveNoi)
end;

procedure ShipMoveSound;

begin
  SetEnvelope (sidVoice2,0,0,8,2);
  SetFreq (sidVoice2,0,100-appShip.Y);
  StartADS (sidVoice2,sidWaveTri);
  StartRel (sidVoice2,sidWaveTri)
end;

procedure LaserSound;

begin
  SetEnvelope (sidVoice3,0,0,6,3);
  SetFreq (sidVoice3,0,30);
  StartADS (sidVoice3,sidWaveSaw);
  StartRel (sidVoice3,sidWaveSaw)
end;

procedure KillLaserSound;

begin
  MultiPlay (appNameArr[6],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[5],appMaxVol,appVol)
end;

procedure KillShipSound;

begin
  MultiPlay (appNameArr[6],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[7],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[8],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[5],appMaxVol,appVol)
end;

procedure RepairLaserSound;

begin
  MultiPlay (appNameArr[6],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[7],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[11],appMaxVol,appVol)
end;

procedure KillBastardSound;

begin
  MultiPlay (appNameArr[10],appMaxVol,appVol)
end;

procedure KillBaseSound;

begin
  MultiPlay (appNameArr[0],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[1],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[5],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[9],appMaxVol,appVol)
end;

procedure TitleSound;

var

  I : byte;

begin
  MultiPlay (appNameArr[0],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[1],appMaxVol,appVol);
  Delay (400);
  MultiPlay (appNameArr[2],appMaxVol,appVol);
  Delay (100);
  MultiPlay (appNameArr[3],appMaxVol,appVol);
  for I := 7 downto 0 do
    MultiPlay (appNameArr[4],I shl 1+1,appVol)
end;

function TitleSong : byte;

var

  K, I : byte;

begin
  repeat
    I := 0;
    Delay (1000);
    repeat
      if appChordArr[I] > -1 then
        MultiPlay (appChordNameArr[appChordArr[I]],appMaxVol,appVol)
      else
        MultiPlay (appChordNameArr[appChordArr[0]],0,appVol);
      K := GetKey (bdosConInStat);
      I := I+1
    until (I > appMaxChord) or (K = kbEsc) or (K = kbCtrlM)
  until (K = kbEsc) or (K = kbCtrlM);
  TitleSong := K
end;
