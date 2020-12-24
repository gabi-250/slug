    .code16
    .text
    .global _boot
    .include "macros.s"

_boot:
    cli
    xor %ax, %ax
    mov %ax, %es
    mov $DATA_SEGMENT, %ax
    mov %ax, %ds
    mov $STACK_SEGMENT, %ax
    mov %ax, %ss
    mov %sp, %bp
    # the direction
    push $DOWN
    # current index in SLUG
    push $0
    # dummy colour
    push $1
    # the x-coordinate of the slug
    mov $150, %ax
    mov %ax, SLUG + SLUG_HEAD
    # the y-coordinate of the slug
    mov $90, %ax
    mov %ax, SLUG + SLUG_HEAD + 2
    init_video
    call draw_borders
.Ltick:
    mov SLUG + SLUG_HEAD, %bx
    mov (SLUG + SLUG_HEAD + 2), %cx
    mov -2(%bp), %ax
.Ltry_right:
    cmp $RIGHT, %ax
    jne .Ltry_down
    mov %bx, %ax
    mov $GRID_WIDTH, %dx
    call slug_forward
    mov %ax, %bx
    jmp .Ldraw
.Ltry_down:
    cmp $DOWN, %ax
    jne .Ltry_left
    mov %cx, %ax
    mov $GRID_HEIGHT, %dx
    call slug_forward
    mov %ax, %cx
    jmp .Ldraw
.Ltry_left:
    cmp $LEFT, %ax
    jne .Ltry_up
    mov %bx, %ax
    mov $GRID_WIDTH, %dx
    call slug_backward
    mov %ax, %bx
    jmp .Ldraw
.Ltry_up:
    mov %cx, %ax
    mov $GRID_HEIGHT, %dx
    call slug_backward
    mov %ax, %cx
.Ldraw:
    # Save the new slug coordinates
    push %bx
    push %cx

    # Delete the tail
    draw_square x=SLUG + SLUG_TAIL, y=SLUG + SLUG_TAIL + 2, colour=$0xc02
    # Draw a red square
    draw_square x=$50, y=$50, colour=$0xc04

    pop %cx
    pop %bx

    # Store the new slug coordinates
    mov %bx, SLUG + SLUG_HEAD
    mov %cx, (SLUG + SLUG_HEAD + 2)

    # Draw the slug
    # XXX draw the whole slug, not just the head
    draw_square x=%bx, y=%cx, colour=$0xc0a

    # Pause for 0.5s
    pause ms=500
    # Check for keystroke
    mov $1, %ah
    int $0x16
    # No keystroke - just keep drawing
    jz .Ltick
    # Read the keystroke
    xor %ax, %ax
    int $0x16
    cmp $UP, %al
    jne .Lread_down
    mov %al, -2(%bp)
    jmp .Ltick
.Lread_down:
    cmp $DOWN, %al
    jne .Lread_left
    mov %al, -2(%bp)
    jmp .Ltick
.Lread_left:
    cmp $LEFT, %al
    jne .Lread_right
    mov %al, -2(%bp)
    jmp .Ltick
.Lread_right:
    cmp $RIGHT, %al
    jne .Ltick
    mov %al, -2(%bp)
    jmp .Ltick
    hlt

# Move the slug one square forward, ensuring it comes out the other side
# when it reaches the edge.
#
# AX - position to advance
# DX - grid width/height
slug_forward:
    # clobber bx..
    push %bx
    add $SQUARE_SIZE, %ax
    mov %dx, %bx
    xor %dx, %dx
    div %bx
    mov %dx, %ax
    pop %bx
    test %ax, %ax
    jne 1f
    mov $SQUARE_SIZE, %ax
1:
    ret

# Move the slug back one square, ensuring it comes out the other side
# when it reaches the edge.
#
# AX - position to advance
# DX - grid width/height
slug_backward:
    sub $SQUARE_SIZE, %ax
    test %ax, %ax
    jg 1f
    sub $SQUARE_SIZE, %dx
    mov %dx, %ax
1:
    ret

# CX - start x pos
# GS - end x pos
draw_horizontal:
    push %bp
    mov %sp, %bp
    push %ax
.Ldraw_horizontal:
    pop %ax
    push %ax
    xor %bh, %bh
    int $0x10
    mov %gs, %ax
    add $1, %cx
    cmp %ax, %cx
    jl .Ldraw_horizontal
    leave
    ret

# DX - start y pos
# GS - end y pos
draw_vertical:
    push %ax
.Ldraw_vertical:
    add $1, %dx
    pop %ax
    push %ax
    xor %bh, %bh
    int $0x10
    mov %gs, %ax
    cmp %ax, %dx
    jne .Ldraw_vertical
    pop %ax
    ret

draw_borders:
    push %bp
    mov %sp, %bp
    # The number of times to repeat .Ldraw_horizontal_borders/.Ldraw_vertical_borders
    push $2
    # The border colour
    push $0xc08
    push $0
    push $0
.Ldraw_horizontal_borders:
    call keep_drawing
    test %ax, %ax
    je 2f
1:
    call draw_square
    pop %ax
    add $SQUARE_SIZE, %ax
    push %ax
    cmp $GRID_WIDTH, %ax
    jne 1b
    movw $0, -8(%bp)
    movw $GRID_HEIGHT, -6(%bp)
    jmp .Ldraw_horizontal_borders
2:
    movw $2, -2(%bp)
    movw $0, -6(%bp)
    movw $0, -8(%bp)
.Ldraw_vertical_borders:
    call keep_drawing
    test %ax, %ax
    je 2f
1:
    call draw_square
    mov -6(%bp), %ax
    add $SQUARE_SIZE, %ax
    mov %ax, -6(%bp)
    cmp $(GRID_HEIGHT + SQUARE_SIZE), %ax
    jne 1b
    movw $0, -6(%bp)
    pop %ax
    push $GRID_WIDTH
    jmp .Ldraw_vertical_borders
2:
    leave
    ret

keep_drawing:
    mov -2(%bp), %ax
    test %ax, %ax
    je .Lno
    sub $1, %ax
    mov %ax, -2(%bp)
.Lyes:
    mov $1, %ax
    jmp 1f
.Lno:
    mov $0, %ax
1:
    ret

draw_square:
    push %bp
    mov %sp, %bp
    # save the y-coordinate
    push 6(%bp)
    push $SQUARE_SIZE
1:
    mov 4(%bp), %cx
    mov 4(%bp), %ax
    add $SQUARE_SIZE, %ax
    mov %ax, %gs

    mov -2(%bp), %dx
    mov 8(%bp), %ax
    call draw_horizontal
    pop %ax
    sub $1, %ax
    push %ax
    cmp $0, %ax
    jle .Ldone
    mov -2(%bp), %ax
    add $1, %ax
    mov %ax, -2(%bp)
    jmp 1b
.Ldone:
    leave
    ret

.set STACK_SEGMENT, 0x9000
.set DATA_SEGMENT, 0x9100
.set SQUARE_SIZE, 10
.set GRID_HEIGHT, 190
.set GRID_WIDTH, 310
.set GRID_X, 100
.set GRID_Y, 0
.set UP, 107
.set RIGHT, 108
.set DOWN, 106
.set LEFT, 104
.set SLUG_HEAD, 0
.set SLUG_TAIL, 0
# A maximum of 10 coordinates
SLUG: .fill 10
