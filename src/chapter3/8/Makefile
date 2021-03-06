# chapter3/8/Makefile
#
# Author: Wenbo Yang <http://yangwenbo.com>
#
# This file is part of the source code of book "Write Your Own OS with Free
# and Open Source Software". Homepage @ <https://github.com/solrex/writeos>.
#
# This file is licensed under the GNU General Public License; either
# version 3 of the License, or (at your option) any later version. 

CC=gcc
LD=ld
OBJCOPY=objcopy

CFLAGS=-c
TRIM_FLAGS=-R .pdr -R .comment -R.note -S -O binary

LDFILE_BOOT=solrex_x86_boot.ld
LDFILE_DOS=solrex_x86_dos.ld
LDFLAGS_BOOT=-T$(LDFILE_BOOT)
LDFLAGS_DOS=-T$(LDFILE_DOS)

all: boot.img LOADER.BIN
	@echo '#################################################################'
	@echo '# Compiling work finished, now you can use "sudo make copy" to'
	@echo '# copy LOADER.BIN into boot.img'
	@echo '#################################################################'

boot.bin: boot.S
	$(CC) $(CFLAGS) boot.S
	$(LD) boot.o -o boot.elf $(LDFLAGS_BOOT)
	$(OBJCOPY) $(TRIM_FLAGS) boot.elf $@

LOADER.BIN: loader.S
	$(CC) $(CFLAGS) loader.S
	$(LD) loader.o -o loader.elf $(LDFLAGS_DOS)
	$(OBJCOPY) $(TRIM_FLAGS) loader.elf $@

boot.img: boot.bin
	@dd if=boot.bin of=boot.img bs=512 count=1
	@dd if=/dev/zero of=boot.img skip=1 seek=1 bs=512 count=2879

# You must have the authority to do mount, or you must use "su root" or
# "sudo" command to do "make copy"
copy: boot.img LOADER.BIN
	@mkdir -p /tmp/floppy;\
	mount -o loop boot.img /tmp/floppy/ -o fat=12;\
	cp LOADER.BIN /tmp/floppy/;\
	umount /tmp/floppy/;\
	rm -rf /tmp/floppy/;

clean: 
	@rm -f *.o *.elf *.bin *.BIN

distclean: clean
	@rm -f boot.img

release: clean
	@mv boot.img solrex.img
