;
; ProyectoFinal.asm
;
; Created: 18/11/2021 18:50:47
; Author : Marcelo Arrarte y Rafael Filardi
;

.ORG	0x0000
	jmp		setupUsart
.ORG	0x002A
	jmp		convADC

.DSEG
	nums: .byte 512		; defino espacio en memoria para almacenar 512 números de un byte

.CSEG
convADC:
	in		r30,	SREG	; guardo contexto
	ldi		r16,	0b01101111
	sts		ADCSRA,	r16

	cpi 	r31,	0x00	; chequeo si la bandera está en 0, entonces nunca fue leída la seed
	brne	2				; si no es 0, ya leí una seed, salto al final de la interrupción (salteo dos líneas)
	lds		r16,	ADCL	; leo el byte inferior (0-255) para usarlo como seed
	ldi		r31,	0x01	; levanto la bandera para no cambiar más la seed

	out		SREG,	r30		; recupero el contexto
	reti

setupUsart:
	ldi		r16,	103	; establece el baudrate of the transmission
	out		UBRR0L, r16
	sbi		UCSR0B,	4; habilita la recepcion (rxen0)
	sbi		UCSR0B,	3; habilita la transmission (txen0)
	sbi		UCSR0C, 2; seteo frame de 8 bits, los bits UCSZ01 y UCSZ00
	sbi		UCSR0C, 1



setupADC:
	; ADCSRA |= (1<<ADEN) | (1<<ADSC) | (1<<ADATE) | (1<<ADIE) | (1<<ADPS2) | (1<<ADPS1) | (1<<ADPS0);
	ldi		r16,	0b11101111
	sts		ADCSRA,	r16
	
	; ADMUX |= (1<<REFS0);
	ldi		r16,	0b01000000
	sts		ADMUX,	r16

	ldi		r31,	0x00	; uso como bandera para leer una sola seed para los números random
	ldi		r20,	0x00	; valor para comparar cuándo salgo del bucle de generar números

	sei

setupPuntero:
	ldi		r26,	low(nums)		; configuro registro X para apuntar a la primera dirección del
	ldi		r27,	high(nums)		; espacio de memoria de los números

start:
    cpi		r31,	0x00	; mientras no haya leído la seed, espero
	breq	start

	ldi		r18,	low(511)	; cargo en este par de registros la cantidad de números a generar
	ldi		r19,	high(511)

	ldi		r17,	83			; número que voy a sumar para generar los números aleatorios

bucleGenerador:
	call	generaNumero
	dec		r18
	cpse	r18,	r20
	rjmp	bucleGenerador

	dec		r19
	cpse	r19,	r20
	rjmp	bucleGenerador

	rjmp	fin

generaNumero:
	add		r16,	r16		; lo agrego con sí mismo y guardo el módulo 255
	rol		r16				; roto cíclicamente dos bit a la izquierda (multiplico por 2^2)
	rol		r16
	adc		r16,	r17		; sumo un valor constante
	st		X+,		r16		; guardo el número generado en la dirección del puntero X e incremento el puntero
	ret

fin:
	rjmp	fin