
#ifndef USER_PARAMS_BLOCK_H_
#define USER_PARAMS_BLOCK_H_

#include <stdint.h>

#define	PARAMS_BLOCK_OFFSET		0x30000000			// абсолютный отступ блока параметров, находящегося в ПЛИС-части

// Относительные отступы отдельных параметров
// шаг адресов должен быть кратен, иначе всё зависнет
#define CONTROL_REG_OFFSET			0x00
#define FRAME_HEIGHT_OFFSET			0x04
#define	FRAME_WIDTH_OFFSET			0x08
#define	TARGET_EXPOSURE_LOW_OFFSET 	0x0C
#define	TARGET_EXPOSURE_HIGH_OFFSET 0x10
#define SF2E_LOW_OFFSET				0x14
#define SF2E_HIGH_OFFSET			0x18
#define DIFF_MODE_OFFSET			0x1C
#define FILTERS_TYPE_OFFSET			0x20

//control register bits
#define CONTROL_REG_FLUSH			(1 << 0)
#define CONTROL_REG_ENABLE_MT_DRIVE	(1 << 1)


void cam_param_block_reg_write(uint8_t reg, uint16_t val);
uint16_t cam_param_block_reg_read(uint8_t reg);
void cam_param_block_flush();
void cam_param_block_flush_and_drive();

#endif//USER_PARAMS_BLOCK_H_
