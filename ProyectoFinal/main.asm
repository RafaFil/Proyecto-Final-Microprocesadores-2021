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
setupADC:
	; ADCSRA |= (1<<ADEN) | (1<<ADSC) | (1<<ADATE) | (1<<ADIE) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0);
	ldi		r16,	0b11101111
	sts		ADCSRA,	r16
	
	; ADMUX |= (1<<REFS0);
	ldi		r16,	0b01000000
	sts		ADMUX,	r16

	ldi		r31,	0x00	; uso como bandera para leer una sola seed para los n�meros random

	sei

setupPuntero:
	ldi		r26,	low(nums)		; configuro registro X para apuntar a la primera direcci�n del
	ldi		r27,	high(nums)		; espacio de memoria de los n�meros

convADC:
	in		r30,	SREG	; guardo contexto

	cpi 	r31,	0x00	; chequeo si la bandera est� en 0, entonces nunca fue le�da la seed
	brne	2				; si no es 0, ya le� una seed, salto al final de la interrupci�n (salteo dos l�neas)
	lds		r16,	ADCL	; leo el byte inferior (0-255) para usarlo como seed
	ldi		r31,	0x01	; levanto la bandera para no cambiar m�s la seed

	out		SREG,	r30		; recupero el contexto
	reti

start:
    cpi		r31,	0x00	; mientras no haya le�do la seed, espero
	breq	start

	ldi		r18,	low(512)	; cargo en este par de registros la cantidad de n�meros a generar
	ldi		r19,	high(512)

generaNumero:
	dec		r18				; resto 1 a los n�meros que me quedan generar
	cpi		r18,	0xFF	; si el r18 qued� en 0xFF, es porque "me llev�" una unidad del r19
	brne	1				
	dec		r19				; entonces le resto una unidad a r19

	cpi		r19,	0x00	; si r19 es 0, ya gener� todos los n�meros necesarios, me voy
	; irse

	; genero un n�mero de alguna forma medio m�gica en el r20

	st		X+,		r20		; guardo el n�mero generado en la direcci�n del puntero X e incremento el puntero

	rjmp	generaNumero	; repito

modulo9:
	subi	r21,	9		; resto 9 a r21
	brlt	1				; si r21 era menor que 9 antes de la resta, dejo de restarle
	rjmp	modulo9

	add		r21,	9		; y le vuelvo a sumar 9, para quedar con un n�mero entre 0 y 8

fin:
	rjmp	fin