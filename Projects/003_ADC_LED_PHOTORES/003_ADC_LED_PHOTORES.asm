;****** Include Files ******
.include "m8535def.inc"

;****** Initialize GPR ******
.def TEMPR1 = R16

;****** Initialize CONST ******

;*** PORT/PIN ***
.equ LED = PORTB3

;*** ADC ***
.equ ADC_PHOTORESISTOR = (0<<MUX4)|(0<<MUX3)|(0<<MUX2)|(1<<MUX1)|(1<<MUX0)
.equ ADC_CHANNEL_RESET = (1<<MUX4)|(1<<MUX3)|(1<<MUX2)|(1<<MUX1)|(1<<MUX0)
.equ ADC_PSC16 = (1<<ADPS2)|(0<<ADPS1)|(0<<ADPS0)
.equ ADC_AVCC = (0<<REFS1)|(1<<REFS0)
.equ ADC_ADIF = (0<<ADTS2)|(0<<ADTS1)|(0<<ADTS0)

;*** Timer 0 ***
.equ TIM0_PSC_RESET = (1<<CS02)|(1<<CS01)|(1<<CS00)
.equ TIM0_PSC1024 = (1<<CS02)|(0<<CS01)|(1<<CS00)
.equ TIM0_WGM_RESET = (1<<WGM01)|(1<<WGM00)
.equ TIM0_FAST_PWM = (1<<WGM01)|(1<<WGM00)
.equ TIM0_COM_RESET = (1<<COM01)|(1<<COM00)
.equ TIM0_FAST_PWM_INVERT = (1<<COM01)|(1<<COM00)


;****** Interrup Vector ******
.org 0x0
	RJMP RESET
	RETI;	RJMP EXT_INT0
	RETI;	RJMP EXT_INT1
	RETI;	RJMP TIM2_COMP
	RETI;	RJMP TIM2_OVF
	RETI;	RJMP TIM1_CAPT
	RETI;	RJMP TIM1_COMPA
	RETI;	RJMP TIM1_COMPB
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

		;	Initialize PORTB3(OC0 Pin) As Output For LED
		SBI DDRB, LED

		;*** ADC Settings ***
		;	Select ADC Prescaler Of 16
		IN TEMPR1, ADCSRA
		SBR TEMPR1, ADC_PSC16
		OUT ADCSRA, TEMPR1
		;	Select Voltage Reference Of AVCC (~5V)
		IN TEMPR1, ADMUX
		SBR TEMPR1, ADC_AVCC
		OUT ADMUX, TEMPR1
		;	Select Left Adjusted Presentation Of ADC Result For 8-bit Resolution
		SBI ADMUX, ADLAR
		;	Enable ADC Conversion Complete Interrupt
		SBI ADCSRA, ADIE
		IN TEMPR1, SFIOR
		SBR TEMPR1, ADC_ADIF
		OUT SFIOR, TEMPR1
		;	Enable Auto-Triggering 
		SBI ADCSRA, ADATE
		;	Select ADC Input Channel
		IN TEMPR1, ADMUX
		CBR TEMPR1, ADC_CHANNEL_RESET
		SBR TEMPR1, ADC_PHOTORESISTOR
		OUT ADMUX, TEMPR1

		;*** Timer 0 Settings ***
		;	Select Clock Source With Prescaler 1024, i.e. Frequency/1024
		IN TEMPR1, TCCR0
		CBR TEMPR1, TIM0_PSC_RESET
		SBR TEMPR1, TIM0_PSC1024
		OUT TCCR0, TEMPR1
		;	Enable Fast PWM Mode
		IN TEMPR1, TCCR0
		CBR TEMPR1, TIM0_WGM_RESET
		SBR TEMPR1, TIM0_FAST_PWM
		OUT TCCR0, TEMPR1
		;	Enable Inverting Compare Output Mode In Fast PWM Mode
		IN TEMPR1, TCCR0
		CBR TEMPR1, TIM0_COM_RESET
		SBR TEMPR1, TIM0_FAST_PWM_INVERT
		OUT TCCR0, TEMPR1
		;	Define MAX As Initial TOP In OCR0 For Fast PWM Mode
		LDI TEMPR1, 255
		OUT OCR0, TEMPR1

		;	Enable Global Interrupt
		SEI


;****** Main Program ******
	LOOP:
		SBIS ADCSRA, ADEN
		;	Enable ADC
		SBI ADCSRA, ADEN
		SBIS ADCSRA, ADSC
		;	Start ADC Conversion
		SBI ADCSRA, ADSC

		RJMP LOOP;	Start LOOP Again


;****** Interrupt Routines ******

	;*** ADC Conversion Complete Request Handler ***
	ADC_COMP:
		;	Store Data of GPR in STACK
		PUSH TEMPR1
		
		;	Update OCR0 With ADC Conversion Result
		IN TEMPR1, ADCH
		OUT OCR0, TEMPR1

		;	Load Stored Data of GPR from STACK
		POP TEMPR1
	
		RETI;	Interrupt Return
