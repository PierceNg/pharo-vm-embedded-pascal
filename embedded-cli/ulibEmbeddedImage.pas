{ This file defines Free Pascal functions for image access called by Pharo Smalltalk. }

unit ulibEmbeddedImage;

{$mode objfpc}{$H+}

interface

uses
  ctypes, 
  {$ifdef unix}baseunix,{$endif}
  {$ifdef windows}windows,{$endif}
  classes;

type
  sqImageFile = pointer;
  sqInt = clong;

procedure setResourceID(rID: integer);
function getResourceID: integer;
function embeddedImageFileClose(f: pointer): sqInt; cdecl;
function embeddedImageFileOpen(fileName: pchar; mode: pchar): sqImageFile; cdecl;
function embeddedImageFilePosition(f: sqImageFile): cint32; cdecl;
function embeddedImageFileRead(ptr: Pointer; sz: size_t; count: size_t; f: sqImageFile): size_t; cdecl;
function embeddedImageFileSeek(f: sqImageFile; pos: culonglong): cint; cdecl;
function embeddedImageFileSeekEnd(f: sqImageFile; offset: culonglong): cint; cdecl;
function embeddedImageFileWrite(ptr: Pointer; sz: size_t; count: size_t; f: sqImageFile): size_t; cdecl;
function embeddedImageFileExists(const aPath: ppchar): cint; cdecl;

implementation

var
  resourceID: integer = -1;
  imageStream: TResourceStream;

procedure setResourceID(rID: integer);
begin
    resourceID := rID;
end;

function getResourceID: integer;
begin
    exit(resourceID);
end;

function badResourceID: boolean;
begin
    exit(resourceID <= 0);
end;

function badImageFile(f: sqImageFile): boolean;
begin
     exit((imageStream = nil) or (f <> imageStream.memory));
end;

(* EXPORT(sqInt) embeddedImageFileClose(void* f) *)
function embeddedImageFileClose(f: pointer): sqInt; cdecl;
begin
     if not badImageFile(f) then
        imageStream.free;
     exit(0);
end;

(* EXPORT(sqImageFile) embeddedImageFileOpen(char* fileName, char *mode) *)
function embeddedImageFileOpen(fileName: pchar; mode: pchar): sqImageFile; cdecl;
begin
     if badResourceID then
         exit(nil);
     imageStream := TResourceStream.createFromID(HInstance, resourceID, RT_RCDATA);
     exit(imageStream.memory);
end;

(* EXPORT(long int) embeddedImageFilePosition(sqImageFile f) *)
function embeddedImageFilePosition(f: sqImageFile): cint32; cdecl;
begin
     if badImageFile(f) then
        exit(0);
     exit(imageStream.position);
end;

(* EXPORT(size_t) embeddedImageFileRead(void * ptr, size_t sz, size_t count, sqImageFile f) *)
function embeddedImageFileRead(ptr: Pointer; sz: size_t; count: size_t; f: sqImageFile): size_t; cdecl;
var
  toRead, remaining: size_t;
begin

     if (badImageFile(f) or (sz = 0) or (count = 0)) then
        exit(0);
     if (imageStream.position) = imageStream.size then
        exit(0);
     remaining := imageStream.size - imageStream.position;
     toRead := count * sz;
     if toRead > remaining then
        toRead := remaining;
     if toRead = 0 then
        exit(0);
     exit(qword(imageStream.read(ptr^, toRead)));
     (* read() returns LongInt, 32 bits, while this function returns size_t, 64 bits. *)
end;

(* EXPORT(int) embeddedImageFileSeek(sqImageFile fileHandler, unsigned long long pos) *)
function embeddedImageFileSeek(f: sqImageFile; pos: culonglong): cint; cdecl;
begin
     if badImageFile(f) then
        exit(0);
     exit(imageStream.seek(pos, soBeginning));
end;

(* EXPORT(int) embeddedImageFileSeekEnd(sqImageFile fileHandler, unsigned long long offset) *)
function embeddedImageFileSeekEnd(f: sqImageFile; offset: culonglong): cint; cdecl;
begin
     if badImageFile(f) then
        exit(0);
     exit(imageStream.seek(offset, soEnd));
end;

(* EXPORT(size_t) embeddedImageFileWrite(void* ptr, size_t sz, size_t count, sqImageFile fileHandler) *)
function embeddedImageFileWrite(ptr: Pointer; sz: size_t; count: size_t; f: sqImageFile): size_t; cdecl;
begin
     { Not writeable! }
     exit(0);
end;

(* EXPORT(int) embeddedImageFileExists(const char** aPath) *)
function embeddedImageFileExists(const aPath: ppchar): cint; cdecl;
begin
     { Always! }
     exit(1);
end;

end.
