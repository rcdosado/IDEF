IDEF
====

A commandline utility that will produce a def file for creating Lib files, handy for naming nameless undocumented functions inside DLLs 


Requirements
------------

 - tasm32.exe turbo assembler 32 bits
 - tlink32.exe turbo linker32 bits
 - import32 (included in the repo)

Running
-------
 Simply modify the batch file included to point to the location of the requirements, the 3 files must have the same directory
 then execute compile.bat

 ```
	@echo off
	REM point BIN to the location of your tasm32 and tlink32
	set BIN=d:\bin\tasm32
	set INP=idef

	%BIN%\tasm32.exe -ml -t -q -m5 -q %INP%.asm
	%BIN%\tlink32.exe -Tpe -aa -x -c  %INP%,,,%BIN%\import32,,
	del *.obj
	pause

 ```

