{
SG Tools (C) 1992 Parsec, Inc.

The timer module allows you to use CIA #2 TOD clock as a timer.
}

const

  cia2TODTen = $dd08;
  cia2TODSec = $dd09;
  cia2TODMin = $dd0a;
  cia2TODHrs = $dd0b;
  cia2ConRegB = $dd0f;

var

  todTen, todSec, todMin, todHrs : byte;

procedure GetTOD;

begin
  todHrs := PortIn (cia2TODHrs);
  todMin := PortIn (cia2TODMin);
  todSec := PortIn (cia2TODSec);
  todTen := PortIn (cia2TODTen)
end;

procedure SetTOD (hh,mm,ss,tt : byte);

begin
  PortOut (cia2ConRegB,$00);
  PortOut (cia2TODHrs,hh);
  PortOut (cia2TODMin,mm);
  PortOut (cia2TODSec,ss);
  PortOut (cia2TODTen,tt)
end;
