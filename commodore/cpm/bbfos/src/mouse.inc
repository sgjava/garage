{
SG Tools Pro (C) 1992 Steve Goldsmith

The Mouse module allows you to read the 1351 and compatible mouses in port 2
}

{sid pot addrs}

const

  sidPotX = $d419;
  sidPotY = $d41a;

{global mouse vars}

var

  mseX, mseY : byte;

{read 1351 mouse, port 2, proportional mode
 and return x, y value >= 0 and <= 63 }

procedure ReadMouse2;

var

  NewX, NewY : byte;

begin
  NewX := PortIn (sidPotX) and $7f; {read new pos and}
  NewY := PortIn (sidPotY) and $7f; {mask out high bit}
  if NewX < $7f then   {if new pos <> $7f then}
    mseX := NewX shr 1; {cur pos = new pos div 2}
  if NewY < $7f then
    mseY := NewY shr 1
end;
