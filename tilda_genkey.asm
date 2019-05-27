;==================================================
; Replacement Keyscan, patched into TILDA Bank 0
;
;    BLWP @GENKEY
;    Out: R0 - holds value expected by Tilda edge calcs
;
; The below EQUates are from Tilda bank 0
;
;
;KEY_UP EQU >0002
;KEY_DN EQU >0004
;KEY_LT EQU >0008
;KEY_RT EQU >0010
;KEY_A  EQU >0020         fire
;KEY_B  EQU >0040
;KEY_C  EQU >0080
KEYESC EQU >BEEF         future ESCape return to OS
; We will use this table to scan for valid keypresses and apply the
;      proper ORI value.  Only one key may be handled each pass.
;      Joystick(s) can be ORI'd when implemented
KEYTAB DATA 13*256,KEY_A      enter/fire
       DATA 'S'*256,KEY_DN
       DATA 'W'*256,KEY_UP
       DATA 'D'*256,KEY_RT
       DATA 'E'*256,KEY_B
       DATA '/'*256,KEY_C
       DATA ';'*256,KEY_B
       DATA 'A'*256,KEY_LT
       DATA 'Q'*256,KEY_C
       DATA >9B00,KEYESC
       DATA 0
; key patch applied to bank 0
; 1AC2 is not static; re-examine new image when released.
;
KEYIT  BLWP @GENKEY      vector for zelda scan
       B    @>6000+>1AC2     hop to the edge calc

; Actual scan via XOP
; R8 holds the ORI'd value, which is passed on to caller R0
KEYWS  EQU  >F000        use a fast WS (on 9995 ram)
KEY    DATA 5
GENKEY DATA KEYWS,$+2
       CLR  R8           holds the composite key
       LI   R0,5
       XOP  @KEY,0      R1 holds key, make sure it is MSByte and masked
       ANDI R1,>FF00
;      MOV  R1,@0(R13)   debug
;      RTWP
;Test for valid keypress
; 0==end of table
; if found, copy to R8. No OR because we can't scan 2 keys at once. We could
;      try to empty the keyboard buffer but that might cause us more trouble
;
       LI   R2,KEYTAB
TESTK  CLR  R8
       MOV  *R2+,R3      0?  end
       JEQ  TESTEX       Test for ESCAPE key
       MOV  *R2+,R8      move ORI value to R8
       C    R3,R1        compare Key MSB to the XOP key
       JNE  TESTK        not equal? Keep scanning
; At this point we have either tested the keyboard and found nothing (>0000)
;      or we found a valid keypress and saved the ORI value
TESTEX  CI   R8,KEYESC   Did user hit ESCAPE?  If yes, dump out of the game
        JNE  TESTJY
;        B   @TILDEX
       JMP KEYDON
TESTJY LI   R5,>0000     JOYSTICK 1
       LI   R12,>24
;      LDCR R5,1        SBZ 0?
       SBZ  0
J1FIRE TB   -15        0
       JEQ  J1LFT
       ORI  R8,KEY_A     FIRE -15
J1LFT  TB   -14          1
       JEQ  J1RT
       ORI  R8,KEY_LT
J1RT   TB   -13          2
       JEQ  J1DWN
       ORI  R8,KEY_RT
J1DWN  TB   -12          3
       JEQ  J1UP
       ORI  R8,KEY_DN
J1UP   TB   -11          4
       JEQ  J2FIRE
       ORI  R8,KEY_UP
;----
J2FIRE
       LI   R5,>0100     JOYSTICK 2
       LI   R12,>24
;      LDCR R5,1        SBO 0?
       SBO  0
       TB   -15          fire
       JEQ  J2LFT
       ORI  R8,KEY_B
J2LFT  TB   -14
       JEQ  J2RT
       ORI  R8,KEY_A
J2RT   TB   -13
       JEQ  J2DWN
       ORI  R8,KEY_C
J2DWN  TB   -12
       JEQ  J2UP
       ORI  R8,KEY_B
J2UP   TB   -11
       JEQ  KEYDON       yattfu; was jumping to J2FIRE. Endless loop.
       ORI  R8,KEY_C
;
; RETURN R8 as R0 for the edge calculations
;
KEYDON MOV  R8,@0(R13)
       RTWP              and return to Tilda
