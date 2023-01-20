// Include Files
.include "m8535def.inc"

// Init GPR
.def ACC0 = R16
.def ACC1 = R17
.def ACC2 = R18
.def LED_BLINKING = R19

// Init CONST
.equ TURN_ON = 1
.equ TURN_OFF = 0
.equ BUTTON = 2
.equ LED = 3
.equ MAX_CNT = 255
.equ DELAY_SEC = 1
.equ DELAY_mSEC = 20

// Interrup Vector
.org 0x0
	RJMP RESET
	RJMP EXT_INT0

.org 0x15
	RESET:
	
		// Init Stack
		LDI ACC0, LOW(RAMEND)
		OUT SPL, ACC0
		LDI ACC0, HIGH(RAMEND)
		OUT SPH, ACC0

		// Init SFR:
		SBI DDRB, LED
		SBI PORTB, LED

		// Interrupt Settings
		LDI ACC0, 1<<ISC00
		OUT MCUCR, ACC0

		// Enable Interrupt 
		LDI ACC0, 1<<INT0
		OUT GICR, ACC0

		// Enable Global Interrupt
		SEI


	// Main Program
	LOOP:
		SBRC LED_BLINKING, 0
		RCALL LED_BLINKING_CONTROL
		
		RJMP LOOP // Start LOOP Again


	// SubPrograms

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

	LED_BLINKING_CONTROL:

		START_BLINKING:
			CBI PORTB, LED
			RCALL DELAY
			SBI PORTB, LED
			RCALL DELAY
			
			SBRS LED_BLINKING, 0
			RJMP END_BLINKING
			RJMP START_BLINKING
		
		END_BLINKING:
			SBI PORTB, LED

		RET // SubProgram Return

	DELAY:
		CLR ACC0
		CLR ACC1
		CLR ACC2
		DELAY2:
			CPI ACC0, MAX_CNT
			INC ACC0
			BRNE DELAY2
			CPI ACC1, MAX_CNT
			INC ACC1
			BRNE DELAY2
			INC ACC2
			CPI ACC2, DELAY_SEC * 4
			BRNE DELAY2

		RET // SubProgram Return


	// Interrupt Routines
	EXT_INT0:
		
		// Store Data of GPR in STACK
		PUSH ACC0
		PUSH ACC1

		// 20ms Delay to Exclude Noise
		RCALL NOISE_DELAY

		SBIC PIND, BUTTON
		RJMP LED_BLINKING_OFF
		LDI LED_BLINKING, TURN_ON
		RJMP END_EXT_INT0
	
	LED_BLINKING_OFF:
		LDI LED_BLINKING, TURN_OFF

	END_EXT_INT0:

		// Load Data of GPR from STACK
		POP ACC1
		POP ACC0

		RETI // Interrupt Return
