;****** Include Files ******
.include "m8535def.inc"

;****** Initialize GPR ******
.def TEMPR0 = R16
.def TEMPR1 = R17
.def TEMPR2 = R18
.def TEMPR3 = R19
.def OUTPUT_DATA = R20
.def TIM1_DELAY = R21
.def ADC_DRL = R30
.def ADC_DRH = R31

;****** Initialize CONST ******

;*** PORT/PIN ***
.equ LED = PORTD4
.equ BUTTON_1 = PIND2
.equ BUTTON_2 = PIND3
.equ SEG_CLK = PORTC0
.equ SEG_DATA = PORTC1

;*** External Interrupts ***
.equ EXT_INT0_ANY_ISC = (0<<ISC01)|(1<<ISC00)
.equ EXT_INT1_ANY_ISC = (0<<ISC11)|(1<<ISC10)
.equ EXT_INT0_EN = (1<<INT0)
.equ EXT_INT1_EN = (1<<INT1)

;*** ADC Parameters ***
.equ ADC_RHEOSTAT = (0<<MUX4)|(0<<MUX3)|(0<<MUX2)|(0<<MUX1)|(0<<MUX0)
.equ ADC_PHOTORESISTOR = (0<<MUX4)|(0<<MUX3)|(0<<MUX2)|(1<<MUX1)|(1<<MUX0)
.equ ADC_CHANNEL_RESET = (1<<MUX4)|(1<<MUX3)|(1<<MUX2)|(1<<MUX1)|(1<<MUX0)
.equ ADC_PSC16 = (1<<ADPS2)|(0<<ADPS1)|(0<<ADPS0)
.equ ADC_AVCC = (0<<REFS1)|(1<<REFS0)
.equ ADC_TIM1_OVF = (1<<ADTS2)|(1<<ADTS1)|(0<<ADTS0)

;*** Timer 1 Parameters ***
.equ TIM1_PSC_RESET = (1<<CS12)|(1<<CS11)|(1<<CS10)
.equ TIM1_PSC1024 = (1<<CS12)|(0<<CS11)|(1<<CS10)
.equ TIM1_MODE_RESET_A = (1<<WGM11)|(1<<WGM10)
.equ TIM1_MODE_RESET_B = (1<<WGM13)|(1<<WGM12)
.equ TIM1_FAST_PWM_OCR1A_A = (1<<WGM11)|(1<<WGM10)
.equ TIM1_FAST_PWM_OCR1A_B = (1<<WGM13)|(1<<WGM12)
.equ TIM1_COM_RESET_B = (1<<COM1B1)|(1<<COM1B0)
.equ TIM1_FAST_PWM_INVERT_B = (1<<COM1B1)|(1<<COM1B0)
.equ TIM1_INT_OVF = (1<<TOIE1)

;*** Delay Parameters ***
.equ MAX_CNT = 255
.equ DELAY_mSEC = 20
.equ TIM1_DELAY_SEC = 20

;*** 7-Segment Indicator ***
.equ DIGIT_NONE = 0b11111111
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


;****** Interrup Vector ******
.org 0x0
	RJMP RESET
	RJMP EXT_INT0
	RJMP EXT_INT1
	RETI;	RJMP TIM2_COMP
	RETI;	RJMP TIM2_OVF
	RETI;	RJMP TIM1_CAPT
	RETI;	RJMP TIM1_COMPA
	RETI;	RJMP TIM1_COMPB
	RJMP TIM1_OVF
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

		;	Initialize PORTD4(OC1B Pin) As Output For LED
		SBI DDRD, LED
		SBI PORTD, LED

		;	Initialize PORTC1:0 As DATA:CLK Outputs For 7-Segment Indicators
		LDI TEMPR1, (1<<SEG_DATA)|(1<<SEG_CLK)
		OUT DDRC, TEMPR1

		;	Turn Off All 7-segment Indicators
		RCALL SEGMENTS_SLEEP_MODE
	
		;*** External Interrupt 0 Settings ***
		;	Select Any Logical Change As Interrupt Sense Control 
		LDI TEMPR1, EXT_INT0_ANY_ISC
		OUT MCUCR, TEMPR1
		;	Enable External Interrupt 0 Request
		LDI TEMPR1,	EXT_INT0_EN
		OUT GICR, TEMPR1

		;*** External Interrupt 1 Settings ***
		;	Select Any Logical Change As Interrupt Sense Control
		IN TEMPR1, MCUCR 
		SBR TEMPR1, EXT_INT1_ANY_ISC
		OUT MCUCR, TEMPR1
		;	Enable External Interrupt 1 Request
		IN TEMPR1, GICR
		SBR TEMPR1,	EXT_INT1_EN
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
		;	ADC_INPUT_CHANNEL_SELECT_BEGIN
		SBIS PIND, BUTTON_2
		RJMP ADC_INITIAL_SOURCE_PHOTORESISTOR
		RJMP ADC_INITIAL_SOURCE_RHEOSTAT	
		ADC_INITIAL_SOURCE_PHOTORESISTOR:
			;	Select Photoresistor As Analog Single-Ended Input Channel
			IN TEMPR1, ADMUX
			CBR TEMPR1, ADC_CHANNEL_RESET
			SBR TEMPR1, ADC_PHOTORESISTOR
			OUT ADMUX, TEMPR1
			RJMP ADC_INPUT_CHANNEL_SELECT_END										
		ADC_INITIAL_SOURCE_RHEOSTAT:
			;	Select Rheostat As Analog Single-Ended Input Channel
			IN TEMPR1, ADMUX
			CBR TEMPR1, ADC_CHANNEL_RESET
			SBR TEMPR1, ADC_RHEOSTAT
			OUT ADMUX, TEMPR1
		ADC_INPUT_CHANNEL_SELECT_END:
		;	Select Timer/Counter 1 Overflow As Auto Trigger Source
		IN TEMPR1, SFIOR
		SBR TEMPR1, ADC_TIM1_OVF
		OUT SFIOR, TEMPR1
		;	Enable Auto-Triggering 
		SBI ADCSRA, ADATE
		;	Enable ADC Conversion Complete Interrupt
		SBI ADCSRA, ADIE

		;*** Timer 1 Settings ***
		;	Select Clock Source With Prescaler 1024, i.e. Frequency/1024
		IN TEMPR1, TCCR1B
		CBR TEMPR1, TIM1_PSC_RESET
		SBR TEMPR1, TIM1_PSC1024
		OUT TCCR1B, TEMPR1
		;	Enable Fast PWM OCR1A Mode
		IN TEMPR1, TCCR1B
		CBR TEMPR1, TIM1_MODE_RESET_B
		SBR TEMPR1, TIM1_FAST_PWM_OCR1A_B
		OUT TCCR1B, TEMPR1
		IN TEMPR1, TCCR1A
		CBR TEMPR1, TIM1_MODE_RESET_A
		SBR TEMPR1, TIM1_FAST_PWM_OCR1A_A
		OUT TCCR1A, TEMPR1
		;	Select Inverting Fast PWM Mode For OC1B Pin
		IN TEMPR1, TCCR1A
		CBR TEMPR1, TIM1_COM_RESET_B
		SBR TEMPR1, TIM1_FAST_PWM_INVERT_B
		OUT TCCR1A, TEMPR1
		;	Define TOP=0x3FF In OCR1A For Overflow Flag To Be Set 
		LDI TEMPR1, 0x03
		OUT OCR1AH, TEMPR1
		LDI TEMPR1, 0xFF
		OUT OCR1AL, TEMPR1
		;	Define Initial OCR1B(=TOP=0x3FF) For Compare B Match Flag To Be Set 
		LDI TEMPR1, 0x03
		OUT OCR1BH, TEMPR1
		LDI TEMPR1, 0xFF
		OUT OCR1BL, TEMPR1
		;	Enable Overflow Interrupt
		IN TEMPR1, TIMSK
		SBR TEMPR1, TIM1_INT_OVF
		OUT TIMSK, TEMPR1

		;	Set Delay(Sec) In Timer/Counter 1 Overflow Interrupt Routine 
		;	Between ADC Conversion Results Transfer To 7-Segment Indicators
		;	For Better Human Perception
		LDI TIM1_DELAY, TIM1_DELAY_SEC
			
		;	Enable Global Interrupt
		SEI


;****** Main Program ******
	LOOP:
		NOP
		NOP
		NOP
		NOP
		NOP
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
	;*** Send ADC Conversion Result ***
	ADC_RESULT_SEND:
		SENDING_BEGIN:
			IN ADC_DRL, ADCL
			IN ADC_DRH, ADCH
			
			SBIW ADC_DRH:ADC_DRL, 1
			BRCS RESULT_0
			ADIW ADC_DRH:ADC_DRL, 1
			ADIW ADC_DRH:ADC_DRL, 1
			SBRC ADC_DRH, 4
			RJMP RESULT_100
			RJMP ANY_OTHER_RESULT

			;	Result = 0x000 i.e. 0%
			RESULT_0:
				RCALL SEGMENTS_SLEEP_MODE
				;	Send 1st Digit To 1st Indicator
				LDI OUTPUT_DATA, DIGIT_0
				RCALL SERIAL_TRANSFER

				RJMP SENDING_END

			;	Result = 0x3FF i.e. 100%
			RESULT_100:
				RCALL SEGMENTS_SLEEP_MODE
				;	Send 1st Digit To 3rd Indicator
				LDI OUTPUT_DATA, DIGIT_1
				RCALL SERIAL_TRANSFER
				;	Send 2nd Digit To 2nd Indicator
				LDI OUTPUT_DATA, DIGIT_0
				RCALL SERIAL_TRANSFER
				;	Send 3rd Digit To 1st Indicator
				LDI OUTPUT_DATA, DIGIT_0
				RCALL SERIAL_TRANSFER

				RJMP SENDING_END

			;	Any Other Result 
			ANY_OTHER_RESULT:		
				MOV TEMPR3, ADC_DRH
				
				LDI TEMPR1, 4
				SHIFT_LEFT_x4:
					LSL ADC_DRH
					DEC TEMPR1
					BRNE SHIFT_LEFT_x4
				MOV TEMPR0, ADC_DRH
				MOV TEMPR2, ADC_DRL
				LDI TEMPR1, 4
				SHIFT_RIGHT_x4:
					LSR TEMPR2
					DEC TEMPR1
					BRNE SHIFT_RIGHT_x4
				OR ADC_DRH, TEMPR2
				
				LSR TEMPR2
				LSR TEMPR0
				OR TEMPR2, TEMPR0

				ADD ADC_DRH, TEMPR3
				ADD ADC_DRH, TEMPR2
			
				;	Exclude Max Result
				CPI ADC_DRH, 0x80
				BREQ RESULT_100

				LSL ADC_DRH
				;	Find Result < 100%
					;	0Xxx xxxx
					LSL ADC_DRH
					BRCS DG1_6789
					;	00xx xxxx
					DG1_0123456:
						;	00Xx xxxx
						LSL ADC_DRH
						BRCS DG1_0123456_DG1_3456
						;	000x xxxx
						DG1_0123456_DG1_0123:
							;	000X xxxx
							LSL ADC_DRH
							BRCS DG1_0123456_DG1_0123_DG1_123
							;	0000 xxxx
							DG1_0123456_DG1_0123_DG1_01:
								;	0000 Xxxx
								LSL ADC_DRH
								BRCS DG1_0123456_DG1_0123_DG1_01_DG1_01_DG2_0123456789
								;	0000 0xxx
								DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_01234567:
									;	Store 1st Digit(=0) To Send It Later
									LDI TEMPR2, DIGIT_0

;									;	Store 1st Digit(= NONE) To Send It Later
;									LDI TEMPR2, DIGIT_NONE
;									;	0000 0Xxx
;									LSL ADC_DRH
;									BRCS DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567
;									;	0000 00xx
;									DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_0123:
;										;	Store 2nd Digit(=0) To Send It Later
;										LDI TEMPR3, DIGIT_0
;										RJMP SENDING_END
;
;;										;	0000 00Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_0123_DG2_23
;;										;	0000 000x
;;										DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_0123_DG2_01:
;;											;	0000 000X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_0123_DG2_01_DG2_1
;;											;	0000 0000
;;											DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_0123_DG2_01_DG2_0:
;;												;	Store 2nd Digit(=0) To Send It Later
;;												LDI TEMPR3, DIGIT_0
;;												RJMP SENDING_END
;;											;	0000 0001
;;											DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_0123_DG2_01_DG2_1:
;;												;	Store 2nd Digit(=1) To Send It Later
;;												LDI TEMPR3, DIGIT_1
;;												RJMP SENDING_END
;;										;	0000 001x
;;										DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_0123_DG2_23:
;;											;	0000 001X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_0123_DG2_23_DG2_3
;;											;	0000 0010
;;											DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_0123_DG2_23_DG2_2:
;;												;	Store 2nd Digit(=2) To Send It Later
;;												LDI TEMPR3, DIGIT_2
;;												RJMP SENDING_END
;;											;	0000 0011
;;											DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_0123_DG2_23_DG2_3:
;;												;	Store 2nd Digit(=3) To Send It Later
;;												LDI TEMPR3, DIGIT_3
;;												RJMP SENDING_END
;
;									;	0000 01xx
;									DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567:
;										;	Store 2nd Digit(=4) To Send It Later
;										LDI TEMPR3, DIGIT_4
;										RJMP SENDING_END
;
;;										;	0000 01Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567_DG2_67
;;										;	0000 010x
;;										DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567_DG2_45:
;;											;	0000 010X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567_DG2_45_DG2_5
;;											;	0000 0100
;;											DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567_DG2_45_DG2_4:
;;												;	Store 2nd Digit(=4) To Send It Later
;;												LDI TEMPR3, DIGIT_4
;;												RJMP SENDING_END
;;											;	0000 0101
;;											DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567_DG2_45_DG2_5:
;;												;	Store 2nd Digit(=5) To Send It Later
;;												LDI TEMPR3, DIGIT_5
;;												RJMP SENDING_END
;;										;	0000 011x
;;										DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567_DG2_67:
;;											;	0000 011X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567_DG2_67_DG2_7
;;											;	0000 0110
;;											DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567_DG2_67_DG2_6:
;;												;	Store 2nd Digit(=6) To Send It Later
;;												LDI TEMPR3, DIGIT_6
;;												RJMP SENDING_END
;;											;	0000 0111
;;											DG1_0123456_DG1_0123_DG1_01_DG1_0_DG2_4567_DG2_67_DG2_7:
;;												;	Store 2nd Digit(=7) To Send It Later
;;												LDI TEMPR3, DIGIT_7
;;												RJMP SENDING_END
																						
								;	0000 1xxx
								DG1_0123456_DG1_0123_DG1_01_DG1_01_DG2_0123456789:
									;	Store 1st Digit(= NONE) To Send It Later
									LDI TEMPR2, DIGIT_NONE
									;	Store 2nd Digit(=8) To Send It Later
									LDI TEMPR3, DIGIT_8
									RJMP SENDING_END

;									;	0000 1Xxx
;									LSL ADC_DRH
;									BRCS DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345
;									;	0000 10xx
;									DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_0_DG2_016789:
;										;	Store 2nd Digit(=8) To Send It Later
;										LDI TEMPR3, DIGIT_8
;										RJMP SENDING_END
;
;;										;	0000 10Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_01_DG1_1_DG2_016789_DG2_01
;;										;	0000 100x
;;										DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_01_DG1_0_DG2_016789_DG2_89:
;;											;	Store 1st Digit(= NONE) To Send It Later
;;											LDI TEMPR2, DIGIT_NONE
;;											;	0000 100X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_0_DG2_016789_DG2_89_DG2_9
;;											;	0000 1000
;;											DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_0_DG2_016789_DG2_89_DG2_8:
;;												;	Store 2nd Digit(=8) To Send It Later
;;												LDI TEMPR3, DIGIT_8
;;												RJMP SENDING_END
;;											;	0000 1001
;;											DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_0_DG2_016789_DG2_89_DG2_9:
;;												;	Store 2nd Digit(=9) To Send It Later
;;												LDI TEMPR3, DIGIT_9
;;												RJMP SENDING_END
;;										;	0000 101x
;;										DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_01_DG1_1_DG2_016789_DG2_01:
;;											;	Store 1st Digit(= 1) To Send It Later
;;											LDI TEMPR2, DIGIT_1
;;											;	0000 101X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_01_DG1_1_DG2_016789_DG2_01_DG2_1
;;											;	0000 1010
;;											DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_01_DG1_1_DG2_016789_DG2_01_DG2_0:
;;												;	Store 2nd Digit(=0) To Send It Later
;;												LDI TEMPR3, DIGIT_0
;;												RJMP SENDING_END
;;											;	0000 1011
;;											DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_01_DG1_1_DG2_016789_DG2_01_DG2_1:
;;												;	Store 2nd Digit(=1) To Send It Later
;;												LDI TEMPR3, DIGIT_1
;;												RJMP SENDING_END
;
;									;	0000 11xx
;									DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345:
;										;	Store 1st Digit(= 1) To Send It Later
;										LDI TEMPR2, DIGIT_1
;										;	Store 2nd Digit(=2) To Send It Later
;										LDI TEMPR3, DIGIT_2
;										RJMP SENDING_END
;
;;										;	0000 11Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345_DG2_45
;;										;	0000 110x
;;										DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345_DG2_23:
;;											;	0000 110X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345_DG2_23_DG2_3
;;											;	0000 1100
;;											DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345_DG2_23_DG2_2:
;;												;	Store 2nd Digit(=2) To Send It Later
;;												LDI TEMPR3, DIGIT_2
;;												RJMP SENDING_END
;;											;	0000 1101
;;											DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345_DG2_23_DG2_3:
;;												;	Store 2nd Digit(=3) To Send It Later
;;												LDI TEMPR3, DIGIT_3
;;												RJMP SENDING_END
;;										;	0000 111x
;;										DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345_DG2_45:
;;											;	0000 111X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345_DG2_45_DG2_5
;;											;	0000 1110
;;											DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345_DG2_45_DG2_4:
;;												;	Store 2nd Digit(=4) To Send It Later
;;												LDI TEMPR3, DIGIT_4
;;												RJMP SENDING_END
;;											;	0000 1111
;;											DG1_0123456_DG1_0123_DG1_01_DG1_01_DG1_1_DG2_2345_DG2_45_DG2_5:
;;												;	Store 2nd Digit(=5) To Send It Later
;;												LDI TEMPR3, DIGIT_5
;;												RJMP SENDING_END

							;	0001 xxxx
							DG1_0123456_DG1_0123_DG1_123:
								;	0001 Xxxx
								LSL ADC_DRH
								BRCS DG1_0123456_DG1_0123_DG1_123_DG1_23
								;	0001 0xxx
								DG1_0123456_DG1_0123_DG1_123_DG1_12:
									;	Store 1st Digit(= 1) To Send It Later
									LDI TEMPR2, DIGIT_1
									;	Store 2nd Digit(=6) To Send It Later
									LDI TEMPR3, DIGIT_6
									RJMP SENDING_END

;									;	0001 0Xxx
;									LSL ADC_DRH
;									BRCS DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2
;									;	0001 00xx
;									DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_1:
;										;	Store 1st Digit(= 1) To Send It Later
;										LDI TEMPR2, DIGIT_1
;										;	Store 2nd Digit(=6) To Send It Later
;										LDI TEMPR3, DIGIT_6
;										RJMP SENDING_END
;
;;										;	0001 00Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_1_DG2_89
;;										;	0001 000x
;;										DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_1_DG2_67:
;;											;	0001 000X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_1_DG2_67_DG2_7
;;											;	0001 0000
;;											DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_1_DG2_67_DG2_6:
;;												;	Store 2nd Digit(=6) To Send It Later
;;												LDI TEMPR3, DIGIT_6
;;												RJMP SENDING_END
;;											;	0001 0001
;;											DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_1_DG2_67_DG2_7:
;;												;	Store 2nd Digit(=7) To Send It Later
;;												LDI TEMPR3, DIGIT_7
;;												RJMP SENDING_END
;;										;	0001 001x
;;										DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_1_DG2_89:
;;											;	0001 001X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_1_DG2_89_DG2_9
;;											;	0001 0010
;;											DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_1_DG2_89_DG2_8:
;;												;	Store 2nd Digit(=8) To Send It Later
;;												LDI TEMPR3, DIGIT_8
;;												RJMP SENDING_END
;;											;	0001 0011
;;											DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_1_DG2_89_DG2_9:
;;												;	Store 2nd Digit(=9) To Send It Later
;;												LDI TEMPR3, DIGIT_9
;;												RJMP SENDING_END
;
;									;	0001 01xx
;									DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2:
;										;	Store 1st Digit(= 2) To Send It Later
;										LDI TEMPR2, DIGIT_2
;										;	Store 2nd Digit(=0) To Send It Later
;										LDI TEMPR3, DIGIT_0
;										RJMP SENDING_END
;
;;										;	0001 01Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2_DG2_23
;;										;	0001 010x
;;										DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2_DG2_01:
;;											;	0001 010X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2_DG2_01_DG2_1
;;											;	0001 0100
;;											DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2_DG2_01_DG2_0:
;;												;	Store 2nd Digit(=0) To Send It Later
;;												LDI TEMPR3, DIGIT_0
;;												RJMP SENDING_END
;;											;	0001 0101
;;											DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2_DG2_01_DG2_1:
;;												;	Store 2nd Digit(=1) To Send It Later
;;												LDI TEMPR3, DIGIT_1
;;												RJMP SENDING_END
;;										;	0001 011x
;;										DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2_DG2_23:
;;											;	0001 011X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2_DG2_23_DG2_3
;;											;	0001 0110
;;											DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2_DG2_23_DG2_2:
;;												;	Store 2nd Digit(=2) To Send It Later
;;												LDI TEMPR3, DIGIT_2
;;												RJMP SENDING_END
;;											;	0001 0111
;;											DG1_0123456_DG1_0123_DG1_123_DG1_12_DG1_2_DG2_23_DG2_3:
;;												;	Store 2nd Digit(=3) To Send It Later
;;												LDI TEMPR3, DIGIT_3
;;												RJMP SENDING_END
																									
								;	0001 1xxx
								DG1_0123456_DG1_0123_DG1_123_DG1_23:
									;	Store 1st Digit(= 2) To Send It Later
									LDI TEMPR2, DIGIT_2
									;	Store 2nd Digit(=4) To Send It Later
									LDI TEMPR3, DIGIT_4
									RJMP SENDING_END

;									;	0001 1Xxx
;									LSL ADC_DRH
;									BRCS DG1_0123456_DG1_0123_DG1_123_DG1_23_DG2_0189
;									;	0001 10xx
;									DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_23_DG2_4567:
;										;	Store 1st Digit(= 2) To Send It Later
;										LDI TEMPR2, DIGIT_2
;										;	Store 2nd Digit(=4) To Send It Later
;										LDI TEMPR3, DIGIT_4
;										RJMP SENDING_END
;
;;										;	0001 10Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_23_DG2_4567_DG2_67
;;										;	0001 100x
;;										DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_23_DG2_4567_DG2_45:
;;											;	0001 100X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_23_DG2_4567_DG2_45_DG2_5
;;											;	0001 1000
;;											DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_23_DG2_4567_DG2_45_DG2_4:
;;												;	Store 2nd Digit(=4) To Send It Later
;;												LDI TEMPR3, DIGIT_4
;;												RJMP SENDING_END
;;											;	0001 1001
;;											DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_23_DG2_4567_DG2_45_DG2_5:
;;												;	Store 2nd Digit(=5) To Send It Later
;;												LDI TEMPR3, DIGIT_5
;;												RJMP SENDING_END
;;										;	0001 101x
;;										DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_23_DG2_4567_DG2_67:
;;											;	0001 101X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_23_DG2_4567_DG2_67_DG2_7
;;											;	0001 1010
;;											DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_23_DG2_4567_DG2_67_DG2_6:
;;												;	Store 2nd Digit(=6) To Send It Later
;;												LDI TEMPR3, DIGIT_6
;;												RJMP SENDING_END
;;											;	0001 1011
;;											DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_23_DG2_4567_DG2_67_DG2_7:
;;												;	Store 2nd Digit(=7) To Send It Later
;;												LDI TEMPR3, DIGIT_7
;;												RJMP SENDING_END
;
;									;	0001 11xx
;									DG1_0123456_DG1_0123_DG1_123_DG1_23_DG2_0189:
;										;	Store 1st Digit(= 2) To Send It Later
;										LDI TEMPR2, DIGIT_2
;										;	Store 2nd Digit(=8) To Send It Later
;										LDI TEMPR3, DIGIT_8
;										RJMP SENDING_END
;
;;										;	0001 11Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_3_DG2_0189_DG2_01
;;										;	0001 110x
;;										DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_2_DG2_0189_DG2_89:
;;											;	Store 1st Digit(= 2) To Send It Later
;;											LDI TEMPR2, DIGIT_2
;;											;	0001 110X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_2_DG2_0189_DG2_89_DG2_9
;;											;	0001 1100
;;											DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_2_DG2_0189_DG2_89_DG2_8:
;;												;	Store 2nd Digit(=8) To Send It Later
;;												LDI TEMPR3, DIGIT_8
;;												RJMP SENDING_END
;;											;	0001 1101
;;											DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_2_DG2_0189_DG2_89_DG2_9:
;;												;	Store 2nd Digit(=9) To Send It Later
;;												LDI TEMPR3, DIGIT_9
;;												RJMP SENDING_END
;;										;	0001 111x
;;										DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_3_DG2_0189_DG2_01:
;;											;	Store 1st Digit(= 3) To Send It Later
;;											LDI TEMPR2, DIGIT_3
;;											;	0001 111X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_3_DG2_0189_DG2_01_DG2_1
;;											;	0001 1110
;;											DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_3_DG2_0189_DG2_01_DG2_0:
;;												;	Store 2nd Digit(=0) To Send It Later
;;												LDI TEMPR3, DIGIT_0
;;												RJMP SENDING_END
;;											;	0001 1111
;;											DG1_0123456_DG1_0123_DG1_123_DG1_23_DG1_3_DG2_0189_DG2_01_DG2_1:
;;												;	Store 2nd Digit(=1) To Send It Later
;;												LDI TEMPR3, DIGIT_1
;;												RJMP SENDING_END

						;	001x xxxx
						DG1_0123456_DG1_3456:
							;	001X xxxx
							LSL ADC_DRH
							BRCS DG1_0123456_DG1_3456_DG1_456
							;	0010 xxxx
							DG1_0123456_DG1_3456_DG1_34:
								;	0010 Xxxx
								LSL ADC_DRH
								BRCS DG1_0123456_DG1_3456_DG1_34_DG1_4
								;	0010 0xxx
								DG1_0123456_DG1_3456_DG1_34_DG1_3:
									;	Store 1st Digit(= 3) To Send It Later
									LDI TEMPR2, DIGIT_3
									;	Store 2nd Digit(=2) To Send It Later
									LDI TEMPR3, DIGIT_2
									RJMP SENDING_END

;									;	0010 0Xxx
;									LSL ADC_DRH
;									BRCS DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789
;									;	0010 00xx
;									DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_2345:
;										;	Store 2nd Digit(=2) To Send It Later
;										LDI TEMPR3, DIGIT_2
;										RJMP SENDING_END
;
;;										;	0010 00Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_2345_DG2_45
;;										;	0010 000x
;;										DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_2345_DG2_23:
;;											;	0010 000X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_2345_DG2_23_DG2_3
;;											;	0010 0000
;;											DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_2345_DG2_23_DG2_2:
;;												;	Store 2nd Digit(=2) To Send It Later
;;												LDI TEMPR3, DIGIT_2
;;												RJMP SENDING_END
;;											;	0010 0001
;;											DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_2345_DG2_23_DG2_3:
;;												;	Store 2nd Digit(=3) To Send It Later
;;												LDI TEMPR3, DIGIT_3
;;												RJMP SENDING_END
;;										;	0010 001x
;;										DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_2345_DG2_45:
;;											;	0010 001X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_2345_DG2_45_DG2_5
;;											;	0010 0010
;;											DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_2345_DG2_45_DG2_4:
;;												;	Store 2nd Digit(=4) To Send It Later
;;												LDI TEMPR3, DIGIT_4
;;												RJMP SENDING_END
;;											;	0010 0011
;;											DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_2345_DG2_45_DG2_5:
;;												;	Store 2nd Digit(=5) To Send It Later
;;												LDI TEMPR3, DIGIT_5
;;												RJMP SENDING_END
;
;									;	0010 01xx
;									DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789:
;										;	Store 2nd Digit(=6) To Send It Later
;										LDI TEMPR3, DIGIT_6
;										RJMP SENDING_END
;
;;										;	0010 01Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789_DG2_89
;;										;	0010 010x
;;										DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789_DG2_67:
;;											;	0010 010X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789_DG2_67_DG2_7
;;											;	0010 0100
;;											DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789_DG2_67_DG2_6:
;;												;	Store 2nd Digit(=6) To Send It Later
;;												LDI TEMPR3, DIGIT_6
;;												RJMP SENDING_END
;;											;	0010 0101
;;											DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789_DG2_67_DG2_7:
;;												;	Store 2nd Digit(=7) To Send It Later
;;												LDI TEMPR3, DIGIT_7
;;												RJMP SENDING_END
;;										;	0010 011x
;;										DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789_DG2_89:
;;											;	0010 011X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789_DG2_89_DG2_9
;;											;	0010 0110
;;											DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789_DG2_89_DG2_8:
;;												;	Store 2nd Digit(=8) To Send It Later
;;												LDI TEMPR3, DIGIT_8
;;												RJMP SENDING_END
;;											;	0010 0111
;;											DG1_0123456_DG1_3456_DG1_34_DG1_3_DG2_6789_DG2_89_DG2_9:
;;												;	Store 2nd Digit(=9) To Send It Later
;;												LDI TEMPR3, DIGIT_9
;;												RJMP SENDING_END
;;																						
								;	0010 1xxx
								DG1_0123456_DG1_3456_DG1_34_DG1_4:
									;	Store 1st Digit(= 4) To Send It Later
									LDI TEMPR2, DIGIT_4
									LDI TEMPR3, DIGIT_0
									RJMP SENDING_END

;									;	0010 1Xxx
;									LSL ADC_DRH
;									BRCS DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567
;									;	0010 10xx
;									DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_0123:
;										;	Store 2nd Digit(=0) To Send It Later
;										LDI TEMPR3, DIGIT_0
;										RJMP SENDING_END
;
;;										;	0010 10Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_0123_DG2_23
;;										;	0010 100x
;;										DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_0123_DG2_01:
;;											;	0010 100X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_0123_DG2_01_DG2_1
;;											;	0010 1000
;;											DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_0123_DG2_01_DG2_0:
;;												;	Store 2nd Digit(=0) To Send It Later
;;												LDI TEMPR3, DIGIT_0
;;												RJMP SENDING_END
;;											;	0010 1001
;;											DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_0123_DG2_01_DG2_1:
;;												;	Store 2nd Digit(=1) To Send It Later
;;												LDI TEMPR3, DIGIT_1
;;												RJMP SENDING_END
;;										;	0010 101x
;;										DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_0123_DG2_23:
;;											;	0010 101X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_0123_DG2_23_DG2_3
;;											;	0010 1010
;;											DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_0123_DG2_23_DG2_2:
;;												;	Store 2nd Digit(=2) To Send It Later
;;												LDI TEMPR3, DIGIT_2
;;												RJMP SENDING_END
;;											;	0010 1011
;;											DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_0123_DG2_23_DG2_3:
;;												;	Store 2nd Digit(=3) To Send It Later
;;												LDI TEMPR3, DIGIT_3
;;												RJMP SENDING_END
;;
;;									;	0010 11xx
;									DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567:
;										;	Store 2nd Digit(=4) To Send It Later
;										LDI TEMPR3, DIGIT_4
;										RJMP SENDING_END
;
;;										;	0010 11Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567_DG2_67
;;										;	0010 110x
;;										DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567_DG2_45:
;;											;	0010 110X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567_DG2_45_DG2_5
;;											;	0010 1100
;;											DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567_DG2_45_DG2_4:
;;												;	Store 2nd Digit(=4) To Send It Later
;;												LDI TEMPR3, DIGIT_4
;;												RJMP SENDING_END
;;											;	0010 1101
;;											DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567_DG2_45_DG2_5:
;;												;	Store 2nd Digit(=5) To Send It Later
;;												LDI TEMPR3, DIGIT_5
;;												RJMP SENDING_END
;;										;	0010 111x
;;										DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567_DG2_67:
;;											;	0010 111X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567_DG2_67_DG2_7
;;											;	0010 1110
;;											DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567_DG2_67_DG2_6:
;;												;	Store 2nd Digit(=6) To Send It Later
;;												LDI TEMPR3, DIGIT_6
;;												RJMP SENDING_END
;;											;	0010 1111
;;											DG1_0123456_DG1_3456_DG1_34_DG1_4_DG2_4567_DG2_67_DG2_7:
;;												;	Store 2nd Digit(=7) To Send It Later
;;												LDI TEMPR3, DIGIT_7
;;												RJMP SENDING_END

							;	0011 xxxx
							DG1_0123456_DG1_3456_DG1_456:
								;	0011 Xxxx
								LSL ADC_DRH
								BRCS DG1_0123456_DG1_3456_DG1_456_DG1_56
								;	0011 0xxx
								DG1_0123456_DG1_3456_DG1_456_DG1_45:
									;	Store 1st Digit(=4) To Send It Later
									LDI TEMPR2, DIGIT_4
									;	Store 2nd Digit(=8) To Send It Later
									LDI TEMPR3, DIGIT_8
									RJMP SENDING_END

;									;	0011 0Xxx
;									LSL ADC_DRH
;									BRCS DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5
;									;	0011 00xx
;									DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_45:
;										;	Store 1st Digit(=4) To Send It Later
;										LDI TEMPR2, DIGIT_4
;										;	Store 2nd Digit(=8) To Send It Later
;										LDI TEMPR3, DIGIT_8
;										RJMP SENDING_END
;
;;										;	0011 00Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_45_DG1_5
;;										;	0011 000x
;;										DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_45_DG1_4:
;;											;	Store 1st Digit(=4) To Send It Later
;;											LDI TEMPR2, DIGIT_4
;;											;	0011 000X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_45_DG1_4_DG2_9
;;											;	0011 0000
;;											DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_45_DG1_4_DG2_8:
;;												;	Store 2nd Digit(=8) To Send It Later
;;												LDI TEMPR3, DIGIT_8
;;												RJMP SENDING_END
;;											;	0011 0001
;;											DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_45_DG1_4_DG2_9:
;;												;	Store 2nd Digit(=9) To Send It Later
;;												LDI TEMPR3, DIGIT_9
;;												RJMP SENDING_END
;;										;	0011 001x
;;										DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_45_DG1_5:
;;											;	Store 1st Digit(=5) To Send It Later
;;											LDI TEMPR2, DIGIT_5
;;											;	0011 001X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_45_DG1_5_DG2_1
;;											;	0011 0010
;;											DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_45_DG1_5_DG2_0:
;;												;	Store 2nd Digit(=0) To Send It Later
;;												LDI TEMPR3, DIGIT_0
;;												RJMP SENDING_END
;;											;	0011 0011
;;											DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_45_DG1_5_DG2_1:
;;												;	Store 2nd Digit(=1) To Send It Later
;;												LDI TEMPR3, DIGIT_1
;;												RJMP SENDING_END
;
;									;	0011 01xx
;									DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5:
;										;	Store 1st Digit(=5) To Send It Later
;										LDI TEMPR2, DIGIT_5
;										;	Store 2nd Digit(=2) To Send It Later
;										LDI TEMPR3, DIGIT_2
;										RJMP SENDING_END
;
;;										;	0011 01Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5_DG2_45
;;										;	0011 010x
;;										DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5_DG2_23:
;;											;	0011 010X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5_DG2_23_DG2_3
;;											;	0011 0100
;;											DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5_DG2_23_DG2_2:
;;												;	Store 2nd Digit(=2) To Send It Later
;;												LDI TEMPR3, DIGIT_2
;;												RJMP SENDING_END
;;											;	0011 0101
;;											DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5_DG2_23_DG2_3:
;;												;	Store 2nd Digit(=3) To Send It Later
;;												LDI TEMPR3, DIGIT_3
;;												RJMP SENDING_END
;;										;	0011 011x
;;										DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5_DG2_45:
;;											;	0011 011X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5_DG2_45_DG2_5
;;											;	0011 0110
;;											DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5_DG2_45_DG2_4:
;;												;	Store 2nd Digit(=4) To Send It Later
;;												LDI TEMPR3, DIGIT_4
;;												RJMP SENDING_END
;;											;	0011 0111
;;											DG1_0123456_DG1_3456_DG1_456_DG1_45_DG1_5_DG2_45_DG2_5:
;;												;	Store 2nd Digit(=5) To Send It Later
;;												LDI TEMPR3, DIGIT_5
;;												RJMP SENDING_END
																									
								;	0011 1xxx
								DG1_0123456_DG1_3456_DG1_456_DG1_56:
									;	Store 1st Digit(=5) To Send It Later
									LDI TEMPR2, DIGIT_5
									;	Store 2nd Digit(=6) To Send It Later
									LDI TEMPR3, DIGIT_6
									RJMP SENDING_END

;									;	0011 1Xxx
;									LSL ADC_DRH
;									BRCS DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6
;									;	0011 10xx
;									DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_5:
;										;	Store 1st Digit(=5) To Send It Later
;										LDI TEMPR2, DIGIT_5
;										;	Store 2nd Digit(=6) To Send It Later
;										LDI TEMPR3, DIGIT_6
;										RJMP SENDING_END
;
;;										;	0011 10Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_5_DG2_89
;;										;	0011 100x
;;										DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_5_DG2_67:
;;											;	0011 100X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_5_DG2_67_DG2_7
;;											;	0011 1000
;;											DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_5_DG2_67_DG2_6:
;;												;	Store 2nd Digit(=6) To Send It Later
;;												LDI TEMPR3, DIGIT_6
;;												RJMP SENDING_END
;;											;	0011 1001
;;											DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_5_DG2_67_DG2_7:
;;												;	Store 2nd Digit(=7) To Send It Later
;;												LDI TEMPR3, DIGIT_7
;;												RJMP SENDING_END
;;										;	0011 101x
;;										DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_5_DG2_89:
;;											;	0011 101X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_5_DG2_89_DG2_9
;;											;	0011 1010
;;											DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_5_DG2_89_DG2_8:
;;												;	Store 2nd Digit(=8) To Send It Later
;;												LDI TEMPR3, DIGIT_8
;;												RJMP SENDING_END
;;											;	0011 1011
;;											DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_5_DG2_89_DG2_9:
;;												;	Store 2nd Digit(=9) To Send It Later
;;												LDI TEMPR3, DIGIT_9
;;												RJMP SENDING_END
;
;									;	0011 11xx
;									DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6:
;										;	Store 1st Digit(= 6) To Send It Later
;										LDI TEMPR2, DIGIT_6
;										;	Store 2nd Digit(=0) To Send It Later
;										LDI TEMPR3, DIGIT_0
;										RJMP SENDING_END
;
;;										;	0011 11Xx
;;										LSL ADC_DRH
;;										BRCS DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6_DG2_23
;;										;	0011 110x
;;										DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6_DG2_01:
;;											;	Store 1st Digit(= 8) To Send It Later
;;											LDI TEMPR2, DIGIT_8
;;											;	0011 110X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6_DG2_01_DG2_1
;;											;	0011 1100
;;											DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6_DG2_01_DG2_0:
;;												;	Store 2nd Digit(=0) To Send It Later
;;												LDI TEMPR3, DIGIT_0
;;												RJMP SENDING_END
;;											;	0011 1101
;;											DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6_DG2_01_DG2_1:
;;												;	Store 2nd Digit(=1) To Send It Later
;;												LDI TEMPR3, DIGIT_1
;;												RJMP SENDING_END
;;										;	0011 111x
;;										DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6_DG2_23:
;;											;	0011 111X
;;											LSL ADC_DRH
;;											BRCS DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6_DG2_23_DG2_3
;;											;	0011 1110
;;											DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6_DG2_23_DG2_2:
;;												;	Store 2nd Digit(=2) To Send It Later
;;												LDI TEMPR3, DIGIT_2
;;												RJMP SENDING_END
;;											;	0011 1111
;;											DG1_0123456_DG1_3456_DG1_456_DG1_56_DG1_6_DG2_23_DG2_3:
;;												;	Store 2nd Digit(=3) To Send It Later
;;												LDI TEMPR3, DIGIT_3
;;												RJMP SENDING_END

					;	01xx xxxx
					DG1_6789:
						;	01Xx xxxx
						LSL ADC_DRH
						BRCS DG1_6789_DG1_9
						;	010x xxxx
						DG1_6789_DG1_6789:
							;	010X xxxx
							LSL ADC_DRH
							BRCS DG1_6789_DG1_6789_DG1_89
							;	0100 xxxx
							DG1_6789_DG1_6789_DG1_67:
								;	0100 Xxxx
								LSL ADC_DRH
								BRCS DG1_6789_DG1_6789_DG1_67_DG1_7
								;	0100 0xxx
								DG1_6789_DG1_6789_DG1_67_DG1_67:
										;	Store 1st Digit(=6) To Send It Later
										LDI TEMPR2, DIGIT_6
										;	Store 2nd Digit(=4) To Send It Later
										LDI TEMPR3, DIGIT_4
										RJMP SENDING_END

;									;	0100 0Xxx
;									LSL ADC_DRH
;									BRCS DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67
;									;	0100 00xx
;									DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_6:
;										;	Store 1st Digit(=6) To Send It Later
;										LDI TEMPR2, DIGIT_6
;										;	Store 2nd Digit(=4) To Send It Later
;										LDI TEMPR3, DIGIT_4
;										RJMP SENDING_END
;
;;										;	0100 00Xx
;;										LSL ADC_DRH
;;										BRCS DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_6_DG2_67
;;										;	0100 000x
;;										DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_6_DG2_45:
;;											;	0100 000X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_6_DG2_45_DG2_5
;;											;	0100 0000
;;											DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_6_DG2_45_DG2_4:
;;												;	Store 2nd Digit(=4) To Send It Later
;;												LDI TEMPR3, DIGIT_4
;;												RJMP SENDING_END
;;											;	0100 0001
;;											DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_6_DG2_45_DG2_5:
;;												;	Store 2nd Digit(=5) To Send It Later
;;												LDI TEMPR3, DIGIT_5
;;												RJMP SENDING_END
;;										;	0100 001x
;;										DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_6_DG2_67:
;;											;	0100 001X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_6_DG2_67_DG2_7
;;											;	0100 0010
;;											DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_6_DG2_67_DG2_6:
;;												;	Store 2nd Digit(=7) To Send It Later
;;												LDI TEMPR3, DIGIT_7
;;												RJMP SENDING_END
;;											;	0100 0011
;;											DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_6_DG2_67_DG2_7:
;;												;	Store 2nd Digit(=7) To Send It Later
;;												LDI TEMPR3, DIGIT_7
;;												RJMP SENDING_END
;
;									;	0100 01xx
;									DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67:
;										;	Store 1st Digit(=6) To Send It Later
;										LDI TEMPR2, DIGIT_6
;										;	Store 2nd Digit(=8) To Send It Later
;										LDI TEMPR3, DIGIT_8
;										RJMP SENDING_END
;
;;										;	0100 01Xx
;;										LSL ADC_DRH
;;										BRCS DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67_DG1_7
;;										;	0100 010x
;;										DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67_DG1_6:
;;											;	Store 1st Digit(=6) To Send It Later
;;											LDI TEMPR2, DIGIT_6
;;											;	0100 010X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67_DG1_6_DG2_9
;;											;	0100 0100
;;											DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67_DG1_6_DG2_8:
;;												;	Store 2nd Digit(=8) To Send It Later
;;												LDI TEMPR3, DIGIT_8
;;												RJMP SENDING_END
;;											;	0100 0101
;;											DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67_DG1_6_DG2_9:
;;												;	Store 2nd Digit(=9) To Send It Later
;;												LDI TEMPR3, DIGIT_9
;;												RJMP SENDING_END
;;										;	0100 011x
;;										DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67_DG1_7:
;;											;	Store 1st Digit(=7) To Send It Later
;;											LDI TEMPR2, DIGIT_7
;;											;	0100 011X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67_DG1_7_DG2_1
;;											;	0100 0110
;;											DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67_DG1_7_DG2_0:
;;												;	Store 2nd Digit(=0) To Send It Later
;;												LDI TEMPR3, DIGIT_0
;;												RJMP SENDING_END
;;											;	0100 0111
;;											DG1_6789_DG1_6789_DG1_67_DG1_67_DG1_67_DG1_7_DG2_1:
;;												;	Store 2nd Digit(=1) To Send It Later
;;												LDI TEMPR3, DIGIT_1
;;												RJMP SENDING_END
																						
								;	0100 1xxx
								DG1_6789_DG1_6789_DG1_67_DG1_7:
									;	Store 1st Digit(=7) To Send It Later
									LDI TEMPR2, DIGIT_7
									;	Store 2nd Digit(=2) To Send It Later
									LDI TEMPR3, DIGIT_2
									RJMP SENDING_END

;									;	0100 1Xxx
;									LSL ADC_DRH
;									BRCS DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789
;									;	0100 10xx
;									DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_2345:
;										;	Store 2nd Digit(=2) To Send It Later
;										LDI TEMPR3, DIGIT_2
;										RJMP SENDING_END
;
;;										;	0100 10Xx
;;										LSL ADC_DRH
;;										BRCS DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_2345_DG2_45
;;										;	0100 100x
;;										DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_2345_DG2_23:
;;											;	0100 100X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_2345_DG2_23_DG2_3
;;											;	0100 1000
;;											DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_2345_DG2_23_DG2_2:
;;												;	Store 2nd Digit(=2) To Send It Later
;;												LDI TEMPR3, DIGIT_2
;;												RJMP SENDING_END
;;											;	0100 1001
;;											DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_2345_DG2_23_DG2_3:
;;												;	Store 2nd Digit(=3) To Send It Later
;;												LDI TEMPR3, DIGIT_3
;;												RJMP SENDING_END
;;										;	0100 101x
;;										DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_2345_DG2_45:
;;											;	0100 101X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_2345_DG2_45_DG2_5
;;											;	0100 1010
;;											DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_2345_DG2_45_DG2_4:
;;												;	Store 2nd Digit(=4) To Send It Later
;;												LDI TEMPR3, DIGIT_4
;;												RJMP SENDING_END
;;											;	0100 1011
;;											DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_2345_DG2_45_DG2_5:
;;												;	Store 2nd Digit(=5) To Send It Later
;;												LDI TEMPR3, DIGIT_5
;;												RJMP SENDING_END
;
;									;	0100 11xx
;									DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789:
;										;	Store 2nd Digit(=6) To Send It Later
;										LDI TEMPR3, DIGIT_6
;										RJMP SENDING_END
;
;;										;	0100 11Xx
;;										LSL ADC_DRH
;;										BRCS DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789_DG2_89
;;										;	0100 110x
;;										DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789_DG2_67:
;;											;	0100 110X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789_DG2_67_DG2_7
;;											;	0100 1100
;;											DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789_DG2_67_DG2_6:
;;												;	Store 2nd Digit(=6) To Send It Later
;;												LDI TEMPR3, DIGIT_6
;;												RJMP SENDING_END
;;											;	0100 1101
;;											DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789_DG2_67_DG2_7:
;;												;	Store 2nd Digit(=7) To Send It Later
;;												LDI TEMPR3, DIGIT_7
;;												RJMP SENDING_END
;;										;	0100 111x
;;										DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789_DG2_89:
;;											;	0100 111X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789_DG2_89_DG2_9
;;											;	0100 1110
;;											DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789_DG2_89_DG2_8:
;;												;	Store 2nd Digit(=8) To Send It Later
;;												LDI TEMPR3, DIGIT_8
;;												RJMP SENDING_END
;;											;	0100 1111
;;											DG1_6789_DG1_6789_DG1_67_DG1_7_DG2_6789_DG2_89_DG2_9:
;;												;	Store 2nd Digit(=9) To Send It Later
;;												LDI TEMPR3, DIGIT_9
;;												RJMP SENDING_END

							;	0101 xxxx
							DG1_6789_DG1_6789_DG1_89:
								;	0101 Xxxx
								LSL ADC_DRH
								BRCS DG1_6789_DG1_6789_DG1_89_DG1_89
								;	0101 0xxx
								DG1_6789_DG1_6789_DG1_89_DG1_8:
									;	Store 1st Digit(=8) To Send It Later
									LDI TEMPR2, DIGIT_8
									;	Store 2nd Digit(=0) To Send It Later
									LDI TEMPR3, DIGIT_0
									RJMP SENDING_END

;									;	0101 0Xxx
;									LSL ADC_DRH
;									BRCS DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567
;									;	0101 00xx
;									DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_0123:
;										;	Store 2nd Digit(=0) To Send It Later
;										LDI TEMPR3, DIGIT_0
;										RJMP SENDING_END
;
;;										;	0101 00Xx
;;										LSL ADC_DRH
;;										BRCS DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_0123_DG2_23
;;										;	0101 000x
;;										DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_0123_DG2_01:
;;											;	0101 000X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_0123_DG2_01_DG2_1
;;											;	0101 0000
;;											DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_0123_DG2_01_DG2_0:
;;												;	Store 2nd Digit(=0) To Send It Later
;;												LDI TEMPR3, DIGIT_0
;;												RJMP SENDING_END
;;											;	0101 0001
;;											DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_0123_DG2_01_DG2_1:
;;												;	Store 2nd Digit(=1) To Send It Later
;;												LDI TEMPR3, DIGIT_1
;;												RJMP SENDING_END
;;										;	0101 001x
;;										DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_0123_DG2_23:
;;											;	0101 001X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_0123_DG2_23_DG2_3
;;											;	0101 0010
;;											DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_0123_DG2_23_DG2_2:
;;												;	Store 2nd Digit(=2) To Send It Later
;;												LDI TEMPR3, DIGIT_2
;;												RJMP SENDING_END
;;											;	0101 0011
;;											DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_0123_DG2_23_DG2_3:
;;												;	Store 2nd Digit(=3) To Send It Later
;;												LDI TEMPR3, DIGIT_3
;;												RJMP SENDING_END
;
;									;	0101 01xx
;									DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567:
;										;	Store 2nd Digit(=4) To Send It Later
;										LDI TEMPR3, DIGIT_4
;										RJMP SENDING_END
;
;;										;	0101 01Xx
;;										LSL ADC_DRH
;;										BRCS DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567_DG2_67
;;										;	0101 010x
;;										DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567_DG2_45:
;;											;	0101 010X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567_DG2_45_DG2_5
;;											;	0101 0100
;;											DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567_DG2_45_DG2_4:
;;												;	Store 2nd Digit(=4) To Send It Later
;;												LDI TEMPR3, DIGIT_4
;;												RJMP SENDING_END
;;											;	0101 0101
;;											DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567_DG2_45_DG2_5:
;;												;	Store 2nd Digit(=5) To Send It Later
;;												LDI TEMPR3, DIGIT_5
;;												RJMP SENDING_END
;;										;	0101 011x
;;										DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567_DG2_67:
;;											;	0101 011X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567_DG2_67_DG2_7
;;											;	0101 0110
;;											DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567_DG2_67_DG2_6:
;;												;	Store 2nd Digit(=6) To Send It Later
;;												LDI TEMPR3, DIGIT_6
;;												RJMP SENDING_END
;;											;	0101 0111
;;											DG1_6789_DG1_6789_DG1_89_DG1_8_DG2_4567_DG2_67_DG2_7:
;;												;	Store 2nd Digit(=7) To Send It Later
;;												LDI TEMPR3, DIGIT_7
;;												RJMP SENDING_END
																									
								;	0101 1xxx
								DG1_6789_DG1_6789_DG1_89_DG1_89:
									;	Store 1st Digit(=8) To Send It Later
									LDI TEMPR2, DIGIT_8
									;	Store 2nd Digit(=8) To Send It Later
									LDI TEMPR3, DIGIT_8
									RJMP SENDING_END

;									;	0101 1Xxx
;									LSL ADC_DRH
;									BRCS DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9
;									;	0101 10xx
;									DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_89:
;										;	Store 1st Digit(=8) To Send It Later
;										LDI TEMPR2, DIGIT_8
;										;	Store 2nd Digit(=8) To Send It Later
;										LDI TEMPR3, DIGIT_8
;										RJMP SENDING_END
;
;;										;	0101 10Xx
;;										LSL ADC_DRH
;;										BRCS DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_89_DG1_9
;;										;	0101 100x
;;										DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_89_DG1_8:
;;											;	Store 1st Digit(=8) To Send It Later
;;											LDI TEMPR2, DIGIT_8
;;											;	0101 100X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_89_DG1_8_DG2_9
;;											;	0101 1000
;;											DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_89_DG1_8_DG2_8:
;;												;	Store 2nd Digit(=8) To Send It Later
;;												LDI TEMPR3, DIGIT_8
;;												RJMP SENDING_END
;;											;	0101 1001
;;											DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_89_DG1_8_DG2_9:
;;												;	Store 2nd Digit(=9) To Send It Later
;;												LDI TEMPR3, DIGIT_9
;;												RJMP SENDING_END
;;										;	0101 101x
;;										DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_89_DG1_9:
;;											;	Store 1st Digit(=9) To Send It Later
;;											LDI TEMPR2, DIGIT_9
;;											;	0101 101X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_89_DG1_9_DG2_1
;;											;	0101 1010
;;											DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_89_DG1_9_DG2_0:
;;												;	Store 2nd Digit(=0) To Send It Later
;;												LDI TEMPR3, DIGIT_0
;;												RJMP SENDING_END
;;											;	0101 1011
;;											DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_89_DG1_9_DG2_1:
;;												;	Store 2nd Digit(=1) To Send It Later
;;												LDI TEMPR3, DIGIT_1
;;												RJMP SENDING_END
;
;									;	0101 11xx
;									DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9:
;										;	Store 1st Digit(=9) To Send It Later
;										LDI TEMPR2, DIGIT_9
;										;	Store 2nd Digit(=2) To Send It Later
;										LDI TEMPR3, DIGIT_2
;										RJMP SENDING_END
;
;;										;	0101 11Xx
;;										LSL ADC_DRH
;;										BRCS DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9_DG2_45
;;										;	0101 110x
;;										DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9_DG2_23:
;;											;	0101 110X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9_DG2_23_DG2_3
;;											;	0101 1100
;;											DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9_DG2_23_DG2_2:
;;												;	Store 2nd Digit(=2) To Send It Later
;;												LDI TEMPR3, DIGIT_2
;;												RJMP SENDING_END
;;											;	0101 1101
;;											DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9_DG2_23_DG2_3:
;;												;	Store 2nd Digit(=3) To Send It Later
;;												LDI TEMPR3, DIGIT_3
;;												RJMP SENDING_END
;;										;	0101 111x
;;										DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9_DG2_45:
;;											;	0101 111X
;;											LSL ADC_DRH
;;											BRCS DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9_DG2_45_DG2_5
;;											;	0101 1110
;;											DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9_DG2_45_DG2_4:
;;												;	Store 2nd Digit(=4) To Send It Later
;;												LDI TEMPR3, DIGIT_4
;;												RJMP SENDING_END
;;											;	0101 1111
;;											DG1_6789_DG1_6789_DG1_89_DG1_89_DG1_9_DG2_45_DG2_5:
;;												;	Store 2nd Digit(=5) To Send It Later
;;												LDI TEMPR3, DIGIT_5
;;												RJMP SENDING_END

						;	011x xxxx
						DG1_6789_DG1_9:
							;	Store 1st Digit(=9) To Send It Later
							LDI TEMPR2, DIGIT_9
							;	011X xxxx
							LSL ADC_DRH
							;	0110 xxxx
							;	0110 Xxxx
							LSL ADC_DRH
							;	0110 0xxx
;							;	0110 0Xxx
;							LSL ADC_DRH
;							;	0110 00xx
							DG1_6789_DG1_9_DG2_6789:
								;	Store 2nd Digit(=6) To Send It Later
								LDI TEMPR3, DIGIT_6
								RJMP SENDING_END

;;							;	0110 00Xx
;;							LSL ADC_DRH
;;							BRCS DG1_6789_DG1_9_DG2_6789_DG2_89
;;							;	0110 000x
;;							DG1_6789_DG1_9_DG2_6789_DG2_67:
;;								;	0110 000X
;;								LSL ADC_DRH
;;								BRCS DG1_6789_DG1_9_DG2_6789_DG2_67_DG2_7
;;								;	0110 0000
;;								DG1_6789_DG1_9_DG2_6789_DG2_67_DG2_6:
;;									;	Store 2nd Digit(=6) To Send It Later
;;									LDI TEMPR3, DIGIT_6
;;									RJMP SENDING_END
;;								;	0110 0001
;;								DG1_6789_DG1_9_DG2_6789_DG2_67_DG2_7:
;;									;	Store 2nd Digit(=7) To Send It Later
;;									LDI TEMPR3, DIGIT_7
;;									RJMP SENDING_END
;;							;	0110 001x
;;							DG1_6789_DG1_9_DG2_6789_DG2_89:
;;								;	0110 001X
;;								LSL ADC_DRH
;;								BRCS DG1_6789_DG1_9_DG2_6789_DG2_89_DG2_9
;;								;	0110 0010
;;								DG1_6789_DG1_9_DG2_6789_DG2_89_DG2_8:
;;									;	Store 2nd Digit(=8) To Send It Later
;;									LDI TEMPR3, DIGIT_8
;;									RJMP SENDING_END
;;								;	0110 0011
;;								DG1_6789_DG1_9_DG2_6789_DG2_89_DG2_9:
;;									;	Store 2nd Digit(=9) To Send It Later
;;									LDI TEMPR3, DIGIT_9
;;									RJMP SENDING_END

		SENDING_END:
			RCALL SEGMENTS_SLEEP_MODE
			;	Send Result < 100%
			;	Send 1st Digit To 2nd Indicator
			MOV OUTPUT_DATA, TEMPR2
			RCALL SERIAL_TRANSFER
			;	Send 2nd Digit To 1st Indicator
			MOV OUTPUT_DATA, TEMPR3
			RCALL SERIAL_TRANSFER

			RET;	SubProgram Return

;****** Interrupt Routines ******

	;*** External Interrupt 0 Request Handler ***
	EXT_INT0:
		EXT_INT0_HANDLER_BEGIN:
			;	Store Data of GPR in STACK
			PUSH TEMPR1
			PUSH TEMPR2

			;	20ms Delay to Exclude Contact Noise
			RCALL NOISE_DELAY

			SBIS PIND, BUTTON_1
			RJMP ADC_ENABLE
			RJMP ADC_DISABLE
		
			ADC_ENABLE:
				;	Enable ADC 
				SBI ADCSRA, ADEN
				RJMP EXT_INT0_HANDLER_END
			
			ADC_DISABLE:
				;	Disable ADC
				CBI ADCSRA, ADEN
				LDI TEMPR2, 0x03
				LDI TEMPR1, 0xFF
				OUT OCR1BH, TEMPR2
				OUT OCR1BL, TEMPR1
				RCALL SEGMENTS_SLEEP_MODE

		EXT_INT0_HANDLER_END:
			;	Load Stored Data of GPR from STACK
			POP TEMPR2
			POP TEMPR1

			RETI;	Interrupt Return

	;*** External Interrupt 1 Request Handler ***
	EXT_INT1:
		EXT_INT1_HANDLER_BEGIN:
			;	Store Data of GPR in STACK
			PUSH TEMPR1
			PUSH TEMPR2

			;	20ms Delay to Exclude Contact Noise
			RCALL NOISE_DELAY

			;	Disable ADC To Change Channel
			CBI ADCSRA, ADEN
						
			SBIS PIND, BUTTON_2
			RJMP ADC_SOURCE_PHOTORESISTOR
			RJMP ADC_SOURCE_RHEOSTAT
		
			ADC_SOURCE_PHOTORESISTOR:
				;	Select ADC_PHOTORESISTOR Analog Single-Ended Input Channel 
				IN TEMPR1, ADMUX
				CBR TEMPR1, ADC_CHANNEL_RESET
				SBR TEMPR1, ADC_PHOTORESISTOR
				OUT ADMUX, TEMPR1

				RJMP EXT_INT1_HANDLER_END
			
			ADC_SOURCE_RHEOSTAT:
				;	Select ADC_RHEOSTAT Analog Single-Ended Input Channel 
				IN TEMPR1, ADMUX
				CBR TEMPR1, ADC_CHANNEL_RESET
				ORI TEMPR1, ADC_RHEOSTAT
				OUT ADMUX, TEMPR1

		EXT_INT1_HANDLER_END:
			SBIS PIND, BUTTON_1
			;	Reenable ADC To Start Conversions With New Channel
			SBI ADCSRA, ADEN
			;	Load Stored Data of GPR from STACK
			POP TEMPR2
			POP TEMPR1

			RETI;	Interrupt Return

	;*** ADC Conversion Complete Request Handler ***
	ADC_COMP:
		;	Store Data of GPR in STACK
		PUSH TEMPR1
		PUSH TEMPR2
		
		;	Update OCR1B With ADC Conversion Result
		IN TEMPR1, ADCL
		IN TEMPR2, ADCH
		OUT OCR1BH, TEMPR2
		OUT OCR1BL, TEMPR1

		;	Show LED Duty Cycle
		RCALL ADC_RESULT_SEND

		;	Load Stored Data of GPR from STACK
		POP TEMPR2
		POP TEMPR1
	
		RETI;	Interrupt Return

	;*** Timer 1 Overflow Request Handler ***
	TIM1_OVF:
		TIM1_OVF_BEGIN:
			;	Store Data of GPR in STACK
			PUSH TEMPR1
			PUSH TEMPR2

			SBIC ADCSRA, ADEN
			RJMP ADC_CONVERSION_ENABLED
			RJMP TIM1_OVF_END 
			
			ADC_CONVERSION_ENABLED:
				DEC TIM1_DELAY 
				BREQ ADC_RESULT_SEND_SEGMENTS
				RJMP TIM1_OVF_END 
				ADC_RESULT_SEND_SEGMENTS:
					;	Show LED Duty Cycle
					RCALL ADC_RESULT_SEND
					LDI TIM1_DELAY, TIM1_DELAY_SEC

		TIM1_OVF_END:
			;	Load Stored Data of GPR from STACK
			POP TEMPR2
			POP TEMPR1

			RETI;	Interrupt Return
