import math

sine_table = []

for i in xrange(45, 46):
	rad = math.radians(i)
	sine_value = round(math.sin(rad) * 65535)
	sine_table.append(sine_value)

hex_values = []
	
for x in sine_table:
	hex_value = 0

	if x < 0:
		hex_value = int(x) & 0xFFFF
		hex_value |= 0xFFFF0000
	else:
		hex_value = int(x) & 0xFFFF
		
	hex_values.append(hex_value)
	#print "0x" + format(hex_value, "08X")
	
print ["0x" + format(x, "08X") for x in hex_values]
