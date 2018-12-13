{
SG Tools (C) 1992 Parsec, Inc.

The VDC module allows you to access the 8563 VDC chip.
}

{read byte value from 8563 VDC register}

function ReadVDC (Reg : byte) : byte;

var

  VDCReg : byte;

begin
  VDCReg := Reg;
  Inline (
    $01/$00/$D6/                        {lxi       b,$d600  point BC to $d600}
    $3A/VDCReg/                         {lda       VDCReg   VDC reg}
    $ED/$79/                            {outp      a        VDC reg to read}
    $ED/$78/                            {inp       a        get VDC status}
    $CB/$7F/                            {bit       7,a      test status bit}
    $28/$FA/                            {jrz       rep      until bit high}
    $0C/                                {inr       c        point BC to $d601}
    $ED/$78/                            {inp       a        read VDC reg}
    $32/VDCReg                          {sta       VDCReg   stash result}
  );
  ReadVDC := VDCReg
end;

{write byte value to 8563 VDC register}

procedure WriteVDC (Reg   : byte;
                    Value : byte);

var

  VDCReg,
  VDCValue : byte;

begin
  VDCReg := Reg;
  VDCValue := Value;
  Inline (
    $01/$00/$D6/                        {lxi       b,$d600  point BC to VDC}
    $3A/VDCReg/                         {lda       a        VDC reg}
    $ED/$79/                            {outp      a        put reg in VDC}
    $ED/$78/                            {inp       a        get VDC reg}
    $CB/$7F/                            {bit       7,a      check status}
    $28/$FA/                            {jrz       Rep      until bit high}
    $0C/                                {inr       c        point BC data reg}
    $3A/VDCValue/                       {lda       b        value to store}
    $ED/$79                             {outp      a        put value in VDC reg}
  )
end;
