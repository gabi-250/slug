# Pause for the specified number of milliseconds.
.macro pause ms
    mov $(((\ms) * 1000) >> 16), %cx
    mov $(((\ms) * 1000) & 0x0000ffff), %dx
    mov $0x86, %ah
    int $0x15
.endm

.macro draw_square x, y, colour=0xc0a
    push \colour
    push \y
    push \x
    call draw_square
    pop %bx
    pop %cx
    pop %ax
.endm

.macro write_coords slug, coords, pos
    mov \slug, %bx
    mov \coords, (%bx, \pos)
.endm
