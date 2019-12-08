.EQU SWI_EXIT, 0x11
.EQU SWI_DISPLAY, 0x69
.EQU SWI_DISPLAY_INTEGER, 0x6B
.EQU SWI_READ_INTEGER, 0x6C

.TEXT
.global _MAIN

_MAIN:
@@  Read the input for nth fibonacci number
@@  output as STDOUT
@@  input as STDIN
    LDR R0, =OUTPUTFILE
    LDR R0, [R0]
    LDR R1, =NUMBER
    SWI SWI_DISPLAY
    LDR R0, =INPUTFILE
    LDR R0, [R0]
    SWI SWI_READ_INTEGER

@@  Set register R1 to #0 and call subroutine FIBO
    MOV R1, #0
    BL _FIBO

@@  For backup of the answer storing it in register R3
    MOV R3, R1

@@  Print the output to the STDOUT
    LDR R0, =OUTPUTFILE
    LDR R0, [R0]
    LDR R1, =FIBONACCI
    SWI SWI_DISPLAY
    MOV R1, R3
    SWI SWI_DISPLAY_INTEGER
    SWI SWI_EXIT


@@  Subroutine FIBONACCI
_FIBO:
@@  Storing the contents of register R0-R3 and LR to stack
@@  Since during multiple recurrsive call register are getting changed
    STMFD SP!, {R0-R3, LR}
    LDR R0, [SP]
@@  Check the nth element in recurrsion is less than #3 if so return #1
@@  Return #1 in sense setting register R1 of earlier stack with register R1 content
    CMP R0, #3
    BLT _FIBO_BREAK

@@  F_(n) = F_(n-1) + F_(n-2) is done in following steps
@@  For F_(n-1)
    SUB R0, R0, #1
    BL _FIBO

@@  Move the result of F_(n-1) to register R2
    MOV R2, R1

@@  For F_(n-2)
    LDR R0, [SP]
    SUB R0, R0, #2
    BL _FIBO

@@  Move the result of F_(n-2) to register R3
    MOV R3, R1
    ADD R1, R2, R3
    B _FIBO_RETURN

_FIBO_BREAK:
    MOV R1, #1
_FIBO_RETURN:
    STR R1, [SP, #4]
    LDMFD SP!, {R0-R3, PC}

.DATA
INPUTFILE: .word 0          @   STDIN
OUTPUTFILE: .word 1         @   STDOUT
NUMBER: .asciz "N\n"
FIBONACCI: .asciz "F_N\n"
