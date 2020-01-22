program runPharoEmbedded;

{$mode objfpc}{$H+}
{$R resources.res}
{$linklib m}

uses
    {$ifdef unix}
    cthreads,
    {$endif}
    ctypes, sysutils, math,
    ulibPharoVM, ulibEmbeddedImage;

{$ifdef darwin}
{$linklib libPharoVMCore.dylib}
{$endif}

var
    processArgv, envp: array of AnsiString;
    embeddedFileHandler: TFileAccessHandler;
    i: integer;

begin

  { Set math masks. CogVM throws at least one of these from somewhere deep inside. }
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]); 

  { Construct command line arguments to the VM. }
  setLength(processArgv, 5);
  processArgv[0] := paramStr(0); { <= name of this executable }
  processArgv[1] := '--headless';
  processArgv[2] := 'Pharo.image';
  processArgv[3] := 'embeddedExample'; 
  processArgv[4] := '--embedded';

  { Set up environment variables for the VM. }
  setLength(envp, getEnvironmentVariableCount);
  for i := 1 to getEnvironmentVariableCount do
        envp[i-1] := getEnvironmentString(i);

  { Set up the handler for embedded image access. }
  embeddedFileHandler.imageFileClose := pointer(@embeddedImageFileClose);
  embeddedFileHandler.imageFileOpen := pointer(@embeddedImageFileOpen);
  embeddedFileHandler.imageFilePosition := pointer(@embeddedImageFilePosition);
  embeddedFileHandler.imageFileRead := pointer(@embeddedImageFileRead);
  embeddedFileHandler.imageFileSeek := pointer(@embeddedImageFileSeek);
  embeddedFileHandler.imageFileSeekEnd := pointer(@embeddedImageFileSeekEnd);
  embeddedFileHandler.imageFileWrite := pointer(@embeddedImageFileWrite);
  embeddedFileHandler.imageFileExists := pointer(@embeddedImageFileExists);
  setFileAccessHandler(@embeddedFileHandler);

  { Go Pharo! }
  vm_main(5, ppchar(@processArgv[0]), ppchar(@envp[0]));

end.
