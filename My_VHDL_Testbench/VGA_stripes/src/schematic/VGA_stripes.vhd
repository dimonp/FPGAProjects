-- Copyright (C) 2018  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details.

-- PROGRAM		"Quartus Prime"
-- VERSION		"Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition"
-- CREATED		"Tue Oct 16 21:36:01 2018"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY VGA_stripes IS 
	PORT
	(
		clk50 :  IN  STD_LOGIC;
		VGA_HSync :  OUT  STD_LOGIC;
		VGA_VSync :  OUT  STD_LOGIC;
		VGA_BlankN :  OUT  STD_LOGIC;
		VGA_Clock :  OUT  STD_LOGIC;
		VGA_SyncN :  OUT  STD_LOGIC;
		VGA_Blue :  OUT  STD_LOGIC_VECTOR(4 DOWNTO 0);
		VGA_Green :  OUT  STD_LOGIC_VECTOR(5 DOWNTO 0);
		VGA_Red :  OUT  STD_LOGIC_VECTOR(4 DOWNTO 0)
	);
END VGA_stripes;

ARCHITECTURE bdf_type OF VGA_stripes IS 

COMPONENT clk108
	PORT(inclk0 : IN STD_LOGIC;
		 c0 : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT stripes_gen
	PORT(pixelClk : IN STD_LOGIC;
		 blankN : IN STD_LOGIC;
		 rgb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;

COMPONENT vga_sync
	PORT(pixelClk : IN STD_LOGIC;
		 hSync : OUT STD_LOGIC;
		 vSync : OUT STD_LOGIC;
		 blankN : OUT STD_LOGIC;
		 pixelClkN : OUT STD_LOGIC
	);
END COMPONENT;

SIGNAL	blank_n :  STD_LOGIC;
SIGNAL	clk_pixel :  STD_LOGIC;
SIGNAL	hsync :  STD_LOGIC;
SIGNAL	rgb :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	vsync :  STD_LOGIC;


BEGIN 
VGA_SyncN <= '0';



b2v_inst : clk108
PORT MAP(inclk0 => clk50,
		 c0 => clk_pixel);


b2v_inst10 : stripes_gen
PORT MAP(pixelClk => clk_pixel,
		 blankN => blank_n,
		 rgb => rgb);


b2v_inst2 : vga_sync
PORT MAP(pixelClk => clk_pixel,
		 hSync => hsync,
		 vSync => vsync,
		 blankN => blank_n,
		 pixelClkN => VGA_Clock);


VGA_HSync <= hsync;
VGA_VSync <= vsync;
VGA_BlankN <= blank_n;
VGA_Blue(4 DOWNTO 0) <= rgb(15 DOWNTO 11);
VGA_Green(5 DOWNTO 0) <= rgb(10 DOWNTO 5);
VGA_Red(4 DOWNTO 0) <= rgb(4 DOWNTO 0);

END bdf_type;