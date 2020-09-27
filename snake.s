    .code16
    .text
    .global _boot
_boot:
    cli
    xor %ax, %ax
    mov	%ax, %ds
    mov	%ax, %es
    mov $STACK_SEGMENT, %ax
    mov %ax, %ss
    mov %ax, %bp
    # the y-coordinate of the current piece
    push $0
    mov $145, %ax
    push %ax # x coordinate
tick:
    call draw_frame
    call draw_square

    pop %ax # the x-coordinate of the piece

    cmp $(GRID_X + GRID_WIDTH - SQUARE_SIZE), %ax
    jge .Lhlt

    cmp $GRID_X, %ax
    jle .Lhlt
    mov %ax, %cx

    pop %ax # the y-coordinate of the piece

    cmp $(GRID_Y + GRID_HEIGHT - SQUARE_SIZE), %ax
    jge .Lhlt

    add $SQUARE_SIZE, %ax
    push %ax
    push %cx

   # # Pause for 1s (0xf4240 = 10^6 microseconds)
   # mov $0x0f, %cx
   # mov $0x4240, %dx

    # Pause for 0.5s
    mov $0x07, %cx
    mov $0xa120, %dx
    mov $0x86, %ah
    int $0x15
    jmp tick
.Lhlt:
    hlt

draw_frame:
    call init_video
    # y-coordinate
    mov $GRID_Y, %dx
    mov $GRID_X, %ax
    mov %ax, %cx
    add $GRID_WIDTH, %ax
    mov %ax, %gs
    mov $0xc01, %ax
    call draw_horizontal

    mov $GRID_HEIGHT - 1, %dx
    mov $GRID_X, %ax
    mov %ax, %cx
    add $GRID_WIDTH, %ax
    mov %ax, %gs
    mov $0xc01, %ax
    call draw_horizontal

    mov $GRID_X, %cx
    xor %dx, %dx
    mov $GRID_HEIGHT, %ax
    mov %ax, %gs
    mov $0xc01, %ax
    call draw_vertical

    mov $(GRID_X + GRID_WIDTH), %cx
    xor %dx, %dx
    mov $GRID_HEIGHT, %ax
    mov %ax, %gs
    mov $0xc01, %ax
    call draw_vertical
    ret

init_video:
    # Set video mode
    mov $0x0, %ah
    # 80x25, colour
    mov $0x04, %al
    int $0x10
    # Set the background colour
    mov $0xb, %ah
    mov $0, %bh
    # 2 = green
    mov $2, %bl
    int $0x10
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
    mov $0xc06, %ax
    call draw_horizontal
    pop %ax
    sub $1, %ax
    push %ax
    cmp $0, %ax
    jg 2f
    jmp .Ldone
2:
    mov -2(%bp), %ax
    add $1, %ax
    mov %ax, -2(%bp)
    jmp 1b
.Ldone:
    mov %bp, %sp
    pop %bp
    ret

.set STACK_SEGMENT, 0x9000
.set SQUARE_SIZE, 10
.set GRID_HEIGHT, 200
.set GRID_WIDTH, 100
.set GRID_X, 100
.set GRID_Y, 0
