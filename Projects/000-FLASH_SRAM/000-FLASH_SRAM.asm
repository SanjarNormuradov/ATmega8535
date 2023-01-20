;	Include Files
.include "m8535def.inc"

;	Initialize GPR
.def TEMP = R16
.def DATA_L_BYTE = R17
.def DATA_H_BYTE = R18


;	Interrup Vector
.org 0x0
	RJMP RESET

.org 0x15
	RESET:
		
		;	Initialize Stack
		LDI TEMP, LOW(RAMEND)
		OUT SPL, TEMP
		LDI TEMP, HIGH(RAMEND)
		OUT SPH, TEMP
	
	FLASH_ADD100_6BYTES_SRAM_ADD150:

		;	Initialize Z-pointer To 1st Data Address In Program Memory
		LDI ZH, HIGH($100 << 1)
		LDI ZL, LOW($100 << 1)

		;	Initialize Y-pointer To 1st Data Address In Data Space
		LDI YH, HIGH($150)
		LDI YL, LOW($150)
		
		CLR TEMP

		TRANSFER_6BYTES:

			;	Load Data From Program Memory Pointed To By Z
			LPM DATA_L_BYTE, Z+
			LPM DATA_H_BYTE, Z+;	Z-pointer Is Initialized To Next Data Address In Program Memory

			;	Store Data To Data Space
			ST Y+, DATA_L_BYTE
			ST Y+, DATA_H_BYTE	
			
			INC TEMP
			CPI TEMP, 0x3
			BRNE TRANSFER_6BYTES



	SRAM_ADD150_10BYTES_EEPROM_ADD100:

		;	Initialize Y-pointer To 1st Data Address In Data Space
		LDI YH, HIGH($150)
		LDI YL, LOW($150)

		;	Load 1st Data Address High And Low Byte To EEARH
		LDI ZH, 0x01
		OUT EEARH, ZH
		LDI ZL, 0x00
		OUT EEARL, ZL
		
		CLR TEMP

		EEPROM_WRITE_10BYTES:

			;	Wait For Completion Of Previous Write
			SBIC EECR, EEWE
			RJMP EEPROM_WRITE_10BYTES

			;	Increment Data Address Low Byte 
			MOV ZL, TEMP
			OUT EEARL, ZL
			
			;	Store Data To Data Space
			LD DATA_L_BYTE, Y+ 
		
			;	Write Logical One to EEBMWE
			SBI EECR, EEMWE

			;	Start EEPROM Write By Setting EEWE
			SBI EECR, EEWE
			
			INC TEMP
			CPI TEMP, 0x10
			BRNE EEPROM_WRITE_10BYTES
