
# Stereo Camera Shield for Arduino Portenta H7

The repository consists of:
 - hw - Gowin FPGA Designer project. Verilog code for FPGA 
 - sw - Gowin MCU Designer project. C code for the integrated RISC-V microcontroller
 - pcb - module schematic, assemble and gerber files

_THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE._
   
## Project description

Stereo camera aka binocular camera shield for Arduino portenta H7. Shield is build on pair of MT9V034 monochrome imaging sensors with global shutter and high dynamic range (HDR) operation. 
Image processing is performed by Gowin GW2AR FPGA with embedded SDRAM.

<img src="https://user-images.githubusercontent.com/16865504/214307833-3e3a0660-f572-4efa-ba7d-4d174b4c0a16.jpg" alt="h7sterecam1" width="300"/>

Global shutter allow to capture images not affected by motion blur. All this make camera module perfect for professional machine vision applications. Gowin GW2AR FPGA have enough resources not only for simple image stitching, but also for comlex preprocessing. Some functions as sensors rectification, filtering,  morphological transformations and so on may be implemented in the future. 

<img src="https://user-images.githubusercontent.com/16865504/214308006-f777c4a0-99e1-41d8-a09b-72813dce607c.jpg" alt="h7sterecam1" width="300"/> <img src="https://user-images.githubusercontent.com/16865504/214307886-1f947933-f801-4622-a5af-4a8aa72c0f90.jpg" alt="h7sterecam1" width="300"/>

RISC-V soft-cpu inside FPGA is used for communication with image sensors and Arduino Portenta board. 

<img src="https://user-images.githubusercontent.com/16865504/214307930-dd9ed489-e82f-4246-8c2d-3810b5594efd.jpg" alt="h7sterecam1" width="300"/>

 **Working examples**
 
  ***Blob detection based distance measurement***
  
 Here is simplified example of distance measurement based on blob detection algorithm, implemented in OpenMV framework:

https://user-images.githubusercontent.com/16865504/214339641-29158f36-7dc3-4a27-aaf4-9f4db2ad2988.mp4

 ***TensorFlow object detection and distance measurement***
 
 The principle is to detect a human figure using a neural network on the left side of the image, search for the corresponding object on the right side of the image using correlation, and calculate the conditional distance to the corresponding objects
 ```python
for i, detection_list in enumerate(net.detect(img, roi=NET_ROI,thresholds=[(math.ceil(min_confidence * 255), 255)]) ):
        if i == 0:
            continue  # background class
        if len(detection_list) == 0:
            continue  # no detections for this class?

        img_template = img.copy(1.0, 1.0, ([x-10, y-10, w+20, h+20]), copy=True)
        r = img.find_template(img_template, 0.7, step=4 , roi=[WINDOW_FRAME_WIDTH, 0, WINDOW_FRAME_WIDTH, WINDOW_FRAME_HEIGH])
```

The size of the doubled frame in this test is 960x240. The object is searched for on the center of left half-frame, inside 240x240 pixel area. When three objects were found on the right frame and, accordingly, three correlation calculations, the processing speed dropped to 4 frames per second.

Scene view : 

![20240923_164213](https://github.com/user-attachments/assets/5eb7fcf3-be3b-456e-ad91-dde59f604d47)

Output : 

<img width="1916" height="486" alt="dist_mes" src="https://github.com/user-attachments/assets/e811657e-3991-4b7c-a97f-f7a78dc1ffa4" />

  
  ***Frame difference mode***
  
The output frame is obtained by subtracting the pixels of the current frame from the previous one. 

![openmv_diff_hw](https://github.com/user-attachments/assets/770583e7-fb1b-4469-91fb-321a2e7d2b00)

***Morphological Transformations***

No filtering:

![openmv_0](https://github.com/user-attachments/assets/87641b7f-fba6-45d3-8075-bb08e5a3812e)

Both filters switched in erosion mode to visually "separate" nearby objects:

![openmv_1](https://github.com/user-attachments/assets/7ebc0178-e8a4-48e3-be0c-05afb4315995)

***Gamma correction***

No correction:

<img width="1203" height="452" alt="image" src="https://github.com/user-attachments/assets/abba7ee3-a120-4456-9180-e0d3b2252881" />

Gamma = 1/2.2:

<img width="1200" height="451" alt="image" src="https://github.com/user-attachments/assets/8e72342e-5b13-4969-af48-a5492435d2cc" />

Luma inversion: 

<img width="1201" height="452" alt="image" src="https://github.com/user-attachments/assets/5f66d1b2-c76b-4aa9-90e0-80153d9704ed" />

Frame difference, morphological transformations and gamma correction performed on FPGA and not affect Arduino resources and FPS. 

 **Features**
 
 - MT9V034 image sensors (monochrome, global shutter, HDR)
 - Gowin GW2AR FPGA with RISC-V soft-cpu core inside
 - SD card
 - ISP with frame-difference, gamma correction and morphological transformations are implemented on FPGA
 
 **Operation**
 
Shield is controlled by I2C interface. 16-bitwidth address and  16-bitwidth data is using. There is 4 address spaces inside:
 -  0 - internal FPGA processor registers. Using for control common camera functions
 -  1 - direct access to MT1 image sensor i2c registers
 -  2 - direct access to MT2 image sensor i2c registers
 -  3 - simultaneously write to both MT1 and MT2 sensors *(not tested yet)*

Number of address space passed in high 8 bits of i2c address, number of register to write is passed in low 8 bits of address.  For example, to write data to MT2 register 0x35(analog gain) user should provide i2c address as 0x0235.

**Internal FPGA processor registers :**

|NAME                |OFFSET|DESCRIPRION|
|----------------|-------------------------------|-----------------------------|
|CAM_EXPOSURE_REG_LOW 	|0x80          |Low 16 bits  of exposure(in 27Mhz ticks)            |
|CAM_EXPOSURE_REG_HIGH	|0x82           |High 16 bits  of exposure(in 27Mhz ticks)            |
|CAM_FRAME_WIDTH			|0x84|Frame width(single image width)|
|CAM_FRAME_HEIGHT			|0x86|Frame height(single image height)|
|CAM_DIFF_MODE			|0x88|Write 1 to enable frame-difference mode|
|CAM_FILTERS_TYPE			|0x8A|Morphological transformations filters mode. See the description below|
|CAM_GAMMA_OFFSET			|0x8C|LUT ram offset for write|
|CAM_GAMMA_VALUE			|0x8E|LUT ram data for write|

 - Writing to CAM_FRAME_WIDTH or CAM_FRAME_HEIGHT updates internal registers. This action also configures the necessary registers in MT1 and MT2 to set the image size and apply offsets, which center the image on the pixel array. The resulting image streamed to the Portenta will have a width of 2 × CAM_FRAME_WIDTH.

 - CAM_FILTERS_TYPE register(See filters block diagram below)
   - CAM_FILTERS_TYPE[1:0] - filter 1 type
   - CAM_FILTERS_TYPE[3:2] - filter 2 type
   - CAM_FILTERS_TYPE[4] - filters enable. Write 0 to switch filters in BYPASS mode

|Filter type 2 bit value|Filter type description|
|----------------|-------------------------------|
| 00  |Pass center pixel from 3x3 kernel |
| 01  |Dilation(max from 3x3 kernel)|
| 10  |Erosion (min from 3x3 kernel)|
| 11  |Median Filtering(median from 3x3 kernel)|


Filters block diagram:

<img width="490" height="190" alt="filters_block" src="https://github.com/user-attachments/assets/5091ed52-ab18-4701-aeb8-a41f01153135" />

 - To initialize the gamma LUT RAM, first write the desired address to the CAM_GAMMA_OFFSET register. Then, write the output value to the CAM_GAMMA_VALUE register. This will update the corresponding LUT entry with the new value.


**FPGA firmware structure**

<img width="1332" height="861" alt="stereocam_struct" src="https://github.com/user-attachments/assets/fa150fe1-d56b-43e3-bf95-e438d479a4a8" />


