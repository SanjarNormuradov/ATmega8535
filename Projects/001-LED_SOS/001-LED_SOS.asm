;******	Include Files ******
.include "m8535def.inc"

;******	Initialize GPR ******
.def TEMPR1 = R16
.def TEMPR2 = R17
.def SHORT_SOS_DELAY_R = R18
.def LONG_SOS_DELAY_R = R19
.def SOS_CNT = R20

;******	Initialize CONST ******
.equ LED = PORTB3
.equ BUTTON = PIND2

.equ EXT_INT0_ANY_SC = (0<<ISC01)|(1<<ISC00)
.equ EXT_INT0_EN = (1<<INT0)

.equ MAX_CNT = 255
.equ SHORT_SOS_SEC = 1
.equ LONG_SOS_SEC = 3


;******	Interrup Vectors ******
.org 0x000
	RJMP RESET
	RETI;	RJMP EXT_INT0


.org 0x015
	RESET:
		;	Initialize STACK
		LDI TEMPR1, HIGH(RAMEND)
		OUT SPH, TEMPR1
		LDI TEMPR1, LOW(RAMEND)
		OUT SPL, TEMPR1

		;	Initialize DDRB3 As PORT For LED
		SBI DDRB, LED
		SBI PORTB, LED

;		;*** External Interrupt 0 ***
;		;	Select Interrupt Sense Control
;		LDI TEMPR1, EXT_INT0_ANY_SC
;		OUT MCUCR, TEMPR1
;		;	Enable Interrupt
;		LDI TEMPR1, EXT_INT0_EN
;		OUT GICR, TEMPR1
		
		;	Enable Global Interrupt
		SEI


	;******	Main Program ******
	LOOP:
		SBIC PIND, BUTTON
		RJMP LED_OFF

		LED_ON:
			LDI SOS_CNT, 3
			SHORT_SOS:
				CBI PORTB, LED
				RCALL SHORT_SOS_DELAY
				SBI PORTB, LED
				RCALL SHORT_SOS_DELAY
				DEC SOS_CNT
				BRNE SHORT_SOS

			LDI SOS_CNT, 3
			LONG_SOS:
				RCALL LONG_SOS_DELAY
				CBI PORTB, LED
				RCALL LONG_SOS_DELAY
				SBI PORTB, LED
				DEC SOS_CNT
				BRNE LONG_SOS
			RJMP LOOP

		LED_OFF:
			SBI PORTB, LED

		RJMP LOOP


	;****** SubPrograms ******

	SHORT_SOS_DELAY:
	;	Setup Short SOS Delay Time In Sec
		LDI SHORT_SOS_DELAY_R, SHORT_SOS_SEC * 4
		CLR TEMPR1
		LDI TEMPR2, MAX_CNT
		SHORT_DELAY_BEGIN:
			CPI TEMPR1, MAX_CNT
			INC TEMPR1
			BRNE SHORT_DELAY_BEGIN
			DEC TEMPR2
			BRNE SHORT_DELAY_BEGIN
			DEC SHORT_SOS_DELAY_R
			BRNE SHORT_DELAY_BEGIN

		RET;	SubProgram Return

	LONG_SOS_DELAY:
	;	Setup Long SOS Delay Time In Sec
		LDI LONG_SOS_DELAY_R, LONG_SOS_SEC * 4
		CLR TEMPR1
		LDI TEMPR2, MAX_CNT
		LONG_DELAY_BEGIN:
			CPI TEMPR1, MAX_CNT
			INC TEMPR1
			BRNE LONG_DELAY_BEGIN
			DEC TEMPR2
			BRNE LONG_DELAY_BEGIN
			DEC LONG_SOS_DELAY_R
			BRNE LONG_DELAY_BEGIN		

		RET;	SubProgram Return


	;****** Interrupt Routines ******

	;*** External Interrupt 0 Request Hanlder ***
	EXT_INT0:
		;	Store Data Of TEMPR1/TEMPR2 In STACK
		PUSH TEMPR1
		PUSH TEMPR2


		;	Load Data From STACK To TEMPR1/TEMPR2 
		POP TEMPR2
		POP TEMPR1

		RETI;	Interrupt Return


		
