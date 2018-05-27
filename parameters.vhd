--------------------------------------------------------------------------------
-- Author : Thibault PIANA
-- This file contains the entire configuration of the project.
-- Please do not modify this file if you do not know what you are doing.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package PROJECT_PARAMS_PKG is
    ---------------------------------------------------------------------------
    -- General parameters
    ---------------------------------------------------------------------------
    constant NB_PLAYERS : integer := 4;
    constant GRID_ROWS : integer := 14;
    constant GRID_COLS : integer := 20;

    constant STATE_PRECISION : integer := 2;
    constant PRNG_PRECISION : integer := 16;
    constant MAX_PLAYER_POWER : integer := 16;

    constant COLOR_BIT_PRECISION : integer := 5;

    constant NB_MAX_CHARACTER_DESIGN : integer := 7;

    -- Screen parameters
    constant FRAME_WIDTH : natural := 800;
    constant FRAME_HEIGHT : natural := 600;

    -- Vectors
    constant VECTOR_PRECISION_Y : integer := 2**12;
    constant VECTOR_PRECISION_X : integer := VECTOR_PRECISION_Y * FRAME_HEIGHT / FRAME_WIDTH; -- Ratio conservation
    
    constant DEFAULT_BLOCK_SIZE_X : integer := VECTOR_PRECISION_X / (GRID_ROWS + 1); -- Last column reserved
    constant DEFAULT_BLOCK_SIZE_Y : integer := VECTOR_PRECISION_Y / GRID_COLS;
    constant DEFAULT_PLAYER_HITBOX_X : integer := DEFAULT_BLOCK_SIZE_X * 2 / 3;
    constant DEFAULT_PLAYER_HITBOX_Y : integer := DEFAULT_BLOCK_SIZE_Y * 2 / 3;
    
    -- Graphic elements
    constant BLOCK_GRAPHIC_WIDTH : integer := FRAME_WIDTH / GRID_COLS;
    constant BLOCK_GRAPHIC_HEIGHT : integer := FRAME_HEIGHT / (GRID_ROWS + 1);

    constant CHARACTER_GRAPHIC_HEIGHT : integer := BLOCK_GRAPHIC_HEIGHT;
    constant CHARACTER_GRAPHIC_WIDTH : integer := BLOCK_GRAPHIC_WIDTH;
    


    -- O-----> Y axis
    -- |
    -- |
    -- X axis

    -- Game parameters
    constant NORMAL_MODE_DURATION : integer := 5 * 60 * 1000;
    constant DEATH_MODE_DURATION : integer := 60 * 1000;

    -- Counter precision
    constant MILLISECOND_COUNTER_PRECISION : integer := integer(ceil(log2(real(NORMAL_MODE_DURATION + DEATH_MODE_DURATION + 60 * 1000)))); -- Max 31 (18 = 4.3 minutes)
    constant CLK_COUNTER_PRECISION : integer := 31; -- Max 31

    ---------------------------------------------------------------------------
    -- Controls parameters
    ---------------------------------------------------------------------------
    type commands_array_type is array(NB_PLAYERS - 1 downto 0) of std_logic_vector(7 downto 0);

    constant CONTROL_SET_FORWARD : commands_array_type := (x"1D", x"43", x"6C", x"75");
    constant CONTROL_SET_LEFT : commands_array_type := (x"1C", x"36", x"71", x"66");
    constant CONTROL_SET_BACK : commands_array_type := (x"1B", x"42", x"69", x"72");
    constant CONTROL_SET_RIGHT : commands_array_type := (x"23", x"46", x"7A", x"74");
    constant CONTROL_SET_BOMB : commands_array_type := (x"01", x"01", x"01", x"01");

    ---------------------------------------------------------------------------
    -- Graphical parameters
    ---------------------------------------------------------------------------
    -- Colors
    constant TRANSPARENT_COLOR : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := (others => '1');
    constant BACKGROUND_COLOR : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := "01010";

    -- More details and values : http://web.mit.edu/6.111/www/s2004/NEWKIT/vga.shtml
    --
    constant H_FP : natural := 40; --H front porch width (pixels)
    constant H_PW : natural := 128; --H sync pulse width (pixels)
    constant H_MAX : natural := 1056; --H total period (pixels)
    --
    constant V_FP : natural := 1; --V front porch width (lines)
    constant V_PW : natural := 4; --V sync pulse width (lines)
    constant V_MAX : natural := 628; --V total period (lines)
    --
    constant H_POL : std_logic := '1';
    constant V_POL : std_logic := '1';
end package;
