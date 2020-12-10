ENTRY(_boot)
OUTPUT_FORMAT("binary")

SECTIONS
{
    . = 0x7c00;
    .text :
    {
        slug.o(.*)
        /* Set the location counter to 0x1fe = 510 */
        . = 0x1fe;
        /* The boot signature */
        SHORT(0xaa55)
    }
}

OUTPUT_FORMAT(binary)
