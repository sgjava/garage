{
SG Tools Pro (C) 1992 Steve Goldsmith

Z Blaster 4 bit digitized sound player.  Sample data must be in 4 bit
uncompressed format.
}

procedure Play4Sample (SamSta, SamLen : integer);

var

  SS, SL : integer;
  SA : byte;

begin
  SS := SamSta;
  SL := SamLen;
  InLine (
  $2A/SamSta/         {ld      hl,(samsta)     ;hl = sample start addr}
  $ED/$5B/SamLen/     {ld      de,(samlen)     ;de = sample length}
  $7B/                {ld      a,e             ;a = e}
  $B7/                {or      a               ;a = a or a}
  $28/$01/            {jr      Z,endif1        ;if a = 0 then}
  $14/                {inc     d               ; d = d+1}
              {endif1:                         ;endif}
              {rep1:                           ;repeat}
  $01/$0D/$DD/        {ld      bc,icr2         ; bc = timea2 addr}
              {rep2:                           ; repeat}
  $ED/$78/            {in      a,(c)           ;  a = timer lo}
  $CB/$47/            {bit     0,a             ;}
  $28/$FA/            {jr      Z,rep2          ; until interrupt flag set}
  $7E/                {ld      a,(hl)          ; a = sample byte}
  $0F/                {rrca                    ; a = a div 16}
  $0F/                {rrca                    ;}
  $0F/                {rrca                    ;}
  $0F/                {rrca                    ;}
  $E6/$0F/            {and     0fh             ; 4 bit nibble}
  $01/$18/$D4/        {ld      bc,sidvol       ; bc = sidvol addr}
  $ED/$79/            {out     (c),a           ; set volume}
  $01/$0D/$DD/        {ld      bc,icr2         ; bc = timea2 addr}
              {rep3:                           ; repeat}
  $ED/$78/            {in      a,(c)           ;  a = timer lo}
  $CB/$47/            {bit     0,a             ;}
  $28/$FA/            {jr      Z,rep3          ; until interrupt flag set}
  $7E/                {ld      a,(hl)          ; a = sample byte}
  $E6/$0F/            {and     0fh             ; a = a and 15}
  $01/$18/$D4/        {ld      bc,sidvol       ; bc = sidvol addr}
  $ED/$79/            {out     (c),a           ; set volume}
  $23/                {inc     hl              ; hl = hl+1}
  $1D/                {dec     e               ;}
  $20/$D6/            {jr      nz,rep1         ;}
  $15/                {dec     d               ; de = de-1}
  $20/$D3             {jr      nz,rep1         ;until de = 0}
  )
end;
