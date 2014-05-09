      .386p
      locals
      jumps
      .model flat,STDCALL

      UNICODE=0
	
	INCLUDE useful.inc

        .data    


banner	db	'iDEF creates DEF file for given PE file with exports.',CRLF
	db	'Usage: iDEF <PEfile.ext> [OutputFile]',CRLF
	db	'If no OutputFile is given PEfile.DEF is created.',0

error_string1	db 'Can't find/open/map module!',CRLF,0
error_string2   db 'Module is not 32bit or exports nothing!',CRLF,0

params  db	104h dup(0)

        .code
Start:
	 mov	 ebp,offset banner
	 callx	 GetCommandLineA
	 mov	 esi,eax

	 mov	 edi, offset params
	 call	 get_params		; get first parameter
	 call	 get_params		; get second parameter

	 mov     ebp, offset error_string1 
	 push    0			; iReadWrite
	 push    edi			; lpPathName
	 callx   _lopen

	 mov     esi, eax
	 sub     edi, edi
	 inc     eax

	 jz	 __epilogue

	 push	 edi			; lpFileSizeHigh
	 push	 esi			; file handle
	 callx	 GetFileSize

	 mov     dwo [banner], eax	; save size
	 
	 push    edi			; lpName
	 push    edi			; dwMaximumSizeLow
	 push    edi			; dwMaximumSizeHigh
	 push    2			; flProtect
	 push    edi			; lpFileMappingAttributes
	 push    esi			; hFile
	 callx   CreateFileMappingA

	 mov	 ebx,eax

	 push	 esi
	 callx	 CloseHandle

	 test	 ebx,ebx
	 jz	 __epilogue

	 push    ebx			; hObject
	 push    edi			; dwNumberOfBytesToMap
	 push    edi			; dwFileOffsetLow
	 push    edi			; dwFileOffsetHigh
	 push    4			; dwDesiredAccess
	 push    ebx			; hFileMappingObject
	 callx   MapViewOfFile
 	 sub     ecx, ecx
	 mov     ebx, eax

	 test    eax, eax
	 jz      _epilogue		; eax points to the start of the image

	 push    offset __exception_handler
	 push    dword ptr fs:[ecx]
         mov     fs:[ecx], esp

	 mov     esi, [ebx+3Ch]		; esi points to 'PE' address
	 mov     ebp, offset error_string2 
	 cmp     word ptr [esi+ebx+18h], 10Bh ;points to magic optional header
	 jnz     epilogue


	 mov     edx, [ebx+esi+78h]	; points to export section,DLLS have non zero value here
	 test    edx, edx
	 jz      epilogue

	 push    edx
	 call    parse_exports
	 cmp     dword ptr [eax+14h], 0
	 jz      epilogue

	 ;to be continued...

epilogue:
	 pop	 dwo fs:0
	 pop	 ecx
	 push	 ebx
	 callx	 UnmapViewOfFile

_epilogue:
	 callx	 CloseHandle



__epilogue:

	 push	 ebp
	 callx	 lstrlenA
	 push	 eax


	 push	 eax
	 callx	 ExitProcess

__exception_handler:         

	 mov     ecx, [esp+8]
	 mov     edx, [esp+0Ch]
	 sub     eax, eax
	 mov     dword ptr [ecx+0B8h], offset epilogue
	 mov     [ecx+0C4h], edx
	 retn

get_params:                   
				      
	 push    edi
	 xor     eax, eax
	 mov     cl, '"'
	 mov     [edi], al
	 lodsb
	 test    al, al
	 jz      short parse_invalid
	 cmp     al, cl
	 jz      short cont1
	 dec     esi
	 mov     cl, ' '

cont1:                             
				 
	 lodsb
	 stosb
	 test    al, al
	 jz      short parse_ok
	 cmp     al, cl
	 jnz     short cont1
	 mov     byte ptr [edi-1], 0

@loop:                             
	 lodsb
	 test    al, al
	 jz      short parse_ok
	 cmp     al, ' '
	 jbe     short @loop

parse_ok:                               
				 
	 mov     al, 1
	 dec     esi

parse_invalid:                          
	 pop     edi
	 retn



End Start
