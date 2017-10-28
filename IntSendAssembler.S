
/*
 * IntSendAssembler.S
 *
 * Created: 2017/10/15 16:12:15
 *  Author: Keiji
 *
 *
 *	�A�Z���u���� if_s_write(uint8_t adr,uint8_t dat)
 *
 *	�Ƃ肠�����o�b�t�@�ɐς��
 *	SPI���M�ς݊��荞��(SPI_STC_vect)�ŏ���	
 *	��M�o�b�t�@�̃T�C�Y��256byte�ɂ���256byte�̋��E�ɔz�u
 *	�A�h���X�v�Z������8bit�����ɂ��ăA�h���X�v�Z��
 *	�J�E���^�̈�ꏈ�����ȗ���
 *
 *	burst write��wait�����鎞�́@flush_spi_buff()���Ă�
 *	�o�b�t�@����ɂȂ�܂ő҂�
 *
 */
 
#include <avr/io.h>
#include <avr/interrupt.h>


#define ZERO  r1
;.extern	send_buf_byte
;.extern	spi_send_read
;.extern	spi_send_write


.global SPI_STC_vect
.global if_s_write	
.global flush_spi_buff

.global spi_sendData
.global send_buf_byte

.section .data

spi_send_write:	.dc.b	0
spi_send_read:	.dc.b	0
send_buf_byte:	.dc.b	0
.extern send_buf_byte

.section .bss
.balign 256	;�o�b�t�@��256byte�̋��E��Ɋm��
spi_sendData:	.ds.b	256

.section .text
.func SPI_STC_vect
SPI_STC_vect:
	cli

	push r0
	in r0, _SFR_IO_ADDR(SREG) 
	push r0

	push r24
	push r30
	push r31

	lds r24,send_buf_byte
	subi r24,1
	sts send_buf_byte,r24
	tst r24
	breq NO_DATA

	sbrs r24,0
	rjmp FIRST_BYTE

	lds r30,spi_send_read
	ldi r31,hi8(spi_sendData)
	ld r24,Z
	out _SFR_IO_ADDR(SPDR),r24
	inc r30
	sts spi_send_read,r30

	pop r31
	pop r30
	pop r24
	pop r0
	out _SFR_IO_ADDR(SREG),r0
	pop r0
	sei
	reti

NO_DATA:	
	sbi 0x5,0

	pop r31
	pop r30
	pop r24
	pop r0
	out _SFR_IO_ADDR(SREG),r0
	pop r0
	sei
	reti

FIRST_BYTE:	
	sbi 0x5,0				;SS��HI

	lds r30,spi_send_read
	cbi 0x5,0					;1 SPI clock �ȏ�󂯂�SS��LO�ɂ���
	ldi  r31,hi8(spi_sendData)

	ld r24,Z
	out _SFR_IO_ADDR(SPDR),r24

	inc r30
	sts spi_send_read,r30

	pop r31
	pop r30
	pop r24
	pop r0
	out _SFR_IO_ADDR(SREG),r0
	pop r0
	sei
	reti

.endfunc



//
//  if_s_write(uint8_t adr,uint8_t dat)
//
.global if_s_write	
.func
if_s_write:

	cli
	
	lds r25,send_buf_byte
	lds r30,spi_send_write
	
	cpse r25,ZERO
	rjmp ON_SEND		//���M��

	ldi	r31,hi8(spi_sendData)
	st Z,r22
	inc r30
	sts	spi_send_write,r30
	ldi r25,2
	sts send_buf_byte,r25
	cbi 0x5,0
	out _SFR_IO_ADDR(SPDR),r24

	sei
	ret


ON_SEND:				//���M���A�o�t�@�ɐςނ���
	ldi r31,hi8(spi_sendData)
	st Z,r24
	inc r30
	st Z,r22
	inc r30
	sts spi_send_write,r30

	subi r25,(-2)
	sts  send_buf_byte,r25

	sei
	ret			


.endfunc

/*
 *	void flush_spi_buff(void)
 *
 *	���M�o�b�t�@����ɂȂ�܂Ń��[�v
 */

.func
flush_spi_buff:

loop1:
	lds r24,send_buf_byte
	tst r24
	brne loop1
	ret
.endfunc