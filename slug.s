    .code16
    .text
    .global _boot
    .include "macros.s"

# Stack layout:
#
# |     ...    |    BP
# |------------|
# |  direction | -2(BP)
# |------------|
# |    head    | -4(BP)
# |------------|
# |    tail    | -6(BP)
# |------------|
# |            | -7(BP)
# |    SLUG    |   ...
# |            | -166(BP)
# |------------|
_boot:
    cli
    xor %ax, %ax
    mov $STACK_SEGMENT, %ax
    mov %ax, %ss
    mov %sp, %bp
    # the direction
    push $DOWN
    # SLUG head
    push $0
    # SLUG tail
    push $0
    sub $SLUG_LEN, %sp
    # the x-coordinate of the slug
    mov $60, %bx
    # the y-coordinate of the slug
    mov $80, %cx

    lea SLUG_START(%bp), %ax
    mov %ax, %gs
    mov -4(%bp), %di
    call write_coords
    init_video
.Ltick:
    mov -4(%bp), %di
    lea SLUG_START(%bp), %bx
    call read_coords
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
    cmp $60, %bx
    jne .Lerase_tail
    cmp $60, %cx
    jne .Lerase_tail
    # Grow the snake
    jmp .Lgrow
.Lerase_tail:
    mov -6(%bp), %di
    lea SLUG_START(%bp), %bx
    call read_coords

    # Delete the tail
    draw_square x=%bx, y=%cx, colour=$0xc02

    # Advance the tail
    mov -6(%bp), %ax
    call increment_end
    mov %ax, -6(%bp)
    # Draw a red square
    draw_square x=$60, y=$60, colour=$0xc04
    # Draw a blue square
    draw_square x=$20, y=$20, colour=$0xc01
.Lgrow:
    # Store the new slug coordinates
    mov -4(%bp), %ax
    call increment_end
    mov %ax, -4(%bp)

    pop %cx
    pop %bx

    # Draw the next position
    draw_square x=%bx, y=%cx, colour=$0xc0a

    lea SLUG_START(%bp), %ax
    mov %ax, %gs
    mov -4(%bp), %di
    call write_coords

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

# AX - the head/tail of SLUG
increment_end:
    add $1, %ax
    mov $SLUG_LEN, %bl
    div %bl
    mov %ah, %al
    xor %ah, %ah
    ret

# BX - the x-coordinate
# CX - the y-coordinate
# GS - the SLUG
# DI - the index in SLUG where to write the coordinates
write_coords:
    # x-coordinate
    xor %dx, %dx
    mov %bx, %ax
    mov $20, %bx
    div %bx
    mov %ax, %bx
    # y-coordinate (don't bother zeroing out DX, because the remainder
    # of the previous division will be 0 anyway)
    mov %cx, %ax
    mov $20, %cx
    div %cx
    # At this point, the lower 4 bits of AL contain the y-coordinate.
    # Now move the x-coordinate and into the highest order 4 bits of AL
    shl $4, %bl
    add %bl, %al
    # SLUG
    mov %gs, %bx
    mov %al, (%bx, %di)
    ret

# BX - the SLUG
# DI - the index of the coordinate to read
read_coords:
    mov (%bx, %di), %al
    # Save AL
    mov %al, %cl
    xor %ah, %ah
    # x-coordinate
    shr $4, %al
    mov $20, %dx
    mul %dx
    mov %ax, %bx

    xor %ah, %ah
    # y-coordinate
    and $0b1111, %cl
    mov $20, %dx
    mov %cl, %al
    mul %dx
    mov %ax, %cx
    ret

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
    jge 1f
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
    jge 1f
    sub $SQUARE_SIZE, %dx
    mov %dx, %ax
1:
    ret

# CX - start x pos
# GS - end x pos
draw_horizontal:
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
    pop %ax
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
    test %ax, %ax
    jle .Ldone
    mov -2(%bp), %ax
    add $1, %ax
    mov %ax, -2(%bp)
    jmp 1b
.Ldone:
    leave
    ret

.set STACK_SEGMENT, 0x9000
.set DATA_SEGMENT, 0x9300
.set SQUARE_SIZE, 20
.set GRID_HEIGHT, 200
.set GRID_WIDTH, 320
.set UP, 107
.set RIGHT, 108
.set DOWN, 106
.set LEFT, 104
# A maximum of 160 coordinates
# The grid is 320 pixels wide and 200 pixels high. Since we use 20x20 squares,
# each position on the x-axis is between 0 and 16, and each position on
# the y-axis is between 0 and 10, so we only need 4 bits to represent each
# coordinate (10 * 16 * 4 bits = 80 bytes)
.set SLUG_LEN, 80
.set SLUG_START, -(SLUG_LEN + 6)
