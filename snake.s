    .code16
    .text
    .global _boot
_boot:
    cli
    xor %ax, %ax
    mov %ax, %es
    mov $DATA_SEGMENT, %ax
    mov %ax, %ds
    mov $STACK_SEGMENT, %ax
    mov %ax, %ss
    mov %ax, %bp
    mov %sp, %bp

    # the direction (stored at [BP])
    push $DOWN
    mov %sp, %bp
    # dummy colour
    push $1
    # the y-coordinate of the snake
    push $90
    # the x-coordinate of the snake
    push $150
    mov $90, %ax
    mov %ax, SNAKE

    mov $150, %ax
    mov %ax, SNAKE + 1
    call init_video

    call draw_borders
tick:
    pop %bx
    pop %cx
    pop %ax
    mov (%bp), %ax
try_right:
    cmp $RIGHT, %ax
    jne try_down

    mov %bx, %ax
    mov $GRID_WIDTH, %dx
    push $1
    call advance_snake
    pop %bx
    mov %ax, %bx
    jmp draw
try_down:
    cmp $DOWN, %ax
    jne try_left
    mov %cx, %ax
    mov $GRID_HEIGHT, %dx
    push $1
    call advance_snake
    pop %cx
    mov %ax, %cx
    jmp draw
try_left:
    cmp $LEFT, %ax
    jne try_up
    mov %bx, %ax
    mov $GRID_WIDTH, %dx
    push $0
    call advance_snake
    pop %bx
    mov %ax, %bx
    jmp draw
try_up:
    mov %cx, %ax
    mov $GRID_HEIGHT, %dx
    push $0
    call advance_snake
    pop %cx
    mov %ax, %cx
draw:
    push $0xc06
    # push the y coordinate
    push %cx
    # push the x coordinate
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
    mov %al, (%bp)
    jmp tick
read_down:
    cmp $DOWN, %al
    jne read_left
    mov %al, (%bp)
    jmp tick
read_left:
    cmp $LEFT, %al
    jne read_right
    mov %al, (%bp)
    jmp tick
read_right:
    cmp $RIGHT, %al
    jne tick
    mov %al, (%bp)
    jmp tick
    hlt

# Move the snake one position forward, ensuring it comes out the other side
# when it reaches the edge.
#
# AX - position to advance
# DX - grid width/height
# top of the stack - 1 if the snake is going forward, or 0, if it's going
# backwards,
advance_snake:
    push %bp
    mov %sp, %bp
    push %cx
    push %bx
    mov 4(%bp), %bx
    test %bx, %bx
    je .Lsubtract
    add $SQUARE_SIZE, %ax
    mov %dx, %bx
    xor %dx, %dx
    div %bx
    mov %dx, %ax
    test %ax, %ax
    jne 1f
    mov $SQUARE_SIZE, %ax
    jmp 1f
.Lsubtract:
    sub $SQUARE_SIZE, %ax
    test %ax, %ax
    jg 1f
    sub $SQUARE_SIZE, %dx
    mov %dx, %ax
1:
    pop %bx
    pop %cx
    leave
    ret

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
    call _keep_drawing
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
    call _keep_drawing
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

_keep_drawing:
    mov -2(%bp), %ax
    test %ax, %ax
    je .Lno
    sub $1, %ax
    mov %ax, -2(%bp)
    jmp .Lyes
.Lno:
    mov $0, %ax
    jmp 1f
.Lyes:
    mov $1, %ax
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
    #mov $0xc06, %ax
    mov 8(%bp), %ax
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
.set SNAKE_LEN, 0
# A maximum of 10 coordinates
SNAKE: .fill 20
