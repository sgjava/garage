/*
SG C Tools 1.8

(C) 1993,1996 Steve Goldsmith
All Rights Reserved

Compiled with HI-TECH C 3.09 (CP/M-80).
*/

#define sidVoice1   0xD400 /* voices */
#define sidVoice2   0xD407
#define sidVoice3   0xD40E
#define sidCutoffLo 0xD415 /* cutoff filter */
#define sidCutoffHi 0xD416
#define sidResCtrl  0xD417 /* resonance control */
#define sidVolume   0xD418 /* master volume and filter select */
#define sidPotX     0xD419 /* paddle X */
#define sidPotY     0xD41A /* paddle Y */
#define sidEnvGen3  0xD41C

#define sidWaveGate 0x01 /* waveforms */
#define sidWaveSync 0x02
#define sidWaveRing 0x04
#define sidWaveTest 0x08
#define sidWaveTri  0x10
#define sidWaveSaw  0x20
#define sidWaveSqu  0x40
#define sidWaveNoi  0x80

#define sidLowPass   0x10 /* filter select settings */
#define sidBandPass  0x20
#define sidHighPass  0x40
#define sidVoice3Off 0x80

#define sidFilter1   0x01 /* filter resonance output settings */
#define sidFilter2   0x02
#define sidFilter3   0x04
#define sidFilterExt 0x08

extern void getpotssid(void);
extern void getmousesid(void);

extern void clearsid(void);
extern void volumesid(uchar Amp, uchar Filter);
extern void envelopesid(ushort Voice, uchar Attack, uchar Decay, uchar Sustain, uchar Release);
extern void freqsid(ushort Voice, ushort Freq);
extern void attacksid(ushort Voice, uchar Waveform);
extern void releasesid(ushort Voice, uchar Waveform);
extern void pulsewavesid(ushort Voice, ushort Width);

extern void playzb4sid(uchar *SamStart, ushort SamLen);
