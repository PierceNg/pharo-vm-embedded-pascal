# Embedding Pharo

This repository demonstrates embedding [Pharo](http://pharo.org) inside host programs written in
[Free Pascal](https://www.freepascal.org). It is inspired by Pablo Tesone's [C
example](https://github.com/tesonep/pharo-vm-embedded-example).

## How It Works

The application Pharo image is as per Pablo's repository, running SDL2AthensDrawingExample
headlessly. This image is compiled into a [Windows resource](https://en.wikipedia.org/wiki/Resource_%28Windows%29). 

Free Pascal has built-in cross-platform support for programmatically accessing Windows
resources. The source code in ```embedded-cli``` implements FFI to Pharo's shared library
```libPharoVMCore```, routines to access the the Pharo image Windows resource for callback from
```libPharoVMCore```, and a driver program. When run, the compiled driver program invokes the Pharo VM 
with the embedded Pharo image which puts up an SDL window where it is possible to draw with the mouse.

## How To Build

Coming soon...

