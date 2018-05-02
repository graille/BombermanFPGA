library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package PROJECT_PARAMS_PKG is
    constant NB_PLAYERS : integer := 4;
    constant ROWS : integer := 12;
    constant COLS : integer := 16;

    constant MILLISECOND_COUNTER_PRECISION : integer := 20;
    constant CLK_COUNTER_PRECISION : integer := 32;

    constant VECTOR_PRECISION : integer := 16;

    constant STATE_PRECISION : integer := 3;

    constant PIXEL_PRECISION : integer := 4;

    constant MAX_PLAYER_POWER : integer := 15;

    -- O-----> Y axis
    -- |
    -- |
    -- X axis

    -- Game parameters
    constant NORMAL_MODE_DURATION : integer := 5 * 60 * 1000;
    constant DEATH_MODE_DURATION : integer := 60 * 1000;
end package;
