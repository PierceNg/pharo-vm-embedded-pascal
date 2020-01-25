{ This file defines the Free Pascal FFI to libPharoVMCore. }

unit ulibPharoVM;

{$mode objfpc}{$H+}

interface
    { empty }

uses
    ctypes;

type

    TFileAccessHandler = record
        imageFileClose: pointer;
        imageFileOpen: pointer;
        imageFilePosition: pointer;
        imageFileRead: pointer;
        imageFileSeek: pointer;
        imageFileSeekEnd: pointer;
        imageFileWrite: pointer;
        imageFileExists: pointer;
    end;
    { Pascal's type system allows defining a type for each function signature. 
      Above we use the Pointer type for expedience. }

    PTFileAccessHandler = ^TFileAccessHandler;

const

    {$ifdef unix}
        {$ifdef darwin}
            dySoDLL = 'libPharoVMCore.dylib';
        {$else}
            dySoDLL = 'libPharoVMCore.so';
        {$endif}
    {$else}
        {$ifdef windows}
            dySoDLL = 'PharoVMCore.dll';
        {$endif}
    {$endif}

function vm_main(ac: cint; const av: ppchar; const ev: ppchar): cint; cdecl; external dySoDLL;
procedure setFileAccessHandler(handler: PTFileAccessHandler); cdecl; external dySoDLL;

implementation
    { empty }

end.
