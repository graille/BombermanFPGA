library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;

entity player is
    generic(
    );
    port(
        clk, rst : in std_logic;
        --grid : out td_array_cube_types(ROWS - 1 downto 0, COLS - 1 downto 0)
    );
end player;
