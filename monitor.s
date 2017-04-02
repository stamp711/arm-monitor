        AREA Monitor1, CODE,READONLY
        IMPORT  Getline
		EXPORT	Monitor
		EXPORT 	SendChar
		EXTERN	r14tmp
;//******************************************************
;//                  FROM: Wei Zhao                     *
;//                   BY: APRICITY                      *
;//******************************************************

;// This is a template for the monitor project
;// it sets up the stack and reserves space for the struct returned
;// by getline. The rest is up to you
;//
;// Reminder: This Monitor is usually called in privileged mode. Dont forget (for example, when displaying registers via the 'R/r' command) that the debugged application is running in user mode.


SWI_ANGEL EQU   0x123456        ;//SWI number for Angel semihosting   

        MACRO
$l      Exit                    ;//Angel SWI call to terminate execution
$l      MOV     r0, #0x18       ;//select Angel SWIreason_ReportException(0x18)
        LDR     r1, =0x20026    ;//report ADP_Stopped_ApplicationExit
        SWI     SWI_ANGEL       ;//ARM semihosting SWI
        MEND

        MACRO
$l      WriteC                  ;//Angel SWI call to output character in [r1]
$l      MOV     r0, #0x3        ;//select Angel SYS_WRITEC function
        SWI     SWI_ANGEL
        MEND
        
        MACRO
$l      ReadC                   ;//Angel SWI call to receive input of a character to [r0]
$l      MOV     r0, #0x7        ;//select Angel SYS_READC function
        MOV     r1, #0x0        ;//[r1] must be 0
        SWI     SWI_ANGEL
        MEND
        

        
Monitor

;// First load the stack pointer (you might want to improve it)
	    ADRL    r13, StackInit
        LDR     r13, [r13]
		STMFD   r13!, {r0-r12,r14}	;//save reg to stack

;// call the Getline routine like this
L1      BL      Getline
        LDRB    r1, [r0]        ;//get Command letter
        LDRB    r2, [r0, #1]    ;//get no. of params
        LDR     r3, [r0, #4]    ;//get 1st param
        LDR     r4, [r0, #8]    ;//get 2nd param
        LDR     r5, [r0, #12]   ;//get 3rd param
;// OK start your code here


;//----------------------------------------------------------------
;//COMMAND: 'Q'
		CMP		r1, #0x51		;//'Q'=0x51
		BNE		Next0
		CMP		r2, #0
		BNE		InvalidComm
		B		MonQuit


;//----------------------------------------------------------------
;//COMMAND: 'E'
;//AUTHOR: APRICITY
Next0
        CMP     r1, #0x45		;//'E'=0x45
        BNE     Next1
        CMP     r2, #0
        BEQ     E_0para
        CMP     r2, #1
        BEQ     E_1para
        B       InvalidComm
E_0para
        LDR     r3, EndianType
		CMP     r3, #0
		MOVEQ   r3, #1
		MOVNE   r3, #0
		B       E_end
E_1para
        CMP     r3, #0
		BEQ     E_end
		CMP     r3, #1
		BEQ     E_end
		B       InvalidComm
E_end
        STR     r3, EndianType
        B       Continue


;//----------------------------------------------------------------
;//COMMAND: 'D'
Next1
		CMP		r1, #0x44		;//'D'=0x44
		BNE		Next2
		CMP		r2, #1
		BNE		InvalidComm
		CMP		r3, #0x10
		BNE		D_1
		MOV		r3, #10
		B		D_end
D_1		CMP		r3, #0x16
		BNE		D_2
		MOV		r3, #16
		B		D_end
D_2		CMP		r3, #0x2
		BNE		InvalidComm
		MOV		r3, #2
D_end
		STR		r3,DataFormat
		B		Continue
		

;//----------------------------------------------------------------
;//COMMAND: 'C'
Next2
		CMP		r1, #0x43		;//'C'=0x43
		BNE		Next3
		;//Task2: You have to implement COMMAND 'C' here
        

;//----------------------------------------------------------------
;//COMMAND: 'M'
Next3
		CMP		r1, #0x4D		;//'M'=0x4D
		BNE		Next4

		MOV		r3, r3, LSR #2
		MOV		r3, r3, LSL #2

		CMP		r2, #0
		BEQ		M_1
		
		CMP		r2, #1
		BNE		M_2
		LDR		r1, =MAddr
		MOV		r2, r3
		B 		M_getdata
M_2	
		CMP		r2, #2
		BNE		InvalidComm
		
		STR		r4, [r3]
		LDR		r3, =Messages3
		BL		PrintNextMessage
		B		M_end		
M_1		
		LDR		r1, =MAddr		
		LDR	    r2, [r1]
		ADD		r2, r2, #4
M_getdata
		STR		r2, [r1]
        MOV		r7, r2
		LDR    	r2, [r2]		;//get 32bits data store in [r2]
		LDR		r1, EndianType
M_print
		CMP		r1, #0
		BEQ		M_3
		MOV		r3, r2, lsr #24
		AND		r3, r3, #0x0ff
		
		MOV		r4, r2, lsr #16
		AND		r4, r4, #0x0ff
		MOV		r4, r4, lsl #8
		
		MOV		r5, r2, lsr #8	
		AND		r5, r5, #0x0ff
		MOV		r5, r5, lsl #16
				
		AND		r6, r2, #0x0ff
		MOV		r6, r6, lsl #24
		
		MOV 	r2, #0
		ORR		r2, r2, r6
		ORR		r2, r2, r5
		ORR		r2, r2, r4
		ORR		r2, r2, r3	
		
M_3
        MOV     r0, r2
        BL      PrintWord
        LDR     r3, =Messages4
        BL      PrintNextMessage
        MOV     r0, r7
		MOV		r2, #0
        BL      PrintAddress

M_end
		LDR		r3, =Messages2
		BL		PrintNextMessage

		B Continue


;//----------------------------------------------------------------
;//COMMAND: 'm'
;//AUTHOR: APRICITY
Next4
		CMP		r1, #0x6D		;//'m'=0x6D
		BNE		Next5
        
        CMP     r2, #0          ;// args = 0, <address> is not specified
        BEQ     m_use_prev_addr ;// use the previous byte address + 1

        CMP     r2, #1          ;// args = 1, only <address> is specified
        BEQ     m_use_spec_addr ;// use that <address>
        
        CMP     r2, #2          ;// args = 2, <value> is specified
        BEQ     m_overwrite     ;// overwrite the memory contents

        B       InvalidComm

m_overwrite
        STRB    r4, [r3]
        LDR     r3, =Messages3
        BL      PrintNextMessage
        B       m_end

m_use_prev_addr
        LDR     r1, =mAddr
        LDR     r2, [r1]
        ADD     r2, r2, #1
        STR     r2, [r1]
        B       m_getdata

m_use_spec_addr
        LDR     r1, =mAddr
        MOV     r2, r3
        STR     r2, [r1]
        B       m_getdata

m_getdata
        LDRB    r0, [r2]        ;// get byte stored in address [r2]
        BL      PrintByte
m_printaddress
        LDR     r3, =Messages4
        BL      PrintNextMessage
        MOV     r0, r2
        BL      PrintAddress

m_end
        LDR     r3, =Messages2
        BL      PrintNextMessage
        B       Continue


;//----------------------------------------------------------------
;//COMMAND: 'R' or 'r'
Next5
		CMP		r1, #0x52		;//'R'=0x52
		CMPNE	r1, #0x72		;//'r'=0x72
		BNE		Next6

        CMP     r2, #0
        BEQ     R_PrintAll

        CMP     r2, #2
        BEQ     R_Modify

        B       InvalidComm

R_Modify
        CMP     r3, #0
        BLT     InvalidComm     ;// r3 < 0 -> invalid
        CMP     r3, #12
        BLE     R_Modify_0To12  ;// 0 <= r3 <= 1
        CMP     r3, #13
        BEQ     R_Modify_13
        CMP     r3, #14
        BEQ     R_Modify_14
        CMP     r3, #15
        BEQ     R_Modify_PC
        CMP     r3, #16
        BEQ     R_Modify_CPSR
        B       InvalidComm
R_Modify_0To12
        ADRL    r2, StackInit
        LDR     r2, [r2]        ;// address of r0-r12 storage
        SUB     r2, r2, #14*4
        ADD     r2, r2, r3, LSL #2
        STR     r4, [r2]
        B       R_Modify_End
R_Modify_End
        LDR     r3, =Messages3
        BL      PrintNextMessage
        LDR     r3, =Messages2
        BL      PrintNextMessage
        B       R_End
R_Modify_13
        STMFD   r13!, {r4}
        LDMFD   r13!, {r13}^
        B       R_Modify_End
R_Modify_14
        STMFD   r13!, {r4}
        LDMFD   r13!, {r14}^
        B       R_Modify_End
R_Modify_PC
        LDR     r1, =r14tmp
        STR     r0, [r1]
        B       R_Modify_End

R_PrintAll
        ADRL    r2, StackInit
        LDR     r2, [r2]        ;// address of r0-r12 storage
        SUB     r2, r2, #14*4
        MOV     r4, #0          ;// reg number
R_0To12
        BL      PrintRegNumber
        LDR     r0, [r2]
        BL      PrintWord
        LDR     r3, =Messages2
        BL      PrintNextMessage

        ADD     r2, r2, #4
        ADD     r4, r4, #1
        CMP     r4, #13
        BNE     R_0To12
R_13
        MOV     r4, #13
        BL      PrintRegNumber
        STMFD   r13!, {sp}^
        LDMFD   r13!, {r0}
        BL      PrintWord
        LDR     r3, =Messages2
        BL      PrintNextMessage
R_14
        MOV     r4, #14
        BL      PrintRegNumber
        STMFD   r13!, {lr}^
        LDMFD   r13!, {r0}
        BL      PrintWord
        LDR     r3, =Messages2
        BL      PrintNextMessage
R_PC
        MOV     r4, #15
        BL      PrintRegNumber
        LDR     r1, =r14tmp
        LDR     r0, [r1]
        BL      PrintWord
        LDR     r3, =Messages2
        BL      PrintNextMessage
R_SPSR
        MOV     r4, #16
        BL      PrintRegNumber
        MRS     r0, SPSR
        BL      PrintWord
        LDR     r3, =Messages2
        BL      PrintNextMessage
R_End
        B       Continue


;//----------------------------------------------------------------
;//more commands can be added here
Next6


;//----------------------------------------------------------------
InvalidComm
		LDR		r3, =Messages1
		BL		PrintNextMessage
		
Continue
        b       L1

MonQuit    
        ldmfd   r13!, {r0-r12,r14}	;//restore reg from stack
        mov		pc,r14				;//return to swi or undef


PrintNextMessage	;//output a string starting at [r3]
		STMFD	r13!, {r0-r12,r14}
		MOV		r0, #0x3			;//select Angel SYS_WRITEC function
NxtTxt	LDRB	r1, [r3], #1		;//get next character
		CMP		r1, #0				;//test for end mark
		SUBNE	r1, r3, #1			;//setup r1 for call to SWI
		SWINE	SWI_ANGEL			;//if not end, print..
		BNE		NxtTxt				;//..and loop
		LDMFD   r13!, {r0-r12,r14}
		MOV		pc, r14

PrintRegNumber                      ;// in r4
		STMFD	r13!, {r0-r12,r14}
        LDR     r1, =SendChar
        
        CMP     r4, #16
        BEQ     PrintRegCPSR

        MOV     r0, #"r"
        STR     r0, [r1]
        WriteC

        MOV     r0, r4
        BL      Print10

        MOV     r0, #" "
        STR     r0, [r1]
        WriteC

        CMP     r4, #9
        BLE     PrintRegNumber_Extra
PrintRegNumber_Mark
		MOV     r0, #":"
        STR     r0, [r1]
        WriteC
        MOV     r0, #" "
        STR     r0, [r1]
        WriteC

        LDMFD   r13!, {r0-r12,r14}
		MOV		pc, r14
PrintRegCPSR
        MOV     r0, #"C"
        STR     r0, [r1]
        WriteC
        MOV     r0, #"P"
        STR     r0, [r1]
        WriteC
        MOV     r0, #"S"
        STR     r0, [r1]
        WriteC
        MOV     r0, #"R"
        STR     r0, [r1]
        WriteC
        B       PrintRegNumber_Mark
PrintRegNumber_Extra
        MOV     r0, #" "
        STR     r0, [r1]
        WriteC
        B       PrintRegNumber_Mark

;//----------------------------------------------------------------
PrintWord
		STMFD	r13!, {r0-r12,r14}
		LDR		r1, DataFormat
        MOV     r2, #0              ;// set word mode
		MOV		r3, #1				;// put format sign
        B       PrintGO
PrintByte
        STMFD   r13!, {r0-r12,r14}
		LDR		r1, DataFormat
        MOV     r2, #1
		MOV		r3, #1				;// put format sign
        B       PrintGO
PrintWordPlain
		STMFD	r13!, {r0-r12,r14}
		LDR		r1, DataFormat
        MOV     r2, #0              ;// set word mode
		MOV		r3, #0				;// don't put format sign
        B       PrintGO
PrintBytePlain
		STMFD	r13!, {r0-r12,r14}
		LDR		r1, DataFormat
        MOV     r2, #1
		MOV		r3, #0				;// don't put format sign
        B       PrintGO
PrintAddress
		STMFD	r13!, {r0-r12,r14}
		MOV		r1, #16
        MOV     r2, #0
		MOV		r3, #0				;// don't put format sign
        B       PrintGO

PrintGO
        ;// Hex
		CMP		r1, #16
		BLEQ    Print16

        CMP     r1, #10
        BLEQ    Print10

        CMP     r1, #2
        BLEQ    Print2
        
		CMP		r3, #1
		BLEQ	PrintFormatSign

        LDMFD   r13!, {r0-r12,r14}
        MOV     pc, r14

;//----------------------------------------------------------------
PrintFormatSign
		STMFD   r13!, {r0-r12,r14}
		
		LDR		r1, DataFormat
		CMP		r1, #16
        MOVEQ   r0, #"h"
		CMP		r1, #10
		MOVEQ	r0, #"d"
		CMP		r1, #2
		MOVEQ	r0, #"b"
		LDR     r1, =SendChar
        STR     r0, [r1]
        WriteC

		LDMFD   r13!, {r0-r12,r14}
        MOV     pc, r14

;//----------------------------------------------------------------
Print16
        STMFD   r13!, {r0-r12,r14}
        MOV     r3, r0
        LDR     r1, =SendChar

        CMP     r2, #0              ;// r2 == 0 -> print word
        MOVEQ   r2, #32
        MOVNE   r2, #8              ;// r2 != 0 -> print byte
Print16_Loop
        SUB     r2, r2, #4
        MOV     r0, r3, LSR r2
        AND     r0, r0, #0xF
        CMP     r0, #9              ;// convert to ascii
        ADDGT   r0, r0, #"A"-10
        ADDLE   r0, r0, #"0"
        STR     r0, [r1]
        WriteC
        CMP     r2, #0
        BNE     Print16_Loop
Print16_End
        LDMFD   r13!, {r0-r12,r14}
        MOV     pc, r14

;//----------------------------------------------------------------
Print2
		STMFD	r13!, {r0-r12,r14}
        MOV     r3, r0
        LDR     r1, =SendChar

        CMP     r2, #0
        MOVEQ   r2, #32
        MOVNE   r2, #8
Print2_Loop
        SUB     r2, r2, #1
        MOV     r0, r3, LSR r2
        ANDS    r0, r0, #0x1
        MOVEQ   r0, #"0"
        MOVNE   r0, #"1"
        STR     r0, [r1]
        WriteC
        CMP     r2, #0
        BEQ     Print2_End
        MOVS    r4, r2, LSL #29
        BNE     Print2_Loop
        MOV     r0, #"_"
        STR     r0, [r1]
        WriteC
        B       Print2_Loop
Print2_End
		LDMFD	r13!, {r0-r12,r14}
		MOV		pc, r14

;//----------------------------------------------------------------
Print10
		STMFD	r13!, {r0-r12,r14}
        MOV     r3, r0
        LDR     r1, =SendChar
        LDR     r2, =0xCCCCCCCD
        MOV     r7, #0              ;// Counter

DivedeBy10  ;// https://community.arm.com/processors/b/blog/posts/divide-and-conquer
        UMULL   r5, r4, r2, r3      ;// Hack: r3 / 10
        MOV     r4, r4, LSR #3      ;// r4 is the quotient
        MOV     r8, r4, LSL #1      ;// r8 = r4 * 2
        ADD     r8, r8, r4, LSL #3  ;// r8 = r8 + r4 *8
        SUB     r0, r3, r8          ;// r0 = r3 - r8 is the remainder
        ADD     r0, r0, #"0"
        STMFD   r13!, {r0}
        ADD     r7, r7, #1
        MOVS    r3, r4
        BNE     DivedeBy10

Print10_Loop
        LDMFD   r13!, {r0}
        STR     r0, [r1]
        WriteC
        SUBS    r7, r7, #1
        BEQ     Print10_End
        B       Print10_Loop
Print10_End
		LDMFD	r13!, {r0-r12,r14}
		MOV		pc, r14


;//----------------------------------------------------------------
StackInit
        DCD     StackTop

	
        AREA stack, DATA, READWRITE
;// Place your data here
SendChar
		DCD 	0					;//sended char
DataFormat							;//the display of memory/register to decimal, hexadecimal or binary
		DCD		16					;//{10 | 16 | 2}, default 16
EndianType							;//the data representation to either little-endian ("E 0", default) or big-endian ("E 1").
		DCD		0					;//{0 | 1}, default 0
mAddr
		DCD		0
MAddr
		DCD		0
Messages1
		= "Invalid Command!", &0a, &0d, 0
		ALIGN
Messages2
		= &0a, &0d, 0
		ALIGN
Messages3
		= "Write Data!"
		ALIGN
Messages4
        = " @ 0x"
        ALIGN
StackBtm
        %        0x1000 
StackTop
        END

