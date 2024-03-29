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
    
    -- Graphic elements
    constant BLOCK_GRAPHIC_WIDTH : integer := FRAME_WIDTH / GRID_COLS;
    constant BLOCK_GRAPHIC_HEIGHT : integer := FRAME_HEIGHT / (GRID_ROWS + 1);

    constant CHARACTER_GRAPHIC_HEIGHT : integer := BLOCK_GRAPHIC_HEIGHT;
    constant CHARACTER_GRAPHIC_WIDTH : integer := BLOCK_GRAPHIC_WIDTH;

    constant FONT_GRAPHIC_HEIGHT : integer := 37;
    constant FONT_GRAPHIC_WIDTH : integer := 28;
    
    -- Vectors
    constant VECTOR_PRECISION_Y : integer := 2**12;
    constant VECTOR_PRECISION_X : integer := (VECTOR_PRECISION_Y * FRAME_HEIGHT) / FRAME_WIDTH; -- Ratio conservation

    constant DEFAULT_BLOCK_SIZE_X : integer := VECTOR_PRECISION_X / (GRID_ROWS + 1); -- Last column reserved
    constant DEFAULT_BLOCK_SIZE_Y : integer := VECTOR_PRECISION_Y / GRID_COLS;
    constant DEFAULT_PLAYER_HITBOX_X : integer := (DEFAULT_BLOCK_SIZE_X * 2) / 3;
    constant DEFAULT_PLAYER_HITBOX_Y : integer := (DEFAULT_BLOCK_SIZE_Y * 2) / 3;

    -- O-----> Y axis
    -- |
    -- |
    -- X axis

    -- Game parameters
    constant NORMAL_MODE_DURATION : integer := 3 * 60 * 1000;
    constant DEATH_MODE_DURATION : integer := 60 * 1000;

    -- Counter precision
    constant MILLISECOND_COUNTER_PRECISION : integer := integer(ceil(log2(real(NORMAL_MODE_DURATION + DEATH_MODE_DURATION + 60 * 1000)))); -- Max 31 (18 = 4.3 minutes)
    constant CLK_COUNTER_PRECISION : integer := 31; -- Max 31

    ---------------------------------------------------------------------------
    -- Controls parameters
    ---------------------------------------------------------------------------
    constant NB_CONTROLS : integer := 5;
    type commands_container_type is array(0 to NB_CONTROLS - 1, 0 to NB_PLAYERS - 1) of std_logic_vector(7 downto 0);
    constant CONTROLS_CONTAINER : commands_container_type := (
        (x"1D", x"43", x"6C", x"75"), -- Forward controls
        (x"23", x"4b", x"7A", x"74"), -- Right controls
        (x"1B", x"42", x"69", x"72"), -- Back controls
        (x"1C", x"3b", x"71", x"6B"), -- Left controls

        (x"24", x"44", x"7d", x"70") -- Bomb controls
    );
    
    ---------------------------------------------------------------------------
    -- Graphic parameters
    ---------------------------------------------------------------------------

    -- Colors
    constant TRANSPARENT_COLOR : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := (others => '1');
    constant BACKGROUND_COLOR : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := "00011";

    -- VGA
    -- More details and values : http://web.mit.edu/6.111/www/s2004/NEWKIT/vga.shtml
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
