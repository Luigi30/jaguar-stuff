#include "fixed.h"

FIXED_32 FIXED_ADD(FIXED_32 a, FIXED_32 b) { return a+b; }
FIXED_32 FIXED_SUB(FIXED_32 a, FIXED_32 b) { return a-b; }

FIXED_32 FIXED_DIV(FIXED_32 a, FIXED_32 b)
{
  FIXED_32 result;
  uint64_t temp;

  if(b != 0) {
    temp = ((uint64_t)a << 16) / ((uint64_t)b);
    result = temp; //reduce back to a uint32                                                                                                                                         
  }
  else {
    printf("Fixed-point division by zero!\n");
    while(true) {};
  }

  return result;
}
