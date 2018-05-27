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
	    state		    : state_type;                                 -- The state of animation of the block
	    direction		: direction_type;                             -- 0 : Up, 1 : Right, 2 : Down, 3 : Left : See PROJECT_RECT_PKG package
        last_update     : millisecond_count;                          -- Last time the block has been updated, usefull to manage animations
        owner : natural range 0 to NB_PLAYERS - 1;                    -- Only used by bombs and explosions to assign points to players
    end record;
    type td_array_cube_types is array(natural range <>, natural range <>) of block_type;
    constant DEFAULT_BLOCK : block_type := (0, 0, 0, 0, 0);

    -- Info :
    -- O-------> Y axis
    -- |
    -- |
    -- X axis

    type vector is record
        X : natural range 0 to VECTOR_PRECISION_X - 1;
        Y : natural range 0 to VECTOR_PRECISION_Y - 1;
    end record;
    type array_vector is array(natural range <>) of vector;
    constant DEFAULT_VECTOR_POSITION : vector := (0, 0);

    type grid_position is record
        i : natural range 0 to (GRID_ROWS - 1);
        j : natural range 0 to (GRID_COLS - 1);
    end record;
    constant DEFAULT_GRID_POSITION : grid_position := (0, 0);
    constant DEFAULT_LAST_GRID_POSITION : grid_position := (GRID_ROWS - 1, GRID_COLS - 1);

    type screen_position_type is record
        X : integer range 0 to FRAME_HEIGHT - 1;
        Y : integer range 0 to FRAME_WIDTH - 1;
    end record;
    constant DEFAULT_SCREEN_POSITION : screen_position_type := (0, 0);
    constant DEFAULT_LAST_SCREEN_POSITION : screen_position_type := (FRAME_HEIGHT - 1, FRAME_WIDTH - 1);

    subtype pixel_value_type is std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);
    constant DEFAULT_PIXEL_VALUE : pixel_value_type := (others => '1');

    -- IO_Signals
    subtype io_signal is std_logic_vector(7 downto 0);
    type array_io_signal is array(natural range <>) of io_signal;

    -- Type for degrees of liberty (North, East, South, West)
    subtype dol_type is std_logic_vector(3 downto 0);

    -- Players dedicated types
    subtype character_id_type is integer range 0 to NB_MAX_CHARACTER_DESIGN - 1;
    type player_status_type is record
        id              : character_id_type;
	    state		    : state_type;
	    direction		: direction_type; -- 0 : Up, 1 : Right, 2 : Down, 3 : Left : See PROJECT_RECT_PKG package
	    
	    is_activated    : std_logic;
	    is_alive        : std_logic;
    end record;
    type array_player_status_type is array(natural range <>) of player_status_type;
    constant DEFAULT_PLAYER_STATUS : player_status_type := (0, 0, D_DOWN, '1', '1');

    type player_action_category is (
        EMPTY_ACTION,
        PLANT_NORMAL_BOMB
    );

    type player_action is record
        category  : player_action_category;
        created   : millisecond_count;
    end record;
    constant EMPTY_PLAYER_ACTION : player_action := (EMPTY_ACTION, 0);

    type players_positions_type is array(NB_PLAYERS - 1 downto 0) of vector;
    type players_grid_position_type is array(NB_PLAYERS - 1 downto 0) of grid_position;
    type players_power_type is array(NB_PLAYERS - 1 downto 0) of integer range 0 to MAX_PLAYER_POWER - 1;
    type players_action_type is array(NB_PLAYERS - 1 downto 0) of player_action;
    type players_status_type is array(NB_PLAYERS - 1 downto 0) of player_status_type;

    -- Processed constants
    constant DEFAULT_BLOCK_SIZE : vector := (DEFAULT_BLOCK_SIZE_X, DEFAULT_BLOCK_SIZE_Y);
    constant DEFAULT_PLAYER_HITBOX : vector := (DEFAULT_PLAYER_HITBOX_X, DEFAULT_PLAYER_HITBOX_Y);
end package;
