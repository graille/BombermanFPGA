library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;

entity block_ram is
    port (
        clk : in std_logic;

        data_a	 : in block_type;
        p_a, p_b : in grid_position;
        we_a	 : in std_logic := '0';

        q_a		 : out block_type;
        q_b		 : out block_type
    );
end block_ram;

architecture behavioral of block_ram is
	type memory_t is array((GRID_ROWS * GRID_COLS) - 1 downto 0) of block_type;

	-- Declare the RAM
	signal ram : memory_t;
	signal addr_a, addr_b : natural range 0 to ((GRID_ROWS * GRID_COLS) - 1);
begin
    addr_a <= p_a.i * GRID_COLS + p_a.j;
    addr_b <= p_b.i * GRID_COLS + p_b.j;

	-- Port A
	process(clk)
	begin
		if rising_edge(clk) then
            if we_a = '1' then
                ram(addr_a) <= data_a;
            end if;
            q_a <= ram(addr_a);
		end if;
	end process;

    -- Port B
    process(clk)
    begin
        if rising_edge(clk) then
            q_b <= ram(addr_b);
        end if;
    end process;
end behavioral;
