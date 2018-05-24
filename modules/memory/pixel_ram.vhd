library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;

entity pixel_ram is
port (
    -- Port A
    a_clk   : in  std_logic;
    a_wr    : in  std_logic;
    a_pos   : in  screen_position_type;
    a_din   : in  std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);
    
    a_dout  : out std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);

    -- Port B
    b_clk   : in  std_logic;
    b_pos  : in  screen_position_type;
    b_dout  : out std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0)
);
end pixel_ram;

architecture rtl of pixel_ram is
    constant SIZE : integer := (FRAME_WIDTH * FRAME_HEIGHT);

    -- Shared memory
    type mem_type is array ((SIZE - 1) downto 0) of std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);
    signal mem : mem_type := (others => std_logic_vector(to_unsigned(0, COLOR_BIT_PRECISION))); -- White screen
    signal a_addr, b_addr : integer range 0 to SIZE - 1;
begin
    a_addr <= a_pos.X * FRAME_WIDTH + a_pos.Y;
    b_addr <= b_pos.X * FRAME_WIDTH + b_pos.Y;
    
    -- Port A (Graphic controller)
    process(a_clk)
    begin
        if rising_edge(a_clk) then
            if a_wr = '1' then
                mem(a_addr) <= a_din;
            end if;
            a_dout <= mem(a_addr);
        end if;
    end process;

    -- Port B (VGA controller)
    process(b_clk)
    begin
        if rising_edge(b_clk) then
            b_dout <= mem(b_addr);
        end if;
    end process;
end rtl;
