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
params  db	104h dup(0)

        .code
Start:
	 mov	 ebp,offset banner
	 callx	 GetCommandLineA
	 mov	 esi,eax
	 mov	 edi, offset params
	 call	 get_params

	 push	 eax
	 callx	 ExitProcess

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
