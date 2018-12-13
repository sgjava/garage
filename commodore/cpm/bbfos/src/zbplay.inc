{
SG Tools Pro (C) 1992, 1993 Steve Goldsmith

Z Blaster digitized sound player.  Sample data must be in 1 bit uncompressed
square wave format.  Covox Voice Master can make this type of file.
}

const

  cia2TimerA     = $dd04; {cia 2 timer a lo byte}
  cia2ContRegA   = $dd0e; {cia 2 control register a}
  cia2IntContReg = $dd0d; {cia 2 int control register}
  ciaTimerRes    = 10227; {cia timer resolution div 100}

procedure SetCIA2TimerA (Latch : integer);

var

  R : byte;

begin
  R := PortIn (cia2IntContReg);      {clear cia 2 icr status bits}
  PortOut (cia2IntContReg,$7f);      {clear all cia 2 icr irq enable bits}
  PortOut (cia2TimerA,Lo (Latch));   {cia2 timer a lo latch}
  PortOut (cia2TimerA+1,Hi (Latch)); {cia 2 timer a hi latch}
  PortOut (cia2ContRegA,$11)         {load latch and start timer}
end;

procedure PlaySample (SamSta, SamLen : integer; SamAmp : byte);

var

  SS, SL : integer;
  SA : byte;

begin
  SS := SamSta;
  SL := SamLen;
  SA := SamAmp;
  InLine (
  $DD/$2A/SamSta/   {ld      ix,(samsta)     ;ix = sample start addr}
  $2A/SamLen/       {ld      hl,(samlen)     ;hl = sample length}
  $7D/              {ld      a,l             ;a = l}
  $B7/              {or      a               ;a = a or a}
  $28/$01/          {jr      Z,endif1        ;if a = 0 then}
  $24/              {inc     h               ; h = h+1}
            {endif1:                         ;endif}
            {rep1:                           ;repeat}
  $1E/$08/          {ld      e,08h           ; e = 8 bits to count}
  $DD/$56/$00/      {ld      d,(ix+0)        ; d = sample byte}
            {rep2:                           ; repeat}
  $01/$0D/$DD/      {ld      bc,icr2         ;  bc = timea2 addr}
            {rep3:                           ;  repeat}
  $ED/$78/          {in      a,(c)           ;   a = timer lo}
  $CB/$47/          {bit     0,a             ;}
  $28/$FA/          {jr      Z,rep3          ;  until interrupt bit set}
  $3E/$00/          {ld      a,00h           ;  a = volume for 0 bits}
  $CB/$02/          {rlc     d               ;  get sample bit}
  $30/$03/          {jr      nc,endif2       ;  if carry=1 then}
  $3A/SamAmp/       {ld      a,(samamp)      ;   a = volume for 1 bits}
            {endif2:                         ;  endif}
  $01/$18/$D4/      {ld      bc,sidvol       ;  bc = sidvol addr}
  $ED/$79/          {out     (c),a           ;  set volume}
  $1D/              {dec     e               ;  e = e-1}
  $20/$E6/          {jr      nz,rep2         ; until e = 0}
  $DD/$23/          {inc     ix              ; ix = ix+1}
  $2D/              {dec     l               ; l = l-1}
  $20/$DC/          {jr      nz,rep1         ; until l = 0}
  $25/              {dec     h               ; h = h-1}
  $20/$D9           {jr      nz,rep1         ;until h = 0}
  )
end;
