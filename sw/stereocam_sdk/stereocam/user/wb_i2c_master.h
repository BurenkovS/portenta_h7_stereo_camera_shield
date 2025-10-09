/*
 * wb_i2c_master.h
 *
 *  Created on: 31 לאנ. 2022 ד.
 *      Author: Ñÿדאוג
 */

#ifndef USER_WB_I2C_MASTER_H_
#define USER_WB_I2C_MASTER_H_

#include <stdbool.h>
#include "picorv32.h"



typedef int32_t status_t;

status_t I2C_Write16(uint8_t dev, uint8_t reg, uint16_t val);

#endif /* USER_WB_I2C_MASTER_H_ */
