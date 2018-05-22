library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package PROJECT_PARAMS_PKG is
    constant NB_PLAYERS : integer := 4;
    constant GRID_ROWS : integer := 15;
    constant GRID_COLS : integer := 20;

    constant VECTOR_PRECISION : integer := 16;
    constant STATE_PRECISION : integer := 3;
    constant PIXEL_PRECISION : integer := 4;

    constant PRNG_PRECISION : integer := 32;

    constant MAX_PLAYER_POWER : integer := 15;

    constant COLOR_BIT_PRECISION : integer := 5;

    constant NB_CHARACTER_DESIGN : integer := 7;

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

    -- Graphics parameters
    constant FRAME_WIDTH : natural := 800;
    constant FRAME_HEIGHT : natural := 600;
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

    constant BLOCK_GRAPHIC_WIDTH : integer := FRAME_WIDTH / GRID_COLS;
    constant BLOCK_GRAPHIC_HEIGHT : integer := FRAME_HEIGHT / GRID_ROWS;

    constant CHARACTER_HEIGHT : integer := BLOCK_GRAPHIC_HEIGHT;
    constant CHARACTER_WIDTH : integer := BLOCK_GRAPHIC_WIDTH;
end package;
