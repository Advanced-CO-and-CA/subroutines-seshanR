.EQU SWI_EXIT, 0x11
.EQU SWI_DISPLAY, 0x69
.EQU SWI_DISPLAY_INTEGER, 0x6B
.EQU SWI_READ, 0x6C
.EQU SWI_MEMALLOC, 0x12
.EQU SWI_MEMFREE, 0x13

.TEXT
.global _MAIN

_MAIN:
@@  Get the number of elements needed for array

@@  Write the string to stdout by setting
@@  file handle in register R0
@@  string in register R1
@@  with SWI 0x69
    LDR R0, =OUTPUTFILE
    LDR R0, [R0]
    LDR R1, =NUMBER
    SWI SWI_DISPLAY

@@  Get the count from the stdin by setting
@@  file handle in register R0
@@  with SWI 0x6C
    LDR R0, =INPUTFILE
    LDR R0, [R0]
    SWI SWI_READ

@@  To mark the end of integer word 0x0 is used. Therefore, allocating one additional word
    MOV R4, R0                  @@  Moving content of R0 to R4 for backup
    ADD R0, R0, #1              @@  Incrementing value in  R0 for one additional word

@@  Since the memory allocation requires number of bytes, multiplying content of R0 by #4
@@  Allocating memory by SWI 0x12 and the start address will be returned in R0
    MOV R2, #4
    MUL R0, R2
    SWI SWI_MEMALLOC
    LDR R2, =MEMORYADDR         @@  Storing the returned address in some known location
    STR R0, [R2]
    MOV R2, R0

@@  To Display string "Enter elements\n"
@@  Set the register R0 to stdout file handle
@@  Set the register R1 to string 
@@  Display with SWI 0x69
    LDR R0, =OUTPUTFILE
    LDR R0, [R0]
    LDR R1, =ARRAY
    SWI SWI_DISPLAY

@@  To Read elements till register R4 reaches #0 (zero) which holds count
@@  Set the register R0 with input file handle (stdin)
@@  Move the content read to memory location in R2 (indirect)
@@  Increment the register R2 by #4 to next memory location (word)
@@  Decrement the register content of R4 by #1
_ARRAY_READ_LOOP:
    CMP R4, #0
    BEQ _ARRAY_READ_EXIT
    LDR R0, =INPUTFILE
    LDR R0, [R0]
    SWI SWI_READ
    STR R0, [R2], #4
    SUBS R4, R4, #1
    B _ARRAY_READ_LOOP

@@  On exit from the above loop set the last word to 0x0
@@  Display the string "Search element\n" to output file handle (stdout)
_ARRAY_READ_EXIT:
    MOV R0, #0
    STR R0, [R2]
    LDR R0, =OUTPUTFILE
    LDR R0, [R0]
    LDR R1, =SEARCH
    SWI SWI_DISPLAY

@@  Read the search element from input file handle (stdin)
    LDR R0, =INPUTFILE
    LDR R0, [R0]
    SWI SWI_READ

@@  To pass the search element and array starting address to subroutine
@@  Set register R1 with memory address of array
@@  Set register R2 with search element
@@  Branch to subroutine _SEARCH and update the link register 
    LDR R1, =MEMORYADDR
    LDR R1, [R1]
    MOV R2, R0
    BL _SEARCH

@@  Free memory and print output to the stdout
    SWI SWI_MEMFREE
    MOV R4, R0
    LDR R0, =OUTPUTFILE
    LDR R0, [R0]
    LDR R1, =OUT
    SWI SWI_DISPLAY
    LDR R0, =OUTPUTFILE
    LDR R0, [R0]
    MOV R1, R4
    SWI SWI_DISPLAY_INTEGER
    SWI SWI_EXIT


@@  Subroutine SEARCH

@@  Store the content of register R1-R2 and LR in stack and update it
@@  Load the contents back to register from stack in this way parameter got passed via stack
@@  Set register R0 with search element
@@  Set register R1 with array starting address
@@  Set register R2 to #0
_SEARCH:
    STMFD SP!, {R1-R2, LR}
    LDR R0, [SP, #4]
    LDR R1, [SP]
    MOV R2, #0

@@  Load the content in memory location to register R3
@@  Compare the array word with search element
@@  If matched exit the loop
@@  If not matched increment the index
@@  Compare the last word is reached or not by comparing R3 with word #0 (zero)
@@  If search element not found set register R2 to #-1 and return
_SEARCH_ARRAY_LOOP:
    LDR R3, [R1], #4
    CMP R3, R0
    BEQ _SEARCH_FOUND_EXIT
    ADD R2, R2, #1
    CMP R3, #0
    BNE _SEARCH_ARRAY_LOOP
    MOV R2, #-1
    B _SEARCH_RETURN

_SEARCH_FOUND_EXIT:
    ADD R2, R2, #1
_SEARCH_RETURN:
    STMFD SP!, {R2}
    LDMFD SP!, {R0-R2, PC}

.DATA
INPUTFILE: .word 0  @   STDIN
OUTPUTFILE: .word 1 @   STDOUT
MEMORYADDR: .word 0 @   MEMORY
NUMBER: .asciz "Number of elements\n"
ARRAY: .asciz "Enter elements\n"
SEARCH: .asciz "Search element\n"
OUT: .asciz "Output\n"