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

    MOV R5, R0                  @@  Moving content of R0 to R5 for backup

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

@@  Moving number of elements from register R5 to R4 for loop
    MOV R4, R5

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

@@  Display the string "Search element\n" to output file handle (stdout)
_ARRAY_READ_EXIT:
    LDR R0, =OUTPUTFILE
    LDR R0, [R0]
    LDR R1, =SEARCH
    SWI SWI_DISPLAY

@@  R0 - contains search element
@@  R1 - contains memory address
@@  R2 - contains first elemens [FIRST INDEX]
@@  R3 - contains number of elements - 1 [LAST INDEX]
    LDR R0, =INPUTFILE
    LDR R0, [R0]
    SWI SWI_READ

    LDR R1, =MEMORYADDR
    LDR R1, [R1]
    MOV R2, #0
    SUB R3, R5, #1

@@  Branch to subroutine BINARY SEARCH
    BL _BINARY_SEARCH

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


@@  Subroutine BINARY SEARCH

_BINARY_SEARCH:
@@  Retrieve the contents from stack and move to register R0-R3
    STMFD SP!, {R0-R3, LR}
    LDR R0, [SP]
    LDR R1, [SP, #4]
    LDR R2, [SP, #8]
    LDR R3, [SP, #12]

@@  Compare the content (index) of register R2, R3
@@  If R2 content is greater which says no more element to check
@@  So skip the recurrsion
    CMP R2, R3
    BGT _SEARCH_NOT_FOUND_EXIT

@@  For displacement addressing mode calculating the offset
    MOV R5, #4
    MOV R4, R2

@@  For binary search mid = (first + last)/2 operation is carried out
    ADD R2, R2, R3
    LSR R2, #1

@@  Retrieving the content of memory location pointed by offset
@@  Comparing with the search element whether element is found or not
    MUL R5, R2
    LDR R5, [R1, R5]
    CMP R0, R5
    BEQ _SEARCH_FOUND_EXIT

@@  If not and the search element is larger move the first index to (mid + 1)
@@  Continue the recurrsion
    ADDGT R2, R2, #1
    BGT _BINARY_SEARCH_CONTINUE

@@  Else move the last index to (mid - 1)
@@  Continue the recurrsion
    SUB R3, R2, #1
    MOV R2, R4
    BLT _BINARY_SEARCH_CONTINUE

_SEARCH_NOT_FOUND_EXIT:
    MOV R2, #-1
    B _BINARY_SEARCH_RETURN
_SEARCH_FOUND_EXIT:
    ADD R2, R2, #1
    B _BINARY_SEARCH_RETURN
_BINARY_SEARCH_CONTINUE:
    BL _BINARY_SEARCH
_BINARY_SEARCH_RETURN:
    ADD SP, SP, #12
    STR R2, [SP]
    LDMFD SP!, {R0, PC}

.DATA
INPUTFILE: .word 0  @   STDIN
OUTPUTFILE: .word 1 @   STDOUT
MEMORYADDR: .word 0 @   MEMORY
NUMBER: .asciz "Number of elements\n"
ARRAY: .asciz "Enter elements\n"
SEARCH: .asciz "Search element\n"
OUT: .asciz "Output\n"