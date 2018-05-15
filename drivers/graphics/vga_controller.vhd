----------------------------------------------------------------------------------
-- Company: Digilent
-- Engineer: Arthur Brown
--
--
-- Create Date:    13:01:51 02/15/2013
-- Project Name:   pmodvga
-- Target Devices: arty
-- Tool versions:  2016.4
-- Additional Comments:
--
-- Copyright Digilent 2017
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

use work.PROJECT_PARAMS_PKG.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity VGA_CONTROLLER is
    port ( 
        CLK_I : in  STD_LOGIC;
        CLK_O : out STD_LOGIC;
        VGA_HS_O : out  STD_LOGIC;
        VGA_VS_O : out  STD_LOGIC
    );
end VGA_CONTROLLER;

architecture Behavioral of VGA_CONTROLLER is
    component clk_wiz_0
    port (
        CLK_IN1           : in     std_logic; -- Clock in ports
        CLK_OUT1          : out    std_logic -- Clock out ports
    );
    end component;

    --Sync Generation constants

    ----***640x480@60Hz***--  Requires 25 MHz clock
    --constant FRAME_WIDTH : natural := 640;
    --constant FRAME_HEIGHT : natural := 480;

    --constant H_FP : natural := 16; --H front porch width (pixels)
    --constant H_PW : natural := 96; --H sync pulse width (pixels)
    --constant H_MAX : natural := 800; --H total period (pixels)

    --constant V_FP : natural := 10; --V front porch width (lines)
    --constant V_PW : natural := 2; --V sync pulse width (lines)
    --constant V_MAX : natural := 525; --V total period (lines)

    --constant H_POL : std_logic := '0';
    --constant V_POL : std_logic := '0';

    ----***800x600@60Hz***--  Requires 40 MHz clock
    --constant FRAME_WIDTH : natural := 800;
    --constant FRAME_HEIGHT : natural := 600;
    --
    --constant H_FP : natural := 40; --H front porch width (pixels)
    --constant H_PW : natural := 128; --H sync pulse width (pixels)
    --constant H_MAX : natural := 1056; --H total period (pixels)
    --
    --constant V_FP : natural := 1; --V front porch width (lines)
    --constant V_PW : natural := 4; --V sync pulse width (lines)
    --constant V_MAX : natural := 628; --V total period (lines)
    --
    --constant H_POL : std_logic := '1';
    --constant V_POL : std_logic := '1';


    ----***1280x720@60Hz***-- Requires 74.25 MHz clock
    --constant FRAME_WIDTH : natural := 1280;
    --constant FRAME_HEIGHT : natural := 720;
    --
    --constant H_FP : natural := 110; --H front porch width (pixels)
    --constant H_PW : natural := 40; --H sync pulse width (pixels)
    --constant H_MAX : natural := 1650; --H total period (pixels)
    --
    --constant V_FP : natural := 5; --V front porch width (lines)
    --constant V_PW : natural := 5; --V sync pulse width (lines)
    --constant V_MAX : natural := 750; --V total period (lines)
    --
    --constant H_POL : std_logic := '1';
    --constant V_POL : std_logic := '1';

    ----***1280x1024@60Hz***-- Requires 108 MHz clock
    --constant FRAME_WIDTH : natural := 1280;
    --constant FRAME_HEIGHT : natural := 1024;

    --constant H_FP : natural := 48; --H front porch width (pixels)
    --constant H_PW : natural := 112; --H sync pulse width (pixels)
    --constant H_MAX : natural := 1688; --H total period (pixels)

    --constant V_FP : natural := 1; --V front porch width (lines)
    --constant V_PW : natural := 3; --V sync pulse width (lines)
    --constant V_MAX : natural := 1066; --V total period (lines)

    --constant H_POL : std_logic := '1';
    --constant V_POL : std_logic := '1';

    --***1920x1080@60Hz***-- Requires 148.5 MHz pxl_clk
    --constant FRAME_WIDTH : natural := 1920;
    --constant FRAME_HEIGHT : natural := 1080;

    --constant H_FP : natural := 88; --H front porch width (pixels)
    --constant H_PW : natural := 44; --H sync pulse width (pixels)
    --constant H_MAX : natural := 2200; --H total period (pixels)

    --constant V_FP : natural := 4; --V front porch width (lines)
    --constant V_PW : natural := 5; --V sync pulse width (lines)
    --constant V_MAX : natural := 1125; --V total period (lines)

    --constant H_POL : std_logic := '1';
    --constant V_POL : std_logic := '1';

    signal pxl_clk : std_logic;

    signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');

    signal h_sync_reg : std_logic := not(H_POL);
    signal v_sync_reg : std_logic := not(V_POL);

    signal h_sync_dly_reg : std_logic := not(H_POL);
    signal v_sync_dly_reg : std_logic :=  not(V_POL);

    signal update_box : std_logic;
    signal pixel_in_box : std_logic;
begin

clk_div_inst : clk_wiz_0
  port map
   (-- Clock in ports
    CLK_IN1 => CLK_I,
    -- Clock out ports
    CLK_OUT1 => pxl_clk);

 ------------------------------------------------------
 -------         SYNC GENERATION                 ------
 ------------------------------------------------------
  CLK_O <= pxl_clk;
  
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (h_cntr_reg = (H_MAX - 1)) then
        h_cntr_reg <= (others =>'0');
      else
        h_cntr_reg <= h_cntr_reg + 1;
      end if;
    end if;
  end process;

  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if ((h_cntr_reg = (H_MAX - 1)) and (v_cntr_reg = (V_MAX - 1))) then
        v_cntr_reg <= (others =>'0');
      elsif (h_cntr_reg = (H_MAX - 1)) then
        v_cntr_reg <= v_cntr_reg + 1;
      end if;
    end if;
  end process;

  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (h_cntr_reg >= (H_FP + FRAME_WIDTH - 1)) and (h_cntr_reg < (H_FP + FRAME_WIDTH + H_PW - 1)) then
        h_sync_reg <= H_POL;
      else
        h_sync_reg <= not(H_POL);
      end if;
    end if;
  end process;


  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      if (v_cntr_reg >= (V_FP + FRAME_HEIGHT - 1)) and (v_cntr_reg < (V_FP + FRAME_HEIGHT + V_PW - 1)) then
        v_sync_reg <= V_POL;
      else
        v_sync_reg <= not(V_POL);
      end if;
    end if;
  end process;
  
  process (pxl_clk)
  begin
    if (rising_edge(pxl_clk)) then
      v_sync_dly_reg <= v_sync_reg;
      h_sync_dly_reg <= h_sync_reg;
    end if;
  end process;

  VGA_HS_O <= h_sync_dly_reg;
  VGA_VS_O <= v_sync_dly_reg;
end Behavioral;
