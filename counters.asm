* Increment counters (And animate fire, and inc/dec rupees)
* Modifies R0-R13
COUNT
       MOV @COUNTR,R0
       AI R0,->1120  ; Add -1 to left 3 counters
       CI R0,>1000   ; Left nibble 0?
       JHE !
       AI R0,>6000   ; Add 6

!      MOV R0,R1
       ANDI R1,>0F00 ; Right nibble 0?
       JNE !
       AI R0,>0B00   ; Add 11
!      MOV R0,R1
       ANDI R1,>00E0 ; 5 bit counter 0?
       JNE !
       AI R0,>00A0   ; Add 5
!      INC R0
       ANDI R0,>FFEF
       MOV R0,@COUNTR

       ANDI R0,>0003    ; Every 4 frames
       JNE !

       LI R13,x#FFANIM     ; Animate fire + fairy sub-function
       B @BANK1  ; return thru bank switch


!      ; R0 = 1,2 or 3
       DECT R0
       JEQ  !    ; return if R0 was 2
       ; R0 was 1 or 3 (every other frame)
       MOV @RUPEES,R2
       JNE !!
!      RT
!      ; R2 is non-zero
       MOV R11,R13     ; save return address
       LI R0,SDRUPE
       BL @VDPRB       ; R1 = current rupees

       MOV R2,R2
       JGT !
       ; negative
       INC @RUPEES     ; toward zero
       AI R1,->100     ; dec rupees  (be careful not to set RUPEES negative when SDRUPE is zero)
       JGT !!
       CLR R1          ; set min rupees
       JMP CLRRUP

!      ; positive
       DEC @RUPEES     ; toward zero
       AI R1,>100      ; inc rupees
       JNC !
       SETO R1    ; set max rupees

CLRRUP
       CLR @RUPEES   ; don't add any more if min or max

!      BL @VDPWB     ; store updated rupee count

       LI R1,x#TSF181      ; Rupee sound effect
       MOV R1,@SOUND2

       MOV R13,R11  ; return to saved address
       LI R13,x#STATUS
       B @BANK5     ; return thru bank switch


