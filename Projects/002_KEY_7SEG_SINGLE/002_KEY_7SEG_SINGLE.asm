// Include Files
.include "m8535def.inc"

// Init GPR
.def ACC0 = R16
.def INPUT_DATA = R17
.def OUTPUT_DATA_VAR = R18
.def OUTPUT_DATA = R19
.def INPUT_ROW = R20
.def DIAL_CONTROL = R21
.def REPETITION_CONTROL = R22

// Init CONST
.equ KEY_IN_1 = 4
.equ KEY_IN_2 = 5
.equ KEY_IN_3 = 6
.equ KEY_IN_4 = 7

.equ KEY_OUT_1 = 5
.equ KEY_OUT_2 = 6
.equ KEY_OUT_3 = 7

.equ SEG_CLK = 0
.equ SEG_DATA = 1

// Interrup Vector
.org 0x0
	RJMP RESET

.org 0x15
	RESET:

		// Init Stack
		LDI ACC0, LOW(RAMEND)
		OUT SPL, ACC0
		LDI ACC0, HIGH(RAMEND)
		OUT SPH, ACC0

		// Init Keyboard Input
		LDI ACC0, (1<<KEY_IN_1) | (1<<KEY_IN_2) | (1<<KEY_IN_3) | (1<<KEY_IN_4)
		OUT DDRB, ACC0

		// Init Keyboard Output
		LDI ACC0, (1<<SEG_CLK) | (1<<SEG_DATA)
		OUT DDRC, ACC0

		// Turn Off Segments
		SLEEP_MODE_ACTIVATE:
			LDI ACC0, 1<<SEG_DATA
			OUT PORTC, ACC0
			CLR ACC0
			SLEEP_MODE_ACTIVATE_BEGIN:
				SBI PORTC, SEG_CLK
				CBI PORTC, SEG_CLK
				INC ACC0
				CPI ACC0, 0x20
				BRNE SLEEP_MODE_ACTIVATE_BEGIN
				RJMP SLEEP_MODE_ACTIVATE_END
			
			SLEEP_MODE_ACTIVATE_END:
				SBI PORTC, SEG_DATA
				SBI PORTC, SEG_CLK
				CBI PORTC, SEG_CLK

		
		LDI INPUT_ROW, 0x1 //1st Bit Set 1 
		LDI DIAL_CONTROL, (1<<KEY_OUT_1) | (1<<KEY_OUT_2) | (1<<KEY_OUT_3)
		MOV REPETITION_CONTROL, DIAL_CONTROL


// Main Program
	LOOP:
		NO_OR_LONG_PRESSED_KEY:
			RCALL SET_INPUT_DATA
			LONG_PRESSED_KEY:
				MOV REPETITION_CONTROL, DIAL_CONTROL
				MOV OUTPUT_DATA, OUTPUT_DATA_VAR
				OUT PORTB, INPUT_DATA
				LDI DIAL_CONTROL, (1<<KEY_OUT_1) | (1<<KEY_OUT_2) | (1<<KEY_OUT_3)
				IN OUTPUT_DATA_VAR, PIND
				AND DIAL_CONTROL, OUTPUT_DATA_VAR
				CPI DIAL_CONTROL, 0xE0
				BRNE LONG_PRESSED_KEY
				CP	DIAL_CONTROL, REPETITION_CONTROL
				BREQ NO_OR_LONG_PRESSED_KEY		
		RCALL PRESSED_KEY 
		
		RJMP LOOP // Start LOOP Again


// SubPrograms

	// Set 0 In Keyboard Input Lines
	SET_INPUT_DATA:
		SBRC INPUT_ROW, 0
		RJMP ZEROin1
		SBRC INPUT_ROW, 1
		RJMP ZEROin2
		SBRC INPUT_ROW, 2
		RJMP ZEROin3
		SBRC INPUT_ROW, 3
		RJMP ZEROin4

	ZEROin1:
		LDI INPUT_DATA, 0xE0
		CLR INPUT_ROW
		LDI INPUT_ROW, 0x2
		RJMP END_SET_INPUT_DATA

	ZEROin2:
		LDI INPUT_DATA, 0xD0
		CLR INPUT_ROW
		LDI INPUT_ROW, 0x4
		RJMP END_SET_INPUT_DATA

	ZEROin3:
		LDI INPUT_DATA, 0xB0
		CLR INPUT_ROW
		LDI INPUT_ROW, 0x8
		RJMP END_SET_INPUT_DATA

	ZEROin4:
		LDI INPUT_DATA, 0x70
		CLR INPUT_ROW
		LDI INPUT_ROW, 0x1

	END_SET_INPUT_DATA:

		RET // SubProgram Return

	
	// Input Row Detection	
	PRESSED_KEY:
		RCALL CLEAR_SEGMENT			
		SBRC INPUT_ROW, 0
		RJMP KEYS_SOS
		SBRC INPUT_ROW, 1
		RJMP KEYS_123
		SBRC INPUT_ROW, 2
		RJMP KEYS_456
		SBRC INPUT_ROW, 3
		RJMP KEYS_789

	// 1st Row Keyboards
	KEYS_123:
		SBRS OUTPUT_DATA, 5
		RJMP KEY_1
		SBRS OUTPUT_DATA, 6
		RJMP KEY_2
		SBRS OUTPUT_DATA, 7
		RJMP KEY_3

	// 2nd Row Keyboards
	KEYS_456:
		SBRS OUTPUT_DATA, 5
		RJMP KEY_4
		SBRS OUTPUT_DATA, 6
		RJMP KEY_5
		SBRS OUTPUT_DATA, 7
		RJMP KEY_6

	// 3rd Row Keyboards
	KEYS_789:
		SBRS OUTPUT_DATA, 5
		RJMP KEY_7
		SBRS OUTPUT_DATA, 6
		RJMP KEY_8
		SBRS OUTPUT_DATA, 7
		RJMP KEY_9

	// 4st Row Keyboards
	KEYS_SOS:
		SBRS OUTPUT_DATA, 5
		RJMP KEY_ASTERISK
		SBRS OUTPUT_DATA, 6
		RJMP KEY_0
		SBRS OUTPUT_DATA, 7
		RJMP KEY_HASHTAG

	// Send Number To Indicator
	KEY_1: // 8'b11111001
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<6) | (1<<5) | (1<<4) | (1<<3) | (1<<0)
		RCALL SERIAL_TRANSFER

		RJMP END_PRESSED_KEY_DETECTION

	KEY_2: // 8'b10100100
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<5) | (1<<2)
		RCALL SERIAL_TRANSFER		

		RJMP END_PRESSED_KEY_DETECTION

	KEY_3: // 8'b10110000
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<5) | (1<<4)
		RCALL SERIAL_TRANSFER

		RJMP END_PRESSED_KEY_DETECTION

	KEY_4: // 8'b10011001
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<4) | (1<<3) | (1<<0)
		RCALL SERIAL_TRANSFER

		RJMP END_PRESSED_KEY_DETECTION

	KEY_5: // 8'b10010010
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<4) | (1<<1)
		RCALL SERIAL_TRANSFER

		RJMP END_PRESSED_KEY_DETECTION

	KEY_6: // 8'b10000010
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<1)
		RCALL SERIAL_TRANSFER

		RJMP END_PRESSED_KEY_DETECTION

	KEY_7: // 8'b11111000
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<6) | (1<<5) | (1<<4) | (1<<3)
		RCALL SERIAL_TRANSFER

		RJMP END_PRESSED_KEY_DETECTION

	KEY_8: // 8'b10000000
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7)
		RCALL SERIAL_TRANSFER

		RJMP END_PRESSED_KEY_DETECTION

	KEY_9: // 8'b10010000
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<4)
		RCALL SERIAL_TRANSFER

		RJMP END_PRESSED_KEY_DETECTION

	KEY_ASTERISK: // 8'b10001000
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<3)
		RCALL SERIAL_TRANSFER

		RJMP END_PRESSED_KEY_DETECTION

	KEY_0: // 8'b11000000
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<6)
		RCALL SERIAL_TRANSFER

		RJMP END_PRESSED_KEY_DETECTION

	KEY_HASHTAG: // 8'b10001001
		CLR OUTPUT_DATA
		LDI OUTPUT_DATA, (1<<7) | (1<<3) | (1<<0)
		RCALL SERIAL_TRANSFER


	END_PRESSED_KEY_DETECTION:

		RET ;SubProgram Return

	// Serial Data Transfer
	SERIAL_TRANSFER:
		CLR ACC0
		SERIAL_TRANSFER_BEGIN:
			LSL OUTPUT_DATA
			BRCS SEND_1
			SEND_0:
				CBI PORTC, SEG_DATA
				SBI PORTC, SEG_CLK
				CBI PORTC, SEG_CLK
				INC ACC0
				CPI ACC0, 0x8
				BRNE SERIAL_TRANSFER_BEGIN
				RJMP SERIAL_TRANSFER_END

			SEND_1:
				SBI PORTC, SEG_DATA
				SBI PORTC, SEG_CLK
				CBI PORTC, SEG_CLK
				INC ACC0
				CPI ACC0, 0x8
				BRNE SERIAL_TRANSFER_BEGIN

		SERIAL_TRANSFER_END:
			
			RET ;SubProgram Return

	CLEAR_SEGMENT:
		LDI ACC0, 1<<SEG_DATA
		OUT PORTC, ACC0
		CLR ACC0
		CLEAR_SEGMENT_BEGIN:
			SBI PORTC, SEG_CLK
			CBI PORTC, SEG_CLK
			INC ACC0
			CPI ACC0, 0x20
			BRNE CLEAR_SEGMENT_BEGIN
			RJMP CLEAR_SEGMENT_END
			
		CLEAR_SEGMENT_END:
			SBI PORTC, SEG_DATA
			SBI PORTC, SEG_CLK
			CBI PORTC, SEG_CLK

		RET ;SubProgram Return
