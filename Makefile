.PHONY: \
	ensure-tmp \
	vars \
	help \
	code-fmt \
	clean \
	compile \
	ping \
	link \
	upload

# Hack to get the directory this makefile is in:
MKFILE_PATH := $(lastword $(MAKEFILE_LIST))
MKFILE_DIR := $(notdir $(patsubst %/,%,$(dir $(MKFILE_PATH))))
MKFILE_ABSDIR := $(abspath $(MKFILE_DIR))


BUILDTMP ?= $(MKFILE_DIR)/build-tmp

OPTIMIZATION ?= -Os
AVRCC        ?= $(shell type -p "avr-gcc")
AVRCPP       ?= $(shell type -p "avr-cpp")
PYMCUPROG    ?= $(shell type -p "pymcuprog")
AVR_SIZE     ?= $(shell type -p "avr-size")
AVR_OBJCOPY  ?= $(shell type -p "avr-objcopy")
DEVICE       ?= avr128da28
UDPI_TARGET  ?= $(DEVICE)
CLOCK        ?= 4000000L
PROGRAMMER   ?= stk500v1
BAUD         ?= 115200
HEADERS      = $(shell find $(MKFILE_DIR)/lib -name "*.h")
UNIT         ?= blink

# Misc target info:
help_spacing  := 18

.DEFAULT_GOAL := compile


#---------------------------------------------------------
# Ensure temp directories.
#
# In order to ensure temp dirs exit, we include a file
# that doesn't exist, with a target declared as PHONY
# (above), and then have the target create our tmp dirs.
#---------------------------------------
-include ensure-tmp
ensure-tmp:
	@mkdir -p $(BUILDTMP)

vars: ## Print relevant environment vars
	@printf  "%-20.20s%s\n"  "MKFILE_PATH:"    "$(MKFILE_PATH)"
	@printf  "%-20.20s%s\n"  "MKFILE_DIR:"     "$(MKFILE_DIR)"
	@printf  "%-20.20s%s\n"  "MKFILE_ABSDIR:"  "$(MKFILE_ABSDIR)"
	@printf  "%-20.20s%s\n"  "BUILDTMP:"       "$(BUILDTMP)"
	@printf  "%-20.20s%s\n"  "OPTIMIZATION:"   "$(OPTIMIZATION)"
	@printf  "%-20.20s%s\n"  "AVRCC:"          "$(AVRCC)"
	@printf  "%-20.20s%s\n"  "PYMCUPROG:"      "$(PYMCUPROG)"
	@printf  "%-20.20s%s\n"  "PYMCUPROG_OPTS:" "$(PYMCUPROG_OPTS)"
	@printf  "%-20.20s%s\n"  "AVR_SIZE:"       "$(AVR_SIZE)"
	@printf  "%-20.20s%s\n"  "AVR_OBJCOPY:"    "$(AVR_OBJCOPY)"
	@printf  "%-20.20s%s\n"  "ATPACK:"         "$(ATPACK)"
	@printf  "%-20.20s%s\n"  "DEVICE:"         "$(DEVICE)"
	@printf  "%-20.20s%s\n"  "UDPI_TARGET:"    "$(UDPI_TARGET)"
	@printf  "%-20.20s%s\n"  "CLOCK:"          "$(CLOCK)"
	@printf  "%-20.20s%s\n"  "PROGRAMMER:"     "$(PROGRAMMER)"
	@printf  "%-20.20s%s\n"  "BAUD:"           "$(BAUD)"
	@printf  "%-20.20s%s\n"  "UNIT:"           "$(UNIT)"
	@printf  "%-20.20s%s\n"  "USBDEVICE:"      "$(USBDEVICE)"

help: ## Print this makefile help menu
	@echo "TARGETS:"
	@grep '^[a-z_\-]\{1,\}:.*##' $(MAKEFILE_LIST) \
		| sed 's/^\([a-z_\-]\{1,\}\): *\(.*[^ ]\) *## *\(.*\)/\1:\t\3 (\2)/g' \
		| sed 's/^\([a-z_\-]\{1,\}\): *## *\(.*\)/\1:\t\2/g' \
		| awk '{$$1 = sprintf("%-$(help_spacing)s", $$1)} 1' \
		| sed 's/^/  /'

code-fmt: ## Use uncrustify to format source code
	find "$(MKFILE_DIR)" \
	    \( -iname "*.c" -or -iname "*.h" -or -iname "*.ino" \) \
	    -exec uncrustify -c $(MKFILE_DIR)/uncrustify.cfg \
	    --no-backup '{}' \+

clean: ## Clean build artifacts
	rm -rf $(BUILDTMP)/*
	rm -vf *.s

compile: $(UNIT).c ## Compile project
ifndef ATPACK
	$(error 'ATPACK not defined! Please set ATPACK env var!')
endif # ATPACK
	$(AVRCC) \
	     -c \
	     -Wall \
	     $(OPTIMIZATION) \
	     -DF_CPU=$(CLOCK) \
	     -mmcu=$(DEVICE) \
	     -B$(ATPACK)/gcc/dev/$(DEVICE) \
	     -isystem $(ATPACK)/include \
	     -I$(MKFILE_DIR)/lib \
 	     $(UNIT).c \
	     -o $(BUILDTMP)/$(UNIT).c.o

ping: ## Ping the device using $(PYMCUPROG)
ifndef USBDEVICE
	$(error 'USBDEVICE not defined! Please set USBDEVICE env var!')
endif # USBDEVICE
	 $(PYMCUPROG) ping \
		 -c $(BAUD) \
		 -v info \
		 -d $(UDPI_TARGET) \
		 -t uart \
		 --uart-timeout 2 \
		 -u $(USBDEVICE)

link: compile ## Link compilation artifacts and package for upload
	$(AVRCC) \
	     -w \
	     $(OPTIMIZATION) \
	     -flto \
	     -fuse-linker-plugin \
	     -Wl,--gc-sections \
	     -mmcu=$(DEVICE) \
	     -B$(ATPACK)/gcc/dev/$(DEVICE) \
	     -isystem $(ATPACK)/include \
	     -o $(BUILDTMP)/$(UNIT).c.elf \
	     $(BUILDTMP)/$(UNIT).c.o \
	     -L$(BUILDTMP)
	$(AVR_OBJCOPY) \
	     -O ihex \
	     -j .eeprom \
	     --set-section-flags=.eeprom=alloc,load \
	     --no-change-warnings \
	     --change-section-lma .eeprom=0 \
	     $(BUILDTMP)/$(UNIT).c.elf \
	     $(BUILDTMP)/$(UNIT).c.eep
	$(AVR_OBJCOPY) \
	     -O ihex \
	     -R .eeprom \
	     $(BUILDTMP)/$(UNIT).c.elf \
	     $(BUILDTMP)/$(UNIT).c.hex
	$(AVR_SIZE) \
	     -A $(BUILDTMP)/$(UNIT).c.elf

upload: link ## Upload (NOTE: USBDEVICE must be set)
ifndef USBDEVICE
	$(error 'USBDEVICE not defined! Please set USBDEVICE env var!')
endif # USBDEVICE
	$(PYMCUPROG) write \
		-c $(BAUD) \
		-v info \
		-d $(UDPI_TARGET) \
		-t uart \
		--uart-timeout 2 \
		-u $(USBDEVICE) \
		-f $(BUILDTMP)/$(UNIT).c.hex \
		--erase \
		--verify


fuses: ## Flash the fuses
ifndef USBDEVICE
	$(error 'USBDEVICE not defined! Please set USBDEVICE env var!')
endif # USBDEVICE
	@echo "TODO"
