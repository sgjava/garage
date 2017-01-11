#Commodore 64                                               

I took the natural Commodore progression from VIC 20 to C64 and finally the C128. The C64 was one of the best game machines of that period, but I really bought it to continue working in Assembler code and possibly other languages besides BASIC. As time progressed I was coding in HLLs such as Pascal on other platforms, but there was still something challenging about crafting a good Assembler based program. In college I took Structured Assembler for the IBM 360/370 (the book's author was also the professor). You will see the difference in my early and later code :)

I started coding in machine code in 1980 or so on a Ohio Scientific Challenger 2P in high school. The A/V department was using it for a character generator (what a waste I thought) and I built my first 6502 program on the OSI. After getting a VIC 20 in early 1981 I started working on BASIC/machine language hybrid games using BASIC for the controller and machine language for graphics and sound. It was cumbersome translating op codes and building basic loaders (I used to code on paper first just like the old IBM 360 later in college). I typed in a Machine Language monitor (from Jim Butterfield I think) and it was the next level of evolution. Eventually I progressed into Rebel Assembler (the Turbo Pascal of Commodore Assemblers) after using the Commodore Macro Assembler Development System which was super slow and step intensive. 

Categories
* [Boink](https://github.com/sgjava/garage/tree/master/commodore/c64/boink) Simpler version of the Amiga Boing Ball demo using rotating Commodore logo running in the background.
* [Digisound](https://github.com/sgjava/garage/tree/master/commodore/c64/digisound) Demo of using samples from a Covox Voice Master with Commodore logos bouncing around. You could use any 1 bit PCM data up to 26 KHz!
* [Digiblaster 64](https://github.com/sgjava/garage/tree/master/commodore/c64/digiblaster64) Shows you how to play back 1 bit PCM sound samples using a BASIC controller. This uses the variable play back rate code. The 22K and 26K routines only play back at that speed.

### Rebel assembler
If you want to use Rebel assembler (one of the best I've used for the C64):
* [d64](https://github.com/sgjava/garage/raw/master/commodore/c64/rebel-assembler.d64.zip)
* [Manual](https://github.com/sgjava/garage/raw/master/commodore/c64/rebel-assembler-manual.pdf.zip)

### Commodore Macro Assembler Development System
This is a slow and cumbersome way to work on Assembler code. The ML monitors are great for debugging, but the process from source to executable is too many steps. At least with VICE you can warp mode through all the slow stuff.
* [d64](https://github.com/sgjava/garage/raw/master/commodore/c64/mads.d64.zip)
* [Manual](https://github.com/sgjava/garage/raw/master/commodore/c64/mads.txt.zip)

### FreeBSD License
Copyright (c) Steven P. Goldsmith

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

