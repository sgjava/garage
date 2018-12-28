# CP/M                                                

A lot of the code I developed for the C128 was specifically for CP/M 80 column mode. This was more interesting to me than what native mode had to offer. I could use high level languages like Pascal and C and easily integrate Z80 Assembler or in line machine code to speed things up when needed. The Turbo Pascal editor was excellent for its time and offered an easy way to edit text files.

Categories
* [SG C Tools](https://github.com/sgjava/garage/tree/master/commodore/cpm/sgctools) - C API for C128 in CPM with low level access to VDC, CIA and SID, fast high resolution graphics, digitized sound player, etc.
* [Blue Bastards from Outer Space](https://github.com/sgjava/garage/tree/master/commodore/cpm/bbfos) - Graphic game for C128 CP/M that utilizes digitized guitar chords to compose a intro song, voice for game actions and intro. This was written in Turbo Pascal 3.01 using SG C Tools for Pascal.

## Programming considerations
* The VDC should be configured to its default CP/M 3.0 settings at the start and end of each program.
```
Display memory        0000h
Attribute memory      0800h
Character definitions 2000h
```
* This includes restoring character definitions if you use memory at 2000h for bit maps, etc. Setting the VDC to 64K mode wipes out memory used in 16K mode, so be sure to save the character definitions to a memory buffer or file before using 64K mode. The VDC remains in 64K mode until you do a cold boot or warm boot with the C128's reset button.

* Most of the VDC functions do not check parameters for range violations. Range checking should be performed at the application level. There are times when you may want to write to a off screen memory location. For this reason there is no need to waste time and code doing range checks. Just be aware of the implications. A renegade program may accidentally wipe out character definitions or other important memory regions forcing you to reboot. Basically, just return to CP/M the way it was before your program ran. See DEMO.C for a complete example of setting various VDC modes and exiting back to CP/M correctly.

* CP/M relies on the CIAs for communication to the outside world just like in native 64/128 modes. With this in mind it is best not to change certain registers. I have found it safe to use CIA #2's TOD clock, timers A and B and disable all interrupt sources. You can also safely read the keyboard and joy sticks via CIA #1 if you disable interrupts. My low level key scan function reads all key positions into an array of 11 bytes. See page 642 of the [Commodore 128 Programmer's Reference](http://www.pagetable.com/docs/Commodore%20128%20Programmer's%20Reference%20Guide.pdf) for the key positions in the matrix. You can tell joy stick signals from a key short because the joy stick shorts a whole row in the matrix instead of one bit like a key press. See page 32 of the [1351 Mouse User's manual](http://www.commodore.ca/manuals/funet/cbm/manuals/1351-mouse.txt) for more info.

* CP/M uses voice 1 of the SID to produce a key click. You can use the SID just as you would in native 128 mode with one exception. Since CP/M writes to the SID during key presses it may affect a sound in progress. You can disable interrupts to eliminate this problem.

* The four bit Z Blaster engine requires the sound data's high nibbles to come first. You can easily swap the nibbles once the sample is in memory if needed. The maximum sample rate is about 15 KHz.

* The PCX engines for 640 X 200 and 640 X 480 require you to toggle off the disk status line. The status line updates during disk I/O and changes the VDC update address which throws off the engines.

### Other CP/M resources
* [The HUMONGOUS CP/M Software Archives](http://www.classiccmp.org/cpmarchives)
* [Funet.fi C128 CP/M stuff](http://zimmers.net/anonftp/pub/cpm/sys/c128/index.html) (you'll see my stuff here)

### FreeBSD License
Copyright (c) Steven P. Goldsmith

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
