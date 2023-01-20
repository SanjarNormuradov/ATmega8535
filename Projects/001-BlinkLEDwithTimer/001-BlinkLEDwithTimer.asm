;	Include Files
.include "m8535def.inc"

;	Initialize GPR
.def TEMP = R16
.def TEMPR1 = R17

;	Initialize CONST
.equ BUTTON = PIND2
.equ LED = PORTB3
.equ MAX_CNT = 255
.equ DELAY_mSEC = 20

;	Interrup Vector
.org 0x0
	RJMP RESET
;	RJMP EXT_INT0
;	RJMP TIMER0_OVF
;	RJMP TIMER0_COMP

.org 0x15
	RESET:

		;	Initialize Stack
		LDI TEMP, LOW(RAMEND)
		OUT SPL, TEMP
		LDI TEMP, HIGH(RAMEND)
		OUT SPH, TEMP

		;	Enable PORTB3(OC0 Pin) As Output
		SBI DDRB, LED
		SBI PORTB, LED

;		;	Interrupt Settings
;		LDI TEMP, 1<<ISC00
;		OUT MCUCR, TEMP

;		;	Enable Interrupt 
;		LDI TEMP, 1<<INT0
;		OUT GICR, TEMP

		;	Select Clock Source
		IN TEMP, TCCR0
		CBR TEMP, (1<<CS00) | (1<<CS01) | (1<<CS02)

		;	Prescaler 1024, i.e. Frequency/1024
		SBR TEMP, (1<<CS00) | (1<<CS02)
		OUT TCCR0, TEMP

;		;	Enable TIMER0 Overflow Interrupt
;		IN TEMP, TIMSK
;		SBR TEMP, 1<<TOIE0
;		OUT TIMSK, TEMP

;		;	Enable TIMER0 Compare Match Interrupt
;		IN TEMP, TIMSK
;		SBR TEMP, 1<<OCIE0
;		OUT TIMSK, TEMP

		;	Load MAX Count In OCR0
		SBR TEMP, 180
		OUT OCR0, TEMP

		;	Enable CTC Mode In TIMER0 
;		IN TEMP, TCCR0
;		SBR TEMP, 1<<WGM01
;		CBR TEMP, 0<<WGM00
;		OUT TCCR0, TEMP

		;	Enable Fast PWM Mode In TIMER0
		IN TEMP, TCCR0
		SBR TEMP, (1<<WGM00) | (1<<WGM01)
		OUT TCCR0, TEMP

		;	Enable Inverting Compare Output Mode In Fast PWM Mode In TIMER0
		IN TEMP, TCCR0
		SBR TEMP, (1<<COM01)|(1<<COM00)
		OUT TCCR0, TEMP
		
;		;	Enable Global Interrupt
;		SEI
		


	;	Main Program
	LOOP:
		
		RJMP LOOP;	Start LOOP Again


	;	SubPrograms

	NOISE_DELAY:
		CLR TEMP
		CLR TEMPR1
		DELAY_BEGIN:
			CPI TEMP, MAX_CNT
			INC TEMP
			BRNE DELAY_BEGIN
			INC TEMPR1
			CPI TEMPR1, DELAY_mSEC
			BRNE DELAY_BEGIN

		RET;	SubProgram Return


	;	Interrupt Routines

;	;	EXT_INT0 Handler
;	EXT_INT0:
;		
;		;	Store Data of GPR in STACK
;		PUSH TEMP
;		PUSH TEMPR1
;
;		;	20ms Delay to Exclude Noise
;		RCALL NOISE_DELAY
;		
;		;	Store Bit From PORTB
;		IN TEMP, PORTB
;		LDI TEMPR1, 1<<LED
;
;		;	Invert Bit
;		EOR TEMP, TEMPR1
;
;		;	Load Bit To PORTB
;		OUT PORTB, TEMP
;		
;		;	Load Data of GPR from STACK
;		POP TEMPR1
;		POP TEMP
;
;		RETI;	Interrupt Return

;	;	TIMER0_OVF Handler
;	TIMER0_OVF:
;
;		;	Store Data of GPR in STACK
;		PUSH TEMP
;		PUSH TEMPR1
;
;		;	Store Bit From PORTB
;		IN TEMP, PORTB
;		LDI TEMPR1, 1<<LED
;
;		;	Invert Bit
;		EOR TEMP, TEMPR1;	Invert Bit To Toggle LED 
;
;		;	Load Bit To PORTB
;		OUT PORTB, TEMP
;
;		;	Load Data of GPR from STACK
;		POP TEMPR1
;		POP TEMP
;
;		RETI;	Interrupt Return

;	;	TIMER0_COMP Handler
;	TIMER0_COMP:
;
;		;	Store Data of GPR in STACK
;		PUSH TEMP
;		PUSH TEMPR1
;
;		;	Store Bit From PORTB
;		IN TEMP, PORTB
;		LDI TEMPR1, 1<<LED
;
;		;	Invert Bit
;		EOR TEMP, TEMPR1
;
;		;	Load Bit To PORTB
;		OUT PORTB, TEMP
;
;		;	Load Data of GPR from STACK
;		POP TEMPR1
;		POP TEMP
;
;		RETI;	Interrupt Return
