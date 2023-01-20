;****** Include Files ******
.include "m8535def.inc"

;****** Initialize GPR ******
.def TEMPR1 = R16
.def TEMPR2 = R17
.def TEMPR3 = R18
.def USART_TRANSMIT_DATA = R19
.def USART_RECEIVE_DATA = R20
.def USART_ERROR_FLAGS = R21
.def USART_DOR_DATA = R22

;****** Initialize CONST ******

;*** PORT/PIN ***
.equ BUTTON_1 = PIND2


;*** External Interrupts ***
.equ EXT_INT0_ANY_ISC = (0<<ISC01)|(1<<ISC00)
.equ EXT_INT0_EN = (1<<INT0)

;*** Delay Parameters ***
.equ MAX_CNT = 255
.equ DELAY_mSEC = 20

;*** USART ***
.equ USART_BAUD_4800 = 12
.equ USART_ASYNC_MODE = (1<<URSEL)|(0<<UMSEL)
.equ USART_EVEN_PARITY = (1<<URSEL)|(1<<UPM1)|(0<<UPM0)
.equ USART_1_STOP = (1<<URSEL)|(0<<USBS)
.equ USART_UCSRC_8_DATA = (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
.equ USART_UCSRB_8_DATA =(0<<UCSZ2)
.equ USART_TX_EN = (1<<TXEN)
.equ USART_TX_DIS = (1<<TXEN)
.equ USART_RX_EN = (1<<RXEN)
.equ USART_RX_DIS = (1<<RXEN)
.equ USART_INT_UDRE_EN = (1<<UDRIE)
.equ USART_INT_TXC_EN = (1<<TXCIE)
.equ USART_INT_RXC_EN = (1<<RXCIE)

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
	RETI;	RJMP ADC_COMP
	RETI;	RJMP EE_READY
	RETI;	RJMP ANA_COMP
	RETI;	RJMP TWI
	RETI;	RJMP INT2
	RETI;	RJMP TIM0_COMP
	RETI;	RJMP SPM_RDY

.org 0x15
	RESET:
		;	Initialize STACK
		LDI TEMPR1, LOW(RAMEND)
		OUT SPL, TEMPR1
		LDI TEMPR1, HIGH(RAMEND)
		OUT SPH, TEMPR1

		;*** USART Settings ***
		;	Set BAUD Rate(4800)
		LDI TEMPR1, USART_BAUD_4800
		OUT UBRRL, TEMPR1
		;	Set Frame Format: 
		IN TEMPR1, UBRRH
		IN TEMPR1, UCSRC
		IN TEMPR2, UCSRB
		;	8 Data Bits
		SBR TEMPR1, USART_UCSRC_8_DATA
		SBR TEMPR2, USART_UCSRB_8_DATA
		;	1 Stop Bit
		SBR TEMPR1, USART_1_STOP
		;	Even Parity Bit
		SBR TEMPR1, USART_EVEN_PARITY
		;	Asynchronous Mode
		SBR TEMPR1, USART_ASYNC_MODE
		OUT UCSRC, TEMPR1
		OUT UCSRB, TEMPR2
		;	Enable Transmit Operation
		IN TEMPR1, UCSRB
		SBR TEMPR1, USART_TX_EN
		OUT UCSRB, TEMPR1
		;	Enable Receive Operation
		IN TEMPR1, UCSRB
		SBR TEMPR1, USART_RX_EN
		OUT UCSRB, TEMPR1
;		;	Enable USART Data Register Empty Interrupt
;		IN TEMPR1, UCSRB
;		SBR TEMPR1, USART_INT_UDRE_EN
;		OUT UCSRB, TEMPR1
;		;	Enable USART Transmit Complete Interrupt
;		IN TEMPR1, UCSRB
;		SBR TEMPR1, USART_INT_TXC_EN
;		OUT UCSRB, TEMPR1
;		;	Enable USART Receive Complete Interrupt
;		IN TEMPR1, UCSRB
;		SBR TEMPR1, USART_INT_RXC_EN
;		OUT UCSRB, TEMPR1

		;*** External Interrupt 0 Settings ***
		;	Select Any Logical Change As Interrupt Sense Control 
;		LDI TEMPR1, EXT_INT0_ANY_ISC
;		OUT MCUCR, TEMPR1
		;	Enable External Interrupt 0 Request
;		LDI TEMPR1,	EXT_INT0_EN
;		OUT GICR, TEMPR1

		;	Enable Global Interrupt
		SEI


;****** Main Program ******
	LOOP:
		USART_RECEIVE:
			SBIS UCSRA, RXC
			RJMP LOOP
			RCALL USART_RX_DATA
		OUT UDR, USART_TRANSMIT_DATA
		USART_TRANSMIT:
			SBIS UCSRA, UDRE
			RJMP USART_TRANSMIT
		ORI USART_DOR_DATA, 0
		BREQ USART_RECEIVE
		OUT UDR, USART_DOR_DATA
		CLR USART_DOR_DATA
		RJMP USART_TRANSMIT
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

	;*** USART Receive Data ***
	USART_RX_DATA:
		USART_RX_DATA_BEGIN:
			IN USART_ERROR_FLAGS, UCSRA
			IN USART_RECEIVE_DATA, UDR
			ANDI USART_ERROR_FLAGS, (1<<DOR)|(1<<FE)|(1<<PE)
			BRNE USART_FRAME_PARITY_OVERRUN_ERRORS
			;	No Error Detected Or Data Overrun Occured
			MOV USART_TRANSMIT_DATA, USART_RECEIVE_DATA
			INC USART_TRANSMIT_DATA
			RJMP USART_RX_DATA_END
			USART_FRAME_PARITY_OVERRUN_ERRORS:
				IN USART_DOR_DATA, UDR
				LDI USART_TRANSMIT_DATA, -1	
		USART_RX_DATA_END:
			RET;	SubProgram Return	


;****** Interrupt Routines ******

	;*** USART Data Register Empty Interrupt Request Handler ***
	USART_DRE:
		USART_DRE_HANDLER_BEGIN:
			;	Store Data of GPR in STACK
			
			CPI USART_DOR_DATA, 0
			BREQ USART_NO_DATA_OVERRUN
			OUT UDR, USART_DOR_DATA
			RJMP USART_DRE_HANDLER_END		
		USART_NO_DATA_OVERRUN:
			OUT UDR, USART_TRANSMIT_DATA
		USART_DRE_HANDLER_END:
			;	Load Stored Data of GPR from STACK

			;	Enable Transmit Operation Temporarily
			;	To Send Modified Data Back To Terminal
			IN TEMPR1, UCSRB
			SBR TEMPR1, USART_TX_EN
			OUT UCSRB, TEMPR1
			RETI;	Interrupt Return

	;*** USART Transmit Complete Interrupt Request Handler ***
	USART_TXC:
			;	Store Data of GPR in STACK
			PUSH TEMPR1			
			;	Disable Transmit Operation Temporarily
			;	Till Receive Operation Is Over
			IN TEMPR1, UCSRB
			CBR TEMPR1, USART_TX_DIS
			OUT UCSRB, TEMPR1			
			;	Load Stored Data of GPR from STACK
			POP TEMPR1
			RETI;	Interrupt Return

	;*** USART Receive Complete Interrupt Request Handler ***
	USART_RXC:
		USART_RXC_HANDLER_BEGIN:
			;	Store Data of GPR in STACK
			PUSH TEMPR1
			;	Read Initial Data From RXD 
			;	And Load Modified Data To TXD
			RCALL USART_RX_DATA
;			;	Disable Receive Operation
;			IN TEMPR1, UCSRB
;			CBR TEMPR1, USART_RX_DIS
;			OUT UCSRB, TEMPR1
	
		USART_RXC_HANDLER_END:		
			;	Load Stored Data of GPR from STACK
			POP TEMPR1
			RETI;	Interrupt Return

	;*** External Interrupt 0 Request Handler ***
	EXT_INT0:
		EXT_INT0_HANDLER_BEGIN:
			;	Store Data of GPR in STACK
			PUSH TEMPR1
			PUSH TEMPR2
			;	20ms Delay to Exclude Contact Noise
			RCALL NOISE_DELAY
			SBIC PINC, BUTTON_1
			RJMP USART_TRANSFER_DISABLE
			USART_TRANSFER_ENABLE:
				;	Enable Transmit Operation
				IN TEMPR1, UCSRB
				SBR TEMPR1, USART_TX_EN
				OUT UCSRB, TEMPR1
				;	Enable Receive Operation
				IN TEMPR1, UCSRB
				SBR TEMPR1, USART_RX_EN
				OUT UCSRB, TEMPR1
			USART_TRANSFER_DISABLE:
				;	Wait Till Ongoing Data Reception Is Over
				SBIS UCSRA, RXC
				RJMP USART_TRANSFER_DISABLE
				;	Read Initial Data From RXD 
				;	And Load Modified Data To TXD 
				;	Before Disabling Transmit And Receive Operations
				RCALL USART_RX_DATA
				;	Disable Receive Operation
				IN TEMPR1, UCSRB
				CBR TEMPR1, USART_RX_DIS
				OUT UCSRB, TEMPR1
				;	Disable Transmit Operation
				IN TEMPR1, UCSRB
				CBR TEMPR1, USART_TX_DIS
				OUT UCSRB, TEMPR1			
		EXT_INT0_HANDLER_END:
			;	Load Stored Data of GPR from STACK
			POP TEMPR2
			POP TEMPR1
			RETI;	Interrupt Return
