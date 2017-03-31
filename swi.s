		AREA	swi, CODE, READWRITE
		EXPORT	My_SWI_Handler
		;//install a swi handler for SWI 0xff to print string
		;//inline in the source code
		
SWI_ANGEL EQU 0x123456		;//SWI number for Angel semihosting	

		
My_SWI_Handler
		STR		r13, r13tmp			;//save r13
		LDR		r13, [r14, #-4]		;//get swi instruction
		BIC		r13, r13, #0xff000000	;//extract swi number
		CMP		r13, #0xff			;//this swi ?
		BEQ		DoIt
		LDR		r13, r13tmp			;//restore r13
		MOVS	pc, r14				;//return to user mode code
		
DoIt
		;//save r0 and r1, could use a stack here
		ADR		r13, r0tmp			;//set up tmp store pointer
		STMIA	r13, {r0,r1}		;//save r0,r1

;//;//;//;//;//;//;//;//;//;//;//;//;//start of TextOut routine from earlier exercise;//;//;//;//;//;//;//;//;// 
TextOut	;//output string starting at [r14]
		MOV		r0, #0x3			;//select Angel SYS_WRITEC function
NxtTxt	LDRB	r1, [r14], #1		;//get next character
		CMP		r1, #0				;//test for end mark
		SUBNE	r1, r14, #1			;//setup r1 for call to SWI
		SWINE	SWI_ANGEL			;//if not end, print..
		BNE		NxtTxt				;// ..and loop
		ADD		r14, r14, #3		;//pass next word boundary
		BIC		r14, r14, #3		;//round back to boundary
;//;//;//;//;//;//;//;//;//;//;//;//;//end of textout routine from earlier exercise;//;//;//;//;//;//;//;//;//;//;//

		;//restore r0,r1,r13
		LDMIA	r13, {r0,r1}		;//restore r0,r1
		LDR		r13, r13tmp			;//restore r13

		MOVS	pc, r14				;//return to user mode code


r0tmp     DCD 0
r1tmp     DCD 0
r13tmp	  DCD 0

		END
