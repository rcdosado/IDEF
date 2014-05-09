@echo off
REM point BIN to the location of your tasm32 and tlink32
set BIN=d:\bin\tasm32
set INP=idef

%BIN%\tasm32.exe -ml -t -q -m5 -q %INP%.asm
%BIN%\tlink32.exe -Tpe -aa -x -c  %INP%,,,%BIN%\import32,,
del *.obj
pause