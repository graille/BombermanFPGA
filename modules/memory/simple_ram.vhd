--
-- Adapted from Altera RAM model : https://www.altera.com/support/support-resources/design-examples/design-software/vhdl/vhd-single-port-ram.html
--

library ieee;
use ieee.std_logic_1164.all;

entity single_port_ram is
  generic (
      L_ADDRESS : integer := 6;  -- Number of bits on which the address is coded
      L_DATA_BUS : integer := 8  -- Number of bits of the data
  );
	port
	(
		data	: in std_logic_vector(L_DATA_BUS - 1 downto 0);  -- Input data
		addr	: in natural range 0 to (2**L_ADDRESS - 1);  -- Address
		we		: in std_logic := '0';  -- Write Enable
		clk		: in std_logic;  -- Clock
		q		: out std_logic_vector(L_DATA_BUS - 1 downto 0)  -- Output data
	);
end entity;

architecture behavioral of single_port_ram is
	-- Build a 2-D array type for the RAM
	subtype word_t is std_logic_vector(L_DATA_BUS - 1 downto 0);
	type memory_t is array(2**L_ADDRESS - 1 downto 0) of word_t;

	-- Declare the RAM signal.
	signal ram : memory_t;

	-- Register to hold the address
	signal addr_reg : natural range 0 to (2**L_ADDRESS - 1);
begin
    process(clk)
    begin
    	if(rising_edge(clk)) then
    		if(we = '1') then
    			ram(addr) <= data;
    		end if;

    		-- Register the address for reading
    		addr_reg <= addr;
    	end if;

    end process;
    q <= ram(addr_reg);
end behavioral;
