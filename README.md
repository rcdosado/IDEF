IDEF
====

A commandline utility that will produce a def file for creating Lib files for windows C compilers, if a PE file export a function by ordinal, it is renamed into a generic name,otherwise it is named after its export name,very handy for naming nameless undocumented functions inside DLLs so you can call it from your application like normal API,of course given that you know how that function be called (calling convention, # of parameters, types, etc)


Requirements
------------

 - tasm32.exe turbo assembler 32 bits
 - tlink32.exe turbo linker32 bits
 - import32 (included in the repo)

Compilation
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

Sample Outputs
-------

>idef c:\windows\system32\user32.dll
```
	NAME USER32.dll
	EXPORTS
	USER32_ORD_05DC @1500 NONAME
	USER32_ORD_05DD @1501 NONAME
	ActivateKeyboardLayout
	AddClipboardFormatListener
	AdjustWindowRect
	AdjustWindowRectEx
	AlignRects
	AllowForegroundActivation
	AllowSetForegroundWindow
	AnimateWindow
	AnyPopup
	AppendMenuA
	AppendMenuW
	ArrangeIconicWindows
	AttachThreadInput
	BeginDeferWindowPos
	BeginPaint
	BlockInput
	BringWindowToTop
	BroadcastSystemMessage
	BroadcastSystemMessageA
	BroadcastSystemMessageExA
	BroadcastSystemMessageExW
	BroadcastSystemMessageW
	BuildReasonArray
	...
	...
```
