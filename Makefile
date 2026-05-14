# Makefile for string library

ASM = nasm
ASMFLAGS = -f elf64
LD = ld
TARGET = stringlib

OBJS = data.o string.o main.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) $(OBJS) -o $(TARGET)

data.o: data.asm
	$(ASM) $(ASMFLAGS) data.asm -o data.o

string.o: string.asm
	$(ASM) $(ASMFLAGS) string.asm -o string.o

main.o: main.asm
	$(ASM) $(ASMFLAGS) main.asm -o main.o

clean:
	rm -f *.o $(TARGET)
