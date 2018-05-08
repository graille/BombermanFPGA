library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;

entity player_to_grid is
    port(
        in_player_position : in vector;

        out_i : out integer range 0 to GRID_ROWS - 1;
        out_j : out integer range 0 to GRID_COLS - 1
    );
end player_to_grid;

architecture behavioural of player_to_grid is
begin
    out_i <= in_player_position.X / DEFAULT_BLOCK_SIZE.X;
    out_j <= in_player_position.Y / DEFAULT_BLOCK_SIZE.Y;
end architecture;
