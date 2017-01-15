#Turbo Vision CyberTools                                                

Turbo Vision (tm) is a great object-oriented framework for building DOS applications. Unfortunately, fonts, graphics, 256 color animation, ANSI terminals, generic database browsers and other 'drop-in' tools are not included. You could spend a small fortune on commercial or Shareware libraries just to find out you bought a disjointed set of TV gizmos and gadgets in beta testing. Your DOS Real and DPMI applications need a competitive edge to be successful. Turbo Vision CyberTools gives you that edge by creating professional applications with a flexible set of tools. Powerful tools are important, but applications that show you how to use the library are equally important. All too often you get a 'powerful' commercial library with 100 line demo programs that barely scratch the surface (or gasp, have error handling). With CyberTools you get full blown applications and not empty skeleton code.

CyberTools was used all over the world in everything from embedded systems to foreign language products.

###CyberFont

 ![Cyedit](images/cyedit.png)
 ![Cygraph](images/cygraph.png)
 ![Cygame](images/cygame.png)

CyberFont (tm) provides fonts, graphics, PCX images, sprites, bitmap animation and DAC palettes. CyberFont is simply the fastest and easiest to use Turbo Vision graphics enhancement around. Now with new Windows (tm) look for CyberFont apps!

###CyberAnimation

 ![Cyani](images/cyani.png)

CyberAnimation is a fast 256 color animation player, creator and PCX importer/exporter. Animation format faster and smaller than FLI format! Great for multimedia or game applications.

###CyberBase

![Cybase](images/cybase.png)

CyberBase for Paradox Engine 3.x includes a new generic table editor window, generic table and index create, memo editor,
cut and paste fields, easy engine configuration, automatic locks and validation. Windows and DOS based network sharing also supported.

###CyberTerm

![Cyterm](images/cyterm.png)

CyberTerm for Async Professional 2.x is a professional multi-session async communications application with CyberScript
(tm) script language, IDE and supporting tools.  If you were disappointed with other Turbo Vision terminals then CyberTerm is for you!

###Requirements
* IBM PC or 100% compatible
* MS DOS compatible OS
* Borland Pascal 7.x or Turbo Pascal 7.x with Turbo Vision 2.x
* VGA display for CyberFont apps and CyberAnimaton app
* Borland Paradox Engine 3.x for CyberBase app
* Turbo Power Async Professional 2.x for CyberTerm app
* Working knowledge of Pascal, OOP and Turbo Vision

## Using Borland Pascal under dosemu

![dosemu](images/dosemu.png)

Using Borland Pascal under dosemu is going to be the most efficient way to work on code. I'm providing you my development environment from the 90s since it was already configured and has all the required tools. I've updated it to work on fast CPUs (fixed runtime 200 errors), but there could be other issues. It looks like everything is Y2K compliant including Paradox Engine! See application source for IDE paths.  Help files (??HELP.TXT) need to be compiled with Turbo Vision Help Compiler 1.1 (\BP\EXAMPLES\DOS\TVDEMO\TVHC.PAS) that comes with TVDEMO.
* Install dosemu `sudo apt-get install dosemu`
* Download [bp.zip](https://github.com/sgjava/garage/raw/master/commodore/dos/cybertools/bp.zip)
* Extract zip to ~/.dosemu/drive_c
* Add c:\bp\bin to path in ~/.dosemu/drive_c/autoexec.bat
* `dosemu`
* `bp`

<meta http-equiv="Content-Type"  content="text/html charset=IBM437" />

ÄObjects
 ÃÄÄRoot
 ³  ÃÄÄAbstractPort

### FreeBSD License
Copyright (c) Steven P. Goldsmith

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

