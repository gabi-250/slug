.code16

.macro init_video
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
.endm

# Pause for the specified number of milliseconds.
.macro pause ms
    mov $(((\ms) * 1000) >> 16), %cx
    mov $(((\ms) * 1000) & 0x0000ffff), %dx
    mov $0x86, %ah
    int $0x15
.endm

