SECTIONS {
    . = 0x4000;
    .text: {
      *(.text CODE text)
    }
    . = ALIGN(32);
    .data: {
      VBCC_CONSTRUCTORS
      *(.data DATA data)
    }
    . = ALIGN(32);
    .bss: {
      *(.bss BSS bss)
      *(COMMON)
      _BSS_END = ALIGN(32);
    }
  };