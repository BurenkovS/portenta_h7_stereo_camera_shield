/*
 * ****************************************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		sections.lds
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Linking script for MCU boot from and run in ITCM / MCU boot from external flash and run in ITCM.
 ******************************************************************************************************************
 */

/* MCU boot from and run in ITCM                */
/* MCU boot from external flash and run in ITCM */
/*
 * RAM size : 8KB, 16KB, 32KB, 64KB, 128KB, 256KB
 * SMEM size : 8KB, 16KB, 32KB, 64KB, 128KB, 256KB
 */
MEMORY
{
    RAM   (wxa!ri)   : ORIGIN = 0x01000000, LENGTH = 8K   /* LENGTH based on hardware configuration of DTCM size */
    SMEM  (rxai!w)   : ORIGIN = 0x02000000, LENGTH = 8K   /* LENGTH based on hardware configuration of ITCM size */
    FLASH (rxw)      : ORIGIN = 0x10400000, LENGTH = 1M
}

ENTRY(start)

SECTIONS {
    _lma_btsec_start = 0;
    .btsec : AT (_lma_btsec_start)
    {
        _vsbtsec = .;
        KEEP(*.o(.btsec))
        . = ALIGN(4);
    } >FLASH
    _lma_btsec_end = _lma_btsec_start + SIZEOF(.btsec);

        
    _lma_text_start = _lma_btsec_end;
    _cp_text_start = _vsbtsec + _lma_text_start;
    .text : AT(_lma_text_start)
    {
    	_vstext = .;
        . = ALIGN(4);
        *(.text)           /* .text sections (code) */
        *(.text*)          /* .text* sections (code) */
        *(.rodata)         /* .rodata sections (constants, strings, etc.) */
        *(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
        *(.srodata)        /* .rodata sections (constants, strings, etc.) */
        *(.srodata*)       /* .rodata* sections (constants, strings, etc.) */
        . = ALIGN(4);
        _etext = .;        /* define a global symbol at end of code */
    } >SMEM	
 	_lma_text_end = _lma_text_start + SIZEOF(.text);
 	_cp_text_end = _vsbtsec + _lma_text_end;
 
 		
 	_lma_ldsec_start = _lma_text_end;
    _cp_ldsec_start = _vsbtsec + _lma_ldsec_start;
    .ldsec : AT (_lma_ldsec_start)
    {
    	_vsloader = .;
        KEEP(*.o(.ldsec))
        . = ALIGN(4);
        _eldsec = .;        /* define a global symbol at end of code */
        _sidata = _eldsec;  /* This is used by the startup in order to initialize the .data secion */
    } >SMEM
    _lma_ldsec_end = _lma_ldsec_start + SIZEOF(.ldsec); 
 	_cp_ldsec_end = _vsbtsec + _lma_ldsec_end;   
 
 	
 	_lma_data_start = _lma_ldsec_end;
 	_cp_data_start = _vsbtsec + _lma_data_start;
    .data : AT (_lma_data_start)
    {
        . = ALIGN(4);
        _sdata = .;        /* create a global symbol at data start; used by startup code in order to initialise the .data section in RAM */
        _ram_start = .;    /* create a global symbol at ram start for garbage collector */
        . = ALIGN(4);
        *(.data)           /* .data sections */
        *(.data*)          /* .data* sections */
        *(.sdata)           /* .sdata sections */
        *(.sdata*)          /* .sdata* sections */
        . = ALIGN(4);
        _edata = .;        /* define a global symbol at data end; used by startup code in order to initialise the .data section in RAM */
    } >RAM
    _lma_data_end = _lma_data_start + SIZEOF(.data);
    _cp_data_end = _vsbtsec + _lma_data_end;
 
 
    .bss :
    {
        . = ALIGN(4);
        _sbss = .;         /* define a global symbol at bss start; used by startup code */
        *(.bss)
        *(.bss*)
        *(.sbss)
        *(.sbss*)
        *(COMMON)

        . = ALIGN(4);
        _ebss = .;         /* define a global symbol at bss end; used by startup code */
    } >RAM

    .heap :
    {
        . = ALIGN(4);
        _heap_start = .;    /* define a global symbol at heap start */
    } >RAM
    
    _lma_eh_frame_start = _lma_data_end;
    .eh_frame : AT (_lma_eh_frame_start)
    {
        . = ALIGN(4);
    } >RAM
}
