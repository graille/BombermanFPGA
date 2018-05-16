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

architecture behavioral of VGA_CONTROLLER is
    component clk_divider is
        generic (
            N : integer
        )
        port (
            clk, rst: in std_logic;
            clock_out: out std_logic
        );
    end component;


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
    CLK_DIVISER_INSTANCE : clk_divider
        generic map (
            N => 2
        )
        port map (
            rst => '0',
            clk => CLK_I,
            clock_out => pxl_clk
        );

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

end behavioral;
