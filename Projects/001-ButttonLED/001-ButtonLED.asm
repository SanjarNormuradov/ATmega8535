// Device
.device ATMEGA8535

// Include Files
.include "m8535def.inc"

// Init GPR
.def ACC0 = R16
.def ACC1 = R17

// Init CONST
.equ BUTTON = 2
.equ LED = 3
.equ MAX_CNT = 255
.equ DELAY_mSEC = 20

// Interrup Vector
.org 0x0
	RJMP RESET
	RJMP EXT_INT0


.org 0x15
	RESET:

// Init Stack
		LDI ACC0, HIGH(RAMEND)
		OUT SPH, ACC0
		LDI ACC0, LOW(RAMEND)
		OUT SPL, ACC0

// Init SFR
		SBI DDRB, LED

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

		RJMP LOOP // Start LOOP Again

// Interrupt Routines
	EXT_INT0:

// Store Data of GPR in STACK
		PUSH ACC0
		PUSH ACC1

// 20ms Delay to Exclude Noise
		RCALL DELAY

		SBIC PIND, BUTTON
		RJMP LED_OFF
		SBI PORTB, LED // LED_ON
		RJMP END_EXT_INT0
	
	LED_OFF:
		CBI PORTB, LED

	END_EXT_INT0:

// Load Data of GPR from STACK
		POP ACC1
		POP ACC0

		RETI // Interrupt Return

// SubProgram
	DELAY:
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
