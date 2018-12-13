{
SG Tools (C) 1992 Parsec, Inc.

The port module allows you to access the C128's I/O chips.
}

{input byte from port with Z80 in e,(c) instruction}

function PortIn (PortAddr : integer) : integer;

var

  PA : integer;
  RV : byte;

begin
  PA := PortAddr;
  InLine (
  $ED/$4B/PA/  {ld      bc,(port)       ;bc = port addr}
  $ED/$78/     {in      a,(c)           ;a = port value}
  $32/RV       {ld      (rval),a        ;read value = a}
  );
  PortIn := RV
end;

{output byte to port with Z80 out (c),e instruction}

procedure PortOut (PortAddr : integer;
                   WriteVal : byte);

var

  WV : byte;
  PA : integer;

begin
  PA := PortAddr;
  WV := WriteVal;
  InLine (
  $ED/$4B/PA/ {ld      bc,(port)       ;bc = port addr}
  $3A/WV/     {ld      a,(wval)        ;a = write value}
  $ED/$79     {out     (c),a           ;port = a}
  )
end;
