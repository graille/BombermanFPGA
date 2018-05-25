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

architecture Behavioral of vga_controller is
    --Moving Box constants
    constant BOX_WIDTH : natural := 8;
    constant BOX_CLK_DIV : natural := 1000000; --MAX=(2^25 - 1)

    constant BOX_X_MAX : natural := (512 - BOX_WIDTH);
    constant BOX_Y_MAX : natural := (FRAME_HEIGHT - BOX_WIDTH);

    constant BOX_X_MIN : natural := 0;
    constant BOX_Y_MIN : natural := 256;

    constant BOX_X_INIT : std_logic_vector(11 downto 0) := x"000";
    constant BOX_Y_INIT : std_logic_vector(11 downto 0) := x"190"; --400

    signal active : std_logic;

    signal h_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');
    signal v_cntr_reg : std_logic_vector(11 downto 0) := (others =>'0');

    signal h_sync_reg : std_logic := not(H_POL);
    signal v_sync_reg : std_logic := not(V_POL);

    signal h_sync_dly_reg : std_logic := not(H_POL);
    signal v_sync_dly_reg : std_logic :=  not(V_POL);

    signal box_x_reg : std_logic_vector(11 downto 0) := BOX_X_INIT;
    signal box_x_dir : std_logic := '1';
    signal box_y_reg : std_logic_vector(11 downto 0) := BOX_Y_INIT;
    signal box_y_dir : std_logic := '1';
    signal box_cntr_reg : std_logic_vector(24 downto 0) := (others =>'0');

    signal update_box : std_logic;
    

begin

    out_active <= active;

 ------------------------------------------------------
 -------         MOVING BOX LOGIC                ------
 ------------------------------------------------------
    process (pxl_clk)
    begin
        if (rising_edge(pxl_clk)) then
            if (update_box = '1') then
                if (box_x_dir = '1') then
                    box_x_reg <= box_x_reg + 1;
                else
                    box_x_reg <= box_x_reg - 1;
                end if;
                if (box_y_dir = '1') then
                    box_y_reg <= box_y_reg + 1;
                else
                    box_y_reg <= box_y_reg - 1;
                end if;
            end if;
        end if;
    end process;

    process (pxl_clk)
    begin
        if (rising_edge(pxl_clk)) then
            if (update_box = '1') then
                if ((box_x_dir = '1' and (box_x_reg = BOX_X_MAX - 1)) or (box_x_dir = '0' and (box_x_reg = BOX_X_MIN + 1))) then
                    box_x_dir <= not(box_x_dir);
                end if;
                if ((box_y_dir = '1' and (box_y_reg = BOX_Y_MAX - 1)) or (box_y_dir = '0' and (box_y_reg = BOX_Y_MIN + 1))) then
                    box_y_dir <= not(box_y_dir);
                end if;
            end if;
        end if;
    end process;

    process (pxl_clk)
    begin
        if (rising_edge(pxl_clk)) then
            if (box_cntr_reg = (BOX_CLK_DIV - 1)) then
                box_cntr_reg <= (others=>'0');
            else
                box_cntr_reg <= box_cntr_reg + 1;
            end if;
        end if;
    end process;

    update_box <= '1' when box_cntr_reg = (BOX_CLK_DIV - 1) else
    '0';

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
        end if;
    end process;

    active <= '1' when ((h_cntr_reg < FRAME_WIDTH) and (v_cntr_reg < FRAME_HEIGHT)) else '0';
    VGA_HS_O <= h_sync_dly_reg;
    VGA_VS_O <= v_sync_dly_reg;
end Behavioral;
