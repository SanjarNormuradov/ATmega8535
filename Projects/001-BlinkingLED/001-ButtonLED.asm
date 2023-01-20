.include "m8535def.inc"

.def ACC0 = R16
.def ACC1 = R17

.org 0x0
	RJMP RESET

.org 0x15
	RESET:
		LDI ACC0, 0x5f
		OUT SPL, ACC0
		LDI ACC0, 0x02
		OUT SPH, ACC0

		CLR ACC1
		SBI DDRB, 3	

	LOOP:
		SBIC PIND, 2
		SBI PORTB, 3
		CBI PORTB, 3
		RJMP LOOP
