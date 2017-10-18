* Dan2 decompression - http://atariage.com/forums/topic/260572-dan2-lossless-data-compression/
* R5 = Source data address
* R7 = VDP output address
* Register usage
* R3 = length (elias_gamma)
* R8 = status bits
* R9 = offset
* R10 = saved return address
* R12 = max offset bits
DAN2DC
       MOV R11,R10  ; Save return address
       CLR R8
       LI R12,1   ; R12 = 2 (max offset bits initial value, minus 8)
!      INC R12
       BL @D2RBIT   ; R12 = (count of 1 bits) + 2
       DATA -!
D2LIT ; literal
       MOVB *R5+,R1
       MOV R7,R0
       BL @VDPWB
       INC R7
D2LZLP ; LZ loop
       BL @D2RBIT
       DATA D2LIT
       ; length = read_elias_gamma()
       CLR R4      ; len (number of bits in elias_gamma)
       LI R3,1     ; elias_gamma
!      INC R4      ; while carry_flag == 0
       CI R4,17
       JEQ D2_L17
       BL @D2RBIT
       DATA !      ; if carry, increment counter
       JMP -!
D2_L17
       ; elias_gamma = 0; so length = 0, done!
       B *R10       ; Return to saved address

D2_IEG ; increment elias_gamma
       INC R3   ; elias_gamma += 1
!      DEC R4
       JEQ !
       SLA R3,1
       BL @D2RBIT
       DATA D2_IEG   ; if carry, increment elias_gamma
       JMP -!
!      ; R3 = elias_gamma = length (known to be nonzero)
       ; offset = read_offset(length)

       CLR R9   ; offset = 0

       ; read_offset(option=R3) returns offset in R1
       CI R3,2
       JLE !  ; if (option > 2)

       BL @D2RBIT
       DATA D2OFF3
!
       CI R3,1
       JLE !  ; if (option > 1)

       BL @D2RBIT
       DATA D2OFF2
!
       BL @D2RBIT
       DATA D2OFF1

       INC R9
       BL @D2RBIT
       DATA D2_OFF
       CLR R9
D2_OFF
       ; offset = R9
       NEG R9
       DEC R9
       A R7,R9   ; R9 index = out_addr - offset - 1
!
       MOV R9,R0    ; Read byte from R9 (index)
       BL @VDPRB
       INC R9

       MOV R7,R0    ; Write byte to R7 (out_addr)
       BL @VDPWB
       INC R7

       DEC R3
       JNE -!
       JMP D2LZLP

MAXOF1 EQU 2             ; 1<<1
MAXOF2 EQU MAXOF1+16     ; 1<<4
MAXOF3 EQU MAXOF2+256    ; 1<<8

D2OFF3
       ; read_bits(max_bits - 8)
       MOV R12,R4    ; R4=MAX_OFFSET_BITS-8
       BL @D2RBTS
       SLA R9,8
       AI R9,MAXOF3-MAXOF2
       ;fall thru
D2OFF2
       MOVB *R5+,@R9LB
       AI R9,MAXOF2
       JMP D2_OFF
D2OFF1
       LI R4,4
       BL @D2RBTS
       AI R9,MAXOF1
       JMP D2_OFF

* read_bits(count=R4) return in R9
D2RBTS
       MOV R11,R0  ; Save return address
!      SLA R9,1
       BL @D2RBIT
       DATA D2RBT2
       JMP D2RBT3
D2RBT2 INC R9
D2RBT3 DEC R4
       JNE -!
       B *R0   ; Return to saved address

* read_bit, jump to *R11+ if set, return otherwise
* Modifies R2
D2RBIT
       MOV *R11+,R2
D2RBI2
       SLA R8,1
       JEQ D2RFIL
       JNC !
       B *R2
!      RT

* read_bit refill bits
D2RFIL
       LI R8,>0080
       MOVB *R5+,R8
       JMP D2RBI2
