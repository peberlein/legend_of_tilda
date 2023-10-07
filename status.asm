
* Draw the byte number in R1 as (right-justified) [space][space]n or [space]nn or nnn
* Used for price underneath items in caves
* R0: VDP address (with VDPWM set)
* R1: number
* Modifies R0,R1
NUMBRJ
       MOVB @R0LB,*R14       ; Send low byte of VDP RAM write address
       MOVB R0,*R14          ; Send high byte of VDP RAM write address

       CI R1,>6400      ; R1 >= 100 decimal ?
       JHE NUMBE2
       LI R0,>2000
       MOVB R0,*R15     ; Write a space
       CI R1,>0A00      ; R1 < 10 decimal ?
       JL NUMBE4
       LI R0,>3000      ; 0 ascii
       JMP NUMBE3

* Draw the byte number in R1 as Xn[space] or Xnn or nnn
* R0: VDP address (with VDPWM set)
* R1: number
* Modifies R0,R1
NUMBER MOVB @R0LB,*R14       ; Send low byte of VDP RAM write address
       MOVB R0,*R14          ; Send high byte of VDP RAM write address

       CI R1, >6400  ; 100 decimal
       JHE NUMBE2
       LI R0, >5800           ; X ascii
       MOVB R0,*R15        ; Write X
       LI R0, >3000             ; 0 ascii
       CI R1, >A00   ; 10 decimal
       JHE NUMBE3
       A R0,R1
       MOVB R1,*R15        ; Write second digit
       LI R1, >2000
       MOVB R1,*R15           ; Write a space
       RT

NUMBE2 LI R0, >3100           ; 1 ascii
       AI R1, ->6400    ; R1 -= 100
       CI R1, >6400     ; R1 < 100 ?
       JL !
       AI R1, ->6400
       LI R0, >3200           ; 2 ascii
!      MOVB R0,*R15           ; Write first digit
       LI R0, >3000           ; 0 ascii
       JMP NUMBE3
!      AI R0,>100
       AI R1, ->A00        ; R1 -= 10
NUMBE3 CI R1, >A00         ; 10 decimal
       JHE -!
NUMBE4 MOVB R0,*R15        ; Write second digit
       AI R1, >3000        ; 0 ascii
       MOVB R1,*R15        ; Write final digit
       RT


* Draw number of rupees, keys, bombs and hearts
* Modifies R0-R3,R7-R12
STATUS MOV R11,R10         ; save return address

       MOV @FLAGS,R3
       ANDI R3,SCRFLG      ; R3 = current screen offset

       LI R0,SDRUPE
       BL @VDPRB           ; R1 = rupees from save data
       MOV R3,R0
       AI R0,VDPWM+SCR1TB+(32*0)+12  ; Write mask + screen offset + row 0 col 12
       BL @NUMBER             ; Write rupee count

       LI R0,SDKEYS
       BL @VDPRB           ; R1 = keys from save data
       MOV R3,R0
       AI R0,VDPWM+SCR1TB+(32*1)+12  ; Write mask + screen offset + row 1 col 12
       BL @NUMBER             ; Write keys count

       LI R0,SDBOMB
       BL @VDPRB              ; R1 = bombs from save data
       ANDI R1,>1F00          ; Mask 5 bits of bomb count
       MOV R3,R0
       AI R0,VDPWM+SCR1TB+(32*2)+12  ; Write mask + screen offset + row 2 col 12
       BL @NUMBER             ; Write bombs count

       LI R0,SDHART
       BL @VDPRB           ; R1 = max hearts from save data
       MOV  R1,R9          ; R9 = max hearts

       AI R3,VDPWM+SCR1TB+(32*2)+22  ; Write mask + screen offset + row 2 col 22
       ; R3 = lower left heart position
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
       AI R3,-32              ; R3 = upper left heart position

       MOV R10,R11        ; restore return address

       MOV  @HFLAG2,R0
       LI   R10,1             ; R10 = 1 hp per half-heart
       ANDI R0,BLURNG+REDRNG  ; test either ring
       JEQ  !
       A    R9,R9             ; double max hp
       INC  R10               ; R10 = 2 hp per half-heart
       ANDI R0,REDRNG         ; red ring
       JEQ  !
       A    R9,R9             ; double max hp again
       INCT R10               ; R10 = 4 hp per half-heart
!
       A    R9,R9             ; double max hp for half-hearts
       SWPB R10
       ;  write hearts and move half-heart sprite
       CLR R2
       LI R0,>1F01            ; Full heart / empty heart
       LI R12,8               ; Countdown to move up
       LI R7,>0BAC            ; Half-heart sprite coordinates
       LI R8,>E400            ; Half-heart sprite index and color (invisible)
       MOVB @HP,R1            ; R1 = hit points
       JEQ HALFH
       C R1,R9
       JL FILLH
       MOV R9,R1              ; Set HP to max HP
       MOVB R1,@HP
FILLH
       A   R10,R2
       CB  R2,R1              ; Compare counter to HP
       JL !
       LI  R8,>E406           ; Half-heart sprite index and color (red)
       S   R10,R2
       JMP HALFH
!      A   R10,R2
       AI  R7,>0008
       MOVB R0,*R15           ; Draw heart
       DEC R12
       JNE !
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
       LI R7,>03AC            ; Half-heart sprite coordinates
!      CB  R2,R1              ; Compare counter to HP
       JL FILLH
HALFH  ;LI R1,HARTST+VDPWM
       ;MOVB @R1LB,*R14
       ;MOVB R1,*R14
       ;MOVB R7,*R15            ; Save sprite coordinates
       ;MOVB @R7LB,*R15
       ;MOVB R8,*R15            ; Save sprite index and color
       ;MOVB @R8LB,*R15

       SWPB R0                ; Switch hearts
       LI R1,FULLHP
       C R2,R9                ; Compare to max hearts
       JL EMPTYH
       SOC R1,@FLAGS          ; Set full hp flag
       JMP HALFH2
EMPTYH
       A   R10,R2
       A   R10,R2
       MOVB R0,*R15           ; Draw heart
       DEC R12
       JNE !
       MOVB @R3LB,*R14        ; Send low byte of VDP RAM write address
       MOVB R3,*R14           ; Send high byte of VDP RAM write address
!      C R2,R9                ; Compare counter to max hearts
       JL EMPTYH
       SZC R1,@FLAGS          ; Clear full hp flag
HALFH2
       LI R0,HARTST           ; Set half-heart sprite and position
       LI R1,WRKSP+14         ; Point to R7
       LI R2,4
       B @VDPW                ; Return thru VDPW
