MCU=stm32
CORE=F0
CC=arm-none-eabi-gcc
OBJDUMP=arm-none-eabi-objdump
OBJCOPY=arm-none-eabi-objcopy
SIZE=arm-none-eabi-size
NM=arm-none-eabi-nm
READELF=arm-none-eabi-readelf
CFLOW_ARG ?=
CDEFS := -DSTM32F051x8

# Include paths
INCLUDES := -Iinclude
INCLUDES += -Ilib/ST
INCLUDES += -Ilib/ARM

CFLAGS=-mcpu=cortex-m0 -mthumb -W -Wall -Wextra -Werror -Wundef -Wshadow -Wdouble-promotion -Wno-error=unused-function    -Wformat-truncation -fno-common -Wconversion     -g2 -Os -ffunction-sections -fdata-sections     $(INCLUDES)    $(CDEFS)
LDFLAGS=-Tlib/ST/stm32.ld -specs=nano.specs -specs=nosys.specs -lc -lgcc -Wl,--cref,--gc-section,--Map=build/output.map

SRC=$(wildcard src/*.c)
SRC+=$(wildcard lib/ST/system_*.c)
SRC+=$(wildcard lib/ST/startup_*.s)
SRC+=$(wildcard lib/ff15a/source/*.c)

OBJ=$(SRC:.c=.o)
LIBAMB=lib/nazengg/libnazengg.a
TARGET=build/main.elf
TARGET_BIN=build/main.bin

all: $(LIBAMB) $(TARGET)

$(LIBAMB):
	$(MAKE) -C lib/nazengg

$(TARGET): $(OBJ) $(LIBAMB)
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

disasm: $(TARGET)
	$(OBJDUMP) -h -d $(TARGET) > build/main.disasm.s
	@echo "✓ Disassembly written to build/main.disasm.s"

symbols_text: $(TARGET)
	$(NM) -n $(TARGET) | grep ' T ' > build/symbols_text.txt
	@echo "✓ .text symbols written to build/symbols_text.txt"

symbols_undefined: $(TARGET)
	$(NM) -u $(TARGET) > build/symbols_undefined.txt
	@echo "✓ Undefined symbols written to build/symbols_undefined.txt"

readelf_headers: $(TARGET)
	$(READELF) -a $(TARGET) > build/elf_headers.txt
	@echo "✓ ELF headers and sections dumped to build/elf_headers.txt"

linkermap: $(TARGET)
	@echo "✓ Linker map generated at build/output.map"

symbolsize: $(TARGET)
	$(NM) --print-size --size-sort --radix=d $(TARGET) > build/symbolsize.txt
	@echo "✓ Symbols sorted by size(decimal) written to build/symbolsize.txt"

size: $(TARGET)
	@echo "arm-none-eabi-size measures the size of *loadable* sections (text + data only + bss, not total ELF size)"
	@echo "text+data ==>> total flash usage, data+bss ==>> total ram usage:"
	$(SIZE) $(TARGET)
	@echo ""
	@echo "Actual file size on disk:"
	@ls -lh $(TARGET)

strip: $(TARGET)
	@echo "Stripping debug info from ELF to reduce file size..."
	arm-none-eabi-strip $(TARGET) -o $(basename $(TARGET))_stripped.elf

flash_bin: $(TARGET_BIN)
	st-flash write $(TARGET_BIN) 0x08000000

hex: $(TARGET)
	$(OBJCOPY) -O ihex $(TARGET) build/main.hex
	@echo "✓ Intel HEX file: build/main.hex"

bin: $(TARGET)
	$(OBJCOPY) -O binary $(TARGET) build/main.bin
	@echo "✓ Raw binary: build/main.bin"

info: $(TARGET)
	$(NM) -n $(TARGET) > build/symbols.txt
	@echo "✓ Symbols written to build/symbols.txt"

# Text call graph
callgraph-txt:
	cflow --brief --number --omit-arguments --level-indent 4 --depth=4 $(CFLOW_ARG) $(SRC) -o callgraph.txt

# PNG call graph (requires Graphviz)
callgraph-png:
	cflow --omit-arguments --format=dot $(CFLOW_ARG) $(SRC) | dot -Granksep=1.0 -Txlib

# callgraph-png: callgraph-txt
# 	cat callgraph.txt | dot -Grankdir=LR -Tpng -o callgraph.png
# argument meaning: -Grankdir=LR: Left-to-right layout (default is top-to-bottom).

# Python script for DOT conversion

depgraph: $(SRC)
	@echo "[1/3] Generating deps.mk..."
	arm-none-eabi-gcc -MM $(SRC) $(INCLUDES) $(CDEFS) > deps.mk
	@echo "[2/3] Converting to deps.dot..."
	python3 deps_to_dot.py deps.mk > deps.dot
	@echo "[3/3] Rendering deps.png..."
	dot -Tpng deps.dot -o deps.png
	@echo "✅ Done: deps.png generated"	

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf build *.o
	rm -rf src/*.o
	rm -rf lib/ST/*.o
	rm -rf lib/ff15a/source/*.o
	$(MAKE) -C lib/nazengg clean
	rm -f your_program callgraph.txt callgraph.png
	rm deps.png deps.mk deps.dot

test:
	gcc -Iinclude tests/test_main.c -o build/test && ./build/test

flash: $(TARGET)
	st-flash write $(TARGET) 0x8000000

help:
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_-]+:($$|\s)' Makefile | cut -d':' -f1 | sort | uniq
	@echo "you can use the following to debug your application: openocd, telnet, and gdb."

.PHONY: all clean flash test cmsis_core cmsis_device disasm readelf_headers symbols_text symbols_undefined size info symbolsize linkermap callgraph-txt callgraph-png depgraph