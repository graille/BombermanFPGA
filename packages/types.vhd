library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;

package PROJECT_TYPES_PKG is
    -- Timer types
    subtype millisecond_count is integer range 0 to 2**(MILLISECOND_COUNTER_PRECISION) - 1;
    subtype clk_count is integer range 0 to 2**(CLK_COUNTER_PRECISION) - 1;

    type array_logic is array(natural range <>) of std_logic;
    type td_array_logic is array(natural range <>, natural range <>) of std_logic;
    -- Cubes types
        -- 0 = empty block
        -- 1..3 = unbreakable block type 0,1,2
        -- 4..6 = breakeable block type 0,1,2

        -- 7..9 = Bombs type 0,1,2
        -- 10-12 : Explosion
        -- from 13 to 31 : Bonus and malus blocks
    subtype block_category_type is natural range 0 to 31;
    subtype state_type is natural range 0 to 2**STATE_PRECISION - 1;
    type block_type is record
	    category	    : block_category_type;                        -- The block category (see dedicated package)
	    state		    : state_type;  -- The state of animation of the block
	    direction		: direction_type;                       -- 0 : Up, 1 : Right, 2 : Down, 3 : Left : See PROJECT_RECT_PKG package
        last_update     : millisecond_count;                          -- Last time the block has been updated, usefull to manage animations
        owner : natural range 0 to NB_PLAYERS - 1;                    -- Only used by bombs and explosions to assign points to players
    end record;
    type td_array_cube_types is array(natural range <>, natural range <>) of block_type;

    type pixel is record
        R               : std_logic_vector(PIXEL_PRECISION - 1 downto 0);
        G               : std_logic_vector(PIXEL_PRECISION - 1 downto 0);
        B               : std_logic_vector(PIXEL_PRECISION - 1 downto 0);
    end record;
    type array_pixel is array(natural range <>) of pixel;

    type vector is record
        X               : natural range 0 to (2**VECTOR_PRECISION) - 1;
        Y               : natural range 0 to (2**VECTOR_PRECISION) - 1;
    end record;

    -- IO_Signals
    subtype io_signal is std_logic_vector(7 downto 0);
    type array_io_signal is array(natural range <>) of io_signal;

    -- Type for degrees of liberty (North, East, South, West)
    subtype dol_type is std_logic_vector(3 downto 0);

    type player_status_type is record
	    state		    : state_type;
	    direction		: direction_type; -- 0 : Up, 1 : Right, 2 : Down, 3 : Left : See PROJECT_RECT_PKG package
    end record;

    -- Processed constants
    constant DEFAULT_BLOCK_SIZE : vector := (2**(VECTOR_PRECISION) / COLS, 2**(VECTOR_PRECISION) / COLS);


end package;
