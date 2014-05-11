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


	 mov     edx, [ebx+esi+78h]	; points to export section RVA,it'll jump if pefile has no
	 test    edx, edx		; exports whatsoever
	 jz      epilogue

	 push    edx
	 call    resolveRVAddress
	 cmp     dword ptr [eax+14h], 0
	 jz      epilogue


         push    eax
	 push    50000h			; uBytes
	 push    40h			; uFlags
	 callx   LocalAlloc
	 test    eax, eax
	 pop     ecx
	 jz      epilogue

	 mov     edi, eax
	 mov     dword ptr ds:banner+4, eax
	 mov     ebp, ecx
	 mov     eax, 'EMAN'
	 stosd
	 mov     al, 20h
	 stosb

	 push    dword ptr [ebp+0Ch]
	 call    resolveRVAddress

	 xchg    eax, ecx
	 sub     edx, edx
	 mov     esi, offset buffer1

copy_pe_name:                          
				 
	 mov     al, [ecx]
	 test    al, al
	 jz      short create_heading
	 inc     ecx
	 stosb
	 test    edx, edx
	 jnz     short copy_pe_name
	 cmp     al, '.'
	 jz      short @@period
	 cmp     al, 'a'
	 jb      short @@jmp
	 cmp     al, 'z'
	 ja      short @@jmp
	 and     al, '�'

@@jmp:                            				 
	 mov     [esi], al
	 inc     esi
	 jmp     short copy_pe_name
; ---------------------------------------------------------------------------

@@period:                             
	 mov     byte ptr [esi], 0
	 inc     edx
	 jmp     short copy_pe_name
; ---------------------------------------------------------------------------

create_heading:                         
	 mov     eax, 58450A0Dh		;0a,0d,'EX'
	 mov     esi, [ebp+10h]
	 stosd
	 mov     eax, 'TROP'
	 dec     esi
	 stosd
	 mov     al, 'S'
	 stosb

pex_exports_loop:                
				 
	 inc     esi
	 mov     ecx, esi
	 sub     eax, eax
	 sub     ecx, [ebp+16]
	 jl      short loc_401483
	 cmp     ecx, [ebp+20]
	 jnb     short loc_4014DB
	 push    dword ptr [ebp+28]
	 call    resolveRVAddress
	 mov     eax, [eax+ecx*4]

loc_401483:                            
	 test    eax, eax
	 jz      short pex_exports_loop
	 mov     ax, 0A0Dh
	 stosw
	 push    dword ptr [ebp+24h]
	 call    resolveRVAddress
	 sub     edx, edx

loc_401497:                             
	 cmp     edx, [ebp+18h]		; checking if export has ordinals
	 jnb     short ordinals_true
	 cmp     cx, [eax]
	 jz      short loc_4014A6
	 inc     edx
	 inc     eax
	 inc     eax
	 jmp     short loc_401497	; checking if export has ordinals
; ---------------------------------------------------------------------------

loc_4014A6:                             
	 push    dword ptr [ebp+20h]
	 call    resolveRVAddress
	 push    dword ptr [eax+edx*4]
	 call    resolveRVAddress
	 xchg    eax, ecx

pex_copyUntilz:                         
	 mov     al, [ecx]
	 test    al, al
	 jz      short pex_exports_loop
	 inc     ecx
	 stosb
	 jmp     short pex_copyUntilz
; ---------------------------------------------------------------------------

ordinals_true:                         
	 push    esi
	 push    esi
	 push    offset buffer1
	 push    offset tmpl8		; "%s_ORD_%.4X @%d NONAME"
	 push    edi			; LPSTR
	 call    ds:wsprintfA
	 add     esp, 14h
	 add     edi, eax
	 jmp     short pex_exports_loop
; ---------------------------------------------------------------------------

loc_4014DB:                            
	 mov     esi, offset dmpname
	 cmp     byte ptr [esi], 0
	 jnz     short createOutputFile
	 mov     esi, offset buffer1
	 push    esi			; lpString
	 call    ds:lstrlenA
	 mov     dword ptr [eax+esi], 'FED.'
	 mov     byte ptr [eax+esi+4], 0

createOutputFile:                     
	 push    0			; iAttribute
	 push    esi			; lpPathName
	 call    ds:_lcreat
	 mov     esi, eax
	 sub     edi, dword ptr ds:banner+4
	 push    edi			; uBytes
	 push    dword ptr ds:banner+4	; lpBuffer
	 push    esi			; hFile
	 call    ds:_lwrite
	 push    esi			; hObject
	 call    ds:CloseHandle
	 push    dword ptr ds:banner+4	; hMem
	 call    ds:LocalFree
	 mov     ebp, 40128Dh


epilogue:
	 pop	 dwo fs:0		;restore old exception handler
	 pop	 ecx
	 push	 ebx
	 callx	 UnmapViewOfFile

_epilogue:
	 callx	 CloseHandle



__epilogue:

	 push	 ebp
	 callx	 lstrlenA
	 push	 eax
	 push    ebp
	 push    0FFFFFFF5h      ; hFile
	 callx   _lwrite	 
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


resolveRVAddress proc near     
				


arg_0           = dword ptr  4

	push    ecx
	push    edx
	push    ebp
	push    esi
	push    edi
	push    ebx
	mov     edx, ebx		; edx points to mapped PE file
	mov     eax, [esp+1Ch]		; eax points to export table RVA,from arg0
	add     edx, [edx+3Ch]		; edx points to PE signature for mapped file
	movzx   ecx, word ptr [edx+6]	; get how many sections this pe file has
	dec     ecx			; decrement
	jl      short pex_exit0
	lea     ebx, [edx+248]		; goes to the first section name
	imul    ecx, 28h		; multiplies decremented section # with 0x28
	sub     edi, edi

getSectionRVA:                         
	mov     esi, [ecx+ebx+0Ch]	; gets the section's RVA starting from last?
	cmp     esi, eax		; test if its below or equal to arg0
	jbe     short pex_getsection

pex_checksection:                       
					
	sub     ecx, 28h
	jge     short getSectionRVA	; gets the section's RVA starting from last?
	test    edi, edi
	jnz     short pex_exit1
	cmp     [edx+54h], eax
	jbe     short pex_exit0
	jmp     short pex_exit2
; ---------------------------------------------------------------------------

pex_getsection:                        
	cmp     edi, esi
	ja      short pex_checksection
	mov     edi, esi
	mov     ebp, [ecx+ebx+14h]	; gets the sections pointer to raw data
	jmp     short pex_checksection
; ---------------------------------------------------------------------------

pex_exit1:                              
	sub     eax, edi
	add     eax, ebp

pex_exit2:                              
	add     eax, [esp]		;access the last data pushed in the stack w/c is ebx

pex_exit3:                              
	pop     ebx
	pop     edi
	pop     esi
	pop     ebp
	pop     edx
	pop     ecx
	retn    4
; ---------------------------------------------------------------------------

pex_exit0:                      
				
	sub     eax, eax
	jmp     short pex_exit3

resolveRVAddress endp




End Start
