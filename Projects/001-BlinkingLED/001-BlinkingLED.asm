// Include Files
.include "m8535def.inc"

// Init GPR
.def ACC0 = R16
.def ACC1 = R17
.def ACC2 = R18
.def BUTTON_CONTROL = R19

// Init CONST
.equ BUTTON = 2
.equ LED = 3
.equ MAX_CNT = 255
.equ MAX_DELAY = 4
.equ MIN_DELAY = 1
.equ DELAY_mSEC = 20

// Interrup Vector
.org 0x0
	RJMP RESET
;	RJMP EXT_INT0

.org 0x15
	RESET:

		// Init Stack
		LDI ACC0, LOW(RAMEND)
		OUT SPL, ACC0
		LDI ACC0, HIGH(RAMEND)
		OUT SPH, ACC0

		// Init SFR:
		SBI DDRB, LED

		// Set Initial Delay Option
		LDI BUTTON_CONTROL, MAX_DELAY * 4


		// Interrupt Settings
		LDI ACC0, (1<<ISC00)
		OUT MCUCR, ACC0

		// Enable Interrupt 
		LDI ACC0, 1<<INT0
		OUT GICR, ACC0

		// Enable Global Interrupt
		SEI



	// Main Program		
	LOOP:
		CBI PORTB, LED
		RCALL DELAY
		SBI PORTB, LED
		RCALL DELAY

		RJMP LOOP // Start LOOP Again


	// SubProgram

	NOISE_DELAY:
		CLR ACC0
		CLR ACC1
		DELAY1:
			CPI ACC0, MAX_CNT
			INC ACC0
			BRNE DELAY1
			INC ACC1
			CPI ACC1, DELAY_mSEC
			BRNE DELAY1

		RET // SubProgram Return

	DELAY:
		CLR ACC0
		CLR ACC2
		DELAY2:
			CPI ACC0, MAX_CNT
			INC ACC0
			BRNE DELAY2
			CPI ACC1, MAX_CNT
			INC ACC1
			BRNE DELAY2
			INC ACC2
			CP ACC2, BUTTON_CONTROL
			BRNE DELAY2

		RET // SubProgram Return


	// Interrupt Routines
	EXT_INT0:

		// Store Data of GPR in STACK
		PUSH ACC0
		PUSH ACC1
		PUSH ACC2

		// 20ms Delay to Exclude Noise
		RCALL NOISE_DELAY

		// Set Delay Option
		SBIC PIND, BUTTON
		RJMP MAXIMUM_DELAY
		LDI BUTTON_CONTROL, MIN_DELAY * 4 // Min Delay
		RJMP END_EXT_INT0

	// Max Delay
	MAXIMUM_DELAY:
		LDI BUTTON_CONTROL, MAX_DELAY * 4

	END_EXT_INT0:

		// Load Data of GPR from STACK
		POP ACC2
		POP ACC1
		POP ACC0

		RETI // Interrupt Return
