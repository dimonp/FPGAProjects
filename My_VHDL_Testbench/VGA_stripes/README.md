# VGA stripes

Color stripes generator with FPGA board.  
[Blogpost](http://we.easyelectronics.ru/blog/plis/2713.html)

## Getting Started

[INTEL&reg; FPGAS RESOURCE CENTER](https://www.intel.com/content/www/us/en/products/programmable/fpga/new-to-fpgas/resource-center/getting-started.html)  
[NANDLAND Tutorial - Introduction to VHDL](https://www.nandland.com/vhdl/tutorials/tutorial-introduction-to-vhdl-for-beginners.html)  

## Additional information

[VGA Signal Timing](http://tinyvga.com/vga-timing)  
[Introduce the VGA video standard](http://www.eng.ucy.ac.cy/theocharides/Courses/ECE664/VGA.pdf)  
[VGA Controller (VHDL)](https://www.digikey.com/eewiki/pages/viewpage.action?pageId=15925278)

##### Pin assigments (Cyclone IV EP4CE10F17C8)

| Signal   |      Pin      |
|----------|--------------:|
| clk50 | PIN_E1 |  
| | |
|VGA_Blue[0]|PIN_R6|
|VGA_Blue[1]|PIN_T3|
|VGA_Blue[2]|PIN_R4|
|VGA_Blue[3]|PIN_N5|
|VGA_Blue[4]|PIN_R3|
| | |
|VGA_Green[0]|PIN_N3|
|VGA_Green[1]|PIN_P3|
|VGA_Green[2]|PIN_R1|
|VGA_Green[3]|PIN_T2|
|VGA_Green[4]|PIN_P1|
|VGA_Green[5]|PIN_P2|
| | |
|VGA_Red[0]|PIN_N1|
|VGA_Red[1]|PIN_N2|
|VGA_Red[2]|PIN_L1|
|VGA_Red[3]|PIN_L2|
|VGA_Red[4]|PIN_K5|
| | |
|VGA_VSync|PIN_L7|
|VGA_HSync|PIN_M10|

