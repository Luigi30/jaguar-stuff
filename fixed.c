#include "fixed.h"

FIXED_32 FIXED_ADD(FIXED_32 a, FIXED_32 b) { return a+b; }
FIXED_32 FIXED_SUB(FIXED_32 a, FIXED_32 b) { return a-b; }

FIXED_32 FIXED_MUL(FIXED_32 a, FIXED_32 b)
{
	FIXED_32 result = 0;
	uint64_t temp, long_a, long_b;
	
	long_a = 0;
	long_b = 0;
	
	if(a & 0x80000000) {
		long_a = 0xFFFFFFFF00000000;
	}
	if(b & 0x80000000)
	{
		long_b = 0xFFFFFFFF00000000;
	}
	
	long_a |= a;
	long_b |= b;
	
	temp = long_a*long_b;
	result = temp >> 16;
	
	//printf("a: %016llX\n", long_a);
	//printf("b: %016llX\n", long_b);
	//result = (a*b) >> 16;
	//printf("result: %016X\n", result);
	return result;
}

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

void FIXED_PRINT(FIXED_32 val)
{
	printf("%5d.%d", (int32_t)FIXED_INT(val), (uint16_t)((FIXED_FRAC(val) / 65536.0) * 10000));
	//printf("%08X ", val);
}
