SUBDIRS=bl1 saros

ARCH=-march=rv32i
ABI=-mabi=ilp32

SCRIPTS_PATH=$(top_srcdir)/../../scripts

noinst_PROGRAMS=saros.mcs saros.mem

saros.mcs$(EXEEXT): saros/saros.bin
	$(SCRIPTS_PATH)/make_hex.py "" "$<" > "$@".tmp
	mv "$@".tmp "$@"

saros/%:
	$(MAKE) -C saros "$*"
.PRECIOUS: saros/saros.bin

saros.mem$(EXEEXT): saros/saros.bin
	echo "@200000" > "$@.tmp"
	hexdump -ve '16/1 "%02X " "\n"' "$<" >> "$@.tmp"
	mv "$@.tmp" "$@"
