
# Stereo Camera Shield for Arduino Portenta H7

## Project description

Stereo camera aka binocular camera shield for Arduino portenta H7. Shield is build on pair of MT9V034 monochrome imaging sensors with global shutter and high dynamic range (HDR) operation. 
Image processing is performed by Gowin GW2AR FPGA with embedded SDRAM.

<img src="https://user-images.githubusercontent.com/16865504/214307833-3e3a0660-f572-4efa-ba7d-4d174b4c0a16.jpg" alt="h7sterecam1" width="300"/>

Global shutter allow to capture images not affected by motion blur. All this make camera module perfect for professional machine vision applications. Gowin GW2AR FPGA have enough resources not only for simple image stitching, but also for comlex preprocessing. Some functions as sensors rectification, filtering,  morphological transformations and so on may be implemented in the future. 

<img src="https://user-images.githubusercontent.com/16865504/214308006-f777c4a0-99e1-41d8-a09b-72813dce607c.jpg" alt="h7sterecam1" width="300"/> <img src="https://user-images.githubusercontent.com/16865504/214307886-1f947933-f801-4622-a5af-4a8aa72c0f90.jpg" alt="h7sterecam1" width="300"/>

RISC-V soft-cpu inside FPGA is used for communication with image sensors and Arduino Portenta board. 

<img src="https://user-images.githubusercontent.com/16865504/214307930-dd9ed489-e82f-4246-8c2d-3810b5594efd.jpg" alt="h7sterecam1" width="300"/>

 **Features**
 - MT9V034 image sensors (monochrome, global shutter, HDR)
 - Gowin GW2AR FPGA with RISC-V soft-cpu core inside
 - SD card 
 
 **Operation**
Shield is controlled by I2C interface. 16-bitwidth address and  16-bitwidth data is using. There is 4 address spaces inside:
 -  0 - internal FPGA processor registers. Using for control common camera functions
 -  1 - direct access to MT1 image sensor i2c registers
 -  2 - direct access to MT2 image sensor i2c registers
 -  3 - simultaneously write to both MT1 and MT2 sensors *(not tested yet)*
Number of address space passed in high 8 bits of i2c address, number of register to wite is passed in low 8 bits of address.  For example, to wite data to MT2 register 0x35(analog gain) user should provide i2c address as 0x0235.

**Internal FPGA processor registers :**

|NAME                |OFFSET|DESCRIPRION|
|----------------|-------------------------------|-----------------------------|
|CAM_EXPOSURE_REG_LOW 	|0x80          |Low 16 bits  of exposure(in 27Mhz ticks)            |
|CAM_EXPOSURE_REG_HIGH	|0x82           |High 16 bits  of exposure(in 27Mhz ticks)            |
|CAM_FRAME_WIDTH			|0x84|Frame width(single image width)|
|CAM_FRAME_HEIGHT			|0x86|Frame height(single image width)|

When writing to CAM_FRAME_WIDTH or CAM_FRAME_HEIGHT, internal registers will update and also necessary registers of MT1 and MT2 will configure image size and offsets to allign image to the center of pixels array. The result image, which will stream to Portenta will have 2xCAM_FRAME_WIDTH width. 
