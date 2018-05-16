library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_RECT_PKG.all;

entity block_ram is
    generic(
        ROWS : integer := 12;
        COLS : integer := 16
    );
    port (
        clk : in std_logic;

        data_a	 : in block_type;
        i_a, i_b : in natural range 0 to (ROWS - 1);
        j_a, j_b : in natural range 0 to (COLS - 1);
        we_a	 : in std_logic := '0';

        q_a		 : out block_type;
        q_b		 : out block_type
    );

end block_ram;

architecture behavioral of block_ram is
	type memory_t is array((ROWS * COLS) - 1 downto 0) of block_type;

	-- Declare the RAM
	signal ram : memory_t;
	signal addr_a, addr_b : natural range 0 to ((ROWS * COLS) - 1);
begin
    addr_a <= i_a * COLS + j_a;
    addr_b <= i_b * COLS + j_b;

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
