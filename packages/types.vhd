library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package PROJECT_TYPES_PKG is
    type array_logic is array(natural range <>) of std_logic;
    type td_array_logic is array(natural range <>, natural range <>) of std_logic;
    -- Cubes types
        -- 0 = empty block
        -- 1..3 = unbreakable block type 0,1,2
        -- 4..6 = breakeable block type 0,1,2

        -- 7..9 = Bombs type 0,1,2
        -- 10-12 : Explosion
        -- from 13 to 31 : Bonus of malus blocks
    subtype block_category_type: natural range 0 to 31;
    type block_type is record
	    category	    : block_category_type;
	    state		    : natural range 0 to 7;
	    direction		: natural range 0 to 3;
            -- 0 : Up, 1 : Right, 2 : Down, 3 : Left : See PROJECT_RECT_PKG package
    end record;
    type td_array_cube_types is array(natural range <>, natural range <>) of block_type;

    type pixel is record
        R               : std_logic_vector(2 downto 0);
        G               : std_logic_vector(2 downto 0);
        B               : std_logic_vector(2 downto 0);
    end record;
    type array_pixel is array(natural range <>) of pixel;

    type vector is array(1 downto 0) of natural range 0 to 2**16 - 1;

    -- IO_Signals
    subtype io_signal is std_logic_vector(7 downto 0);
    type array_io_signal is array(natural range <>) of io_signal;

    -- Type for degrees of liberty (North, East, South, West)
    subtype dol_type is std_logic_vector(3 downto 0);

    type player_status_type is record
	    state		    : natural range 0 to 7;
	    direction		: natural range 0 to 3;
            -- 0 : Up, 1 : Right, 2 : Down, 3 : Left : See PROJECT_RECT_PKG package
    end record;
end package;


package PROJECT_RECT_PKG is
    constant UP : integer range 0 to 3 := 0;
    constant RIGHT : integer range 0 to 3 := 1;
    constant DOWN : integer range 0 to 3 := 2;
    constant LEFT : integer range 0 to 3 := 3;
end package;
