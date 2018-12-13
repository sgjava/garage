{
SG Tools Pro (C) 1992 Steve Goldsmith

The SID module allows you to manipulate the SID chip.
}

const

  sidAddr = $d400;

{SID registers}

  sidVoice1 = $d400; sidVoice2 = $d407; sidVoice3 = $d40e; sidVolume = $d418;

{SID waveforms}

  sidWaveGate = $01; sidWaveSync = $02; sidWaveRing = $04; sidWaveTest = $08;
  sidWaveTri  = $10; sidWaveSaw  = $20; sidWaveSqu  = $40; sidWaveNoi  = $80;

procedure ClearSID;

var

  I : integer;

begin
  for I := sidAddr TO sidAddr+28 do
    PortOut (I,0)
end;

procedure SetVolume (Amp : byte);

begin
  PortOut (sidVolume,Amp)
end;

procedure SetEnvelope (Voice : integer;
                       Attack, Decay, Sustain, Release : byte);


begin
  PortOut (Voice+5,Attack*16+Decay);
  PortOut (Voice+6,Sustain*16+Release)
end;

procedure SetFreq (Voice : integer;
                   LowFreq, HighFreq : byte);

begin
  PortOut (Voice,LowFreq);
  PortOut (Voice+1,HighFreq)
end;

procedure StartADS (Voice : integer;
                    Waveform : byte);

begin
  PortOut (Voice+4,Waveform+sidWaveGate)
end;

procedure StartRel (Voice : integer;
                    Waveform : byte);

begin
  PortOut (Voice+4,Waveform)
end;
