		AREA	swi_test,CODE,READONLY
		EXTERN	INITVECTORS


;// ******************************************
;// * This file does NOT need to be modified *
;// ******************************************


SWI_ANGEL EQU 0x123456		;//SWI number for Angel semihosting	
Mode_USR  EQU     0x10

		MACRO
$l		Exit					;//Angel SWI call to terminate execution
$l		MOV		r0, #0x18		;//select Angel SWIreason_ReportException(0x18)
		LDR     r1, =0x20026	;//report ADP_Stopped_ApplicationExit
		SWI 	SWI_ANGEL		;//ARM semihosting SWI
		MEND



		ENTRY					;//code entry point

		;// You need to create the following procedure to initialise the ARM Vector Table
		;// (see SWI handler exercise)
		;// "Undefined Instruction" handler and SWI handler should be redirected to your Monitor
		BL		INITVECTORS

		;// Switch to User mode
        MSR     CPSR_c, #Mode_USR

		;// Set up some test values in registers and memory for the monitor
		LDR		r4, =0x12345678
		LDR		r5, =0x11112222
		LDR		r6, =0x22223333
		MOV		r7, #0x1000
		STMIA	r7!, {r4-r6}
		STMIA	r7!, {r4-r6}
		STMIA	r7!, {r4-r6}	
		STMIA	r7!, {r4-r6}

		;// Set up a "trampoline" code at address 0x800 to test "R 15 <value>" in the Monitor.
		;// "R 15 800" + "Q" should set the user mode program counter to 0x800, which should
		;// automatically jump to R15Test_Function, printing a "succesfull" message.
		;// This technique is identical to the one used to initialise the ARM vector table.
		MOV		r7, #0x800
		ADR		r8, R15Test_MemoryBlock
		LDMIA	r8, {r0-r1}
		STMIA	r7, {r0-r1}


		;// Testing the monitor: Alternate between printing a message and calling the monitor,
		;// twice, using 2 different methods supposed to start the monitor
		ADR		r3, Messages
		
		BL		PrintNextMessage
		DCD		0xe7ff0010		;// unknown opcode -> undefined instruction
								;// => should automatically call your monitor
								;// (Note: it usually also generates an "Undefined Instruction"
								;//        error box during simulation and breakpoints at the related
								;//        vector address - just run/step in to continue the execution)
		BL		PrintNextMessage
		SWI		0				;// This should also be redirected to your monitor
		BL		PrintNextMessage

		Exit					;//finish



PrintNextMessage	;//output string starting at [r3]
		MOV		r0, #0x3			;//select Angel SYS_WRITEC function
NxtTxt	LDRB	r1, [r3], #1		;//get next character
		CMP		r1, #0				;//test for end mark
		SUBNE	r1, r3, #1			;//setup r1 for call to SWI
		SWINE	SWI_ANGEL			;//if not end, print..
		BNE		NxtTxt				;//..and loop
		MOV		pc, r14

Messages
		= "Part 1: Testing the Undefined Instruction handler", &0a, &0d, 0
		= "Part 2: Undefined Instruction handler successful. Testing the SWI handler", &0a, &0d, 0
		= "Part 3: SWI handler successful. Exiting.", &0a, &0d, 0
		ALIGN
		

R15Test_MemoryBlock
		LDR		PC, R15Test_Pointer
R15Test_Pointer
		DCD		R15Test_Function
R15Test_Function
		ADR		r3, R15Test_Message
		BL		PrintNextMessage
		Exit
R15Test_Message
		= "R15Test completed successfully. Exiting.", &0a, &0d, 0

		END