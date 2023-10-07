* Game over function (bank 4)

* called from bank 0
GAMOVR       ; GAME OVER

       ; HP is zero, game over and restart


       LI R0,x#TSF151      ; Game over sound
       MOV R0,@SOUND2

       LI R4,26
!      BL @!VSYNC0
       DEC R4
       JNE -!

       LI R5,DEDCLR
       BL @FGCSET
       BL @!VSYNC0
       BL @!VSYNC0


       LI R0,CLRTAB
       LI R1,DEDCLR
       LI R2,32
       BL @VDPW
       BL @!VSYNC0
       BL @!VSYNC0


       LI R4,16    ; spin 16 times, 5 frames each
!
       BL @!VSYNC0
       BL @!VSYNC0
       BL @!VSYNC0
       BL @!VSYNC0
       BL @!VSYNC0
       MOV R4,R3
       ANDI R3,>0003
       A R3,R3
       MOV @LNKSPN(R3),R3
       BL @LNKSPR
       DEC R4
       JNE -!

       LI R0,CLRTAB
       LI R1,DEDCL2
       LI R2,32
       BL @VDPW
       LI R4,10
!      BL @!VSYNC0
       DEC R4
       JNE -!

       LI R0,CLRTAB
       LI R1,DEDCL3
       LI R2,32
       BL @VDPW
       LI R4,10
!      BL @!VSYNC0
       DEC R4
       JNE -!

       LI R0,CLRTAB
       LI R1,DEDCL4
       LI R2,32
       BL @VDPW
       LI R4,10
!      BL @!VSYNC0
       DEC R4
       JNE -!

       MOV @FLAGS,R0
       ANDI R0,SCRFLG
       ORI R0,VDPWM+(3*32)
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R1,>2000  ; Fill screen with Space
       LI R2,21*32
!      MOVB R1,*R15
       DEC R2
       JNE -!

       LI R0,>0E00
       MOVB R0,@HEROSP+3   ; Set hero color to gray
       BL @!SPRUPD
       LI R4,24
!      BL @!VSYNC0
       DEC R4
       JNE -!


       LI R0,>E800
       MOVB R0,@HEROSP+2   ; Set hero sprite index to little star
       BL @!SPRUPD
       LI R4,10
!      BL @!VSYNC0
       DEC R4
       JNE -!

       ; play text writing sound
       LI R0,x#TSF100
       MOV R0,@SOUND1

       LI R0,>EC00
       MOVB R0,@HEROSP+2   ; Set hero sprite index to big star
       BL @!SPRUPD
       LI R4,4
!      BL @!VSYNC0
       DEC R4
       JNE -!

       CLR @HEROSP+2   ; Set hero color to transparent
       CLR @HEROSP+6   ; Set hero color to transparent
       BL @!SPRUPD
       LI R4,46
!      BL @!VSYNC0
       DEC R4
       JNE -!

       ;1133 96 GAME OVER (G below X's) centered vertically
       MOV @FLAGS,R0
       ANDI R0,SCRFLG
       ORI R0,VDPWM+(14*32)+12
       MOVB @R0LB,*R14
       MOVB R0,*R14
       LI R1,GAMEOV
       LI R2,9
!      MOVB *R1+,*R15
       DEC R2
       JNE -!

       LI R4,96
!      BL @!VSYNC0
       DEC R4
       JNE -!

!      BL @!VSYNC0
       JMP -!
       ;B @CONSAV ; Continue save mainmenu

!VSYNC0
       B @BANK0X
       DATA x#VSYNC0  ; TODO move this to bank 6

GAMEOV TEXT 'GAME OVER'
       EVEN

       ; Set foreground colors from colorset at R5
FGCSET MOV R11,R10  ; Save return address
       LI R0,CLRTAB
       LI R1,SCRTCH
       LI R2,32
       BL @VDPR

       LI R0,CLRTAB+VDPWM
       LI R1,SCRTCH
       LI R2,32
       MOVB @R0LB,*R14
       MOVB R0,*R14

!      MOVB *R1+,R0
       ANDI R0,>0F00
       MOVB *R5+,R3
       ANDI R3,>F000
       A R3,R0
       MOVB R0,*R15
       DEC R2
       JNE -!
       B *R10   ; Return to saved address
!SPRUPD
       LI R0,HEROST
       LI R1,HEROSP
       LI R2,5*4     ; write 5 sprites
       B @VDPW

LNKSPN DATA DIR_RT,DIR_DN,DIR_LT,DIR_UP

* 939 2 brown on dark red palette
DEDCLR BYTE >16,>96,>96,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>86,>86            ;
       BYTE >18,>18,>18,>18            ;
       BYTE >18,>18,>16,>96            ;
       BYTE >96,>96,>16,>41            ;

* 1018 10 brown on lightred palette
DEDCL2 BYTE >18,>98,>98,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >18,>16,>16,>16            ;
       BYTE >16,>18,>98,>98            ;
       BYTE >19,>19,>19,>19            ;
       BYTE >19,>19,>18,>98            ;
       BYTE >98,>98,>18,>41            ;

* 1028 10 dark brown on darkred palette
DEDCL3 BYTE >16,>96,>96,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>86,>86            ;
       BYTE >18,>18,>18,>18            ;
       BYTE >18,>18,>16,>96            ;
       BYTE >96,>96,>16,>41            ;

* 1038 10 black on darkred palette
DEDCL4 BYTE >16,>16,>16,>61            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >F1,>F1,>F1,>F1            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>16,>16            ;
       BYTE >16,>16,>16,>41            ;
