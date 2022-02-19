; Archivo:	Prelab4.s
; Dispositivo:	PIC16F887
; Autor:	Carolina Paz 20719
; Compilador:	pic-as (v2.30), MPLABX V5.40
; 
; Programa:	Presionar RB0  o RB7 para inc o dec usando interrupciones
; Hardware:	Botones en RB0 y RB7
;
; Creado:	13 feb, 2022
; Última modificación: 14 feb, 2022
    
PROCESSOR 16F887
    
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

Timer_reset MACRO TMR_VAR
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   TMR_VAR
    MOVWF   TMR0	    ; configur¿ tiempo de retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    ENDM 
  
UP    EQU 0
DOWN  EQU 7
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		  ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
    
PSECT udata_bank0         ;reservar memoria
    cont:		DS 1
    cont2:		DS 1
    cont3:              DS 1
    
PSECT resVect, class=CODE, abs, delta=2
ORG 00h	    ; posición 0000h para el reset
;------------ VECTOR RESET --------------
resetVec:
    PAGESEL Main	  ; Cambio de pagina
    GOTO    Main

PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
    
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    BTFSC   RBIF
    CALL    INT_ONC
    
    BTFSC   T0IF	    
    CALL    INT_TMR0	    
     
POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal  
    
PSECT code, delta=2, abs
ORG 100h                  ; posición 100h para el codigo
 
 
;-------------SUBRUTINA DE INTERRUPCION--------
INT_ONC:
    BANKSEL PORTB
    BTFSS   PORTB, UP	  ; Ver si botón ya no está presionado
    INCF    PORTA  
    BTFSS   PORTB, DOWN	  ; Ver si botón ya no está presionado
    DECF    PORTA  
    BCF     RBIF
    RETURN
     
INT_TMR0:
    Timer_reset	217
    CALL        Unidades
    CALL        Decenas
    INCF	cont
    MOVF	cont, W	
    SUBLW	100	    
    BTFSS	STATUS, 2
    RETURN
    CALL        Display1
    CLRF	cont
    RETURN

;-----------Tablas---------------------------
Tabla:
   CLRF    PCLATH	  ; Limpiamos registro PCLATH
   BSF	   PCLATH, 0	  ; Posicionamos el PC en dirección 02xxh
   ANDLW   0x0F		  ; No saltar más del tamaño de la tabla
   ADDWF   PCL , F	  ; Apuntamos el PC a caracter  PC= PCLATH+PCL +W
   RETLW   00111111B	  ; ASCII char 0
   RETLW   00000110B	  ; ASCII char 1
   RETLW   01011011B	  ; ASCII char 2
   RETLW   01001111B	  ; ASCII char 3
   RETLW   01100110B	  ; ASCII char 4
   RETLW   01101101B	  ; ASCII char 5
   RETLW   01111101B	  ; ASCII char 6
   RETLW   00000111B	  ; ASCII char 7
   RETLW   01111111B	  ; ASCII char 8
   RETLW   01101111B	  ; ASCII char 9
   RETLW   00111111B	  ; ASCII char 0
   
Tabla2:
   CLRF    PCLATH	  ; Limpiamos registro PCLATH
   BSF	   PCLATH, 0	  ; Posicionamos el PC en dirección 02xxh
   ANDLW   0x0F		  ; No saltar más del tamaño de la tabla
   ADDWF   PCL , F	  ; Apuntamos el PC a caracter  PC= PCLATH+PCL +W
   RETLW   00111111B	  ; ASCII char 0
   RETLW   00000110B	  ; ASCII char 1
   RETLW   01011011B	  ; ASCII char 2
   RETLW   01001111B	  ; ASCII char 3
   RETLW   01100110B	  ; ASCII char 4
   RETLW   01101101B	  ; ASCII char 5
   ;RETLW   01111101B	  ; ASCII char 6
   ;RETLW   00000111B	  ; ASCII char 7
   ;RETLW   01111111B	  ; ASCII char 8
   ;RETLW   01101111B	  ; ASCII char 9
   RETLW   00111111B	  ; ASCII char 0
   

;------------- CONFIGURACION -----------------
Main:
    CALL    IO_config	  ; Configuración de I/O
    CALL    Reloj_config   ; Configuración de Oscilador
    CALL    Timer0_config  ; Configuración de TMR0
    CALL    ONC_config
    CALL    INT_config
    BANKSEL PORTB
       
;----------------loop principal-----------------
Loop:
    goto Loop
    
;------------- SUBRUTINAS ---------------
IO_config:
    BANKSEL ANSEL	  ; Cambiar de Banco
    CLRF    ANSEL
    CLRF    ANSELH	  ; Poner I/O digitales
    
    BANKSEL TRISA	  ; Cambiar de Banco de TRISA
    CLRF    TRISA
    MOVLW   0xF0	  ; Pasar el número a W
    MOVWF   TRISA	  ; Mover w a TRISA , definir como salida
    BSF     TRISB, UP	  ; poner como entradas
    BSF     TRISB, DOWN
    CLRF    TRISC	  ; Poner como salida
    CLRF    TRISD	  ; Poner como salida
    
    BCF  OPTION_REG, 7
    BSF  WPUB, UP	;habilitar pull-ups
    BSF  WPUB, DOWN
      
    ;MOVLW   0xFF          ; Pasar el número a W
    ;MOVWF   TRISB         ; Mover w a TRISB , definir como salida
    
    BANKSEL PORTA	  ; Cambiar de Banco
    CLRF    PORTA	  ; Limpiar PORTA
    CLRF    PORTC
    CLRF    PORTD
    RETURN
    
Reloj_config:
   BANKSEL  OSCCON        ; cambiamos a banco 1
   BSF	    SCS	          ; SCS =1, Usamos reloj interno
   BSF	    IRCF2         ; IRCF 1
   BSF	    IRCF1         ; IRCF 1
   BCF	    IRCF0         ; IRCF 0 --> 110 4MHz
   RETURN
   

Timer0_config:
   BANKSEL  OPTION_REG	  ; cambiamos de banco de OPTION_REG
   BCF	    T0CS	  ; Timer0 como temporizador
   BCF	    PSA   	  ; Prescaler a TIMER0
   BSF	    PS2	          ; PS2
   BSF	    PS1	          ; PS1
   BSF	    PS0	          ; PS0 Prescaler de 1 : 256
    
   BANKSEL  TMR0	  ; cambiamos de banco de TMR0
   MOVLW    217		  ; 10ms = 4*1/4MHz*(256-x)(256)
   MOVWF    TMR0	  ; 10ms de retardo
   BCF	    T0IF	  ; limpiamos bandera de interrupción
   RETURN 

ONC_config:
    BANKSEL TRISA
    BSF     IOCB, UP
    BSF     IOCB, DOWN
    
    BANKSEL PORTA
    MOVF    PORTB, W	    ; Al leer termina condición de mismatch
    BCF     RBIF 
    RETURN
   
INT_config:
   BANKSEL INTCON
   BSF	    GIE		    ; Habilitamos interrupciones
   BSF	    RBIE	    ; Habilitamos interrupcion PUERTOB
   BCF	    RBIF	    ; Limpiamos bandera de TMR0
   BSF	    T0IE	    ; Habilitamos interrupcion TMR
   BCF	    T0IF	    ; Limpiamos bandera de TMR0
   RETURN

Display1:
   INCF   cont2         ; Incrementar 1 y se almacena en el registro F
   MOVF   cont2, W         ; mover el valor a w
   CALL   Tabla	          ; Llamar a tabla
   MOVWF  PORTD         ; resultado pasa al PORTD
   RETURN
   
Display2:
   INCF   cont3         ; Incrementar 1 y se almacena en el registro F
   MOVF   cont3, W         ; mover el valor a w
   CALL   Tabla2	          ; Llamar a tabla
   MOVWF  PORTC        ; resultado pasa al PORTC
   RETURN
   
Unidades:
   MOVLW   10		  ; mover una literal al registro W
   SUBWF   cont2, W	  ; Se resta 10 del valor del contador 1
   BTFSS   STATUS, 2	  ; Se verifica si la bandera de zero está encendida
   RETURN		  ; Si es 0
   CLRF    cont2          ; limpiar el cont1
   CALL    Display2
   RETURN
   
Decenas:
   MOVLW   6		  ; mover una literal al registro W
   SUBWF   cont3, W	  ; Se resta 10 del valor del contador 1
   BTFSS   STATUS, 2	  ; Se verifica si la bandera de zero está encendida
   RETURN		  ; Si es 0
   CLRF    cont3          ; limpiar el cont1
   RETURN  
   
   
  
END
