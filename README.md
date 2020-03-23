# PS/2 Interface Chip
The PS/2 Interface Chip can link a keyboard or mouse to any host system via an 8-bit data bus and a few control line. It provides all the logic needed to convert between the PS/2 protocol and the host bus while offering a straightforward host interface making it ideal for embedded microcontroller and microprocessor designs.

The PS/2 Interface Chip project page, with user manual and hardware files, can be found [here](https://sites.google.com/view/m-chips/ps2)

## Archive content

The following files are provided:
* HostInterface.vhd - Source code file
* MicrosecondGenerator.vhd - Source code file
* PS2.vhd - Source code file
* PS2Interface.vhd - Source code file
* ReceiveBuffer.vhd - Source code file
* Status.vhd - Source code file
* PS2.ucf - Configuration file
* PS2.jed - JEDEC Program file
* LICENSE - License text
* README.md - This file

## Prerequisites

Xilinx’s ISE WebPACK Design Suite version 14.7 is required to do a build and can be obtained [here](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive-ise.html)

Familiarity with the use and operation of the Xilinx ISE Design Suite is assumed and beyond the scope of this readme file.

## Installing

Place the source files into any convenient location on your PC.  NOTE:  The Xilinx ISE Design Suite can not handle spaces in directory and file names.

The JEDEC Program file PS2.jed was created with Xilinx ISE WebPACK Design Suite version 14.7.  This can be used to program the Xilinx XC9572XL-10VQG44C CPLD without any further setup.  If you wish to do a build continue with the following steps.

Create a project called PS2 using the XC9572XL CPLD in a VQ44 package with a speed of -10.\
Set the following for the project:\
Top-Level Source Type = HDL\
Synthesis Tool = XST (VHDL/Verilog)\
Simulator ISim (VHDL/Verilog)\
Perferred Language = VHDL\
VHDL Source Analysis Standard = VHDL-93

Add the source code and configuration file to the project.

Synthesis options need to be set as:  
Input File Name                    : "PS2.prj"\
Input Format                       : mixed\
Ignore Synthesis Constraint File   : NO\
Output File Name                   : "PS2"\
Output Format                      : NGC\
Target Device                      : XC9500XL CPLDs\
Top Module Name                    : PS2\
Automatic FSM Extraction           : YES\
FSM Encoding Algorithm             : Auto\
Safe Implementation                : No\
Mux Extraction                     : Yes\
Resource Sharing                   : YES\
Add IO Buffers                     : YES\
MACRO Preserve                     : YES\
XOR Preserve                       : YES\
Equivalent register Removal        : YES\
Optimization Goal                  : Speed\
Optimization Effort                : 1\
Keep Hierarchy                     : Yes\
Netlist Hierarchy                  : As_Optimized\
RTL Output                         : Yes\
Hierarchy Separator                : /\
Bus Delimiter                      : <>\
Case Specifier                     : Maintain\
Verilog 2001                       : YES\
Clock Enable                       : YES\
wysiwyg                            : NO

Fitter options need to be set as:\
Device(s) Specified                         : xc9572xl-10-VQ44\
Optimization Method                         : SPEED\
Multi-Level Logic Optimization              : ON\
Ignore Timing Specifications                : OFF\
Default Register Power Up Value             : LOW\
Keep User Location Constraints              : ON\
What-You-See-Is-What-You-Get                : OFF\
Exhaustive Fitting                          : OFF\
Keep Unused Inputs                          : OFF\
Slew Rate                                   : FAST\
Power Mode                                  : STD\
Ground on Unused IOs                        : ON\
Set I/O Pin Termination                     : FLOAT\
Global Clock Optimization                   : ON\
Global Set/Reset Optimization               : ON\
Global Ouput Enable Optimization            : ON\
Input Limit                                 : 54\
Pterm Limit                                 : 25

The design can now be implemented.

## Built With

* [Xilinx’s ISE WebPACK Design Suite version 14.7](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive-ise.html) - The development, simulation, and programming environment used

## Version History

* v1.0.0 - 2015 
	- Initial release

## Authors

* **Donald J Bartley** - *Initial work* - [djbcoffee](https://github.com/djbcoffee)

## License

This project is licensed under the GNU Public License 2 - see the [LICENSE](LICENSE) file for details
