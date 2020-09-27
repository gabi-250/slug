    .code16
    .text
    .global _boot
_boot:
    cli
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es
    mov $STACK_SEGMENT, %ax
    mov %ax, %ss
    mov %ax, %bp
    mov %sp, %bp

    push %bp
    mov %sp, %bp
    # the direction
    push $DOWN
    # the y-coordinate of the snake
    push $95
    # the x-coordinate of the snake
    push $155
    call init_video
tick:
    pop %bx
    pop %cx
    pop %ax
    cmp $UP, %ax
    jne try_right
try_right:
    cmp $RIGHT, %ax
    jne try_down
    add $SQUARE_SIZE, %bx
    jmp draw
try_down:
    cmp $DOWN, %ax
    jne try_left
    add $SQUARE_SIZE, %cx
    jmp draw
try_left:
    cmp $LEFT, %ax
    jne try_up
    sub $SQUARE_SIZE, %bx
    jmp draw
try_up:
    sub $SQUARE_SIZE, %cx
draw:
    push %ax
    push %cx
    push %bx
    call draw_square
    # Pause for 0.5s
    mov $0x07, %cx
    mov $0xa120, %dx
    mov $0x86, %ah
    int $0x15
    # Check for keystroke
    mov $1, %ah
    int $0x16
    # No keystroke - just keep drawing
    jz tick
    # Read the keystroke
    mov $0, %ah
    int $0x16
    cmp $UP, %al
    jne read_down
    mov %al, -2(%bp)
    jmp tick
read_down:
    cmp $DOWN, %al
    jne read_left
    mov %al, -2(%bp)
    jmp tick
read_left:
    cmp $LEFT, %al
    jne read_right
    mov %al, -2(%bp)
    jmp tick
read_right:
    cmp $RIGHT, %al
    jne tick
    mov %al, -2(%bp)
    jmp tick
    hlt

init_video:
    # Set the video mode...
    mov $0x0, %ah
    # VGA 320 x 200 colour
    mov $0xd, %al
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
.set GRID_WIDTH, 300
.set GRID_X, 100
.set GRID_Y, 0
.set UP, 107
.set RIGHT, 108
.set DOWN, 106
.set LEFT, 104
