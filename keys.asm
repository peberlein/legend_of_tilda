* Set keyboard lines in R1 to CRU
SETCRU
       MOV *R11+,R1    ; Get output line from callers DATA
       LI R12,>0024    ; Select address lines starting at line 18
       LDCR R1,3       ; Send 3 bits to set one 8 of output lines enabled
       LI R12,>0006    ; Select address lines to read starting at line 3
       RT

* Read keys and joystick into KEY_FL
* Modifies R0-2,R10,R12
DOKEYS
       MOV R11,R10     ; Save return address
       .IFDEF GENEVE

       BLWP @GENKEY    ; Geneve key scan

       .ELSE
       CLR R0
       BL @SETCRU
       DATA >0000
       TB 2            ; Test Enter
       JEQ !
       ORI R0, KEY_A
!      BL @SETCRU
       DATA >0100
       TB 5            ; Test S
       JEQ !
       ORI R0, KEY_DN
!      TB 6            ; Test W
       JEQ !
       ORI R0, KEY_UP
!      BL @SETCRU
       DATA >0200
       TB 5            ; Test D
       JEQ !
       ORI R0, KEY_RT
!      TB 6            ; Test E
       JEQ !
       ORI R0, KEY_B
!      BL @SETCRU
       DATA >0500
       TB 0            ; Test Slash
       JEQ !
       ORI R0, KEY_C
!      TB 1            ; Test Semicolon
       JEQ !
       ORI R0, KEY_B
!      TB 5            ; Test A
       JEQ !
       ORI R0, KEY_LT
!      TB 6            ; Test Q
       JEQ !
       ORI R0, KEY_C
!      BL @SETCRU
       DATA >0600
       TB 0            ; Test J1 Fire
       JEQ !
       ORI R0, KEY_A
!      TB 1            ; Test J1 Left
       JEQ !
       ORI R0, KEY_LT
!      TB 2            ; Test J1 Right
       JEQ !
       ORI R0, KEY_RT
!      TB 3            ; Test J1 Down
       JEQ !
       ORI R0, KEY_DN
!      TB 4            ; Test J1 Up
       JEQ !
       ORI R0, KEY_UP
!      BL @SETCRU
       DATA >0700
       TB 0            ; Test J2 Fire
       JEQ !
       ORI R0, KEY_B
!      TB 1            ; Test J2 Left
       JEQ !
       ORI R0, KEY_A
!      TB 2            ; Test J2 Right
       JEQ !
       ORI R0, KEY_C
!      TB 3            ; Test J2 Down
       JEQ !
       ORI R0, KEY_B
!      TB 4            ; Test J2 Up
       JEQ !
       ORI R0, KEY_C
!

       .ENDIF

       ; Calculate edges
       MOV R0,R1
       XOR @KEY_FL,R1
       INV R0
       SZC R0,R1
       INV R0
       SLA R1,8
       SOC R1,R0
       MOV R0,@KEY_FL

       B *R10  ; Return to saved address


*R1     TB 0  TB 1  TB 2  TB 3  TB 4  TB 5  TB 6  TB 7
*0000   =     space enter fctn  shift ctrl
*0100   .     L     O     9     2     S     W     X
*0200   ,     K     I     8     3     D     E     C
*0300   M     J     U     7     4     F     R     V
*0400   N     H     Y     6     5     G     T     B
*0500   /     ;     P     0     1     A     Q     Z
*0600   Fire  Left  Right Down  Up  (Joystick 1)
*0700   Fire  Left  Right Down  Up  (Joystick 2)


