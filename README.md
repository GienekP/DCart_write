This is sample code demonstrating how to write to the flash memory of a DCart cartridge. The example shows how to define banks in MADS and how to place routines within the $D5 page area. The sector used for the write operation is the first 256 bytes.

1) Read byte, X register which byte
		ldx # which
		jsr READDC
		
2) Erase sector, fill $FF
		jsr ERASEDC

3) Write byte, X register which byte, A register value
		lda # what
		ldx # where
		jsr WRITEDC
