#include "dsp.h"

void DSP_LOAD_MATRIX_PROGRAM() {
  jag_dsp_load(D_RAM, dsp_matrix_functions, dsp_matrix_functions_end-dsp_matrix_functions);
}

void DSP_START(uint8_t *function) {
  MMIO32(D_PC) = 0xF1B000 + (uint32_t)(function - dsp_matrix_functions);
  //printf("DSP running from 0x%08X\n", calculated_pc);
  MMIO32(D_CTRL) = MMIO32(D_CTRL) | 0x01;
}

#define DSP_WAIT() ( jag_dsp_wait() )
