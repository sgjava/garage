{
Global include for units and programs.  Define the 'Production' label to
delete debugging information, etc.  'UseDLL' allows the VGA unit to be
overlayed in a DLL.
}

{$DEFINE Production}
{.$DEFINE UseDLL}

{$IFDEF Production}
  {$A+,B-,D-,E+,F-,I+,K+,L-,N+,P-,Q-,R-,S-,T-,V-,W+,Y-}
{$ELSE}
  {$A+,B-,D+,E+,F-,I+,K+,L+,N+,P-,Q+,R+,S+,T-,V-,W+,Y+}
{$ENDIF}
