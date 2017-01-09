{
SG Tools Pro (C) 1992 Steve Goldsmith

The Z Blaster Record module creates 1 bit digitized data with the Covox Voice
Master in port 2.
}

const

  cia1DataPortRegA = $dc00;
  cia1DataDirRegA  = $dc02;

var

  zbrDDRSave : byte;

procedure InitVoiceMaster;

begin
  zbrDDRSave := PortIn (cia1DataDirRegA); {save ddr}
  PortOut (cia1DataDirRegA,$08);          {set ddr bit 3 output rest inputs}
  PortOut (cia1DataPortRegA,0);           {initilize digitizer}
end;

procedure RecVoiceMaster (SamSta, SamLen : integer);

var

  SS, SL : integer;

begin
  SS := SamSta;
  SL := SamLen;
  InLine (
  $DD/$2A/SamSta/  {ld      ix,(samsta)     ;ix = sample start addr}
  $2A/SamLen/      {ld      hl,(samlen)     ;hl = sample length}
           {rep1:                           ;repeat}
  $16/$00/         {ld      d,00h           ; d = freq byte}
  $1E/$08/         {ld      e,08h           ; e = 8 bits to count}
           {rep2:                           ; repeat}
  $01/$0D/$DD/     {ld      bc,icr2         ;  bc = timea2 addr}
           {rep3:                           ;  repeat}
  $ED/$78/         {in      a,(c)           ;   a = timer lo}
  $CB/$47/         {bit     0,a             ;}
  $28/$FA/         {jr      Z,rep3          ;  until}
  $01/$00/$DC/     {ld      bc,porta1       ;  bc = porta1 addr}
  $ED/$78/         {in      a,(c)           ;  a = porta1 value}
  $E6/$01/         {and     01h             ;  a = freq bit}
  $CB/$22/         {sla     d               ;  make room for next}
  $B2/             {or      d               ;  add new freq bit}
  $57/             {ld      d,a             ;  d = new freq byte}
  $1D/             {dec     e               ;  e = e-1}
  $20/$E9/         {jr      nz,rep2         ; until e = 0}
  $DD/$72/$00/     {ld      (ix+0),d        ; store freq byte in mem}
  $DD/$23/         {inc     ix              ; ix = ix+1}
  $2D/             {dec     l               ; l = l-1}
  $20/$DD/         {jr      nz,rep1         ; until l = 0}
  $25/             {dec     h               ; h = h-1}
  $20/$DA          {jr      nz,rep1         ;until h = 0}
  )
end;

procedure DoneVoiceMaster;

begin
  PortOut (cia1DataDirRegA,zbrDDRSave) {restore ddr}
end;
