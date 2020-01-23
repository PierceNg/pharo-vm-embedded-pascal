# Embedding Pharo

This repository demonstrates embedding [Pharo](http://pharo.org) inside host programs written in
[Free Pascal](https://www.freepascal.org). It is inspired by Pablo Tesone's [C
example](https://github.com/tesonep/pharo-vm-embedded-example).

## How It Works

The application Pharo image is as per Pablo's repository, running SDL2AthensDrawingExample
headlessly. This image is compiled into a [Windows resource](https://en.wikipedia.org/wiki/Resource_%28Windows%29). 

Free Pascal has built-in cross-platform support for programmatically accessing Windows
resources. The source code in ```embedded-cli``` implements FFI to Pharo's shared library
```libPharoVMCore```, routines to access the Pharo image Windows resource for callback from
```libPharoVMCore```, and a driver program. When run, the compiled driver program invokes the Pharo VM 
with the embedded Pharo image which puts up an SDL window where it is possible to draw with the mouse.

## How To Build

### Pharo headless VM

First, build the [Pharo headless
VM](https://github.com/pharo-project/opensmalltalk-vm/tree/headless), following the instructions in
its README. When done, the VM files are in ```build/vm```.

### Pharo application image

Next, prepare the Pharo application image. Basically, start from a fresh Pharo 8.0 image and
load the ```EmbeddedSupport``` code from Pablo's repository. The following snippet works,
assuming you have cloned Pablo's repository locally; adjust the ```gitlocal``` path in the snippet,
of course.

```
Metacello new
	baseline: 'EmbeddedSupport';
	repository: 'gitlocal:///home/pierce/src/st/pharo-vm-embedded-example/smalltalk-src';
	load.

NoChangesLog install.
NoPharoFilesOpener install.
PharoCommandLineHandler forcePreferencesOmission: true.

SmalltalkImage current snapshot: true andQuit: true
```

### Windows resource 

Then, embed the Pharo application image into a Windows resource file.

Here's a simplified version of ```resources.rc```. This assumes you have named the image to be
embedded ```Pharo.image```.

```
300 RCDATA "Pharo.image"
```

Building a Windows resource file on Linux requires ```windres```. On Ubuntu, this program is
part of the package ```binutils-mingw-w64-x86-64```.

Place the application ```Pharo.image``` and ```resources.rc``` in the same
directory. Then,

```
% /usr/bin/x86_64-w64-mingw32-windres -i resources.rc -o resources.res
% ls -l
total 113488
-rw-r--r-- 2 pierce pierce 58098672 Jan 23 14:10 Pharo.image
-rw-r--r-- 2 pierce pierce       25 Jan 23 14:01 resources.rc
-rw-r--r-- 2 pierce pierce 58098736 Jan 23 14:10 resources.res
```

The output ```resources.res``` is the compiled resources file.

### Pascal host program

Finally we are ready to build the Pascal host program. Move ```resources.res``` to this
repository's ```embedded-cli``` directory. Also create a link to ```libPharoVMCore.so``` or make
a copy of it. The directory's content is now as follows:

```bash
% ls -l
total 58736
-rwxr-xr-x 2 pierce pierce  3344760 Jan 23 09:26 libPharoVMCore.so*
-rw-r--r-- 2 pierce pierce 58098736 Jan 23 14:10 resources.res
-rw-r--r-- 4 pierce pierce     1945 Jan 23 12:55 runPharoEmbedded.pas
-rw-r--r-- 4 pierce pierce     3824 Jan 23 12:54 ulibEmbeddedImage.pas
-rw-r--r-- 5 pierce pierce     1045 Jan 22 15:42 ulibPharoVM.pas
```

At the start of ```runPharoEmbedded.pas```, the line
```{$R resources.res}``` is the Pascal compiler directive to incorporate ```resources.res``` into the
executable that is being built:

```pascal
program runPharoEmbedded;

{$mode objfpc}{$H+}
{$R resources.res} { <= compiler directive to incorporate resources.res }
{$linklib m}
```

Build the host program - the Pascal compiler is its own ```make``` system and knows to compile
the necessary source files. (The Pascal compiler also knows how to invoke ```windres``` to
compile ```resources.rc``` into ```resources.res``` when so configured. I've done that part by
hand since this is a HOWTO.)

```bash
% fpc runPharoEmbedded.pas
Free Pascal Compiler version 3.0.4 [2018/10/29] for x86_64
Copyright (c) 1993-2017 by Florian Klaempfl and others
Target OS: Linux for x86-64
Compiling runPharoEmbedded.pas
Compiling ulibPharoVM.pas
Compiling ulibEmbeddedImage.pas
Compiling resource runPharoEmbedded.or
Linking runPharoEmbedded
/usr/bin/ld: warning: link.res contains output sections; did you forget -T?
232 lines compiled, 0.4 sec

% ls -l runPharoEmbedded
-rwxr-xr-x 1 pierce pierce 58884328 Jan 23 14:22 runPharoEmbedded*
```

Much of the size of the executable is due to the embedded ```Pharo.image```.

We'll run ```runPharoEmbedded``` in the headless VM build directory because Pharo's
baked-in library lookup currently requires this. (More on this in a later post.) So move the
program over.

```
% mv runPharoEmbedded ~/src/st/opensmalltalk-vm-pharo/build/vm
% cd ~/src/st/opensmalltalk-vm-pharo/build/vm
% ls -T 30
libB2DPlugin.so*             libgit2.so.0.25.1             libSDL2-2.0.so.0*      libssl.so*
libBitBltPlugin.so*          libgit2.so.25                 libSDL2-2.0.so.0.7.0*  libssl.so.1.0.0*
libcrypto.so.1.0.0*          libIA32ABI.so*                libSDL2.so*            libSurfacePlugin.so*
libDSAPrims.so*              libJPEGReaderPlugin.so*       libSecurityPlugin.so*  libTestLibrary.so*
libffi.so*                   libJPEGReadWriter2Plugin.so*  libSocketPlugin.so*    libUnixOSProcessPlugin.so*
libffi.so.7*                 libLargeIntegers.so*          libSqueakFFIPrims.so*  libUUIDPlugin.so*
libffi.so.7.1.0*             libLocalePlugin.so*           libSqueakSSL.so*       pharo*
libFileAttributesPlugin.so*  libMiscPrimitivePlugin.so*    libssh2.so*            runPharoEmbedded*
libFilePlugin.so*            libPharoVMCore.so*            libssh2.so.1*
libgit2.so                   libPThreadedPlugin.so*        libssh2.so.1.0.1*
```

Set up LD_LIBRARY_PATH. The first path segment is for the Pharo VM. The second is for
```libcairo2.so``` needed by the embedded ```Pharo.image``` - on Ubuntu, it lives in
```/usr/lib/x86_64-linux-gnu```, which isn't in Pharo 8's current hardcoded lookup path. Then
run the executable:

```
% export LD_LIBRARY_PATH=`pwd`:/usr/lib/x86_64-linux-gnu
% uname -a
Linux Otrus 4.15.0-74-generic #84-Ubuntu SMP Thu Dec 19 08:06:28 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
% ./runPharoEmbedded
lala
```

![runPharoEmbedded](https://github.com/PierceNg/doc/img/embedded-linux.png)

Ta da! "lala" is printed by Pharo.


