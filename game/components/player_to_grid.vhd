library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;

entity player_to_grid is
    port(
        in_player_position : in vector;

        out_position : out grid_position
    );
end player_to_grid;

architecture behavioral of player_to_grid is
begin
    out_position.i <= in_player_position.X / DEFAULT_BLOCK_SIZE.X;
    out_position.j <= in_player_position.Y / DEFAULT_BLOCK_SIZE.Y;
end behavioral;
