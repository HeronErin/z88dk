        INCLUDE "graphics/grafix.inc"

  IF    !__CPU_INTEL__&!__CPU_GBZ80__
        SECTION code_graphics
        PUBLIC  Line_r

        EXTERN  __gfx_coords

;
;    $Id: liner2.asm $
;

;    ...SLLLOOOW Variant by Stefano Bodrato
;    with the alternate registers left untouched and 8080 compatible instructions

; ******************************************************************************
;
;    Draw a pixel line from (x0,y0) defined in (COORDS) - the current plot
;    coordinate, to the relative distance points (x0+x,y0+y).
;
;    Design & programming by Gunther Strube,    Copyright (C) InterLogic 1995
;
;    The (COORDS+0)    pointer contains the current y coordinate, (COORDS+1) the
;    current x coordinate. The main program should reset the (COORDS) variables
;    before using line drawing.
;
;    The routine checks the range of specified coordinates which is the
;    boundaries of the graphics area (256x64    pixels).
;    If a boundary error occurs the routine exits automatically.    This may be
;    useful if you are trying to draw a line longer than allowed. Only the
;    visible part will be drawn.
;
;    The hardware graphics memory is organized as (0,0) in the top left corner.
;
;    The plot routine is    defined by an address pointer    in IX.
;
;    IN:    HL =    move    relative x horisontal points (maximum +/- 255).
;    DE =    move    relative y vertical    points (maximum +/-    255).
;    IX =    pointer to plot routine that uses HL = (x,y)    of plot coordinate.
;
;    OUT:    None.
;
;    Registers    used    by routine:
;      N    :    B, loop counter
;      i    :    line    balance variable
;      x    :    H/L,    horisontal, vertical distance    variables
;      y    :    H/L,    horisontal, vertical distance    variables
;    (x0,y0)    :    (h,l)
;    direc_x    :    d, horisontal step increment
;    direc_y    :    e, vertical step increment
;    ddx    :    b, horisontal step increment
;    ddy    :    c, vertical step increment
;
;    DE, A work registers.
;
; The algorithm in pseudo-code:
;
;    direc_x =    SGN x: direc_y    = SGN y
;    x = ABS x: y =    ABS y
;
;    if x    >= y
;    if x+y=0 then return
;    H = x
;    L = y
;    ddx = direc_x
;    ddy = 0
;    else
;    H = y
;    L = x
;    ddx = 0
;    ddy = direc_y
;    endif
;
;    B = H
;    i = INT(B/2)
;    FOR N=B TO 1 STEP -1
;    i = i + L
;    if i    < H
;    ix =    ddx
;    iy =    ddy
;    else
;    i = i - H
;    ix =    direc_x
;    iy =    direc_y
;    endif
;    x0 =    x0 +    ix
;    y0 =    y0 +    iy
;    plot    (x0,y0)
;    NEXT    N
;
;
;    Registers    changed after return:
;    ..BCDEHL/IXIY/af......    same
;    AF....../..../..bcdehl    different
;
Line_r: push    bc
        push    de                      ; preserve relative    vertical distance
        push    hl                      ; preserve relative    horisontal distance

        push    de
        push    hl

    ;exx
        push    bc
        push    de
        ld      bc, (bc1save)
        ld      de, (de1save)
        pop     hl
        ld      (de1save), hl
        pop     hl
        ld      (bc1save), hl

        pop     hl                      ; get relative    horisontal movement
        call    sgn
        ld      d, a                    ; direc_x    = SGN(x) installed
        call    abs
        ld      b, l                    ; x = ABS(x)

        pop     hl                      ; get relative    vertical movement
        call    sgn
        ld      e, a                    ; direc_y    = SGN(y) installed
        call    abs
        ld      c, l                    ; y = ABS(y)
        push    bc

    ;exx
        push    bc
        push    de
        ld      bc, (bc1save)
        ld      de, (de1save)
        pop     hl
        ld      (de1save), hl
        pop     hl
        ld      (bc1save), hl

        pop     hl                      ; H = absolute    x dist., L = absolute y distance

        ld      a, h
        cp      l
        jr      c, x_smaller_y          ; if    x >=    y
        or      h                       ;    if x+y = 0
        jp      z, exit_draw            ;    return

       ;exx    ;    else
        push    hl
        push    bc
        push    de
        ld      bc, (bc1save)
        ld      de, (de1save)
        pop     hl
        ld      (de1save), hl
        pop     hl
        ld      (bc1save), hl
        pop     hl

        ld      b, d                    ;    ddx = direc_x
        ld      c, 0                    ;    ddy = 0

       ;exx
        push    hl
        push    bc
        push    de
        ld      bc, (bc1save)
        ld      de, (de1save)
        pop     hl
        ld      (de1save), hl
        pop     hl
        ld      (bc1save), hl
        pop     hl

        jr      init_drawloop           ; else
x_smaller_y:
        ld      a, h
        ld      h, l                    ;    H = y
        ld      l, a                    ;    L = x

       ;exx
        push    hl
        push    bc
        push    de
        ld      bc, (bc1save)
        ld      de, (de1save)
        pop     hl
        ld      (de1save), hl
        pop     hl
        ld      (bc1save), hl
        pop     hl

        ld      b, 0                    ;    ddx = 0
        ld      c, e                    ;    ddy = direc_y

       ;exx
        push    hl
        push    bc
        push    de
        ld      bc, (bc1save)
        ld      de, (de1save)
        pop     hl
        ld      (de1save), hl
        pop     hl
        ld      (bc1save), hl
        pop     hl

init_drawloop:
        ld      b, h
        ld      c, h                    ; B = H
    ;srl    c    ; i = INT(B/2)
        xor     a
        add     c
        rra
        ld      c, a
          ; FOR N=B    TO 1    STEP    -1
drawloop:

        xor     a                       ; (Stefano)
        or      h                       ; .. vertical line drawing was slow
        jr      z, i_greater            ; this shortcut seems to solve the problem

        ld      a, c
        add     a, l
        jr      c, i_greater            ;    i + L > 255  (i > H)
        cp      h
        jr      nc, i_greater           ;    if i    < H
        ld      c, a                    ;    i = i + L

       ;exx
        push    hl
        push    bc
        push    de
        ld      bc, (bc1save)
        ld      de, (de1save)
        pop     hl
        ld      (de1save), hl
        pop     hl
        ld      (bc1save), hl
        pop     hl

        push    bc                      ;    ix =    ddx:    iy =    ddy

       ;exx
        push    hl
        push    bc
        push    de
        ld      bc, (bc1save)
        ld      de, (de1save)
        pop     hl
        ld      (de1save), hl
        pop     hl
        ld      (bc1save), hl
        pop     hl

        jr      check_plot              ;    else
i_greater:
        sub     h                       ;    i = i - H
        ld      c, a

       ;exx
        push    hl
        push    bc
        push    de
        ld      bc, (bc1save)
        ld      de, (de1save)
        pop     hl
        ld      (de1save), hl
        pop     hl
        ld      (bc1save), hl
        pop     hl

        push    de                      ;    ix =    direc_x: iy = direc_y

       ;exx    ;    endif
        push    hl
        push    bc
        push    de
        ld      bc, (bc1save)
        ld      de, (de1save)
        pop     hl
        ld      (de1save), hl
        pop     hl
        ld      (bc1save), hl
        pop     hl

check_plot:
        ex      (sp), hl                ;    preserve H,L distances on stack
        ex      de, hl                  ;    D,E = ix,    iy
        ld      hl, (__gfx_coords)
        ld      a, l
        add     a, e                    ;
        ld      l, a                    ;    y0 =    y0 +    iy (y0 is    checked by plot)

        ld      a, d
        inc     a
        add     a, h
        jr      c, check_range          ;    check out    of range
        jr      z, range_error          ;    Fz=1    & Fc=0 denotes    x0 <    0
        jr      plot_point
check_range:
        jr      nz, range_error         ;    Fz=0    & Fc=1 denotes    x0 >    255

plot_point:
        dec     a
        ld      h, a                    ;    x0 =    x0 +    ix
        ld      de, plot_RET
        push    de                      ;    hl =    (x0,y0)...
        jp      (ix)                    ;    execute PLOT at (x0,y0)
plot_RET:
        pop     hl                      ;    restore H,L distances...
    ;djnz    drawloop    ; NEXT N
        dec     b
        jp      nz, drawloop
        jr      exit_draw
range_error:
        pop     hl                      ; remove H,L distances...
exit_draw:
        pop     hl                      ; restore    relative horisontal    distance
        pop     de                      ; restore    relative vertical distance
        pop     bc
        ret


; ******************************************************************************
;
;    SGN (Signum value) of 16    bit signed integer.
;
;    IN:    HL =    integer
;    OUT:    A = result: 0,1,-1 (if zero, positive, negative)
;
;    Registers    changed after return:
;    ..BCDEHL/IXIY    same
;    AF....../....    different
;
sgn:    ld      a, h
        or      l
        ret     z                       ; integer    is zero, return 0...
;    bit    7,h
        ld      a, 128                  ; trying to be 8080 compatible  ;)
        and     h
        jr      nz, negative_int
        ld      a, 1
        ret
negative_int:
        ld      a, -1
        ret


; ******************************************************************************
;
;    ABS (Absolute value) of 16 bit signed integer.
;
;    IN:    HL =    integer
;    OUT:    HL =    converted    integer
;
;    Registers    changed after return:
;    A.BCDE../IXIY    same
;    .F....HL/....    different
;
abs:
;    bit    7,h
        ld      a, 128                  ; trying to be 8080 compatible  ;)
        and     h
        ret     z                       ; integer    is positive...
;    push    de
;    ex    de,hl
    ;ld    hl,0
    ;cp    a    ; Fc    = 0,    may not be used...
    ;sbc    hl,de    ; convert    negative integer
        xor     a
        sub     l
        ld      l, a
;	ld    a,0	; values between 0..255 are expected
;	sbc   h
;	ld    h,a

;    pop    de
        ret

        SECTION bss_graphics
bc1save:
        defw    0
de1save:
        defw    0
  ENDIF
