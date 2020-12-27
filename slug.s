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
# |  target-x  | -8(BP)
# |------------|
# |  target-y  | -10(BP)
# |------------|
# |            | -11(BP)
# |            |
# |    SLUG    |   ...
# |            |
# |            | -90(BP)
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
    # Target-x
    push $60
    # Target-y
    push $80
    sub $SLUG_LEN, %sp
    # the x-coordinate of the slug
    mov $60, %bx
    # the y-coordinate of the slug
    mov $80, %cx

    lea SLUG_START(%bp), %ax
    mov %ax, %gs
    mov -4(%bp), %di
    call write_coords
    # 2 = green
    mov $002, %bx
    call init_video
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
    mov $(GRID_WIDTH - SQUARE_SIZE), %dx
    call slug_backward
    mov %ax, %bx
    jmp .Ldraw
.Ltry_up:
    mov %cx, %ax
    mov $(GRID_HEIGHT- SQUARE_SIZE), %dx
    call slug_backward
    mov %ax, %cx
.Ldraw:
    # Save the new slug coordinates
    push %bx
    push %cx
    cmp -8(%bp), %bx
    jne .Lerase_tail
    cmp -10(%bp), %cx
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


    # Draw a blue square
   # draw_square x=$20, y=$20, colour=$0xc01
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

    mov -8(%bp), %bx
    mov -10(%bp), %cx
    call compress_coords
    mov %al, %cl
    lea SLUG_START(%bp), %bx
    mov -6(%bp), %di
    mov -4(%bp), %si
    call coord_in_slug
    test %al, %al
    jnz .Lread_input
    # Draw a red square
    draw_square x=-8(%bp), y=-10(%bp), colour=$0xc04
.Lread_input:
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
    mov %al, -2(%bp)
    jne .Lread_down
    jmp .Ltick
.Lread_down:
    cmp $DOWN, %al
    jne .Lread_left
    jmp .Ltick
.Lread_left:
    cmp $LEFT, %al
    jne .Lread_right
    jmp .Ltick
.Lread_right:
    cmp $RIGHT, %al
    jne .Ltick
    jmp .Ltick
.Lhlt:
    hlt

# BX - the backgorund colour
init_video:
    # Set the video mode to VGA 320 x 200 colour
    mov $0x00d, %ax
    int $0x10
    # Set the background colour
    mov $0xb, %ah
    int $0x10
    jmp .Ltick
    ret

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
    call compress_coords
    # SLUG
    mov %gs, %bx
    mov %al, (%bx, %di)
    ret

# BX - the x-coordinate
# CX - the y-coordinate
# AL - the coordinates stored as 4-bit values
compress_coords:
    # x-coordinate
    xor %dx, %dx
    mov %bx, %ax
    mov $SQUARE_SIZE, %bx
    div %bx
    mov %ax, %bx
    # y-coordinate (don't bother zeroing out DX, because the remainder
    # of the previous division will be 0 anyway)
    mov %cx, %ax
    mov $SQUARE_SIZE, %cx
    div %cx
    # At this point, the lower 4 bits of AL contain the y-coordinate.
    # Now move the x-coordinate and into the highest order 4 bits of AL
    shl $4, %bl
    add %bl, %al
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
    mov $SQUARE_SIZE, %dx
    mul %dx
    mov %ax, %bx
    xor %ah, %ah
    # y-coordinate
    and $0b1111, %cl
    mov $SQUARE_SIZE, %dx
    mov %cl, %al
    mul %dx
    mov %ax, %cx
    ret

# BX - the SLUG
# CL - the coordinates to search for
# DI - the tail
# SI - the head
#
# AL - whether the coordinate was found
coord_in_slug:
    mov (%bx, %di), %al
    cmp %al, %cl
    je .Lfound
    cmp %si, %di
    je .Lnot_found
    mov %di, %ax
    push %bx
    call increment_end
    pop %bx
    mov %ax, %di
    jmp coord_in_slug
.Lnot_found:
    xor %al, %al
    ret
.Lfound:
    mov $1, %al
    ret

# Move the slug one square forward, ensuring it comes out the other side
# when it reaches the edge.
#
# AX - position to advance
# DX - grid width/height
slug_forward:
    add $SQUARE_SIZE, %ax
    mov %dx, %di
    xor %dx, %dx
    div %di
    mov %dx, %ax
    ret

# Move the slug back one square, ensuring it comes out the other side
# when it reaches the edge.
#
# AX - position to advance
# DX - grid width/height - SQUARE_SIZE
slug_backward:
    sub $SQUARE_SIZE, %ax
    test %ax, %ax
    jge 1f
    mov %dx, %ax
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
    mov %cx, %ax
    add $SQUARE_SIZE, %ax
    mov %ax, %gs

    mov -2(%bp), %dx
    mov 8(%bp), %es
.Ldraw_horizontal:
    mov %es, %ax
    xor %bh, %bh
    int $0x10
    mov %gs, %ax
    add $1, %cx
    cmp %ax, %cx
    jl .Ldraw_horizontal
    pop %ax
    sub $1, %ax
    push %ax
    test %ax, %ax
    jle .Ldone_draw_square
    mov -2(%bp), %ax
    add $1, %ax
    mov %ax, -2(%bp)
    jmp 1b
.Ldone_draw_square:
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
.set SLUG_START, -(SLUG_LEN + 10)
