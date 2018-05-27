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
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;

entity vga_controller is
    port (
        pxl_clk : in  STD_LOGIC;
        
        VGA_HS_O : out  STD_LOGIC;
        VGA_VS_O : out  STD_LOGIC;

        out_active : out std_logic;
        VGA_POSITION : out screen_position_type
    );
end vga_controller;

architecture behavioral of vga_controller is
    signal active : std_logic;

    signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');

    signal h_sync_reg : std_logic := not(H_POL);
    signal v_sync_reg : std_logic := not(V_POL);

    signal h_sync_dly_reg : std_logic := not(H_POL);
    signal v_sync_dly_reg : std_logic :=  not(V_POL);
begin
    out_active <= active;
    
    ------------------------------------------------------
    -------         SYNC GENERATION                 ------
    ------------------------------------------------------
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

    process(v_cntr_reg, h_cntr_reg)
    begin
        if v_cntr_reg < FRAME_HEIGHT and h_cntr_reg < FRAME_WIDTH then
            VGA_POSITION.X <= to_integer(unsigned(v_cntr_reg));
            VGA_POSITION.Y <= to_integer(unsigned(h_cntr_reg));
        else
            VGA_POSITION.X <= 0;
            VGA_POSITION.Y <= 0;
        end if;
    end process;

    active <= '1' when ((h_cntr_reg < FRAME_WIDTH) and (v_cntr_reg < FRAME_HEIGHT)) else '0';
    VGA_HS_O <= h_sync_dly_reg;
    VGA_VS_O <= v_sync_dly_reg;
end behavioral;
