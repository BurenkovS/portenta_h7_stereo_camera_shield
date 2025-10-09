/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		config.h
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Configuartion.
 ******************************************************************************************
 */

#ifndef CONFIG_H_
#define CONFIG_H_

//User configures MCU boot mode
/*
 * BUILD_LOAD : MCU boot from and run in ITCM
 *              sections.lds
 * BUILD_BURN : MCU boot from external flash and run in ITCM
 *              sections.lds
 * BUILD_XIP  : MCU boot from and run in external flash
 *              sections_xip.lds
 *
 * */
#define BUILD_LOAD 0  // MCU boot from and run in ITCM, must use sections.lds as linker script!
#define BUILD_BURN 1  // MCU boot from external flash and run in ITCM, must use sections.lds as linker script!
#define BUILD_XIP  2  // MCU boot from and run in external flash, must use sections_xip.lds as linker script!

#define BUILD_MODE BUILD_LOAD

#endif /* CONFIG_H_ */
