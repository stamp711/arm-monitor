        AREA Monitor1, CODE,READONLY
        IMPORT  Getline
		EXPORT	Monitor
		EXPORT 	SendChar
		EXTERN	r14tmp
;//******************************************************
;//                      Wei Zhao                       *
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


;//--------------------------------
;//COMMAND: 'Q'
		CMP		r1, #0x51		;//'Q'=0x51
		BNE		Next0
		CMP		r2, #0
		BNE		InvalidComm
		B		MonQuit


;//--------------------------------
;//COMMAND: 'E'
://AUTHOR: APRICITY
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


;//--------------------------------
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
		

;//--------------------------------
;//COMMAND: 'C'
Next2
		CMP		r1, #0x43		;//'C'=0x43
		BNE		Next3
		;//Task2: You have to implement COMMAND 'C' here
        

;//--------------------------------
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
		LDR		r3, DataFormat		
		CMP		r3, #16
		BNE		M_print10
M_print16	
		MOV 	r0, r2
		BL		Print16
		
		MOV 	r0, #'h'		;//print character
		LDR		r1, =SendChar
		STR		r0, [r1]		;//store character to print
		WriteC					;//print character 'h'
        b		M_end
M_print10
		CMP		r3, #10
		BNE		M_print2		
		MOV		r0, r2

		BL		Print10
		b		M_end
M_print2
		MOV		r0, r2

		BL		Print2
		MOV 	r0, #'b'		;//print character
		LDR		r1, =SendChar
		STR		r0, [r1]		;//store character to print
		WriteC					;//print character 'h'			
M_end
		LDR		r3, =Messages2
		BL		PrintNextMessage

		B Continue


;//--------------------------------
;//COMMAND: 'm'
;//AUTHOR: APRICITY
Next4
		CMP		r1, #0x6D		;//'m'=0x6D
		BNE		Next5
        
        CMP     r2, #0          ;// args = 0, <address> is not specified
        BEQ     m_use_prev_addr ;// use the previous byte address + 1

        CMP     r2, #1          ;// args = 1, only <address> is specified
        BEQ     m_use_spec_addr ;// use that <address>
        
        CMP     r2, #1          ;// args = 2, <value> is specified
        BEQ     m_overwrite     ;// overwrite the memory contents

        B       InvalidComm

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
        LDRB    r2, [r2]        ;// get byte stored in address [r2]

m_overwrite


;//--------------------------------
;//COMMAND: 'R' or 'r'
Next5
		CMP		r1, #0x52		;//'R'=0x52
		CMPNE	r1, #0x72		;//'r'=0x72
		BNE		Next6
		;//Task4: You have to implement COMMAND 'R' and 'r' here		


;//--------------------------------
;//more commands can be added here
Next6


;//--------------------------------
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

Print10		;//output the string of a number at r0 in DEC format
		STMFD	r13!, {r0-r12,r14}

		;//Task5: You have to implement Print10 function here	
		
		LDMFD   r13!, {r0-r12,r14}
		MOV		pc, r14		


Print16		;//output the string of a number at r0 in HEX format
		STMFD	r13!, {r0-r12,r14}
		MOV		r3, r0
		MOV		r4, #8				;//nibble count = 8
		LDR		r1, =SendChar
LoopPrint16
		MOV		r0, r3, LSR #28		;//get top nibble
		CMP		r0, #9				;//0-9 or A-F
		ADDGT	r0, r0, #"A"-10		;//ASCII alphabetic
		ADDLE	r0, r0, #"0"		;//ASCI numeric
		STR		r0, [r1]			;//store character to print
		WriteC						;//print character
		MOV		r3, r3, LSL #4		;//shift left one nibble
		SUBS	r4, r4, #1			;//decrement nibble count
		BNE		LoopPrint16			;//if more do next nibble
		LDMFD   r13!, {r0-r12,r14}
		MOV		pc, r14

Print2		;//output the string of a 32 bits number at r0 in bin format
		STMFD	r13!, {r0-r12,r14}
		;//Task6: You have to implement Print2 function here		

		LDMFD   r13!, {r0-r12,r14}
		MOV		pc, r14

PrintData		;//output the string of a number at r0 in given format
		STMFD	r13!, {r0-r12,r14}
		
		LDR		r1, DataFormat	
		CMP		r1, #16
		BLEQ	Print16
		CMP		r1, #10
		BLEQ	Print10	
		CMP		r1, #2
		BLEQ	Print2		
		
		LDMFD   r13!, {r0-r12,r14}
		MOV		pc, r14	





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
StackBtm
        %        0x1000 
StackTop
        END

