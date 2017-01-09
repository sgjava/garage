{
SG Tools Pro (C) 1992 Steve Goldsmith

The Joystick module allows you to read joystick 2
}

const

  cia1DataPortRegA = $dc00;
  cia1DataDirRegA  = $dc02;

{joystick direction masks}

  joyNone      = $1f; joyFire      = $10;
  joyUp        = $01; joyDown      = $02;
  joyLeft      = $04; joyRight     = $08;
  joyUpLeft    = $05; joyUpRight   = $09;
  joyDownLeft  = $06; joyDownRight = $0a;

function ReadJoy2 : byte;

var

  RegSave : byte;

begin
  RegSave := PortIn (cia1DataDirRegA); {save ddr}
  PortOut (cia1DataDirRegA,$0);        {set ddr to all inputs}
  ReadJoy2 := PortIn (cia1DataPortRegA) and $1f; {read joystick 2}
  PortOut (cia1DataDirRegA,RegSave)    {restore ddr}
end;
