;;;;;;; Program hierarchy ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mainline
;   Initial
;   LoopTime
;     InitLCD.
;     T40
;      DisplayV
;       DisplayC
;        constant strings
;;;;;;; Assembler directives ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        list  P=PIC18F452, F=INHX32, C=160, N=0, ST=OFF, MM=OFF, R=DEC, X=ON
        #include P18F452.inc
        __CONFIG  _CONFIG1H, _HS_OSC_1H  ;HS oscillator
        __CONFIG  _CONFIG2L, _PWRT_ON_2L & _BOR_ON_2L & _BORV_42_2L  ;Reset
        __CONFIG  _CONFIG2H, _WDT_OFF_2H  ;Watchdog timer disabled
        __CONFIG  _CONFIG3H, _CCP2MX_ON_3H  ;CCP2 to RC1 (rather than to RB3)
        __CONFIG  _CONFIG4L, _LVP_OFF_4L  ;RB5 enabled for I/O

;;;;;;; Variables ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Variables are 8-bit long each
        cblock  0x000           ;Beginning of Access RAM
        TMR0LCOPY               ;Copy of sixteen-bit Timer0 used by LoopTime
        TMR0HCOPY
        INTCONCOPY              ;Copy of INTCON for LoopTime subroutine
        ALIVECNT                ;Counter for blinking "Alive" LED
        BYTESTR:10              ;initialize it to 10-8byte
	BYTE
	COUNT
	counter
	counter1 
	counter2
	counter3
	counter4
	counter5
	counter6
	counter7
	counter8
	counter9
	counter10
	counter11
	counter12
	counter13
	counter14
	counter15
	counter16
	counter17
	counter18
	endc

;;;;;;; Macro definitions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVLF   macro  literal,dest
        movlw  literal
        movwf  dest
        endm
POINT   macro  stringname
        MOVLF  high stringname, TBLPTRH
        MOVLF  low stringname, TBLPTRL
        endm
DISPLAY macro register
	movff register,BYTE
	call  ByteDisplay
	endm
;;;;;;; Vectors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        org  0x0000             ;Reset vector
        nop
        goto  Mainline

        org  0x0008             ;High priority interrupt vector
        goto HiPriISR              ;Trap

        org  0x0018             ;Low priority interrupt vector
        goto $               ;Trap

;;;;;;; Mainline program ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Mainline
        rcall  Initial          ;Initialize everything
    Loop
	rcall Messages		;Welcome messages
    bra Loop
    
;;;;;;; Initial subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This subroutine performs all initializations of variables and registers.
Initial
	MOVLF  B'01000001',ADCON0
        MOVLF  B'10001110',ADCON1  ;Enable PORTA & PORTE digital I/O pins
        MOVLF  B'11100001',TRISA  ;Set I/O for PORTA
        MOVLF  B'11111110',TRISB  ;Set I/O for PORTB
        MOVLF  B'11010000',TRISC  ;Set I/0 for PORTC
        MOVLF  B'00001111',TRISD  ;Set I/O for PORTD
        MOVLF  B'00000000',TRISE  ;Set I/O for PORTE
        MOVLF  B'10001000',T0CON  ;Set up Timer0 for a looptime of 10 ms
        MOVLF  B'00010000',PORTA  ;Turn off all four LEDs driven from PORTA
        rcall InitLCD
	bsf RCON,IPEN
	bsf TRISB,1
	bsf INTCON2,INTEDG1
	bcf INTCON,INT0IF
	bsf INTCON,INT0IE
	bsf INTCON3,INT1IP
	bcf INTCON3,INT1IF
	bsf INTCON3,INT1IE
	bsf INTCON,GIEH
	bsf INTCON,GIEL
return
	
Check_bit			    ;Check b4 status, continue runing when pressed or start over
    IF_ PORTB,4==1
	nop
    ELSE_
	POINT fi
	rcall DisplayC
	POINT fi1
	rcall DisplayC
	rcall Delayloop
	rcall Delayloop
	goto Mainline
    ENDIF_
return 
    
Check_bit1			    ;Check b4 and b5 statuses
    IF_ 
    AND_
	PORTB,4==1
	PORTB,5==1
    ENDAND_
	nop
    ELSE_
	POINT fi
	rcall DisplayC
	POINT fi1
	rcall DisplayC
	rcall Delayloop
	rcall Delayloop
	goto Mainline
    ENDIF_
return

Check_bit2			    ;Check b5 status
    IF_ PORTB,5==1
	nop
    ELSE_
	POINT fi
	rcall DisplayC
	POINT fi1
	rcall DisplayC
	rcall Delayloop
	rcall Delayloop
	goto Mainline
    ENDIF_
return 
    
Reader				    ;Simplified time delay and message read from register
	rcall Delayloop
	rcall DisplayC
return 

Reader1
	rcall Delayloop1
	rcall DisplayC
return
	
;;;;;;; LoopTime subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This subroutine waits for Timer0 to complete its ten millisecond count
; sequence. It does so by waiting for sixteen-bit Timer0 to roll over. To obtain
; a period of precisely 10000/0.4 = 25000 clock periods, it needs to remove
; 65536-25000 or 40536 counts from the sixteen-bit count sequence.  The
; algorithm below first copies Timer0 to RAM, adds "Bignum" to the copy ,and
; then writes the result back to Timer0. It actually needs to add somewhat more
; counts to Timer0 than 40536.  The extra number of 12+2 counts added into
; "Bignum" makes the precise correction.

Bignum  equ     65536-25000+12+2
LoopTime
        REPEAT_
        UNTIL_ INTCON,TMR0IF ==1  
        movff  INTCON,INTCONCOPY  ;Disable all interrupts to CPU
        bcf  INTCON,GIEH
        movff  TMR0L,TMR0LCOPY  ;Read 16-bit counter at this moment
        movff  TMR0H,TMR0HCOPY
        movlw  low  Bignum
        addwf  TMR0LCOPY,F
        movlw  high  Bignum
        addwfc  TMR0HCOPY,F
        movff  TMR0HCOPY,TMR0H
        movff  TMR0LCOPY,TMR0L  ;Write 16-bit counter at this moment
        movf  INTCONCOPY,W      ;Restore GIEH interrupt enable bit
        andlw  B'10000000'
        iorwf  INTCON,F
        bcf  INTCON,TMR0IF      ;Clear Timer0 flag
return

Delayloop			;Time delayed by 0.6s
	movlw 60
	movwf counter
    again
	rcall LoopTime
	decfsz counter,F
	goto again
return
    
Delayloop1			;Time delayed by 0.3s
	movlw 30
	movwf counter1
    again1
	rcall LoopTime
	decfsz counter1,F
	goto again1
return
     
;;;;;;; InitLCD subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Initialize the Optrex 8x2 character LCD.
; First wait for 0.1 second, to get past display's power-on reset time.
InitLCD
        MOVLF  10,COUNT         ;Wait 0.1 second
        REPEAT_
          rcall  LoopTime       ;Call LoopTime 10 times
          decf  COUNT,F
    UNTIL_  .Z.

        bcf  PORTE,0            ;RS=0 for command
        POINT  LCDstr           ;Set up table pointer to initialization string
        tblrd*                  ;Get first byte from string into TABLAT
    REPEAT_
        bsf  PORTE,1          ;Drive E high
        movff  TABLAT,PORTD   ;Send upper nibble
        bcf  PORTE,1          ;Drive E low so LCD will process input
        rcall  LoopTime       ;Wait ten milliseconds
        bsf  PORTE,1          ;Drive E high
        swapf  TABLAT,W       ;Swap nibbles
        movwf  PORTD          ;Send lower nibble
        bcf  PORTE,1          ;Drive E low so LCD will process input
        rcall  LoopTime       ;Wait ten milliseconds
        tblrd+*               ;Increment pointer and get next byte
        movf  TABLAT,F        ;Is it zero?
    UNTIL_  .Z.
return
    
;;;;;;; T40 subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Pause for 40 microseconds  or 40/0.4 = 100 clock cycles.
; Assumes 10/4 = 2.5 MHz internal clock rate.
T40
        movlw  100/3            ;Each REPEAT loop takes 3 cycles

        movwf  COUNT
    REPEAT_
          decf  COUNT,F
    UNTIL_  .Z.
        return
;;;;;;; DisplayV subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This subroutine is called with FSR0 containing the address of a variable
; display string.  It sends the bytes of the string to the LCD.  The first
; byte sets the cursor position.  The remaining bytes are displayed, beginning
; at that position.
DisplayV
        bcf  PORTE,0            ;Drive RS pin low for cursor positioning code
    REPEAT_
         bsf  PORTE,1          ;Drive E pin high
         movff  INDF0,PORTD    ;Send upper nibble
         bcf  PORTE,1          ;Drive E pin low so LCD will accept nibble
         bsf  PORTE,1          ;Drive E pin high again
         swapf  INDF0,W        ;Swap nibbles
         movwf  PORTD          ;Write lower nibble
         bcf  PORTE,1          ;Drive E pin low so LCD will process byte
         rcall  T40            ;Wait 40 usec
         bsf  PORTE,0          ;Drive RS pin high for displayable characters
         movf  PREINC0,W       ;Increment pointer, then get next byte
    UNTIL_ .Z.             ;Is it zero?
return

;;;;;;;;DisplayC subroutine;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This subroutine is called with TBLPTR containing the address of a constant
; display string.  It sends the bytes of the string to the LCD.  The first
; byte sets the cursor position.  The remaining bytes are displayed, beginning
; at that position.
; This subroutine expects a normal one-byte cursor-positioning code, 0xhh, or
; an occasionally used two-byte cursor-positioning code of the form 0x00hh.
DisplayC
        bcf  PORTE,0            ;Drive RS pin low for cursor-positioning code
        tblrd*                   ;Get byte from string into TABLAT
        movf  TABLAT,F          ;Check for leading zero byte
    IF_ .Z.
        tblrd+*                 ;If zero, get next byte
    ENDIF_
    REPEAT_
        bsf  PORTE,1          ;Drive E pin high
        movff  TABLAT,PORTD   ;Send upper nibble
        bcf  PORTE,1          ;Drive E pin low so LCD will accept nibble
        bsf  PORTE,1          ;Drive E pin high again
        swapf  TABLAT,W       ;Swap nibbles
        movwf  PORTD          ;Write lower nibble
        bcf  PORTE,1          ;Drive E pin low so LCD will process byte
        rcall  T40            ;Wait 40 usec
        bsf  PORTE,0          ;Drive RS pin high for displayable characters
        tblrd+*                 ;Increment pointer, then get next byte
        movf  TABLAT,F        ;Is it zero?
        UNTIL_ .Z.
return

;;;;;;;;ByteDisplay subroutine;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
ByteDisplay 
	lfsr 0,BYTESTR+8
    REPEAT_
	clrf WREG
	rrcf BYTE,F
	rlcf WREG,F
	iorlw 0x30
	movwf POSTDEC0
	movf FSR0L,W
	sublw low BYTESTR
    UNTIL_ .Z.
	lfsr 0,BYTESTR
	MOVLF 0xc4,BYTESTR
	clrf BYTESTR+9
	rcall DisplayV
return   
	
;;;;;;;;Priority subroutine;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HiPriISR		
    LOOP_
    IF_ INTCON,INT0IF==1	;The interrupt to check the game starts or not
	rcall Level_option
    ENDIF_
    AND
	IF_ PORTB,1==1		;Check b1 status, goes Lvl1 if its on 
	rcall Level_1
	ENDIF_
    OR
	IF_ PORTB,2==1		;Check b2 status,goes Lvl2 if its on 
	rcall Level_2
	ENDIF_
    OR1
	IF_ PORTB,3==1		;Check b3 status,goes Lvl3 if its on 
	rcall Level_3
	ENDIF_
    BREAK_
    ENDLOOP_
retfie FAST
    
;;;;;;; Messages subroutine ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Messages			;Point to welcome messages
    POINT message
	rcall Reader1
	MOVLF 59,counter2
    REPEAT_
	rcall Reader1
	decf counter2,F
    UNTIL_ .Z.
return

Level_option			;Point to lvl select messages
    POINT mes
	rcall Reader1
	MOVLF 18,counter3
    REPEAT_
	rcall Reader1
	decf counter3,F
    UNTIL_ .Z.
return

Level_1				;Lvl1 of the game
    WHILE_ INTCON,INT0IF==1	;Always check the flag on 
	MOVLF 2,counter4
	bsf PORTA,3		;A3 LED on 
	POINT lvl1		;Message for which lvl
	rcall DisplayC
    REPEAT_			;The messages run 2 times 
	MOVLF 6,counter5	;Runs the edited scenes
	POINT lvl1n2_
	rcall DisplayC
    REPEAT_
	rcall Reader		
	decf counter5,F
    UNTIL_ .Z.
	rcall Check_bit		;Used the subroutine to check users press the button or not at this moment
	POINT jp		;Runs the edited scenes, when button pressed 
	rcall DisplayC
	MOVLF 6,counter6
    REPEAT_
	rcall Reader
	decf counter6,F
    UNTIL_ .Z.
	rcall Check_bit		;Check jump button status
	POINT jp1_		;Runs the edited scenes, when button pressed 
	rcall DisplayC
	MOVLF 2,counter7
    REPEAT_
	rcall Reader		
	decf counter7,F		 
    UNTIL_ .Z.
	rcall Check_bit		;Check jump button status
	POINT jp2_		;Runs the edited scenes, when button pressed
	rcall DisplayC
	MOVLF 8,counter8
    REPEAT_
	rcall Reader
	decf counter8,F
    UNTIL_ .Z.
	rcall Check_bit		;Check jump button status
	POINT jp3_		;Runs the edited scenes, when button pressed
	rcall DisplayC
	MOVLF 8,counter9
    REPEAT_
	rcall Reader
	decf counter9,F
    UNTIL_ .Z.
	rcall Check_bit		;Check jump button status
	POINT jp4_		;Runs the edited scenes, when button pressed
	rcall DisplayC
	MOVLF 6,counter10
    REPEAT_
	rcall Reader
	decf counter10,F
    UNTIL_ .Z.
	rcall Check_bit		;Check jump button status
	POINT jp5_		;Runs the edited scenes, when button pressed
	rcall DisplayC
	MOVLF 2,counter11
    REPEAT_
	rcall Reader
	decf counter11,F
    UNTIL_ .Z.
	rcall Check_bit		;Check jump button status
	POINT jp6_		;Runs the edited scenes, when button pressed
	rcall DisplayC
	MOVLF 8,counter12
    REPEAT_
	rcall Reader
	decf counter12,F
    UNTIL_ .Z.
	rcall Check_bit		;Check jump button status
	POINT jp7_		;Runs the edited scenes, when button pressed
	rcall DisplayC
	MOVLF 5,counter13
    REPEAT_
	rcall Reader
	decf counter13,F
    UNTIL_ .Z.
	decf counter4,F	
    UNTIL_ .Z.
	POINT ba		;Messages remind number of conins and tell boss show up
	rcall DisplayC
	POINT ba3
	rcall DisplayC
	rcall Delayloop
	MOVLF 2,counter14
    REPEAT_
	POINT bs		;The scene of boss
	MOVLF 12,counter15
    REPEAT_
	rcall Reader
	decf counter15,F
    UNTIL_ .Z.
	rcall Check_bit1
	POINT ut		;Users attacking
	rcall DisplayC
	MOVLF 22,counter16
    REPEAT_
	rcall Reader
	decf counter16,F
    UNTIL_ .Z.
	rcall Check_bit1
	POINT ut1_
	rcall DisplayC
	MOVLF 13,counter17
    REPEAT_
	rcall Reader
	decf counter17,F
    UNTIL_ .Z.
	decf counter14,F
    UNTIL_ .Z.
	POINT bd		;Scenes when boss destroyed 
	rcall DisplayC		
	MOVLF 8,counter18
    REPEAT_
	rcall Reader
	decf counter18,F
    UNTIL_ .Z.
	POINT wi		;User passed lvl1
	rcall DisplayC		
	POINT wi1
	rcall DisplayC
	rcall Delayloop
	rcall Delayloop
	bcf INTCON,INT0IF
    ENDWHILE_
	goto Mainline		;The game starts over
return

Level_2				;Lvl2 of the game, same as lvl1 with the different time delay
    WHILE_ INTCON,INT0IF==1	
	MOVLF 3,counter4	;The messages repest three times
	MOVLF B'00011100',PORTA	;RA2 and RA3 LED on 
	POINT lvl2
	rcall DisplayC
    REPEAT_
	MOVLF 6,counter5
	POINT lvl1n2_
	rcall DisplayC
    REPEAT_
	rcall Reader1
	decf counter5,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT jp
	rcall DisplayC
	MOVLF 6,counter6
    REPEAT_
	rcall Reader1
	decf counter6,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT jp1_
	rcall DisplayC
	MOVLF 2,counter7
    REPEAT_
	rcall Reader1
	decf counter7,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT jp2_
	rcall DisplayC
	MOVLF 8,counter8
    REPEAT_
	rcall Reader1
	decf counter8,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT jp3_
	rcall DisplayC
	MOVLF 8,counter9
    REPEAT_
	rcall Reader1
	decf counter9,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT jp4_
	rcall DisplayC
	MOVLF 6,counter10
    REPEAT_
	rcall Reader1
	decf counter10,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT jp5_
	rcall DisplayC
	MOVLF 2,counter11
    REPEAT_
	rcall Reader1
	decf counter11,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT jp6_
	rcall DisplayC
	MOVLF 8,counter12
    REPEAT_
	rcall Reader1
	decf counter12,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT jp7_
	rcall DisplayC
	MOVLF 5,counter13
    REPEAT_
	rcall Reader1
	decf counter13,F
    UNTIL_ .Z.
	decf counter4,F
    UNTIL_ .Z.
	POINT ba1
	rcall DisplayC
	POINT ba3
	rcall DisplayC
	rcall Delayloop
	rcall Delayloop
	MOVLF 3,counter14
    REPEAT_
	POINT bs 
	MOVLF 12,counter15
    REPEAT_
	rcall Reader1
	decf counter15,F
    UNTIL_ .Z.
	rcall Check_bit1
	POINT ut
	rcall DisplayC
	MOVLF 22,counter16
    REPEAT_
	rcall Reader1
	decf counter16,F
    UNTIL_ .Z.
	rcall Check_bit1
	POINT ut1_
	rcall DisplayC
	MOVLF 13,counter17
    REPEAT_
	rcall Reader1
	decf counter17,F
    UNTIL_ .Z.
	decf counter14,F
    UNTIL_ .Z.
	POINT bd 
	rcall DisplayC
	MOVLF 8,counter18
    REPEAT_
	rcall Reader
	decf counter18,F
    UNTIL_ .Z.
	POINT wi
	rcall DisplayC
	POINT wi1
	rcall DisplayC
	rcall Delayloop
	rcall Delayloop
	bcf INTCON,INT0IF
    ENDWHILE_
	goto Mainline
return	
    
Level_3				;Lvl3 with the new edited scene
    WHILE_ INTCON,INT0IF==1
	MOVLF B'00011110',PORTA	;RA3, RA2, and RA1 LED on 
	POINT lvl3
	rcall DisplayC
	MOVLF 5,counter4
    REPEAT_
	MOVLF 6,counter5
	POINT Lvl3
	rcall DisplayC
    REPEAT_
	rcall Reader1
	decf counter5,F
    UNTIL_ .Z.
	rcall Check_bit
	MOVLF 4,counter6
	POINT jm
	rcall DisplayC
    REPEAT_
	rcall Reader1
	decf counter6,F
    UNTIL_ .Z.
	rcall Check_bit2	;Check attacking button status 
	MOVLF 10,counter7
	POINT ma
	rcall DisplayC
    REPEAT_
	rcall Reader1
	decf counter7,F
    UNTIL_ .Z.
	rcall Check_bit
	MOVLF 4,counter8
	POINT jm1_
	rcall DisplayC
    REPEAT_
	rcall Reader1
	decf counter8,F
    UNTIL_ .Z.
	rcall Check_bit2
	MOVLF 10,counter9
	POINT ma1_
	rcall DisplayC
    REPEAT_
	rcall Reader1
	decf counter9,F
    UNTIL_ .Z.
	rcall Check_bit
	MOVLF 2,counter10
	POINT jm2_
	rcall DisplayC
    REPEAT_
	rcall Reader1
	decf counter10,F
    UNTIL_ .Z.
	rcall Check_bit
	MOVLF 4,counter11
	POINT jm3_
	rcall DisplayC
    REPEAT_
	rcall Reader1
	decf counter11,F
    UNTIL_ .Z.
	decf counter4,F
    UNTIL_ .Z.
	POINT ba2
	rcall DisplayC
	POINT ba3
	rcall DisplayC
	rcall Delayloop
	MOVLF 8,counter12	
    REPEAT_
	POINT bs3_		    ;Different attacking method of boss
	rcall DisplayC
	MOVLF 13,counter13
    REPEAT_
	rcall Reader1
	decf counter13,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT bj
	rcall DisplayC
	MOVLF 2,counter14
    REPEAT_
	rcall Reader1
	decf counter14,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT bj1_
	rcall DisplayC
	MOVLF 3,counter15
    REPEAT_
	rcall Reader1
	decf counter15,F
    UNTIL_ .Z.
	rcall Check_bit
	POINT bj2_
	rcall DisplayC
	MOVLF 2,counter16
    REPEAT_
	rcall Reader1
	decf counter16,F
    UNTIL_ .Z.
	rcall Check_bit1
	POINT bj3_
	rcall DisplayC
	MOVLF 12,counter17
    REPEAT_
	rcall Reader1
	decf counter17,F
    UNTIL_ .Z.
	decf counter12,F
    UNTIL_ .Z.
	POINT bd 
	rcall DisplayC
	MOVLF 8,counter18
    REPEAT_
	rcall Reader
	decf counter18,F
    UNTIL_ .Z.
	POINT wi
	rcall DisplayC
	POINT wi1
	rcall DisplayC
	rcall Delayloop
	rcall Delayloop
	bcf INTCON,INT0IF
    ENDWHILE_
	goto Mainline
return	
	
;;;;;;;;;constant strings;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LCDstr dB 0x33,0x32,0x28,0x01,0x0c,0x06,0x00   ;Initialization string for LCD
message dB "\x80       H\x00"		   
message1 dB "\x80      He\x00"
message2 dB "\x80     Hel\x00"
message3 dB "\x80    Hell\x00"
message4 dB "\x80   Hello\x00"
message5 dB "\x80  Hello!\x00"
message6 dB "\x80 Hello! \x00"
message7 dB "\x80Hello! W\x00"
message8 dB "\x80ello! We\x00"
message9 dB "\x80llo! Wel\x00"
message10 dB "\x80lo! Welc\x00"
message11 dB "\x80o! Welco\x00"
message12 dB "\x80! Welcom\x00"
message13 dB "\x80 Welcome\x00"
message14 dB "\x80Welcome \x00"
message15 dB "\x80elcome T\x00"  
message16 dB "\x80lcome To\x00"
message17 dB "\x80come To \x00"
message18 dB "\x80ome To P\x00"
message19 dB "\x80me To Pl\x00"
message20 dB "\x80e To Pla\x00"
message21 dB "\x80 To Play\x00"
message22 dB "\x80To Play \x00"
message23 dB "\x80o Play S\x00"
message24 dB "\x80 Play Su\x00"
message25 dB "\x80Play Sur\x00"
message26 dB "\x80lay Surv\x00"
message27 dB "\x80ay Survi\x00"
message28 dB "\x80y Surviv\x00"
message29 dB "\x80 Survivo\x00"
message30 dB "\x80Survivor\x00"
message32 dB "\x80Survivor\x00"
message33 dB "\x80Survivor\x00"  
message34 dB "\x80       P\x00"
message35 dB "\x80      Pu\x00"
message36 dB "\x80     Pus\x00"
message37 dB "\x80    Push\x00"
message38 dB "\x80   Push \x00"
message39 dB "\x80  Push t\x00"
message40 dB "\x80 Push th\x00"
message41 dB "\x80Push the\x00"
message42 dB "\x80ush the \x00"
message43 dB "\x80sh the B\x00"
message44 dB "\x80h the Bu\x00"
message45 dB "\x80 the But\x00"
message46 dB "\x80the Butt\x00"
message47 dB "\x80he Butto\x00"
message48 dB "\x80e Button\x00"
message49 dB "\x80 Button \x00"
message50 dB "\x80Button t\x00"
message51 dB "\x80utton to\x00"		    
message52 dB "\x80tton to \x00"
message53 dB "\x80ton to S\x00"
message54 dB "\x80on to St\x00"
message55 dB "\x80n to Sta\x00"
message56 dB "\x80 to Star\x00"
message57 dB "\x80to Start\x00"
message58 dB "\x80o Start!\x00"
message59 dB "\x80 Start! \x00"		    ;Welcome messages
message60 dB 0x00
 
mes dB "\x80Choose a\x00"
mes1 dB "\x80hoose a \x00"
mes2 dB "\x80oose a l\x00"
mes3 dB "\x80ose a le\x00"
mes4 dB "\x80se a lev\x00"
mes5 dB "\x80e a leve\x00"
mes6 dB "\x80 a level\x00"
mes7 dB "\x80a level \x00"
mes8 dB "\x80 level f\x00"
mes9  dB "\x80level fr\x00"
mes10 dB "\x80evel fro\x00"
mes11 dB "\x80vel from\x00"
mes12 dB "\x80el from \x00"
mes13 dB "\x80l from 1\x00"
mes14 dB "\x80 from 1-\x00"
mes15 dB "\x80from 1-3\x00" 
mes16 dB "\x80rom 1-3:\x00"
mes17 dB "\x80rom 1-3:\x00"		    ;Lvl options messages
mes18 dB "\x80rom 1-3:\x00"  
mes19 dB 0x00
   
lvl1n2_ dB "\x80&  _ $ _\x00"
lvl1n2_1 dB "\xc0  _   _ \x00"
lvl1n2_2 dB "\x80& _ $ _ \x00"		    ;Beginning of lvl1
lvl1n2_3 dB "\xc0 _   _  \x00"
lvl1n2_4 dB "\x80&_ $ _ _\x00" 
lvl1n2_5 dB "\xc0_   _  $\x00"
lvl1n2_6 dB 0x00 
 
jp dB "\x80_ $ _ _ \x00"
jp1 dB "\xc0&  _  $ \x00"
jp2 dB "\x80 $ _ _  \x00"
jp3 dB "\xc0& _  $ _\x00"		    ;First jump
jp4 dB "\x80$ _ _  $\x00"
jp5 dB "\xc0&_ $ _  \x00"
jp6 dB 0x00 
 
jp1_ dB "\xc0_ $ _  _\x00"		    ;Secone jump
jp1_1 dB "\x80&_ _  $ \x00"
jp1_2 dB 0x00
 
jp2_ dB "\x80_ _  $ _\x00"
jp2_2 dB "\xc0&$ _  _ \x00"
jp2_4 dB "\x80 _  $ _ \x00"
jp2_5 dB "\xc0& _  _ $\x00"
jp2_6 dB "\x80_  $ _ $\x00"
jp2_7 dB "\xc0&_  _ $ \x00"		    ;Third jump
jp2_8 dB 0x00
 
jp3_ dB "\xc0_  _ $ _\x00"
jp3_1 dB "\x80& $ _ $ \x00"
jp3_2 dB "\xc0  _ $ _ \x00"
jp3_3 dB "\x80&$ _ $ _\x00"
jp3_4 dB "\xc0 _ $ _ $\x00"		    ;Fourth jump
jp3_5 dB "\x80& _ $ _ \x00"
jp3_6 dB "\xc0_ $ _ $ \x00" 
jp3_7 dB "\x80&_ $ _  \x00"
jp3_8 dB 0x00
 
jp4_ dB "\x80_ $ _  _\x00"
jp4_1 dB "\xc0&$ _ $  \x00" 
jp4_2 dB "\x80 $ _  _ \x00"		    ;Fifth jump
jp4_3 dB "\xc0& _ $  _\x00"
jp4_4 dB "\x80$ _  _  \x00"
jp4_5 dB "\xc0&_ $  _ \x00"  
jp4_6 dB 0x00 
 
jp5_ dB "\xc0_ $  _  \x00"   
jp5_1 dB "\x80&_  _  $\x00"		    ;Sixth jump
jp5_2 dB 0x00
 
jp6_ dB "\x80_  _  $ \x00"
jp6_1 dB "\xc0&$  _   \x00" 
jp6_2 dB "\x80  _ $   \x00"
jp6_3 dB "\xc0&  _   _\x00"		    ;Seventh jump
jp6_4 dB "\x80 _ $   _\x00"
jp6_5 dB "\xc0& _   _ \x00"
jp6_6 dB "\x80_ $   _ \x00"
jp6_7 dB "\xc0&_   _  \x00"  
jp6_8 dB 0x00 
 
jp7_ dB "\xc0 _   _  \x00"   
jp7_1 dB "\x80&$   _ $\x00"		    ;Eighth jump
jp7_2 dB "\xc0_   _   \x00"
jp7_3 dB "\x80&   _ $ \x00"
jp7_4 dB "\xc0   _   _\x00"		    ;4 coins for one runs
jp7_5 dB 0x00
 
bs dB "\x80&     <>\x00"
bs1 dB "\xc0      <>\x00"		    
bs2 dB "\x80&    -<>\x00"
bs3 dB "\xc0      <>\x00"
bs4 dB "\x80&   --<>\x00"
bs5 dB "\xc0      <>\x00"		    ;Boss appeared and attacking 
bs6 dB "\x80&  ---<>\x00"
bs7 dB "\xc0      <>\x00"
bs8 dB "\x80& --- <>\x00"
bs9 dB "\xc0      <>\x00"
bs10 dB "\x80&---  <>\x00"
bs11 dB "\xc0      <>\x00"   
bs12 dB 0x00 
 
ut dB "\x80---   <>\x00"
ut1 dB "\xc0&~    <>\x00"
ut2 dB "\x80--    <>\x00"		    
ut3 dB "\xc0& ~   <>\x00"
ut4 dB "\x80-     <>\x00"
ut5 dB "\xc0&  ~  <>\x00"
ut6 dB "\x80      <>\x00"
ut7 dB "\xc0&   ~ <>\x00"
ut8 dB "\x80      <>\x00"
ut9 dB "\xc0&    ~<>\x00"
ut10 dB "\x80      <>\x00"
ut11 dB "\xc0&     *>\x00"
ut12 dB "\x80      <>\x00"
ut13 dB "\xc0&    -<>\x00"
ut14 dB "\x80      <>\x00"		    ;Users first jump and attacking
ut15 dB "\xc0&   --<>\x00"
ut16 dB "\x80      <>\x00"
ut17 dB "\xc0&  ---<>\x00"
ut18 dB "\x80      <>\x00"
ut19 dB "\xc0& --- <>\x00"
ut20 dB "\x80      <>\x00"
ut21 dB "\xc0&---  <>\x00"  
ut22 dB 0x00 
 
ut1_ dB "\xc0 ---  <>\x00"   
ut1_1 dB "\x80&~    <>\x00"
ut1_2 dB "\xc0---   <>\x00" 
ut1_3 dB "\x80& ~   <>\x00"
ut1_4 dB "\xc0--    <>\x00"
ut1_5 dB "\x80&  ~  <>\x00"
ut1_6 dB "\xc0-     <>\x00"
ut1_7 dB "\x80&   ~ <>\x00"
ut1_8 dB "\xc0      <>\x00"
ut1_9 dB "\x80&    ~<>\x00"		    ;Users second jump and attacking 
ut1_10 dB "\xc0      <>\x00"
ut1_11 dB "\x80&     *>\x00"
ut1_12 dB "\xc0      <>\x00" 
ut1_13 dB 0x00
 
Lvl3 dB "\x80&  _   $\x00"
Lvl3_1 dB "\xc0 _  $  @\x00"
Lvl3_2 dB "\x80& _   $ \x00"
Lvl3_3 dB "\xc0_  $  @ \x00"
Lvl3_4 dB "\x80&_   $ _\x00"
Lvl3_5 dB "\xc0  $  @  \x00"		    ;The beginning of lvl3
Lvl3_6 dB 0x00
 
jm dB "\x80_   $ _ \x00"
jm1 dB "\xc0& $  @ _\x00"
jm2 dB "\x80   $ _  \x00"		    ;First jump
jm3 dB "\xc0&$  @ _ \x00" 
jm4 dB 0x00
 
ma dB "\x80  $ _  $\x00"
ma1 dB "\xc0&~ @ _ $\x00"
ma2 dB "\x80 $ _  $ \x00"
ma3 dB "\xc0& * _ $ \x00"
ma4 dB "\x80$ _  $  \x00"		    ;User attacking the little monster
ma5 dB "\xc0&  _ $ _\x00"
ma6 dB "\x80 _  $  @\x00"
ma7 dB "\xc0& _ $ _ \x00"
ma8 dB "\x80_  $  @ \x00"
ma9 dB "\xc0&_ $ _ $\x00"
ma10 dB 0x00
 
jm1_ dB "\xc0_ $ _ $ \x00"
jm1_1 dB "\x80& $  @ _\x00"		    ;Second jump
jm1_2 dB "\x80&$  @ _ \x00"
jm1_3 dB "\xc0 $ _ $ _\x00"
jm1_4 dB 0x00
 
ma1_ dB "\x80&~ @ _  \x00"
ma1_1 dB "\xc0$ _ $ _ \x00"		    
ma1_2 dB "\x80& * _  $\x00"
ma1_3 dB "\xc0 _ $ _  \x00"
ma1_4 dB "\x80&  _  $ \x00"
ma1_5 dB "\xc0_ $ _  _\x00"		    ;Second time of attacking 
ma1_6 dB "\x80& _  $  \x00"
ma1_7 dB "\xc0 $ _  _ \x00"
ma1_8 dB "\x80&_  $  _\x00"
ma1_9 dB "\xc0$ _  _  \x00" 
ma1_10 dB 0x00
 
jm2_ dB "\x80_  $  _ \x00"
jm2_1 dB "\xc0&_  _  \x00"		    ;Third jump
jm2_2 dB 0x00
 
jm3_ dB "\xc0_  _  $ \x00"
jm3_1 dB "\x80& $  _  \x00"
jm3_2 dB "\xc0  _  $  \x00"		    ;Fourth jump
jm3_3 dB "\x80&$  _   \x00" 
jm3_4 dB 0x00
 
bs3_ dB "\x80&     <>\x00"
bs3_1 dB "\xc0      <>\x00"
bs3_2 dB "\x80&   -<> \x00"		    
bs3_3 dB "\xc0      <>\x00"
bs3_4 dB "\x80&  -  <>\x00"
bs3_5 dB "\xc0    -<> \x00"
bs3_6 dB "\xc0    - <>\x00" 
bs3_7 dB "\x80& - -<> \x00"		    ;Boss appeared and attacking with the diffrent way
bs3_8 dB "\xc0   -  <>\x00"
bs3_9 dB "\x80& - - <>\x00"
bs3_10 dB "\xc0  - -<> \x00"
bs3_11 dB "\x80&- -  <>\x00"
bs3_12 dB "\xc0  - - <>\x00" 
bs3_13 dB 0x00


bj dB "\x80- -   <>\x00"
bj1 dB "\xc0&- -  <>\x00"		    ;First jump
bj2 dB 0x00
 
bj1_ dB "\xc0 - -  <>\x00" 
bj1_1 dB "\x80&-    <>\x00"
bj1_2 dB "\xc0- -   <>\x00"		    ;Second jump
bj1_3 dB 0x00 

bj2_ dB "\x80-     <>\x00"
bj2_1 dB "\xc0&-    <>\x00"		    ;Third jump
bj2_2 dB 0x00
 
bj3_ dB "\xc0 -    <>\x00" 
bj3_1 dB "\x80&~    <>\x00"		    ;Fourth jump with attacking 
bj3_2 dB "\xc0-     <>\x00" 
bj3_3 dB "\x80& ~   <>\x00"
bj3_4 dB "\xc0      <>\x00" 
bj3_5 dB "\x80&  ~  <>\x00"
bj3_6 dB "\xc0      <>\x00" 
bj3_7 dB "\x80&   ~ <>\x00"
bj3_8 dB "\xc0      <>\x00" 
bj3_9 dB "\x80&    ~<>\x00"
bj3_10 dB "\xc0      <>\x00" 
bj3_11 dB "\x80&     *>\x00"  
bj3_12 dB 0x00 

bd dB "\x80      *>\x00"
bd1 dB "\xc0      <>\x00"
bd2 dB "\x80      *>\x00"
bd3 dB "\xc0      <*\x00"
bd4 dB "\x80      **\x00"		    ;Boss destroyed 
bd5 dB "\xc0      <*\x00"
bd6 dB "\x80      **\x00"
bd7 dB "\xc0      **\x00"  
bd8 dB 0x00 
 
lvl1 dB "\x80Level 1 \x00"		    
lvl1_1 dB 0x00
 
lvl2 db "\x80Level 2 \x00"
lvl2_1 dB 0x00
 
lvl3 dB "\x80Level 3 \x00"
lvl3_1 dB 0x00
 
ba dB "\x808 Coins\x00" 
ba1 dB "\x8012 Coins\x00"
ba2 dB "\x8015 Coins\x00"
ba3 dB "\xc0Boss Up \x00"
ba4 dB 0x00 
 
wi dB "\x80You     \x00"
wi1 dB "\xc0     Won\x00"
wi2 dB 0x00 
 
fi dB "\x80Game    \x00"
fi1 dB "\xc0    Over\x00" 
fi2 dB 0x00 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
end


