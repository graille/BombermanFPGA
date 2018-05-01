library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package PROJECT_PARAMS is
    constant NB_PLAYERS : integer := 4;
    constant ROWS : integer := 12;
    constant COLS : integer := 16;

    constant MILLISECOND_COUNTER_PRECISION : integer := 16;
    constant CLK_COUNTER_PRECISION : integer := 32;

    constant VECTOR_PRECISION : integer := 16;

    constant STATE_PRECISION : integer := 8;

    -- O-----> Y axis
    -- |
    -- |
    -- X axis

    -- Game parameters
    constant NORMAL_MODE_DURATION : integer := 5 * 60 * 1000;
    constant DEATH_MODE_DURATION : integer := 60 * 1000;
end package;

package PROJECT_GAME_STATES is
    -- Choices
    constant STATE_START : integer := 0;
    constant STATE_MENU_LOADING : integer := 1;
    constant STATE_MAP_INIT : integer := 2;
    constant STATE_GAME : integer := 3;
        constant STATE_GAME_PLAYERS_BOMB_CHECK : integer := 4;
        constant STATE_GAME_GRID_UPDATE : integer := 5;
            constant STATE_GAME_BOMB_EXPLODE : integer := 6;
        constant STATE_GAME_CHECK_PLAYERS_DOG : integer := 7;
    constant STATE_DEATH_MODE : integer := 8;
        constant STATE_DEATH_MODE_PLACE_BLOCK : integer := 9;
        constant STATE_DEATH_MODE_CHECK_DEATH : integer := 10;
    constant STATE_GAME_OVER : integer := 11;


    subtype game_state_type is integer range 0 to STATE_GAME_OVER;
end package;


package PROJECT_RECT_PKG is
    constant UP : integer range 0 to 3 := 0;
    constant RIGHT : integer range 0 to 3 := 1;
    constant DOWN : integer range 0 to 3 := 2;
    constant LEFT : integer range 0 to 3 := 3;
end package;

package PROJECT_BLOCKS_PKG is
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.PROJECT_PARAMS.all;

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
        -- from 13 to 31 : Bonus of malus blocks
    subtype block_category_type is natural range 0 to 31;
    type block_type is record
	    category	    : block_category_type;
	    state		    : natural range 0 to STATE_PRECISION - 1;
	    direction		: natural range 0 to 3; -- 0 : Up, 1 : Right, 2 : Down, 3 : Left : See PROJECT_RECT_PKG package
        last_update     : millisecond_count
    end record;
    type td_array_cube_types is array(natural range <>, natural range <>) of block_type;

    type pixel is record
        R               : std_logic_vector(2 downto 0);
        G               : std_logic_vector(2 downto 0);
        B               : std_logic_vector(2 downto 0);
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
	    state		    : natural range 0 to STATE_PRECISION - 1;
	    direction		: natural range 0 to 3; -- 0 : Up, 1 : Right, 2 : Down, 3 : Left : See PROJECT_RECT_PKG package
    end record;



    -- Processed constants
    constant DEFAULT_BLOCK_SIZE : vector := (2**(VECTOR_PRECISION) / COLS, 2**(VECTOR_PRECISION) / COLS);


end package;
