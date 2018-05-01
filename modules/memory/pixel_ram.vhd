library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_RECT_PKG.all;

entity pixel_ram is
generic (
    WIDTH   : integer := 800;
    HEIGHT  : integer := 600
);
port (
    -- Port A
    a_clk   : in  std_logic;
    a_wr    : in  std_logic;
    a_addr  : in  natural range 0 to (WIDTH * HEIGHT) - 1;
    a_din   : in  pixel;
    a_dout  : out pixel;
     
    -- Port B
    b_clk   : in  std_logic;
    b_addr  : in  natural range 0 to (WIDTH * HEIGHT) - 1;
    b_dout  : out pixel
);
end pixel_ram;
 
architecture rtl of pixel_ram is
    -- Shared memory
    type mem_type is array (((WIDTH * HEIGHT) - 1) downto 0 ) of pixel;
    signal mem : mem_type;
begin
 
    -- Port A
    process(a_clk)
    begin
        if(a_clk'event and a_clk='1') then
            if(a_wr='1') then
                mem(a_addr) <= a_din;
            end if;
            a_dout <= mem(a_addr);
        end if;
    end process;
    
    -- Port B
    process(b_clk)
    begin
        if(b_clk'event and b_clk='1') then
            b_dout <= mem(b_addr);
        end if;
    end process;
     
end rtl;