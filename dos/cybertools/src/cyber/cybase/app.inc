{
Global include for main program and units
}

{
The 'Production' label deletes debugging information, etc.
}

{$DEFINE Production}

{$IFDEF Production}
  {$A+,B-,D-,E+,F-,I+,K+,L-,N+,P-,Q-,R-,S-,T-,V-,W+,Y-}
{$ELSE}
  {$A+,B-,D+,E+,F-,I+,K+,L+,N+,P-,Q+,R+,S+,T-,V-,W+,Y+}
{$ENDIF}
