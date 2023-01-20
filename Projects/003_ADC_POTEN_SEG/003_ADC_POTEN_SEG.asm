;	Include Files
.include "m8535def.inc"

;	Initialize GPR
.def TEMPR1 = R16
.def TEMPR2 = R17
.def TEMPR3 = R18
.def TEMPR4 = R19
.def TEMPR0 = R20
.def OUTPUT_DATA = R21
.def ADC_DRL = R30
.def ADC_DRH = R31

;	Initialize CONST
.equ MAX_CNT = 255
.equ DELAY_mSEC = 20

.equ SEG_CLK = PORTC0
.equ SEG_DATA = PORTC1

.equ EXT_INT0_FALL_EDGE = (1<<ISC01)|(0<<ISC00)
.equ EXT_INT1_FALL_EDGE = (1<<ISC11)|(0<<ISC10)

.equ ADC0 = (0<<MUX4)|(0<<MUX3)|(0<<MUX2)|(0<<MUX1)|(0<<MUX0)
.equ ADC_PSC16 = (1<<ADPS2)|(0<<ADPS1)|(0<<ADPS0)
.equ ADC_AVCC = (0<<REFS1)|(1<<REFS0)
.equ ADC_TIM1_COMPB = (1<<ADTS2)|(0<<ADTS1)|(1<<ADTS0)

.equ DIGIT_0 = 0b11000000
.equ DIGIT_1 = 0b11111001
.equ DIGIT_2 = 0b10100100
.equ DIGIT_3 = 0b10110000
.equ DIGIT_4 = 0b10011001
.equ DIGIT_5 = 0b10010010
.equ DIGIT_6 = 0b10000010
.equ DIGIT_7 = 0b11111000
.equ DIGIT_8 = 0b10000000
.equ DIGIT_9 = 0b10010000

.equ TIM1_PSC1024 = (1<<CS12)|(0<<CS11)|(1<<CS10)
.equ TIM1_PERIOD_SEC = 5


;	Interrup Vector
.org 0x0
	RJMP RESET
	RJMP EXT_INT0
	RJMP EXT_INT1
	RETI;	RJMP TIM2_COMP
	RETI;	RJMP TIM2_OVF
	RETI;	RJMP TIM1_CAPT
	RETI;	RJMP TIM1_COMPA
	RJMP TIM1_COMPB
	RETI;	RJMP TIM1_OVF
	RETI;	RJMP TIM0_OVF
	RETI;	RJMP SPI_STC
	RETI;	RJMP USART_RXC
	RETI;	RJMP USART_DRE
	RETI;	RJMP USART_TXC
	RJMP ADC_COMP
	RETI;	RJMP EE_READY
	RETI;	RJMP ANA_COMP
	RETI;	RJMP TWI
	RETI;	RJMP INT2
	RETI;	RJMP TIM0_COMP
	RETI;	RJMP SPM_RDY

.org 0x15
	RESET:
		;	Initialize Stack
		LDI TEMPR1, LOW(RAMEND)
		OUT SPL, TEMPR1
		LDI TEMPR1, HIGH(RAMEND)
		OUT SPH, TEMPR1

		;	Initialize PORTC0 And PORTC1 As Outputs For 7-Segment Indicators
		LDI TEMPR1, (1<<SEG_CLK) | (1<<SEG_DATA)
		OUT DDRC, TEMPR1

		;	Turn Off All 7-segment Indicators
		RCALL SEGMENTS_SLEEP_MODE
	
		;*** External Interrupt 0 Settings ***
		;	Select Falling Edge On External Interrupt 0 As Interrupt Sense Control 
		LDI TEMPR1, EXT_INT0_FALL_EDGE
		OUT MCUCR, TEMPR1
		;	Enable External Interrupt Request 0
		LDI TEMPR1,(1<<INT0)
		OUT GICR, TEMPR1

		;*** External Interrupt 1 Settings ***
		;	Select Falling Edge On External Interrupt 1 As Interrupt Sense Control
		IN TEMPR1, MCUCR 
		SBR TEMPR1, EXT_INT1_FALL_EDGE
		OUT MCUCR, TEMPR1
		;	Enable External Interrupt Request 1
		IN TEMPR1, GICR
		SBR TEMPR1,(1<<INT1)
		OUT GICR, TEMPR1		
		
		;*** ADC Settings ***
		;	Select ADC Prescaler Of 16
		IN TEMPR1, ADCSRA
		SBR TEMPR1, ADC_PSC16
		OUT ADCSRA, TEMPR1
		;	Select Voltage Reference Of AVCC (~5V)
		IN TEMPR1, ADMUX
		SBR TEMPR1, ADC_AVCC
		OUT ADMUX, TEMPR1
		;	Select Analog Single-Ended Input Channel ADC0
		IN TEMPR1, ADMUX
		SBR TEMPR1, ADC0
		OUT ADMUX, TEMPR1
		;	Enable ADC Conversion Complete Interrupt
		SBI ADCSRA, ADIE
		;	Select Timer/Counter 1 Compare B Match As Auto Trigger Source
		IN TEMPR1, SFIOR
		SBR TEMPR1, ADC_TIM1_COMPB
		OUT SFIOR, TEMPR1
		;	Enable Auto-Triggering 
		SBI ADCSRA, ADATE

		;*** Timer 1 Settings ***
		;	Select Clock Source With Prescaler 1024, i.e. Frequency/1024
		IN TEMPR1, TCCR1B
		SBR TEMPR1, TIM1_PSC1024
		OUT TCCR1B, TEMPR1
		;	Define TOP In OCR1A For Compare Match Mode
		LDI TEMPR1, TIM1_PERIOD_SEC
		LSL TEMPR1
		LSL TEMPR1
		OUT OCR1AH, TEMPR1
		LDI TEMPR1, 0x00
		OUT OCR1AL, TEMPR1
		;	Copy TOP In OCR1A To OCR1B For Compare B Match Mode
		LDI TEMPR1, TIM1_PERIOD_SEC
		LSL TEMPR1
		LSL TEMPR1
		OUT OCR1BH, TEMPR1
		LDI TEMPR1, 0x00
		OUT OCR1BL, TEMPR1
		;	Enable CTC_OCR1A Mode
		IN TEMPR1, TCCR1A
		CBR TEMPR1, (0<<WGM11)|(0<<WGM10)
		OUT TCCR1A, TEMPR1
		IN TEMPR1, TCCR1B
		CBR TEMPR1, (0<<WGM13)
		SBR TEMPR1, (1<<WGM12)
		OUT TCCR1B, TEMPR1
		;	Enable Compare B Match Interrupt
		IN TEMPR1, TIMSK
		SBR TEMPR1, (1<<OCIE1B)
		OUT TIMSK, TEMPR1
				
		;	Enable Global Interrupt
		SEI


;****** Main Program ******
	LOOP:

		RJMP LOOP;	Start LOOP Again


;****** SubPrograms ******

	;*** 20ms Delay to Exclude Contact Noise ***
	NOISE_DELAY:
		CLR TEMPR1
		CLR TEMPR2
		DELAY_BEGIN:
			CPI TEMPR1, MAX_CNT
			INC TEMPR1
			BRNE DELAY_BEGIN
			INC TEMPR2
			CPI TEMPR2, DELAY_mSEC
			BRNE DELAY_BEGIN
		
		RET;	SubProgram Return

	;*** Turn Off All 7-Segment Indicators ***
	SEGMENTS_SLEEP_MODE:
		SBI PORTC, SEG_DATA
		LDI TEMPR1, 0x20
		SLEEP_MODE_BEGIN:
			SBI PORTC, SEG_CLK
			CBI PORTC, SEG_CLK
			DEC TEMPR1
			BRNE SLEEP_MODE_BEGIN

		RET;	SubProgram Return

	;*** Send 1st Digit To 1st Indicator ***
	SEND_1ST_DIGIT:
		;	Include Dot-Segment In 1st Digit 
		CBR TEMPR0, 0x80
		MOV OUTPUT_DATA, TEMPR0
		RCALL SERIAL_TRANSFER

		RET;	SubProgram Return

	;*** Serial Data Transfer To One 7-Segment Indicator ***
	SERIAL_TRANSFER:
		LDI TEMPR1, 0x8
		TRANSFER_BEGIN:
			LSL OUTPUT_DATA
			BRCS SEND_1
			SEND_0:
				CBI PORTC, SEG_DATA
				SBI PORTC, SEG_CLK
				CBI PORTC, SEG_CLK
				DEC TEMPR1
				BRNE TRANSFER_BEGIN
				RJMP TRANSFER_END

			SEND_1:
				SBI PORTC, SEG_DATA
				SBI PORTC, SEG_CLK
				CBI PORTC, SEG_CLK
				DEC TEMPR1
				BRNE TRANSFER_BEGIN

		TRANSFER_END:
			RET;	SubProgram Return

	ADC_RESULT_SEND:
		SENDING_BEGIN:
			IN ADC_DRL, ADCL
			IN ADC_DRH, ADCH
			
			SBIW ADC_DRH:ADC_DRL, 1
			BRCS RESULT_0V
			ADIW ADC_DRH:ADC_DRL, 1
			ADIW ADC_DRH:ADC_DRL, 1
			SBRC ADC_DRH, 2
			RJMP RESULT_5V
			RJMP ANY_OTHER_RESULT

			;	Result = 0x000 i.e. 0V
			RESULT_0V:
				RCALL SEGMENTS_SLEEP_MODE
				;	Send 1st Digit To 1st Indicator
				LDI TEMPR0, DIGIT_0
				RCALL SEND_1ST_DIGIT
				;	Send 2nd Digit To 2nd Indicator
				LDI OUTPUT_DATA, DIGIT_0
				RCALL SERIAL_TRANSFER
				;	Send 3rd Digit To 3rd Indicator
				LDI OUTPUT_DATA, DIGIT_0
				RCALL SERIAL_TRANSFER
				;	Send 4th Digit To 4th Indicator
				LDI OUTPUT_DATA, DIGIT_0
				RCALL SERIAL_TRANSFER
				RJMP SENDING_END

			;	Result = 0x3FF i.e. 5V
			RESULT_5V:
				RCALL SEGMENTS_SLEEP_MODE
				;	Send 1st Digit To 1st Indicator
				LDI TEMPR0, DIGIT_5
				RCALL SEND_1ST_DIGIT
				;	Send 2nd Digit To 2nd Indicator
				LDI OUTPUT_DATA, DIGIT_0
				RCALL SERIAL_TRANSFER
				;	Send 3rd Digit To 3rd Indicator
				LDI OUTPUT_DATA, DIGIT_0
				RCALL SERIAL_TRANSFER
				;	Send 4th Digit To 4th Indicator
				LDI OUTPUT_DATA, DIGIT_0
				RCALL SERIAL_TRANSFER
				RJMP SENDING_END

			;	Any Other Result 
			ANY_OTHER_RESULT:		
				MOV TEMPR3, ADC_DRH
				LDI TEMPR1, 6
				SHIFT_LEFT_x6:
					LSL ADC_DRH
					DEC TEMPR1
					BRNE SHIFT_LEFT_x6
				MOV TEMPR2, ADC_DRL
				LDI TEMPR1, 2
				SHIFT_RIGHT_x2:
					LSR TEMPR2
					DEC TEMPR1
					BRNE SHIFT_RIGHT_x2
				OR ADC_DRH, TEMPR2
				ADD ADC_DRL, ADC_DRH
				CLR ADC_DRH
				ADC ADC_DRH, TEMPR3
			
				;	Send Whole Part Of Result
				RESULT_WHOLE_PART_SEND:
					CPI ADC_DRH, 4
					BREQ WHOLE_4
					CPI ADC_DRH, 3
					BREQ WHOLE_3
					CPI ADC_DRH, 2
					BREQ WHOLE_2
					CPI ADC_DRH, 1
					BREQ WHOLE_1
					CPI ADC_DRH, 0
					BREQ WHOLE_0

					WHOLE_0:
						LDI TEMPR0, DIGIT_0
						RJMP RESULT_FRACTIONAL_PART_SEND
					WHOLE_1:
						LDI TEMPR0, DIGIT_1
						RJMP RESULT_FRACTIONAL_PART_SEND
					WHOLE_2:
						LDI TEMPR0, DIGIT_2
						RJMP RESULT_FRACTIONAL_PART_SEND
					WHOLE_3:
						LDI TEMPR0, DIGIT_3
						RJMP RESULT_FRACTIONAL_PART_SEND
					WHOLE_4:
						LDI TEMPR0, DIGIT_4
			
				;	Send Fractional Part Of Result	
				RESULT_FRACTIONAL_PART_SEND:
					;	0.Xxxxxxxx
					LSL ADC_DRL
					BRCS FR1_56789
					;	0.0xxxxxxx
					FR1_01234:
						;	0.0Xxxxxxx
						LSL ADC_DRL
						BRCS FR1_01234_FR1_234
						;	0.00xxxxxx
						FR1_01234_FR1_01:
							;	0.00Xxxxxx
							LSL ADC_DRL
							BRCS FR1_01234_FR1_01_FR1_1
							;	0.000xxxxx
							FR1_01234_FR1_01_FR1_0:
								;	0.000Xxxxx
								LSL ADC_DRL
								BRCS FR1_01234_FR1_01_FR1_0_FR2_6
								;	0.0000xxxx
								FR1_01234_FR1_01_FR1_0_FR2_0:
									;	Store 2nd Digit(=0) To Send It Later
									LDI TEMPR2, DIGIT_0
									;	Store 3rd Digit(=0) To Send It Later
									LDI TEMPR3, DIGIT_0
									;	Store 4th Digit(=0) To Send It Later
									LDI TEMPR4, DIGIT_0
									RJMP SENDING_END								
								;	0.0001xxxx
								FR1_01234_FR1_01_FR1_0_FR2_6:
									;	Store 2nd Digit(=0) To Send It Later
									LDI TEMPR2, DIGIT_0
									;	Store 3rd Digit(=6) To Send It Later
									LDI TEMPR3, DIGIT_6
									;	Store 4th Digit(=3) To Send It Later
									LDI TEMPR4, DIGIT_3
									RJMP SENDING_END
							;	0.001xxxxx
							FR1_01234_FR1_01_FR1_1:
								;	0.001Xxxxx
								LSL ADC_DRL
								BRCS 	FR1_01234_FR1_01_FR1_1_FR2_8
								;	0.0010xxxx
								FR1_01234_FR1_01_FR1_1_FR2_2:
									;	Store 2nd Digit(=1) To Send It Later
									LDI TEMPR2, DIGIT_1
									;	Store 3rd Digit(=2) To Send It Later
									LDI TEMPR3, DIGIT_2
									;	Store 4th Digit(=5) To Send It Later
									LDI TEMPR4, DIGIT_5
									RJMP SENDING_END								
								;	0.0011xxxx
								FR1_01234_FR1_01_FR1_1_FR2_8:
									;	Store 2nd Digit(=1) To Send It Later
									LDI TEMPR2, DIGIT_1
									;	Store 3rd Digit(=8) To Send It Later
									LDI TEMPR3, DIGIT_8
									;	Store 4th Digit(=8) To Send It Later
									LDI TEMPR4, DIGIT_8
									RJMP SENDING_END									
						;	0.01xxxxxx
						FR1_01234_FR1_234:
							;	0.01Xxxxxx
							LSL ADC_DRL
							BRCS FR1_01234_FR1_234_FR1_34
							;	0.010xxxxx
							FR1_01234_FR1_234_FR1_23:
								;	0.100Xxxxx
								LSL ADC_DRL
								BRCS FR1_01234_FR1_234_FR1_23_FR1_3
								;	0.0100xxxx
								FR1_01234_FR1_234_FR1_23_FR1_2:
									;	Store 2nd Digit(=2) To Send It Later
									LDI TEMPR2, DIGIT_2
									;	Store 3rd Digit(=5) To Send It Later
									LDI TEMPR3, DIGIT_5
									;	Store 4th Digit(=0) To Send It Later
									LDI TEMPR4, DIGIT_0
									RJMP SENDING_END
								;	0.0101xxxx
								FR1_01234_FR1_234_FR1_23_FR1_3:
									;	Store 2nd Digit(=3) To Send It Later
									LDI TEMPR2, DIGIT_3
									;	Store 3rd Digit(=1) To Send It Later
									LDI TEMPR3, DIGIT_1
									;	Store 4th Digit(=3) To Send It Later
									LDI TEMPR4, DIGIT_3
									RJMP SENDING_END
							;	0.011xxxxx
							FR1_01234_FR1_234_FR1_34:
								;	0.011Xxxxx
								LSL ADC_DRL
								BRCS 	FR1_01234_FR1_234_FR1_34_FR1_4
								;	0.0110xxxx
								FR1_01234_FR1_234_FR1_34_FR1_3:
									;	Store 2nd Digit(=3) To Send It Later
									LDI TEMPR2, DIGIT_3
									;	Store 3rd Digit(=7) To Send It Later
									LDI TEMPR3, DIGIT_7
									;	Store 4th Digit(=5) To Send It Later
									LDI TEMPR4, DIGIT_5
									RJMP SENDING_END
								;	0.0111xxxx
								FR1_01234_FR1_234_FR1_34_FR1_4:
									;	Store 2nd Digit(=4) To Send It Later
									LDI TEMPR2, DIGIT_4
									;	Store 3rd Digit(=3) To Send It Later
									LDI TEMPR3, DIGIT_3
									;	Store 4th Digit(=8) To Send It Later
									LDI TEMPR4, DIGIT_8
									RJMP SENDING_END									
					;	0.1xxxxxxx
					FR1_56789:
						;	0.1Xxxxxxx
						LSL ADC_DRL
						BRCS FR1_56789_FR1_789
						;	0.10xxxxxx
						FR1_56789_FR1_56:
							;	0.10Xxxxxx
							LSL ADC_DRL
							BRCS FR1_56789_FR1_56_FR1_6
							;	0.100xxxxx
							FR1_56789_FR1_56_FR1_5:
								;	0.100Xxxxx
								LSL ADC_DRL
								BRCS FR1_56789_FR1_56_FR1_5_FR2_6
								;	0.1000xxxx
								FR1_56789_FR1_56_FR1_5_FR2_0:
									;	Store 2nd Digit(=5) To Send It Later
									LDI TEMPR2, DIGIT_5
									;	Store 3rd Digit(=0) To Send It Later
									LDI TEMPR3, DIGIT_0
									;	Store 4th Digit(=0) To Send It Later
									LDI TEMPR4, DIGIT_0
									RJMP SENDING_END								
								;	0.1001xxxx
								FR1_56789_FR1_56_FR1_5_FR2_6:
									;	Store 2nd Digit(=5) To Send It Later
									LDI TEMPR2, DIGIT_5
									;	Store 3rd Digit(=6) To Send It Later
									LDI TEMPR3, DIGIT_6
									;	Store 4th Digit(=3) To Send It Later
									LDI TEMPR4, DIGIT_3
									RJMP SENDING_END
							;	0.101xxxxx
							FR1_56789_FR1_56_FR1_6:
								;	0.101Xxxxx
								LSL ADC_DRL
								BRCS FR1_56789_FR1_56_FR1_6_FR2_8
								;	0.1010xxxx
								FR1_56789_FR1_56_FR1_6_FR2_2:
									;	Store 2nd Digit(=6) To Send It Later
									LDI TEMPR2, DIGIT_6
									;	Store 3rd Digit(=2) To Send It Later
									LDI TEMPR3, DIGIT_2
									;	Store 4th Digit(=5) To Send It Later
									LDI TEMPR4, DIGIT_5
									RJMP SENDING_END								
								;	0.1011xxxx
								FR1_56789_FR1_56_FR1_6_FR2_8:
									;	Store 2nd Digit(=6) To Send It Later
									LDI TEMPR2, DIGIT_6
									;	Store 3rd Digit(=8) To Send It Later
									LDI TEMPR3, DIGIT_8
									;	Store 4th Digit(=8) To Send It Later
									LDI TEMPR4, DIGIT_8
									RJMP SENDING_END
						;	0.11xxxxxx
						FR1_56789_FR1_789:
							;	0.11Xxxxxx
							LSL ADC_DRL
							BRCS FR1_56789_FR1_789_FR1_89
							;	0.110xxxxx
							FR1_56789_FR1_789_FR1_78:
								;	0.110Xxxxx
								LSL ADC_DRL
								BRCS FR1_56789_FR1_789_FR1_78_FR1_8
								;	0.1100xxxx
								FR1_56789_FR1_789_FR1_78_FR1_7:
									;	Store 2nd Digit(=7) To Send It Later
									LDI TEMPR2, DIGIT_7
									;	Store 3rd Digit(=5) To Send It Laterr
									LDI TEMPR3, DIGIT_5
									;	Store 4th Digit(=0) To Send It Later
									LDI TEMPR4, DIGIT_0
									RJMP SENDING_END
								;	0.1101xxxx
								FR1_56789_FR1_789_FR1_78_FR1_8:
									;	Store 2nd Digit(=8) To Send It Later
									LDI TEMPR2, DIGIT_8
									;	Store 3rd Digit(=1) To Send It Later
									LDI TEMPR3, DIGIT_1
									;	Store 4th Digit(=3) To Send It Later
									LDI TEMPR4, DIGIT_3
									RJMP SENDING_END
							;	0.111xxxxx
							FR1_56789_FR1_789_FR1_89:
								;	0.111Xxxxx
								LSL ADC_DRL
								BRCS FR1_56789_FR1_789_FR1_89_FR1_9
								;	0.1110xxxx
								FR1_56789_FR1_789_FR1_89_FR1_8:
									;	Store 2nd Digit(=8) To Send It Later
									LDI TEMPR2, DIGIT_8
									;	Store 3rd Digit(=7) To Send It Later
									LDI TEMPR3, DIGIT_7
									;	Store 4th Digit(=5) To Send It Later
									LDI TEMPR4, DIGIT_5
									RJMP SENDING_END
								;	0.1111xxxx
								FR1_56789_FR1_789_FR1_89_FR1_9:
									;	Store 2nd Digit(=9) To Send It Later
									LDI TEMPR2, DIGIT_9
									;	Store 3rd Digit(=3) To Send It Later
									LDI TEMPR3, DIGIT_3
									;	Store 4th Digit(=8) To Send It Later
									LDI TEMPR4, DIGIT_8

				SENDING_END:
					RCALL SEGMENTS_SLEEP_MODE
					;	Send 1st Digit To 1st Indicator
					RCALL SEND_1ST_DIGIT
					;	Send 2nd Digit To 2nd Indicator
					MOV OUTPUT_DATA, TEMPR2
					RCALL SERIAL_TRANSFER
					;	Send 3rd Digit To 3rd Indicator
					MOV OUTPUT_DATA, TEMPR3
					RCALL SERIAL_TRANSFER
					;	Send 4th Digit To 4th Indicator
					MOV OUTPUT_DATA, TEMPR4
					RCALL SERIAL_TRANSFER

					RET;	SubProgram Return

;****** Interrupt Routines ******

	;*** External Interrupt 0 Request Handler ***
	EXT_INT0:
		;	Store Data of GPR in STACK
		PUSH TEMPR1
		PUSH TEMPR2

		;	20ms Delay to Exclude Contact Noise
		RCALL NOISE_DELAY

		;	Enable ADC 
		SBI ADCSRA, ADEN

		;	Load Stored Data of GPR from STACK
		POP TEMPR2
		POP TEMPR1

		RETI;	Interrupt Return

	;*** External Interrupt 1 Request Handler ***
	EXT_INT1:
		;	Store Data of GPR in STACK
		PUSH TEMPR1
		PUSH TEMPR2

		;	20ms Delay to Exclude Noise
		RCALL NOISE_DELAY

		;	Disable ADC
		CBI ADCSRA, ADEN

		RCALL SEGMENTS_SLEEP_MODE

		;	Load Stored Data of GPR from STACK
		POP TEMPR2
		POP TEMPR1

		RETI;	Interrupt Return

	;*** ADC Conversion Complete Request Handler ***
	ADC_COMP:
		;	Store Data of GPR in STACK
		PUSH TEMPR1
		PUSH TEMPR2

		RCALL ADC_RESULT_SEND

		;	Clear Output Compare B Match Flag, OCF1B
;		IN TEMPR1, TIFR
;		SBR TEMPR1, (1<<OCF1B)
;		OUT TIFR, TEMPR1

		;	Load Stored Data of GPR from STACK
		POP TEMPR2
		POP TEMPR1
	
		RETI;	Interrupt Return

	;*** Timer 1 Compare B Match Request Handler ***
	TIM1_COMPB:

		RETI;	Interrupt Return
