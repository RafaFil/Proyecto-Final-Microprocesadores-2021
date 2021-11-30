;
; ProyectoFinal.asm
;
; Created: 18/11/2021 18:50:47
; Author : Marcelo Arrarte y Rafael Filardi
;

.ORG	0x0000
	jmp		setupADC
.ORG	0x002A
	jmp		convADC

.DSEG
	nums: .byte 512		; defino espacio en memoria para almacenar 512 n�meros de un byte

.CSEG
convADC:
	in		r30,	SREG	; guardo contexto

	cpi 	r31,	0x00	; chequeo si la bandera est� en 0, entonces nunca fue le�da la seed
	brne	2				; si no es 0, ya le� una seed, salto al final de la interrupci�n (salteo dos l�neas)
	lds		r16,	ADCL	; leo el byte inferior (0-255) para usarlo como seed
	ldi		r31,	0x01	; levanto la bandera para no cambiar m�s la seed

	out		SREG,	r30		; recupero el contexto
	reti

setupADC:
	; ADCSRA |= (1<<ADEN) | (1<<ADSC) | (1<<ADATE) | (1<<ADIE) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0);
	ldi		r16,	0b11101111
	sts		ADCSRA,	r16
	
	; ADMUX |= (1<<REFS0);
	ldi		r16,	0b01000000
	sts		ADMUX,	r16

	ldi		r31,	0x00	; uso como bandera para leer una sola seed para los n�meros random
	ldi		r20,	0x00	; valor para comparar cu�ndo salgo del bucle de generar n�meros

	sei

setupPuntero:
	ldi		r26,	low(nums)		; configuro registro X para apuntar a la primera direcci�n del
	ldi		r27,	high(nums)		; espacio de memoria de los n�meros

start:
    cpi		r31,	0x00	; mientras no haya le�do la seed, espero
	breq	start

	ldi		r18,	low(511)	; cargo en este par de registros la cantidad de n�meros a generar
	ldi		r19,	high(511)

bucleGenerador:
	call	generaNumero
	dec		r18
	cpse	r18,	r20
	rjmp	bucleGenerador

	dec		r19
	cpse	r19,	r20
	rjmp	bucleGenerador

	rjmp	PC+0

generaNumero:
	add		r16,	r16		; lo agrego con s� mismo y guardo el m�dulo 255
	st		X+,		r16		; guardo el n�mero generado en la direcci�n del puntero X e incremento el puntero
	ret

fin:
	rjmp	fin