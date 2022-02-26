;Alaa Zuhd - 1180865
;Rawan Yassin - 1182224
PROCESSOR 16F877	; Define MCU type
__CONFIG 0x3731		; Set config fuses

org 0x00 ;This is where we come on power up and reset
;*******************SETUP CONSTANTS*******************
INTCON      EQU 0x0B ;Interrupt Control Register
PORTB       EQU 0x06 ;Port B register address
PORTD       EQU 0x08 ;Port D register address
TRISB       EQU 0x86 ;TrisB register address
TRISD       EQU 0x88 ;TrisD register address
STATUS      EQU 0X03 ;Status register address
C1          EQU 0x20 ;Used for Delay function
C2          EQU 0x21 ;Used for Delay function
C3          EQU 0x22 ;Used for Delay function
COUNT       EQU 0x23 ;This will be our counting variable
TEMP        EQU 0x24 ;Temporary store for w register
IncrementBy EQU 0x25 ;The amount of increment, will be edited using ISR of Push button_1 
DelayBy     EQU 0x26 ;The amount of outer variable for the delay function, whenever it is incremented, delays get incremented as well
Flag        EQU 0x27 ;Dummy variable

GOTO main ;Jump over the interrupt address

;***************INTERRUPT ROUTINE***************
ORG 0x04 ;This is where PC points on an interrupt
NOP
MOVWF TEMP ;Store the value of w temporarily

;If bit 0 of INTCON (RBIF) is set, this means that RB4 is set, and delay interrupt is activated. 
BTFSC INTCON, 0
GOTO INCREMENT_DELAY
;If RBIF is not set, then RB0 may be the one activating the interrupt, and asking for an increment in the amount of increment
BTFSS PORTB, 0
GOTO DONE
;Increment_incrementby, aims to add the 'INCREMENTBY' variable by one, until it reaches 6, then it is set back to 1
INCREMENT_INCREMENTBY
MOVLW 0x01
ADDWF IncrementBy, F
BTFSC IncrementBy, 2
GOTO CHECK_SECOND_BIT
GOTO DONE
CHECK_SECOND_BIT
BTFSS IncrementBy, 1
GOTO DONE
MOVLW D'1'
MOVWF IncrementBy

GOTO DONE

;Increment_delay, aims to add 4 to the 'DelayBy' variable, as this variable is used as the variable for the outer loop in 
;the delay function, and whenever it is incremented by 4, a new second would be added as a result in the delay function.
;it would keep incrementing 'DelayBy' until it reaches 24 
INCREMENT_DELAY
;Just a simple check to make sure that RB4 is set, the port reading from the push button
BTFSC PORTB, 4
GOTO DONE
MOVLW 0x04
ADDWF DelayBy, F
BTFSC DelayBy, 4
GOTO CHECK_FOURTH_BIT
GOTO DONE
CHECK_FOURTH_BIT
BTFSS DelayBy, 3
GOTO DONE
MOVLW D'4'
MOVWF DelayBy

DONE


MOVFW TEMP ;Restore w to the value before the interrupt
BCF INTCON,0 ;RBIF - Clear FLag Bit Just In Case
BCF INTCON,1 ;INTF - Clear FLag Bit Just In Case

RETFIE ;Come out of the interrupt routine

SHOW 	MOVF COUNT, w     ; move the current count to W
		MOVWF	PORTD	   ; update PORTC to reflect the current count
		RETURN

DELAY   ; 1SEC = 4, 2SEC = 8, 3SEC = 12, 4SEC = 16, 5SEC = 20.
		MOVF DelayBy, W 
		MOVWF C3
		LOOP3
		MOVLW D'200'
		MOVWF C2
		LOOP2
		MOVLW D'230'
		MOVWF C1
		LOOP
		NOP
		NOP 
		DECFSZ C1, F
		GOTO LOOP
		DECFSZ C2, F
		GOTO LOOP2
		DECFSZ C3, F
		GOTO LOOP3
		RETURN

;*******************Main Program*********************
main

;*******************Set Up The Ports******************
BSF STATUS,5 ;Switch to Bank 1
MOVLW 0x11
MOVWF TRISB ;Set RB0 as input
MOVLW 0x00
MOVWF TRISD ;Set PortD as output
BCF STATUS,5 ;Come back to Bank 0

MOVLW 0x11
MOVWF PORTB


;*******************Set Up The Interrupt Registers****
BSF INTCON,7 ;GIE – Global interrupt enable (1=enable)
BSF INTCON,6 ;
BSF INTCON,4 ;INTE - RB0 Interrupt Enable (1=enable)
BCF INTCON,1 ;INTF - Clear FLag Bit Just In Case
BCF INTCON,0 ;RBIF - Clear FLag Bit for Port B Just In Case
BSF INTCON,3;INTE - RB Port Change Interrupt Enable (1=enable)

; clear PORTD
MOVLW 0x00
MOVWF PORTD

; initilization 
MOVLW 0x00
MOVWF COUNT
MOVLW 0x01
MOVWF IncrementBy
MOVLW D'4'
MOVWF DelayBy
MOVLW D'0'
MOVWF Flag

NOP

; DISPLAHY THE FIRST COUNT (ZERO)
CALL SHOW ; TO SHOW 0
CALL DELAY

;Counting loop, will go through the numbers from 0 to 31, unless there is an interrupt
COUNTING
MOVF IncrementBy, W    ; move the current increment by to W
ADDWF COUNT, W		   ; add the IncrementBy value to count
MOVWF COUNT 
BTFSC COUNT, 5		   ;if 32 is reached we go back to zero
GOTO RESET_COUNT
GOTO CALL_SHOW
RESET_COUNT
MOVLW 0x20
SUBWF COUNT, F
CALL_SHOW
CALL SHOW
;Delay is called after each SHOW call is performed
CALL DELAY
GOTO COUNTING ;Keep on doing this

END ;End Of Program