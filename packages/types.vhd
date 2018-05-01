library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package PROJECT_TYPES_PKG is
    type array_logic is array(natural range <>) of std_logic;
    type td_array_logic is array(natural range <>, natural range <>) of std_logic;

    -- Type (5 bits), Etat (5 bits) 
    type block_type is record
	    category	    : natural range 0 to 31;
	    state		    : natural range 0 to 15;
	    direction		: natural range 0 to 3;
            -- 0 : North, 1 : East, 2 : South, 3 : West
    end record;

    type td_array_cube_types is array(natural range <>, natural range <>) of block_type;
    type vector is array(1 downto 0) of natural range 0 to 2**16 - 1;
    subtype io_signal is std_logic_vector(7 downto 0);
end package;


package PROJECT_RECT_PKG is
    constant UP_FACE : integer range 0 to 3 := 0;
    constant RIGHT_FACE : integer range 0 to 3 := 1;
    constant DOWN_FACE : integer range 0 to 3 := 2;
    constant LEFT_FACE : integer range 0 to 3 := 3;
end package;