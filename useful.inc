;most of the tricks  here are taken from the infamous 29A's inc files


callx   macro api
  extrn api:proc
  call  api
endm
      

LF      equ     10
CR      equ     13
CRLF    equ     <13,10>
LF      equ     10
CR      equ     13
CRLF    equ     <13,10>

ofs equ offset
dwo equ dword ptr
wor equ word ptr
byt equ byte ptr

param1 equ 4
param2 equ 8
param3 equ 12
param4 equ 16
param5 equ 20

Pushad_struc            struc
        Pushad_edi      dd      ?
        Pushad_esi      dd      ?
        Pushad_ebp      dd      ?
        Pushad_esp      dd      ?
        Pushad_ebx      dd      ?
        Pushad_edx      dd      ?
        Pushad_ecx      dd      ?
        Pushad_eax      dd      ?
Pushad_struc            ends

cPushad         equ     size Pushad_struc


;-------------------------------------------------------









; 컴� Structured Exception Handling (SEH) related stuff 쳐컴컴컴컴컴컴컴컴컴�

; This structure is the one pointed to by FS:[0]:

EXCEPTIONREGISTRATIONRECORD     STRUC   ; != EXCEPTION_RECORD structure
        ERR_prev_structure      DD      EXCEPTIONREGISTRATIONRECORD PTR ?
        ERR_ExceptionHandler    DD      BYTE PTR ? ; CODE PTR
        ; These are the minimun fieldz required for proper OS operation
        ; Other undocumented fieldz exist for Microsoft and Borland compilerz
EXCEPTIONREGISTRATIONRECORD     ENDS

; Exception record definition:

EXCEPTION_MAXIMUM_PARAMETERS    EQU     15      ; max # of except paramz

EXCEPTION_RECORD                STRUC
        ER_ExceptionCode        DD      ?
        ER_ExceptionFlags       DD      ?
        ER_ExceptionRecord      DD      EXCEPTION_RECORD PTR ?
        ER_ExceptionAddress     DD      BYTE PTR ? ; CODE PTR
        ER_NumberParameters     DD      ?
        ER_ExceptionInformation DD      EXCEPTION_MAXIMUM_PARAMETERS DUP (?)
EXCEPTION_RECORD                ENDS

EXCEPTION_POINTERS              STRUC
        EP_ExceptionRecord      DD      EXCEPTION_RECORD PTR ?
        EP_ContextRecord        DD      CONTEXT PTR ?
EXCEPTION_POINTERS              ENDS

; Other SEH related constantz and return valuez:

EXCEPTION_EXECUTE_HANDLER       EQU     1
EXCEPTION_CONTINUE_SEARCH       EQU     0
EXCEPTION_CONTINUE_EXECUTION    EQU     -1

EXCEPTION_ACCESS_VIOLATION              EQU     0C0000005h
EXCEPTION_DATATYPE_MISALIGNMENT         EQU     080000002h
EXCEPTION_BREAKPOINT                    EQU     080000003h
EXCEPTION_SINGLE_STEP                   EQU     080000004h
EXCEPTION_ARRAY_BOUNDS_EXCEEDED         EQU     0C000008Ch
EXCEPTION_FLT_DENORMAL_OPERAND          EQU     0C000008Dh
EXCEPTION_FLT_DIVIDE_BY_ZERO            EQU     0C000008Eh
EXCEPTION_FLT_INEXACT_RESULT            EQU     0C000008Fh
EXCEPTION_FLT_INVALID_OPERATION         EQU     0C0000090h
EXCEPTION_FLT_OVERFLOW                  EQU     0C0000091h
EXCEPTION_FLT_STACK_CHECK               EQU     0C0000092h
EXCEPTION_FLT_UNDERFLOW                 EQU     0C0000093h
EXCEPTION_INT_DIVIDE_BY_ZERO            EQU     0C0000094h
EXCEPTION_INT_OVERFLOW                  EQU     0C0000095h
EXCEPTION_PRIV_INSTRUCTION              EQU     0C0000096h
EXCEPTION_IN_PAGE_ERROR                 EQU     0C0000006h
EXCEPTION_ILLEGAL_INSTRUCTION           EQU     0C000001Dh
EXCEPTION_NONCONTINUABLE_EXCEPTION      EQU     0C0000025h
EXCEPTION_STACK_OVERFLOW                EQU     0C00000FDh
EXCEPTION_INVALID_DISPOSITION           EQU     0C0000026h
EXCEPTION_GUARD_PAGE                    EQU     080000001h

; Useful structure to access the "Except_Handler" function argumentz:

Except_Handler                  STRUC
        EH_Dummy                DD      ?                    ; Ret address
        EH_ExceptionRecord      DD      EXCEPTION_RECORD PTR ?
        EH_EstablisherFrame     DD      BYTE PTR ?
        EH_ContextRecord        DD      CONTEXT PTR ?
        EH_DispatcherContext    DD      BYTE PTR ?
Except_Handler                  ENDS

; The following macroz "@SEH_SetupFrame" and "@SEH_RemoveFrame" are limited
; assembler versionz of the _try and _except keywordz used in C language.
; They provide fast and powerful "Structured Exception Handling" support
; for Win32 applicationz in a few linez of code. Though Microsoft seems
; intent on hiding the details of OS-level structured exception handling,
; this code relies on documented featurez of the Win32 API implementation
; and as such it works in both Windoze 95 and Windoze NT.

@SEH_SetupFrame macro   ExceptionHandler
                local   set_new_eh
                call    set_new_eh
                mov     esp,[esp.EH_EstablisherFrame]
                ExceptionHandler
    set_new_eh: xor     edx,edx         ; Setup new SEH frame
                push    dword ptr fs:[edx]
                mov     fs:[edx],esp
endm

; The ExceptionHandler argument in the @SEH_SetupFrame macro definition
; can be a single instruction or another macro containing several of them.

@SEH_RemoveFrame macro
                 xor    edx,edx         ; Remove new SEH frame and set old
                 pop    dword ptr fs:[edx]
                 pop    edx
endm

comment #
// Exception disposition return values.

typedef enum _EXCEPTION_DISPOSITION {
    ExceptionContinueExecution,
    ExceptionContinueSearch,
    ExceptionNestedException,
    ExceptionCollidedUnwind
} EXCEPTION_DISPOSITION;

EXCEPTION_DISPOSITION __cdecl _except_handler (
    struct _EXCEPTION_RECORD *ExceptionRecord,
    void * EstablisherFrame,
    struct _CONTEXT *ContextRecord,
    void * DispatcherContext
    );
#