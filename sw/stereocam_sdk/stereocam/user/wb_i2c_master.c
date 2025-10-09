#include "wb_i2c_master.h"

status_t I2C_Write16(uint8_t dev, uint8_t reg, uint16_t val)
{
	uint32_t *addr_p;
	addr_p = (uint32_t*)(OPEN_WB_BASE + (dev << 16) + (reg << 8));
	*addr_p = (uint32_t)val;
	return 0;
}
