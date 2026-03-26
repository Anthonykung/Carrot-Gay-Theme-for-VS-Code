; SPDX-License-Identifier: MIT
; Author: Anthony Kung <hi@anth.dev> (anth.dev)
;
; AVR assembly based on ECE370 at Oregon State University
; See https://ta.anth.dev
;
;  Tiny AVR Playground
;  ATmega32U4
;  - Timer1 overflow interrupt
;  - ADC0 (PF0) analog read
;  - PB4..PB7 LED level meter

.include "m32U4def.inc"

.def  mpr   = r16
.def  temp  = r17
.def  adclo = r18
.def  adchi = r19

.dseg
sample_flag: .byte 1

.cseg
.org 0x0000
  rjmp INIT

.org OVF1addr
  rjmp TIMER1_OVF_ISR

INIT:
  ; Stack
  ldi mpr, high(RAMEND)
  out SPH, mpr
  ldi mpr, low(RAMEND)
  out SPL, mpr

  ; PB4..PB7 output
  ldi mpr, (1 << PB4) | (1 << PB5) | (1 << PB6) | (1 << PB7)
  out DDRB, mpr
  ldi mpr, 0x00
  out PORTB, mpr

  ; ADC0 = PF0 input
  cbi DDRF, PF0
  cbi PORTF, PF0

  ; ADC setup
  ; REFS0 = 1 -> AVcc reference
  ; MUX = 00000 -> ADC0
  ldi mpr, (1 << REFS0)
  sts ADMUX, mpr

  ; Enable ADC, prescaler = 128
  ldi mpr, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
  sts ADCSRA, mpr

  ; Timer1 normal mode, prescaler 1024
  ldi mpr, 0x00
  sts TCCR1A, mpr
  ldi mpr, (1 << CS12) | (1 << CS10)
  sts TCCR1B, mpr

  ; Enable Timer1 overflow interrupt
  ldi mpr, (1 << TOIE1)
  sts TIMSK1, mpr

  ; Clear flag
  ldi mpr, 0
  sts sample_flag, mpr

  sei

MAIN:
  lds mpr, sample_flag
  tst mpr
  breq MAIN

  ; clear flag
  ldi mpr, 0
  sts sample_flag, mpr

  ; start ADC conversion
  lds mpr, ADCSRA
  ori mpr, (1 << ADSC)
  sts ADCSRA, mpr

WAIT_ADC:
  lds mpr, ADCSRA
  sbrc mpr, ADSC
  rjmp WAIT_ADC

  ; read ADC
  lds adclo, ADCL
  lds adchi, ADCH

  ; simple 4-level meter using high byte only
  ; 10-bit ADC -> ADCH holds top 2 bits + more depending on alignment,
  ; but for playground thresholding this is good enough.

  ldi temp, 0x00

  cpi adchi, 16
  brlo LEDS_OFF
  ori temp, (1 << PB4)

  cpi adchi, 64
  brlo WRITE_LEDS
  ori temp, (1 << PB5)

  cpi adchi, 128
  brlo WRITE_LEDS
  ori temp, (1 << PB6)

  cpi adchi, 192
  brlo WRITE_LEDS
  ori temp, (1 << PB7)
  rjmp WRITE_LEDS

LEDS_OFF:
  ldi temp, 0x00

WRITE_LEDS:
  out PORTB, temp
  rjmp MAIN

TIMER1_OVF_ISR:
  push mpr
  in mpr, SREG
  push mpr

  ldi mpr, 1
  sts sample_flag, mpr

  pop mpr
  out SREG, mpr
  pop mpr
  reti