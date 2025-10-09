/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2020 Gowin Semiconductor Technology Co.,Ltd.
 *
 * @file		sections_xip.lds
 * @author		Embedded Development Team
 * @version		V1.2
 * @date		2020-6-30 09:00:00
 * @brief		Linking script for MCU boot from and run in external flash.
 ******************************************************************************************
 */

/* MCU boot from and run in external flash */
/*
 * DTCM size : 8KB, 16KB, 32KB, 64KB, 128KB, 256KB
 * ITCM size : 8KB, 16KB, 32KB, 64KB, 128KB, 256KB
 */
MEMORY
{
    RAM   (wxa!ri)   : ORIGIN = 0x01000000, LENGTH = 8K   /* LENGTH based on hardware configuration of DTCM size */
    SMEM  (rxai!w)   : ORIGIN = 0x02000000, LENGTH = 8K   /* LENGTH based on hardware configuration of ITCM size */
    FLASH (rxw)      : ORIGIN = 0x10400000, LENGTH = 1M
}

ENTRY(start)

SECTIONS {
    /* The program code and other data goes into FLASH */
    _lma_text_start = 0;
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
        _sidata = _etext;  /* This is used by the startup in order to initialize the .data secion */
    } >FLASH	
 	_lma_text_end = _lma_text_start + SIZEOF(.text);
 	
 	_lma_data_start = _lma_text_end;
    /* This is the initialized data section
    The program executes knowing that the data is in the DTCM
    but the loader puts the initial values in the ITCM (inidata).
    It is one task of the startup to copy the initial values from ITCM to DTCM. */
    .data : AT (_lma_data_start)
    {
        . = ALIGN(4);
        _sdata = .;        /* create a global symbol at data start; used by startup code in order to initialise the .data section in DTCM */
        _ram_start = .;    /* create a global symbol at ram start for garbage collector */
        . = ALIGN(4);
        *(.data)           /* .data sections */
        *(.data*)          /* .data* sections */
        *(.sdata)           /* .sdata sections */
        *(.sdata*)          /* .sdata* sections */
        . = ALIGN(4);
        _edata = .;        /* define a global symbol at data end; used by startup code in order to initialise the .data section in DTCM */
    } >DTCM
    _lma_data_end = _lma_data_start + SIZEOF(.data);
    
    . = ALIGN(4);
    _lma_irqsec_start = _lma_data_end;
    _cps_irqsec =  _sidata + SIZEOF(.data);
    .irqsec : AT (_lma_irqsec_start)
    {
    	_vsirqsec = .;
        *.o(.irqsec)
        *.o(.delay)
		*.o(.advspi)
        . = ALIGN(4);
        _veirqsec = .;
    } >ITCM
    _lma_irqsec_end = _lma_irqsec_start + SIZEOF(.irqsec);

    /* Uninitialized data section */
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
    } >DTCM

    /* this is to define the start of the heap, and make sure we have a minimum size */
    .heap :
    {
        . = ALIGN(4);
        _heap_start = .;    /* define a global symbol at heap start */
    } >DTCM
    
    .eh_frame : AT (_lma_irqsec_end)
    {
        . = ALIGN(4);
    } >DTCM
}


