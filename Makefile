BOOT := slug
OBJS := slug.o macros.o

.PHONY: all clean qemu

all: clean $(BOOT).bin

$(BOOT).bin: $(OBJS)
	$(LD) -T linker.ld -o $@

qemu: $(BOOT).bin
	qemu-system-x86_64 -drive format=raw,file=./$<

debug: $(BOOT).bin
	qemu-system-x86_64 -drive format=raw,file=./$< -s -S

clean:
	rm -f $(OBJS) $(BOOT).bin
