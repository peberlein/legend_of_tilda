; Copy R2 bytes from R1 to VDP address R0
VDPW   MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       ORI  R0,VDPWM        ; Set read/write bits 14 and 15 to write (01)
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
!      MOVB *R1+,*R15       ; Write byte to VDP RAM
       DEC  R2              ; Byte counter
       JNE  -!              ; Check if done
       RT

; Write one byte from R1 to VDP address R0
VDPWB  MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       ORI  R0,VDPWM        ; Set read/write bits 14 and 15 to write (01)
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       MOVB R1,*R15
       RT

; Read one byte to R1 from VDP address R0 (R0 is preserved)
VDPRB  MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       LI R1,VDPRD          ; Very important delay for 9918A prefetch, otherwise glitches can occur
       MOVB *R1,R1
       RT

; Read R2 bytes to R1 from VDP address R0 (R0 is preserved)
VDPR   MOVB @R0LB,*R14      ; Send low byte of VDP RAM write address
       MOVB R0,*R14         ; Send high byte of VDP RAM write address
       NOP                  ; Very important delay for 9918A prefetch, otherwise glitches can occur
!      MOVB @VDPRD,*R1+
       DEC R2
       JNE -!
       RT


; Write VDP register R0HB data R0LB
VDPREG MOVB @R0LB,*R14      ; Send low byte of VDP Register Data
       ORI  R0,VDPRM          ; Set register access bit
       MOVB R0,*R14         ; Send high byte of VDP Register Number
       RT

; Note: The interrupt is disabled in VDP Reg 1 so we can poll it here
; There could be a race condition where the interrupt flag could be cleared before we read it,
; resulting it a missed vsync interrupt, and polling the status register increases that chance.
; VSYNC  MOVB @VDPSTA,R0     ; Note: VDP Interrupt flag is now cleared after reading it
;        ANDI R0, >8000
;        JEQ VSYNC
;        RT

; Reading the VDP INT bit from the CRU doesn't clear the status register, so it should be safe to poll.
; The CRU bit gets updated even with interrupts disabled (LIMI 0)
; Modifies R12
;VSYNC
;       MOVB @VDPSTA,R12      ; Clear interrupt flag manually since we polled CRU
;       CLR R12
;!      TB 2                  ; CRU bit 2 - VDP INT
;       JEQ -!                ; Loop until set
;       MOVB @VDPSTA,R12      ; Clear interrupt flag manually since we polled CRU
;       ; fall thru
;       RT
